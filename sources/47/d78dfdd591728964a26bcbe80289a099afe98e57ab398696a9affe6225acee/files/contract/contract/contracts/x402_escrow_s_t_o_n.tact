// SPDX-License-Identifier: UNLICENSED
//
// Contract: X402EscrowSTON
// Purpose: Custodial escrow for STON-based gas abstraction.
//
// Author: Tychi Labs
//
import "./types.tact";


/// @title X402EscrowSTON
/// @notice Escrow contract for locking STON tokens and receiving x402 STON credits for gas payments
/// @dev Users lock STON jettons to receive x402 STON balance, which can be spent for TON gas fees
contract X402EscrowSTON {
    /// @notice Contract owner with administrative privileges
    owner: Address;

    /// @notice STON jetton master contract address
    stonJetton: Address;

    /// @notice Mapping of user addresses to their locked x402 STON balance
    balances: map<Address, Int>;

    /// @notice Mapping of user addresses to their registered ed25519 public keys
    userPubKeys: map<Address, Int>;

    /// @notice Total amount of STON tokens locked in the contract
    totalLocked: Int;

    /// @notice This contract's STON jetton wallet address
    myJettonWallet: Address;

    /// @notice Destination address for withdrawals
    withdrawAddress: Address;

    /// @notice Mapping of admin addresses authorized to execute batch transfers
    admins: map<Address, Bool>;

    /// @notice Initializes the escrow contract
    /// @param owner_ Contract owner address
    /// @param stonJetton_ STON jetton master contract address
    /// @param withdraw_ Withdrawal destination address
    /// @param admin1-5 Additional admin addresses for batch operations
    init(
        owner_: Address,
        stonJetton_: Address,
        withdraw_: Address,
        admin1: Address,
        admin2: Address,
        admin3: Address,
        admin4: Address,
        admin5: Address,
    ) {
        self.owner = owner_;
        self.admins = emptyMap();
        self.admins.set(owner_, true);
        self.admins.set(admin1, true);
        self.admins.set(admin2, true);
        self.admins.set(admin3, true);
        self.admins.set(admin4, true);
        self.admins.set(admin5, true);
        self.stonJetton = stonJetton_;
        self.myJettonWallet = owner_; // temporary placeholder
        self.withdrawAddress = owner_;

        self.balances = emptyMap();
        self.totalLocked = 0;
        self.userPubKeys = emptyMap();
    }

    /// @notice Accepts TON deposits
    receive() {}

    /// @notice Returns the x402 STON balance of a user
    /// @param user User's address
    /// @return User's locked x402 STON balance
    get fun balanceOf(user: Address): Int {
        let v = self.balances.get(user);
        return v == null ? 0 : v!!;
    }

    /// @notice Returns total amount of STON locked in the contract
    /// @return Total locked STON amount
    get fun totalLockedAmount(): Int {
        return self.totalLocked;
    }

    /// @notice Returns the contract's TON balance
    /// @return Contract TON balance
    get fun tonBalance(): Int {
        return myBalance();
    }

    /// @notice Returns the contract's STON jetton wallet address
    /// @return STON jetton wallet address
    get fun myJettonWallet(): Address {
        return self.myJettonWallet;
    }

    /// @notice Returns the registered public key for a user
    /// @param user User's address
    /// @return User's ed25519 public key (256-bit integer) or null
    get fun userPubKey(user: Address): Int? {
        return self.userPubKeys.get(user);
    }

    /// @dev Checks if an address has admin privileges
    /// @param addr Address to check
    /// @return True if address is an admin
    inline fun isAuthorized(addr: Address): Bool {
        return self.admins.get(addr) == true;
    }

    /// @notice Receives STON jetton transfers and locks them as x402 STON
    /// @dev Expects forwardPayload containing user's ed25519 public key (256 bits)
    /// @param msg Jetton transfer notification from the jetton wallet
    receive(msg: JettonTransferNotification) {
        if (sender() != self.myJettonWallet) {
            throw(100); // NOT_JETTON_WALLET
        }
        if (msg.forwardPayload.empty()) {
            throw(101);
        }

        let user = msg.from;

        let s = msg.forwardPayload;

        let isRef = s.loadBit(); // 0 = inline, 1 = ref

        if (isRef) {
            throw(105); // unexpected: you sent ref payload
        }

        let userPubKey = s.loadUint(256); // PROVIDED BY USER
        let amount = msg.amount;
        if (amount <= 0) {
            throw(103);
        }

        if (self.userPubKeys.get(user) == null) {
            self.userPubKeys.set(user, userPubKey);
        }

        let prevOpt = self.balances.get(user);
        let prev: Int = prevOpt == null ? 0 : prevOpt!!;

        self.balances.set(user, prev + amount);
        self.totalLocked += amount;
    }

    /// @notice Executes batch TON gas transfers and deducts x402 STON
    /// @dev Only callable by authorized admins, max 50 transfers per batch
    /// @param msg Batch transfer message containing transfer entries
    receive(msg: BatchTransferTON) {
        if (!self.isAuthorized(sender())) {
            throw(401);
        }

        if (msg.count > 50) {
            throw(300);
        }

        if (msg.count > 50) {
            throw(300);
        }

        let maxTon = ton("0.5");
        let i: Int = 0;

        repeat (msg.count) {
            let entryOpt = msg.entries.get(i);
            if (entryOpt == null) {
                throw(301);
            }

            let entry = entryOpt!!;
            let sendAmt = entry.tonAmount > maxTon ? maxTon : entry.tonAmount;

            self.spendX402Internal(
                entry.to,
                entry.stonAmount,
            );

            send(SendParameters {
                to: entry.to,
                value: sendAmt,
                mode: SendPayGasSeparately,
                bounce: false,
            });

            i += 1;
        }
    }

    /// @notice Withdraws STON tokens from the escrow
    /// @dev Only callable by owner, reduces totalLocked
    /// @param msg Withdrawal message with amount
    receive(msg: WithdrawSTON) {
        if (sender() != self.owner) {
            throw(401);
        }

        if (msg.amount > self.totalLocked) {
            throw(402);
        }

        self.totalLocked -= msg.amount;

        send(SendParameters {
            to: self.myJettonWallet,
            value: ton("0.05"), // Use exact constant from docs
            body: JettonTransfer {
                queryId: 0,
                amount: msg.amount,
                destination: self.withdrawAddress,
                responseDestination: self.withdrawAddress,
                customPayload: null,
                forwardTonAmount: 1, // 1 nanoton like in example
                forwardPayload: rawSlice("F"), // Simple payload like example
            }.toCell(),
        });
    }

    /// @notice Withdraws TON from the contract
    /// @dev Only callable by owner
    /// @param msg Withdrawal message with TON amount
    receive(msg: WithdrawTON) {
        if (sender() != self.owner) {
            throw(401);
        }

        send(SendParameters {
            to: self.withdrawAddress,
            value: msg.amount,
            mode: SendPayGasSeparately,
            bounce: false,
        });
    }

    /// @notice Unlocks and returns STON to a user
    /// @dev Only callable by owner, deducts fee before returning STON
    /// @param msg Unlock message with user address, amount, and fee
    receive(msg: UnlockSTON) {
        if (sender() != self.owner) {
            throw(401);
        }

        let user = msg.user;
        let balOpt = self.balances.get(user);
        let bal: Int = balOpt == null ? 0 : balOpt!!;

        if (bal < msg.amount) {
            throw(403);
        }

        // Calculate amount after fee
        let amountAfterFee = msg.amount - msg.fee;

        // Deduct full amount from user's x402 balance
        self.balances.set(user, bal - msg.amount);
        self.totalLocked -= msg.amount;

        // Send reduced amount to user (owner keeps fee)
        send(SendParameters {
            to: self.myJettonWallet,
            value: ton("0.05"),
            body: JettonTransfer {
                queryId: 0,
                amount: amountAfterFee,
                destination: user,
                responseDestination: user,
                customPayload: null,
                forwardTonAmount: 1,
                forwardPayload: rawSlice("F"),
            }.toCell(),
        });
    }

    /// @notice Sets the contract's STON jetton wallet address
    /// @dev Only callable by owner, required after deployment
    /// @param msg Message containing jetton wallet address
    receive(msg: SetJettonWallet) {
        if (sender() != self.owner) {
            throw(401);
        }

        self.myJettonWallet = msg.jettonWallet;
    }

    /// @dev Internal function to deduct x402 STON from user balance
    /// @param user User's address
    /// @param amount Amount to deduct
    inline fun spendX402Internal(user: Address, amount: Int) {
        let balOpt = self.balances.get(user);
        let bal: Int = balOpt == null ? 0 : balOpt!!;

        if (bal < amount) {
            throw(204);
        }

        self.balances.set(user, bal - amount);
    }
}
