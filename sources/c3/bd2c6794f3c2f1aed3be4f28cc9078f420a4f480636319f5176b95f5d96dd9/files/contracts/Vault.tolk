// Vault: конфиг капсулы, реестр участников, котёл (tsTON) и накопительный счётчик acc.
// DESIGN.md §3.1, §4. Администратора и апгрейда нет (I5).

import "constants"
import "errors"
import "messages"
import "storage"
import "tonstakers"
import "window"

contract Vault {
    author: "lock-in-wallet"
    version: "0.1.0"
    description: "Lock-in Wallet vault: schedule, member registry, cauldron (tsTON) with acc counter"
    storage: VaultStorage
    incomingMessages: VaultMessage
}

type VaultMessage =
    | Deposit
    | StakeForfeits
    | ExitNotice
    | TrancheCancelled
    | TrancheActivated
    | Forfeit
    | ExitReport
    | JettonTransferNotification
    | Excesses
    | TopUp

// ---------- helpers ----------

fun VaultStorage.accountInit(self, owner: address): AutoDeployAddress {
    return calcAccountInit(contract.getAddress(), owner, self.accountCode, self.accountParams);
}

fun VaultStorage.assertFromAccount(self, sender: address, owner: address) {
    assert (sender == self.accountInit(owner).calculateAddress()) throw Errors.NotMemberAccount;
}

fun VaultStorage.tstonWallet(self): address {
    val params = self.accountParams.load();
    return calcTsTonWalletAddress(
        contract.getAddress(),
        params.tstonMaster,
        params.tstonWalletCode,
    );
}

fun VaultStorage.window(self): WindowState {
    return calcWindowState(self.period, self.windowLength, self.epochStart, blockchain.now());
}

/// Разнести tsTON котла в acc (I4). Если активных вкладов нет — в unallocated до следующего раза.
fun VaultStorage.distribute(mutate self, tokens: coins) {
    if (self.totalPrincipal > 0) {
        val total = tokens + self.unallocated;
        self.acc += (total << ACC_SCALE_BITS) / self.totalPrincipal;
        self.unallocated = 0;
    } else {
        self.unallocated += tokens;
    }
}

/// Отправить накопленные форфейты в пул, если буфер ≥ FORFEIT_STAKE_MIN и хватает на комиссию пула.
fun VaultStorage.tryStakeForfeits(mutate self) {
    if (self.pendingStake != 0 || self.forfeitBuffer < FORFEIT_STAKE_MIN) {
        return;
    }
    val needed = self.forfeitBuffer + POOL_DEPOSIT_FEE + VAULT_MIN_BALANCE;
    if (contract.getOriginalBalance() < needed) {
        return;
    }
    val params = self.accountParams.load();
    val amount = self.forfeitBuffer;
    val stake = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: params.pool,
        value: amount + POOL_DEPOSIT_FEE,
        body: PoolDeposit { queryId: 0 },
    });
    stake.send(SEND_MODE_PAY_FEES_SEPARATELY);
    self.pendingStake = amount;
    self.forfeitBuffer = 0;
    emitLog(
        0x344b89ee,
        LogForfeitStaked {
            queryId: 0,
            amount,
        },
    );
}

fun sendExitAck(
    to: address,
    queryId: uint64,
    mode: int,
    bonus: coins,
    value: coins,
    sendMode: int,
) {
    val ack = createMessage({
        bounce: BounceMode.NoBounce,
        dest: to,
        value,
        body: ExitAck { queryId, mode, bonus },
    });
    ack.send(sendMode);
}

// ---------- bounces ----------

fun onBouncedMessage(in: InMessageBounced) {
    val prefix = in.bouncedBody.preloadUint(32);
    if (prefix == 0xffffffff) {
        // Only256BitsOfBody: единственный такой исходящий — deposit форфейтов в пул
        in.bouncedBody.skipBouncedPrefix();
        val op = in.bouncedBody.loadUint(32);
        if (op == 0x47d54391) {
            var storage = VaultStorage.load();
            storage.forfeitBuffer += storage.pendingStake;
            storage.pendingStake = 0;
            storage.save();
        }
        return;
    }

    val rich = lazy RichBounceBody.fromSlice(in.bouncedBody);
    var body = rich.originalBody.beginParse();
    val op = body.loadUint(32);
    var storage = VaultStorage.load();

    if (op == 0x5ce33f6f) {
        // credit_tranche отбит: вернуть principal из total_principal, TON — владельцу
        val queryId = body.loadUint(64);
        val principal = body.loadCoins();
        body.skipBits(128 + 32);
        val owner = body.loadAddress();
        storage.totalPrincipal = max(storage.totalPrincipal - principal, 0);
        storage.save();
        val refund = createMessage({
            bounce: BounceMode.NoBounce,
            dest: owner,
            value: 0,
            body: TrancheCancelled {
                queryId,
                owner,
                principal,
                slot: 255,
            },
        });
        refund.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS);
        emitLog(
            0x1da026e0,
            LogTrancheCancelled {
                queryId,
                owner,
                principal,
                slot: 255,
            },
        );
        return;
    }

    if (op == 0x0f8a7ea5) {
        // бонус-жетон не доставлен: вернуть токены в котёл, аккаунт разблокировать exit_ack{bonus=0}
        val queryId = body.loadUint(64);
        val bonus = body.loadCoins();
        val account = body.loadAddress();
        storage.distribute(bonus);
        storage.save();
        sendExitAck(
            account,
            queryId,
            MODE_FULL,
            0,
            0,
            SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE,
        );
        return;
    }
}

// ---------- messages ----------

fun onInternalMessage(in: InMessage) {
    val msg = lazy VaultMessage.fromSlice(in.body);

    match (msg) {
        Deposit => {
            assert (in.senderAddress.getWorkchain() == MY_WORKCHAIN) throw Errors.WrongWorkchain;
            assert (msg.amount >= MIN_DEPOSIT) throw Errors.DepositTooSmall;
            assert (
                in.valueCoins >= msg.amount + POOL_DEPOSIT_FEE + DEPOSIT_GAS
            ) throw Errors.NotEnoughGas;

            var storage = VaultStorage.load();
            storage.totalPrincipal += msg.amount;
            val now = blockchain.now();
            val accountInit = storage.accountInit(in.senderAddress);

            val credit = createMessage({
                bounce: BounceMode.RichBounce,
                dest: accountInit,
                value: in.valueCoins - VAULT_GAS_CUT,
                body: CreditTranche {
                    queryId: msg.queryId,
                    principal: msg.amount,
                    acc0: storage.acc,
                    depositedAt: now,
                    owner: in.senderAddress,
                },
            });
            credit.send(SEND_MODE_PAY_FEES_SEPARATELY);
            storage.save();

            emitLog(
                0x85b4434a,
                LogDeposited {
                    queryId: msg.queryId,
                    owner: in.senderAddress,
                    account: accountInit.calculateAddress(),
                    principal: msg.amount,
                },
            );
        }

        ExitNotice => {
            var storage = VaultStorage.load();
            storage.assertFromAccount(in.senderAddress, msg.owner);
            assert (storage.totalPrincipal >= msg.principalSum) throw Errors.PrincipalUnderflow;

            val window = storage.window();
            val remaining = storage.totalPrincipal - msg.principalSum;
            val full = window.isOpen || remaining == 0; // I6: последнему некому отдавать

            if (!full && !msg.forceEarly) {
                val rejected = createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: in.senderAddress,
                    value: in.valueCoins - VAULT_GAS_CUT,
                    body: ExitRejected {
                        queryId: msg.queryId,
                        nextWindowAt: window.nextWindowAt,
                    },
                });
                rejected.send(SEND_MODE_PAY_FEES_SEPARATELY);
                emitLog(
                    0x9f2b0f1e,
                    LogExitRejected {
                        queryId: msg.queryId,
                        owner: msg.owner,
                        nextWindowAt: window.nextWindowAt,
                    },
                );
                return;
            }

            var share = (msg.principalSum * storage.acc - msg.debtSum) >> ACC_SCALE_BITS;
            if (share < 0) {
                share = 0;
            }
            storage.totalPrincipal = remaining;

            if (full) {
                if (share > 0) {
                    val value = in.valueCoins - VAULT_GAS_CUT;
                    val transfer = createMessage({
                        bounce: BounceMode.RichBounce,
                        dest: storage.tstonWallet(),
                        value,
                        body: JettonTransfer {
                            queryId: msg.queryId,
                            jettonAmount: share,
                            destination: in.senderAddress,
                            responseDestination: in.senderAddress,
                            customPayload: null,
                            forwardTonAmount: value - JETTON_TRANSFER_RESERVE,
                            forwardPayload: beginCell().storeUint(0, 1).endCell().beginParse(),
                        },
                    });
                    transfer.send(SEND_MODE_PAY_FEES_SEPARATELY);
                } else {
                    sendExitAck(
                        in.senderAddress,
                        msg.queryId,
                        MODE_FULL,
                        0,
                        in.valueCoins - VAULT_GAS_CUT,
                        SEND_MODE_PAY_FEES_SEPARATELY,
                    );
                }
                emitLog(
                    0x72d5e9ca,
                    LogExitStarted {
                        queryId: msg.queryId,
                        owner: msg.owner,
                        mode: MODE_FULL,
                        slots: msg.slots,
                        principalSum: msg.principalSum,
                        bonus: share,
                    },
                );
            } else {
                // I2: доля котла ушедшего остаётся в котле и делится между оставшимися
                storage.distribute(share);
                sendExitAck(
                    in.senderAddress,
                    msg.queryId,
                    MODE_EARLY,
                    0,
                    in.valueCoins - VAULT_GAS_CUT,
                    SEND_MODE_PAY_FEES_SEPARATELY,
                );
                emitLog(
                    0x72d5e9ca,
                    LogExitStarted {
                        queryId: msg.queryId,
                        owner: msg.owner,
                        mode: MODE_EARLY,
                        slots: msg.slots,
                        principalSum: msg.principalSum,
                        bonus: 0,
                    },
                );
            }
            storage.save();
        }

        TrancheCancelled => {
            var storage = VaultStorage.load();
            storage.assertFromAccount(in.senderAddress, msg.owner);
            storage.totalPrincipal = max(storage.totalPrincipal - msg.principal, 0);
            storage.save();
            emitLog(
                0x1da026e0,
                LogTrancheCancelled {
                    queryId: msg.queryId,
                    owner: msg.owner,
                    principal: msg.principal,
                    slot: msg.slot,
                },
            );
        }

        TrancheActivated => {
            var storage = VaultStorage.load();
            storage.assertFromAccount(in.senderAddress, msg.owner);
            if (msg.first) {
                storage.memberCount += 1;
            }
            storage.save();
            emitLog(
                0xd4592eba,
                LogTrancheActivated {
                    queryId: msg.queryId,
                    owner: msg.owner,
                    slot: msg.slot,
                    principal: msg.principal,
                    tokens: msg.tokens,
                    memberJoined: msg.first,
                    memberCount: storage.memberCount,
                },
            );
        }

        Forfeit => {
            var storage = VaultStorage.load();
            storage.assertFromAccount(in.senderAddress, msg.owner);
            assert (in.valueCoins >= msg.amount) throw Errors.NotEnoughGas;
            storage.forfeitBuffer += msg.amount;
            storage.tryStakeForfeits();
            storage.save();
        }

        ExitReport => {
            var storage = VaultStorage.load();
            storage.assertFromAccount(in.senderAddress, msg.owner);
            assert (in.valueCoins >= msg.forfeit) throw Errors.NotEnoughGas;
            storage.forfeitBuffer += msg.forfeit;
            if (!msg.hasTranches && storage.memberCount > 0) {
                storage.memberCount -= 1;
            }
            storage.tryStakeForfeits();
            storage.save();
            emitLog(
                0x72208540,
                LogExited {
                    queryId: msg.queryId,
                    owner: msg.owner,
                    mode: msg.mode,
                    slots: msg.slots,
                    payout: msg.payout,
                    forfeit: msg.forfeit,
                    hasTranches: msg.hasTranches,
                    memberCount: storage.memberCount,
                },
            );
        }

        StakeForfeits => {
            var storage = VaultStorage.load();
            storage.tryStakeForfeits();
            storage.save();
        }

        JettonTransferNotification => {
            // tsTON пришли на кошелёк Vault: стейк форфейтов (from == none) или пожертвование
            var storage = VaultStorage.load();
            assert (in.senderAddress == storage.tstonWallet()) throw Errors.NotTstonWallet;
            if (msg.from == null) {
                storage.pendingStake = 0;
            }
            storage.distribute(msg.jettonAmount);
            storage.save();
        }

        Excesses => {
            // возврат комиссии пула после стейка форфейтов: остаётся на балансе Vault
        }

        TopUp => {}

        else => {
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
        }
    }
}

// ---------- get-методы ----------

struct VaultConfigReply {
    period: uint32
    windowLength: uint32
    epochStart: uint32
    pool: address
    tstonMaster: address
    vaultTstonWallet: address
    memberCount: uint32
    totalPrincipal: coins
    acc: uint128
    unallocated: coins
    forfeitBuffer: coins
    pendingStake: coins
}

get fun get_config(): VaultConfigReply {
    val storage = VaultStorage.load();
    val params = storage.accountParams.load();
    return {
        period: storage.period,
        windowLength: storage.windowLength,
        epochStart: storage.epochStart,
        pool: params.pool,
        tstonMaster: params.tstonMaster,
        vaultTstonWallet: storage.tstonWallet(),
        memberCount: storage.memberCount,
        totalPrincipal: storage.totalPrincipal,
        acc: storage.acc,
        unallocated: storage.unallocated,
        forfeitBuffer: storage.forfeitBuffer,
        pendingStake: storage.pendingStake,
    };
}

get fun get_window(): WindowState {
    val storage = VaultStorage.load();
    return storage.window();
}

get fun get_account_address(owner: address): address {
    val storage = VaultStorage.load();
    return storage.accountInit(owner).calculateAddress();
}
