inline fun checkEitherForwardPayload(forwardPayload: Slice) {
    if (forwardPayload.preloadUint(1) == 1) {
        let bitsAndRefs = calculateSliceBitsAndRefs(forwardPayload);
        require(bitsAndRefs.refs == 1 && bitsAndRefs.bits == 1, "Invalid forward payload in message");
    }
}

asm fun emptyAddress(): Address {
    b{00} PUSHSLICE
}

inline fun makeTakeWalletAddressMsg(targetJettonWallet: BasechainAddress, msg: ProvideWalletAddress): Cell {
    return beginCell()
        .storeUint(TakeWalletAddressOpcode, 32)
        .storeUint(msg.queryId, 64)
        .storeBasechainAddress(targetJettonWallet)
        .storeMaybeRef(
            msg.includeAddress ?
            beginCell().storeAddress(msg.ownerAddress).endCell() :
            null
        )
        .endCell();
}

struct SliceBitsAndRefs {
    bits: Int;
    refs: Int;
}

asm fun calculateSliceBitsAndRefs(slice: Slice): SliceBitsAndRefs {
    SBITREFS
}

asm fun setCode(newCode: Cell) {
    SETCODE
}

asm fun setData(newData: Cell) {
    c4 POP
}

inline fun getJettonWalletInit(ownerAddress: Address, masterAddress: Address): StateInit {
    return initOf JettonWalletGovernance(0, 0, ownerAddress, masterAddress);
}

inline fun getJettonWalletByOwner(ownerAddress: Address, masterAddress: Address): Address {
    return contractAddress(getJettonWalletInit(ownerAddress, masterAddress));
}

inline fun getJettonBasechainWalletByOwner(ownerAddress: Address, masterAddress: Address): BasechainAddress {
    return contractBasechainAddress(getJettonWalletInit(ownerAddress, masterAddress));
}

inline fun validateAddress(addr: Address) {
    let parsed = parseStdAddress(addr.asSlice());
    require(parsed.workchain == 0, "Invalid workchain");
    require(parsed.address != 0, "Zero address not allowed");

    require(parsed.address != 0x0000000000000000000000000000000000000000000000000000000000000000, "Invalid null address");
}

inline fun forceBasechainValidation(addr: Address) {
    require(parseStdAddress(addr.asSlice()).workchain == 0, "Wrong workchain");
}

inline fun checkEitherForwardPayloadEnhanced(forwardPayload: Slice) {
    checkEitherForwardPayload(forwardPayload);

    if (forwardPayload.preloadUint(1) == 1) {
        let payloadCell = forwardPayload.loadRef();
        let bitsAndRefs = calculateSliceBitsAndRefs(payloadCell.asSlice());
        let payloadSize = bitsAndRefs.bits / 8 + bitsAndRefs.refs * 32;
        require(payloadSize <= maxForwardPayloadSize, "Forward payload too large");
    }
}
