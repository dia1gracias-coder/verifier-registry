import "../../gen/PoolV2.code"
import "../common/consts"
import "../common/errors"
import "../vendor/jetton/messages"
import "fee-splitter-messages"
import "launcher-messages"
import "launcher-types"
import "reward-messages"
import "reward-types"

contract CurveV2 {
    author: "GRAMDESKS"
    version: "2.0.0"
    description: "Virtual constant-product bonding curve for a launched coin. Buys mint through the RewardMaster, sells arrive as burns. Graduates once, atomically, into a locked-liquidity Pool credited by the master."
    storage: CurveStorage
    incomingMessages: AllowedMessageToCurve
}

type AllowedMessageToCurve =
    | OpenCurve
    | Buy
    | SellNotify
    | TopUpTons

/// Gas kept from a Buy: mint (master + wallet deploy), FeeIn, excess message.
const BUY_GAS = ton("0.15")
/// Value attached to MintReward towards the master.
const MINT_VALUE = ton("0.06")
/// Gas taken out of `graduationFee`: pool deploy, CurveGraduated to the master.
const GRADUATION_GAS = ton("0.3")
const POOL_DEPLOY_GAS = ton("0.1")
const GRADUATED_VALUE = ton("0.05")
const SPLIT_GAS_CURVE = ton("0.03")
/// Minimum value a SellNotify must carry for the curve's own messages (FeeIn + payout).
const SELL_GAS_CURVE = ton("0.05")

fun emitCurveEvent<T>(topic: int, body: T) {
    val ev = createExternalLogMessage({
        dest: ExtOutLogBucket { topic: topic as uint248 },
        body,
    });
    ev.send(SEND_MODE_REGULAR);
}

fun sendCurveFee(splitter: address, fee: coins, queryId: uint64) {
    if (fee == 0) {
        return;
    }
    val m = createMessage({
        bounce: BounceMode.NoBounce,
        dest: splitter,
        value: fee + SPLIT_GAS_CURVE,
        body: FeeIn {
            queryId,
            amount: fee,
        },
    });
    m.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

/// Coins out for `tonIn` on the virtual curve.
fun CurveStorage.coinOut(self, tonIn: coins): coins {
    return ((self.virtualToken * tonIn) / (self.virtualTon + tonIn)) as coins;
}

/// TON needed (rounded up) to take exactly `coinOut` coins.
fun CurveStorage.tonInFor(self, coinOut: coins): coins {
    val num = self.virtualTon * coinOut;
    val den = self.virtualToken - coinOut;
    return ((num + den - 1) / den) as coins;
}

/// Gross TON out for `coinIn` sold back to the curve.
fun CurveStorage.tonOut(self, coinIn: coins): coins {
    return ((self.virtualTon * coinIn) / (self.virtualToken + coinIn)) as coins;
}

/// Fee on top of a net amount so that `net + fee` is what the buyer pays at `feeBps`.
fun feeOnNet(net: coins, feeBps: int): coins {
    return ((net * feeBps) / (10000 - feeBps)) as coins;
}

fun CurveStorage.graduate(mutate self, roles: CurveRoles, params: CurveParams, queryId: uint64) {
    val liquidityTon = self.realTon - params.graduationFee;
    val pool = AutoDeployAddress {
        workchain: BASECHAIN,
        stateInit: {
            code: poolV2CompiledCode(),
            data: PoolStorage {
                reserveTon: liquidityTon,
                reserveCoin: params.poolSupply,
                lpFeeBps: params.poolLpFeeBps,
                protocolFeeBps: params.poolProtocolFeeBps,
                volumeTon: 0,
                nonce: 0,
                roles: PoolRoles {
                    master: roles.master,
                    splitter: roles.splitter,
                    walletCode: params.walletCode,
                }.toCell(),
                inFlight: [],
            }.toCell(),
        },
    };
    val poolAddress = pool.calculateAddress();

    // the master learns the pool and credits it `poolSupply` in one message: no wallet, no race
    val graduated = createMessage({
        bounce: BounceMode.NoBounce,
        dest: roles.master,
        value: GRADUATED_VALUE,
        body: CurveGraduated {
            queryId,
            pool: poolAddress,
            poolSupply: params.poolSupply,
        },
    });
    graduated.send(SEND_MODE_PAY_FEES_SEPARATELY);
    val deploy = createMessage({
        bounce: BounceMode.NoBounce,
        dest: pool,
        value: liquidityTon + POOL_DEPLOY_GAS,
        body: TopUpTons {},
    });
    deploy.send(SEND_MODE_PAY_FEES_SEPARATELY);
    val protocolFee = params.graduationFee - GRADUATION_GAS;
    if (protocolFee > 0) {
        val toProtocol = createMessage({ bounce: BounceMode.NoBounce, dest: params.protocol, value: protocolFee });
        toProtocol.send(SEND_MODE_PAY_FEES_SEPARATELY);
    }

    self.state = CURVE_GRADUATED;
    self.pool = poolAddress;
    self.realTon = 0;
    emitCurveEvent(
        EVENT_TOPIC_CURVE_GRADUATED,
        CurveGraduatedEvent {
            pool: poolAddress,
            liquidityTon,
            liquidityCoin: params.poolSupply,
            protocolFee,
        },
    );
}

fun onInternalMessage(in: InMessage) {
    var storage = lazy CurveStorage.load();
    val msg = lazy AllowedMessageToCurve.fromSlice(in.body);

    match (msg) {
        OpenCurve => {
            val roles = lazy storage.roles.load();
            assert (in.senderAddress == roles.factory) throw Errors.NotFromFactory;
            assert (storage.state == CURVE_INIT) throw Errors.AlreadyWired;
            storage.state = CURVE_OPEN;
            storage.save();
        }

        Buy => {
            assert (storage.state == CURVE_OPEN) throw Errors.CurveNotOpen;
            val params = lazy storage.params.load();
            val roles = lazy storage.roles.load();
            assert (in.valueCoins > BUY_GAS) throw Errors.InsufficientValue;
            val amountIn = in.valueCoins - BUY_GAS;
            assert (amountIn >= params.minBuy) throw Errors.BelowMinTrade;
            var fee = (amountIn * params.feeBps) / 10000;
            var net = amountIn - fee;
            var out = storage.coinOut(net);
            val remaining = params.curveSupply - storage.sold;
            if (out > remaining) {
                // last lot: the buyer pays exactly what those coins cost, fee included; the rest is refunded
                out = remaining;
                net = storage.tonInFor(out);
                fee = min(feeOnNet(net, params.feeBps), amountIn - net);
            }
            assert (out > 0 && out >= msg.minOut) throw Errors.SlippageExceeded;
            val recipient: address = msg.recipient != null ? msg.recipient : in.senderAddress;
            assert (recipient.getWorkchain() == BASECHAIN) throw Errors.InvalidWorkchain;

            val realTonBefore = storage.realTon;
            storage.virtualTon += net;
            storage.virtualToken -= out;
            storage.realTon += net;
            storage.sold += out;
            val graduating = storage.sold >= params.curveSupply ||
            storage.realTon >= params.graduationTon;

            if (graduating) {
                // everything collected leaves (pool liquidity + graduation fee): keep only the storage reserve
                reserveToncoinsOnBalance(
                    max(
                        contract.getOriginalBalance() - in.valueCoins - realTonBefore,
                        MIN_STORAGE_RESERVE,
                    ),
                    RESERVE_MODE_EXACT_AMOUNT,
                );
            } else {
                // keep what the curve held plus the TON it just collected; everything else is gas / refund
                reserveToncoinsOnBalance(
                    contract.getOriginalBalance() - in.valueCoins + net,
                    RESERVE_MODE_EXACT_AMOUNT,
                );
            }
            val mint = createMessage({
                bounce: BounceMode.NoBounce,
                dest: roles.master,
                value: MINT_VALUE,
                body: MintReward {
                    queryId: msg.queryId,
                    to: recipient,
                    amount: out,
                    forwardTonAmount: 0,
                    forwardPayload: null,
                },
            });
            mint.send(SEND_MODE_PAY_FEES_SEPARATELY);
            sendCurveFee(roles.splitter, fee, msg.queryId);
            emitCurveEvent(
                EVENT_TOPIC_CURVE_TRADE,
                CurveTradeEvent {
                    isBuy: true,
                    trader: recipient,
                    ton: net,
                    coin: out,
                    fee,
                    virtualTon: storage.virtualTon,
                    virtualToken: storage.virtualToken,
                    realTon: storage.realTon,
                },
            );

            if (graduating) {
                storage.graduate(roles, params, msg.queryId);
            }
            storage.save();

            val excesses = createMessage({
                bounce: BounceMode.NoBounce,
                dest: in.senderAddress,
                value: 0,
                body: ReturnExcessesBack { queryId: msg.queryId },
            });
            // SAFETY: last action after a RESERVE of what we held before this message: carries the incoming value minus our fixed sends (rule 1, docs/10)
            excesses.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS);
        }

        SellNotify => {
            val roles = lazy storage.roles.load();
            assert (in.senderAddress == roles.master) throw Errors.NotFromMaster;
            val params = lazy storage.params.load();

            var gross: coins = 0;
            var fee: coins = 0;
            var net: coins = 0;
            var ok = storage.state == CURVE_OPEN && msg.amount <= storage.sold &&
            in.valueCoins >= SELL_GAS_CURVE + SPLIT_GAS_CURVE;
            if (ok) {
                gross = storage.tonOut(msg.amount);
                fee = (gross * params.feeBps) / 10000;
                net = gross - fee;
                ok = net > 0 && net >= msg.minTon && gross <= storage.realTon;
            }
            if (!ok) {
                // refused: the master burned the coins on the Settle, it mints them back to the seller
                val back = createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: roles.master,
                    value: 0,
                    body: Remint {
                        queryId: msg.queryId,
                        to: msg.owner,
                        amount: msg.amount,
                    },
                });
                back.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
                return;
            }

            storage.virtualTon -= gross;
            storage.virtualToken += msg.amount;
            storage.realTon -= gross;
            storage.sold -= msg.amount;
            storage.save();

            reserveToncoinsOnBalance(
                contract.getOriginalBalance() - in.valueCoins - gross,
                RESERVE_MODE_EXACT_AMOUNT,
            );
            sendCurveFee(roles.splitter, fee, msg.queryId);
            emitCurveEvent(
                EVENT_TOPIC_CURVE_TRADE,
                CurveTradeEvent {
                    isBuy: false,
                    trader: msg.owner,
                    ton: net,
                    coin: msg.amount,
                    fee,
                    virtualTon: storage.virtualTon,
                    virtualToken: storage.virtualToken,
                    realTon: storage.realTon,
                },
            );
            // last action: carries the remaining balance (net payout + leftover gas)
            val payout = createMessage({
                bounce: BounceMode.NoBounce,
                dest: msg.owner,
                value: 0,
                body: ReturnExcessesBack { queryId: msg.queryId },
            });
            // SAFETY: last action after a RESERVE of what we held before this message: carries the incoming value minus our fixed sends (rule 1, docs/10)
            payout.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS);
        }

        TopUpTons => {
            // accept
        }

        else => {
            assert (in.body.isEmpty() || in.body.preloadUint(32) == 0) throw 0xFFFF;
        }
    }
}

get fun get_curve_data(): CurveDataReply {
    val storage = lazy CurveStorage.load();
    return {
        state: storage.state,
        virtualTon: storage.virtualTon,
        virtualToken: storage.virtualToken,
        realTon: storage.realTon,
        sold: storage.sold,
        pool: storage.pool,
        roles: storage.roles.load(),
        params: storage.params.load(),
    };
}

/// Coins received for `tonAttached` TON (BUY_GAS is deducted here).
get fun get_buy_quote(tonAttached: coins): Quote {
    val storage = lazy CurveStorage.load();
    val params = storage.params.load();
    if (tonAttached <= BUY_GAS) {
        return { amountOut: 0, fee: 0 };
    }
    val amountIn = tonAttached - BUY_GAS;
    var fee = (amountIn * params.feeBps) / 10000;
    var out = storage.coinOut(amountIn - fee);
    val remaining = params.curveSupply - storage.sold;
    if (out > remaining) {
        out = remaining;
        val net = storage.tonInFor(out);
        fee = min(feeOnNet(net, params.feeBps), amountIn - net);
    }
    return { amountOut: out, fee };
}

/// Net TON received for selling `coinIn` coins.
get fun get_sell_quote(coinIn: coins): Quote {
    val storage = lazy CurveStorage.load();
    val params = storage.params.load();
    val gross = storage.tonOut(coinIn);
    val fee = (gross * params.feeBps) / 10000;
    return { amountOut: gross - fee, fee };
}

/// TON (fee and gas included) that takes the whole `curveSupply` from a fresh curve — what the
/// Factory compares to `graduationTon` (docs/10 §4, D4-2).
get fun get_sell_out_ton(): coins {
    val storage = lazy CurveStorage.load();
    val params = storage.params.load();
    val remaining = params.curveSupply - storage.sold;
    if (remaining == 0) {
        return 0;
    }
    val net = storage.tonInFor(remaining);
    return net + feeOnNet(net, params.feeBps);
}

get fun get_buy_gas(): coins {
    return BUY_GAS;
}

get fun get_code_version(): int {
    return LAUNCHER_CODE_VERSION;
}
