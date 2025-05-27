fun composeJettonMetadata(
    name: String,        // full name
    description: String, // text description of the Jetton
    symbol: String,      // "stock ticker" symbol without the $ prefix, like USDT or SCALE
    image: String,       // link to the image
    // There could be other data, see:
    // https://github.com/ton-blockchain/TEPs/blob/master/text/0064-token-data-standard.md#jetton-metadata-attributes
): Cell {
    let dict: map<Int as uint256, Cell> = emptyMap();
    dict.set(sha256("name"), name.asMetadataCell());
    dict.set(sha256("description"), description.asMetadataCell());
    dict.set(sha256("symbol"), symbol.asMetadataCell());
    dict.set(sha256("image"), image.asMetadataCell());

    return beginCell()
        .storeUint(0, 8)                // a null byte prefix
        .storeMaybeRef(dict.asCell()!!) // 1 as a single bit, then a reference
        .endCell();
}

// Prefixes the String with a single null byte and converts it to a Cell
// The null byte prefix is used to express metadata in various standards, like NFT or Jetton
inline extends fun asMetadataCell(self: String): Cell {
    return beginTailString().concat(self).toCell();
}