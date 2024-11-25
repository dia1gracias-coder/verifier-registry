import "@stdlib/deploy";

message Add {
    amount: Int as uint32;
}

contract SampleTactContract with Deployable {

    owner: Address;
    counter: Int as uint32;

    init(owner: Address) {
        self.owner = owner;
        self.counter = 0;
    }

    fun add(v: Int) {
        
        // Check sender
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");
        
        // Update counter
        self.counter += v;
    }

    receive(msg: Add) {
        self.add(msg.amount);
    }

    receive("increment") {
        self.add(1);
        self.reply("incremented".asComment());
    }

    get fun counter(): Int {
        return self.counter;
    }
}

contract MultiSendContract with Deployable {
    owner: Address;
    tokenAddress: Address;

    init(tokenAddress: Address) {
        self.owner = context().sender;
        self.tokenAddress = tokenAddress;
    }

    fun send(recipients: map<Address, Int>) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");

        foreach (recipient, amount in recipients) {
            let cmt: StringBuilder = beginComment();
            cmt.append("Sending to ");
            cmt.append(recipient.toString());
            cmt.append(" amount ");
            cmt.append(amount.toString());

            send(SendParameters{
                to: recipient,
                value: amount,
                mode: SendIgnoreErrors,
                body: cmt.toCell()
            });

            self.reply(cmt.toCell());
        }

        self.reply("sent".asComment());
    }    
}