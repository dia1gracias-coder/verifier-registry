import "../common/consts"
import "../common/errors"
import "../vendor/jetton/messages"
import "buyback-messages"
import "buyback-types"
import "fee-splitter-messages"
import "launcher-messages"
import "reward-messages"

contract BuybackVault {
    author: "GRAMDESKS"
    version: "0.1.0"
    description: "Receives the buyback share of coin fees, buys $DESK on its own market under keeper-bounded quotes and burns it. TON can only leave towards the market; $DESK can only be burned. No withdrawal exists."
    storage: BuybackStorage
    incomingMessages: AllowedMessageToBuyback
}

type AllowedMessageToBuyback =
    | BuybackIn
    | BuybackBuy
    | BuybackBurn
    | CancelBuyback
    | TransferNotificationForRecipient
    | ResponseWalletAddress
    | SyncBuybackMarket
    | MarketAnswer
    | SetBuybackLimits
    | SetBuybackRoles
    | TopUpTons
    | ReturnExcessesBack

/// Gas attached on top of tonAmount when hitting the market (Curve.BUY_GAS / Pool swap gas).
const MARKET_GAS = ton("0.15")
/// Gas for the burn (RewardWallet settle round trip).
const BURN_GAS = ton("0.15")
const DISCOVERY_VALUE = ton("0.03")

fun emitBuybackEvent(body: BuybackEvent) {
    val ev = createExternalLogMessage({
        dest: ExtOutLogBucket { topic: EVENT_TOPIC_BUYBACK as uint248 },
        body,
    });
    ev.send(SEND_MODE_REGULAR);
}

fun BuybackStorage.discoverWallet(self, queryId: uint64) {
    if (self.deskWallet != null) {
        return;
    }
    val roles = self.roles.load();
    val req = createMessage({
        bounce: BounceMode.NoBounce,
        dest: roles.deskMaster,
        value: DISCOVERY_VALUE,
        body: RequestWalletAddress { queryId, ownerAddress: contract.getAddress(), includeOwnerAddress: true },
    });
    req.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun BuybackStorage.pendingOf(self): BuybackPending? {
    return self.pending == null ? null : self.pending!.load();
}

fun onInternalMessage(in: InMessage) {
    var storage = lazy BuybackStorage.load();
    val msg = lazy AllowedMessageToBuyback.fromSlice(in.body);

    match (msg) {
        BuybackIn => {
            // income from any FeeSplitter (a stranger sending here only donates)
            var stats = storage.stats.load();
            stats.totalTonIn += in.valueCoins;
            storage.stats = stats.toCell();
            storage.save();
        }

        BuybackBuy => {
            val roles = lazy storage.roles.load();
            assert (in.senderAddress == roles.keeper) throw Errors.NotFromKeeper;
            assert (storage.pending == null) throw Errors.OperationInFlight;
            assert (storage.marketKind != MARKET_NONE && storage.market != null) throw Errors.MarketUnset;
            assert (storage.deskWallet != null) throw Errors.NotWired;
            assert (msg.tonAmount > 0 && msg.tonAmount <= storage.maxPerBuy) throw Errors.BudgetExceeded;
            assert (msg.minOut > 0) throw Errors.InvalidParams;
            assert (in.valueCoins >= MARKET_GAS) throw Errors.InsufficientValue;
            // only fee income above the reserve can be spent (the keeper's gas is not ours to spend)
            val spendable = contract.getOriginalBalance() - in.valueCoins - storage.reserve;
            assert (msg.tonAmount <= spendable) throw Errors.BudgetExceeded;

            storage.pending = BuybackPending { kind: PENDING_BUY, queryId: msg.queryId, amount: msg.tonAmount, startedAt: blockchain.now() as uint32 }.toCell();
            storage.save();
            reserveToncoinsOnBalance(contract.getOriginalBalance() - msg.tonAmount - MARKET_GAS, RESERVE_MODE_EXACT_AMOUNT);
            if (storage.marketKind == MARKET_CURVE) {
                val buy = createMessage({
                    bounce: BounceMode.Only256BitsOfBody,
                    dest: storage.market!,
                    value: 0,
                    body: Buy { queryId: msg.queryId, minOut: msg.minOut, recipient: null },
                });
                buy.send(SEND_MODE_CARRY_ALL_BALANCE);
            } else {
                val swap = createMessage({
                    bounce: BounceMode.Only256BitsOfBody,
                    dest: storage.market!,
                    value: 0,
                    body: SwapTonForCoin { queryId: msg.queryId, minOut: msg.minOut },
                });
                swap.send(SEND_MODE_CARRY_ALL_BALANCE);
            }
        }

        BuybackBurn => {
            val roles = lazy storage.roles.load();
            assert (in.senderAddress == roles.keeper) throw Errors.NotFromKeeper;
            assert (storage.pending == null) throw Errors.OperationInFlight;
            assert (storage.deskWallet != null) throw Errors.NotWired;
            assert (msg.amount > 0) throw Errors.InvalidParams;
            assert (in.valueCoins >= BURN_GAS) throw Errors.InsufficientValue;
            var stats = storage.stats.load();
            stats.totalBurned += msg.amount;
            stats.burns += 1;
            storage.stats = stats.toCell();
            storage.pending = BuybackPending { kind: PENDING_BURN, queryId: msg.queryId, amount: msg.amount, startedAt: blockchain.now() as uint32 }.toCell();
            storage.save();
            emitBuybackEvent({ queryId: msg.queryId, tonSpent: 0, burned: msg.amount });
            val burn = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: storage.deskWallet!,
                value: 0,
                body: AskToBurn { queryId: msg.queryId, jettonAmount: msg.amount, sendExcessesTo: contract.getAddress(), customPayload: null },
            });
            burn.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        ReturnExcessesBack => {
            // the market (buy) or our wallet (burn) confirms the pending operation with its queryId
            val p = storage.pendingOf();
            if (p != null && p.queryId == msg.queryId) {
                if (p.kind == PENDING_BUY && storage.market != null && in.senderAddress == storage.market!) {
                    var stats = storage.stats.load();
                    stats.totalTonSpent += p.amount;
                    storage.stats = stats.toCell();
                    storage.pending = null;
                    storage.save();
                    emitBuybackEvent({ queryId: msg.queryId, tonSpent: p.amount, burned: 0 });
                } else if (p.kind == PENDING_BURN && in.senderAddress == storage.deskWallet!) {
                    storage.pending = null;
                    storage.save();
                }
            }
        }

        TransferNotificationForRecipient => {
            // $DESK landing in our wallet (bought, or donated): it stays there until the keeper burns it
            assert (storage.deskWallet != null && in.senderAddress == storage.deskWallet!) throw Errors.UnknownJettonWallet;
        }

        CancelBuyback => {
            val roles = lazy storage.roles.load();
            assert (in.senderAddress == roles.keeper || in.senderAddress == roles.admin) throw Errors.NotFromKeeper;
            val p = storage.pendingOf();
            assert (p != null) throw Errors.NothingPending;
            assert (blockchain.now() >= p.startedAt + storage.pendingTimeout) throw Errors.PendingNotExpired;
            if (p.kind == PENDING_BURN) {
                var stats = storage.stats.load();
                stats.totalBurned -= p.amount;
                stats.burns -= 1;
                storage.stats = stats.toCell();
            }
            storage.pending = null;
            storage.save();
        }

        ResponseWalletAddress => {
            val roles = lazy storage.roles.load();
            assert (in.senderAddress == roles.deskMaster) throw Errors.NotFromMaster;
            assert (msg.jettonWalletAddress != null) throw Errors.InvalidParams;
            if (msg.ownerAddress != null) {
                assert (msg.ownerAddress.load() == contract.getAddress()) throw Errors.InvalidParams;
            }
            storage.deskWallet = msg.jettonWalletAddress;
            storage.save();
        }

        SyncBuybackMarket => {
            val roles = lazy storage.roles.load();
            assert (in.senderAddress == roles.admin || in.senderAddress == roles.keeper) throw Errors.NotFromAdmin;
            assert (in.valueCoins >= DISCOVERY_VALUE) throw Errors.InsufficientValue;
            val query = createMessage({
                bounce: BounceMode.NoBounce,
                dest: roles.deskMaster,
                value: 0,
                body: QueryMarket { queryId: msg.queryId },
            });
            query.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        MarketAnswer => {
            // only the $DESK master is trusted to name the market
            val roles = lazy storage.roles.load();
            assert (in.senderAddress == roles.deskMaster) throw Errors.NotFromMaster;
            if (msg.pool != null) {
                storage.marketKind = MARKET_POOL;
                storage.market = msg.pool;
            } else if (msg.curveOpen && msg.curve != null) {
                storage.marketKind = MARKET_CURVE;
                storage.market = msg.curve;
            } else {
                storage.marketKind = MARKET_NONE;
                storage.market = null;
            }
            storage.save();
        }

        SetBuybackLimits => {
            val roles = lazy storage.roles.load();
            assert (in.senderAddress == roles.admin) throw Errors.NotFromAdmin;
            storage.reserve = msg.reserve;
            storage.maxPerBuy = msg.maxPerBuy;
            storage.pendingTimeout = msg.pendingTimeout;
            storage.save();
        }

        SetBuybackRoles => {
            var roles = storage.roles.load();
            assert (in.senderAddress == roles.admin) throw Errors.NotFromAdmin;
            roles.admin = msg.admin;
            roles.keeper = msg.keeper;
            storage.roles = roles.toCell();
            storage.save();
        }

        TopUpTons => {
            storage.discoverWallet(0);
        }

        else => {
            // plain TON (deploy, gas top-up): kept as reserve (not counted as fee income)
            assert (in.body.isEmpty() || in.body.preloadUint(32) == 0) throw 0xFFFF;
            storage.discoverWallet(0);
        }
    }
}

fun onBouncedMessage(in: InMessageBounced) {
    var storage = lazy BuybackStorage.load();
    in.bouncedBody.skipBouncedPrefix();
    val op = in.bouncedBody.loadUint(32);
    val p = storage.pendingOf();
    if (p == null) {
        return;
    }
    // the market refused our buy (slippage, closed curve): the TON came back
    if (p.kind == PENDING_BUY && (op == 0x43550002 || op == 0x504F0001)) {
        storage.pending = null;
        storage.save();
    }
    // the wallet refused the burn (more than the balance, busy): undo the stats
    if (p.kind == PENDING_BURN && op == 0x595f07bc) {
        var stats = storage.stats.load();
        stats.totalBurned -= p.amount;
        stats.burns -= 1;
        storage.stats = stats.toCell();
        storage.pending = null;
        storage.save();
    }
}

get fun get_buyback_data(): BuybackDataReply {
    val storage = lazy BuybackStorage.load();
    return {
        reserve: storage.reserve,
        maxPerBuy: storage.maxPerBuy,
        pendingTimeout: storage.pendingTimeout,
        marketKind: storage.marketKind,
        market: storage.market,
        deskWallet: storage.deskWallet,
        roles: storage.roles.load(),
        stats: storage.stats.load(),
        pending: storage.pendingOf(),
    };
}
