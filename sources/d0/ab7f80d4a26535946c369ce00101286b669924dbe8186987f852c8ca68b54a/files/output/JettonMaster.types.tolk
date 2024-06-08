// Generated from the verified Tact contract ABI.
contract JettonMaster {
    storage: JettonMasterData
    incomingMessages: JettonMasterDeploy
    thrownErrors: JettonMasterErrors
}

struct (0x946a98b6) JettonMasterDeploy {
    queryId: uint64
}

struct JettonMasterMetadata {
    symbol: string
    totalSupply: int257
}

struct JettonMasterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    symbol: string
    totalSupply: coins
}

enum JettonMasterErrors {
    /// Stack undeflow
    StackUndeflow = 2
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
    /// JettonWallet only
    JettonWalletOnly = 34232
    /// Access denied
    AccessDenied2 = 49469
    /// Parent only
    ParentOnly = 54404
    /// Insufficient balance
    InsufficientBalance = 54615
}

get fun walletAddress(owner: address): address {
    throw 0;
}

get fun metadata(): JettonMasterMetadata {
    throw 0;
}
