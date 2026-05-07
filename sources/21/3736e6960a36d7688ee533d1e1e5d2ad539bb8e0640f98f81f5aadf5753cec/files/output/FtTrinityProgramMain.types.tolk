// Generated from the verified Tact contract ABI.
contract FtTrinityProgramMain {
    storage: FtTrinityProgramMainData
    incomingMessages: FtTrinityProgramMainIncomingMessage
    thrownErrors: FtTrinityProgramMainErrors
}

struct (0x90e412e3) FtTrinityProgramMainManualRecycle {
    id: uint64
    levelNumber: uint8
    nextLevelPrice: coins
    autoWithdrawMinFee: coins
    recipientExcesses: address
}

struct (0x0ab05820) FtTrinityProgramMainSetupProgramUser {
    id: uint64
    owner: address
    invitedId: uint64
    invitedAddress: address
    canClaim: coins
    lastLevel: uint8
    overtakeInfo: map<uint8, uint16>
    levelInfo: map<uint8, Cell<FtTrinityProgramMainTrinityInfo>>
    spentForActivate: coins
}

struct (0xab67517e) FtTrinityProgramMainChangeActivation {
    id: uint64
    activating: bool
    lastLevel: uint8
    recipientExcesses: address
}

struct (0x95ab4bd6) FtTrinityProgramMainSetupTrinityPrice {
    newLevelPrice: map<uint8, coins>
    newLevelPriceAutoFee: map<uint8, coins>
}

struct (0x968898a9) FtTrinityProgramMainSetupTrinityFee {
    newLevelFee: map<uint8, coins>
}

struct (0x6fe57a02) FtTrinityProgramMainSetupJettonWallet {
    wallet: address
}

struct (0xbdd5f8f8) FtTrinityProgramMainSetupTrinityStart {
    startTrinity: uint32
}

struct (0x5cb522cd) FtTrinityProgramMainSetupMinValueForActivate {
    newMinValue: coins
}

struct (0x2593ba97) FtTrinityProgramMainSetupAutoWithdrawMinFee {
    value: coins
}

struct (0x7afb1b33) FtTrinityProgramMainSetupAutoWithdrawPercent {
    value: uint8
}

struct (0x26e869b0) FtTrinityProgramMainSetupStartParam {
    totalFrtInProgram: coins
    passiveVault: coins
}

struct (0xd07d62b1) FtTrinityProgramMainChangeUOwner {
    id: uint64
    newOwner: address
    recipientExcesses: address
}

struct (0xc2ccdad9) FtTrinityProgramMainChangeInfo {
    id: uint64
    levelNumber: uint8
    tactContinuation: Cell<FtTrinityProgramMainChangeInfoContinuation>
}

struct FtTrinityProgramMainChangeInfoContinuation {
    newInfo: FtTrinityProgramMainTrinityInfo
    tactContinuation: Cell<FtTrinityProgramMainChangeInfoContinuation2>
}

struct FtTrinityProgramMainChangeInfoContinuation2 {
    recipientExcesses: address
}

struct (0x7b0dbcbf) FtTrinityProgramMainReturnJetton {
    userId: uint64
    recipient: address
    autoFee: coins
    amount: coins
}

struct (0x006ddf63) FtTrinityProgramMainClaimJetton {
    userId: uint64
    recipient: address
    amount: coins
    isAuto: bool
    recipientExcesses: address
}

struct (0xf933be53) FtTrinityProgramMainClaimTon {
    amount: coins
}

struct (0x6490dc2a) FtTrinityProgramMainGetPassiveBank {
}

struct (0xd456c178) FtTrinityProgramMainGetProtocolFees {
}

struct (0x835e82d2) FtTrinityProgramMainGetPassiveBankFull {
}

struct (0x2d9ae3fe) FtTrinityProgramMainGetJetton {
    value: coins
    recipient: address
    recipientExcesses: address
}

struct (0x01c9e5b8) FtTrinityProgramMainChangeEditable {
}

struct (0xc867352c) FtTrinityProgramMainChangeRelaunch {
}

struct (0x07887435) FtTrinityProgramMainAutoActivation {
    userId: uint64
    levelNumber: uint8
    value: coins
    recipientExcesses: address
}

struct (0x7362d09c) FtTrinityProgramMainJettonNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0xd53276db) FtTrinityProgramMainJettonExcesses {
    queryId: uint64
}

struct (0xd587100b) FtTrinityProgramMainBuyLevel {
    owner: address
    userId: uint64
    invitedId: uint64
    levelNumber: uint8
    recipientExcesses: address
}

struct FtTrinityProgramMainPlace {
    userId: uint64
    type_: uint8
}

struct FtTrinityProgramMainTrinityMatrix {
    places: map<uint8, Cell<FtTrinityProgramMainPlace>>
    userPlace: map<uint64, uint8>
    firstFreePlace: uint8
}

struct FtTrinityProgramMainTrinityInfo {
    matrixProfit: coins
    lineProfit: coins
    lostProfit: coins
    holdValue: coins
    nextLevelValue: coins
    canClaimFirstLineBonus: coins
    canClaimSecondLineBonus: coins
    canClaimThirdLineBonus: coins
    tactContinuation: Cell<FtTrinityProgramMainTrinityInfoContinuation>
}

struct FtTrinityProgramMainTrinityInfoContinuation {
    notAvailableFirstLineBonus: coins
    notAvailableSecondLineBonus: coins
    notAvailableThirdLineBonus: coins
    reinvestCount: uint16
    upperAddress: address?
    matrix: FtTrinityProgramMainTrinityMatrix
}

struct FtTrinityProgramMainData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    editable: bool
    relaunch: bool
    wallet: address
    startTrinity: uint256
    totalFrtInProgram: coins
    passiveVault: coins
    protocolFees: coins
    tactContinuation: Cell<FtTrinityProgramMainDataContinuation>
}

struct FtTrinityProgramMainDataContinuation {
    owner: address
    master: address
    levelPrices: map<uint8, coins>
    levelFees: map<uint8, coins>
    levelPricesAutoFee: map<uint8, coins>
    autoWithdrawMinFee: coins
    autoWithdrawPercent: uint8
    minValueForActivate: coins
}

type FtTrinityProgramMainIncomingMessage =
    | FtTrinityProgramMainJettonExcesses
    | FtTrinityProgramMainSetupTrinityPrice
    | FtTrinityProgramMainSetupTrinityFee
    | FtTrinityProgramMainSetupTrinityStart
    | FtTrinityProgramMainSetupJettonWallet
    | FtTrinityProgramMainSetupAutoWithdrawMinFee
    | FtTrinityProgramMainSetupAutoWithdrawPercent
    | FtTrinityProgramMainSetupMinValueForActivate
    | FtTrinityProgramMainSetupStartParam
    | FtTrinityProgramMainSetupProgramUser
    | FtTrinityProgramMainChangeUOwner
    | FtTrinityProgramMainChangeInfo
    | FtTrinityProgramMainChangeActivation
    | FtTrinityProgramMainChangeRelaunch
    | FtTrinityProgramMainChangeEditable
    | FtTrinityProgramMainManualRecycle
    | FtTrinityProgramMainBuyLevel
    | FtTrinityProgramMainAutoActivation
    | FtTrinityProgramMainJettonNotification
    | FtTrinityProgramMainReturnJetton
    | FtTrinityProgramMainClaimJetton
    | FtTrinityProgramMainGetPassiveBankFull
    | FtTrinityProgramMainGetPassiveBank
    | FtTrinityProgramMainGetProtocolFees
    | FtTrinityProgramMainGetJetton
    | FtTrinityProgramMainClaimTon

enum FtTrinityProgramMainErrors {
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
    /// Level number should be less than 4 and more than 0
    LevelNumberShouldBeLessThan4AndMoreThan0 = 38880
    /// Nothing to withdraw
    NothingToWithdraw = 40636
    /// Too big level number
    TooBigLevelNumber = 63137
}

get fun owner(): address {
    throw 0;
}

get fun master(): address {
    throw 0;
}

get fun jettonWallet(): address {
    throw 0;
}

get fun startTrinity(): int257 {
    throw 0;
}

get fun totalFrtInProgram(): int257 {
    throw 0;
}

get fun passiveBankAmount(): int257 {
    throw 0;
}

get fun commissionFees(): int257 {
    throw 0;
}

get fun levelPrices(): map<uint8, coins> {
    throw 0;
}

get fun levelFees(): map<uint8, coins> {
    throw 0;
}

get fun levelPricesAutoFee(): map<uint8, coins> {
    throw 0;
}

get fun autoWithdrawMinFee(): int257 {
    throw 0;
}

get fun autoWithdrawPercent(): int257 {
    throw 0;
}

get fun trinityProgramUserAddress(id: int257): address {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}

get fun editable(): bool {
    throw 0;
}

get fun relaunch(): bool {
    throw 0;
}
