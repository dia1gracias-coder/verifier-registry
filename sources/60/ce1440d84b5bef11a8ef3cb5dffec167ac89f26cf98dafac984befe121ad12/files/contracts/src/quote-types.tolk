/// Canonical quote payload. The signature is intentionally outside this cell.
/// Automatic Tolk serialization is the normative encoding and is mirrored by QuoteCodec.ts.
struct HopprQuote {
    version: uint16
    networkId: int32
    mintContractAddress: address
    buyerWallet: address
    quantity: uint16
    firstSerial: uint32
    lastSerial: uint32
    tail: Cell<HopprQuoteTail>
}

struct HopprQuoteTail {
    usdTotalNanoDollars: uint64
    paymentAssetKind: uint8
    paymentAssetId: uint256
    paymentAmountBaseUnits: coins
    validFrom: uint32
    validUntil: uint32
    crypto: Cell<HopprQuoteCrypto>
}

struct HopprQuoteCrypto {
    nonce: uint256
    signerEpoch: uint32
    metadataAssignmentCommitment: uint256
}
