import "@stdlib/deploy";


message ClaimUpdate {
    recipients: map<Address, Int>;
}

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

    receive(msg: ClaimUpdate) {
        self.total += 1;
        self.updateClaim(msg.recipients);
    }

    receive("claim") {
        let ctx: Context = context();
        let amount = self.recipients.get(ctx.sender);
        require(amount != null && amount != 0, "No amount to claim");

        send(SendParameters{
            to: self.tokenAddress, 
            value: JettonTransferGas, 
            body: JettonTransfer{
                queryId: 42,
                amount: amount!!,
                destination: sender(),
                responseDestination: sender(),
                customPayload: null,
                forwardTonAmount: 1,
                forwardPayload: rawSlice("F")
            }.toCell(),
        });

        self.recipients.set(ctx.sender, 0);
        self.totalClaimed += amount!!;
        self.reply("claimed".asComment());
    }

    receive("test") {
        let ctx: Context = context();
        self.reply("test".asComment());
        self.total += 1;
        self.recipients.set(ctx.sender, 10);
    }

    receive(msg: WithdrawUpdate) {
        self.updateWithdraw(msg);
    }

    fun updateClaim(recipients: map<Address, Int>) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");
        let cmt: StringBuilder = beginComment();
        cmt.append("[Update]");

        foreach (recipient, amount in recipients) {
            let old = self.recipients.get(recipient);
            if (old == null) {
                self.recipients.set(recipient, amount);
            } else {
                let new = old!! + amount;
                self.recipients.set(recipient, new);
            }
            self.totalWithdraw += amount;
            cmt.append("Recipient: ");
            cmt.append(recipient.toString());
            cmt.append(" Amount: ");
            cmt.append(amount.toString());
        }

        self.total += 1;
    
        self.reply(cmt.toCell());
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
        return 100;
    }

    get fun totalRecipients(): Int {
        return self.total;
    }

    get fun totalWithdraw(): Int {
        return self.totalWithdraw;
    }

    get fun totalClaimed(): Int {
        return self.totalClaimed;
    }
}