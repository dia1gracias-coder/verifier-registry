import "./sora_primitives.tact";
struct SoraTransferMessage {
    token: Address;
    sender: Address;
    recipient: Bytes32;
    amount: Int;
}
struct SoraTonTransferMessage {
    sender: Address;
    recipient: Bytes32;
    amount: Int;
}
struct SoraEncodedCall {
    data: Cell;
}

fun newEncodedCall(data: Cell): SoraEncodedCall {
    return SoraEncodedCall{data: data};
}

extends fun encode(self: SoraTransferMessage): SoraEncodedCall {
    let builder: Builder = beginCell();
    builder = builder.storeUint(0x0600, 16);
    builder = builder.storeAlignedAddress(self.token);
    builder = builder.storeAlignedAddress(self.sender);
    builder = builder.storeBytes32(self.recipient);
    builder = builder.storeUint(self.amount, 128);
    return newEncodedCall(builder.endCell());
}

extends fun encode(self: SoraTonTransferMessage): SoraEncodedCall {
    let builder: Builder = beginCell();
    builder = builder.storeUint(0x0600, 16);
    builder = builder.storeUint(0, 16); // prefix(8) + workchain(8)
    builder = builder.storeUint(0, 256); // hash
    builder = builder.storeAlignedAddress(self.sender);
    builder = builder.storeBytes32(self.recipient);
    builder = builder.storeUint(self.amount, 128);
    require(builder.bits() == 944, "Wrong call encoding");
    return newEncodedCall(builder.endCell());
}