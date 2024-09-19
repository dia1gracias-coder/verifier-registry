// Generated from the verified Tact contract ABI.
contract JettonDex {
    storage: JettonDexData
    incomingMessages: JettonDexIncomingMessage
    thrownErrors: JettonDexErrors
}

struct (0x946a98b6) JettonDexDeploy {
    queryId: uint64
}

struct (0x7362d09c) JettonDexTokenNotification {
    queryId: uint64
    amount: coins
    from: address
    forward_payload: RemainingBitsAndRefs
}

struct (0xc204e1b0) JettonDexSetAllowedAddress {
    allowedAdress: address
}

struct JettonDexData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    jettonABalance: coins
    jettonBalance: coins
    fails: uint32
    allowedAddress: address?
}

type JettonDexIncomingMessage =
    | JettonDexTokenNotification
    | JettonDexSetAllowedAddress
    | JettonDexDeploy

enum JettonDexErrors {
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
    /// wrong addr
    WrongAddr = 54444
    /// null check
    NullCheck = 57189
    /// Already here
    AlreadyHere = 58776
}

get fun getJettonABalance(): int257 {
    throw 0;
}

get fun getJettonBalance(): int257 {
    throw 0;
}

get fun getFails(): int257 {
    throw 0;
}

get fun getAddr(): address? {
    throw 0;
}
