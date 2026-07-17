// TEP-62 collection + governance root. Spec: docs/spec/registry.md.
// Never add per-user state here: TitleItem addresses are deterministic (architecture §3).

import "consul-order-types"
import "council-gate-types"
import "election-types"
import "registry-types"
import "seat-auction-types"
import "shared"
import "title-item-types"

contract NobilityRegistry {
    author: "digital-nobility"
    version: "0.1.0"
    description: "Digital Nobility registry: TEP-62 collection and governance root"
    storage: RegistryStorage
    incomingMessages: RegistryMessage
}

fun RegistryStorage.itemDeploy(self, owner: address): AutoDeployAddress {
    return titleItemDeployAddress(self.codes.load().itemCode, contract.getAddress(), owner);
}

// P(n) = dukeBasePrice · (dukeGrowthPermille/1000)ⁿ, truncating integer iteration (n < 49).
fun dukePriceAt(params: Params, n: int): coins {
    var price = params.dukeBasePrice;
    repeat (n) {
        price = price * params.dukeGrowthPermille / 1000;
    }
    return price;
}

// Sends DukeGrant as deploy+message: works for fresh wallets and existing holders alike
// (stateInit attached to an active account is ignored).
fun RegistryStorage.sendDukeGrant(
    self,
    owner: address,
    queryId: uint64,
    price: coins,
    value: coins,
    sendMode: int,
) {
    val params = self.params.load();
    val grantMsg = createMessage({
        bounce: false,
        dest: self.itemDeploy(owner),
        value,
        body: DukeGrant {
            queryId,
            budget: params.dukeBudget,
            treasury: self.treasury,
            price,
        },
    });
    grantMsg.send(sendMode);
}

// Bounded 7-bit popcount (bit 0 unused, seats numbered 1..7) — never a loop over users.
fun popcountSeats(mask: int): int {
    var count = 0;
    var i = 1;
    while (i <= TOTAL_SEATS) {
        if (((mask >> i) & 1) == 1) {
            count += 1;
        }
        i += 1;
    }
    return count;
}

// Scan by value (at most 7 entries) — is `target` the current holder of *some* seat?
// Used only for RevokeTitle's officeholder classification (docs/spec/registry.md
// "NewProposal", "Design resolution" spec concern #4).
fun seatHoldsValue(seatHolders: map<uint8, address>, target: address): bool {
    var found = false;
    var i = 1;
    while (i <= TOTAL_SEATS && !found) {
        val r = seatHolders.get(i as uint8);
        if (r.isFound && r.loadValue() == target) {
            found = true;
        }
        i += 1;
    }
    return found;
}

// Same bounded scan, returning the matched seat index (0 if none) instead of a bool — Task 7's
// AwardSeat domain check needs to know *which* seat backed the proposal, not just whether one
// did (docs/spec/registry.md "AwardSeat").
fun seatIndexOf(seatHolders: map<uint8, address>, target: address): int {
    var found = 0;
    var i = 1;
    while (i <= TOTAL_SEATS && found == 0) {
        val r = seatHolders.get(i as uint8);
        if (r.isFound && r.loadValue() == target) {
            found = i;
        }
        i += 1;
    }
    return found;
}

// docs/spec/registry.md "NewProposal" table: each kind belongs to exactly one seat's domain.
fun domainSeatFor(kind: int): int {
    if (kind == COUNCIL_KIND_TREASURY_SPEND) {
        return 2;
    }
    if (kind == COUNCIL_KIND_SET_PARAMS) {
        return 3;
    }
    if (kind == COUNCIL_KIND_REVOKE_TITLE || kind == COUNCIL_KIND_REMOVE_OFFICER) {
        return 7;
    }
    if (kind == COUNCIL_KIND_CONFIRM_DUKEDOM || kind == COUNCIL_KIND_REJECT_DUKEDOM) {
        return 4;
    }
    // COUNCIL_KIND_APPOINT_INTERIM, COUNCIL_KIND_SET_PAUSED
    return 1;
}

// Domain authorization (docs/spec/registry.md "NewProposal" check 2): who may propose for
// `seat`'s domain right now, and with what pre-counted weight. Returns (proposerSeat,
// proposerWeight); throws NotAuthorized on any mismatch.
fun domainAuth(
    ledgers: Ledgers,
    claimedMask: int,
    imperiumRenounced: bool,
    kind: int,
    seat: int,
    sender: address,
    emperor: address,
): (int, int) {
    val holderR = ledgers.seatHolders.get(seat as uint8);
    if (holderR.isFound) {
        assert (sender == holderR.loadValue()) throw RegistryErr.NotAuthorized;
        return (seat, 1);
    }
    val claimed = ((claimedMask >> seat) & 1) == 1;
    if (claimed) {
        // Claimed but currently vacant: falls to the First Consul ad interim, except a
        // treasury spend, which simply halts while seat 2 is vacant (architecture §8).
        assert (kind != COUNCIL_KIND_TREASURY_SPEND) throw RegistryErr.NotAuthorized;
        val seat1R = ledgers.seatHolders.get(1);
        assert (seat1R.isFound) throw RegistryErr.NotAuthorized;
        assert (sender == seat1R.loadValue()) throw RegistryErr.NotAuthorized;
        return (1, 1);
    }
    // Never claimed: the domain is still the Emperor's — unless he has renounced (Task 7),
    // in which case never-claimed domains have no valid proposer at all (docs/spec/registry.md
    // "RenounceImperium").
    assert (!imperiumRenounced) throw RegistryErr.NotAuthorized;
    assert (sender == emperor) throw RegistryErr.NotAuthorized;
    return (0, TOTAL_SEATS - popcountSeats(claimedMask));
}

// The shared accession side-effect step (docs/spec/registry.md "The shared claim step"),
// funneling every mechanism — heir, VIP, committee award, and later auction/election/doyen —
// through one routine: duke-cap check, seat overwrite + interim clear, one-way ratchet bit,
// seat-1 activity bump, and the founding-dukedom mint via the existing DukeGrant path.
// `value`/`sendMode` are threaded straight through to sendDukeGrant (mirroring its own already-
// parameterized signature): every existing caller passes (0, CARRY_ALL_REMAINING_MESSAGE_VALUE)
// to preserve the original single-send behavior; the Task 8 auction hook is the one caller that
// needs a different mode (CARRY_ALL_BALANCE, mode 128) because its AuctionResult handler also
// sends an AuctionCollect/AuctionRefund reply in the same transaction, and combining that with
// a mode-64 send would double-count the incoming value (playbook pitfall).
fun RegistryStorage.claimSeat(
    mutate self,
    seatIndex: int,
    claimant: address,
    queryId: uint64,
    value: coins,
    sendMode: int,
) {
    val slots = self.dukeCount + self.pendingDukeCount;
    assert (slots < MAX_DUKES) throw RegistryErr.DukeCapReached;

    var ledgers = self.ledgers.load();
    ledgers.seatHolders.set(seatIndex as uint8, claimant);
    self.ledgers = ledgers.toCell();
    // Clear the interim bit unconditionally (idempotent whether it was set or not) — this is
    // where interim replacement and seat-4/5 supersession/renewal happen.
    self.interimSeatsMask -= (self.interimSeatsMask & (1 << seatIndex));
    // One-way ratchet: |= is idempotent, so a re-claim of an ever-claimed seat is a no-op here.
    self.claimedSeatsMask |= (1 << seatIndex);
    if (seatIndex == 1) {
        self.seat1LastActiveAt = blockchain.now();
    }
    // Founding-dukedom mint (pinned, docs/spec/registry.md step 5): always attempted, even on
    // a re-claim — the item's own DukeGrant/DukeRejected round trip resolves "already a Duke"
    // without any owner->title lookup here.
    self.dukeCount += 1;
    self.save();
    self.sendDukeGrant(claimant, queryId, 0, value, sendMode);
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy RegistryMessage.fromSlice(in.body);

    match (msg) {
        BuyCitizenship => {
            val storage = lazy RegistryStorage.load();
            assert (!storage.paused) throw RegistryErr.Paused;
            val params = storage.params.load();
            val minValue = params.citizenshipPrice + ITEM_ENDOWMENT + GAS_MARGIN;
            assert (in.valueCoins >= minValue) throw RegistryErr.InsufficientValue;
            // The item forwards the price to the Treasury, keeps the endowment, refunds the
            // rest to the buyer — or refunds everything if the buyer already holds a title.
            val initMsg = createMessage({
                bounce: false,
                dest: storage.itemDeploy(in.senderAddress),
                value: 0,
                body: Initialize {
                    queryId: msg.queryId,
                    rank: RANK_CITIZEN,
                    patron: contract.getAddress(),
                    budget: 0,
                    treasury: storage.treasury,
                    price: params.citizenshipPrice,
                },
            });
            initMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        BuyDukedom => {
            var storage = RegistryStorage.load();
            assert (!storage.paused) throw RegistryErr.Paused;
            val slots = storage.dukeCount + storage.pendingDukeCount;
            assert (slots < MAX_DUKES) throw RegistryErr.DukeCapReached;
            val params = storage.params.load();
            val price = dukePriceAt(params, slots);
            val kept = price + ITEM_ENDOWMENT + GAS_MARGIN;
            assert (in.valueCoins >= kept + GAS_MARGIN) throw RegistryErr.InsufficientValue;

            if (params.dukeConfirmationRequired) {
                // Valve on (architecture §2): hold the funds until a consul confirmation.
                var ledgers = storage.ledgers.load();
                assert (
                    !ledgers.pendingDukes.exists(in.senderAddress)
                ) throw RegistryErr.AlreadyPending;
                ledgers.pendingDukes.set(in.senderAddress, { price, ts: blockchain.now() });
                storage.ledgers = ledgers.toCell();
                storage.pendingDukeCount += 1;
                storage.save();
                val refundMsg = createMessage({
                    bounce: false,
                    dest: in.senderAddress,
                    value: in.valueCoins - kept,
                    body: Excesses { queryId: msg.queryId },
                });
                refundMsg.send(SEND_MODE_REGULAR);
            } else {
                storage.dukeCount += 1;
                storage.save();
                storage.sendDukeGrant(
                    in.senderAddress,
                    msg.queryId,
                    price,
                    0,
                    SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE,
                );
            }
        }

        DukeRejected => {
            // The slot returns to the market; 1:1 with a grant whose increment happened.
            var storage = RegistryStorage.load();
            val expected = storage.itemDeploy(msg.owner).calculateAddress();
            assert (in.senderAddress == expected) throw RegistryErr.NotTitleItem;
            assert (storage.dukeCount > 0) throw RegistryErr.NotTitleItem;
            storage.dukeCount -= 1;
            storage.save();
            // The notice value stays as a registry top-up.
        }

        PatentFee => {
            // The final promotion gate: fees, transitions, bootstrap (docs/spec/registry.md).
            var storage = RegistryStorage.load();
            val expected = storage.itemDeploy(msg.owner).calculateAddress();
            assert (in.senderAddress == expected) throw RegistryErr.NotTitleItem;
            assert (!storage.paused) throw RegistryErr.Paused;
            val params = storage.params.load();
            var fee: coins = 0;
            var newBudget = 0;
            if (msg.targetRank == RANK_KNIGHT) {
                fee = params.knightFee;
            } else if (msg.targetRank == RANK_BARON) {
                fee = params.baronFee;
                newBudget = params.baronBudget;
            } else if (msg.targetRank == RANK_COUNT) {
                fee = params.countFee;
                newBudget = params.countBudget;
            } else {
                throw RegistryErr.BadTransition;
            }
            // Half a margin: the wallet-side minimum is fee + GAS_MARGIN, and the two hops
            // to get here eat into it; what remains must still fund the approval hops.
            assert (in.valueCoins >= fee + GAS_MARGIN / 2) throw RegistryErr.InsufficientValue;

            if (msg.targetRank != msg.currentRank + 1) {
                // Bootstrap gap fill, top-down (architecture §2); the close is one-way.
                val open = msg.targetRank == RANK_BARON
                    ? !storage.baronBootstrapClosed
                    : msg.targetRank == RANK_COUNT && !storage.countBootstrapClosed;
                assert (open && msg.currentRank < msg.targetRank) throw RegistryErr.BadTransition;
            }
            if (msg.targetRank == RANK_BARON) {
                storage.baronPop += 1;
                if (storage.baronPop >= params.baronQuota) {
                    storage.baronBootstrapClosed = true;
                }
            } else if (msg.targetRank == RANK_COUNT) {
                storage.countPop += 1;
                if (storage.countPop >= params.countQuota) {
                    storage.countBootstrapClosed = true;
                }
            }
            storage.save();

            // Protect the registry's own balance, forward the exact fee, pass the rest on.
            reserveToncoinsOnBalance(0, RESERVE_MODE_INCREASE_BY_ORIGINAL_BALANCE);
            val feeMsg = createMessage({
                bounce: false,
                dest: storage.treasury,
                value: fee,
            });
            feeMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
            val approvedMsg = createMessage({
                bounce: false,
                dest: in.senderAddress,
                value: 0,
                body: PatentApproved {
                    queryId: msg.queryId,
                    targetRank: msg.targetRank,
                    newBudget: newBudget as uint8,
                    fee,
                },
            });
            // SAFETY: CARRY_ALL_BALANCE runs after reserving the original balance, so only
            // the incoming remainder (minus the fee) rides to the item.
            approvedMsg.send(SEND_MODE_CARRY_ALL_BALANCE);
        }

        RepledgeFee => {
            // Repledge gate (docs/spec/registry.md "RepledgeFee"): no pause check by
            // design — repledge must keep working during an emergency pause (§11).
            val storage = lazy RegistryStorage.load();
            val expected = storage.itemDeploy(msg.owner).calculateAddress();
            assert (in.senderAddress == expected) throw RegistryErr.NotTitleItem;
            val params = storage.params.load();
            var fee: coins = 0;
            if (msg.rank == RANK_KNIGHT) {
                fee = params.knightFee / 2;
            } else if (msg.rank == RANK_BARON) {
                fee = params.baronFee / 2;
            } else if (msg.rank == RANK_COUNT) {
                fee = params.countFee / 2;
            } else {
                throw RegistryErr.BadTransition;
            }
            assert (in.valueCoins >= fee + GAS_MARGIN / 2) throw RegistryErr.InsufficientValue;

            // Repledge is not issuance: no population/bootstrap changes.
            reserveToncoinsOnBalance(0, RESERVE_MODE_INCREASE_BY_ORIGINAL_BALANCE);
            val feeMsg = createMessage({
                bounce: false,
                dest: storage.treasury,
                value: fee,
            });
            feeMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
            val doneMsg = createMessage({
                bounce: false,
                dest: in.senderAddress,
                value: 0,
                body: RepledgeDone {
                    queryId: msg.queryId,
                    fee,
                },
            });
            // SAFETY: CARRY_ALL_BALANCE runs after reserving the original balance, so
            // only the incoming remainder (minus the fee) rides back to the item.
            doneMsg.send(SEND_MODE_CARRY_ALL_BALANCE);
        }

        DeployGate => {
            // CouncilGate factory (docs/spec/registry.md "DeployGate"): no pause check by
            // design — verification infrastructure is exempt from the emergency pause,
            // same carve-out as RepledgeFee (architecture §11).
            val storage = lazy RegistryStorage.load();
            val params = storage.params.load();
            assert (
                in.valueCoins >= params.gateDeployFee + GAS_MARGIN
            ) throw RegistryErr.InsufficientValue;

            // The walk always terminates (TVM cells form a DAG built bottom-up); the cap
            // exists so a gate can never be deployed unable to finish its own execution walk.
            var count = 0;
            var node = msg.actions;
            while (node != null) {
                count += 1;
                assert (count <= MAX_GATE_ACTIONS) throw RegistryErr.TooManyActions;
                node = node!.load().next;
            }

            val codes = storage.codes.load();
            val gateConfig: GateStorage = {
                registry: contract.getAddress(),
                codes: StaticGateCodes { itemCode: codes.itemCode }.toCell(),
                quorum: msg.quorum,
                minRank: msg.minRank,
                expiry: msg.expiry,
                maxProofAge: msg.maxProofAge,
                executed: false,
                approvalCount: 0,
                approvals: [],
                actions: msg.actions,
                treasury: storage.treasury,
                verificationFee: params.verificationFee,
                salt: msg.salt,
            };
            val gateAddr = councilGateDeployAddress(codes.gateCode, gateConfig.toCell());

            // No response is sent back: the caller can already compute `gateAddr` themselves
            // off-chain from the same public inputs (gateCode(), this address, their config).
            reserveToncoinsOnBalance(0, RESERVE_MODE_INCREASE_BY_ORIGINAL_BALANCE);
            val feeMsg = createMessage({
                bounce: false,
                dest: storage.treasury,
                value: params.gateDeployFee,
            });
            feeMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
            val deployMsg = createMessage({
                bounce: false,
                dest: gateAddr,
                value: 0,
            });
            // SAFETY: CARRY_ALL_BALANCE runs after reserving the original balance, so only
            // the incoming remainder (minus the fee) funds the gate's deploy.
            deployMsg.send(SEND_MODE_CARRY_ALL_BALANCE);
        }

        NewProposal => {
            // The single entry point for all council business (docs/spec/registry.md
            // "NewProposal"). No pause check: governance business (including the SetPaused
            // toggle that would unpause) must stay reachable during a pause.
            var storage = RegistryStorage.load();
            assert (msg.kind <= COUNCIL_KIND_AWARD_SEAT) throw RegistryErr.BadDomain;
            assert (
                in.valueCoins >= ORDER_ENDOWMENT + 2 * GAS_MARGIN
            ) throw RegistryErr.InsufficientValue;

            val ledgers = storage.ledgers.load();

            var proposerSeat = 0;
            var proposerWeight = 0;
            var requiredWeight = QUORUM_ORDINARY;

            if (msg.kind == COUNCIL_KIND_AWARD_SEAT) {
                // Committee award (docs/spec/registry.md "AwardSeat"): not any single seat's
                // domain — the proposer must currently hold *some* seat, and the emperor's
                // votes are explicitly excluded (architecture §8).
                assert (in.senderAddress != storage.emperor) throw RegistryErr.NotAuthorized;
                val matchedSeat = seatIndexOf(ledgers.seatHolders, in.senderAddress);
                assert (matchedSeat != 0) throw RegistryErr.NotAuthorized;
                proposerSeat = matchedSeat;
                proposerWeight = 1;

                val body = AwardSeatBody.fromCell(msg.body);
                assert (body.seatIndex == 4 || body.seatIndex == 5) throw RegistryErr.BadDomain;
                // "Majority of claimed non-emperor seats, min 2" — denominator is the
                // ever-claimed mask, not currently-held seats (docs/spec/registry.md).
                val majority = popcountSeats(storage.claimedSeatsMask) / 2 + 1;
                requiredWeight = majority > 2 ? majority : 2;
            } else {
                val seat = domainSeatFor(msg.kind);
                val (pSeat, pWeight) = domainAuth(
                    ledgers,
                    storage.claimedSeatsMask,
                    storage.imperiumRenounced,
                    msg.kind,
                    seat,
                    in.senderAddress,
                    storage.emperor,
                );
                proposerSeat = pSeat;
                proposerWeight = pWeight;

                if (msg.kind == COUNCIL_KIND_TREASURY_SPEND) {
                    val body = TreasuryActionsBody.fromCell(msg.body);
                    // Same bounded walk-and-count shape as DeployGate's own action-list cap.
                    var count = 0;
                    var node = body.actions;
                    while (node != null) {
                        count += 1;
                        assert (count <= MAX_ORDER_ACTIONS) throw RegistryErr.TooManyActions;
                        node = node!.load().next;
                    }
                } else if (msg.kind == COUNCIL_KIND_SET_PARAMS) {
                    val body = SetParamsBody.fromCell(msg.body);
                    val np = body.newParams.load();
                    assert (
                        np.baronBudget <= MAX_BUDGET && np.countBudget <= MAX_BUDGET &&
                        np.dukeBudget <= MAX_BUDGET &&
                        np.epochSeconds >= EPOCH_FLOOR
                    ) throw RegistryErr.BadClamp;
                } else if (msg.kind == COUNCIL_KIND_REVOKE_TITLE) {
                    val body = RevokeTitleBody.fromCell(msg.body);
                    requiredWeight = seatHoldsValue(ledgers.seatHolders, body.targetOwner)
                        ? QUORUM_REMOVAL
                        : QUORUM_ORDINARY;
                } else if (msg.kind == COUNCIL_KIND_REMOVE_OFFICER) {
                    val body = RemoveOfficerBody.fromCell(msg.body);
                    assert (
                        body.seatIndex >= 1 && body.seatIndex <= TOTAL_SEATS &&
                        ledgers.seatHolders.exists(body.seatIndex)
                    ) throw RegistryErr.SeatNotHeld;
                    requiredWeight = QUORUM_REMOVAL;
                } else if (msg.kind == COUNCIL_KIND_APPOINT_INTERIM) {
                    val body = AppointInterimBody.fromCell(msg.body);
                    val claimed = body.seatIndex >= 1 && body.seatIndex <= TOTAL_SEATS &&
                    ((storage.claimedSeatsMask >> body.seatIndex) & 1) == 1;
                    assert (
                        claimed && !ledgers.seatHolders.exists(body.seatIndex)
                    ) throw RegistryErr.SeatNotVacant;
                    requiredWeight = QUORUM_REMOVAL;
                } else if (msg.kind == COUNCIL_KIND_CONFIRM_DUKEDOM) {
                    val body = ConfirmDukedomBody.fromCell(msg.body);
                    assert (
                        ledgers.pendingDukes.exists(body.candidate)
                    ) throw RegistryErr.NoPendingDuke;
                } else if (msg.kind == COUNCIL_KIND_REJECT_DUKEDOM) {
                    val body = RejectDukedomBody.fromCell(msg.body);
                    assert (
                        ledgers.pendingDukes.exists(body.candidate)
                    ) throw RegistryErr.NoPendingDuke;
                }
                // else: COUNCIL_KIND_SET_PAUSED, no extra check beyond the flat quorum above.
            }

            // Dead-man switch feed (docs/spec/registry.md "Storage additions"): any successful
            // proposal whose authenticated sender is seat 1's CURRENT holder — own-domain,
            // ad-interim fallback, or kind-8 alike — proves the First Consul is alive.
            val seat1R = ledgers.seatHolders.get(1);
            if (seat1R.isFound && seat1R.loadValue() == in.senderAddress) {
                storage.seat1LastActiveAt = blockchain.now();
            }

            val seqno = storage.nextOrderSeqno;
            storage.nextOrderSeqno += 1;
            storage.save();

            // Task 7: kind-8 orders snapshot emperorWeight as 0 regardless of the real ratchet
            // arithmetic — "the entire abstains-by-protocol implementation" (docs/spec/
            // registry.md "AwardSeat"); a renounced emperor also always snapshots 0.
            val emperorWeightForOrder = (msg.kind == COUNCIL_KIND_AWARD_SEAT ||
            storage.imperiumRenounced)
                ? 0
                : TOTAL_SEATS - popcountSeats(storage.claimedSeatsMask);

            val codes = storage.codes.load();
            val orderAddr = consulOrderDeployAddress(codes.orderCode, contract.getAddress(), seqno);
            val initMsg = createMessage({
                bounce: false,
                dest: orderAddr,
                value: 0,
                body: OrderInit {
                    queryId: msg.queryId,
                    kind: msg.kind,
                    body: msg.body,
                    emperor: storage.emperor,
                    emperorWeight: emperorWeightForOrder as uint8,
                    requiredWeight: requiredWeight as uint8,
                    expiry: msg.expiry,
                    holders: ledgers.seatHolders,
                    treasury: storage.treasury,
                    proposerSeat: proposerSeat as uint8,
                    proposerWeight: proposerWeight as uint8,
                },
            });
            // No response to the proposer: the order's address was already computable by
            // them off-chain from the same public inputs (orderCode(), this address,
            // nextOrderSeqno() before sending).
            initMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        CouncilAction => {
            // A ConsulOrder child -> Registry, once its own weighted quorum executes
            // (docs/spec/registry.md "CouncilAction"). Only kind 1..7 ever arrive here.
            var storage = RegistryStorage.load();
            val codes = storage.codes.load();
            val expected = consulOrderDeployAddress(
                codes.orderCode,
                contract.getAddress(),
                msg.orderSeqno,
            ).calculateAddress();
            assert (in.senderAddress == expected) throw RegistryErr.NotConsulOrder;

            if (msg.kind == COUNCIL_KIND_SET_PARAMS) {
                val body = SetParamsBody.fromCell(msg.body);
                storage.params = body.newParams;
                storage.save();
            } else if (msg.kind == COUNCIL_KIND_REVOKE_TITLE) {
                val body = RevokeTitleBody.fromCell(msg.body);
                val revokeMsg = createMessage({
                    bounce: false,
                    dest: storage.itemDeploy(body.targetOwner),
                    value: 0,
                    body: Revoke { queryId: msg.queryId },
                });
                revokeMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
            } else if (msg.kind == COUNCIL_KIND_REMOVE_OFFICER) {
                val body = RemoveOfficerBody.fromCell(msg.body);
                var ledgers = storage.ledgers.load();
                // Re-check against LIVE storage (docs/spec/registry.md "Design resolution:
                // re-check at execution") — a competing order may have already cleared this
                // seat since NewProposal time. claimedSeatsMask is untouched: office loss
                // keeps the dukedom and the seat's "ever claimed" status (architecture §8).
                assert (ledgers.seatHolders.exists(body.seatIndex)) throw RegistryErr.SeatNotHeld;
                ledgers.seatHolders.delete(body.seatIndex);
                storage.ledgers = ledgers.toCell();
                // Task 7: office loss clears the interim bit too (any replacement/removal
                // path clears it, docs/spec/registry.md "Storage additions").
                storage.interimSeatsMask -= (storage.interimSeatsMask & (1 << body.seatIndex));
                storage.save();
            } else if (msg.kind == COUNCIL_KIND_APPOINT_INTERIM) {
                val body = AppointInterimBody.fromCell(msg.body);
                var ledgers = storage.ledgers.load();
                val claimed = ((storage.claimedSeatsMask >> body.seatIndex) & 1) == 1;
                assert (
                    claimed && !ledgers.seatHolders.exists(body.seatIndex)
                ) throw RegistryErr.SeatNotVacant;
                ledgers.seatHolders.set(body.seatIndex, body.interim);
                storage.ledgers = ledgers.toCell();
                // Task 7: mark this holder as interim-installed so a later mechanism claim can
                // displace it without waiting for vacancy or inactivity (docs/spec/registry.md
                // "Storage additions").
                storage.interimSeatsMask |= (1 << body.seatIndex);
                storage.save();
            } else if (msg.kind == COUNCIL_KIND_AWARD_SEAT) {
                // Committee award execution (docs/spec/registry.md "AwardSeat"): no
                // precondition re-check — the award replaces whoever sits there by design, and
                // no pause check — an accession claim (and its founding dukedom) can never be
                // blocked, pause included (the ruling principle, same section).
                val body = AwardSeatBody.fromCell(msg.body);
                storage.claimSeat(
                    body.seatIndex,
                    body.awardee,
                    msg.queryId,
                    0,
                    SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE,
                );
            } else if (msg.kind == COUNCIL_KIND_CONFIRM_DUKEDOM) {
                // Issuance, unlike the other six kinds: the pause carve-out only exempts
                // un-issuance/verification (architecture §11).
                assert (!storage.paused) throw RegistryErr.Paused;
                val body = ConfirmDukedomBody.fromCell(msg.body);
                var ledgers = storage.ledgers.load();
                val found = ledgers.pendingDukes.deleteAndGetDeleted(body.candidate);
                assert (found.isFound) throw RegistryErr.NoPendingDuke;
                val pending = found.loadValue();
                storage.ledgers = ledgers.toCell();
                storage.pendingDukeCount -= 1;
                storage.dukeCount += 1;
                storage.save();
                // Identical to the retired ConfirmDukedom's effect: held funds ride with the
                // grant, this message's own remainder subsidizes gas.
                storage.sendDukeGrant(
                    body.candidate,
                    msg.queryId,
                    pending.price,
                    pending.price + ITEM_ENDOWMENT + GAS_MARGIN,
                    SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE,
                );
            } else if (msg.kind == COUNCIL_KIND_REJECT_DUKEDOM) {
                // No pause check: a refund is not new issuance (same stance as RepledgeFee).
                val body = RejectDukedomBody.fromCell(msg.body);
                var ledgers = storage.ledgers.load();
                val found = ledgers.pendingDukes.deleteAndGetDeleted(body.candidate);
                assert (found.isFound) throw RegistryErr.NoPendingDuke;
                val pending = found.loadValue();
                storage.ledgers = ledgers.toCell();
                storage.pendingDukeCount -= 1;
                storage.save();
                // The pending-duke ledger is keyed by the buyer's own wallet, not an item —
                // no item exists yet for a first-time duke buyer, so refund the wallet directly.
                val refundMsg = createMessage({
                    bounce: false,
                    dest: body.candidate,
                    value: pending.price + ITEM_ENDOWMENT + GAS_MARGIN,
                });
                refundMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
            } else if (msg.kind == COUNCIL_KIND_SET_PAUSED) {
                val body = SetPausedBody.fromCell(msg.body);
                storage.paused = body.paused;
                storage.save();
            } else {
                throw RegistryErr.BadDomain;
            }
        }

        DesignateHeir => {
            // Seat-1 holder wallet -> registry (docs/spec/registry.md "DesignateHeir").
            var storage = RegistryStorage.load();
            var ledgers = storage.ledgers.load();
            val holder = ledgers.seatHolders.get(1);
            assert (
                holder.isFound && in.senderAddress == holder.loadValue()
            ) throw RegistryErr.NotAuthorized;
            ledgers.heir = msg.heir;
            storage.ledgers = ledgers.toCell();
            // Managing succession is activity: restarts the dead-man clock.
            storage.seat1LastActiveAt = blockchain.now();
            storage.save();
            // Remaining value stays as a top-up: no response message.
        }

        ClaimSeatHeir => {
            // Heir wallet -> registry (docs/spec/registry.md "ClaimSeatHeir").
            var storage = RegistryStorage.load();
            val ledgers = storage.ledgers.load();
            assert (in.senderAddress == ledgers.heir) throw RegistryErr.NotAuthorized;
            assert (
                in.valueCoins >= ITEM_ENDOWMENT + 2 * GAS_MARGIN
            ) throw RegistryErr.InsufficientValue;

            val holder = ledgers.seatHolders.get(1);
            val vacant = !holder.isFound;
            val interim = ((storage.interimSeatsMask >> 1) & 1) == 1;
            val params = storage.params.load();
            val epochElapsed = blockchain.now() >= storage.seat1LastActiveAt + params.epochSeconds;
            assert (vacant || interim || epochElapsed) throw RegistryErr.HolderActive;

            storage.claimSeat(
                1,
                in.senderAddress,
                msg.queryId,
                0,
                SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE,
            );
        }

        AbdicateSeat => {
            // Any seat holder wallet -> registry (docs/spec/registry.md "AbdicateSeat"). One
            // check covers wrong sender, vacant seat, and out-of-range index alike.
            var storage = RegistryStorage.load();
            var ledgers = storage.ledgers.load();
            val holder = ledgers.seatHolders.get(msg.seatIndex);
            assert (
                holder.isFound && in.senderAddress == holder.loadValue()
            ) throw RegistryErr.NotAuthorized;
            ledgers.seatHolders.delete(msg.seatIndex);
            storage.ledgers = ledgers.toCell();
            // claimedSeatsMask untouched: the ratchet never rewinds (architecture §8).
            storage.interimSeatsMask -= (storage.interimSeatsMask & (1 << msg.seatIndex));
            storage.save();
        }

        ClaimSeatVip => {
            // Anyone -> registry, seat 6 (docs/spec/registry.md "ClaimSeatVip"). The message
            // sender is deliberately irrelevant — the signature is a credential for the
            // claimant, not the sender.
            var storage = RegistryStorage.load();
            assert (
                in.valueCoins >= ITEM_ENDOWMENT + 2 * GAS_MARGIN
            ) throw RegistryErr.InsufficientValue;

            val ledgers = storage.ledgers.load();
            val holder = ledgers.seatHolders.get(6);
            val vacant = !holder.isFound;
            val interim = ((storage.interimSeatsMask >> 6) & 1) == 1;
            assert (vacant || interim) throw RegistryErr.SeatNotVacant;

            val payload = VipClaimPayload {
                registry: contract.getAddress(),
                claimant: msg.claimant,
            };
            assert (
                isSignatureValid(payload.toCell().hash(), msg.signature as slice, ledgers.vipPubkey)
            ) throw RegistryErr.BadSignature;

            storage.claimSeat(
                6,
                msg.claimant,
                msg.queryId,
                0,
                SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE,
            );
        }

        RenounceImperium => {
            // Emperor wallet -> registry (docs/spec/registry.md "RenounceImperium"). One-way,
            // idempotent.
            var storage = RegistryStorage.load();
            assert (in.senderAddress == storage.emperor) throw RegistryErr.NotAuthorized;
            storage.imperiumRenounced = true;
            storage.save();
        }

        SetTreasury => {
            // Founder wallet -> registry, genesis-only (docs/spec/registry.md "SetTreasury").
            // Guard: sender is the founder AND treasury still equals the genesis placeholder
            // (founder's own address, per scripts/genesis.tolk) -- once this succeeds,
            // storage.treasury no longer equals ledgers.founder, so the guard can never pass
            // again. No extra lock bit, no storage growth.
            var storage = RegistryStorage.load();
            val ledgers = storage.ledgers.load();
            assert (
                in.senderAddress == ledgers.founder && storage.treasury == ledgers.founder
            ) throw RegistryErr.TreasuryWiringClosed;
            storage.treasury = msg.treasury;
            storage.save();
        }

        SeatActive => {
            // A ConsulOrder child -> registry (docs/spec/registry.md "SeatActive"). Advisory:
            // a stale-holder mismatch is silently absorbed, never thrown.
            var storage = RegistryStorage.load();
            val codes = storage.codes.load();
            val expected = consulOrderDeployAddress(
                codes.orderCode,
                contract.getAddress(),
                msg.orderSeqno,
            ).calculateAddress();
            assert (in.senderAddress == expected) throw RegistryErr.NotConsulOrder;

            val holder = storage.ledgers.load().seatHolders.get(1);
            if (holder.isFound && holder.loadValue() == msg.holder) {
                storage.seat1LastActiveAt = blockchain.now();
                storage.save();
            }
        }

        StartAuction => {
            // Permissionless genesis/re-auction trigger for seat 2 (docs/spec/registry.md
            // "Task 8 — auction hook"). No pause check: accession is permissionless (the ruling
            // principle, "Task 7").
            var storage = RegistryStorage.load();
            val slots = storage.dukeCount + storage.pendingDukeCount;
            assert (slots < MAX_DUKES) throw RegistryErr.DukeCapReached;
            assert (!storage.auctionOpen) throw RegistryErr.AuctionOpen;

            val ledgers = storage.ledgers.load();
            val holder = ledgers.seatHolders.get(2);
            val vacant = !holder.isFound;
            val interim = ((storage.interimSeatsMask >> 2) & 1) == 1;
            assert (vacant || interim) throw RegistryErr.SeatNotVacant;

            assert (
                in.valueCoins >= AUCTION_ENDOWMENT + GAS_MARGIN
            ) throw RegistryErr.InsufficientValue;

            storage.auctionSeqno += 1;
            storage.auctionOpen = true;
            storage.save();

            val codes = storage.codes.load();
            val auctionAddr = seatAuctionDeployAddress(
                codes.codes2.load().auctionCode,
                contract.getAddress(),
                storage.auctionSeqno,
            );
            val initMsg = createMessage({
                bounce: false,
                dest: auctionAddr,
                value: 0,
                body: AuctionInit {
                    queryId: msg.queryId,
                    treasury: storage.treasury,
                    endAt: blockchain.now() + AUCTION_DURATION,
                },
            });
            // No response to the caller: the round's address was already computable off-chain
            // from auctionCode(), this address, and nextAuctionSeqno() before sending.
            initMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        AuctionResult => {
            // A SeatAuction child -> registry, once its own round settles (docs/spec/
            // seat-auction.md "Settle"; docs/spec/registry.md "Task 8 — auction hook",
            // escrow-until-ack amendment). Sender is reconstructed from the auction code cell,
            // exactly ErrNotConsulOrder's shape for CouncilAction.
            var storage = RegistryStorage.load();
            val codes = storage.codes.load();
            val expected = seatAuctionDeployAddress(
                codes.codes2.load().auctionCode,
                contract.getAddress(),
                msg.auctionSeqno,
            ).calculateAddress();
            assert (in.senderAddress == expected) throw RegistryErr.NotAuction;

            // Unconditional first effect: this must happen regardless of which branch below
            // runs, so a future re-auction is always startable again.
            storage.auctionOpen = false;

            if (msg.winner != null) {
                val capOk = storage.dukeCount + storage.pendingDukeCount < MAX_DUKES;
                if (capOk) {
                    // Reserve-then-split (same idiom as PatentFee/RepledgeFee): the incoming
                    // AUCTION_ENDOWMENT funds both the AuctionCollect reply below and the
                    // founding-dukedom deploy+hops inside claimSeat, without a mode-64/mode-128
                    // double count (playbook pitfall) — reserve first, one exact send, then a
                    // single CARRY_ALL_BALANCE send for the remainder.
                    reserveToncoinsOnBalance(0, RESERVE_MODE_INCREASE_BY_ORIGINAL_BALANCE);
                    val collectMsg = createMessage({
                        bounce: false,
                        dest: in.senderAddress,
                        value: GAS_MARGIN / 2,
                        body: AuctionCollect {
                            queryId: msg.queryId,
                            treasury: storage.treasury,
                        },
                    });
                    collectMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
                    // SAFETY: CARRY_ALL_BALANCE runs after the reserve + exact collect send
                    // above, so only the remaining incoming value (endowment minus the collect
                    // reply) rides with the founding-dukedom grant.
                    storage.claimSeat(
                        2,
                        msg.winner!,
                        msg.queryId,
                        0,
                        SEND_MODE_CARRY_ALL_BALANCE,
                    );
                } else {
                    // Duke cap filled mid-round (the auction cannot know or prevent this):
                    // refund the winner instead of losing their bid — the fix this amendment
                    // makes over the originally accepted gap (docs/spec/seat-auction-test-plan.md
                    // "Spec concerns" #1, now closed). Seat 2 stays exactly as it was.
                    storage.save();
                    val refundMsg = createMessage({
                        bounce: false,
                        dest: in.senderAddress,
                        value: GAS_MARGIN / 2,
                        body: AuctionRefund { queryId: msg.queryId },
                    });
                    refundMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
                }
            } else {
                // No-bid round: nothing was ever escrowed, nothing to collect or refund.
                storage.save();
            }
        }

        StartElection => {
            // Permissionless genesis/re-contest trigger for seats 3/7 (docs/spec/registry.md
            // "Task 9 — election hook"). No pause check, no vacancy precondition (unlike
            // StartAuction) — both seats are unconditionally re-contested every cycle.
            var storage = RegistryStorage.load();
            assert (!storage.electionOpen) throw RegistryErr.AuctionOpen;
            assert (blockchain.now() >= storage.nextEpochAt) throw RegistryErr.EpochNotDue;
            assert (
                in.valueCoins >= ELECTION_DEPLOY_ENDOWMENT + GAS_MARGIN
            ) throw RegistryErr.InsufficientValue;

            storage.electionSeqno += 1;
            storage.electionOpen = true;
            val params = storage.params.load();
            storage.nextEpochAt = blockchain.now() + params.epochSeconds;
            storage.save();

            val codes = storage.codes.load();
            val codes2 = codes.codes2.load();
            val electionAddr = electionDeployAddress(
                codes2.electionCode,
                contract.getAddress(),
                storage.electionSeqno,
            );
            val initMsg = createMessage({
                bounce: false,
                dest: electionAddr,
                value: 0,
                body: ElectionInit {
                    queryId: msg.queryId,
                    treasury: storage.treasury,
                    itemCode: codes.itemCode,
                    candidateWindowEnd: blockchain.now() + ELECTION_CANDIDATE_WINDOW,
                    votingEnd: blockchain.now() + ELECTION_WINDOW,
                },
            });
            // No response to the caller: the round's address was already computable off-chain
            // from electionCode(), this address, and nextElectionSeqno() before sending.
            initMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        ElectionResult => {
            // An Election child -> registry, seat 3 (docs/spec/registry.md "Task 9 — election
            // hook"). Sender is reconstructed from the election code cell, identical shape to
            // AuctionResult's own check.
            var storage = RegistryStorage.load();
            val codes = storage.codes.load();
            val codes2 = codes.codes2.load();
            val expected = electionDeployAddress(
                codes2.electionCode,
                contract.getAddress(),
                msg.electionSeqno,
            ).calculateAddress();
            assert (in.senderAddress == expected) throw RegistryErr.NotElection;

            // Unconditional first effect: this must happen regardless of which branch below
            // runs, so a future cycle is always startable again.
            storage.electionOpen = false;

            if (msg.winner != null) {
                val capOk = storage.dukeCount + storage.pendingDukeCount < MAX_DUKES;
                if (capOk) {
                    // Only one send this transaction (docs/spec/election.md "Key decisions"
                    // #10) — a plain claimSeat call, no reserve/mode-128 gymnastics needed.
                    storage.claimSeat(
                        3,
                        msg.winner!,
                        msg.queryId,
                        0,
                        SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE,
                    );
                } else {
                    // Duke cap filled mid-cycle: seat 3 stays exactly as it was. No escrow was
                    // ever created for a seat-3 winner, so there is nothing to refund.
                    storage.save();
                }
            } else {
                // No turnout, or no candidates: nothing further to do.
                storage.save();
            }
        }

        DoyenClaim => {
            // An Election child -> registry, seat 7 (docs/spec/registry.md "Task 9 — election
            // hook"). Identical shape and handling to ElectionResult, targeting seat 7 instead
            // of seat 3 — arrives as its own independent transaction.
            var storage = RegistryStorage.load();
            val codes = storage.codes.load();
            val codes2 = codes.codes2.load();
            val expected = electionDeployAddress(
                codes2.electionCode,
                contract.getAddress(),
                msg.electionSeqno,
            ).calculateAddress();
            assert (in.senderAddress == expected) throw RegistryErr.NotElection;

            storage.electionOpen = false;

            if (msg.winner != null) {
                val capOk = storage.dukeCount + storage.pendingDukeCount < MAX_DUKES;
                if (capOk) {
                    storage.claimSeat(
                        7,
                        msg.winner!,
                        msg.queryId,
                        0,
                        SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE,
                    );
                } else {
                    storage.save();
                }
            } else {
                storage.save();
            }
        }

        else => {
            // Empty body = rent top-up (the registry funds its own storage this way).
            assert (in.body.isEmpty()) throw RegistryErr.InvalidMessage;
        }
    }
}

fun onBouncedMessage(_in: InMessageBounced) {
    // Initialize is sent non-bounceable; any stray bounce is absorbed as a top-up.
}

// TEP-62 getters.

get fun get_collection_data(): (int, cell, address) {
    val storage = lazy RegistryStorage.load();
    // Item indexes are owner-derived account ids, not sequential — report -1.
    return (-1, storage.content.load().meta, storage.emperor);
}

get fun get_nft_address_by_index(index: uint256): address {
    val storage = lazy RegistryStorage.load();
    // Index is the owner's basechain account_id; non-basechain owners are unsupported in MVP.
    val owner = address.fromWorkchainAndHash(0, index);
    return storage.itemDeploy(owner).calculateAddress();
}

get fun get_nft_content(_index: uint256, individual: cell): cell {
    val storage = lazy RegistryStorage.load();
    // TEP-64 offchain layout: 0x01 prefix + common base bytes + individual content ref.
    return beginCell()
        .storeUint(1, 8)
        .storeSlice(storage.content.load().commonBase.beginParse())
        .storeRef(individual)
        .endCell();
}

// Convenience getters.

get fun titleItemAddress(owner: address): address {
    val storage = lazy RegistryStorage.load();
    return storage.itemDeploy(owner).calculateAddress();
}

get fun currentParams(): Params {
    val storage = lazy RegistryStorage.load();
    return storage.params.load();
}

get fun gateCode(): cell {
    val storage = lazy RegistryStorage.load();
    return storage.codes.load().gateCode;
}

get fun treasuryAddress(): address {
    val storage = lazy RegistryStorage.load();
    return storage.treasury;
}

get fun dukePrice(): coins {
    val storage = lazy RegistryStorage.load();
    return dukePriceAt(storage.params.load(), storage.dukeCount + storage.pendingDukeCount);
}

get fun dukeCounts(): (int, int) {
    val storage = lazy RegistryStorage.load();
    return (storage.dukeCount, storage.pendingDukeCount);
}

get fun bootstrapState(): (int, int, bool, bool) {
    val storage = lazy RegistryStorage.load();
    return (
        storage.baronPop,
        storage.countPop,
        storage.baronBootstrapClosed,
        storage.countBootstrapClosed,
    );
}

// Task 6 getters (docs/spec/registry.md "Get-methods").

get fun orderCode(): cell {
    val storage = lazy RegistryStorage.load();
    return storage.codes.load().orderCode;
}

get fun nextOrderSeqno(): int {
    val storage = lazy RegistryStorage.load();
    return storage.nextOrderSeqno;
}

// Task 7: imperiumRenounced is one-way and final — once set, the emperor's weight is 0
// forever regardless of the ratchet math (docs/spec/registry.md "Getters (Task 7)").
get fun emperorWeight(): int {
    val storage = lazy RegistryStorage.load();
    if (storage.imperiumRenounced) {
        return 0;
    }
    return TOTAL_SEATS - popcountSeats(storage.claimedSeatsMask);
}

// addr_none if unheld — claimed-but-vacant and never-claimed are indistinguishable from this
// getter alone; combine with seatClaimed to tell them apart.
get fun seatHolder(seatIndex: int): any_address {
    val storage = lazy RegistryStorage.load();
    val r = storage.ledgers.load().seatHolders.get(seatIndex as uint8);
    if (r.isFound) {
        return r.loadValue() as any_address;
    }
    return createAddressNone() as any_address;
}

get fun seatClaimed(seatIndex: int): int {
    val storage = lazy RegistryStorage.load();
    return (storage.claimedSeatsMask >> seatIndex) & 1;
}

// Task 7 getters (docs/spec/registry.md "Getters (Task 7)").

get fun heir(): address {
    val storage = lazy RegistryStorage.load();
    return storage.ledgers.load().heir;
}

get fun founder(): address {
    val storage = lazy RegistryStorage.load();
    return storage.ledgers.load().founder;
}

get fun vipPubkey(): int {
    val storage = lazy RegistryStorage.load();
    return storage.ledgers.load().vipPubkey;
}

get fun seat1LastActiveAt(): int {
    val storage = lazy RegistryStorage.load();
    return storage.seat1LastActiveAt;
}

// The interimSeatsMask bit for seatIndex, 0/1 — completing the per-facet trio with seatHolder/
// seatClaimed.
get fun seatInterim(seatIndex: int): int {
    val storage = lazy RegistryStorage.load();
    return (storage.interimSeatsMask >> seatIndex) & 1;
}

// Task 8 getters (docs/spec/registry.md "Get-methods (Task 8)").

get fun auctionCode(): cell {
    val storage = lazy RegistryStorage.load();
    return storage.codes.load().codes2.load().auctionCode;
}

get fun nextAuctionSeqno(): int {
    val storage = lazy RegistryStorage.load();
    return storage.auctionSeqno + 1;
}

get fun auctionOpen(): int {
    val storage = lazy RegistryStorage.load();
    return storage.auctionOpen ? 1 : 0;
}

// Task 9 getters (docs/spec/registry.md "Getters (Task 9)").

get fun electionCode(): cell {
    val storage = lazy RegistryStorage.load();
    return storage.codes.load().codes2.load().electionCode;
}

get fun nextElectionSeqno(): int {
    val storage = lazy RegistryStorage.load();
    return storage.electionSeqno + 1;
}

get fun electionOpen(): int {
    val storage = lazy RegistryStorage.load();
    return storage.electionOpen ? 1 : 0;
}

get fun nextEpochAt(): int {
    val storage = lazy RegistryStorage.load();
    return storage.nextEpochAt;
}
