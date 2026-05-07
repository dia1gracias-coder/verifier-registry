// Generated from the verified Tact contract ABI.
contract Mining {
    storage: MiningData
    incomingMessages: MiningIncomingMessage
    thrownErrors: MiningErrors
}

struct MiningContractStatus {
    owner: address
    jettonWallet: address
    paused: bool
    maxClaimAmount: uint64
}

struct (0x7e208cb4) MiningExcesses {
    queryId: uint64
}

struct (0xb36a9178) MiningSetJettonWallet {
    jettonWallet: address
}

struct (0x7362d09c) MiningNotification {
    queryId: uint64
    amount: coins
    sender: address
    forward_payload: RemainingBitsAndRefs
}

struct (0xd53276db) MiningTokenExcesses {
    queryId: uint64
}

struct (0x7a4508d9) MiningPause {
}

struct (0x8dcb2d19) MiningUnpause {
}

struct (0xcc8eef55) MiningSetMaxClaim {
    newMax: uint64
}

struct (0xc60fadaf) MiningRotateSigner {
    newKey: uint256
}

struct (0xc5429ccf) MiningAdminWithdraw {
    amount: uint64
}

struct (0x94cc7430) MiningWithdraw {
    amount: uint64
}

struct (0x946a98b6) MiningDeploy {
    queryId: uint64
}

struct MiningData {
    tactDeploymentCompleted: bool
    owner: address
    signerPubKey: uint256
    jettonWallet: address?
    paused: bool
    maxClaimAmount: uint64
    lastUserNonce: map<address, uint64>
    tactContinuation: Cell<MiningDataContinuation>
}

struct MiningDataContinuation {
    timestamp: int257
}

type MiningIncomingMessage =
    | MiningSetJettonWallet
    | MiningTokenExcesses
    | MiningNotification
    | MiningExcesses
    | MiningAdminWithdraw
    | MiningWithdraw
    | MiningPause
    | MiningUnpause
    | MiningSetMaxClaim
    | MiningRotateSigner
    | MiningDeploy

enum MiningErrors {
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
    /// 'Unknown' error
    UnknownError = 11
    /// Fatal error
    FatalError = 12
    /// Out of gas error
    OutOfGasError = 13
    /// Virtualization error
    VirtualizationError = 14
    /// Action list is invalid
    ActionListIsInvalid = 32
    /// Action list is too long
    ActionListIsTooLong = 33
    /// Action is invalid or not supported
    ActionIsInvalidOrNotSupported = 34
    /// Invalid source address in outbound message
    InvalidSourceAddressInOutboundMessage = 35
    /// Invalid destination address in outbound message
    InvalidDestinationAddressInOutboundMessage = 36
    /// Not enough Toncoin
    NotEnoughToncoin = 37
    /// Not enough extra currencies
    NotEnoughExtraCurrencies = 38
    /// Outbound message does not fit into a cell after rewriting
    OutboundMessageDoesNotFitIntoACellAfterRewriting = 39
    /// Cannot process a message
    CannotProcessAMessage = 40
    /// Library reference is null
    LibraryReferenceIsNull = 41
    /// Library change action error
    LibraryChangeActionError = 42
    /// Exceeded maximum number of cells in the library or the maximum depth of the Merkle tree
    ExceededMaximumNumberOfCellsInTheLibraryOrTheMaximumDepthOfTheMerkleTree = 43
    /// Account state size exceeded limits
    AccountStateSizeExceededLimits = 50
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
    /// Invalid standard address
    InvalidStandardAddress = 136
    /// Not a basechain address
    NotABasechainAddress = 138
    /// Invalid value!!
    InvalidValue = 4159
    /// Invalid sender
    InvalidSender = 4429
    /// The total supply will be overlapping.
    TheTotalSupplyWillBeOverlapping = 6898
    /// Zero amount
    ZeroAmount = 7189
    /// Invalid nonce order
    InvalidNonceOrder = 8255
    /// Not owner
    NotOwner = 14534
    /// Invalid rewardId
    InvalidRewardId = 15170
    /// Expired
    Expired = 17473
    /// Insufficient gas, send at least 0.08 TON
    InsufficientGasSendAtLeast008TON = 26938
    /// Exceed max
    ExceedMax = 35206
    /// Invalid sender!
    InvalidSender2 = 42708
    /// Unknown jetton wallet
    UnknownJettonWallet = 43382
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// Paused
    Paused = 59457
    /// Invalid sig
    InvalidSig = 62332
    /// Invalid balance
    InvalidBalance = 62972
}

get fun next_nonce(user: address): int257 {
    throw 0;
}

get fun status(): MiningContractStatus {
    throw 0;
}
