import "collection-storage"
import "errors"
import "quote-types"

fun requiredAttachedValue(
    quote: HopprQuote,
    config: CollectionConfig,
): coins {
    val tail = quote.tail.load();
    return tail.paymentAmountBaseUnits + quote.quantity * config.itemDeploymentValue +
    config.collectionExecutionReserve +
    config.outboundMessageReserve;
}

fun validateNativePayment(incomingValue: coins, quote: HopprQuote, config: CollectionConfig) {
    assert (incomingValue >= requiredAttachedValue(quote, config)) throw HopprErrors.Underpayment;
    assert (incomingValue <= requiredAttachedValue(quote, config)) throw HopprErrors.Overpayment;
}
