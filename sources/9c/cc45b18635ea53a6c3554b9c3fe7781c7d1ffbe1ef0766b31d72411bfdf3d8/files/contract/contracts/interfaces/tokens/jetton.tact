// This file defines interfaces for Jetton smart contracts in accordance with TEP-74.
// TEP-74 specifies the standard for fungible tokens (Jettons) on the TON blockchain.
// For more details, refer to the TEP-74 specification: https://github.com/ton-blockchain/TEPs/blob/master/text/0074-jettons-standard.md

// https://docs.tact-lang.org/cookbook/jettons/
// Jetton op-codes described here:
// https://github.com/ton-blockchain/token-bridge-func/blob/3346a901e3e8e1a1e020fac564c845db3220c238/src/func/jetton-bridge/op-codes.fc#L11C22-L11C24

// Jettonn messages
message(0x7362d09c) MsgJettonTransferNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    owner: Address;
    forwardPayload: Slice; 
}

message(0xf8a7ea5) MsgJettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell? = null;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

message(0x595f07bc) MsgJettonBurn {
    queryId: Int as uint64;
    amount: Int as coins; // the amount of jettons to burn
    responseDestination: Address?; // user address to receive the execut message
    
    forwardAddress: Address?; // the Bridge address 
    forwardTonAmount: Int as coins; // the amount of TON to be sent to the Bridge address(to cover fee)
    forwardPayload: Slice as remaining; // the payload to be sent to the Bridge address
}

message (0x7bdd97de) MsgJettonBurnNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    owner: Address;  
    forwardPayload: Slice;
}

// Jetton masster messages 
message (0x15) MsgMintTokens {  
    queryId: Int as uint64;
    destination: Address;
    totalTonAmount: Int as coins;

    jettonAmount: Int as coins;
    mintMsg: Cell;
}

// This message is used on the MsgMintTokens as a ref
message (0x178d4519) MsgInternalTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    forwardTonAmount: Int as coins;
}

message (0x3) MsgChangeTokenAdmin{  
    queryId: Int as uint64;
    newAdmin: Address;
}

message (0xd53276db) MsgExcesses{
    queryId: Int as uint64;
}