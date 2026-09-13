import "../../gen/RewardWalletV2.code"
import "../common/consts"
import "../common/errors"
import "../vendor/jetton/messages"
import "../vendor/jetton/storage"
import "reward-messages"
import "reward-types"

contract RewardMasterV2 {
    author: "GRAMDESKS"
    version: "2.0.0"
    description: "Jetton master of a launched coin (TEP-74/89 surface) and dividend hub: holds one cumulative reward index per reward id, acks wallet settles, mints for the Curve, owns the Pool reserve and forwards sells. Never spends its own balance."
    storage: RewardMasterStorage
    incomingMessages: AllowedMessageToRewardMaster
}

type AllowedMessageToRewardMaster =
    | Settle
    | MintReward
    | Remint
    | PremintCoins
    | PoolOut
    | PoolCredit
    | IndexBump
    | CurveGraduated
    | PayRewardFailed
    | WireMaster
    | RequestWalletAddress
    | QueryMarket
    | TopUpTons

/// Value forwarded to the market (curve or pool) with a SellNotify: its compute, PoolCredit / Remint,
/// FeeIn and the TON payout to the seller.
const SELL_NOTIFY_VALUE = ton("0.1")
/// Minimum left for the SettleAck back to the wallet (wallet compute at MAX_REWARDS + its last message).
const ACK_MIN = ton("0.03")
/// Value forwarded to the wallet with a RestoreAccrued.
const RESTORE_VALUE = ton("0.01")

fun emitMasterEvent<T>(topic: int, body: T) {
    val ev = createExternalLogMessage({
        dest: ExtOutLogBucket { topic: topic as uint248 },
        body,
    });
    ev.send(SEND_MODE_REGULAR);
}

fun walletCode(): cell {
    return rewardWalletV2CompiledCode();
}

fun walletOf(owner: address): address {
    return calcRewardWalletAddress(owner, contract.getAddress(), walletCode());
}

/// Keeps what the master held before this message (at least the storage reserve): everything the
/// handler sends is paid by the incoming value, and the last message carries the remainder.
fun keepOwnBalance(inValue: coins) {
    reserveToncoinsOnBalance(
        max(contract.getOriginalBalance() - inValue, MIN_STORAGE_RESERVE),
        RESERVE_MODE_AT_MOST,
    );
}

/// Deliver `amount` coins to `to` (mint, remint): the recipient wallet is deployed if needed.
fun RewardMasterStorage.deliver(
    self,
    inValue: coins,
    queryId: uint64,
    to: address,
    amount: coins,
    forwardTonAmount: coins,
    forwardPayload: cell?,
) {
    keepOwnBalance(inValue);
    val step = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: calcDeployedRewardWallet(to, contract.getAddress(), walletCode()),
        value: 0,
        body: RewardTransferStep {
            queryId,
            jettonAmount: amount,
            transferInitiator: null,
            sendExcessesTo: to,
            forwardTonAmount,
            indices: self.indices,
            forwardPayload: beginCell().storeMaybeRef(forwardPayload).endCell().beginParse(),
        },
    });
    // SAFETY: last action after a RESERVE of what we held before this message: carries the incoming value minus our fixed sends (rule 1, docs/10)
    step.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
}

fun onInternalMessage(in: InMessage) {
    var storage = lazy RewardMasterStorage.load();
    val msg = lazy AllowedMessageToRewardMaster.fromSlice(in.body);

    match (msg) {
        Settle => {
            assert (in.senderAddress == walletOf(msg.owner)) throw Errors.NotFromRewardWallet;
            val roles = lazy storage.roles.load();
            var spent: coins = 0;
            keepOwnBalance(in.valueCoins);

            if (msg.action == ACTION_CLAIM) {
                assert (roles.vault != null) throw Errors.NotWired;
            }
            if (msg.action == ACTION_BURN) {
                assert (
                    msg.burnAmount > 0 && msg.burnAmount <= storage.totalSupply
                ) throw Errors.BudgetExceeded;
                storage.totalSupply -= msg.burnAmount;
                storage.save();
                if (msg.sellMinTon != null) {
                    var market: address? = storage.pool;
                    if (market == null) {
                        assert (storage.curveOpen && roles.curve != null) throw Errors.CurveClosed;
                        market = roles.curve;
                    }
                    spent = SELL_NOTIFY_VALUE;
                    val sell = createMessage({
                        bounce: BounceMode.NoBounce,
                        dest: market!,
                        value: SELL_NOTIFY_VALUE,
                        body: SellNotify {
                            queryId: msg.queryId,
                            owner: msg.owner,
                            amount: msg.burnAmount,
                            minTon: msg.sellMinTon!,
                        },
                    });
                    sell.send(SEND_MODE_PAY_FEES_SEPARATELY);
                }
            }
            assert (in.valueCoins >= spent + ACK_MIN) throw Errors.InsufficientValue;

            val ack = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: in.senderAddress,
                value: 0,
                body: SettleAck {
                    queryId: msg.queryId,
                    retry: false,
                    vault: roles.vault,
                    indices: storage.indices,
                },
            });
            // SAFETY: last action after a RESERVE of what we held before this message: carries the incoming value minus our fixed sends (rule 1, docs/10)
            ack.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
        }

        MintReward => {
            val roles = lazy storage.roles.load();
            assert (
                roles.curve != null && in.senderAddress == roles.curve
            ) throw Errors.NotFromCurve;
            assert (msg.to.getWorkchain() == BASECHAIN) throw Errors.InvalidWorkchain;
            storage.totalSupply += msg.amount;
            storage.save();
            storage.deliver(
                in.valueCoins,
                msg.queryId,
                msg.to,
                msg.amount,
                msg.forwardTonAmount,
                msg.forwardPayload,
            );
        }

        Remint => {
            val roles = lazy storage.roles.load();
            val fromCurve = roles.curve != null && in.senderAddress == roles.curve;
            val fromPool = storage.pool != null && in.senderAddress == storage.pool;
            assert (fromCurve || fromPool) throw Errors.NotFromCurve;
            assert (msg.to.getWorkchain() == BASECHAIN) throw Errors.InvalidWorkchain;
            storage.totalSupply += msg.amount;
            storage.save();
            storage.deliver(
                in.valueCoins,
                msg.queryId,
                msg.to,
                msg.amount,
                0,
                null,
            );
        }

        PremintCoins => {
            val roles = lazy storage.roles.load();
            assert (in.senderAddress == roles.factory) throw Errors.NotFromFactory;
            assert (msg.to.getWorkchain() == BASECHAIN) throw Errors.InvalidWorkchain;
            storage.totalSupply += msg.amount;
            storage.save();
            storage.deliver(
                in.valueCoins,
                msg.queryId,
                msg.to,
                msg.amount,
                0,
                null,
            );
        }

        PoolOut => {
            assert (
                storage.pool != null && in.senderAddress == storage.pool
            ) throw Errors.NotFromPool;
            assert (msg.to.getWorkchain() == BASECHAIN) throw Errors.InvalidWorkchain;
            assert (msg.amount > 0 && msg.amount <= storage.poolReserve) throw ERR_POOL_RESERVE;
            storage.poolReserve -= msg.amount;
            storage.totalSupply += msg.amount;
            storage.save();
            keepOwnBalance(in.valueCoins);
            val step = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: calcDeployedRewardWallet(msg.to, contract.getAddress(), walletCode()),
                value: 0,
                body: PoolDeliver {
                    queryId: msg.queryId,
                    jettonAmount: msg.amount,
                    sendExcessesTo: msg.to,
                    forwardTonAmount: msg.forwardTonAmount,
                    indices: storage.indices,
                },
            });
            // SAFETY: last action after a RESERVE of what we held before this message: carries the incoming value minus our fixed sends (rule 1, docs/10)
            step.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
        }

        PoolCredit => {
            assert (
                storage.pool != null && in.senderAddress == storage.pool
            ) throw Errors.NotFromPool;
            storage.poolReserve += msg.amount;
            storage.save();
        }

        IndexBump => {
            val roles = lazy storage.roles.load();
            assert (
                roles.vault != null && in.senderAddress == roles.vault
            ) throw Errors.NotFromVault;
            assert (msg.rewardId < MAX_REWARDS) throw Errors.RewardUnknown;
            val circulating = storage.totalSupply;
            if (circulating == 0 || msg.amount == 0) {
                val refused = createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: in.senderAddress,
                    value: 0,
                    body: IndexBumpRefused {
                        queryId: msg.queryId,
                        rewardId: msg.rewardId,
                        amount: msg.amount,
                    },
                });
                refused.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
                return;
            }
            // exact division: the remainder is carried so rounding never loses reward units
            val scaled = msg.amount * INDEX_SCALE + amountOf(storage.remainders, msg.rewardId);
            val newIndex = indexOf(storage.indices, msg.rewardId) + scaled / circulating;
            assert (newIndex < (1 << 128)) throw Errors.IndexOverflow;
            val index = newIndex as uint128;
            storage.indices.set(msg.rewardId, index);
            storage.remainders.set(msg.rewardId, (scaled % circulating) as coins);
            storage.save();
            emitMasterEvent(
                EVENT_TOPIC_INDEX_BUMPED,
                IndexBumpedEvent {
                    rewardId: msg.rewardId,
                    amount: msg.amount,
                    circulating,
                    index,
                },
            );
        }

        CurveGraduated => {
            val roles = lazy storage.roles.load();
            assert (
                roles.curve != null && in.senderAddress == roles.curve
            ) throw Errors.NotFromCurve;
            assert (storage.pool == null) throw Errors.AlreadyWired;
            storage.pool = msg.pool;
            storage.poolReserve += msg.poolSupply;
            storage.curveOpen = false;
            storage.save();
        }

        PayRewardFailed => {
            val roles = lazy storage.roles.load();
            assert (
                roles.vault != null && in.senderAddress == roles.vault
            ) throw Errors.NotFromVault;
            val restore = createMessage({
                bounce: BounceMode.NoBounce,
                dest: walletOf(msg.owner),
                value: 0,
                body: RestoreAccrued {
                    queryId: msg.queryId,
                    rewardId: msg.rewardId,
                    amount: msg.amount,
                },
            });
            restore.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        WireMaster => {
            var roles = storage.roles.load();
            assert (in.senderAddress == roles.factory) throw Errors.NotFromFactory;
            assert (roles.curve == null) throw Errors.AlreadyWired;
            roles.curve = msg.curve;
            roles.vault = msg.vault;
            storage.roles = roles.toCell();
            storage.curveOpen = true;
            storage.save();
        }

        RequestWalletAddress => {
            val ownerAddress: Cell<address>? = msg.includeOwnerAddress
                ? msg.ownerAddress.toCell()
                : null;
            var walletAddress: address? = null;
            if (msg.ownerAddress.getWorkchain() == BASECHAIN) {
                walletAddress = walletOf(msg.ownerAddress);
            }
            val respond = createMessage({
                bounce: BounceMode.NoBounce,
                dest: in.senderAddress,
                value: 0,
                body: ResponseWalletAddress {
                    queryId: msg.queryId,
                    jettonWalletAddress: walletAddress,
                    ownerAddress,
                },
            });
            respond.send(
                SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_BOUNCE_ON_ACTION_FAIL,
            );
        }

        QueryMarket => {
            val roles = lazy storage.roles.load();
            val answer = createMessage({
                bounce: BounceMode.NoBounce,
                dest: in.senderAddress,
                value: 0,
                body: MarketAnswer {
                    queryId: msg.queryId,
                    curveOpen: storage.curveOpen,
                    curve: roles.curve,
                    pool: storage.pool,
                },
            });
            answer.send(
                SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_BOUNCE_ON_ACTION_FAIL,
            );
        }

        TopUpTons => {
            // accept
        }

        else => {
            assert (in.body.isEmpty() || in.body.preloadUint(32) == 0) throw 0xFFFF;
        }
    }
}

fun onBouncedMessage(in: InMessageBounced) {
    var storage = lazy RewardMasterStorage.load();
    in.bouncedBody.skipBouncedPrefix();
    val op = in.bouncedBody.loadUint(32);
    // every message we send goes to a basechain wallet or to the pool; anything else is not ours
    assert (in.senderAddress.getWorkchain() == BASECHAIN) throw Errors.InvalidWorkchain;

    if (op == 0x52570003) {
        // mint / remint step bounced: supply never reached the wallet
        in.bouncedBody.skipBits(64);
        val amount = in.bouncedBody.loadCoins();
        assert (amount <= storage.totalSupply) throw Errors.BudgetExceeded;
        storage.totalSupply -= amount;
        storage.save();
        return;
    }
    if (op == 0x52570005) {
        // pool delivery bounced: coins go back to the pool reserve, the pool refunds the buyer
        val queryId = in.bouncedBody.loadUint(64);
        val amount = in.bouncedBody.loadCoins();
        assert (amount <= storage.totalSupply) throw Errors.BudgetExceeded;
        storage.totalSupply -= amount;
        storage.poolReserve += amount;
        storage.save();
        val failed = createMessage({
            bounce: BounceMode.NoBounce,
            dest: storage.pool!,
            value: 0,
            body: PoolOutFailed { queryId, amount },
        });
        failed.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS);
        return;
    }
    if (op == 0x52570002) {
        // the ack did not reach the wallet's storage: retry once, on the bounced value
        val queryId = in.bouncedBody.loadUint(64);
        val retry = in.bouncedBody.loadBool();
        if (retry) {
            return;
        }
        val roles = lazy storage.roles.load();
        val again = createMessage({
            bounce: BounceMode.Only256BitsOfBody,
            dest: in.senderAddress,
            value: 0,
            body: SettleAck {
                queryId,
                retry: true,
                vault: roles.vault,
                indices: storage.indices,
            },
        });
        again.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS);
    }
}

get fun get_jetton_data(): JettonDataReply {
    val storage = lazy RewardMasterStorage.load();
    val roles = storage.roles.load();
    return {
        totalSupply: storage.totalSupply + storage.poolReserve,
        mintable: storage.curveOpen,
        adminAddress: roles.curve,
        jettonContent: storage.metadata as Cell<OnchainMetadataReply>,
        jettonWalletCode: walletCode(),
    };
}

get fun get_wallet_address(ownerAddress: address): address {
    return walletOf(ownerAddress);
}

get fun get_reward_master_data(): RewardMasterDataReply {
    val storage = lazy RewardMasterStorage.load();
    return {
        totalSupply: storage.totalSupply,
        poolReserve: storage.poolReserve,
        curveOpen: storage.curveOpen,
        pool: storage.pool,
        roles: storage.roles.load(),
        indices: storage.indices,
        remainders: storage.remainders,
    };
}

get fun get_code_version(): int {
    return LAUNCHER_CODE_VERSION;
}
