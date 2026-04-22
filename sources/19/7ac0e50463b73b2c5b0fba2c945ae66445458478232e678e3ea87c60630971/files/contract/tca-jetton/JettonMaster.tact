// TCA Token — TON Capital Arena
// TEP-74 Jetton with a transparent on-chain ledger for game economy tracking.
//
// Every 12 hours the backend makes up to 3 calls:
//
//   1. BatchMint(portfolioAmount, profitAmount)
//      - Mints portfolioAmount + profitAmount to adminWallet (all tokens held there)
//      - Mints 5% of the total to marketingWallet
//      - Updates counters: portfolioLocked, profitCirculating
//
//   2. BatchBurn(amount)
//      - Burns amount from adminWallet (level fees, fund burns, arena fees)
//      - Updates: portfolioLocked -= amount, totalBurned += amount
//
//   3. RecordWithdrawal(amount)
//      - Called after transferring tokens from adminWallet to a user's TON wallet
//      - Updates: profitCirculating -= amount, totalWithdrawn += amount
//
// Roles:
//   owner       — cold wallet. Can change minter, adminWallet, marketing, content.
//   minter      — backend hot wallet. Calls BatchMint, BatchBurn, RecordWithdrawal.
//   adminWallet — holds all project TCA tokens (portfolio pool + profit pool).

import "@stdlib/deploy";

// ── Messages ───────────────────────────────────────────────────────────────

message BatchMint {
    portfolioAmount: Int as coins;   // amount to mint into portfolios (locked)
    profitAmount:    Int as coins;   // amount to mint into profit (circulating)
}

message BatchBurn {
    amount: Int as coins;            // burn from portfolio pool (level fees, fund, arena)
}

message RecordWithdrawal {
    amount: Int as coins;            // user withdrew this amount from profit
}

// TEP-74 standard messages
message TokenTransfer {
    queryId:             Int as uint64;
    amount:              Int as coins;
    destination:         Address;
    responseDestination: Address?;
    customPayload:       Cell?;
    forwardTonAmount:    Int as coins;
    forwardPayload:      Slice as remaining;
}

message ProvideWalletAddress {
    queryId:        Int as uint64;
    ownerAddress:   Address;
    includeAddress: Bool;
}

message TakeWalletAddress {
    queryId:       Int as uint64;
    walletAddress: Address;
    ownerAddress:  Slice as remaining;
}

message JettonExcesses { queryId: Int as uint64; }

message InternalTransfer {
    queryId:          Int as uint64;
    amount:           Int as coins;
    from:             Address;
    responseAddress:  Address?;
    forwardTonAmount: Int as coins;
    forwardPayload:   Slice as remaining;
}

message BurnNotification {
    queryId:             Int as uint64;
    amount:              Int as coins;
    sender:              Address;
    responseDestination: Address?;
}

message Burn {
    queryId:             Int as uint64;
    amount:              Int as coins;
    responseDestination: Address?;
}

// Administration
message SetMinter      { newMinter:      Address; }
message SetAdminWallet { newAdminWallet: Address; }
message SetMarketing   { newWallet: Address; newPct: Int as uint8; }
message SetContent     { newContent: Cell; }   // update off-chain metadata URL
message DisableMinting {}

// ── Main Contract ──────────────────────────────────────────────────────────

contract TCAToken with Deployable {

    // ── Roles ──
    owner:           Address;   // cold wallet
    minter:          Address;   // backend hot wallet
    adminWallet:     Address;   // holds all project tokens
    marketingWallet: Address;   // receives 5% of every mint
    marketingPct:    Int as uint8;  // 5

    // ── TEP-74 ──
    totalSupply: Int as coins;
    content:     Cell;
    mintable:    Bool;

    // ── Ledger (portfolio pool — locked tokens) ──
    portfolioLocked:      Int as coins;   // total of all player portfolios right now
    profitCirculating:    Int as coins;   // total profit (circulating, awaiting withdrawal)
    totalMinted:          Int as coins;   // total ever minted
    totalBurned:          Int as coins;   // total ever burned
    totalWithdrawn:       Int as coins;   // total ever withdrawn by users
    totalMarketingMinted: Int as coins;   // 5% marketing share of all mints
    lastSyncAt:           Int as uint32;
    syncCount:            Int as uint32;

    init(
        owner:           Address,
        minter:          Address,
        adminWallet:     Address,
        marketingWallet: Address,
        content:         Cell
    ) {
        self.owner           = owner;
        self.minter          = minter;
        self.adminWallet     = adminWallet;
        self.marketingWallet = marketingWallet;
        self.marketingPct    = 5;

        self.totalSupply = 0;
        self.content     = content;
        self.mintable    = true;

        self.portfolioLocked      = 0;
        self.profitCirculating    = 0;
        self.totalMinted          = 0;
        self.totalBurned          = 0;
        self.totalWithdrawn       = 0;
        self.totalMarketingMinted = 0;
        self.lastSyncAt           = 0;
        self.syncCount            = 0;
    }

    // ── BatchMint — called every 12 hours ────────────────────────────────
    //
    // Mints (portfolioAmount + profitAmount) to adminWallet.
    // Plus 5% of the total to marketingWallet.

    receive(msg: BatchMint) {
        require(sender() == self.minter, "Only minter");
        require(self.mintable, "Minting disabled");

        let total:         Int = msg.portfolioAmount + msg.profitAmount;
        let marketingCut:  Int = total * self.marketingPct / 100;

        require(total > 0, "Nothing to mint");

        // Update totalSupply
        self.totalSupply = self.totalSupply + total + marketingCut;

        // Mint to adminWallet (all portfolio + profit tokens)
        self._mintTo(self.adminWallet, total, 0);

        // Mint marketing share
        if (marketingCut > 0) {
            self._mintTo(self.marketingWallet, marketingCut, 0);
        }

        // Update ledger
        self.portfolioLocked   = self.portfolioLocked + msg.portfolioAmount;
        self.profitCirculating = self.profitCirculating + msg.profitAmount;
        self.totalMinted          = self.totalMinted + total + marketingCut;
        self.totalMarketingMinted = self.totalMarketingMinted + marketingCut;
        self.lastSyncAt = now();
        self.syncCount  = self.syncCount + 1;
    }

    // ── BatchBurn — called every 12 hours ────────────────────────────────
    //
    // Burns portfolio tokens from adminWallet.
    // These are level fees, arena fees, and fund burns.

    receive(msg: BatchBurn) {
        require(sender() == self.minter, "Only minter");
        require(msg.amount > 0, "Nothing to burn");
        require(self.portfolioLocked >= msg.amount, "Burn exceeds portfolio locked");

        // Send Burn to the adminWallet's Jetton wallet
        send(SendParameters{
            to:     self._walletAddr(self.adminWallet),
            value:  ton("0.05"),
            mode:   SendPayGasSeparately,
            bounce: true,
            body:   Burn{
                queryId:             0,
                amount:              msg.amount,
                responseDestination: self.minter
            }.toCell()
        });

        // Update ledger optimistically (burn almost always succeeds)
        self.portfolioLocked = self.portfolioLocked - msg.amount;
        self.totalBurned     = self.totalBurned + msg.amount;
    }

    // ── RecordWithdrawal — called after transferring tokens to the user ───
    //
    // Backend transfers tokens from adminWallet to the user's wallet,
    // then calls this method to update the ledger.

    receive(msg: RecordWithdrawal) {
        require(sender() == self.minter, "Only minter");
        require(self.profitCirculating >= msg.amount, "Exceeds profit circulating");

        self.profitCirculating = self.profitCirculating - msg.amount;
        self.totalWithdrawn    = self.totalWithdrawn + msg.amount;
    }

    // ── BurnNotification from JettonWallet ───────────────────────────────

    receive(msg: BurnNotification) {
        require(
            sender() == self._walletAddr(msg.sender),
            "Unauthorized burn notification"
        );
        self.totalSupply = self.totalSupply - msg.amount;
    }

    // ── Wallet address query (TEP-74) ─────────────────────────────────────

    receive(msg: ProvideWalletAddress) {
        send(SendParameters{
            to:     sender(),
            value:  0,
            mode:   SendRemainingValue,
            bounce: false,
            body:   TakeWalletAddress{
                queryId:      msg.queryId,
                walletAddress: self._walletAddr(msg.ownerAddress),
                ownerAddress:  msg.includeAddress
                    ? beginCell().storeAddress(msg.ownerAddress).endCell().asSlice()
                    : emptySlice()
            }.toCell()
        });
    }

    // ── Administration (owner only) ───────────────────────────────────────

    receive(msg: SetMinter) {
        require(sender() == self.owner, "Only owner");
        self.minter = msg.newMinter;
    }

    receive(msg: SetAdminWallet) {
        require(sender() == self.owner, "Only owner");
        self.adminWallet = msg.newAdminWallet;
    }

    receive(msg: SetMarketing) {
        require(sender() == self.owner, "Only owner");
        require(msg.newPct <= 20, "Max 20%");
        self.marketingWallet = msg.newWallet;
        self.marketingPct    = msg.newPct;
    }

    receive(msg: SetContent) {
        require(sender() == self.owner, "Only owner");
        self.content = msg.newContent;
    }

    receive(msg: DisableMinting) {
        require(sender() == self.owner, "Only owner");
        self.mintable = false;
    }

    // ── Internal helpers ──────────────────────────────────────────────────

    fun _mintTo(to: Address, amount: Int, queryId: Int) {
        let walletInit: StateInit = initOf JettonWallet(myAddress(), to);
        send(SendParameters{
            to:     contractAddress(walletInit),
            value:  ton("0.05"),
            mode:   SendPayGasSeparately,
            bounce: false,
            code:   walletInit.code,
            data:   walletInit.data,
            body:   InternalTransfer{
                queryId:          queryId,
                amount:           amount,
                from:             myAddress(),
                responseAddress:  self.owner,
                forwardTonAmount: 0,
                forwardPayload:   emptySlice()
            }.toCell()
        });
    }

    fun _walletAddr(owner: Address): Address {
        return contractAddress(initOf JettonWallet(myAddress(), owner));
    }

    // ── Getters (visible in TON Explorer) ────────────────────────────────

    // Ledger
    get fun portfolioLocked(): Int      { return self.portfolioLocked; }
    get fun profitCirculating(): Int    { return self.profitCirculating; }
    get fun totalInGame(): Int          { return self.portfolioLocked + self.profitCirculating; }
    get fun totalMinted(): Int          { return self.totalMinted; }
    get fun totalBurned(): Int          { return self.totalBurned; }
    get fun totalWithdrawn(): Int       { return self.totalWithdrawn; }
    get fun totalMarketingMinted(): Int { return self.totalMarketingMinted; }
    get fun lastSyncAt(): Int           { return self.lastSyncAt; }
    get fun syncCount(): Int            { return self.syncCount; }

    // Roles
    get fun owner(): Address           { return self.owner; }
    get fun minter(): Address          { return self.minter; }
    get fun adminWallet(): Address     { return self.adminWallet; }
    get fun marketingWallet(): Address { return self.marketingWallet; }
    get fun marketingPct(): Int        { return self.marketingPct; }

    // TEP-74 standard
    get fun totalSupply(): Int { return self.totalSupply; }
    get fun mintable(): Bool   { return self.mintable; }

    get fun get_jetton_data(): JettonData {
        return JettonData{
            total_supply:       self.totalSupply,
            mintable:           self.mintable,
            admin_address:      self.owner,
            jetton_content:     self.content,
            jetton_wallet_code: initOf JettonWallet(myAddress(), myAddress()).code
        };
    }

    // Keep old name for backward compat
    get fun jetton_data(): JettonData {
        return self.get_jetton_data();
    }

    get fun get_wallet_address(ownerAddress: Address): Address {
        return self._walletAddr(ownerAddress);
    }

    get fun wallet_address(ownerAddress: Address): Address {
        return self._walletAddr(ownerAddress);
    }
}

struct JettonData {
    total_supply:       Int;
    mintable:           Bool;
    admin_address:      Address;
    jetton_content:     Cell;
    jetton_wallet_code: Cell;
}

// ── Jetton Wallet (TEP-74) ─────────────────────────────────────────────────

contract JettonWallet {
    balance: Int as coins;
    owner:   Address;
    master:  Address;

    init(master: Address, owner: Address) {
        self.balance = 0;
        self.owner   = owner;
        self.master  = master;
    }

    receive(msg: TokenTransfer) {
        require(sender() == self.owner, "Only owner can transfer");
        require(self.balance >= msg.amount, "Insufficient balance");

        self.balance = self.balance - msg.amount;

        send(SendParameters{
            to:     contractAddress(initOf JettonWallet(self.master, msg.destination)),
            value:  0,
            mode:   SendRemainingValue,
            bounce: false,
            body:   InternalTransfer{
                queryId:          msg.queryId,
                amount:           msg.amount,
                from:             self.owner,
                responseAddress:  msg.responseDestination,
                forwardTonAmount: msg.forwardTonAmount,
                forwardPayload:   msg.forwardPayload
            }.toCell(),
            data: initOf JettonWallet(self.master, msg.destination).data
        });
    }

    receive(msg: InternalTransfer) {
        self.balance = self.balance + msg.amount;

        if (msg.responseAddress != null) {
            send(SendParameters{
                to:     msg.responseAddress!!,
                value:  0,
                mode:   SendRemainingValue + SendIgnoreErrors,
                bounce: false,
                body:   JettonExcesses{ queryId: msg.queryId }.toCell()
            });
        }
    }

    receive(msg: Burn) {
        require(sender() == self.owner, "Only owner can burn");
        require(self.balance >= msg.amount, "Insufficient balance");

        self.balance = self.balance - msg.amount;

        send(SendParameters{
            to:     self.master,
            value:  0,
            mode:   SendRemainingValue,
            bounce: false,
            body:   BurnNotification{
                queryId:             msg.queryId,
                amount:              msg.amount,
                sender:              self.owner,
                responseDestination: msg.responseDestination
            }.toCell()
        });
    }

    get fun get_wallet_data(): WalletData {
        return WalletData{
            balance: self.balance,
            owner:   self.owner,
            master:  self.master,
            code:    myCode()
        };
    }
}

struct WalletData {
    balance: Int;
    owner:   Address;
    master:  Address;
    code:    Cell;
}
