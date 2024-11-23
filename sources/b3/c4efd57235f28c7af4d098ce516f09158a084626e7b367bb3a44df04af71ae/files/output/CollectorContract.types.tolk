// Generated from the verified Tact contract ABI.
contract CollectorContract {
    storage: CollectorContractData
    incomingMessages: CollectorContractIncomingMessage
    thrownErrors: CollectorContractErrors
}

struct (0x946a98b6) CollectorContractDeploy {
    queryId: uint64
}

struct (0x05138d91) CollectorContractOwnershipAssigned {
    queryId: uint64
    previousOwner: address
    forwardPayload: cell?
}

struct (0x779bf430) CollectorContractSetupMessage {
    rewardAmount: uint32
}

struct CollectorContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    nftCollectionAddress: address
    rewardAmount: uint32
    owner: address
    nftItemCode: cell
}

type CollectorContractIncomingMessage =
    | CollectorContractOwnershipAssigned
    | CollectorContractSetupMessage
    | CollectorContractDeploy

enum CollectorContractErrors {
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
    /// Sender is not expected NFT item contract
    SenderIsNotExpectedNFTItemContract = 8854
    /// No forwardPayload provided
    NoForwardPayloadProvided = 18944
}

get fun collection(): address {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}

get fun rewardAmount(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
