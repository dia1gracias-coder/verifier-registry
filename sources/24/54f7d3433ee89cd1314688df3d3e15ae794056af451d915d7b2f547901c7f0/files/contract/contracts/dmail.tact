import "@stdlib/deploy";


message DmailEvent {
    to: String;
    path: String;
}

contract Dmail with Deployable {
    init() {}

    receive(msg: DmailEvent) {
        emit(DmailEvent{to:msg.to,path:msg.path}.toCell());
    }
}