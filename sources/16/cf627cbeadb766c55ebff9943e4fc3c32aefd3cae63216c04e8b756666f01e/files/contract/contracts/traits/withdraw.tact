trait Withdrawal {
    receive(msg: Withdraw) {
        let ctx: Context = context();
        self.validatePermissions(ctx, msg.amount);

        message(MessageParameters{
            to: msg.target_address,
            value: msg.amount,
            bounce: true,
            mode: SendPayFwdFeesSeparately,
        });
    }

    abstract fun validatePermissions(ctx: Context, amount: Int);
}
