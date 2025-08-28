struct NftData {
    deployed: Bool;
    index: Int;
    collection: Slice;
    owner: Slice;
    content: Cell;
}

trait VirtualNFT {
    get fun get_nft_data(): NftData {
        let addr_none = beginCell().storeUint(0, 2).endCell().beginParse();

        return NftData{
        deployed: true,
        index: 0,
        collection: addr_none,
        owner: addr_none,
        content: emptyCell()
        };
    }
}
