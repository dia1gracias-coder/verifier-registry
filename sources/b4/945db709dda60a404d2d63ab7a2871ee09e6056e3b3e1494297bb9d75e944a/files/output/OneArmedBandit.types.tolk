// Generated from the verified Tact contract ABI.
contract OneArmedBandit {
    storage: OneArmedBanditData
    incomingMessages: OneArmedBanditIncomingMessage
    thrownErrors: OneArmedBanditErrors
}

struct (0x946a98b6) OneArmedBanditDeploy {
    queryId: uint64
}

struct (0x96c36f9b) OneArmedBanditWinNumbersReply {
    winnumbers: map<uint8, uint8>
}

struct OneArmedBanditData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    seqno: uint8
    winraitlenght: uint8
    childseqno: uint8
    winraittable: map<uint8, uint8>
}

type OneArmedBanditIncomingMessage =
    | OneArmedBanditWinNumbersReply
    | OneArmedBanditDeploy

enum OneArmedBanditErrors {
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
}

get fun getchildseqno(): int257 {
    throw 0;
}

get fun getwinratetablereadble(winraittableq: map<uint8, uint8>): string {
    throw 0;
}
