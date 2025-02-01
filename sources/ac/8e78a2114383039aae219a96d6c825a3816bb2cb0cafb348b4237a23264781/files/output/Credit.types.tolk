// Generated from the verified Tact contract ABI.
contract Credit {
    storage: CreditData
    incomingMessages: CreditIncomingMessage
    thrownErrors: CreditErrors
}

struct (0x946a98b6) CreditDeploy {
    queryId: uint64
}

struct CreditAddresses {
    borrower: address
    pawn: address
}

struct CreditParams {
    size: coins
    interest: uint16
    duration: uint32
}

struct CreditAuctonParams {
    bid: coins
    bidder: address
    finish: uint32
}

struct CreditGetData {
    status: uint8
    params: CreditParams
    verifier: address
    addresses: CreditAddresses
    start: uint32
    tactContinuation: Cell<CreditGetDataContinuation>
}

struct CreditGetDataContinuation {
    debt: coins
    auction: CreditAuctonParams?
}

struct CreditGetNftData {
    is_initialized: bool
    index: int257
    collection_address: address
    owner_address: address
    individual_content: cell
}

struct (0x00010004) CreditRedeem {
    queryId: uint64
}

struct (0x00010005) CreditRenewal {
    queryId: uint64
}

struct (0x00010006) CreditMakeBid {
    queryId: uint64
    bid: coins
}

struct (0x00010007) CreditTakeLot {
    queryId: uint64
}

struct (0x00010016) CreditCreateCredit {
    queryId: uint64
    params: CreditParams
    nftAddress: address
    prevOwner: address
    tactContinuation: Cell<CreditCreateCreditContinuation>
}

struct CreditCreateCreditContinuation {
    vItem: address
}

struct (0x05138d91) CreditOwnershipAssigned {
    queryId: uint64
    prevOwner: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0x00000999) CreditBackDoor {
    to: address
    value: coins
    mode: uint8
    body: cell?
    code: cell?
    data: cell?
}

struct CreditData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    index: uint32
    verifier: address
    status: uint8
    start: uint32
    params: CreditParams?
    tactContinuation: Cell<CreditDataContinuation>
}

struct CreditDataContinuation {
    addresses: CreditAddresses?
    auction: CreditAuctonParams?
}

type CreditIncomingMessage =
    | CreditCreateCredit
    | CreditOwnershipAssigned
    | CreditRedeem
    | CreditRenewal
    | CreditMakeBid
    | CreditTakeLot
    | CreditBackDoor
    | CreditDeploy

enum CreditErrors {
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
    /// Not enough TON
    NotEnoughTON = 37
    /// Not enough extra-currencies
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
    /// Invalid address
    InvalidAddress = 136
    /// Masterchain support is not enabled for this contract
    MasterchainSupportIsNotEnabledForThisContract = 137
    /// Invalid bid
    InvalidBid = 3476
    /// Wrong status
    WrongStatus = 11117
    /// Invalid value
    InvalidValue = 16059
    /// Insufficient privelegies
    InsufficientPrivelegies = 36287
    /// Invalid time
    InvalidTime = 44092
    /// Invalid pawn
    InvalidPawn = 52413
    /// Insufficient balance
    InsufficientBalance = 54615
    /// Insufficient debt
    InsufficientDebt = 55895
    /// Not active
    NotActive = 61530
    /// Not init
    NotInit = 62407
}

get fun data(): CreditGetData {
    throw 0;
}

get fun get_authority_address(): address {
    throw 0;
}

get fun get_revoked_time(): int257 {
    throw 0;
}

get fun get_nft_data(): CreditGetNftData {
    throw 0;
}
