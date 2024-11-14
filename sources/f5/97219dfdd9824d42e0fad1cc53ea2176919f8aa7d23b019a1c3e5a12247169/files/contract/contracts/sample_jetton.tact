import "@stdlib/deploy";
import "./jetton.tact";
import "./messages.tact";

contract SampleJetton with Jetton {

    const minTonsForStorage: Int = ton("0.01");
    const gasConsumption: Int = ton("0.01");

    const ONE_TON_AMOUNT: Int = ton("1");


    totalSupply: Int as coins;
    owner: Address;
    content: Cell?;
    mintable: Bool;

    price: Int as coins;
    availableBalance: Int as coins;

    // Initialize the Master Contract with owner address and content
    init(owner: Address, content: Cell, max_supply: Int, price: Int) 
    {
        self.totalSupply = max_supply;      // Setted to max amount: 999999
        self.owner = owner;
        self.mintable = true;
        self.content = content;
        self.price = price;

        self.availableBalance = max_supply;
    }

    // Mint Message from Deployer
    receive(msg: Mint) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Only Owner");
        require(self.mintable, "Mintable is Disabled");

        self.availableBalance += msg.amount;
        self.mint(msg.receiver, msg.amount, self.owner);
    }

    receive("Swap") 
    {
        let ctx: Context = context();
        
        // Gas checks
        let fwdFee: Int = ctx.readForwardFee() * 2;  
        let finalPrice: Int = (2 * (self.gasConsumption + self.minTonsForStorage + fwdFee));
        
        require(self.availableBalance > 0, "Invalid Balance");
        require(ctx.value >= finalPrice, "Invalid Price!"); 

        // Calculate available TOKEN then Send it to Sender Address
        let amountToSend: Int = (ctx.value * self.ONE_TON_AMOUNT) / self.price;

        // dump(ctx.value);
        // dump(ctx.value.toCoinsString());

        // dump(self.price);
        // dump(self.price.toCoinsString());

        // dump(amountToSend);
        // dump(amountToSend.toCoinsString());

        require(self.availableBalance >= amountToSend, "Over Amount");

        self.availableBalance -= amountToSend;

        // Send Jetton and TON to Jetton Address
        self.sendTo(ctx.sender, amountToSend, finalPrice, ctx.sender);
    }

    receive(msg: SetPrice){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Only Owner");

        self.price = msg.amount;
    }

    receive("Close Mint"){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Only Owner");
        require(self.mintable, "Mintable is Disabled Already");

        self.mintable = false;
    }

    receive("Destroy"){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Only Owner");

        send(SendParameters{
            to: self.owner,
            value: 0,
            mode: SendRemainingBalance | SendDestroyIfZero,
            body: "Master Destroyed".asComment(),
        });
    }

    receive(msg: Withdraw){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Only Owner");

        let target: Address = self.owner;

        if(msg.to != null){
            target = msg.to!!;
        } 

        let fwdFee: Int = ctx.readForwardFee() * 2;  
        let finalPrice: Int = (2 * (self.gasConsumption + self.minTonsForStorage + fwdFee));

        require(myBalance() > finalPrice, "Balance is not Enough");

        let targetAmount: Int = myBalance() - msg.amount - finalPrice;

        require(targetAmount > 0, "Target Amount is not Enough");

        let sendingValue: Int = myBalance() - targetAmount;

        self.replyToSender("You will get ", sendingValue.toString(), " TON");

        send(SendParameters{
            to: target,
            value: sendingValue,
            mode: SendRemainingValue | SendIgnoreErrors,
            body: "Withdraw Amount".asComment(),
        });
    }

    fun replyToSender(msg1: String, msg2: String, msg3: String){
        let sb: StringBuilder = beginString();
        sb.append(msg1);
        sb.append(msg2);
        sb.append(msg3);

        self.reply(sb.toString().asComment());
    }

    get fun balance(): Int {
        return myBalance();
    }

    get fun sample_jetton_data(): SampleJettonData {
        let code: Cell = self.getJettonWalletInit(myAddress()).code;
        return SampleJettonData{ 
            totalSupply: self.totalSupply, 
            availableBalance: self.availableBalance,
            price: self.price,
            mintable: self.mintable, 
            owner: self.owner, 
            content: self.content, 
            walletCode: code
        };
    }
}
