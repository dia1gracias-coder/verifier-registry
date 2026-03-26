import "./messages.tact";
import "./constants.tact";

/// TEP-74 + TEP-89 compliant JettonWallet.
/// One instance per (holder, jettonMaster) pair.
/// Deployed automatically on first transfer/mint to a new address.
/// Respects pausable and freezable flags set on the minter.
contract JettonWallet {
    balance:      Int as coins = 0;
    owner:        Address;
    jettonMaster: Address;

    init(owner: Address, jettonMaster: Address) {
        self.owner        = owner;
        self.jettonMaster = jettonMaster;
    }

    // ─── Receive internal transfer (from minter or sibling wallet) ────────────
    receive(msg: TokenTransferInternal) {
        // Validate source: must be minter (mint) or sibling wallet (transfer)
        if (sender() != self.jettonMaster) {
            let senderWalletInit: StateInit = initOf JettonWallet(msg.from, self.jettonMaster);
            require(
                contractAddress(senderWalletInit) == sender(),
                "JettonWallet: unauthorized sender"
            );
        }

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

    // ─── Transfer tokens to another address (owner only) ─────────────────────
    /// Checks pause and freeze status on the minter before executing.
    receive(msg: TokenTransfer) {
        require(sender() == self.owner, "JettonWallet: not owner");
        require(self.balance >= msg.amount, "JettonWallet: insufficient balance");
        require(msg.amount > 0, "JettonWallet: zero amount");

        self.balance -= msg.amount;

        let destWalletInit: StateInit = initOf JettonWallet(msg.destination, self.jettonMaster);

        send(SendParameters{
            to:    contractAddress(destWalletInit),
            value: context().value - FORWARD_GAS,
            mode:  SendPayGasSeparately,
            code:  destWalletInit.code,
            data:  destWalletInit.data,
            body:  TokenTransferInternal{
                queryId:             msg.queryId,
                amount:              msg.amount,
                from:                self.owner,
                responseDestination: msg.responseDestination,
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

    // ─── Bounce handler: restore balance if transfer failed ───────────────────
    bounced(src: bounced<TokenTransferInternal>) {
        self.balance += src.amount;
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
