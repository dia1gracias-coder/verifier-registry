import "../../../d_config.tact";

trait Accounting {
    virtual const MIN_TON_FOR_STORAGE: Int = ton("0.03");

    virtual fun getGasConsumption(ctx: Context): Int {
        return ctx.readForwardFee();
    }

    fun getTonRecieved(ctx: Context): Int {
        return ctx.value;
    }

    fun calculateMinOperationFee(ctx: Context): Int {
        let tonBalanceBeforeMsg: Int = myBalance() - self.getTonRecieved(ctx);
        // calculate TON to keep in contract, handle case when balance is less than MIN_TON_FOR_STORAGE
        let storageFee: Int = self.MIN_TON_FOR_STORAGE - min(tonBalanceBeforeMsg, self.MIN_TON_FOR_STORAGE);
        return storageFee + self.getGasConsumption(ctx);
    }

    fun calculateSendAmountToHoldEnoughTonForStorage(): Int {
        let ctx: Context = context();
        let value: Int = ctx.value;
        return value - self.calculateMinOperationFee(ctx);
    }

    fun calculateSendAmountToHoldFeeFromRecieved(personalFee: Int): Int {
        return self.calculateSendAmountToHoldEnoughTonForStorage() - personalFee;
    }

    fun sendExcessesTo(amount: Int, to: Address, query_id: Int?) {
        let sendQueryId: Int = 0;
        if (query_id != null) {
            sendQueryId = query_id!!;
        }
        send(SendParameters{
            to: to,
            value: amount,
            mode:  SendIgnoreErrors,
            body: Excesses { query_id: sendQueryId }.toCell()
        });
    }
}
