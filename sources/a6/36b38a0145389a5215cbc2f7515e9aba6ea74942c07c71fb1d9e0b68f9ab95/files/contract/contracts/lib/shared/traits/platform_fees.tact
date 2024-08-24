import "./accounting.tact";

trait PlatformFees with Accounting {
    treasury_address: Address;

    fun payPlatformFee(amount: Int, comment: String) {
        send(SendParameters{
            to: self.treasury_address,
            value: amount,
            mode: SendIgnoreErrors,
            body: comment.asComment()
        });
    }

    fun payPlatformFeeWithFullBalance(comment: String) {
        send(SendParameters{
            to: self.treasury_address,
            value: 0,
            mode: SendIgnoreErrors + SendRemainingValue,
            body: comment.asComment()
        });
    }
}
