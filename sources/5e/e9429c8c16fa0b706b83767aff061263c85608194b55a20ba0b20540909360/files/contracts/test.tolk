fun onInternalMessage(in: InMessage) {
    val msg = createExternalLogMessage(CreateExternalLogMessageOptions{dest: createAddressNone(), body: beginCell().storeSlice("w1orld!")});
    msg.send(SEND_MODE_REGULAR);
}
