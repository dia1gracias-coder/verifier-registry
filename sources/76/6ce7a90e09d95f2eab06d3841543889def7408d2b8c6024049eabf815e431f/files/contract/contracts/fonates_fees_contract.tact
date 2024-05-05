import "@stdlib/deploy";
message Donate {
    to: Address;
    comment: String;
}

contract FonatesFeesContract with Deployable {
    init(){}

    receive(){}

    receive(msg: Donate){
        send(SendParameters{
                to: msg.to,
                value: 0,
                mode: SendRemainingValue,
                body: msg.comment.asComment()
            }
        );
    }
}