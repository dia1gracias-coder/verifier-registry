fun onInternalMessage(in: InMessage) {
    var num: uint256 = 8440158399147309856;
    createMessage({
       dest: in.senderAddress,
       value: ton("0.05"),
       bounce: false,
       body: num.toCell(), 
    }).send(SEND_MODE_REGULAR);
}


get fun GetData(): int256 {
    return 8440158399147309856;
}