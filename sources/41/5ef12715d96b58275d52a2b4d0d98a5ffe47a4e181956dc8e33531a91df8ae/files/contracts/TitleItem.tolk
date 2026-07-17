// TEP-85 soulbound title item. Spec: docs/spec/title-item.md.

import "shared"
import "title-item-types"

contract TitleItem {
    author: "digital-nobility"
    version: "0.1.0"
    description: "TEP-85 soulbound title item: rank, patron chain, patents, merit"
    storage: ItemStorage
    incomingMessages: ItemMessage
}

// Rank sentinel for a destroyed (abdicated) item; the tombstone keeps merit history.
const DESTROYED_RANK = 255

fun rankContent(rank: uint8): cell {
    return beginCell().storeUint(rank, 8).endCell();
}

fun ItemStorage.itemId(self): uint256 {
    val (_, hash) = self.owner.getWorkchainAndHash();
    return hash;
}

fun emitMeritFor(actor: address, kind: uint8, amount: coins) {
    createExternalLogMessage({
        dest: createAddressNone(),
        body: MeritEvent {
            actor,
            kind,
            amount,
            ts: blockchain.now(),
        },
    }).send(SEND_MODE_REGULAR);
}

fun ItemStorage.emitMerit(self, kind: uint8, amount: coins) {
    emitMeritFor(self.owner, kind, amount);
}

// All TitleItems share one code cell, so any item can reconstruct a sibling's address.
fun siblingItemAddress(registry: address, owner: address): address {
    return titleItemDeployAddress(contract.getCode(), registry, owner).calculateAddress();
}

// Loads storage for ops that require an initialized, non-destroyed item.
fun loadLiveStorage(): ItemStorage {
    val loader = ItemStorage.startLoading();
    assert (loader.isInitialized()) throw ItemErr.NotInitialized;
    val storage = loader.endLoading();
    assert (storage.rank != DESTROYED_RANK) throw ItemErr.Destroyed;
    return storage;
}

// Refund the whole message value to the owner. No state change.
fun refundAllToOwner(owner: address, queryId: uint64) {
    val refundMsg = createMessage({
        bounce: false,
        dest: owner,
        value: 0,
        body: Excesses { queryId },
    });
    refundMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
}

// First-time initialization: persist the tail, emit the issuance merit event, keep the rent
// endowment, forward the price to the Treasury, refund the rest to the owner.
fun initializeItem(
    loader: ItemStorageLoader,
    rank: uint8,
    patron: address,
    budget: uint8,
    treasury: address,
    price: coins,
    queryId: uint64,
) {
    val storage: ItemStorage = {
        registry: loader.registry,
        owner: loader.owner,
        rank,
        patron,
        budget,
        revokedAt: 0,
        merit: price,
        chainValidUntil: 0,
        pendingPatent: null,
    };
    storage.save();
    // Issuance merit kind equals the acquired rank (architecture §7).
    storage.emitMerit(rank, price);
    reserveToncoinsOnBalance(ITEM_ENDOWMENT, RESERVE_MODE_EXACT_AMOUNT);
    // Skipped for price == 0 (founding dukedoms): a 0-TON message gives the destination no
    // gas credit and aborts — docs/spec/registry.md "The shared claim step".
    if (price > 0) {
        val feeMsg = createMessage({
            bounce: false,
            dest: treasury,
            value: price,
        });
        feeMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
    }
    val excessesMsg = createMessage({
        bounce: false,
        dest: storage.owner,
        value: 0,
        body: Excesses { queryId },
    });
    // SAFETY: CARRY_ALL_BALANCE runs after the exact-amount reserve above, so the
    // endowment stays; the remainder is the buyer's change and belongs to the owner.
    excessesMsg.send(SEND_MODE_CARRY_ALL_BALANCE);
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy ItemMessage.fromSlice(in.body);

    match (msg) {
        Initialize => {
            val loader = ItemStorage.startLoading();
            assert (in.senderAddress == loader.registry) throw ItemErr.NotRegistry;
            if (loader.isInitialized()) {
                // Double purchase (owner == buyer in MVP; gift ennoblement is Phase 2).
                refundAllToOwner(loader.owner, msg.queryId);
                return;
            }
            initializeItem(
                loader,
                msg.rank,
                msg.patron,
                msg.budget,
                msg.treasury,
                msg.price,
                msg.queryId,
            );
        }

        DukeGrant => {
            val loader = ItemStorage.startLoading();
            assert (in.senderAddress == loader.registry) throw ItemErr.NotRegistry;
            if (!loader.isInitialized()) {
                // Fresh wallet: initialize directly as a Duke (patron = registry, chain top).
                initializeItem(
                    loader,
                    RANK_DUKE,
                    loader.registry,
                    msg.budget,
                    msg.treasury,
                    msg.price,
                    msg.queryId,
                );
                return;
            }
            var storage = loader.endLoading();
            if (
                storage.rank == DESTROYED_RANK || storage.rank == RANK_DUKE ||
                storage.revokedAt != 0
            ) {
                // Cannot become a Duke: full refund to the owner, and the slot returns to
                // the market via DukeRejected (spec: docs/spec/registry.md).
                val rejectMsg = createMessage({
                    bounce: false,
                    dest: storage.registry,
                    value: DUKE_REJECT_NOTICE,
                    body: DukeRejected {
                        queryId: msg.queryId,
                        owner: storage.owner,
                    },
                });
                rejectMsg.send(SEND_MODE_REGULAR);
                refundAllToOwner(storage.owner, msg.queryId);
                return;
            }
            // In-place upgrade (one title per address): the old patron's spent patent stays
            // spent; duke patents replace any unspent lower ones.
            storage.rank = RANK_DUKE;
            storage.patron = storage.registry;
            storage.budget = msg.budget;
            storage.merit += msg.price;
            storage.save();
            storage.emitMerit(RANK_DUKE, msg.price);
            // The endowment already sits on this item: protect the pre-message balance,
            // forward the price, refund the rest of the incoming value to the owner.
            reserveToncoinsOnBalance(0, RESERVE_MODE_INCREASE_BY_ORIGINAL_BALANCE);
            // Skipped for price == 0 (founding-dukedom upgrade of an existing holder):
            // a 0-TON message aborts at the destination — docs/spec/registry.md.
            if (msg.price > 0) {
                val feeMsg = createMessage({
                    bounce: false,
                    dest: msg.treasury,
                    value: msg.price,
                });
                feeMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
            }
            val excessesMsg = createMessage({
                bounce: false,
                dest: storage.owner,
                value: 0,
                body: Excesses { queryId: msg.queryId },
            });
            // SAFETY: CARRY_ALL_BALANCE runs after reserving the original balance, so the
            // pre-existing endowment stays; only the incoming remainder goes to the owner.
            excessesMsg.send(SEND_MODE_CARRY_ALL_BALANCE);
        }

        PromoteVassal => {
            var storage = loadLiveStorage();
            assert (in.senderAddress == storage.owner) throw ItemErr.NotOwner;
            assert (in.valueCoins >= 2 * GAS_MARGIN) throw ItemErr.InsufficientValue;
            assert (storage.revokedAt == 0) throw ItemErr.AlreadyRevoked;
            assert (storage.rank >= RANK_BARON && storage.budget > 0) throw ItemErr.CannotPromote;
            assert (msg.candidate != storage.owner) throw ItemErr.CannotPromote;
            storage.budget -= 1;
            storage.save();
            // Bounceable: an undeployed candidate bounces the grant and the budget is
            // restored in onBouncedMessage.
            val grantMsg = createMessage({
                bounce: true,
                dest: siblingItemAddress(storage.registry, msg.candidate),
                value: 0,
                body: GrantPatent {
                    queryId: msg.queryId,
                    targetRank: storage.rank - 1,
                    patronOwner: storage.owner,
                    grantedAt: blockchain.now(),
                },
            });
            grantMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        GrantPatent => {
            val loader = ItemStorage.startLoading();
            assert (loader.isInitialized()) throw ItemErr.NotInitialized;
            assert (
                in.senderAddress == siblingItemAddress(loader.registry, msg.patronOwner)
            ) throw ItemErr.NotTitleItem;
            var storage = loader.endLoading();
            val cannotTake = storage.rank == DESTROYED_RANK || storage.revokedAt != 0 ||
            storage.rank >= msg.targetRank ||
            storage.pendingPatent != null;
            if (cannotTake) {
                // Return the patent to the patron; no state change here.
                val rejectMsg = createMessage({
                    bounce: false,
                    dest: in.senderAddress,
                    value: 0,
                    body: PatentRejected {
                        queryId: msg.queryId,
                        candidateOwner: storage.owner,
                    },
                });
                rejectMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
                return;
            }
            storage.pendingPatent = PendingPatent {
                patronItem: in.senderAddress,
                patronOwner: msg.patronOwner,
                targetRank: msg.targetRank,
                coSponsored: false,
                grantedAt: msg.grantedAt,
            }.toCell();
            storage.save();
            // The remaining grant value stays as rent.
        }

        PatentRejected => {
            var storage = loadLiveStorage();
            assert (
                in.senderAddress == siblingItemAddress(storage.registry, msg.candidateOwner)
            ) throw ItemErr.NotTitleItem;
            // 1:1 with a real decrement — items only reject grants this item actually sent.
            storage.budget += 1;
            storage.save();
        }

        CoSponsor => {
            val storage = loadLiveStorage();
            assert (in.senderAddress == storage.owner) throw ItemErr.NotOwner;
            assert (in.valueCoins >= 2 * GAS_MARGIN) throw ItemErr.InsufficientValue;
            assert (storage.revokedAt == 0) throw ItemErr.AlreadyRevoked;
            val sponsorMsg = createMessage({
                bounce: true,
                dest: siblingItemAddress(storage.registry, msg.candidate),
                value: 0,
                body: CoSponsorGrant {
                    queryId: msg.queryId,
                    sponsorOwner: storage.owner,
                    sponsorRank: storage.rank,
                },
            });
            sponsorMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        CoSponsorGrant => {
            var storage = loadLiveStorage();
            assert (
                in.senderAddress == siblingItemAddress(storage.registry, msg.sponsorOwner)
            ) throw ItemErr.NotTitleItem;
            assert (storage.pendingPatent != null) throw ItemErr.NoPatent;
            var pending = storage.pendingPatent!.load();
            assert (
                blockchain.now() < pending.grantedAt + PATENT_EXPIRY
            ) throw ItemErr.PatentExpired;
            assert (msg.sponsorRank >= pending.targetRank) throw ItemErr.SponsorRankTooLow;
            assert (msg.sponsorOwner != pending.patronOwner) throw ItemErr.SponsorRankTooLow;
            pending.coSponsored = true;
            storage.pendingPatent = pending.toCell();
            storage.save();
            emitMeritFor(msg.sponsorOwner, MERIT_KIND_CO_SPONSORSHIP, 0);
        }

        AcceptPatent => {
            val storage = loadLiveStorage();
            assert (in.senderAddress == storage.owner) throw ItemErr.NotOwner;
            assert (storage.pendingPatent != null) throw ItemErr.NoPatent;
            val pending = storage.pendingPatent!.load();
            assert (
                blockchain.now() < pending.grantedAt + PATENT_EXPIRY
            ) throw ItemErr.PatentExpired;
            assert (
                pending.targetRank < RANK_COUNT || pending.coSponsored
            ) throw ItemErr.NeedsCoSponsor;
            // The registry is the final gate (fees, bootstrap); a bounce refunds the owner.
            val feeMsg = createMessage({
                bounce: true,
                dest: storage.registry,
                value: 0,
                body: PatentFee {
                    queryId: msg.queryId,
                    owner: storage.owner,
                    currentRank: storage.rank,
                    targetRank: pending.targetRank,
                },
            });
            feeMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        PatentApproved => {
            val loader = ItemStorage.startLoading();
            assert (in.senderAddress == loader.registry) throw ItemErr.NotRegistry;
            var storage = loader.endLoading();
            if (storage.pendingPatent == null) {
                // Race guard: a reclaim landed while the fee was in flight. Fail closed
                // against patent inflation (the patron's budget was already restored).
                refundAllToOwner(storage.owner, msg.queryId);
                return;
            }
            val pending = storage.pendingPatent!.load();
            if (pending.targetRank != msg.targetRank) {
                refundAllToOwner(storage.owner, msg.queryId);
                return;
            }
            storage.rank = msg.targetRank;
            storage.budget = msg.newBudget;
            storage.patron = pending.patronItem;
            storage.pendingPatent = null;
            storage.merit += msg.fee;
            storage.save();
            storage.emitMerit(msg.targetRank, msg.fee);
            refundAllToOwner(storage.owner, msg.queryId);
        }

        ReclaimPatent => {
            val storage = loadLiveStorage();
            assert (in.senderAddress == storage.owner) throw ItemErr.NotOwner;
            assert (in.valueCoins >= 2 * GAS_MARGIN) throw ItemErr.InsufficientValue;
            val reclaimMsg = createMessage({
                bounce: true,
                dest: siblingItemAddress(storage.registry, msg.candidate),
                value: 0,
                body: PatentReclaim {
                    queryId: msg.queryId,
                    patronOwner: storage.owner,
                },
            });
            reclaimMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        PatentReclaim => {
            // Works on revoked/destroyed candidates too — the patron must be able to
            // recover the patent regardless of the candidate's fate.
            val loader = ItemStorage.startLoading();
            assert (loader.isInitialized()) throw ItemErr.NotInitialized;
            var storage = loader.endLoading();
            assert (
                in.senderAddress == siblingItemAddress(storage.registry, msg.patronOwner)
            ) throw ItemErr.NotTitleItem;
            assert (storage.pendingPatent != null) throw ItemErr.NoPatent;
            val pending = storage.pendingPatent!.load();
            assert (pending.patronItem == in.senderAddress) throw ItemErr.NotTitleItem;
            assert (
                blockchain.now() >= pending.grantedAt + PATENT_EXPIRY
            ) throw ItemErr.PatentNotExpired;
            storage.pendingPatent = null;
            storage.save();
            val returnMsg = createMessage({
                bounce: false,
                dest: in.senderAddress,
                value: 0,
                body: PatentReturned {
                    queryId: msg.queryId,
                    candidateOwner: storage.owner,
                },
            });
            returnMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        PatentReturned => {
            var storage = loadLiveStorage();
            assert (
                in.senderAddress == siblingItemAddress(storage.registry, msg.candidateOwner)
            ) throw ItemErr.NotTitleItem;
            storage.budget += 1;
            storage.save();
        }

        RevokeVassal => {
            val storage = loadLiveStorage();
            assert (in.senderAddress == storage.owner) throw ItemErr.NotOwner;
            assert (in.valueCoins >= 2 * GAS_MARGIN) throw ItemErr.InsufficientValue;
            assert (storage.revokedAt == 0) throw ItemErr.AlreadyRevoked;
            val revokeMsg = createMessage({
                bounce: true,
                dest: siblingItemAddress(storage.registry, msg.vassal),
                value: 0,
                body: RevokeByPatron {
                    queryId: msg.queryId,
                    patronOwner: storage.owner,
                    reason: msg.reason,
                },
            });
            revokeMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        RevokeByPatron => {
            var storage = loadLiveStorage();
            assert (
                in.senderAddress == siblingItemAddress(storage.registry, msg.patronOwner)
            ) throw ItemErr.NotTitleItem;
            // Only the direct patron may revoke (architecture §5).
            assert (in.senderAddress == storage.patron) throw ItemErr.NotPatron;
            assert (storage.revokedAt == 0) throw ItemErr.AlreadyRevoked;
            storage.revokedAt = blockchain.now();
            storage.save();
            createExternalLogMessage({
                dest: createAddressNone(),
                body: RevocationEvent {
                    vassal: storage.owner,
                    patronItem: in.senderAddress,
                    ts: blockchain.now(),
                    reason: msg.reason,
                },
            }).send(SEND_MODE_REGULAR);
        }

        Repledge => {
            var storage = loadLiveStorage();
            assert (in.senderAddress == storage.owner) throw ItemErr.NotOwner;
            assert (storage.revokedAt == 0) throw ItemErr.AlreadyRevoked;
            // Citizens and Dukes have the Registry as patron — nothing to repledge.
            assert (
                storage.rank >= RANK_KNIGHT && storage.rank <= RANK_COUNT
            ) throw ItemErr.CannotRepledge;
            assert (msg.newPatron != storage.owner) throw ItemErr.CannotRepledge;
            // Overwrites any previous intent; approval resets.
            storage.pendingRepledge = PendingRepledge {
                newPatronOwner: msg.newPatron,
                approved: false,
                requestedAt: blockchain.now(),
            }.toCell();
            storage.save();
        }

        AcceptRepledge => {
            val storage = loadLiveStorage();
            assert (in.senderAddress == storage.owner) throw ItemErr.NotOwner;
            assert (in.valueCoins >= 2 * GAS_MARGIN) throw ItemErr.InsufficientValue;
            assert (storage.revokedAt == 0) throw ItemErr.AlreadyRevoked;
            // No patent is spent — repledge is not new issuance (architecture §5).
            val approveMsg = createMessage({
                bounce: true,
                dest: siblingItemAddress(storage.registry, msg.vassal),
                value: 0,
                body: RepledgeApproved {
                    queryId: msg.queryId,
                    patronOwner: storage.owner,
                    patronRank: storage.rank,
                },
            });
            approveMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        RepledgeApproved => {
            var storage = loadLiveStorage();
            assert (
                in.senderAddress == siblingItemAddress(storage.registry, msg.patronOwner)
            ) throw ItemErr.NotTitleItem;
            assert (storage.pendingRepledge != null) throw ItemErr.NoRepledge;
            var pending = storage.pendingRepledge!.load();
            assert (pending.newPatronOwner == msg.patronOwner) throw ItemErr.NoRepledge;
            assert (msg.patronRank >= storage.rank + 1) throw ItemErr.RankTooLow;
            pending.approved = true;
            storage.pendingRepledge = pending.toCell();
            storage.save();
        }

        FinalizeRepledge => {
            val storage = loadLiveStorage();
            assert (in.senderAddress == storage.owner) throw ItemErr.NotOwner;
            assert (storage.revokedAt == 0) throw ItemErr.AlreadyRevoked;
            assert (storage.pendingRepledge != null) throw ItemErr.NoRepledge;
            val pending = storage.pendingRepledge!.load();
            assert (pending.approved) throw ItemErr.NotApproved;
            // The registry validates and routes the fee; a bounce refunds the owner.
            val feeMsg = createMessage({
                bounce: true,
                dest: storage.registry,
                value: 0,
                body: RepledgeFee {
                    queryId: msg.queryId,
                    owner: storage.owner,
                    rank: storage.rank,
                },
            });
            feeMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        RepledgeDone => {
            val loader = ItemStorage.startLoading();
            assert (in.senderAddress == loader.registry) throw ItemErr.NotRegistry;
            var storage = loader.endLoading();
            if (storage.pendingRepledge == null) {
                refundAllToOwner(storage.owner, msg.queryId);
                return;
            }
            val pending = storage.pendingRepledge!.load();
            if (!pending.approved) {
                // Race guard: the intent was overwritten while the fee was in flight.
                refundAllToOwner(storage.owner, msg.queryId);
                return;
            }
            storage.patron = siblingItemAddress(storage.registry, pending.newPatronOwner);
            storage.pendingRepledge = null;
            storage.merit += msg.fee;
            storage.save();
            storage.emitMerit(MERIT_KIND_REPLEDGE, msg.fee);
            refundAllToOwner(storage.owner, msg.queryId);
        }

        ChainProve => {
            // Approver-paid, initiator-only cache short-circuit (title-item.md "Chain-proof
            // walk"): only this handler ever consults chainValidUntil for its own item.
            var storage = loadLiveStorage();
            assert (in.senderAddress == storage.owner) throw ItemErr.NotOwner;
            assert (in.valueCoins >= 4 * GAS_MARGIN) throw ItemErr.InsufficientValue;
            assert (storage.revokedAt == 0) throw ItemErr.AlreadyRevoked;

            if (storage.patron == storage.registry) {
                // Genuine, fresh top (Citizen or Duke) — zero hops, safe to (re-)cache.
                storage.chainValidUntil = blockchain.now() + PROOF_TTL;
                storage.save();
                val proofMsg = createMessage({
                    bounce: false,
                    dest: msg.dest,
                    value: 0,
                    body: ChainProof {
                        queryId: msg.queryId,
                        topOwner: storage.owner,
                        topRank: storage.rank,
                        initiatorOwner: storage.owner,
                        initiatorRank: storage.rank,
                        payload: msg.payload,
                        cached: false,
                        merit: storage.merit,
                    },
                });
                proofMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
                return;
            }
            if (storage.chainValidUntil > blockchain.now()) {
                // Reuse the cache; never extend it here (architecture §5).
                val proofMsg = createMessage({
                    bounce: false,
                    dest: msg.dest,
                    value: 0,
                    body: ChainProof {
                        queryId: msg.queryId,
                        topOwner: storage.owner,
                        topRank: storage.rank,
                        initiatorOwner: storage.owner,
                        initiatorRank: storage.rank,
                        payload: msg.payload,
                        cached: true,
                        merit: storage.merit,
                    },
                });
                proofMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
                return;
            }
            val hopMsg = createMessage({
                bounce: false,
                dest: storage.patron,
                value: 0,
                body: ChainProveHop {
                    queryId: msg.queryId,
                    dest: msg.dest,
                    initiatorOwner: storage.owner,
                    initiatorRank: storage.rank,
                    hopCount: 1,
                    linkOwner: storage.owner,
                    payload: msg.payload,
                },
            });
            hopMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        ChainProveHop => {
            var storage = loadLiveStorage();
            assert (
                in.senderAddress == siblingItemAddress(storage.registry, msg.linkOwner)
            ) throw ItemErr.NotTitleItem;
            // Fail-closed: any revoked ancestor throws here; the whole walk dies, no recovery.
            assert (storage.revokedAt == 0) throw ItemErr.AlreadyRevoked;

            if (storage.patron == storage.registry) {
                // Genuine top (a Duke; Citizens never have vassals so never appear here) —
                // a real walk just completed through this item, safe to extend its cache.
                storage.chainValidUntil = blockchain.now() + PROOF_TTL;
                storage.save();
                // Two sends this transaction (ChainProof to dest, CacheOk to the initiator's
                // own item): the codebase's fan-out idiom (reserve, fixed send, sweep send)
                // is used instead of stacking two CARRY_ALL_REMAINING_MESSAGE_VALUE (mode 64)
                // sends, which would double-count the inbound value in one action phase.
                reserveToncoinsOnBalance(0, RESERVE_MODE_INCREASE_BY_ORIGINAL_BALANCE);
                val cacheMsg = createMessage({
                    bounce: false,
                    dest: siblingItemAddress(storage.registry, msg.initiatorOwner),
                    value: GAS_MARGIN,
                    body: CacheOk {
                        queryId: msg.queryId,
                        topOwner: storage.owner,
                    },
                });
                cacheMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
                val proofMsg = createMessage({
                    bounce: false,
                    dest: msg.dest,
                    value: 0,
                    body: ChainProof {
                        queryId: msg.queryId,
                        topOwner: storage.owner,
                        topRank: storage.rank,
                        initiatorOwner: msg.initiatorOwner,
                        initiatorRank: msg.initiatorRank,
                        payload: msg.payload,
                        cached: false,
                        merit: storage.merit,
                    },
                });
                // SAFETY: CARRY_ALL_BALANCE runs after reserving the original balance and the
                // fixed CacheOk send above, so only the true remainder rides to `dest`.
                proofMsg.send(SEND_MODE_CARRY_ALL_BALANCE);
                return;
            }
            // Caps the walk at 5 ChainProveHop messages total (architecture §6).
            assert (msg.hopCount < 5) throw ItemErr.ChainTooDeep;
            val hopMsg = createMessage({
                bounce: false,
                dest: storage.patron,
                value: 0,
                body: ChainProveHop {
                    queryId: msg.queryId,
                    dest: msg.dest,
                    initiatorOwner: msg.initiatorOwner,
                    initiatorRank: msg.initiatorRank,
                    hopCount: msg.hopCount + 1,
                    linkOwner: storage.owner,
                    payload: msg.payload,
                },
            });
            hopMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        CacheOk => {
            // Only ever sent by a ChainProveHop finalize at a genuine top; no owner refund,
            // no merit event (that is the consuming gate's job, not the walk's).
            var storage = loadLiveStorage();
            assert (
                in.senderAddress == siblingItemAddress(storage.registry, msg.topOwner)
            ) throw ItemErr.NotTitleItem;
            storage.chainValidUntil = blockchain.now() + PROOF_TTL;
            storage.save();
        }

        ProveOwnership => {
            val storage = loadLiveStorage();
            assert (in.senderAddress == storage.owner) throw ItemErr.NotOwner;
            val proofMsg = createMessage({
                bounce: true,
                dest: msg.dest,
                value: 0,
                body: OwnershipProof {
                    queryId: msg.queryId,
                    itemId: storage.itemId(),
                    owner: storage.owner,
                    data: msg.forwardPayload,
                    revokedAt: storage.revokedAt as uint64,
                    content: msg.withContent ? rankContent(storage.rank) : null,
                },
            });
            proofMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        RequestOwner => {
            val storage = loadLiveStorage();
            val infoMsg = createMessage({
                bounce: true,
                dest: msg.dest,
                value: 0,
                body: OwnerInfo {
                    queryId: msg.queryId,
                    itemId: storage.itemId(),
                    initiator: in.senderAddress,
                    owner: storage.owner,
                    data: msg.forwardPayload,
                    revokedAt: storage.revokedAt as uint64,
                    content: msg.withContent ? rankContent(storage.rank) : null,
                },
            });
            infoMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        Revoke => {
            var storage = loadLiveStorage();
            assert (in.senderAddress == storage.registry) throw ItemErr.NotRegistry;
            assert (storage.revokedAt == 0) throw ItemErr.AlreadyRevoked;
            storage.revokedAt = blockchain.now();
            storage.save();
        }

        Destroy => {
            var storage = loadLiveStorage();
            assert (in.senderAddress == storage.owner) throw ItemErr.NotOwner;
            if (storage.revokedAt == 0) {
                storage.revokedAt = blockchain.now();
            }
            storage.rank = DESTROYED_RANK;
            storage.save();
            val excessesMsg = createMessage({
                bounce: false,
                dest: storage.owner,
                value: 0,
                body: Excesses { queryId: msg.queryId },
            });
            excessesMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        NftTransfer => {
            // Soulbound: transfer is rejected from any sender in any state.
            throw ItemErr.Soulbound;
        }

        else => {
            // Empty body = rent top-up, accepted in any state.
            assert (in.body.isEmpty()) throw ItemErr.InvalidMessage;
        }
    }
}

type ItemBounceable = OwnershipProof | GrantPatent | PatentFee | RepledgeFee

fun onBouncedMessage(in: InMessageBounced) {
    in.bouncedBody.skipBouncedPrefix();
    // Only 256 bits of the bounced body are available: opcode + queryId.
    val msg = lazy ItemBounceable.fromSlice(in.bouncedBody);
    match (msg) {
        OwnershipProof => {
            // Per TEP-85: a bounced ownership_proof is re-sent to the owner.
            val loader = ItemStorage.startLoading();
            if (!loader.isInitialized()) {
                return;
            }
            val storage = loader.endLoading();
            val reproofMsg = createMessage({
                bounce: false,
                dest: storage.owner,
                value: 0,
                body: OwnershipProof {
                    queryId: msg.queryId,
                    itemId: storage.itemId(),
                    owner: storage.owner,
                    data: createEmptyCell(), // forward payload is lost in a 256-bit bounce
                    revokedAt: storage.revokedAt as uint64,
                    content: null,
                },
            });
            reproofMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }
        GrantPatent => {
            // The candidate item was undeployed (or died): restore the spent patent.
            val loader = ItemStorage.startLoading();
            if (!loader.isInitialized()) {
                return;
            }
            var storage = loader.endLoading();
            storage.budget += 1;
            storage.save();
        }
        PatentFee => {
            // The registry rejected the promotion (fee/transition/pause): refund the owner;
            // the pending patent stays for a retry.
            val loader = ItemStorage.startLoading();
            if (!loader.isInitialized()) {
                return;
            }
            val storage = loader.endLoading();
            refundAllToOwner(storage.owner, msg.queryId);
        }
        RepledgeFee => {
            // The registry rejected the repledge fee: refund the owner; intent stays.
            val loader = ItemStorage.startLoading();
            if (!loader.isInitialized()) {
                return;
            }
            val storage = loader.endLoading();
            refundAllToOwner(storage.owner, msg.queryId);
        }
        else => {}
    }
}

// TEP-62/85 getters (standard names and shapes).

get fun get_nft_data(): (bool, uint256, address, any_address, cell) {
    val loader = ItemStorage.startLoading();
    if (!loader.isInitialized()) {
        val (_, hash) = loader.owner.getWorkchainAndHash();
        return (false, hash, loader.registry, loader.owner as any_address, createEmptyCell());
    }
    val s = loader.endLoading();
    if (s.rank == DESTROYED_RANK) {
        return (true, s.itemId(), s.registry, createAddressNone(), createEmptyCell());
    }
    return (true, s.itemId(), s.registry, s.owner as any_address, rankContent(s.rank));
}

get fun get_authority_address(): any_address {
    val loader = ItemStorage.startLoading();
    if (!loader.isInitialized()) {
        return loader.registry as any_address;
    }
    val s = loader.endLoading();
    return s.rank == DESTROYED_RANK ? createAddressNone() : s.registry as any_address;
}

get fun get_revoked_time(): int {
    val loader = ItemStorage.startLoading();
    return loader.isInitialized() ? loader.endLoading().revokedAt : 0;
}
