// Structure representing the initialization data for an individual NFT item.
struct NFTItemInitData {
    index: Int as uint64;           // Index of the NFT item in the collection.
    collectionAddress: Address;     // Address of the NFT collection this item belongs to.
}


// Helper function to calculate the expected address of an NFT item.
inline fun calculateNFTAddress(index: Int, collectionAddress: Address, nftCode: Cell): Address {
    let initData : NFTItemInitData = NFTItemInitData{
        index,
        collectionAddress,
    };
    return contractAddress(StateInit{code: nftCode, data: initData.toCell()});
}
