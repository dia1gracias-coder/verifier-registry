import "@stdlib/reflection"
import "../common/consts"
import "../common/dedust"
import "../common/errors"
import "../desk/desk-messages"
import "../desk/desk-types"
import "../vendor/jetton/messages"
import "pot-messages"
import "pot-types"

contract Pot {
    author: "GRAMDESKS"
    version: "0.1.0"
    description: "Protocol pot: receives TON (royalties, mint surcharge, launcher share), converts to USDT, buys stock in rounds through a whitelisted escrow, and accounts per-desk shares with cumulative counters."
    storage: PotStorage
    incomingMessages: AllowedMessageToPot
}

type AllowedMessageToPot =
    | RegisterDesk
    | SweepRequest
    | WithdrawViaPot
    | TransferNotificationForRecipient
    | Convert
    | Round
    | CancelPending
    | SkipSlot
    | AddSlot
    | SetSlotEnabled
    | SetSlotFloor
    | SetPotParams
    | SetPotRoles
    | PotTopUp
    | ReturnExcessesBack
    | DedustPayout

/// Value kept by the Pot from a keeper Round message for its own compute.
const ROUND_KEEPER_GAS = ton("0.02")
/// Value kept by the Pot from a keeper Convert message for its own compute; the rest funds the DEX chain.
const CONVERT_KEEPER_GAS = ton("0.02")

fun emitEvent<T>(topic: int, body: T) {
    val ev = createExternalLogMessage({
        dest: ExtOutLogBucket { topic: topic as uint248 },
        body,
    });
    ev.send(SEND_MODE_REGULAR);
}

fun PotStorage.snapshotCounters(self): map<uint8, uint128> {
    var stamps: map<uint8, uint128> = createEmptyMap();
    var r = self.slots.findFirst();
    while (r.isFound) {
        val slot = r.loadValue();
        stamps.set(r.getKey(), slot.counter);
        r = self.slots.iterateNext(r);
    }
    return stamps;
}

/// Returns the slot id whose Pot jetton wallet is `wallet`, or -1.
fun PotStorage.findSlotByWallet(self, wallet: address): int {
    var r = self.slots.findFirst();
    while (r.isFound) {
        val slot = r.loadValue();
        if (slot.potWallet == wallet) {
            return r.getKey();
        }
        r = self.slots.iterateNext(r);
    }
    return -1;
}

/// Moves `rotationNext` to the next enabled slot (cyclic). Leaves it unchanged if none.
fun PotStorage.advanceRotation(mutate self) {
    if (self.slotCount == 0) {
        return;
    }
    var i = 1;
    while (i <= self.slotCount) {
        val candidate = ((self.rotationNext + i) % self.slotCount) as uint8;
        val found = self.slots.get(candidate);
        if (found.isFound && found.loadValue().enabled) {
            self.rotationNext = candidate;
            return;
        }
        i += 1;
    }
}

fun PotStorage.assertFromDesk(self, roles: PotRoles, serial: uint32, sender: address) {
    val desk = calcDeployedDesk(serial, roles.collection, roles.deskItemCode);
    assert (desk.addressMatches(sender)) throw Errors.NotFromDesk;
}

/// Reserve everything the Pot owned before this message so that only the incoming value can leave.
fun reserveOwnBalance(incomingValue: coins) {
    reserveToncoinsOnBalance(contract.getOriginalBalance() - incomingValue, RESERVE_MODE_EXACT_AMOUNT);
}

fun onInternalMessage(in: InMessage) {
    var storage = lazy PotStorage.load();
    val msg = lazy AllowedMessageToPot.fromSlice(in.body);

    match (msg) {
        RegisterDesk => {
            val roles = lazy storage.roles.load();
            assert (in.senderAddress == roles.collection) throw Errors.NotFromCollection;
            storage.liveDesks += 1;
            val stamps = storage.snapshotCounters();
            storage.save();
            val desk = calcDeployedDesk(msg.serial, roles.collection, roles.deskItemCode);
            val initMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: desk.calculateAddress(),
                value: 0,
                body: StampsInit { queryId: msg.queryId, stamps },
            });
            initMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        SweepRequest => {
            val roles = lazy storage.roles.load();
            storage.assertFromDesk(roles, msg.serial, in.senderAddress);
            val found = storage.slots.get(msg.slot);
            assert (found.isFound) throw Errors.SlotUnknown;
            val slot = found.loadValue();
            val owed = slot.counter > msg.stamp ? (slot.counter - msg.stamp) / COUNTER_SCALE : 0;

            emitEvent(EVENT_TOPIC_DESK_SWEPT, DeskSweptEvent { serial: msg.serial, slot: msg.slot, owed, newStamp: slot.counter });
            reserveOwnBalance(in.valueCoins);
            if (owed > 0) {
                val transfer = createMessage({
                    bounce: BounceMode.Only256BitsOfBody,
                    dest: slot.potWallet,
                    value: POT_JETTON_TRANSFER_VALUE,
                    body: AskToTransfer {
                        queryId: msg.queryId,
                        jettonAmount: owed,
                        transferRecipient: in.senderAddress,
                        sendExcessesTo: in.senderAddress,
                        customPayload: null,
                        forwardTonAmount: 0,
                        forwardPayload: emptyForwardPayload(),
                    },
                });
                transfer.send(SEND_MODE_PAY_FEES_SEPARATELY);
            }
            val ack = createMessage({
                bounce: BounceMode.NoBounce,
                dest: in.senderAddress,
                value: 0,
                body: SweepAck { queryId: msg.queryId, slot: msg.slot, newStamp: slot.counter },
            });
            ack.send(SEND_MODE_CARRY_ALL_BALANCE);
        }

        WithdrawViaPot => {
            val roles = lazy storage.roles.load();
            storage.assertFromDesk(roles, msg.serial, in.senderAddress);
            val found = storage.slots.get(msg.slot);
            assert (found.isFound) throw Errors.SlotUnknown;
            val slot = found.loadValue();
            assert (slot.counter == msg.stamp) throw Errors.RoundOwed;
            emitEvent(EVENT_TOPIC_DESK_WITHDRAWN, DeskWithdrawnEvent { serial: msg.serial, slot: msg.slot, amount: msg.amount, to: msg.to });
            val ok = createMessage({
                bounce: BounceMode.NoBounce,
                dest: in.senderAddress,
                value: 0,
                body: WithdrawOk {
                    queryId: msg.queryId,
                    slot: msg.slot,
                    jettonWallet: msg.jettonWallet,
                    amount: msg.amount,
                    to: msg.to,
                },
            });
            ok.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        TransferNotificationForRecipient => {
            val params = lazy storage.params.load();
            val pending = storage.pending != null ? storage.pending.load() : null;

            if (params.usdtWallet != null && in.senderAddress == params.usdtWallet) {
                storage.usdtBudget += msg.jettonAmount;
                if (pending != null && pending.kind == PENDING_CONVERT) {
                    emitEvent(EVENT_TOPIC_CONVERT_SETTLED, ConvertSettledEvent {
                        spendTon: pending.spend,
                        receivedUsdt: msg.jettonAmount,
                        minUsdt: pending.minOut,
                    });
                    if (msg.jettonAmount < pending.minOut) {
                        emitEvent(EVENT_TOPIC_SLIPPAGE_BREACH, SlippageBreachEvent {
                            kind: PENDING_CONVERT,
                            slot: 0,
                            expectedMin: pending.minOut,
                            received: msg.jettonAmount,
                        });
                    }
                    storage.pending = null;
                } else if (pending != null && pending.kind == PENDING_ROUND) {
                    emitEvent(EVENT_TOPIC_ROUND_REFUNDED, RoundRefundedEvent {
                        slot: pending.slot,
                        spendUsdt: pending.spend,
                        refunded: msg.jettonAmount,
                    });
                    storage.pending = null;
                } else {
                    emitEvent(EVENT_TOPIC_POT_IN, PotInEvent {
                        source: 255,
                        amount: msg.jettonAmount,
                        from: in.senderAddress,
                    });
                }
                storage.save();
                return;
            }

            val slotId = storage.findSlotByWallet(in.senderAddress);
            assert (slotId >= 0) throw Errors.UnknownJettonWallet;
            var slot = storage.slots.mustGet(slotId as uint8);

            if (storage.liveDesks == 0) {
                emitEvent(EVENT_TOPIC_UNALLOCATED, UnallocatedEvent { slot: slotId as uint8, amount: msg.jettonAmount });
                return;
            }

            slot.counter += ((msg.jettonAmount * COUNTER_SCALE) / storage.liveDesks) as uint128;
            storage.slots.set(slotId as uint8, slot);

            var spendUsdt: coins = 0;
            if (pending != null && pending.kind == PENDING_ROUND && pending.slot == slotId) {
                spendUsdt = pending.spend;
                storage.roundNo += 1;
                if (pending.advance) {
                    storage.advanceRotation();
                }
                if (msg.jettonAmount < pending.minOut) {
                    emitEvent(EVENT_TOPIC_SLIPPAGE_BREACH, SlippageBreachEvent {
                        kind: PENDING_ROUND,
                        slot: slotId as uint8,
                        expectedMin: pending.minOut,
                        received: msg.jettonAmount,
                    });
                }
                storage.pending = null;
            }
            emitEvent(EVENT_TOPIC_ROUND_SETTLED, RoundSettledEvent {
                roundNo: storage.roundNo,
                slot: slotId as uint8,
                spendUsdt,
                received: msg.jettonAmount,
                liveDesks: storage.liveDesks,
                counter: slot.counter,
            });
            storage.save();
        }

        Convert => {
            val roles = lazy storage.roles.load();
            assert (in.senderAddress == roles.keeper) throw Errors.NotFromKeeper;
            assert (storage.pending == null) throw Errors.OperationInFlight;
            val params = lazy storage.params.load();
            assert (params.usdtWallet != null) throw Errors.UsdtWalletUnset;
            val wl = lazy params.whitelist.load();
            assert (wl.dexPools.exists(msg.pool)) throw Errors.DestNotWhitelisted;
            val available = contract.getOriginalBalance() - in.valueCoins - params.reserve;
            assert (msg.spend >= params.threshold) throw Errors.BelowThreshold;
            assert (msg.spend <= available && msg.spend <= params.maxConvertTon) throw Errors.BudgetExceeded;
            // price floor: the keeper cannot accept less USDT per TON than the admin allows
            assert (params.floorUsdtPerTon > 0 && msg.minUsdt * TON_ONE >= msg.spend * params.floorUsdtPerTon) throw Errors.BelowFloor;
            // the keeper pays the DEX gas chain (vault -> pool -> jetton transfer back to us)
            assert (in.valueCoins >= DEDUST_SWAP_GAS + CONVERT_KEEPER_GAS) throw Errors.InsufficientValue;

            storage.totalTonSpent += msg.spend;
            storage.pending = Pending {
                kind: PENDING_CONVERT,
                slot: 0,
                spend: msg.spend,
                minOut: msg.minUsdt,
                startedAt: blockchain.now() as uint32,
                advance: false,
            }.toCell();
            storage.save();

            // receiver and limit are ours: a compromised keeper can only pick a whitelisted pool and a bounded price
            val swap = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: wl.dexVault,
                value: msg.spend + in.valueCoins - CONVERT_KEEPER_GAS,
                body: buildDedustNativeSwap(msg.queryId, msg.spend, msg.pool, msg.minUsdt, contract.getAddress()),
            });
            swap.send(SEND_MODE_PAY_FEES_SEPARATELY);
        }

        Round => {
            val roles = lazy storage.roles.load();
            assert (in.senderAddress == roles.keeper) throw Errors.NotFromKeeper;
            assert (storage.pending == null) throw Errors.OperationInFlight;
            assert (storage.liveDesks > 0) throw Errors.NoLiveDesks;
            val params = lazy storage.params.load();
            assert (params.usdtWallet != null) throw Errors.UsdtWalletUnset;
            assert (msg.slot == storage.rotationNext) throw Errors.NotRotationNext;
            val found = storage.slots.get(msg.slot);
            assert (found.isFound) throw Errors.SlotUnknown;
            val slot = found.loadValue();
            assert (slot.enabled) throw Errors.SlotDisabled;
            assert (msg.spendUsdt > 0 && msg.spendUsdt <= storage.usdtBudget && msg.spendUsdt <= params.maxRoundUsdt) throw Errors.BudgetExceeded;
            assert (in.valueCoins >= msg.forwardTon + ROUND_KEEPER_GAS + ton("0.05")) throw Errors.InsufficientValue;
            // price floor: at least `floorPerUsdt` stock units per USDT spent
            assert (slot.floorPerUsdt > 0 && msg.minOut * USDT_ONE >= msg.spendUsdt * slot.floorPerUsdt) throw Errors.BelowFloor;

            val wl = lazy params.whitelist.load();
            var p = msg.escrowPayload.beginParse();
            assert (p.loadUint(32) == wl.escrowOp) throw Errors.DestNotWhitelisted;
            p.skipBits(wl.escrowOwnerBitOffset - 32);
            assert (p.loadAddress() == contract.getAddress()) throw Errors.PayloadOwnerMismatch;
            // the escrow enforces the resolver's minimum delivery: it must be at least what the keeper declared
            var mo = escrowMinOutCell(msg.escrowPayload, wl.escrowMinOutRef).beginParse();
            mo.skipBits(wl.escrowMinOutBitOffset);
            assert (mo.loadCoins() >= msg.minOut) throw Errors.PayloadMinOutMismatch;

            storage.usdtBudget -= msg.spendUsdt;
            storage.pending = Pending {
                kind: PENDING_ROUND,
                slot: msg.slot,
                spend: msg.spendUsdt,
                minOut: msg.minOut,
                startedAt: blockchain.now() as uint32,
                advance: msg.advance,
            }.toCell();
            storage.save();

            val transfer = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: params.usdtWallet,
                value: 0,
                body: AskToTransfer {
                    queryId: msg.queryId,
                    jettonAmount: msg.spendUsdt,
                    transferRecipient: wl.escrowMinter,
                    sendExcessesTo: contract.getAddress(),
                    customPayload: null,
                    forwardTonAmount: msg.forwardTon,
                    forwardPayload: beginCell().storeBool(true).storeRef(msg.escrowPayload).endCell().beginParse(),
                },
            });
            transfer.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        CancelPending => {
            val roles = lazy storage.roles.load();
            assert (in.senderAddress == roles.keeper) throw Errors.NotFromKeeper;
            assert (storage.pending != null) throw Errors.NothingPending;
            val pending = storage.pending.load();
            val params = lazy storage.params.load();
            assert (blockchain.now() >= pending.startedAt + params.pendingTimeout) throw Errors.PendingNotExpired;
            emitEvent(EVENT_TOPIC_PENDING_CANCELLED, PendingCancelledEvent {
                kind: pending.kind,
                slot: pending.slot,
                spend: pending.spend,
            });
            storage.pending = null;
            storage.save();
        }

        SkipSlot => {
            val roles = lazy storage.roles.load();
            assert (in.senderAddress == roles.keeper) throw Errors.NotFromKeeper;
            assert (storage.pending == null) throw Errors.OperationInFlight;
            val skipped = storage.rotationNext;
            storage.advanceRotation();
            emitEvent(EVENT_TOPIC_SLOT_SKIPPED, SlotSkippedEvent { slot: skipped, next: storage.rotationNext });
            storage.save();
        }

        AddSlot => {
            val roles = lazy storage.roles.load();
            assert (in.senderAddress == roles.admin) throw Errors.NotFromAdmin;
            assert (msg.slot < MAX_SLOTS) throw Errors.InvalidParams;
            assert (!storage.slots.exists(msg.slot)) throw Errors.SlotExists;
            storage.slots.set(msg.slot, Slot { master: msg.master, potWallet: msg.potWallet, enabled: true, counter: 0, floorPerUsdt: msg.floorPerUsdt });
            if (msg.slot >= storage.slotCount) {
                storage.slotCount = msg.slot + 1;
            }
            storage.save();
        }

        SetSlotEnabled => {
            val roles = lazy storage.roles.load();
            assert (in.senderAddress == roles.admin) throw Errors.NotFromAdmin;
            var slot = storage.slots.mustGet(msg.slot, Errors.SlotUnknown as int);
            slot.enabled = msg.enabled;
            storage.slots.set(msg.slot, slot);
            if (!msg.enabled && storage.rotationNext == msg.slot) {
                storage.advanceRotation();
            }
            storage.save();
        }

        SetSlotFloor => {
            val roles = lazy storage.roles.load();
            assert (in.senderAddress == roles.admin) throw Errors.NotFromAdmin;
            var slot = storage.slots.mustGet(msg.slot, Errors.SlotUnknown as int);
            slot.floorPerUsdt = msg.floorPerUsdt;
            storage.slots.set(msg.slot, slot);
            storage.save();
        }

        SetPotParams => {
            val roles = lazy storage.roles.load();
            assert (in.senderAddress == roles.admin) throw Errors.NotFromAdmin;
            storage.params = msg.params;
            storage.save();
        }

        SetPotRoles => {
            val roles = lazy storage.roles.load();
            assert (in.senderAddress == roles.admin) throw Errors.NotFromAdmin;
            storage.roles = msg.roles;
            storage.save();
        }

        PotTopUp => {
            storage.totalTonIn += in.valueCoins;
            storage.save();
            emitEvent(EVENT_TOPIC_POT_IN, PotInEvent { source: msg.source, amount: in.valueCoins, from: in.senderAddress });
        }

        ReturnExcessesBack => {
            // gas excesses from our own jetton transfers / swaps: keep silently
        }

        DedustPayout => {
            // TON back from the DEX vault. A rejected swap (limit / deadline) returns the whole amount:
            // the conversion did not happen, so the accounting is restored. Smaller payouts are leftover gas.
            val params = lazy storage.params.load();
            val wl = lazy params.whitelist.load();
            assert (in.senderAddress == wl.dexVault) throw Errors.DestNotWhitelisted;
            if (storage.pending != null) {
                val pending = storage.pending.load();
                if (pending.kind == PENDING_CONVERT && in.valueCoins + DEDUST_SWAP_GAS >= pending.spend) {
                    emitEvent(EVENT_TOPIC_PENDING_CANCELLED, PendingCancelledEvent { kind: PENDING_CONVERT, slot: 0, spend: pending.spend });
                    storage.totalTonSpent -= pending.spend;
                    storage.pending = null;
                    storage.save();
                }
            }
        }

        else => {
            // plain TON (royalties, DEX gas excess, donations): accept; unknown opcodes bounce.
            assert (in.body.isEmpty() || in.body.preloadUint(32) == 0) throw 0xFFFF;
            storage.totalTonIn += in.valueCoins;
            storage.save();
            emitEvent(EVENT_TOPIC_POT_IN, PotInEvent { source: 0, amount: in.valueCoins, from: in.senderAddress });
        }
    }
}

fun onBouncedMessage(in: InMessageBounced) {
    var storage = lazy PotStorage.load();
    in.bouncedBody.skipBouncedPrefix();
    val op = in.bouncedBody.loadUint(32);
    if (storage.pending == null) {
        return;
    }
    val pending = storage.pending.load();
    // The DEX rejected our swap message: TON came back, nothing was converted.
    if (pending.kind == PENDING_CONVERT && op != reflect.serializationPrefixOf<AskToTransfer>().0) {
        storage.totalTonSpent -= pending.spend;
        storage.pending = null;
        storage.save();
        return;
    }
    // Our USDT wallet refused the transfer (insufficient balance): budget is restored.
    if (pending.kind == PENDING_ROUND && op == reflect.serializationPrefixOf<AskToTransfer>().0) {
        storage.usdtBudget += pending.spend;
        storage.pending = null;
        storage.save();
    }
}

get fun get_pot_data(): PotDataReply {
    val storage = lazy PotStorage.load();
    return {
        liveDesks: storage.liveDesks,
        rotationNext: storage.rotationNext,
        slotCount: storage.slotCount,
        roundNo: storage.roundNo,
        totalTonIn: storage.totalTonIn,
        totalTonSpent: storage.totalTonSpent,
        usdtBudget: storage.usdtBudget,
        pending: storage.pending != null ? storage.pending.load() : null,
    };
}

get fun get_slot(slotId: int): Slot? {
    val storage = lazy PotStorage.load();
    val found = storage.slots.get(slotId as uint8);
    return found.isFound ? found.loadValue() : null;
}

get fun get_slots(): map<uint8, Slot> {
    val storage = lazy PotStorage.load();
    return storage.slots;
}

get fun get_roles(): PotRoles {
    val storage = lazy PotStorage.load();
    return storage.roles.load();
}

get fun get_params(): PotParams {
    val storage = lazy PotStorage.load();
    return storage.params.load();
}

/// Amount of stock a desk with `stamp` for `slotId` can sweep right now.
get fun get_owed(slotId: int, stamp: int): int {
    val storage = lazy PotStorage.load();
    val found = storage.slots.get(slotId as uint8);
    if (!found.isFound) {
        return 0;
    }
    val slot = found.loadValue();
    return slot.counter > stamp ? (slot.counter - stamp) / COUNTER_SCALE : 0;
}
