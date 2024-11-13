struct JettonWalletData {
    totalSupply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell;
    walletCode: Cell;
}

struct WalletData {
    balance: Int;
    owner: Address;
    master: Address;
    walletCode: Cell;
}

struct PrivateSaleWalletData {
    balance: Int;
    owner: Address;
    master: Address;
}

struct ClaimData {
    startTime: Int as uint32;
    endTime: Int as uint32;
    claimable: Bool;
}

struct SaleData {
    startTime: Int as uint32;
    endTime: Int as uint32;
    stopped: Bool;
    price: Int as coins;
    minBuyToken: Int as uint256;
    maxBuyToken: Int as uint256;
}