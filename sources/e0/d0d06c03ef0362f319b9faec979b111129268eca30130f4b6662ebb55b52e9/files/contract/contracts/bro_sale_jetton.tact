import "@stdlib/deploy";

const SaleWalletDeployValue: Int = 60000000;
const SaleStorageReserve: Int = 20000000;
const SaleMinBuy: Int = 100000000;
const JettonTransferGas: Int = 30000000;
const JettonWalletStorageReserve: Int = 5000000;

message(0xf8a7ea5) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell? = null;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

message(0x178d4519) JettonInternalTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    responseAddress: Address?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

message(0x7362d09c) JettonTransferNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forwardPayload: Slice as remaining;
}

message(0xd53276db) JettonExcesses {
    queryId: Int as uint64;
}

message(0x595f07bc) JettonBurn {
    queryId: Int as uint64;
    amount: Int as coins;
    responseDestination: Address?;
    customPayload: Cell? = null;
}

message(0x7bdd97de) JettonBurnNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    owner: Address;
    responseDestination: Address?;
}

message(0x2c76b973) ProvideWalletAddress {
    queryId: Int as uint64;
    ownerAddress: Address;
    includeAddress: Bool;
}

message(0xd1735400) TakeWalletAddress {
    queryId: Int as uint64;
    walletAddress: Address?;
    ownerAddress: Cell?;
}

message(21) Mint {
    queryId: Int as uint64;
    receiver: Address;
    amount: Int as coins;
}

message(3) ChangeOwner {
    newOwner: Address;
}

message(4) UpdateContent {
    content: Cell;
}

message(0x42524f01) UpdateSale {
    tokensPerTon: Int as uint64;
    hardCap: Int as coins;
    startTime: Int as int64;
    endTime: Int as int64;
}

message(0x42524f02) SetPaused {
    paused: Bool;
}

message(0x42524f03) SetTreasury {
    treasury: Address;
}

message(0x42524f04) WithdrawTon {
    amount: Int as coins;
}

struct JettonData {
    totalSupply: Int as coins;
    mintable: Bool;
    adminAddress: Address;
    content: Cell;
    walletCode: Cell;
}

struct JettonWalletData {
    balance: Int as coins;
    ownerAddress: Address;
    jettonMasterAddress: Address;
    jettonWalletCode: Cell;
}

contract BroSaleJettonMaster(
    totalSupply: Int as coins,
    owner: Address,
    treasury: Address,
    content: Cell,
    mintable: Bool,
    tokensPerTon: Int as uint64,
    hardCap: Int as coins,
    startTime: Int as int64,
    endTime: Int as int64,
    raised: Int as coins,
    soldTokens: Int as uint128,
    paused: Bool,
) {
    receive() {
        cashback(sender());
    }

    fun walletCode(): Cell {
        let sample: StateInit = initOf BroSaleJettonWallet(0, myAddress(), myAddress(), emptyCell());
        return sample.code;
    }

    fun walletInit(ownerAddress: Address): StateInit {
        return initOf BroSaleJettonWallet(0, ownerAddress, myAddress(), self.walletCode());
    }

    receive("buy") {
        let ctx: Context = context();
        let value: Int = ctx.value;
        let currentTime: Int = now();

        require(!self.paused, "paused");
        require(self.mintable, "mint_closed");
        require(value >= SaleMinBuy, "low_value");
        require(value >= SaleWalletDeployValue + SaleStorageReserve, "low_gas");
        require(self.tokensPerTon > 0, "bad_rate");
        require(currentTime >= self.startTime, "not_started");
        require(currentTime <= self.endTime, "ended");

        let nextRaised: Int = self.raised + value;
        require(nextRaised <= self.hardCap, "hard_cap");

        let jettonAmount: Int = value * self.tokensPerTon;
        let walletInit: StateInit = self.walletInit(ctx.sender);
        let walletAddress: Address = contractAddress(walletInit);

        nativeReserve(SaleStorageReserve, ReserveAtMost);

        self.raised = nextRaised;
        self.soldTokens = self.soldTokens + jettonAmount;
        self.totalSupply = self.totalSupply + jettonAmount;

        send(SendParameters{
            to: walletAddress,
            value: SaleWalletDeployValue,
            bounce: false,
            code: walletInit.code,
            data: walletInit.data,
            body: JettonInternalTransfer{
                queryId: currentTime,
                amount: jettonAmount,
                from: myAddress(),
                responseAddress: null,
                forwardTonAmount: 0,
                forwardPayload: rawSlice("F"),
            }.toCell(),
        });
    }

    receive(msg: Mint) {
        require(sender() == self.owner, "only_owner");
        require(self.mintable, "mint_closed");
        require(msg.amount > 0, "bad_amount");

        let walletInit: StateInit = self.walletInit(msg.receiver);
        let walletAddress: Address = contractAddress(walletInit);

        self.totalSupply = self.totalSupply + msg.amount;

        send(SendParameters{
            to: walletAddress,
            value: SaleWalletDeployValue,
            bounce: false,
            code: walletInit.code,
            data: walletInit.data,
            body: JettonInternalTransfer{
                queryId: msg.queryId,
                amount: msg.amount,
                from: myAddress(),
                responseAddress: null,
                forwardTonAmount: 0,
                forwardPayload: rawSlice("F"),
            }.toCell(),
        });

        cashback(sender());
    }

    receive(msg: JettonBurnNotification) {
        let expectedWallet: Address = contractAddress(self.walletInit(msg.owner));
        require(sender() == expectedWallet, "bad_wallet");
        require(self.totalSupply >= msg.amount, "bad_supply");

        self.totalSupply = self.totalSupply - msg.amount;

        if (msg.responseDestination != null) {
            message(MessageParameters{
                to: msg.responseDestination!!,
                value: 0,
                mode: SendRemainingValue,
                bounce: false,
                body: JettonExcesses{queryId: msg.queryId}.toCell(),
            });
        }
    }

    receive(msg: ProvideWalletAddress) {
        let ownerCell: Cell? = null;
        if (msg.includeAddress) {
            ownerCell = beginCell().storeAddress(msg.ownerAddress).endCell();
        }

        message(MessageParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: TakeWalletAddress{
                queryId: msg.queryId,
                walletAddress: contractAddress(self.walletInit(msg.ownerAddress)),
                ownerAddress: ownerCell,
            }.toCell(),
        });
    }

    receive(msg: UpdateSale) {
        require(sender() == self.owner, "only_owner");
        require(msg.tokensPerTon > 0, "bad_rate");
        require(msg.hardCap >= self.raised, "bad_cap");
        require(msg.endTime > msg.startTime, "bad_time");

        self.tokensPerTon = msg.tokensPerTon;
        self.hardCap = msg.hardCap;
        self.startTime = msg.startTime;
        self.endTime = msg.endTime;

        cashback(sender());
    }

    receive(msg: SetPaused) {
        require(sender() == self.owner, "only_owner");
        self.paused = msg.paused;
        cashback(sender());
    }

    receive(msg: SetTreasury) {
        require(sender() == self.owner, "only_owner");
        self.treasury = msg.treasury;
        cashback(sender());
    }

    receive(msg: WithdrawTon) {
        require(sender() == self.owner, "only_owner");
        require(msg.amount > 0, "bad_amount");

        nativeReserve(SaleStorageReserve, ReserveAtMost);

        message(MessageParameters{
            to: self.treasury,
            value: msg.amount,
            bounce: false,
        });
    }

    receive(msg: ChangeOwner) {
        require(sender() == self.owner, "only_owner");
        self.owner = msg.newOwner;
        cashback(sender());
    }

    receive(msg: UpdateContent) {
        require(sender() == self.owner, "only_owner");
        self.content = msg.content;
        cashback(sender());
    }

    get fun get_jetton_data(): JettonData {
        return JettonData{
            totalSupply: self.totalSupply,
            mintable: self.mintable,
            adminAddress: self.owner,
            content: self.content,
            walletCode: self.walletCode(),
        };
    }

    get fun get_wallet_address(ownerAddress: Address): Address {
        return contractAddress(self.walletInit(ownerAddress));
    }

    get fun owner(): Address {
        return self.owner;
    }

    get fun treasury(): Address {
        return self.treasury;
    }

    get fun tokensPerTon(): Int {
        return self.tokensPerTon;
    }

    get fun hardCap(): Int {
        return self.hardCap;
    }

    get fun startTime(): Int {
        return self.startTime;
    }

    get fun endTime(): Int {
        return self.endTime;
    }

    get fun raised(): Int {
        return self.raised;
    }

    get fun soldTokens(): Int {
        return self.soldTokens;
    }

    get fun paused(): Bool {
        return self.paused;
    }
}

contract BroSaleJettonWallet(
    balance: Int as coins,
    ownerAddress: Address,
    jettonMasterAddress: Address,
    jettonWalletCode: Cell,
) {
    receive() {
        cashback(sender());
    }

    fun walletAddress(owner: Address): Address {
        let walletData: JettonWalletData = JettonWalletData{
            balance: 0,
            ownerAddress: owner,
            jettonMasterAddress: self.jettonMasterAddress,
            jettonWalletCode: self.jettonWalletCode,
        };

        return contractAddress(StateInit{
            code: self.jettonWalletCode,
            data: walletData.toCell(),
        });
    }

    receive(msg: JettonTransfer) {
        require(sender() == self.ownerAddress, "only_owner");
        require(msg.amount > 0, "bad_amount");
        require(self.balance >= msg.amount, "low_balance");

        let ctx: Context = context();
        require(ctx.value >= JettonTransferGas, "low_gas");
        nativeReserve(JettonWalletStorageReserve, ReserveAtMost);

        self.balance = self.balance - msg.amount;

        let walletData: JettonWalletData = JettonWalletData{
            balance: 0,
            ownerAddress: msg.destination,
            jettonMasterAddress: self.jettonMasterAddress,
            jettonWalletCode: self.jettonWalletCode,
        };
        let destinationInit: StateInit = StateInit{
            code: self.jettonWalletCode,
            data: walletData.toCell(),
        };
        let destinationWallet: Address = contractAddress(destinationInit);

        send(SendParameters{
            to: destinationWallet,
            value: JettonTransferGas,
            bounce: false,
            code: destinationInit.code,
            data: destinationInit.data,
            body: JettonInternalTransfer{
                queryId: msg.queryId,
                amount: msg.amount,
                from: self.ownerAddress,
                responseAddress: msg.responseDestination,
                forwardTonAmount: msg.forwardTonAmount,
                forwardPayload: msg.forwardPayload,
            }.toCell(),
        });

        if (msg.responseDestination != null) {
            message(MessageParameters{
                to: msg.responseDestination!!,
                value: 0,
                mode: SendRemainingValue,
                bounce: false,
                body: JettonExcesses{queryId: msg.queryId}.toCell(),
            });
        }
    }

    receive(msg: JettonInternalTransfer) {
        require(msg.amount > 0, "bad_amount");
        require(sender() == self.jettonMasterAddress || sender() == self.walletAddress(msg.from), "bad_sender");
        nativeReserve(JettonWalletStorageReserve, ReserveAtMost);

        self.balance = self.balance + msg.amount;

        if (msg.forwardTonAmount > 0) {
            message(MessageParameters{
                to: self.ownerAddress,
                value: msg.forwardTonAmount,
                bounce: false,
                body: JettonTransferNotification{
                    queryId: msg.queryId,
                    amount: msg.amount,
                    sender: msg.from,
                    forwardPayload: msg.forwardPayload,
                }.toCell(),
            });
        }

        if (msg.responseAddress != null) {
            message(MessageParameters{
                to: msg.responseAddress!!,
                value: 0,
                mode: SendRemainingValue,
                bounce: false,
                body: JettonExcesses{queryId: msg.queryId}.toCell(),
            });
        }
    }

    receive(msg: JettonBurn) {
        require(sender() == self.ownerAddress, "only_owner");
        require(self.balance >= msg.amount, "low_balance");

        self.balance = self.balance - msg.amount;

        message(MessageParameters{
            to: self.jettonMasterAddress,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: JettonBurnNotification{
                queryId: msg.queryId,
                amount: msg.amount,
                owner: self.ownerAddress,
                responseDestination: msg.responseDestination,
            }.toCell(),
        });
    }

    bounced(msg: bounced<JettonInternalTransfer>) {
        self.balance = self.balance + msg.amount;
    }

    bounced(msg: bounced<JettonBurnNotification>) {
        self.balance = self.balance + msg.amount;
    }

    get fun get_wallet_data(): JettonWalletData {
        return JettonWalletData{
            balance: self.balance,
            ownerAddress: self.ownerAddress,
            jettonMasterAddress: self.jettonMasterAddress,
            jettonWalletCode: self.jettonWalletCode,
        };
    }
}
