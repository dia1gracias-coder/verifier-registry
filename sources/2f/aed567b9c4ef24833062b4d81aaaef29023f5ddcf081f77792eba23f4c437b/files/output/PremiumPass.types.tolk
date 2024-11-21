// Generated from the verified Tact contract ABI.
contract PremiumPass {
    storage: PremiumPassData
    incomingMessages: PremiumPassIncomingMessage
    thrownErrors: PremiumPassErrors
}

struct (0x946a98b6) PremiumPassDeploy {
    queryId: uint64
}

struct (0x819dbe99) PremiumPassChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0xaa324c19) PremiumPassSetPassPrice {
    newPrice: uint128
}

struct (0xbb844464) PremiumPassSetCheckInPrice {
    newCheckInPrice: uint128
}

struct (0x86aea23a) PremiumPassSetVipMaxCheckIns {
    newLimit: int257
}

struct (0x0c5b6fee) PremiumPassPurchasePass {
    chatId: int257
}

struct (0x722bfa86) PremiumPassCheckIn {
    chatId: int257
}

struct (0xdd01ae2c) PremiumPassWithdrawAll {
}

struct (0x1406afd3) PremiumPassWithdrawSafe {
}

struct PremiumPassPassInfo {
    hasPass: bool
    joinDate: int257
    lastCheckInDate: int257
    lastCheckInTimestamp: int257
    tactContinuation: Cell<PremiumPassPassInfoContinuation>
}

struct PremiumPassPassInfoContinuation {
    checkInCountToday: int257
}

struct PremiumPassData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    passPrice: uint128
    checkInPrice: uint128
    vipMaxCheckIns: int257
    passHolders: map<int257, Cell<PremiumPassPassInfo>>
}

type PremiumPassIncomingMessage =
    | PremiumPassSetPassPrice
    | PremiumPassSetCheckInPrice
    | PremiumPassSetVipMaxCheckIns
    | PremiumPassPurchasePass
    | PremiumPassCheckIn
    | PremiumPassWithdrawAll
    | PremiumPassWithdrawSafe
    | PremiumPassDeploy
    | PremiumPassChangeOwner

enum PremiumPassErrors {
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
    /// Check-in price must be greater than 0
    CheckInPriceMustBeGreaterThan0 = 1853
    /// Insufficient funds to check in
    InsufficientFundsToCheckIn = 11004
    /// Only deployer is allowed to withdraw
    OnlyDeployerIsAllowedToWithdraw = 15509
    /// SuperPass users can only check in twice per day
    SuperPassUsersCanOnlyCheckInTwicePerDay = 17142
    /// User already owns a pass
    UserAlreadyOwnsAPass = 17259
    /// Regular users can only check in once per day
    RegularUsersCanOnlyCheckInOncePerDay = 18401
    /// VIP check-in limit must be greater than 0
    VIPCheckInLimitMustBeGreaterThan0 = 32125
    /// Initial price must be greater than 0
    InitialPriceMustBeGreaterThan0 = 49580
    /// Price must be greater than 0
    PriceMustBeGreaterThan0 = 50036
    /// Insufficient funds to purchase pass
    InsufficientFundsToPurchasePass = 61692
}

get fun passPrice(): int257 {
    throw 0;
}

get fun checkInPrice(): int257 {
    throw 0;
}

get fun vipMaxCheckIns(): int257 {
    throw 0;
}

get fun passInfo(chatId: int257): PremiumPassPassInfo {
    throw 0;
}

get fun balance(): string {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
