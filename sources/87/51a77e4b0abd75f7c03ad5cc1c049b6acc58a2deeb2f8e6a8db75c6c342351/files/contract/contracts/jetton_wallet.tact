// ─── JettonMaker V4 — jetton_wallet.tact ─────────────────────────────────────

import "./messages.tact";
import "./constants.tact";

/// TEP-74 + TEP-89 compliant JettonWallet — V4.
/// One instance per (owner, jettonMaster) pair.
/// Deployed automatically on first transfer/mint to a new address.
///
/// V4 change: TokenTransfer is routed through the minter for pause/freeze
/// enforcement. The wallet deducts the balance immediately (preventing
/// double-spend) and forwards a TokenTransferViaRouter to the minter.
/// If the minter rejects the transfer (require fails → bounce), the
/// bounced<TokenTransferViaRouter> handler restores the balance.
contract JettonWallet {
    balance:      Int as coins = 0;
    owner:        Address;
    jettonMaster: Address;

    init(owner: Address, jettonMaster: Address) {
        self.owner        = owner;
        self.jettonMaster = jettonMaster;
    }

    // ─── Receive mint credit (from minter only) ──────────────────────────────
    /// Used exclusively for mints (MintInitial + Mint).
    /// Sender must be the jettonMaster.
    receive(msg: TokenTransferInternal) {
        require(sender() == self.jettonMaster, "JettonWallet: mint must come from minter");

        self.balance += msg.amount;

        // Notify owner if forwardTonAmount > 0
        if (msg.forwardTonAmount > 0) {
            send(SendParameters{
                to:    self.owner,
                value: msg.forwardTonAmount,
                mode:  SendPayGasSeparately,
                body:  TokenNotification{
                    queryId:        msg.queryId,
                    amount:         msg.amount,
                    from:           msg.from,
                    forwardPayload: msg.forwardPayload
                }.toCell()
            });
        }

        // Refund excess gas to responseDestination
        if (msg.responseDestination != null) {
            send(SendParameters{
                to:    msg.responseDestination!!,
                value: 0,
                mode:  SendRemainingValue | SendIgnoreErrors,
                body:  TokenExcesses{ queryId: msg.queryId }.toCell()
            });
        }
    }

    // ─── Receive transfer credit (routed by minter) ───────────────────────────
    /// Used for V4 routed transfers. Sender must be the jettonMaster.
    receive(msg: TokenTransferCredit) {
        require(sender() == self.jettonMaster, "JettonWallet: credit must come from minter");

        self.balance += msg.amount;

        // Notify owner if forwardTonAmount > 0
        if (msg.forwardTonAmount > 0) {
            send(SendParameters{
                to:    self.owner,
                value: msg.forwardTonAmount,
                mode:  SendPayGasSeparately,
                body:  TokenNotification{
                    queryId:        msg.queryId,
                    amount:         msg.amount,
                    from:           msg.from,
                    forwardPayload: msg.forwardPayload
                }.toCell()
            });
        }

        // Refund excess gas to responseDestination
        if (msg.responseDestination != null) {
            send(SendParameters{
                to:    msg.responseDestination!!,
                value: 0,
                mode:  SendRemainingValue | SendIgnoreErrors,
                body:  TokenExcesses{ queryId: msg.queryId }.toCell()
            });
        }
    }

    // ─── Transfer tokens (owner only) — routed through minter for enforcement ─
    /// V4: balance is deducted here to prevent double-spend, then a
    /// TokenTransferViaRouter is sent to the minter which validates pause/freeze
    /// before crediting the destination wallet.
    /// If the minter rejects → bounced<TokenTransferViaRouter> restores balance.
    receive(msg: TokenTransfer) {
        require(sender() == self.owner, "JettonWallet: not owner");
        require(self.balance >= msg.amount, "JettonWallet: insufficient balance");
        require(msg.amount > 0, "JettonWallet: zero amount");

        // Deduct balance now — prevents double-spend while awaiting minter response
        self.balance -= msg.amount;

        // Route through minter for pause/freeze validation.
        // SendRemainingValue forwards the full incoming TON to the minter so it
        // has enough gas to forward to the destination wallet in turn.
        send(SendParameters{
            to:   self.jettonMaster,
            value: 0,
            mode:  SendRemainingValue,
            body:  TokenTransferViaRouter{
                queryId:             msg.queryId,
                amount:              msg.amount,
                from:                self.owner,
                destination:         msg.destination,
                responseDestination: msg.responseDestination,
                customPayload:       msg.customPayload,
                forwardTonAmount:    msg.forwardTonAmount,
                forwardPayload:      msg.forwardPayload
            }.toCell()
        });
    }

    // ─── Burn tokens (owner only) ─────────────────────────────────────────────
    receive(msg: TokenBurn) {
        require(sender() == self.owner, "JettonWallet: not owner");
        require(self.balance >= msg.amount, "JettonWallet: insufficient balance");
        require(msg.amount > 0, "JettonWallet: zero amount");

        self.balance -= msg.amount;

        // Notify minter to reduce totalSupply
        send(SendParameters{
            to:    self.jettonMaster,
            value: 0,
            mode:  SendRemainingValue,
            body:  TokenBurnNotification{
                queryId:             msg.queryId,
                amount:              msg.amount,
                sender:              self.owner,
                responseDestination: msg.responseDestination
            }.toCell()
        });
    }

    // ─── Bounce: minter rejected the transfer (pause or freeze) ──────────────
    /// Fired when the minter's require() fails and TokenTransferViaRouter bounces.
    /// Restores the balance that was deducted in receive(msg: TokenTransfer).
    bounced(src: bounced<TokenTransferViaRouter>) {
        self.balance += src.amount;
    }

    // ─── Bounce: destination wallet rejected TokenTransferCredit ────────────
    /// Fires when the destination wallet bounces the TokenTransferCredit sent by
    /// the minter (rare edge case). The minter's bounced<TokenTransferCredit>
    /// handler will send a refund TokenTransferInternal back to this wallet.
    /// Nothing to do here — balance will be restored by receive(TokenTransferInternal).
    bounced(src: bounced<TokenTransferCredit>) {
        // Intentionally empty — refund handled by minter's bounce handler
        // which sends TokenTransferInternal back to restore our balance.
    }

    // ─── TEP-74 get methods ───────────────────────────────────────────────────
    get fun get_wallet_data(): JettonWalletData {
        return JettonWalletData{
            balance:      self.balance,
            owner:        self.owner,
            jettonMaster: self.jettonMaster,
            walletCode:   (initOf JettonWallet(self.owner, self.jettonMaster)).code
        };
    }
}

struct JettonWalletData {
    balance:      Int as coins;
    owner:        Address;
    jettonMaster: Address;
    walletCode:   Cell;
}
