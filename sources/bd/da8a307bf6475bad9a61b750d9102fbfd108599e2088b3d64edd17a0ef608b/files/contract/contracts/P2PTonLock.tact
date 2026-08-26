import "@stdlib/deploy";

/// TON jetton lock for p2pBridge.
/// Lock happens only after a verified JettonTransferNotification funds the
/// escrow. Read shape stays aligned with backend `read_ton_trade`.
/// Platform fee (optional in create payload) is paid only on successful
/// release / resolve-to-buyer. Full refund returns the entire lock to seller.
struct Trade {
    state: Int as uint8;
    amount: Int as coins;
    seller: Address;
    buyer: Address;
    jetton: Address;
    feeAmount: Int as coins;
    feeRecipient: Address;
}

struct TradeView {
    state: Int;
    amount: Int;
    seller: Address;
    buyer: Address;
    jetton: Address;
    feeAmount: Int;
    feeRecipient: Address;
}

message(0x7362d09c) JettonTransferNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forwardPayload: Slice as remaining;
}

message(0xf8a7ea5) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    // TEP-74 requires a plain MsgAddress here (not Maybe). Optional broke
    // wallet parsing (exit 9 / cell underflow) on mainnet USDT releases.
    responseDestination: Address;
    customPayload: Cell? = null;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

/// Forward-payload opcode carried inside the jetton transfer that funds a lock.
const OP_CREATE_TRADE: Int = 0x7f4e2a11;
const OP_RELEASE: Int = 0x9a3b1c2d;
const OP_DISPUTE: Int = 0x4c8d2e01;
const OP_RESOLVE: Int = 0x2b7a9f55;
const OP_SET_JETTON_WALLET: Int = 0x5e8f1a03;
/// Arbiter-only recovery when a COMPLETED trade still holds jettons after a
/// non-atomic success-path send failure (fee or payout leg).
const OP_RESCUE_COMPLETED: Int = 0x1e9c4a77;

message(0x9a3b1c2d) Release {
    tradeId: Int as uint256;
}

message(0x4c8d2e01) Dispute {
    tradeId: Int as uint256;
}

message(0x2b7a9f55) Resolve {
    tradeId: Int as uint256;
    toBuyer: Bool;
}

message(0x1e9c4a77) RescueCompleted {
    tradeId: Int as uint256;
    to: Address;
    amount: Int as coins;
}

/// Arbiter sets the escrow's jetton wallet after deploy.
/// Address of this contract depends on init data, so the wallet cannot be
/// known at init time (it is get_wallet_address(lock) on the jetton master).
message(0x5e8f1a03) SetJettonWallet {
    wallet: Address;
}

const STATE_EMPTY: Int = 0;
const STATE_LOCKED: Int = 1;
const STATE_DISPUTED: Int = 2;
const STATE_COMPLETED: Int = 3;
const STATE_REFUNDED: Int = 4;
const JettonTransferGas: Int = ton("0.15");
/// Enough TON for the destination jetton wallet to accept / deploy on first receive.
const JettonForwardTon: Int = ton("0.05");

contract P2PTonLock with Deployable {
    trades: map<Int as uint256, Trade>;
    arbiter: Address;
    jettonMaster: Address;
    myJettonWallet: Address;
    jettonWalletSet: Bool;
    payoutNonce: Int as uint64;
    payoutTrade: map<Int as uint64, Int as uint256>;
    payoutRestore: map<Int as uint64, Int as uint8>;

    init(arbiter: Address, jettonMaster: Address) {
        self.arbiter = arbiter;
        self.jettonMaster = jettonMaster;
        self.myJettonWallet = arbiter;
        self.jettonWalletSet = false;
        self.payoutNonce = 0;
    }

    receive() {}

    receive(msg: SetJettonWallet) {
        require(sender() == self.arbiter, "arbiter");
        require(!self.jettonWalletSet, "set");
        require(msg.wallet != self.arbiter, "wallet");
        self.myJettonWallet = msg.wallet;
        self.jettonWalletSet = true;
    }

    /// Seller funds the lock by transferring jettons to this contract with a
    /// forward payload: opcode + tradeId + buyer [+ feeAmount + feeRecipient].
    receive(msg: JettonTransferNotification) {
        require(self.jettonWalletSet, "wallet");
        require(sender() == self.myJettonWallet, "wallet");
        let payload: Slice = self._unwrapForwardPayload(msg.forwardPayload);
        require(payload.bits() >= 32 + 256, "payload");
        let op: Int = payload.loadUint(32);
        require(op == OP_CREATE_TRADE, "op");
        let tradeId: Int = payload.loadUint(256);
        let buyer: Address = payload.loadAddress();
        require(buyer != msg.sender, "buyer");
        require(msg.amount > 0, "amount");

        let feeAmount: Int = 0;
        let feeRecipient: Address = self.arbiter;
        // Optional fee tail: coins + address (both-sided platform fee total).
        if (payload.bits() >= 4) {
            feeAmount = payload.loadCoins();
            feeRecipient = payload.loadAddress();
            require(feeAmount < msg.amount, "fee");
            require(feeAmount == 0 || (feeRecipient != buyer && feeRecipient != msg.sender), "treasury");
        }

        let current: Trade? = self.trades.get(tradeId);
        require(current == null || current!!.state == STATE_EMPTY, "exists");

        self.trades.set(tradeId, Trade{
            state: STATE_LOCKED,
            amount: msg.amount,
            seller: msg.sender,
            buyer: buyer,
            jetton: self.jettonMaster,
            feeAmount: feeAmount,
            feeRecipient: feeRecipient,
        });
    }

    receive(msg: Release) {
        let tradeOpt: Trade? = self.trades.get(msg.tradeId);
        require(tradeOpt != null, "missing");
        let trade: Trade = tradeOpt!!;
        require(trade.state == STATE_LOCKED, "state");
        require(sender() == trade.seller, "seller");
        self._paySuccess(msg.tradeId, trade);
    }

    receive(msg: Dispute) {
        let tradeOpt: Trade? = self.trades.get(msg.tradeId);
        require(tradeOpt != null, "missing");
        let trade: Trade = tradeOpt!!;
        require(trade.state == STATE_LOCKED, "state");
        require(sender() == trade.seller || sender() == trade.buyer, "party");
        self.trades.set(msg.tradeId, Trade{
            state: STATE_DISPUTED,
            amount: trade.amount,
            seller: trade.seller,
            buyer: trade.buyer,
            jetton: trade.jetton,
            feeAmount: trade.feeAmount,
            feeRecipient: trade.feeRecipient,
        });
    }

    receive(msg: Resolve) {
        require(sender() == self.arbiter, "arbiter");
        let tradeOpt: Trade? = self.trades.get(msg.tradeId);
        require(tradeOpt != null, "missing");
        let trade: Trade = tradeOpt!!;
        require(trade.state == STATE_LOCKED || trade.state == STATE_DISPUTED, "state");
        if (msg.toBuyer) {
            self._paySuccess(msg.tradeId, trade);
        } else {
            self._payFull(msg.tradeId, trade, trade.seller, STATE_REFUNDED);
        }
    }

    receive(msg: RescueCompleted) {
        require(sender() == self.arbiter, "arbiter");
        require(msg.amount > 0, "amount");
        let tradeOpt: Trade? = self.trades.get(msg.tradeId);
        require(tradeOpt != null, "missing");
        let trade: Trade = tradeOpt!!;
        require(trade.state == STATE_COMPLETED, "state");
        // Drain jettons left after a non-atomic fee/payout leg failure.
        self._sendJetton(msg.tradeId, trade, msg.to, msg.amount, STATE_COMPLETED, false);
    }

    bounced(msg: bounced<JettonTransfer>) {
        let q: Int = msg.queryId;
        let tradeId: Int? = self.payoutTrade.get(q);
        let prev: Int? = self.payoutRestore.get(q);
        if (tradeId == null || prev == null) {
            return;
        }
        let tradeOpt: Trade? = self.trades.get(tradeId!!);
        if (tradeOpt == null) {
            return;
        }
        let trade: Trade = tradeOpt!!;
        self.trades.set(tradeId!!, Trade{
            state: prev!!,
            amount: trade.amount,
            seller: trade.seller,
            buyer: trade.buyer,
            jetton: trade.jetton,
            feeAmount: trade.feeAmount,
            feeRecipient: trade.feeRecipient,
        });
    }

    fun _unwrapForwardPayload(payload: Slice): Slice {
        /// TEP-74 forward_payload is Either Cell ^Cell. Jetton wallets copy
        /// that Either prefix into JettonTransferNotification remainder.
        if (payload.refs() >= 1) {
            if (payload.bits() >= 1) {
                let asRef: Bool = payload.loadBool();
                if (asRef) {
                    return payload.loadRef().beginParse();
                }
                return payload;
            }
            return payload.loadRef().beginParse();
        }
        if (payload.bits() >= 33 + 256) {
            let probe: Slice = payload;
            let flag: Bool = probe.loadBool();
            if (!flag && probe.bits() >= 32) {
                let op: Int = probe.preloadUint(32);
                if (op == OP_CREATE_TRADE) {
                    let skipped: Bool = payload.loadBool();
                    return payload;
                }
            }
            return payload;
        }
        return payload;
    }

    fun _paySuccess(tradeId: Int, trade: Trade) {
        let feeAmount: Int = trade.feeAmount;
        let payout: Int = trade.amount - feeAmount;
        // Mark COMPLETED before outbound jetton sends. Otherwise a bounce could
        // restore LOCKED and a second release would charge the platform fee twice.
        // Both sends are enqueued in this same transaction; if a later jetton-wallet
        // leg fails, arbiter RescueCompleted can drain leftover jettons.
        self.trades.set(tradeId, Trade{
            state: STATE_COMPLETED,
            amount: trade.amount,
            seller: trade.seller,
            buyer: trade.buyer,
            jetton: trade.jetton,
            feeAmount: trade.feeAmount,
            feeRecipient: trade.feeRecipient,
        });
        // Buyer first, then platform fee (same-tx message queue).
        if (payout > 0) {
            self._sendJetton(tradeId, trade, trade.buyer, payout, STATE_COMPLETED, false);
        }
        if (feeAmount > 0) {
            self._sendJetton(tradeId, trade, trade.feeRecipient, feeAmount, STATE_COMPLETED, false);
        }
    }

    fun _payFull(tradeId: Int, trade: Trade, to: Address, nextState: Int) {
        // Refund keeps prior-state bounce restore so a failed return can retry.
        self._sendJetton(tradeId, trade, to, trade.amount, trade.state, true);
        self.trades.set(tradeId, Trade{
            state: nextState,
            amount: trade.amount,
            seller: trade.seller,
            buyer: trade.buyer,
            jetton: trade.jetton,
            feeAmount: trade.feeAmount,
            feeRecipient: trade.feeRecipient,
        });
    }

    fun _sendJetton(tradeId: Int, trade: Trade, to: Address, amount: Int, prevState: Int, bounce: Bool) {
        self.payoutNonce = self.payoutNonce + 1;
        let q: Int = self.payoutNonce;
        self.payoutTrade.set(q, tradeId);
        self.payoutRestore.set(q, prevState);
        // TEP-74 forward_payload is Either Cell ^Cell. An empty remaining slice
        // causes jetton wallets to exit 9 (cell underflow) on load_uint(1).
        // either-bit 0 = empty inline forward payload.
        let emptyForward: Slice = beginCell().storeBool(false).endCell().beginParse();
        send(SendParameters{
            to: self.myJettonWallet,
            value: JettonTransferGas,
            bounce: bounce,
            body: JettonTransfer{
                queryId: q,
                amount: amount,
                destination: to,
                responseDestination: to,
                customPayload: null,
                forwardTonAmount: JettonForwardTon,
                forwardPayload: emptyForward,
            }.toCell(),
        });
    }

    get fun get_trade(tradeId: Int): TradeView {
        let tradeOpt: Trade? = self.trades.get(tradeId);
        if (tradeOpt == null) {
            return TradeView{
                state: STATE_EMPTY,
                amount: 0,
                seller: myAddress(),
                buyer: myAddress(),
                jetton: myAddress(),
                feeAmount: 0,
                feeRecipient: myAddress(),
            };
        }
        let trade: Trade = tradeOpt!!;
        return TradeView{
            state: trade.state,
            amount: trade.amount,
            seller: trade.seller,
            buyer: trade.buyer,
            jetton: trade.jetton,
            feeAmount: trade.feeAmount,
            feeRecipient: trade.feeRecipient,
        };
    }

    get fun jetton_master(): Address {
        return self.jettonMaster;
    }

    get fun jetton_wallet(): Address {
        return self.myJettonWallet;
    }

    get fun jetton_wallet_set(): Bool {
        return self.jettonWalletSet;
    }
}
