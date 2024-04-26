import "@stdlib/deploy";


message DmailNFTEvent {
    to: String;
    nft: String;
}

contract DmailNFT with Deployable {
    init() {}

    receive(msg: DmailNFTEvent) {
        emit(DmailNFTEvent{to:msg.to,nft:msg.nft}.toCell());
    }
}