import "@stdlib/deploy";

message WithdrawUpdate {
    amount: Int as coins;
    destination: Address;
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

message(0x7362d09c) JettonTransferNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forwardPayload: Slice as remaining;
}

struct JettonWalletData {
    balance: Int as coins;
    ownerAddress: Address;
    jettonMasterAddress: Address;
    jettonWalletCode: Cell;
}

fun calculateJettonWalletAddress(
    ownerAddress: Address,
    jettonMasterAddress: Address,
    jettonWalletCode: Cell
): Address {

    let initData = JettonWalletData{
        balance: 0,
        ownerAddress,
        jettonMasterAddress,
        jettonWalletCode,
    };

    return contractAddress(StateInit{
        code: jettonWalletCode,
        data: initData.toCell(),
    });
}

contract MimiappContract with Deployable {
    owner: Address;
    tokenAddress: Address;
    recipients: map<Address, Int>;
    totalWithdrawn: Int;
    totalClaimed: Int;
    myJettonWalletAddress: Address;
    myJettonAmount: Int as coins = 0;

    init(tokenAddress: Address, jettonWalletCode: Cell) {
        self.owner = context().sender;
        self.tokenAddress = tokenAddress;
        self.recipients = emptyMap();
        self.totalWithdrawn = 0;
        self.totalClaimed = 0;
        self.myJettonWalletAddress = calculateJettonWalletAddress(
            myAddress(),
            tokenAddress,
            jettonWalletCode,
        );
    }

    receive(msg: JettonTransferNotification) {
        require(
            sender() == self.myJettonWalletAddress,
            "Notification not from your jetton wallet!",
        );

        self.myJettonAmount += msg.amount;

        // Forward excesses
        self.forward(msg.sender, null, false, null);
    }

    receive(msg: WithdrawUpdate) {
        self.updateWithdraw(msg);
        self.reply("Withdraw updated".asComment());
    }

    fun updateWithdraw(msg: WithdrawUpdate) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");

        let old = self.recipients.get(msg.destination);
        if (old == null) {
            self.recipients.set(msg.destination, msg.amount);
        } else {
            let new = old!! + msg.amount;
            self.recipients.set(msg.destination, new);
        }

        self.totalWithdrawn += msg.amount;
    }

    receive("claim") {
        let ctx: Context = context();
        let amount = self.recipients.get(ctx.sender);
        require(amount != null && amount != 0, "No amount to claim");
        require(self.myJettonAmount >= amount!!, "Not enough jettons");

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

        self.reply("Claimed".asComment());
    }

    receive("claim_test") {
        let ctx: Context = context();
        let amount = self.recipients.get(ctx.sender);
        require(amount != null && amount != 0, "No amount to claim");
        let strBuilder: StringBuilder = beginComment();
        strBuilder.append("Claimable");
        strBuilder.append(amount!!.toString());


        self.reply(strBuilder.toCell());
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

    get fun totalWithdrawn(): Int {
        return self.totalWithdrawn;
    }

    get fun totalClaimed(): Int {
        return self.totalClaimed;
    }

    get fun tokenAddress(): Address {
        return self.tokenAddress;
    }
}
