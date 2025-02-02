import "../messages";
import "../feeContract/getCommission";

@interface("org.ton.jetton.wallet")
contract JettonDefaultWallet with Ownable{
    const minTonsForStorage: Int = ton("0.03");
    const gasConsumption: Int = ton("0.013");

    balance: Int as coins = 0;
    owner: Address;
    master: Address;
    feeContractAddress: Address;
    fee_wallet_address: Address;
    is_dex_vault: Bool = false;

    init(owner: Address, master: Address) {
        self.balance = 0;
        self.owner = owner;
        self.master = master;

        self.feeContractAddress = contractAddress(initOf FeeContract(address("EQAP0qitT_2nYlUzShQIo6kysygIJzk-SwyKin7TKN5HlfLw")));
        self.fee_wallet_address = contractAddress(initOf JettonDefaultWallet(address("UQDEVyQP76fX9SxRbvTj0AluVQmHbLLaPHh4fGkw98Xa1-OR"), self.master));
    }

//    receive(msg: Test){
//        self.requireOwner();
//        send(SendParameters{
//            to: self.feeContractAddress,
//            value: 0,
//            mode: SendRemainingValue,
//            bounce: true,
//            body: TokenTransfer{
//                query_id: msg.query_id,
//                amount: msg.amount,
//                destination: msg.destination,
//                response_destination: msg.response_destination,
//                custom_payload: msg.custom_payload,
//                forward_ton_amount: msg.forward_ton_amount,
//                forward_payload: msg.forward_payload
//            }.toCell(),
//        });
//    }

    receive(msg: TokenTransfer) {
        self.requireOwner();
        let ctx: Context = context();

        require(self.balance - msg.amount >= 0, "Invalid balance");

        let fwd_fee: Int = ctx.readForwardFee();
        let final: Int = fwd_fee * 4 +
        4 * self.gasConsumption +
        self.minTonsForStorage +
        msg.forward_ton_amount;

        require(ctx.value > final, "Invalid value");

        let is_sell: Bool = false;
        if (!msg.forward_payload.empty() && msg.forward_payload.refs() >= 1) {
            let fwdSlice: Slice = msg.forward_payload.preloadRef().beginParse();
            if (fwdSlice.bits() >= 32 && fwdSlice.loadUint(32) == 0xe3a0d482) {
                is_sell = true;
            }
        }

        if (is_sell) {
            send(SendParameters{
                to: self.feeContractAddress,
                value: 0,
                mode: SendRemainingValue,
                bounce: true,
                body: TokenTransfer{
                    query_id: msg.query_id,
                    amount: msg.amount,
                    destination: msg.destination,
                    response_destination: msg.response_destination,
                    custom_payload: msg.custom_payload,
                    forward_ton_amount: msg.forward_ton_amount,
                    forward_payload: msg.forward_payload
                }.toCell(),
            });

        } else {
            self.balance = self.balance - msg.amount;

            let init: StateInit = initOf JettonDefaultWallet(msg.destination, self.master);

            send(SendParameters{
            to: contractAddress(init),
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: TokenTransferInternal{
            query_id: msg.query_id,
            amount: msg.amount,
            from: self.owner,
            response_destination: msg.response_destination,
            forward_ton_amount: msg.forward_ton_amount,
            forward_payload:  msg.forward_payload
            }.toCell(),
            code: init.code,
            data: init.data
            });
            }
    }

    receive(msg: TokenTransferWithFee) {
        let ctx: Context = context();
        require(ctx.sender == self.feeContractAddress, "Invalid sender");
        self.balance -= msg.amount;
        require(self.balance >= 0, "Invalid balance");

        let calculated_fee: Int = msg.amount * msg.numerator / msg.denominator;
        msg.amount -= calculated_fee;

        let ton_for_fee: Int = 0;
        if (calculated_fee>0){
            ton_for_fee = ton("0.009");
        }

        let balance_befor: Int = myBalance() - ctx.value - ton_for_fee;
        if (balance_befor < self.minTonsForStorage) {
            ctx.value -= min(self.minTonsForStorage - balance_befor, ton("0.05"));
        }

        let init: StateInit = initOf JettonDefaultWallet(msg.destination, self.master);
        send(SendParameters{
            to: contractAddress(init),
            value: ctx.value,
            mode: 0,
            bounce: false,
            body: TokenTransferInternal{
                query_id: msg.query_id,
                amount: msg.amount,
                from: self.owner,
                response_destination: msg.response_destination,
                forward_ton_amount: msg.forward_ton_amount,
                forward_payload:  msg.forward_payload
            }.toCell(),
            code: init.code,
            data: init.data
        });

        if (calculated_fee>0){
            send(SendParameters{
                to: self.fee_wallet_address,
                value: ton_for_fee,
                mode: 0,
                bounce: false,
                body: TokenTransferInternal{
                    query_id: 888,
                    amount: calculated_fee,
                    from: self.owner,
                    response_destination: msg.response_destination,
                    forward_ton_amount: 0,
                    forward_payload: emptySlice()
                    }.toCell()
            });
        }
    }

    receive(msg: TokenTransferInternal) {
        let ctx: Context = context();
        if (ctx.sender != self.master) {
            let sinit: StateInit = initOf JettonDefaultWallet(msg.from, self.master);
            require(contractAddress(sinit) == ctx.sender, "Invalid sender!");
        }

        self.balance += msg.amount;
        require(self.balance >= 0, "Invalid balance");

        let msg_value: Int = self.msg_value(ctx.value);
        let fwd_fee: Int = ctx.readForwardFee();

        if (msg.forward_ton_amount > 0) {
            msg_value -= msg.forward_ton_amount - fwd_fee;

            if (!self.is_dex_vault && msg.forward_payload.refs() >= 1) {
                let fwdSlice: Slice = msg.forward_payload.preloadRef().beginParse();
                if (fwdSlice.bits() >= 32 && fwdSlice.loadUint(32) == 0x40e108d6) {
                    self.is_dex_vault = true;
                }
            }

            send(SendParameters{
                to: self.owner,
                value: msg.forward_ton_amount,
                mode: SendPayGasSeparately,
                bounce: false,
                body: TokenNotification {
                    query_id: msg.query_id,
                    amount: msg.amount,
                    from: msg.from,
                    forward_payload: msg.forward_payload
                }.toCell()
            });
        }

        if (msg.response_destination != null && msg_value > 0) {
            send(SendParameters {
            to: msg.response_destination!!,
            value: msg_value,
            bounce: false,
            body: TokenExcesses { query_id: msg.query_id }.toCell(),
            mode: SendPayGasSeparately
            });
        }
    }

    receive(msg: TokenBurn) {
        self.requireOwner();
        let ctx: Context = context();

        self.balance = self.balance - msg.amount;
        require(self.balance >= 0, "Invalid balance");

        let fwd_fee: Int = ctx.readForwardFee();
        require(ctx.value > fwd_fee + 2 * self.gasConsumption + self.minTonsForStorage, "Invalid value - Burn");

        send(SendParameters{
        to: self.master,
        value: 0,
        mode: SendRemainingValue,
        bounce: true,
        body: TokenBurnNotification {
        query_id: msg.query_id,
        amount: msg.amount,
        sender: self.owner,
        response_destination: msg.response_destination!!,
        send_excess: true
        }.toCell()
        });
    }

    fun msg_value(value: Int): Int {
        let v: Int = value;
        let ton_balance_before_msg: Int = myBalance() - v;
        let storage_fee: Int = self.minTonsForStorage - min(ton_balance_before_msg, self.minTonsForStorage);

        v = v - (storage_fee + self.gasConsumption);
        return v;
    }

    bounced(msg: bounced<TokenTransferInternal>) {
        self.balance = self.balance + msg.amount;
    }

    bounced(msg: bounced<TokenBurnNotification>) {
        self.balance = self.balance + msg.amount;
    }

    get fun get_wallet_data(): JettonWalletData {
        return JettonWalletData{
        balance: self.balance,
        owner: self.owner,
        master: self.master,
        code: (initOf JettonDefaultWallet(self.owner, self.master)).code
        };
    }

    get fun get_feeContractAddress(): Address {
        return self.feeContractAddress;
    }
}