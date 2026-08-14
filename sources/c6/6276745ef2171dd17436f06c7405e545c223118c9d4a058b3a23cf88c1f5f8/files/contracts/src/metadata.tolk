import "@stdlib/strings"

struct (0x01) OffchainMetadataReply {
    string: string
}

fun serialContent(index: int): string {
    var b = StringBuilder.create();
    b.appendInt(index);
    b.append(".json");
    return b.build();
}

fun joinMetadata(baseUri: string, suffix: string): Cell<OffchainMetadataReply> {
    var b = StringBuilder.create();
    b.append(baseUri);
    b.append(suffix);
    return OffchainMetadataReply { string: b.build() }.toCell();
}
