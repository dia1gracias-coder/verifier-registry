struct StandardWalletStorage {
    jettonBalance: coins
    ownerAddress: address
    minterAddress: address
}

struct FixedMinterStorage {
    totalSupply: coins
    maxSupply: coins
    bootstrapAdmin: address?
    reserveController: address
    metadata: cell
}

fun StandardWalletStorage.load(): StandardWalletStorage {
    return StandardWalletStorage.fromCell(contract.getData());
}

fun StandardWalletStorage.save(self) {
    contract.setData(self.toCell());
}

fun FixedMinterStorage.load(): FixedMinterStorage {
    return FixedMinterStorage.fromCell(contract.getData());
}

fun FixedMinterStorage.save(self) {
    contract.setData(self.toCell());
}

struct StandardJettonWalletDataReply {
    jettonBalance: coins
    ownerAddress: address
    minterAddress: address
    jettonWalletCode: cell
}

struct FixedJettonDataReply {
    totalSupply: int
    mintable: bool
    // TEP-74 requires a SLICE in the getter stack even when the address is
    // `addr_none`; a nullable stack value would become TVM NULL instead.
    adminAddress: slice
    // TEP-64 content may be either an on-chain dictionary (0x00) or an
    // off-chain URI (0x01). Keep the standard getter opaque so generated
    // clients can read both representations without trying to decode one as
    // the other.
    jettonContent: cell
    jettonWalletCode: cell
}

fun FixedJettonDataReply.getAdminAddress(self): address? {
    val encoded = self.adminAddress as any_address;
    if (encoded.isNone()) {
        return null;
    }
    return encoded.castToInternal();
}

struct FixedSupplyDataReply {
    totalSupply: coins
    maxSupply: coins
    bootstrapAdmin: address?
    reserveController: address
    frozen: bool
}

struct (0x00) OnchainMetadataReply {
    contentDict: map<uint256, Cell<SnakeDataReply>>
}

struct (0x00) SnakeDataReply {
    string: string
}
