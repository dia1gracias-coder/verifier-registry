fun onInternalMessage(in: InMessage) {
    var num: uint256 = 123123123123123123123123;
    createMessage({
       dest: in.senderAddress,
       value: ton("0.05"),
       bounce: false,
       body: num.toCell(), 
    }).send(SEND_MODE_REGULAR);
}


get fun GetData(): int256 {
    return 123213123123123123123123123123;
}