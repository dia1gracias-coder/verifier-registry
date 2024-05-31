// Generated from the verified Tact contract ABI.
contract SafeContract {
    storage: SafeContractData
    incomingMessages: SafeContractIncomingMessage
    thrownErrors: SafeContractErrors
}

struct (0x946a98b6) SafeContractDeploy {
    queryId: uint64
}

struct SafeContractSafeParameters {
    timeout: uint32
    requestPrice: coins
    timelock: uint32
}

struct SafeContractSafeOperations {
    ops: map<uint8, Cell<SafeContractSafeOperation>>
    count: uint8
}

struct SafeContractSafeOperation {
    transfer: SafeContractSafeOperationTransfer?
    parameters: SafeContractSafeOperationUpdateParameters?
    add: SafeContractSafeOperationAdd?
    tactContinuation: Cell<SafeContractSafeOperationContinuation>
}

struct SafeContractSafeOperationContinuation {
    remove: SafeContractSafeOperationRemove?
    replace: SafeContractSafeOperationReplace?
}

struct SafeContractSafeOperationAdd {
    owner: address
}

struct SafeContractSafeOperationRemove {
    owner: address
}

struct SafeContractSafeOperationReplace {
    old: address
    new: address
}

struct SafeContractSafeOperationTransfer {
    to: address
    value: coins
    mode: uint8
    bounce: bool
    body: cell?
}

struct SafeContractSafeOperationUpdateParameters {
    parameters: SafeContractSafeParameters
}

struct (0x6eb08253) SafeContractSafeDeployment {
    remaining: address
}

struct (0xa46a3a3d) SafeContractSafeRequestOperation {
    ops: SafeContractSafeOperations
}

struct (0x74a2fc69) SafeContractVoteSuccess {
    args: SafeContractVoteArgs
}

struct (0x407aa202) SafeContractVoteFailure {
    args: SafeContractVoteArgs
}

struct SafeContractVoteArgs {
    safe: address
    owners: map<address, bool>
    ownersCount: uint32
    treshold: uint32
    timeout: uint64
    ops: SafeContractSafeOperations
}

struct SafeContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    seqno: uint64
    owners: map<address, bool>
    ownersCount: int257
    treshold: int257
    parameters: SafeContractSafeParameters
}

type SafeContractIncomingMessage =
    | SafeContractSafeDeployment
    | SafeContractSafeRequestOperation
    | SafeContractVoteFailure
    | SafeContractVoteSuccess
    | SafeContractDeploy

enum SafeContractErrors {
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
    /// Already signed or not an owner
    AlreadySignedOrNotAnOwner = 3094
    /// Timeout
    Timeout = 4755
    /// Not enough value
    NotEnoughValue = 5165
    /// Request price must be less or equals than 10 TON
    RequestPriceMustBeLessOrEqualsThan10TON = 7464
    /// Wrong owners
    WrongOwners = 8884
    /// Not timeouted
    NotTimeouted = 17702
    /// Not enough value to deploy a Safe
    NotEnoughValueToDeployASafe = 25849
    /// Timeout must be less than a year
    TimeoutMustBeLessThanAYear = 31822
    /// Wrong safe address
    WrongSafeAddress = 32453
    /// Timeout must be more than an hour
    TimeoutMustBeMoreThanAnHour = 35981
    /// Sender is not safe
    SenderIsNotSafe = 36682
    /// Wrong treshold
    WrongTreshold = 37479
    /// Request price must be more or equals than 1 TON
    RequestPriceMustBeMoreOrEqualsThan1TON = 38009
    /// Completed
    Completed = 40810
    /// Exactly one operation must be specified
    ExactlyOneOperationMustBeSpecified = 44757
    /// Wrong signer address
    WrongSignerAddress = 45379
    /// Not a member
    NotAMember = 46307
    /// Wrong owners count
    WrongOwnersCount = 62638
}

get fun parameters(): SafeContractSafeParameters {
    throw 0;
}

get fun treshold(): int257 {
    throw 0;
}

get fun timenow(): int257 {
    throw 0;
}

get fun seqno(): int257 {
    throw 0;
}

get fun isOwner(address: address): bool {
    throw 0;
}

get fun owners(): map<address, bool> {
    throw 0;
}
