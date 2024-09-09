// Generated from the verified Tact contract ABI.
contract AttestParent {
    storage: AttestParentData2
    incomingMessages: AttestParentIncomingMessage
    thrownErrors: AttestParentErrors
}

struct (0x819dbe99) AttestParentChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x946a98b6) AttestParentDeploy {
    queryId: uint64
}

struct (0xacd09c05) AttestParentAttestRequest {
    queryId: uint64
    media: int257
    seed: int257
    sign: slice
    update: bool
    response_destination: address?
}

struct (0xad48426b) AttestParentChangePublicKey {
    queryId: uint64
    publicKey: uint256
}

struct (0x0fb2008d) AttestParentChangeAttestFee {
    queryId: uint64
    attestFee: int257
}

struct (0x0ba69751) AttestParentWithdraw {
    amount: coins
}

struct AttestParentData {
    owner: address
    initOwner: address
    publicKey: uint256
    tactContinuation: Cell<AttestParentDataContinuation>
}

struct AttestParentDataContinuation {
    initPublicKey: uint256
    attestFee: int257
    code: cell?
}

struct AttestParentData2 {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    initOwner: address
    publicKey: uint256
    tactContinuation: Cell<AttestParentDataContinuation2>
}

struct AttestParentDataContinuation2 {
    initPublicKey: uint256
    attestFee: int257
}

type AttestParentIncomingMessage =
    | AttestParentChangePublicKey
    | AttestParentChangeAttestFee
    | AttestParentWithdraw
    | AttestParentChangeOwner
    | AttestParentDeploy

enum AttestParentErrors {
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
    /// Invalid media
    InvalidMedia = 2689
    /// Invalid sign
    InvalidSign = 12832
    /// Invalid value
    InvalidValue = 16059
    /// Only master
    OnlyMaster = 16588
    /// Invalid amount
    InvalidAmount = 17062
    /// Invalid attest fee
    InvalidAttestFee = 43657
}

get fun sign_result(msg: AttestParentAttestRequest): bool {
    throw 0;
}

get fun attest_parent_data(withCode: bool): AttestParentData {
    throw 0;
}

get fun attest_child(owner: address): address {
    throw 0;
}

get fun public_key(): int257 {
    throw 0;
}

get fun init_public_key(): int257 {
    throw 0;
}

get fun init_owner(): address {
    throw 0;
}

get fun balance(): string {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
