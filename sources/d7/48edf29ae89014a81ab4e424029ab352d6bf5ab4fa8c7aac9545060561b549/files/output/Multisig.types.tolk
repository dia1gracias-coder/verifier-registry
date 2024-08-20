// Generated from the verified Tact contract ABI.
contract Multisig {
    storage: MultisigData
    incomingMessages: MultisigIncomingMessage
    thrownErrors: MultisigErrors
}

struct (0x946a98b6) MultisigDeploy {
    queryId: uint64
}

struct (0xfe519883) MultisigRequest {
    requested: address
    to: address
    value: coins
    timeout: uint32
    bounce: bool
    mode: uint8
    body: cell?
}

struct (0x16c8cbd3) MultisigCreatePoll {
    request: MultisigRequest
    timestamp: int257
}

struct (0x83ea5599) MultisigSigned {
    request: MultisigRequest
}

struct MultisigData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    seqno: int257
    members: map<address, int257>
    totalWeight: int257
    requiredWeight: int257
    tactContinuation: Cell<MultisigDataContinuation>
}

struct MultisigDataContinuation {
    last_signed_timestamp: int257
}

type MultisigIncomingMessage =
    | MultisigCreatePoll
    | MultisigSigned
    | MultisigDeploy

enum MultisigErrors {
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
    /// Invalid sender
    InvalidSender = 4429
    /// Timeout
    Timeout = 4755
    /// Completed
    Completed = 40810
    /// Not a member
    NotAMember = 46307
}

get fun member(address: address): int257? {
    throw 0;
}

get fun members(): map<address, int257> {
    throw 0;
}
