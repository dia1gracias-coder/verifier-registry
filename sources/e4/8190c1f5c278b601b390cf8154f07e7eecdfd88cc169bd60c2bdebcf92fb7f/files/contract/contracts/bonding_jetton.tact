// =====================================================================
// BondingJetton — TON Jetton with SATO-inspired exponential bonding curve
// =====================================================================
// Curve:  minted(eth) = K * (1 − e^(−eth/S))
// S = 100,000 TON, K = 21,000,000 jettons (9 decimals)
// 99% deprecation at ~460,517 TON cumulative buys (≈ $850K at $1.85/TON)
// Buy fees: 0.5% to dev + 0.5% stays in contract floor
// Sell fees: same
// No max buy cap — first buyers can take large shares of supply
// Anti-flashloan: 60s cooldown between buy and sell on same address
// Self-deprecation at 99% of K
// No admin, no upgrade, no pause
// =====================================================================

import "@stdlib/deploy";

// ============================
// CONSTANTS
// ============================
const FP_ONE: Int = 1_000_000_000_000_000_000;     // 1e18 fixed-point
const S_NANOTON: Int = 100_000_000_000_000;       // S = 100,000 TON
const K_NANOJETTON: Int = 21_000_000_000_000_000;  // K = 21M with 9 decimals
const MIN_BUY: Int = 100_000_000;                  // 0.1 TON min buy (anti-dust)
const FEE_DEV_BPS: Int = 50;                       // 0.5%
const FEE_FLOOR_BPS: Int = 50;                     // 0.5%
const COOLDOWN_SEC: Int = 60;                      // anti-flashloan window
const GAS_FOR_TRANSFER: Int = 60_000_000;          // 0.06 TON
const MIN_STORAGE: Int = 100_000_000;              // 0.1 TON storage buffer

// ============================
// MESSAGES
// ============================

message(0x42554c41) Buy {
    queryId: Int as uint64;
}

message(0xf8a7ea5) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

message(0x178d4519) JettonInternalTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    responseAddress: Address;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

message(0x595f07bc) JettonBurn {
    queryId: Int as uint64;
    amount: Int as coins;
    responseDestination: Address;
    customPayload: Cell?;
}

message(0x7bdd97de) JettonBurnNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    responseDestination: Address;
}

message(0xd53276db) JettonExcesses {
    queryId: Int as uint64;
}

// =====================================================================
// JETTON WALLET (one per holder, deployed by master on first mint)
// =====================================================================

contract BondingJettonWallet {
    balance: Int as coins = 0;
    owner: Address;
    master: Address;

    init(master: Address, owner: Address) {
        self.owner = owner;
        self.master = master;
    }

    // Mint or transfer-in
    receive(msg: JettonInternalTransfer) {
        let ctx: Context = context();
        let senderIsMaster: Bool = ctx.sender == self.master;
        let senderWalletAddr: Address = contractAddress(initOf BondingJettonWallet(self.master, msg.from));
        let senderIsPeer: Bool = ctx.sender == senderWalletAddr;
        require(senderIsMaster || senderIsPeer, "Invalid sender");

        self.balance = self.balance + msg.amount;

        // Forward excesses
        let leftover: Int = ctx.value - GAS_FOR_TRANSFER;
        if (leftover > 0 && msg.responseAddress != newAddress(0, 0)) {
            send(SendParameters{
                to: msg.responseAddress,
                value: leftover,
                mode: SendIgnoreErrors,
                bounce: false,
                body: JettonExcesses{queryId: msg.queryId}.toCell()
            });
        }
    }

    // Owner-initiated transfer
    receive(msg: JettonTransfer) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Only owner");
        require(self.balance >= msg.amount, "Insufficient balance");

        self.balance = self.balance - msg.amount;

        let recipientInit: StateInit = initOf BondingJettonWallet(self.master, msg.destination);
        send(SendParameters{
            to: contractAddress(recipientInit),
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: JettonInternalTransfer{
                queryId: msg.queryId,
                amount: msg.amount,
                from: self.owner,
                responseAddress: msg.responseDestination,
                forwardTonAmount: msg.forwardTonAmount,
                forwardPayload: msg.forwardPayload
            }.toCell(),
            code: recipientInit.code,
            data: recipientInit.data
        });
    }

    // Owner-initiated burn — notifies master to release TON from curve
    receive(msg: JettonBurn) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Only owner");
        require(self.balance >= msg.amount, "Insufficient balance");

        self.balance = self.balance - msg.amount;

        send(SendParameters{
            to: self.master,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: JettonBurnNotification{
                queryId: msg.queryId,
                amount: msg.amount,
                sender: self.owner,
                responseDestination: msg.responseDestination
            }.toCell()
        });
    }

    // Re-credit on bounce (mint or transfer failed)
    bounced(src: bounced<JettonInternalTransfer>) {
        self.balance = self.balance + src.amount;
    }

    // Re-credit on burn rejection (e.g. cooldown anti-flashloan)
    bounced(src: bounced<JettonBurnNotification>) {
        self.balance = self.balance + src.amount;
    }

    get fun get_wallet_data(): WalletData {
        return WalletData{
            balance: self.balance,
            owner: self.owner,
            master: self.master,
            walletCode: myCode()
        };
    }
}

struct WalletData {
    balance: Int as coins;
    owner: Address;
    master: Address;
    walletCode: Cell;
}

// =====================================================================
// MASTER — bonding curve lives here
// =====================================================================

contract BondingJetton with Deployable {
    totalSupply: Int as coins = 0;
    cumulativeEth: Int as coins = 0;
    reserves: Int as coins = 0;
    devWallet: Address;
    deprecated: Bool = false;
    metadata: Cell;
    lastBuyAt: map<Address, Int>;

    init(devWallet: Address, metadata: Cell) {
        self.devWallet = devWallet;
        self.metadata = metadata;
    }

    // ============ BUY ============
    receive(msg: Buy) {
        require(!self.deprecated, "Curve closed");

        let ctx: Context = context();
        let valueIn: Int = ctx.value;
        require(valueIn >= MIN_BUY, "Below min buy");

        let gasReserve: Int = GAS_FOR_TRANSFER * 2;
        let netValue: Int = valueIn - gasReserve;
        require(netValue > 0, "Insufficient value");

        // Apply fees
        let devFee: Int = netValue * FEE_DEV_BPS / 10000;
        let floorFee: Int = netValue * FEE_FLOOR_BPS / 10000;
        let curveValue: Int = netValue - devFee - floorFee;

        // Curve calculation
        let newCumEth: Int = self.cumulativeEth + curveValue;
        let newSupply: Int = self.mintedAt(newCumEth);
        let mintAmount: Int = newSupply - self.totalSupply;
        require(mintAmount > 0, "Zero mint");

        // Cap at 99% — flip self-deprecation
        if (newSupply * 100 >= K_NANOJETTON * 99) {
            self.deprecated = true;
        }

        // Update state
        self.cumulativeEth = newCumEth;
        self.totalSupply = newSupply;
        self.reserves = self.reserves + curveValue + floorFee;
        self.lastBuyAt.set(ctx.sender, now());

        // Send dev fee
        send(SendParameters{
            to: self.devWallet,
            value: devFee,
            mode: SendIgnoreErrors,
            bounce: false,
            body: emptyCell()
        });

        // Mint to user wallet
        let userInit: StateInit = initOf BondingJettonWallet(myAddress(), ctx.sender);
        send(SendParameters{
            to: contractAddress(userInit),
            value: GAS_FOR_TRANSFER,
            mode: SendIgnoreErrors,
            bounce: true,
            body: JettonInternalTransfer{
                queryId: msg.queryId,
                amount: mintAmount,
                from: myAddress(),
                responseAddress: ctx.sender,
                forwardTonAmount: 0,
                forwardPayload: emptySlice()
            }.toCell(),
            code: userInit.code,
            data: userInit.data
        });
    }

    // ============ SELL (via burn notification from user's wallet) ============
    receive(msg: JettonBurnNotification) {
        let ctx: Context = context();
        let expectedWallet: Address = contractAddress(initOf BondingJettonWallet(myAddress(), msg.sender));
        require(ctx.sender == expectedWallet, "Invalid wallet");
        require(msg.amount > 0, "Zero burn");
        require(self.totalSupply >= msg.amount, "Underflow");

        // Anti-flashloan: bounce if within cooldown of last buy
        // If sender never bought directly (e.g. received via transfer), lastBuy=0,
        // which means now() - 0 >> COOLDOWN_SEC, so check passes.
        let lastBuy: Int = 0;
        let maybeLastBuy: Int? = self.lastBuyAt.get(msg.sender);
        if (maybeLastBuy != null) {
            lastBuy = maybeLastBuy!!;
        }
        if (now() - lastBuy < COOLDOWN_SEC) {
            // Throwing reverts and the wallet's bounced<JettonBurnNotification> handler re-credits
            require(false, "Cooldown active");
        }

        // Compute new state via curve inverse
        let newSupply: Int = self.totalSupply - msg.amount;
        let newCumEth: Int = self.cumEthForSupply(newSupply);
        let grossOut: Int = self.cumulativeEth - newCumEth;
        require(grossOut > 0, "Zero payout");

        // Apply fees
        let devFee: Int = grossOut * FEE_DEV_BPS / 10000;
        let floorFee: Int = grossOut * FEE_FLOOR_BPS / 10000;
        let userPayout: Int = grossOut - devFee - floorFee;

        // Drainage check: actual TON leaving contract is devFee + userPayout.
        // floorFee stays in reserves. Use real contract balance as the bound,
        // since reserves accounting is virtual but balance is what we can spend.
        let outflow: Int = devFee + userPayout;
        require(outflow <= myBalance() - MIN_STORAGE, "Reserves drained");

        // Update state
        self.totalSupply = newSupply;
        self.cumulativeEth = newCumEth;
        self.reserves = self.reserves - grossOut + floorFee;

        // Dev fee
        send(SendParameters{
            to: self.devWallet,
            value: devFee,
            mode: SendIgnoreErrors,
            bounce: false,
            body: emptyCell()
        });

        // User payout
        send(SendParameters{
            to: msg.sender,
            value: userPayout,
            mode: SendIgnoreErrors,
            bounce: false,
            body: JettonExcesses{queryId: msg.queryId}.toCell()
        });
    }

    // ============ MATH ============

    // mintedAt(eth) = K · (1 − e^(−eth/S))
    fun mintedAt(cumEth: Int): Int {
        let x: Int = cumEth * FP_ONE / S_NANOTON;
        let factor: Int = self.oneMinusExpNeg(x);
        return K_NANOJETTON * factor / FP_ONE;
    }

    // 1 − e^(−x), x in fixed-point 1e18
    fun oneMinusExpNeg(x: Int): Int {
        let n: Int = x / FP_ONE;
        let frac: Int = x - n * FP_ONE;

        let expN: Int = self.expNegInt(n);

        // Taylor series: e^(−y) for y in [0,1)
        let y: Int = frac;
        let y2: Int = y * y / FP_ONE;
        let y3: Int = y2 * y / FP_ONE;
        let y4: Int = y3 * y / FP_ONE;
        let y5: Int = y4 * y / FP_ONE;
        let y6: Int = y5 * y / FP_ONE;
        let y7: Int = y6 * y / FP_ONE;
        let expFrac: Int = FP_ONE - y + y2/2 - y3/6 + y4/24 - y5/120 + y6/720 - y7/5040;

        let expX: Int = expN * expFrac / FP_ONE;
        return FP_ONE - expX;
    }

    // Lookup table for e^(−n), n integer, in 1e18 fixed-point
    fun expNegInt(n: Int): Int {
        if (n == 0) { return FP_ONE; }
        if (n == 1) { return 367879441171442321; }
        if (n == 2) { return 135335283236612691; }
        if (n == 3) { return 49787068367863943; }
        if (n == 4) { return 18315638888734179; }
        if (n == 5) { return 6737946999085467; }
        if (n == 6) { return 2478752176666358; }
        if (n == 7) { return 911881965554516; }
        if (n == 8) { return 335462627902512; }
        if (n == 9) { return 123409804086680; }
        return 45399929762484; // ~e^(-10), saturated for our purposes
    }

    // Newton's method: find cumEth such that mintedAt(cumEth) = targetSupply
    fun cumEthForSupply(targetSupply: Int): Int {
        if (targetSupply == 0) { return 0; }
        let x: Int = self.cumulativeEth;
        if (x < S_NANOTON / 100) { x = S_NANOTON / 10; }

        repeat(8) {
            let supplyAtX: Int = self.mintedAt(x);
            let diff: Int = supplyAtX - targetSupply;
            if (diff < 1000 && diff > -1000) { return x; }

            // dM/dE = (K/S) · e^(−E/S)
            let xRatio: Int = x * FP_ONE / S_NANOTON;
            let factor: Int = self.oneMinusExpNeg(xRatio);
            let expNegX: Int = FP_ONE - factor;
            if (expNegX < 1000) { return x; }
            let derivative: Int = K_NANOJETTON * expNegX / S_NANOTON;
            if (derivative == 0) { return x; }

            let delta: Int = diff * FP_ONE / derivative;
            x = x - delta;
            if (x < 0) { x = 0; }
        }
        return x;
    }

    // ============ GETTERS ============

    get fun get_jetton_data(): JettonData {
        return JettonData{
            totalSupply: self.totalSupply,
            mintable: !self.deprecated,
            adminAddress: newAddress(0, 0), // explicit: no admin
            jettonContent: self.metadata,
            jettonWalletCode: initOf BondingJettonWallet(myAddress(), myAddress()).code
        };
    }

    get fun get_wallet_address(owner: Address): Address {
        return contractAddress(initOf BondingJettonWallet(myAddress(), owner));
    }

    get fun curve_state(): CurveState {
        return CurveState{
            totalSupply: self.totalSupply,
            cumulativeEth: self.cumulativeEth,
            reserves: self.reserves,
            deprecated: self.deprecated
        };
    }
}

struct JettonData {
    totalSupply: Int as coins;
    mintable: Bool;
    adminAddress: Address;
    jettonContent: Cell;
    jettonWalletCode: Cell;
}

struct CurveState {
    totalSupply: Int as coins;
    cumulativeEth: Int as coins;
    reserves: Int as coins;
    deprecated: Bool;
}
