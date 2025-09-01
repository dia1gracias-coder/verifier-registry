// Generated from the verified Tact contract ABI.
contract PaymentRouter {
    storage: PaymentRouterData
    incomingMessages: PaymentRouterIncomingMessage
    thrownErrors: PaymentRouterErrors
}

struct (0x946a98b6) PaymentRouterDeploy {
    queryId: uint64
}

struct (0x7362d09c) PaymentRouterJettonTransferNotification {
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0x00000001) PaymentRouterCreateUcpi {
    ucpi_id: uint256
}

struct (0x00000003) PaymentRouterPayUcpi {
    ucpi_id: uint256
}

struct PaymentRouterAdminAction {
    target_admin: address
    is_adding: bool
    signatures: int257
    signed_by: map<address, bool>
    action_type: string
    timestamp: int257
}

struct PaymentRouterData {
    tactDeploymentCompleted: bool
    ucpi_to_wallet: map<uint256, address>
    MIN_SIGNATURES: int257
    admin_count: int257
    tactContinuation: Cell<PaymentRouterDataContinuation>
}

struct PaymentRouterDataContinuation {
    wallet_to_ucpi: map<address, uint256>
    pending_admin_actions: map<int257, Cell<PaymentRouterAdminAction>>
    wallet_blocklist: map<address, bool>
    admin_list: map<address, bool>
    next_action_id: int257
}

type PaymentRouterIncomingMessage =
    | PaymentRouterCreateUcpi
    | PaymentRouterPayUcpi
    | PaymentRouterJettonTransferNotification
    | PaymentRouterDeploy

enum PaymentRouterErrors {
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
    /// Ucpi ID must be greater than 0
    UcpiIDMustBeGreaterThan0 = 9993
    /// Only admin can propose
    OnlyAdminCanPropose = 25878
    /// Invalid admin address
    InvalidAdminAddress = 27318
    /// Action does not exist
    ActionDoesNotExist = 37768
    /// Only admin can sign
    OnlyAdminCanSign = 45510
    /// Minimum payment is 0.1 TON
    MinimumPaymentIs01TON = 51560
    /// Action already proposed
    ActionAlreadyProposed = 55617
    /// Blacklisted user cannot be admin
    BlacklistedUserCannotBeAdmin = 57280
    /// Already signed
    AlreadySigned = 57569
}

get fun get_wallet_status(wallet_opt: address?): bool? {
    throw 0;
}

get fun is_active_admin(addr: address): bool {
    throw 0;
}

get fun getUcpiWallet(ucpi_id: int257): address? {
    throw 0;
}

get fun getUcpiByWallet(wallet_address: address): int257? {
    throw 0;
}

get fun getContractBalance(): int257 {
    throw 0;
}

get fun is_admin(addr: address): bool {
    throw 0;
}

get fun zero_address(): address {
    throw 0;
}
