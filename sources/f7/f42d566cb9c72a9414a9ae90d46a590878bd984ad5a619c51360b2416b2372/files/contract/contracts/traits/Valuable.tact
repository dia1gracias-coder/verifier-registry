/**
 * @dev This traits provides functionality to check message values and to calculate
 * their remaining amounts for further processing.
 */
trait Valuable {
    const minStorageValue: Int = ton("0.01"); // Minimal value to cover storage fees for jetton and vesting wallets
    const gasConsumption: Int = ton("0.01");  // Minimal value to cover gas consumption for jettons and vesting wallets

    /**
     * @dev Checks if the value is enough for handling the jetton transfer message.
     * For more details please refer to
     * https://github.com/ton-blockchain/TEPs/blob/master/text/0074-jettons-standard.md#1-transfer
     */
    fun requireValue(ctx: Context) {
        let fwdFee: Int = 2 * ctx.readForwardFee();  
        let value: Int =  2 * self.gasConsumption + self.minStorageValue + fwdFee;
        require(ctx.value > min(value, ton("0.01")), "Transfer: Insufficient value"); 
    }

    /**
     * @dev Gets the remaining value to be passed along with the excesses message.
     */
    get fun getRemainingValue(value: Int): Int {
        let currentValue: Int = value;
        let tonBalanceBeforeMsg: Int = myBalance() - currentValue;
        let storageFee: Int = self.minStorageValue - min(tonBalanceBeforeMsg, self.minStorageValue);

        return currentValue - (storageFee + self.gasConsumption);
    }
}