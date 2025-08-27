
inline extends fun AsMetaDataCell(self: String): Cell {
    return beginTailString().concat(self).toCell();
}

fun ComposeJettonMetaData(Name: String, Desc: String, Symbol: String, Img: String, Decimals: String): Cell {
    let D: map<Int as uint256, Cell> = emptyMap();

    D.set(sha256("name"), Name.AsMetaDataCell());
    D.set(sha256("description"), Desc.AsMetaDataCell());
    D.set(sha256("symbol"), Symbol.AsMetaDataCell());
    D.set(sha256("image"), Img.AsMetaDataCell());
    D.set(sha256("decimals"), Decimals.AsMetaDataCell());

    return beginCell().storeUint(0, 8).storeMaybeRef(D.asCell()!!).endCell();
}

@interface("org.ton.jetton.master")
contract JettonContract {
    const GasOverhead: Int = ton("0.01");

    AdminAddress: Address;
    Mintable: Bool;
    MetaDataContent: Cell;
    TotalSupply: Int as coins;
    DevData: DevData;
    WalletCode: Cell;
    LockedContentDecimals: String;
    GlobalID: Int;
    IsDevFeeSended: Bool;



    init(AdminAddress: Address, MetaDataContent: Cell, DevData: DevData, WalletCode: Cell, LockedContentDecimals: String, GlobalID: Int) {
        self.AdminAddress = AdminAddress;
        self.Mintable = true;
        self.MetaDataContent = MetaDataContent;
        self.TotalSupply = 0;
        self.DevData = DevData;
        self.WalletCode = WalletCode;
        self.LockedContentDecimals = LockedContentDecimals;
        self.GlobalID = GlobalID;
        self.IsDevFeeSended = false;
    }

    receive(Msg: Mint) { // 0x00000001
        let Ctx: Context = context();

        require(Ctx.sender == self.AdminAddress, "Not admin!");

        require(self.Mintable, "Not mintable.");

        self.TotalSupply += Msg.Value;

        let WalletInit: StateInit = self.GetWalletInit(Msg.Address);

        let ForwardPayload: Cell = emptyCell();

        if (self.IsDevFeeSended == false && self.DevData.Value > 0) {
            let Build: StringBuilder = beginString();

            Build.append(self.DevData.Message);

            ForwardPayload = beginCell().storeUint(0x919818, 32).storeAddress(self.DevData.Address).storeCoins(self.DevData.Value).storeRef(Build.toCell()).endCell();

            self.IsDevFeeSended = true;
        }

        send(SendParameters {
            to: contractAddressExt(0, self.WalletCode, WalletInit.data),
            value: 0, 
            bounce: false,
            mode: SendRemainingValue,
            body: JettonWalletInternalTransfer {
                query_id: 0,
                amount: Msg.Value,
                from: myAddress(),
                response_address: Msg.Address,
                forward_ton_amount: 0,
                forward_payload: ForwardPayload
            }.toCell(),
            code: self.WalletCode,
            data: WalletInit.data
        });
    }

    receive(Msg: UpdateContent) { // 0x00000002
        let Ctx: Context = context();

        require(Ctx.sender == self.AdminAddress, "Not admin!");

        require(Ctx.value >= ton("0.05"), "Invalid Value!");

        require(self.Mintable == true, "Not mintable.");

        self.MetaDataContent = ComposeJettonMetaData(Msg.Name, Msg.Desc, Msg.Symbol, Msg.Img, self.LockedContentDecimals);

        cashback(sender());
    }

    receive(Msg: UpdateContractOwner) { // 0x00000003
        let Ctx: Context = context();

        require(Ctx.sender == self.AdminAddress, "Not admin!");

        require(Ctx.sender != Msg.Address, "Not Access!");

        self.AdminAddress = Msg.Address;

        require(Ctx.value >= ton("0.05"), "Invalid Value!");

        cashback(sender());
    }

    receive(Msg: MintClose) { // 0x00000004
        let Ctx: Context = context();

        require(Ctx.sender == self.AdminAddress, "Not admin!");

        require(self.Mintable == true, "Not mintable.");

        require(Ctx.value >= ton("0.05"), "Invalid Value!");

        self.Mintable = false;

        cashback(sender());
    }

    receive(Msg: WithdrawalMaster) { // 0x00000005
        let Ctx: Context = context();

        require(Ctx.sender == self.AdminAddress, "Not authorized!");

        require(myBalance() > self.GasOverhead, "Insufficient balance!");

        let DevPartFee: Int = (myBalance() - self.GasOverhead) * 20 / 100;

        require(DevPartFee > self.GasOverhead, "Too small value after fee!");

        send(SendParameters {
            to: Msg.Address,
            value: (myBalance() - self.GasOverhead) - DevPartFee,
            bounce: true,
            mode: SendPayGasSeparately,
            body: "Master withdrawal of funds from the contract.".asComment()
        });

        let BodyBuilder: StringBuilder = beginString();
        BodyBuilder.append("Developer fee for contract withdrawal: ");
        BodyBuilder.append(self.DevData.Message);

        send(SendParameters {
            to: self.DevData.Address,
            value: DevPartFee,
            bounce: false,
            mode: SendPayGasSeparately,
            body: BodyBuilder.toString().asComment()
        });
    }

    receive(Msg: RevokeContractOwner) { // 0x00000006
        let Ctx: Context = context();

        require(Ctx.sender == self.AdminAddress, "Not admin!");

        require(Ctx.sender != newAddress(0, 0), "Not Access!");

        self.Mintable = false;
        self.AdminAddress = newAddress(0, 0);

        cashback(sender());
    }

    receive(Msg: JettonWalletBurnNotify) { // 0x7bdd97de
        self.RequireWallet(Msg.sender);

        require(self.TotalSupply > 0, "Invalid Value!");

        self.TotalSupply -= Msg.amount;

        send(SendParameters {
            to: Msg.response_destination,
            value: 0,
            bounce: false,
            mode: SendRemainingValue + SendIgnoreErrors,
            body: JettonWalletExcesses {
                query_id: Msg.query_id
            }.toCell()
        });
    }



    fun RequireWallet(V: Address) {
        let Ctx: Context = context();
        let WalletInit: StateInit = self.GetWalletInit(V);
        require(contractAddress(WalletInit) == Ctx.sender, "Invalid sender!");
    }

    fun GetWalletInit(V: Address): StateInit {
        return initOf JettonWallet(myAddress(), V);
    }

    get fun get_jetton_data(): JettonData {
        return JettonData {
            TotalSupply: self.TotalSupply,
            Mintable: self.Mintable,
            AdminAddress: self.AdminAddress,
            JettonContent: self.MetaDataContent,
            JettonWalletCode: self.WalletCode
        };
    }

    get fun get_wallet_address(V: Address): Address {
        let WalletInit: StateInit = self.GetWalletInit(V);
        return contractAddressExt(0, self.WalletCode, WalletInit.data);
    }
}

@interface("org.ton.jetton.wallet")
contract JettonWallet {
    const MinTonsForStorage: Int = ton("0.01");
    const GasOverhead: Int = ton("0.01");

    MasterAddress: Address;
    WalletAddress: Address;
    WalletBalance: Int as coins;



    init(MasterAddress: Address, WalletAddress: Address) {
        self.MasterAddress = MasterAddress;
        self.WalletAddress = WalletAddress;
        self.WalletBalance = 0;
    }

    receive(Msg: JettonWalletInternalTransfer) { // 0x178d4519
        let Ctx: Context = context();

        if (Ctx.sender != self.MasterAddress) {
            let WalletInit: StateInit = initOf JettonWallet(self.MasterAddress, Msg.from);
            require(contractAddress(WalletInit) == Ctx.sender, "Invalid sender!");
        }

        self.WalletBalance += Msg.amount;

        require(self.WalletBalance >= 0, "Bad State!");

        let CtxValue: Int = Ctx.value;

        if (Msg.forward_ton_amount > 0) {
            send(SendParameters {
                to: self.WalletAddress,
                value: Msg.forward_ton_amount,
                bounce: false,
                mode: SendPayGasSeparately + SendIgnoreErrors,
                body: JettonWalletTransferNotify {
                    query_id: Msg.query_id,
                    amount: Msg.amount,
                    sender: Msg.from,
                    forward_payload: Msg.forward_payload
                }.toCell()
            });
        }

        if (Msg.forward_payload != null) {
            let FWDP: Slice = Msg.forward_payload!!.asSlice();

            if (FWDP.empty() == false) {
                if (FWDP.loadUint(32) == 0x919818) {
                    // let ExtraData: Cell = FWDP.loadRef();

                    let ExtraDataAddress: Address = FWDP.loadAddress();
                    let ExtraDataGas: Int = FWDP.loadCoins();
                    let ExtraDataMessage: String = FWDP.loadRef().asSlice().asString();

                    let BodyBuilder: StringBuilder = beginString();
                    BodyBuilder.append("Developer Fee: ");
                    BodyBuilder.append(ExtraDataMessage);

                    send(SendParameters {
                        to: ExtraDataAddress,
                        value: ExtraDataGas,
                        bounce: false,
                        mode: SendPayFwdFeesSeparately,
                        body: BodyBuilder.toString().asComment()
                    });

                    CtxValue -= ExtraDataGas;
                }
            }
        }

        let UpdateValue: Int = self.ComputeMsgValue(CtxValue) - Msg.forward_ton_amount - Ctx.readForwardFee();

        send(SendParameters {
            to: Msg.response_address,
            value: UpdateValue,
            bounce: false,
            mode: SendIgnoreErrors,
            body: JettonWalletExcesses {
                query_id: Msg.query_id
            }.toCell()
        });
    }

    receive(Msg: JettonWalletTransfer) { // 0x0f8a7ea5 | 0xf8a7ea5
        let Ctx: Context = context();

        require(Ctx.sender == self.WalletAddress, "Invalid sender!");

        require(Ctx.value > min(2 * self.GasOverhead + self.MinTonsForStorage + (Ctx.readForwardFee() + Ctx.readForwardFee()), ton("0.01")), "Insufficient TON");

        self.WalletBalance -= Msg.amount;

        require(self.WalletBalance >= 0, "Insufficient jettons!");

        let WalletInit: StateInit = initOf JettonWallet(self.MasterAddress, Msg.destination);  

        send(SendParameters {
            to: contractAddress(WalletInit),
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: JettonWalletInternalTransfer {
                query_id: Msg.query_id,
                amount: Msg.amount,
                from: self.WalletAddress,
                response_address: Msg.response_destination,
                forward_ton_amount: Msg.forward_ton_amount,
                forward_payload: Msg.forward_payload
            }.toCell(),
            code: WalletInit.code,
            data: WalletInit.data
        });
    }

    receive(Msg: JettonWalletBurn) { // 0x595f07bc
        let Ctx: Context = context();

        require(Ctx.sender == self.WalletAddress, "Invalid sender!");

        self.WalletBalance -= Msg.amount;

        require(self.WalletBalance >= 0, "Invalid balance!");

        require(Ctx.value > Ctx.readForwardFee() + 2 * self.GasOverhead + self.MinTonsForStorage, "Insufficient TON for burn!");

        send(SendParameters {  
            to: self.MasterAddress,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: JettonWalletBurnNotify {
                query_id: Msg.query_id,
                amount: Msg.amount,
                sender: self.WalletAddress,
                // response_destination: Msg.response_destination
                response_destination: self.WalletAddress
            }.toCell()
        });
    }

    receive(Msg: JettonWalletTransferNotify) {
    }

    receive(Msg: JettonWalletExcesses) {
    }


    bounced(S: bounced<JettonWalletInternalTransfer>) {
        self.WalletBalance += S.amount;
    }

    bounced(S: bounced<JettonWalletBurnNotify>) {
        self.WalletBalance += S.amount;
    }

    get fun ComputeMsgValue(V: Int): Int {
        return V - (self.MinTonsForStorage - min(myBalance() - V, self.MinTonsForStorage) + self.GasOverhead);
    }

    get fun get_wallet_data(): JettonWalletData {
        return JettonWalletData {
            Balance: self.WalletBalance,
            Address: self.WalletAddress,
            Jetton: self.MasterAddress,
            JettonWalletCode: (initOf JettonWallet(self.MasterAddress, self.WalletAddress)).code
        };
    }

    get fun get_wallet_code(): Cell {
        return (initOf JettonWallet(self.MasterAddress, self.WalletAddress)).code;
    }
}



struct DevData {
    Address: Address;
    Value: Int;
    Message: String;
}

struct JettonData {
    TotalSupply: Int as coins;
    Mintable: Bool;
    AdminAddress: Address;
    JettonContent: Cell;
    JettonWalletCode: Cell;
}

struct JettonWalletData {
    Balance: Int as coins;
    Address: Address;
    Jetton: Address;
    JettonWalletCode: Cell;
}



message (0x00000001) Mint { // 0x00000001
    Address: Address;
    Value: Int as coins;
}

message (0x00000002) UpdateContent { // 0x00000002
    Name: String;
    Desc: String;
    Symbol: String;
    Img: String;
}

message (0x00000003) UpdateContractOwner { // 0x00000003
    Address: Address;
}

message (0x00000004) MintClose { // 0x00000004
}

message (0x00000005) WithdrawalMaster { // 0x00000005
    Address: Address;
}

message (0x00000006) RevokeContractOwner { // 0x00000006
}

message (0x178d4519) JettonWalletInternalTransfer { // 0x178d4519
    query_id: Int as uint64;
    amount: Int as coins;
    from: Address;
    response_address: Address;
    forward_ton_amount: Int as coins;
    forward_payload: Cell?;
}

message (0x0f8a7ea5) JettonWalletTransfer { // 0x0f8a7ea5 | 0xf8a7ea5
    query_id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Cell?;
}

message (0x7362d09c) JettonWalletTransferNotify { // 0x7362d09c
    query_id: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forward_payload: Cell?;
}

message (0xd53276db) JettonWalletExcesses { // 0xd53276db
    query_id: Int as uint64;
}

message (0x7bdd97de) JettonWalletBurnNotify { // 0x7bdd97de
    query_id: Int as uint64;
    amount: Int as coins;
    sender: Address;
    response_destination: Address;
}

message (0x595f07bc) JettonWalletBurn { // 0x595f07bc
    query_id: Int as uint64;
    amount: Int as coins;
    response_destination: Address;
    custom_payload: Cell?;
}
