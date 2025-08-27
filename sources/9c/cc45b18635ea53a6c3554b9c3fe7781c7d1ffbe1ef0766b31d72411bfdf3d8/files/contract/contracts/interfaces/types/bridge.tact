message(0x5386a723) MsgDepositNative { 
    receiver: Slice; // the address on the destination network (127 bytes)
    network: Slice; // the name of the destination network (256bits)
    // the amount of tokens is stored on the context 
    // the sender as well
}

message(0x0255667d) MsgWithdrawJetton { 
    receiver: Address; // the address that will receive the jettons on the TON network(TON wallet address)
    amount: Int ; // the amount of jettons to withdraw
    txHash: Int; //the hash of the transaction on the source network
    txNonce: Int; // the nonce of the transaction on the source network
    network: Slice; // the name of destination network (TON based)
    isWrapped: Bool; // the type of the operation(wrapped or default jetton)
    signature: Slice; // the signed message hash    
    token: Address; // the  addres of the master jetton contract

    // this data is used to send the jettons to the receiver
    bridgeJettonAddress: Address; // the jetton contract address
    forwardTonAmount: Int; // the amount of ton to be sent to the receiver
    totalTonAmount: Int; // the total amount of ton to be sent to the receiver
}

message(0x4cdec437) MsgWithdrawNative { 
    amount: Int; 
    receiver: Address; // the address that will receive the native tokens on the TON network
    txHash: Int as int257; //the hash of the transaction on the source network
    txNonce: Int; // the nonce of the transaction on the source network
    signature: Slice; // the signed message hash (512 bits)
    network: Slice; // the name of destination network (TON based)
}

message(0x12312323) MsgUpdateAdminKey {
    h: Int as uint8;
    x1: Int as uint256;
    x2: Int as uint256;
}

message(0x12121212) MsgUpdateOwner {
    newOwner: Address;
}

message(0x13131444) MsgUpdateBridgeJettonWallets {
   jettons: map<Address, Address>; // map of jetton master address to jetton wallet address
}

message(0x13131555) MsgUpdateWrappedJetton {
  wrappedMasters: map<Address, Address>; // map of jetton master address to jetton master address
}

message(0x7187b179) MsgChangeJettonMasterOwner{
    newOwner: Address;
}