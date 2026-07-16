import "./messages";

struct SliceBitsAndRefs {
    bits: Int;
    refs: Int;
}

asm fun calculateSliceBitsAndRefs(slice: Slice): SliceBitsAndRefs {
    SBITREFS
}

inline fun checkEitherForwardPayload(forwardPayload: Slice) {
    if (forwardPayload.preloadUint(1) == 1) {
        let size = calculateSliceBitsAndRefs(forwardPayload);
        require(size.refs == 1 && size.bits == 1, "Invalid forward payload");
    }
}

inline fun makeTakeWalletAddressMessage(
    targetWallet: BasechainAddress,
    msg: ProvideWalletAddress,
): Cell {
    return beginCell()
        .storeUint(TakeWalletAddressOpcode, 32)
        .storeUint(msg.queryId, 64)
        .storeBasechainAddress(targetWallet)
        .storeMaybeRef(
            msg.includeAddress
                ? beginCell().storeAddress(msg.ownerAddress).endCell()
                : null,
        )
        .endCell();
}
