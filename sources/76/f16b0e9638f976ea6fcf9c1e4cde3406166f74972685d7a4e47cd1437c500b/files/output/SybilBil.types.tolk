// Generated from the verified Tact contract ABI.
contract SybilBil {
    storage: SybilBilData
    incomingMessages: SybilBilIncomingMessage
    thrownErrors: SybilBilErrors
}

struct (0x946a98b6) SybilBilDeploy {
    queryId: uint64
}

struct SybilBilOwnerAddress {
    address: address
    percentage: int257
}

struct (0x599e1782) SybilBilOwnersAddress {
    addresses: map<int257, Cell<SybilBilOwnerAddress>>
    size: int257
}

struct SybilBilData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    deployer: address
    addresses: map<int257, Cell<SybilBilOwnerAddress>>
    addressesSize: int257
    id: uint32
}

type SybilBilIncomingMessage =
    | SybilBilOwnersAddress
    | SybilBilDeploy

enum SybilBilErrors {
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
    /// Only deployer is allowed to withdraw
    OnlyDeployerIsAllowedToWithdraw = 15509
    /// Only deployer is allowed to set addresses
    OnlyDeployerIsAllowedToSetAddresses = 61355
}

get fun addressesSize(): int257 {
    throw 0;
}

get fun addresses(): map<int257, Cell<SybilBilOwnerAddress>> {
    throw 0;
}

get fun balance(): string {
    throw 0;
}

get fun id(): int257 {
    throw 0;
}
