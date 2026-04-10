fun onInternalMessage(in: InMessage) {
    var num: uint256 = 8440158399147309856;
    var num2: coins = 123123123123231312312312;
    var cell = beginCell().storeUint(num, 256).storeAddress(contract.getAddress()).storeCoins(num2).storeBool(true).endCell();
    createMessage({
       dest: in.senderAddress,
       value: ton("123831.05"),
       bounce: true,
       body: cell.toCell(), 
    }).send(SEND_MODE_REGULAR);
}


get fun GetData(): int256 {
    return 8440158399147309856;
}