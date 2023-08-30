// Generated from the verified Tact contract ABI.
contract TonupTosRegistry {
    storage: TonupTosRegistryData
    incomingMessages: TonupTosRegistryIncomingMessage
    thrownErrors: TonupTosRegistryErrors
}

struct (0x946a98b6) TonupTosRegistryDeploy {
    queryId: uint64
}

struct (0xef3d09a7) TonupTosRegistryReadConsent {
    addr: address
}

struct TonupTosRegistryData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    accepted: map<address, bool>
    number_users: uint32
}

type TonupTosRegistryIncomingMessage =
    | TonupTosRegistryReadConsent
    | TonupTosRegistryDeploy

enum TonupTosRegistryErrors {
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
    /// Already accepted
    AlreadyAccepted = 5437
    /// Not enough gas
    NotEnoughGas = 33150
}

get fun hasAccepted(addr: address): bool {
    throw 0;
}

get fun consentMessage(): string {
    throw 0;
}

get fun currentVersion(): int257 {
    throw 0;
}

get fun numberUsers(): int257 {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
