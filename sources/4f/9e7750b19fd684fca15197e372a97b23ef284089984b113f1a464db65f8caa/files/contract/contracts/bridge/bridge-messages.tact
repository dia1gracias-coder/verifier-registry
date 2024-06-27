/**
* Event emitted when tokens are received by this contract.
*/
message SentInstallment {
    tx_hash: Int;
}

message ReceivedInstallment {
    tx_hash: Int;
}

/**
* Event emitted when tokens are sent from this contract.
*/

message Installment {
    from_chain: Int as uint64;
    target_chain: Int as uint64;
    amount: Int as coins;
    nonce: Int;
    from_token: Cell;
    to_token: Cell;
    recepient: Address;
}
struct SignerAndSignature {
    signature: Slice;
    key: Int as uint256;
}

message ReceiveInstallment {
    installment: Installment;
    signatures: map<Int, SignerAndSignature>;
    len: Int;
    tx_hash: Int as uint256;
    id: Int;
}

/**
* The endpoint to be used to freeze ton inside a contract.
*/
message FreezeTon {
    target_chain: Int as uint64;
    to_token: Cell;
    to: Cell;
    from_token: Cell;
    amount: Int as coins;
}

/**
* The message to add a new native contract to the native contracts mapping.
*/
message MapContract {
    token_id: Int;
    token_symbol: String;
    contract: Address;
    decimals: Int as uint8;
    fee: Int;
    fee_decimals: Int;
    swap_address: Address;
    token_bridge_wallet_address: Address;
}


/**
* A message to set the chain fee for a chain.
* chain_id: ID of the chain.
* fee: Fees in integer.
*/
message SetChainFee {
    chain_id: Int as uint64;
    fee: Int as uint256;
}

/*
* An installment in is an installment that is coming from outside to this chain.
* amount: Amount of tokens.
* to: Target Address of the receiver.
* target_chain: Chain nonce of the target chain.
* token_id: The id of the token to be sent.
*/
struct OutgoingTransaction {
    id: Int as uint256;
    amount: Int as coins;
    from_token: Cell;
    to_token: Cell;
    to: Cell;
    target_chain_id: Int as uint64;
}

struct IncomingTransaction {
    id: Int as uint256;
    amount: Int as coins;
    from_token: Cell;
    to_token: Cell;
    target_chain_id: Int as uint64;
    to: Address;
}
/*
* An installment out is an installment that is being sent to outside destination chain.
* amount: Amount of tokens.
* to: Target Address of the receiver.
* target_chain: Chain nonce of the target chain.
* token_id: The id of the token to be sent.
*/
struct InstallmentOut {
    amount: Int as uint256;
    to: String;
    target_chain: Int as uint64;
    token_id: Int;
}
/**
* A struct used to store token information.
* address: Address of the token
* decimals: Amount of decimals that token has.
*/
struct Token {
    symbol: String;
    address: Address;
    swap_address: Address;
    decimals: Int as uint8;
    fee: Int;
    fee_decimals: Int;
    token_bridge_wallet_address: Address;
}

message UpdateBaseUri {
    new_base_uri: String;
}
message UpdateTransferFee {
    new_fee: Int;
}
message RemoveMappedContract {
    token_id: Int as uint256;
}