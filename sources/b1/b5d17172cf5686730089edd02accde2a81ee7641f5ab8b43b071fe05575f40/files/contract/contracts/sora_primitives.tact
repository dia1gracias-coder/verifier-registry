struct Bytes32 {
    data: Int as uint256;
}

/// Creates a new `Bytes32` instance filled with zeros.
fun newBytes32(): Bytes32 {
    return Bytes32{data: 0};
}

extends fun storeBytes32(self: Builder, bytes: Bytes32): Builder {
    return self.storeUint(bytes.data, 256);
}

extends fun storeAlignedAddress(self: Builder, address: Address): Builder {
    self = self.storeUint(0, 5);
    return self.storeAddress(address);
}