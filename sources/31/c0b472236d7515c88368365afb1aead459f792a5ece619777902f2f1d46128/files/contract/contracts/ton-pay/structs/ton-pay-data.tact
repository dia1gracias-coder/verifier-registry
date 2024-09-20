struct TonPayData {
    owner: Address;
    recipient: Address;
    publicKey: Int as uint256;
    usdtMasterAddress: Address;
    jettonWalletGovernedCode: Cell;
    tonPayUsdtWallet: Address;
}