// MemberAccount: контракт участника. Транши в слотах 0..63, tsTON в собственном jetton-кошельке,
// stake/burn в пул, выплаты владельцу по I2/I3, форфейт и отчёты в Vault. DESIGN.md §3.2, §4, §7.3.

import "constants"
import "errors"
import "messages"
import "storage"
import "tonstakers"

contract MemberAccount {
    author: "lock-in-wallet"
    version: "0.1.0"
    description: "Lock-in Wallet member account: tranches, tsTON position, exits"
    storage: AccountStorage
    incomingMessages: AccountMessage
}

type AccountMessage =
    | CreditTranche
    | ExitAck
    | ExitRejected
    | Withdraw
    | RetryExit
    | JettonTransferNotification
    | PoolWithdrawal
    | DistributedAsset
    | OwnershipAssigned
    | Excesses
    | TopUp

/// Сколько из приложенного к withdraw газа аккаунт оставляет себе на будущие служебные сообщения.
const ACCOUNT_OP_KEEP = ton("0.05")

// ---------- helpers ----------

fun AccountStorage.ensureWallet(mutate self): address {
    if (self.tstonWallet == null) {
        val params = self.params.load();
        self.tstonWallet = calcTsTonWalletAddress(
            contract.getAddress(),
            params.tstonMaster,
            params.tstonWalletCode,
        );
    }
    return self.tstonWallet!;
}

fun AccountStorage.pool(self): address {
    return self.params.load().pool;
}

fun sendToOwner<T>(owner: address, value: coins, body: T, sendMode: int) {
    val ownerMessage = createMessage({
        bounce: BounceMode.NoBounce,
        dest: owner,
        value,
        body,
    });
    ownerMessage.send(sendMode);
}

fun sendToVault<T>(vault: address, value: coins, body: T) {
    val vaultMessage = createMessage({
        bounce: BounceMode.NoBounce,
        dest: vault,
        value,
        body,
    });
    vaultMessage.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

/// Найти свободный слот (младший нулевой бит маски) или −1.
fun findFreeSlot(usedSlots: int): int {
    var slot = 0;
    while (slot < MAX_TRANCHES) {
        if (((usedSlots >> slot) & 1) == 0) {
            return slot;
        }
        slot += 1;
    }
    return -1;
}

/// Сжечь токены батча: burn на своём кошельке с явным value — пул вернёт его вместе с выплатой,
/// и аккаунт сможет отделить возврат газа от дохода (§7.3).
fun AccountStorage.sendBurn(mutate self, pending: PendingBatch, available: coins): PendingBatch {
    val wallet = self.ensureWallet();
    val value = max(available - BURN_TX_RESERVE, 0);
    val burn = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: wallet,
        value,
        body: JettonBurn {
            queryId: pending.batchId as uint64,
            jettonAmount: pending.tokensSum + pending.bonusTokens,
            responseDestination: self.owner,
            customPayload: BurnCustomPayload {
                waitTillRoundEnd: false,
                fillOrKill: false,
            }.toCell(),
        },
    });
    burn.send(SEND_MODE_PAY_FEES_SEPARATELY);
    var updated = pending;
    updated.burnSentAt = blockchain.now();
    updated.burnValue = value;
    return updated;
}

/// Вернуть транши батча в active и снять pending (exit_rejected или bounce exit_notice).
fun AccountStorage.rollbackPending(mutate self, pending: PendingBatch) {
    var mask = pending.slots;
    var slot = 0;
    while (mask != 0) {
        if ((mask & 1) == 1) {
            var t = self.tranches.mustGet(slot);
            t.status = TRANCHE_ACTIVE;
            self.tranches.set(slot, t);
        }
        mask >>= 1;
        slot += 1;
    }
    self.pending = null;
}

/// Выплата батча получена: заплатить владельцу по режиму, форфейт и отчёт — в Vault.
/// `gasBack` — часть `received`, которая является возвратом value burn, а не доходом.
fun AccountStorage.completeExit(
    mutate self,
    pending: PendingBatch,
    received: coins,
    gasBack: coins,
) {
    val returned = min(gasBack, received);
    val y = received - returned;
    var payout = y;
    var forfeit = 0;
    if (pending.mode == MODE_EARLY) {
        // I2: между окнами не больше principal, всё сверх — в котёл
        payout = min(y, pending.principalSum);
        forfeit = y - payout;
    }

    var mask = pending.slots;
    var slot = 0;
    while (mask != 0) {
        if ((mask & 1) == 1) {
            self.tranches.delete(slot);
        }
        mask >>= 1;
        slot += 1;
    }
    self.usedSlots &= ~pending.slots;
    self.pending = null;
    val hasTranches = self.usedSlots != 0;
    if (!hasTranches) {
        self.isMember = false;
    }

    val report: ExitReport = {
        queryId: pending.queryId,
        owner: self.owner,
        mode: pending.mode,
        slots: pending.slots,
        payout,
        forfeit,
        hasTranches,
    };
    if (payout + returned > 0) {
        sendToOwner(self.owner, payout + returned, report, SEND_MODE_PAY_FEES_SEPARATELY);
    }
    sendToVault(self.vault, forfeit + REPORT_GAS, report);
}

// ---------- bounces ----------

fun onBouncedMessage(in: InMessageBounced) {
    in.bouncedBody.skipBouncedPrefix();
    val op = in.bouncedBody.loadUint(32);
    val queryId = in.bouncedBody.loadUint(64);
    var storage = AccountStorage.load();

    if (op == 0x47d54391) {
        // deposit в пул отбит: удалить транш, вернуть TON владельцу, сообщить Vault
        val slot = queryId;
        val found = storage.tranches.get(slot);
        if (!found.isFound) {
            return;
        }
        val t = found.loadValue();
        storage.tranches.delete(slot);
        storage.usedSlots &= ~(1 << slot);
        storage.save();
        val cancelled: TrancheCancelled = {
            queryId: t.queryId,
            owner: storage.owner,
            principal: t.principal,
            slot: slot as uint8,
        };
        sendToVault(storage.vault, REPORT_GAS, cancelled);
        sendToOwner(
            storage.owner,
            in.valueCoins - REPORT_GAS - ton("0.01"),
            cancelled,
            SEND_MODE_PAY_FEES_SEPARATELY,
        );
        return;
    }

    if (op == 0x5b129b50) {
        // exit_notice отбит Vault'ом: откатить pending, газ — владельцу
        if (storage.pending != null) {
            storage.rollbackPending(storage.pending!.load());
            storage.save();
        }
        sendToOwner(
            storage.owner,
            0,
            ExitRejected {
                queryId,
                nextWindowAt: 0,
            },
            SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS,
        );
        return;
    }

    if (op == 0x595f07bc) {
        // burn отбит кошельком (нет баланса или газа): pending остаётся, повторить retry_exit
        sendToOwner(
            storage.owner,
            0,
            Excesses { queryId },
            SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS,
        );
        return;
    }
}

// ---------- messages ----------

fun onInternalMessage(in: InMessage) {
    val msg = lazy AccountMessage.fromSlice(in.body);

    match (msg) {
        CreditTranche => {
            var storage = AccountStorage.load();
            assert (in.senderAddress == storage.vault) throw Errors.NotVault;
            storage.ensureWallet();

            val slot = findFreeSlot(storage.usedSlots);
            if (slot < 0) {
                // MAX_TRANCHES: не падать (bounce дороже), а вернуть TON и снять principal в Vault
                storage.save();
                val cancelled: TrancheCancelled = {
                    queryId: msg.queryId,
                    owner: storage.owner,
                    principal: msg.principal,
                    slot: 255,
                };
                sendToVault(storage.vault, REPORT_GAS, cancelled);
                sendToOwner(
                    storage.owner,
                    in.valueCoins - REPORT_GAS - ton("0.01"),
                    cancelled,
                    SEND_MODE_PAY_FEES_SEPARATELY,
                );
                return;
            }

            storage
                .tranches
                .set(
                    slot,
                    {
                        queryId: msg.queryId,
                        principal: msg.principal,
                        depositedAt: msg.depositedAt,
                        tokens: 0,
                        acc0: msg.acc0,
                        status: TRANCHE_STAKING,
                    },
                );
            storage.usedSlots |= 1 << slot;
            storage.save();

            // в пул уходит ровно P + 1 TON: любой лишний TON пул засчитал бы как депозит
            val stake = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: storage.pool(),
                value: msg.principal + POOL_DEPOSIT_FEE,
                body: PoolDeposit { queryId: slot },
            });
            stake.send(SEND_MODE_PAY_FEES_SEPARATELY);

            // остаток газа — владельцу, на балансе остаётся резерв на хранение
            val balanceBefore = contract.getOriginalBalance() - in.valueCoins;
            reserveToncoinsOnBalance(max(balanceBefore, ACCOUNT_MIN_BALANCE), RESERVE_MODE_AT_MOST);
            sendToOwner(
                storage.owner,
                0,
                Excesses { queryId: msg.queryId },
                SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS,
            );
        }

        JettonTransferNotification => {
            var storage = AccountStorage.load();
            val wallet = storage.ensureWallet();
            assert (in.senderAddress == wallet) throw Errors.NotTstonWallet;

            if (msg.from == null) {
                // tsTON от пула после stake: подтвердить транш (query_id == слот)
                if (msg.queryId >= MAX_TRANCHES) {
                    return;
                }
                val slot = msg.queryId as uint8;
                val found = storage.tranches.get(slot);
                if (!found.isFound) {
                    return;
                }
                var t = found.loadValue();
                if (t.status != TRANCHE_STAKING) {
                    return;
                }
                t.tokens = msg.jettonAmount;
                t.status = TRANCHE_ACTIVE;
                storage.tranches.set(slot, t);
                val first = !storage.isMember;
                storage.isMember = true;
                storage.save();
                sendToVault(
                    storage.vault,
                    REPORT_GAS,
                    TrancheActivated {
                        queryId: t.queryId,
                        owner: storage.owner,
                        slot,
                        principal: t.principal,
                        tokens: t.tokens,
                        first,
                    },
                );
                return;
            }

            if (msg.from! == storage.vault) {
                // бонус из котла: выход в окне подтверждён, сжечь транши + бонус
                if (storage.pending == null) {
                    return;
                }
                var pending = storage.pending!.load();
                if (pending.mode != MODE_AWAITING_ACK) {
                    return;
                }
                pending.mode = MODE_FULL;
                pending.bonusTokens = msg.jettonAmount;
                pending = storage.sendBurn(pending, in.valueCoins);
                storage.pending = pending.toCell();
                storage.save();
                return;
            }
            // чужой перевод tsTON: игнорируется
        }

        ExitAck => {
            var storage = AccountStorage.load();
            assert (in.senderAddress == storage.vault) throw Errors.NotVault;
            assert (storage.pending != null) throw Errors.NoPending;
            var pending = storage.pending!.load();
            assert (pending.mode == MODE_AWAITING_ACK) throw Errors.PendingExists;
            pending.mode = msg.mode;
            pending.bonusTokens = msg.bonus;
            pending = storage.sendBurn(pending, in.valueCoins);
            storage.pending = pending.toCell();
            storage.save();
        }

        ExitRejected => {
            var storage = AccountStorage.load();
            assert (in.senderAddress == storage.vault) throw Errors.NotVault;
            if (storage.pending != null) {
                storage.rollbackPending(storage.pending!.load());
                storage.save();
            }
            sendToOwner(
                storage.owner,
                0,
                ExitRejected {
                    queryId: msg.queryId,
                    nextWindowAt: msg.nextWindowAt,
                },
                SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS,
            );
        }

        Withdraw => {
            var storage = AccountStorage.load();
            assert (in.senderAddress == storage.owner) throw Errors.NotOwner;
            assert (in.valueCoins >= WITHDRAW_GAS) throw Errors.NotEnoughGas;
            assert (storage.pending == null) throw Errors.PendingExists;
            assert (msg.slots != 0 && (msg.slots & ~storage.usedSlots) == 0) throw Errors.BadSlots;

            // §7.3 п. 3: неатрибутированный TON сверх резерва уходит в котёл
            val balanceBefore = contract.getOriginalBalance() - in.valueCoins;
            val extra = balanceBefore - ACCOUNT_MIN_BALANCE;
            if (extra >= SWEEP_THRESHOLD) {
                sendToVault(
                    storage.vault,
                    extra,
                    Forfeit {
                        queryId: msg.queryId,
                        owner: storage.owner,
                        amount: extra - REPORT_GAS,
                    },
                );
            }

            var principalSum = 0;
            var tokensSum = 0;
            var debtSum = 0;
            var mask = msg.slots;
            var slot = 0;
            while (mask != 0) {
                if ((mask & 1) == 1) {
                    var t = storage.tranches.mustGet(slot);
                    assert (t.status == TRANCHE_ACTIVE) throw Errors.TrancheNotActive;
                    principalSum += t.principal;
                    tokensSum += t.tokens;
                    debtSum += t.principal * t.acc0;
                    t.status = TRANCHE_EXITING;
                    storage.tranches.set(slot, t);
                }
                mask >>= 1;
                slot += 1;
            }

            val batchId = storage.batchSeq;
            storage.batchSeq += 1;
            val pending: PendingBatch = {
                queryId: msg.queryId,
                slots: msg.slots,
                principalSum,
                tokensSum,
                debtSum,
                mode: MODE_AWAITING_ACK,
                bonusTokens: 0,
                batchId,
                createdAt: blockchain.now(),
                burnSentAt: 0,
                burnValue: 0,
            };
            storage.pending = pending.toCell();
            storage.save();

            val notice = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: storage.vault,
                value: in.valueCoins - ACCOUNT_OP_KEEP,
                body: ExitNotice {
                    queryId: msg.queryId,
                    owner: storage.owner,
                    slots: msg.slots,
                    principalSum,
                    debtSum,
                    forceEarly: msg.forceEarly,
                },
            });
            notice.send(SEND_MODE_PAY_FEES_SEPARATELY);
        }

        RetryExit => {
            var storage = AccountStorage.load();
            assert (in.senderAddress == storage.owner) throw Errors.NotOwner;
            assert (in.valueCoins >= RETRY_GAS) throw Errors.NotEnoughGas;
            assert (storage.pending != null) throw Errors.NoPending;
            var pending = storage.pending!.load();
            assert (pending.burnSentAt != 0) throw Errors.NoPending;
            assert (
                blockchain.now() >= pending.burnSentAt + RETRY_TIMEOUT
            ) throw Errors.RetryTooEarly;
            pending = storage.sendBurn(pending, in.valueCoins);
            storage.pending = pending.toCell();
            storage.save();
        }

        PoolWithdrawal => {
            // §7.3 п. 1: мгновенная выплата от пула с нашим query_id
            var storage = AccountStorage.load();
            if (in.senderAddress != storage.pool() || storage.pending == null) {
                return;
            }
            val pending = storage.pending!.load();
            if (pending.burnSentAt == 0 || msg.queryId != pending.batchId) {
                return;
            }
            // пул переносит остаток value burn в выплату: это возврат газа, а не доход
            storage.completeExit(pending, in.valueCoins, pending.burnValue);
            storage.save();
        }

        DistributedAsset => {
            // §7.3 п. 2: отложенная выплата от коллекции раунда, порог 0.9·P_sum
            var storage = AccountStorage.load();
            if (storage.pending == null) {
                return;
            }
            val pending = storage.pending!.load();
            if (pending.burnSentAt == 0) {
                return;
            }
            if (in.valueCoins * 100 < pending.principalSum * DEFERRED_PAYOUT_MIN_PERCENT) {
                return;
            }
            storage.completeExit(pending, in.valueCoins, 0);
            storage.save();
        }

        Excesses => {
            // возврат газа от пула или своего кошелька — владельцу; прочее остаётся на балансе
            val storage = AccountStorage.load();
            val fromWallet = storage.tstonWallet != null &&
            in.senderAddress == storage.tstonWallet!;
            if (in.senderAddress == storage.pool() || fromWallet) {
                sendToOwner(
                    storage.owner,
                    0,
                    Excesses { queryId: msg.queryId },
                    SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS,
                );
            }
        }

        OwnershipAssigned => {
            // payout-NFT отложенного вывода несёт остаток value burn — вернуть владельцу
            val storage = AccountStorage.load();
            if (storage.pending == null) {
                return;
            }
            val pending = storage.pending!.load();
            if (pending.burnSentAt == 0) {
                return;
            }
            sendToOwner(
                storage.owner,
                0,
                Excesses { queryId: msg.queryId },
                SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS,
            );
        }

        TopUp => {}

        else => {
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
        }
    }
}

// ---------- get-методы ----------

struct AccountDataReply {
    vault: address
    owner: address
    tstonWallet: address?
    usedSlots: uint64
    isMember: bool
    batchSeq: uint32
    balance: coins
}

get fun get_account_data(): AccountDataReply {
    val storage = AccountStorage.load();
    return {
        vault: storage.vault,
        owner: storage.owner,
        tstonWallet: storage.tstonWallet,
        usedSlots: storage.usedSlots,
        isMember: storage.isMember,
        batchSeq: storage.batchSeq,
        balance: contract.getOriginalBalance(),
    };
}

get fun get_tranches(): map<uint8, Tranche> {
    val storage = AccountStorage.load();
    return storage.tranches;
}

get fun get_pending(): PendingBatch? {
    val storage = AccountStorage.load();
    if (storage.pending == null) {
        return null;
    }
    return storage.pending!.load();
}
