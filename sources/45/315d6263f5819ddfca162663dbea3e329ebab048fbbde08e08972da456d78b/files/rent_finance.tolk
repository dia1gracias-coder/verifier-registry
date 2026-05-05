import "storage"
import "messages"

// month is encoded in bits 55-48 so the bounce handler can restore month state.
// Use DISPUTE_MONTH (255) for dispute resolution transfers that have no specific month.
const DISPUTE_MONTH: int = 255;

fun sendRentToLandlord(mutate storage: RentStorage, month: uint8, queryId: uint56, amount: coins | null) {
    var newQueryId = makeQueryId(Purpose.RENT as uint8, month, queryId);
    val wallet: address = storage.extra.load().administrative.load().jettonWallet!;
    sendJettons(wallet, storage.extra.load().clients.load().landlord, amount != null ? amount! : storage.monthRent, newQueryId, ton("0.05"));
}

fun sendRentToTenant(mutate storage: RentStorage, month: uint8, queryId: uint56, amount: coins | null) {
    var newQueryId = makeQueryId(Purpose.RENT as uint8, month, queryId);
    val wallet: address = storage.extra.load().administrative.load().jettonWallet!;
    sendJettons(wallet, storage.extra.load().clients.load().tenant, amount != null ? amount! : storage.monthRent, newQueryId, ton("0.05"));
}

fun sendDepositToLandlord(mutate storage: RentStorage, queryId: uint56, amount: coins) {
    var newQueryId = makeQueryId(Purpose.DEPOSIT as uint8, 0, queryId);
    val wallet: address = storage.extra.load().administrative.load().jettonWallet!;
    sendJettons(wallet, storage.extra.load().clients.load().landlord, amount, newQueryId, ton("0.05"));
}

fun sendDepositToTenant(mutate storage: RentStorage, queryId: uint56, amount: coins) {
    var newQueryId = makeQueryId(Purpose.DEPOSIT as uint8, 0, queryId);
    val wallet: address = storage.extra.load().administrative.load().jettonWallet!;
    sendJettons(wallet, storage.extra.load().clients.load().tenant, amount, newQueryId, ton("0.05"));
}

// queryId layout: [purpose: 8 bits][month: 8 bits][nonce: 48 bits]
fun makeQueryId(purpose: uint8, month: uint8, nonce: uint56) {
    return ((purpose as uint64) << 56) | ((month as uint64) << 48) | (nonce & 0xFFFFFFFFFFFF);
}

fun sendJettons(
    myJettonWallet: address, // this contract's USDT jetton wallet
    recipient: address, // receiver's main address
    amount: coins,
    queryId: uint64,
    forwardTonAmount: coins,
) {
    val msg = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        value: ton("0.05"), // gas for the transfer chain
        dest: myJettonWallet,
        body: AskToTransfer {
            queryId,
            jettonAmount: amount,
            transferRecipient: recipient,
            sendExcessesTo: recipient, // or contract.getAddress()
            customPayload: null,
            forwardTonAmount,
            forwardPayload: createEmptySlice(),
        },
    });
    msg.send(SEND_MODE_REGULAR);
}
