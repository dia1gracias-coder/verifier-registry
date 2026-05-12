type AddressFlagDict = map<address, bool>

struct WalletStorage {
    jettonBalance: coins
    ownerAddress: address
    minterAddress: address
    canSell: bool
}

struct MinterStorage {
    totalSupply: coins
    adminAddress: address
    content: cell
    jettonWalletCode: cell
    buyTaxPercent: uint8
    sellTaxPercent: uint8
    feeWalletAddress: address
    whitelistEnabled: bool
    paused: bool
    whitelistAddresses: AddressFlagDict
    dexPoolAddresses: AddressFlagDict
}

fun MinterStorage.load() {
    return MinterStorage.fromCell(contract.getData())
}

fun MinterStorage.save(self) {
    contract.setData(self.toCell())
}

fun WalletStorage.load() {
    return WalletStorage.fromCell(contract.getData())
}

fun WalletStorage.save(self) {
    contract.setData(self.toCell())
}

fun AddressFlagDict.addFlag(mutate self, address: address) {
    self.set(address, true)
}

fun AddressFlagDict.removeFlag(mutate self, address: address) {
    self.delete(address)
}

fun AddressFlagDict.isFlagSet(self, address: address) {
    return self.exists(address)
}