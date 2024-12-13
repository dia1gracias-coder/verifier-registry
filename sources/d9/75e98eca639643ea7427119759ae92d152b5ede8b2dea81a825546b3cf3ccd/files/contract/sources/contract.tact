import "@stdlib/deploy";

message WithdrawUpdate {
    recipient: Address;
    amount: Int;
}

const JettonTransferGas: Int = ton("0.05");

message(0xf8a7ea5) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell? = null;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

message Claim {
    amount: Int as coins;
}

struct JettonWalletData {
    balance: Int as coins;
    ownerAddress: Address;
    jettonMasterAddress: Address;
    jettonWalletCode: Cell;
}

message(0xf8a7ea5) TokenTransfer {
    query_id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}

contract MimiappContract with Deployable {
    owner: Address;
    tokenAddress: Address;
    recipients: map<Address, Int>;
    total: Int;
    totalClaimed: Int;
    totalWithdraw: Int;

    init(tokenAddress: Address) {
        self.owner = context().sender;
        self.tokenAddress = tokenAddress;
        self.recipients = emptyMap();
        self.total = 0;
        self.totalClaimed = 0;
        self.totalWithdraw = 0;
    }

    receive("claim") {
        let ctx: Context = context();
        let amount = self.recipients.get(ctx.sender);
        require(amount != null && amount != 0, "No amount to claim");

        send(SendParameters{
            to: self.tokenAddress, 
            value: JettonTransferGas,
            mode: (SendRemainingValue + SendIgnoreErrors),
            bounce: false,
            body: TokenTransfer{
                query_id: 0,
                amount: amount!!,
                destination: sender(),
                response_destination: myAddress(),
                custom_payload: null,
                forward_payload: emptySlice(),
                forward_ton_amount:  ton("0.01"),
            }.toCell(),
        });

        self.recipients.set(ctx.sender, 0);
        self.totalClaimed += amount!!;
        self.reply("claimed".asComment());
    }

    receive(msg: WithdrawUpdate) {
        self.updateWithdraw(msg);
    }

    fun updateWithdraw(data: WithdrawUpdate) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");
        let amount = self.recipients.get(data.recipient);
        if (amount == null) {
            self.recipients.set(data.recipient, data.amount);
        } else {
            let new = amount!! + data.amount;
            self.recipients.set(data.recipient, new);
        }

        self.totalWithdraw += data.amount;
        self.total += 1;
        self.reply("Withdraw updated".asComment());
    }

    get fun claimable(adr: Address): Int {
        let ctx: Context = context();
        let amount = self.recipients.get(adr);
        if (amount == null) {
            return 0;
        } else {
            return amount!!;
        }
    }

    get fun recipients(): map<Address, Int> {
        return self.recipients;
    }

    get fun healthCheck(): Int {
        return 200;
    }

    get fun total(): Int {
        return self.total;
    }

    get fun totalWithdraw(): Int {
        return self.totalWithdraw;
    }

    get fun totalClaimed(): Int {
        return self.totalClaimed;
    }

    get fun tokenAddr(): Address {
        return self.tokenAddress;
    }

    get fun owner(): Address {
        return self.owner;
    }

    get fun tokenBalance(): Int {
        return myBalance();
    }
}