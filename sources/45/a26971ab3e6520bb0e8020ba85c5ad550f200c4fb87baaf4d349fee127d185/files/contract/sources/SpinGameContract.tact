import "@stdlib/deploy";
import "@stdlib/ownable";

message Withdraw {
    amount: Int as coins;
}

message TestSpinMessage {
    userAddress: Address;
    changeValue: Int as int8;
    spinAmount: Int as coins;
}

contract SpinWheel with Deployable {
    owner: Address;
    userBettingAmount : map<Address, Int>;
    const MinTonForStorage: Int = ton("0.01"); // enough for 1 KB of storage for 2.5 years
    
    init(owner: Address) {
        self.owner = owner;
        self.userBettingAmount=emptyMap();
    }

    
    receive("Deposit") {
        let amount: Int = context().value;
        if (self.userBettingAmount.get(sender()) != null) {
            amount += self.userBettingAmount.get(sender())!!;
        }
        self.userBettingAmount.set(sender(),amount);
    }


    receive(msg: TestSpinMessage) {
        require(sender()== self.owner,"Only Owner can access this");
        let userAddress: Address = msg.userAddress;
        let changeValue: Int = msg.changeValue;
        let spinAmount: Int = msg.spinAmount;
        if(self.userBettingAmount.get(userAddress) != null) {
            let userAmount: Int = self.userBettingAmount.get(userAddress)!!;
            self.userBettingAmount.set(userAddress,userAmount-(changeValue-1)*spinAmount);
        }

    }

    // this will withdraw the entire balance of the contract and leave 0
    receive("withdraw all") {
        require(sender() == self.owner, "Only deployer is allowed to withdraw");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors
        });
    }

    // this will withdraw a specific amount but leave 0.01 for storage rent costs
    receive(msg: Withdraw) {
        require(sender() == self.owner, "Only deployer is allowed to withdraw");
        let amount: Int = min(msg.amount, myBalance() - context().value - self.MinTonForStorage);
        require(amount > 0, "Insufficient balance");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: amount,
            mode: SendRemainingValue + SendIgnoreErrors
        });
    }

    get fun userBalance(address: Address): Int {
        if (self.userBettingAmount.get(address) != null) {
            return self.userBettingAmount.get(address)!!;
        }
        return 0;
    }

}