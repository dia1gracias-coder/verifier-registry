// Generated from the verified Tact contract ABI.
contract WalletRegistry {
    storage: WalletRegistryData
    incomingMessages: WalletRegistryIncomingMessage
    thrownErrors: WalletRegistryErrors
}

struct (0x946a98b6) WalletRegistryDeploy {
    queryId: uint64
}

struct (0xcd2612b0) WalletRegistryRequestBindWallet {
    chain_type: uint256
    bind_address: uint256
}

struct (0xffe4b1a2) WalletRegistryRequestWallet {
    query_id: uint64
    chain_type: uint256
    user: address
    response_destination: address
}

struct (0x6d59d902) WalletRegistryReplyWallet {
    query_id: uint64
    response_destination: address
    user: address
    chain_type: uint256
    tactContinuation: Cell<WalletRegistryReplyWalletContinuation>
}

struct WalletRegistryReplyWalletContinuation {
    chain_address: uint256
}

struct (0x44807e69) WalletRegistryWithdrawTON {
}

struct WalletRegistryData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    query_id: uint64
    skate_gateway: address
}

type WalletRegistryIncomingMessage =
    | WalletRegistryWithdrawTON
    | WalletRegistryRequestBindWallet
    | WalletRegistryRequestWallet
    | WalletRegistryReplyWallet
    | WalletRegistryDeploy

enum WalletRegistryErrors {
    /// Stack underflow
    StackUnderflow = 2
    /// Stack overflow
    StackOverflow = 3
    /// Integer overflow
    IntegerOverflow = 4
    /// Integer out of expected range
    IntegerOutOfExpectedRange = 5
    /// Invalid opcode
    InvalidOpcode = 6
    /// Type check error
    TypeCheckError = 7
    /// Cell overflow
    CellOverflow = 8
    /// Cell underflow
    CellUnderflow = 9
    /// Dictionary error
    DictionaryError = 10
    /// Out of gas error
    OutOfGasError = 13
    /// Method ID not found
    MethodIDNotFound = 32
    /// Action is invalid or not supported
    ActionIsInvalidOrNotSupported = 34
    /// Not enough TON
    NotEnoughTON = 37
    /// Not enough extra-currencies
    NotEnoughExtraCurrencies = 38
    /// Null reference exception
    NullReferenceException = 128
    /// Invalid serialization prefix
    InvalidSerializationPrefix = 129
    /// Invalid incoming message
    InvalidIncomingMessage = 130
    /// Constraints error
    ConstraintsError = 131
    /// Access denied
    AccessDenied = 132
    /// Contract stopped
    ContractStopped = 133
    /// Invalid argument
    InvalidArgument = 134
    /// Code of a contract was not found
    CodeOfAContractWasNotFound = 135
    /// Invalid address
    InvalidAddress = 136
    /// Masterchain support is not enabled for this contract
    MasterchainSupportIsNotEnabledForThisContract = 137
    /// WalletRegistry::Not enough user fee!
    WalletRegistryNotEnoughUserFee = 29038
}

get fun queryId(): int257 {
    throw 0;
}

get fun gateway(): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
