message UpdateTaxFee {
    queryId: Int as uint64;
    fee: Int as coins;
}

trait Taxable {
    manager: Address;
    taxRate: Int as coins;
    
    receive(msg: UpdateTaxFee) {
        let ctx: Context = context();
        self.updateTaxValidate(ctx);

        self.taxRate = msg.fee;

        cashback(sender());
    }

    virtual inline fun updateTaxValidate(ctx: Context) {
        require(ctx.sender == self.manager, "Incorrect manager");
    }

    get fun taxFee(): Int {
        return self.taxRate;
    }
}