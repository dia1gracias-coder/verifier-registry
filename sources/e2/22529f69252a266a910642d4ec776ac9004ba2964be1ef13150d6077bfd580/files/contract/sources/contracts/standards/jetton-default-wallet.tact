import "@stdlib/ownable";

contract JettonDefaultWallet {

    const minTonsForStorage: Int = ton("0.01");
    const gasConsumption: Int = ton("0.01");

    balance: Int;
    owner: Address;
    master: Address;

    init(master: Address, owner: Address) {
        self.balance = 0;
        self.owner = owner;
        self.master = master;
    }

    /**
    * Initiates transfer of jettons to recipient. Will only be invoked if message is sent by contract owner.
    *
    * @param msg The TokenTransfer message containing the following parameter:
    *       queryId: Arbitrary request number
    *       amount: Amount of transferred jettons in elementary units (nanotons)
    *       destination: Address of the new owner of the jettons
    *       responseDestination: Address to send a response with confirmation of a successful transfer and any excess TON.
    *       customPayload: Optional custom data (which is used by either sender or receiver jetton wallet for inner logic)
    *       forwardTonAmount: Amount of nanotons to be sent to the destination address
    *       forwardPayload: Optional custom data that should be sent to the destination address
    */
    receive(msg: TokenTransfer) {

        // Check sender
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");

        // Update balance
        self.balance = self.balance - msg.amount;
        require(self.balance >= 0, "Invalid balance");

        // Gas checks
        let fwdFee: Int = ctx.readForwardFee();
        let fwdCount: Int = 1;
        if (msg.forwardTonAmount > 0) {
            fwdCount = 2;
        }
        require(ctx.value > fwdCount * fwdFee + 2 * self.gasConsumption + self.minTonsForStorage, "Invalid value");
  
        // Send tokens
        let init: StateInit = initOf JettonDefaultWallet(self.master, msg.destination);
        let walletAddress: Address = contractAddress(init);
        send(SendParameters{
            to: walletAddress, 
            value: 0,
            mode: SendRemainingValue, 
            bounce: true,
            body: TokenTransferInternal{
                amount: msg.amount,
                queryId: msg.queryId,
                from: self.owner,
                responseAddress: msg.responseDestination,
                forwardTonAmount: msg.forwardTonAmount,
                forwardPayload: msg.forwardPayload
            }.toCell(),
            code: init.code,
            data: init.data
        });
    }

    /**
    * Receives jettons from sender. Will only be invoked if message is sent by the Jetton wallet contract owned by the sender.
    *
    * @param msg The TokenTransfer message containing the following parameter:
    *       queryId: Arbitrary request number
    *       amount: Amount of transferred jettons in elementary units (nanotons)
    *       from: Address of the sender
    *       responseAddress: Address to send a response with confirmation of a successful transfer and any excess TON
    *       forwardTonAmount: Amount of nanotons to be sent to the owner address
    *       forwardPayload: Optional custom data that should be sent to the destination address
    */
    receive(msg: TokenTransferInternal) {

        // Check sender
        let ctx: Context = context();
        if (ctx.sender != self.master) {
            let sinit: StateInit = initOf JettonDefaultWallet(self.master, msg.from);
            require(contractAddress(sinit) == ctx.sender, "Invalid sender");
        }

        // Update balance
        self.balance = self.balance + msg.amount;
        require(self.balance >= 0, "Invalid balance");

        // Adjust value for gas
        let msgValue: Int = ctx.value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = self.minTonsForStorage - min(tonBalanceBeforeMsg, self.minTonsForStorage);
        msgValue = msgValue - (storageFee + self.gasConsumption);

        // Forward ton
        // notify the new owner of JettonToken that the transfer is complete
        if (msg.forwardTonAmount > 0) {
            let fwdFee: Int = ctx.readForwardFee();
            msgValue = msgValue - (msg.forwardTonAmount + fwdFee);
            send(SendParameters{
                to: self.owner,
                value: msg.forwardTonAmount,
                bounce: false,
                body: TokenNotification{
                    queryId: msg.queryId,
                    amount: msg.amount,
                    from: msg.from,
                    forwardPayload: msg.forwardPayload
                }.toCell()
            });
        }

        // Cashback
        if (msg.responseAddress != null && msgValue > 0) {
            send(SendParameters{
                to: msg.responseAddress!!,
                value: msgValue,
                bounce: false,
                body: TokenExcesses{
                    queryId: msg.queryId
                }.toCell()
            });
        }
    }

    /**
    * Initiates burn of jettons. Will only be invoked if message is sent by the contract owner.
    *
    * @param msg The TokenTransfer message containing the following parameter:
    *       queryId: Arbitrary request number
    *       amount: Amount of jettons to be burnt in elementary units (nanotons)
    *       owner: Address of the owner
    *       responseAddress: Address to send a response with confirmation of a successful burn and any excess TON.
    */
    receive(msg: TokenBurn) {

        // Check sender
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");

        // Update balance
        self.balance = self.balance - msg.amount;
        require(self.balance >= 0, "Invalid balance");

        // Gas checks
        let fwdFee: Int = ctx.readForwardFee();
        require(ctx.value > fwdFee + 2 * self.gasConsumption + self.minTonsForStorage, "Invalid value");

        // Burn tokens
        send(SendParameters{
            to: self.master,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: TokenBurnNotification{
                queryId: msg.queryId,
                amount: msg.amount,
                owner: self.owner,
                responseAddress: msg.responseAddress
            }.toCell()
        });
    }

    /*
    * Refunds the transferred jettons after a bounced outgoing TokenTransferInternal or TokenBurnNotification message.
    **/
    bounced(msg: Slice) {

        // Parse bounced message
        msg.skipBits(32); // 0xFFFFFFFF
        let op: Int = msg.loadUint(32);
        let queryId: Int = msg.loadUint(64);
        let jettonAmount: Int = msg.loadCoins();
        require(op == 0x178d4519 || op == 0x7bdd97de, "Invalid bounced message");

        // Update balance
        self.balance = self.balance + jettonAmount;
    }

    /**
    * Returns the Jetton wallet data of this contract, including the init code of the Jetton wallet of the owner.
    */
    get fun get_wallet_data(): JettonWalletData {
        return JettonWalletData{
            balance: self.balance,
            owner: self.owner,
            master: self.master,
            walletCode: (initOf JettonDefaultWallet(self.master, self.owner)).code
        };
    }
}

/***************************************** JettonDefaultWallet structs *****************************************/

struct JettonWalletData {
    balance: Int;
    owner: Address;
    master: Address;
    walletCode: Cell;
}

/***************************************** JettonDefaultWallet messages *****************************************/

message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

message(0x178d4519) TokenTransferInternal {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    responseAddress: Address?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

message(0x595f07bc) TokenBurn {
    queryId: Int as uint64;
    amount: Int as coins;
    owner: Address;
    responseAddress: Address?;
}

message(0xd53276db) TokenExcesses {
    queryId: Int as uint64;
}

message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}