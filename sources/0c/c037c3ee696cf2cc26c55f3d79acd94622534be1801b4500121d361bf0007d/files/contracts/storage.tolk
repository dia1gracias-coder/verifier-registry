import "@stdlib/strings"

struct WalletStorage {
    jettonBalance: coins
    ownerAddress: address
    minterAddress: address
}

struct MinterStorage {
    totalSupply: coins

    /// Always null for this fixed-supply minter.
    /// Kept in storage only so source/data audit clearly shows revoked admin state.
    adminAddress: address?

    /// Always null for this fixed-supply minter.
    nextAdminAddress: address?

    metadata: cell

    /// Owner that receives the whole initial fixed supply.
    initialOwnerAddress: address

    /// Once true, initial supply distribution can never run again.
    supplyInitialized: bool
}

fun MinterStorage.load(): MinterStorage {
    return MinterStorage.fromCell(contract.getData());
}

fun MinterStorage.save(self) {
    contract.setData(self.toCell());
}

fun WalletStorage.load(): WalletStorage {
    return WalletStorage.fromCell(contract.getData());
}

fun WalletStorage.save(self) {
    contract.setData(self.toCell());
}

struct JettonWalletDataReply {
    jettonBalance: coins
    ownerAddress: address
    minterAddress: address
    jettonWalletCode: cell
}

struct JettonDataReply {
    totalSupply: int
    mintable: bool
    adminAddress: address?
    jettonContent: Cell<OnchainMetadataReply>
    jettonWalletCode: cell
}

struct (0x00) OnchainMetadataReply {
    contentDict: map<uint256, string_prefixed0x>
}
