import "@stdlib/deploy";
message DmailMailEvent {
    to: String;
    path: String;
}

contract DmailMail with Deployable {
    init(){}

    receive(msg: DmailMailEvent){
        emit(DmailMailEvent{to: msg.to, path: msg.path}.toCell());
    }
}