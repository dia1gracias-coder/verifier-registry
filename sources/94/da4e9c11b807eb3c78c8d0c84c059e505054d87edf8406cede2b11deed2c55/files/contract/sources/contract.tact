import "@stdlib/deploy";


message ClaimUpdate {
    recipients: map<Address, Int>;
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

contract CocoMonContract with Deployable {
    owner: Address;
    tokenAddress: Address;
    recipients: map<Address, Int>;

    init(tokenAddress: Address) {
        self.owner = context().sender;
        self.tokenAddress = tokenAddress;
    }

    receive(msg: ClaimUpdate) {
        self.updateClaim(msg.recipients);
    }

    fun updateClaim(recipients: map<Address, Int>) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");

        foreach (recipient, amount in recipients) {
            let cmt: StringBuilder = beginComment();
            let old = self.recipients.get(recipient);
            if (old == null) {
                self.recipients.set(recipient, amount);
            } else {
                let new = old!! + amount;
                self.recipients.set(recipient, new);
            }
        }

        self.reply("sent".asComment());
    }

    receive(msg: Claim) {
        let ctx: Context = context();
        let amount = self.recipients.get(ctx.sender);
        require(amount != null && amount != 0, "No amount to claim");

        require(msg.amount <= amount!!, "Amount to claim is too big");

        send(SendParameters{
            to: self.tokenAddress, 
            value: JettonTransferGas, 
            body: JettonTransfer{
                queryId: 42,
                amount: msg.amount - amount!!,
                destination: sender(),
                responseDestination: sender(),
                customPayload: null,
                forwardTonAmount: 1,
                forwardPayload: rawSlice("F")
            }.toCell(),
        });

        self.recipients.set(ctx.sender, msg.amount - amount!!);
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
}
