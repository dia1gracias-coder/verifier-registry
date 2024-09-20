struct SignatureMoreInfo {
    validUtil: Int as uint32;
}
struct InfoHash {
    validUtil: Int as uint32;
    info: Cell;
}
trait SignatureVerifiable {
    publicKey: Int;

    fun checkSignature(moreInfo: SignatureMoreInfo, info: Cell, signature: Slice) {
        let infoHash: Int = InfoHash{validUtil: moreInfo.validUtil, info: info}.toCell().hash();
        require(moreInfo.validUtil > now(), "Message expired");
        require(checkSignature(infoHash, signature, self.publicKey), "Invalid signature");
    }

    get fun publicKey(): Int {
        return self.publicKey;
    }
}