import "errors"
import "quote-types"

fun verifyQuoteSignature(quote: Cell<HopprQuote>, signature: bits512, publicKey: uint256) {
    assert (publicKey != 0) throw HopprErrors.InvalidPublicKey;
    assert (
        isSignatureValid(quote.hash(), signature as slice, publicKey)
    ) throw HopprErrors.InvalidSignature;
}
