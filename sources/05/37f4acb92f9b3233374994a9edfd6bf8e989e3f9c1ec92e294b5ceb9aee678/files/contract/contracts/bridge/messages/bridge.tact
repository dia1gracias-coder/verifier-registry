/**
* Cross-chain transaction details of the receive request
*
* from_chain    - the EIP-155 original chainId
* target_chain  - the EIP-155 destination chainId
* amount        - the number of sent tokens
* nonce         - a unique outgoing transaction index
* from_token    - the sent token identifier
* to_token      - the required token identifier
* recipient     - the address of the `to_token` beneficiary
*/
message Installment {
    from_chain:     Int as uint64;
    target_chain:   Int as uint64;
    amount:         Int as coins;
    nonce:          Int;
    from_token:     Cell;
    to_token:       Cell;
    recipient:      Address;
}

/**
* Combination of the public key & the signature
*
* signature - message signature
* key       - the public key of the signer
*/
struct SignerAndSignature {
    signature:      Slice;
    key:            Int as uint256;
}

/**
* The complete body of the receive message
*
* installment   - the cross-chain transaction details
* signatures    - an indexed map of {signature,public key}
* len           - the number of signatures
* tx_hash       - the keccak256 digest of the installment
* id            - the index of the TX in the original chain
*/
message ReceiveInstallment {
    installment:        Installment;
    signatures:         map<Int, SignerAndSignature>;
    len:                Int;
    tx_hash:            Int as uint256;
    id:                 Int;
}

/**
* The endpoint to be used to freeze ton inside a contract.
*
* target_chain  - the EIP-155 destination chainId
* to_token      - the symbol of the destination token
* to            - the address of the token receiver
* from_token    - the symbol of the original token
* amount        - the number of sent tokens
*/
message FreezeTon {
    target_chain:       Int as uint64;
    to_token:           Cell;
    to:                 Cell;
    from_token:         Cell;
    amount:             Int as coins;
}

/**
* An installment in is an installment that is going from outside of this chain.
*
* id                - outgoing transaction index
* amount            - number of sent tokens.
* from_token        - the symbol of the sent token
* to_token          - the symbol of the received token
* to                - the target address of the receiver.
* target_chain_id   - the EIP-155 destination chainId
*/
message OutgoingTransaction {
    id:                 Int as uint256;
    amount:             Int as coins;
    from_token:         Cell;
    to_token:           Cell;
    to:                 Cell;
    target_chain_id:    Int as uint64;
}

/**
* An installment in is an installment that is coming from outside to this chain.
*
* id                - outgoing transaction index
* amount            - number of sent tokens.
* from_token        - the symbol of the sent token
* to_token          - the symbol of the received token
* target_chain_id   - the EIP-155 destination chainId
* to                - the target address of the local TON receiver.
*/
message IncomingTransaction {
    id:                 Int as uint256;
    amount:             Int as coins;
    from_token:         Cell;
    to_token:           Cell;
    target_chain_id:    Int as uint64;
    to:                 Address;
}

/**
* An installment out is an installment that is being sent to outside destination chain.
*
* amount        - number of transferred tokens.
* to            - target address of the receiver.
* target_chain  - the EIP-155 destination chainId
* token_id      - The id of the token to be sent.
*/
struct InstallmentOut {
    amount:             Int as uint256;
    to:                 String;
    target_chain:       Int as uint64;
    token_id:           Int;
}

// ================  LP  ================

message ReleaseTokens {
    to:                     Address;
    amount:                 Int;
    body:                   Cell?;
}


// JETTON MESSAGES

message(0x7bdd97de) JettonBurnNotification {
    query_id:           Int as uint64;      // arbitrary request number
    amount:             Int as coins;       // amount of jettons to burn
    sender:             Address;            // address of the sender of the jettons
    response_destination: Address;          // address where to send a response with confirmation of a successful burn and the rest of the incoming message coins.
    forward_ton_amount: Int as coins;       // the amount of nanotons to be sent to the destination address.
    forward_payload:    Slice as remaining; // optional custom data that should be sent to the destination address.
}

message(0x89b71d09) JettonMint {
    origin:             Address;            // address of origin mint request (may be wallet v4)
    receiver:           Address;            // address of receiver
    amount:             Int;                // amount of jettons to mint
    custom_payload:     Cell?;              // optional custom data
    forward_ton_amount: Int as coins;
    forward_payload:    Slice as remaining;
}

message(0xf8a7ea5)  JettonTransfer {
    query_id:           Int as uint64;
    amount:             Int as coins;
    destination:        Address;
    response_destination: Address?;
    custom_payload:     Cell? = null;
    forward_ton_amount: Int as coins;
    forward_payload:    Cell?; // slightly adjusted
}

message(0x7362d09c) TokenTransferNotification {
    query_id:           Int as uint64;      // arbitrary request number
    amount:             Int as coins;       // amount of jettons to transfer
    sender:             Address;            // address of the sender of the jettons
    forward_payload:    Slice as remaining; // optional custom payload
}

message(0xd53276db) TokenExcesses {
    query_id:           Int as uint64;
}

// ================ SWAP ================


// message(0x25938561) StonFiSwap {
//     askJettonWalletAddress: Address;
//     refundAddress: Address;
//     excessesAddress: Address;
//     __gap: Int as uint128; // To align with cell alignment of ston.
//     minAskAmount: Int as coins;
//     receiverAddress: Address;
//     customPayloadForwardGasAmount: Int as coins;
//     customPayload: Cell?;
//     refundForwardGasAmount: Int as coins; 
//     refundPayload: Cell?;
//     referralValue: Int as uint16;
//     referralAddress: Address?;
// }

// https://docs.tact-lang.org/cookbook/dexes/stonfi/#swaps

// https://docs.tact-lang.org/cookbook/dexes/dedust/

message(0x6664de2a) StonfiSwap {
    otherTokenWallet:   Address;
    refundAddress:      Address;
    excessesAddress:    Address;
    deadline:           Int as uint64;
    additionalData:     SwapAdditionalData;
}

struct SwapAdditionalData {
    minOut:             Int as coins    = 1;
    receiverAddress:    Address;
    fwdGas:             Int as coins    = 0;
    customPayload:      Cell?           = null;
    refundFwdGas:       Int as coins    = 0;
    refundPayload:      Cell?           = null;
    refFee:             Int as uint16   = 10;
    referralAddress:    Address?        = null;
}

const FeeSwapJettonToJetton: Int = ton("0.3");

const FeeSwapJettonToJettonFwd: Int = ton("0.24");
