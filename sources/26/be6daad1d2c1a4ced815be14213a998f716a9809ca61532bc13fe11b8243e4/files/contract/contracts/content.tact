// ════════════════════════════════════════════════════════════
//  TEP-64 on-chain metadata helpers
//
//  Avoids relying on any external JSON host — only the image
//  URL is external. Content cell layout:
//    byte 0x00 (on-chain tag) + dict<sha256(key) -> snake(value)>
// ════════════════════════════════════════════════════════════

fun snakeCell(s: String): Cell {
    let builder: StringBuilder = beginStringFromBuilder(beginCell().storeUint(0, 8));
    builder.append(s);
    return builder.toCell();
}

fun buildOnchainContent(name: String, description: String, image: String): Cell {
    let dict: map<Int as uint256, Cell> = emptyMap();
    dict.set(sha256("name"), snakeCell(name));
    dict.set(sha256("description"), snakeCell(description));
    dict.set(sha256("image"), snakeCell(image));

    return beginCell()
        .storeUint(0, 8)
        .storeMaybeRef(dict.asCell())
        .endCell();
}
