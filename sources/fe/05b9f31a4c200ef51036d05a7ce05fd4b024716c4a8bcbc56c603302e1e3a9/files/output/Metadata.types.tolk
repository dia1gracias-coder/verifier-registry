// Generated from the verified Tact contract ABI.
contract Metadata {
    storage: MetadataData
    incomingMessages: MetadataDeploy
    thrownErrors: MetadataErrors
}

struct (0x946a98b6) MetadataDeploy {
    queryId: uint64
}

struct MetadataState {
    avatar: string
    name: string
    about: string
    tactContinuation: Cell<MetadataStateContinuation>
}

struct MetadataStateContinuation {
    website: string
    terms: string
    telegram: string
    tactContinuation: Cell<MetadataStateContinuation2>
}

struct MetadataStateContinuation2 {
    github: string
    jetton: address
    nft: address
    hide: bool
    dns: string
}

struct MetadataData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    avatar: string
    name: string
    tactContinuation: Cell<MetadataDataContinuation>
}

struct MetadataDataContinuation {
    about: string
    website: string
    terms: string
    tactContinuation: Cell<MetadataDataContinuation2>
}

struct MetadataDataContinuation2 {
    telegram: string
    github: string
    jetton: address
    nft: address
    hide: bool
    dns: string
}

enum MetadataErrors {
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
}

get fun state(): MetadataState {
    throw 0;
}
