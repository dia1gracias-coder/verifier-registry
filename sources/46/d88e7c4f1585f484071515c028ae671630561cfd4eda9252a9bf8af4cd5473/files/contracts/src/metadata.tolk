import "@stdlib/strings"

struct (0x01) OffchainMetadataReply {
    string: string
}

fun serialContent(index: int): string {
    var b = StringBuilder.create();
    // Contract item 0 maps to production metadata 1.json, and item 9999 maps
    // to 10000.json. This keeps TEP-62 enumeration independent from filenames.
    b.appendInt(index + 1);
    b.append(".json");
    return b.build();
}

fun joinMetadata(baseUri: string, suffix: string): Cell<OffchainMetadataReply> {
    var b = StringBuilder.create();
    b.append(baseUri);
    b.append(suffix);
    return OffchainMetadataReply { string: b.build() }.toCell();
}
