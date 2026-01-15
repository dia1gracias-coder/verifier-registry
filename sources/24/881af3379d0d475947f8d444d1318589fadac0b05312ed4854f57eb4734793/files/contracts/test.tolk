fun onInternalMessage(in: InMessage) {
    val msg = createExternalLogMessage(CreateExternalLogMessageOptions{dest: createAddressNone(), body: beginCell().storeSlice("world!")});
    msg.send(SEND_MODE_REGULAR);
}
