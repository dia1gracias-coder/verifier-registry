message UpdatePublicKey {
    publicKey: Int as uint256;
}

message UpdateJettonWalletGoverned {
    usdtMasterAddress: Address?;
    jettonWalletGovernedCode: Cell?;
}

message UpdateRecipient {
    recipient: Address;
}