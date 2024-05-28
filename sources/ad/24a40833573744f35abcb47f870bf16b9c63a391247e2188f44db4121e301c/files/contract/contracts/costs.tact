import "@stdlib/ownable";

message UpdateCosts {
    storage: Int as coins;
    consumption: Int as coins;
    value: Int as coins;
}

trait Costs with Ownable {
    owner: Address;

    minTonsForStorage: Int;
    gasConsumption: Int;
    myValue: Int;

    receive(msg: UpdateCosts) {
        self.requireOwner();
        self.minTonsForStorage = msg.storage;
        self.gasConsumption = msg.consumption;
        self.myValue = msg.value;
    }

    fun calcMsgValue(val: Int): Int{
        let tonBalanceBeforeMsg: Int = myBalance() - val;
        let storageFee: Int = self.minTonsForStorage - min(tonBalanceBeforeMsg, self.minTonsForStorage);
        return val - (storageFee + self.gasConsumption);
    }
}