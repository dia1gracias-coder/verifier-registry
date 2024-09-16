// Generated from the verified Tact contract ABI.
contract JettonMasterContract {
    storage: JettonMasterContractData
    incomingMessages: JettonMasterContractIncomingMessage
    thrownErrors: JettonMasterContractErrors
}

struct (0x946a98b6) JettonMasterContractDeploy {
    queryId: uint64
}

struct (0xe123b673) JettonMasterContractMintJettons {
    amount: uint32
    recipient: address
}

struct JettonMasterContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    totalSupply: uint32
    isMintable: bool
}

type JettonMasterContractIncomingMessage =
    | JettonMasterContractMintJettons
    | JettonMasterContractDeploy

enum JettonMasterContractErrors {
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
    /// Unauthorized minting attempt
    UnauthorizedMintingAttempt = 22623
    /// Minting is disabled
    MintingIsDisabled = 26288
}

get fun currentSupply(): int257 {
    throw 0;
}
