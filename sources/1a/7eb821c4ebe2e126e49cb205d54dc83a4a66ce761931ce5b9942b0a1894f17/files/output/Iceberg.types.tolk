// Generated from the verified Tact contract ABI.
contract Iceberg {
    storage: IcebergData
    incomingMessages: IcebergIncomingMessage
    thrownErrors: IcebergErrors
}

struct (0x819dbe99) IcebergChangeOwner {
    queryId: uint64
    newOwner: address
}

struct IcebergJettonData {
    total_supply: int257
    mintable: bool
    owner: address
    content: cell
    wallet_code: cell
}

struct IcebergVestingSchedule {
    amount: int257
    cliffMonths: int257
    totalMonths: int257
    tactContinuation: Cell<IcebergVestingScheduleContinuation>
}

struct IcebergVestingScheduleContinuation {
    claimed: int257
    address: address
    tgeUnlock: int257
}

struct IcebergUnlockInfo {
    name: string
    totalAmount: int257
    claimedAmount: int257
    cliffEnds: int257
    tactContinuation: Cell<IcebergUnlockInfoContinuation>
}

struct IcebergUnlockInfoContinuation {
    nextUnlock: int257
    monthlyUnlock: int257
    unlockEnds: int257
    tactContinuation: Cell<IcebergUnlockInfoContinuation2>
}

struct IcebergUnlockInfoContinuation2 {
    unlockedAmount: int257
    tgeUnlock: int257
}

struct (0x7bdd97de) IcebergTokenBurnNotification {
    query_id: uint64
    amount: coins
    sender: address
    response_destination: address?
    send_excess: bool
}

struct (0x2c76b973) IcebergProvideWalletAddress {
    query_id: uint64
    owner_address: address
    include_address: bool
}

struct (0xfc708bd2) IcebergMint {
    amount: int257
    receiver: address
}

struct (0xcc76a696) IcebergSetTGEStartTime {
    time: int257
}

struct (0xb1dd6fe5) IcebergGetUnlockInfo {
    time: int257
}

struct (0xa9b72316) IcebergUnlockSchedule {
    team: IcebergUnlockInfo
    tactContinuation: Cell<IcebergUnlockScheduleContinuation>
}

struct IcebergUnlockScheduleContinuation {
    roundA: IcebergUnlockInfo
    tactContinuation: Cell<IcebergUnlockScheduleContinuation2>
}

struct IcebergUnlockScheduleContinuation2 {
    projectDev: IcebergUnlockInfo
    tactContinuation: Cell<IcebergUnlockScheduleContinuation3>
}

struct IcebergUnlockScheduleContinuation3 {
    marketing: IcebergUnlockInfo
    tactContinuation: Cell<IcebergUnlockScheduleContinuation4>
}

struct IcebergUnlockScheduleContinuation4 {
    advisors: IcebergUnlockInfo
    tactContinuation: Cell<IcebergUnlockScheduleContinuation5>
}

struct IcebergUnlockScheduleContinuation5 {
    marketMakers: IcebergUnlockInfo
    tactContinuation: Cell<IcebergUnlockScheduleContinuation6>
}

struct IcebergUnlockScheduleContinuation6 {
    kol: IcebergUnlockInfo
}

struct (0x11b6fe0b) IcebergGetUnlockDates {
    category: string
}

struct IcebergUnlockDetail {
    unlockTime: int257
    unlockAmount: int257
    unlockType: string
}

struct IcebergData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    total_supply: coins
    max_supply: coins
    mintable: bool
    owner: address
    content: cell
    decimals: int257
    tactContinuation: Cell<IcebergDataContinuation>
}

struct IcebergDataContinuation {
    tgeStartTime: int257
    tactContinuation: Cell<IcebergDataContinuation2>
}

struct IcebergDataContinuation2 {
    team_vesting: IcebergVestingSchedule
    tactContinuation: Cell<IcebergDataContinuation3>
}

struct IcebergDataContinuation3 {
    round_a_vesting: IcebergVestingSchedule
    tactContinuation: Cell<IcebergDataContinuation4>
}

struct IcebergDataContinuation4 {
    project_dev_vesting: IcebergVestingSchedule
    tactContinuation: Cell<IcebergDataContinuation5>
}

struct IcebergDataContinuation5 {
    advisors_vesting: IcebergVestingSchedule
    tactContinuation: Cell<IcebergDataContinuation6>
}

struct IcebergDataContinuation6 {
    kol_vesting: IcebergVestingSchedule
    tactContinuation: Cell<IcebergDataContinuation7>
}

struct IcebergDataContinuation7 {
    marketing_vesting: IcebergVestingSchedule
    tactContinuation: Cell<IcebergDataContinuation8>
}

struct IcebergDataContinuation8 {
    market_makers_vesting: IcebergVestingSchedule
}

type IcebergIncomingMessage =
    | IcebergMint
    | IcebergSetTGEStartTime
    | IcebergTokenBurnNotification
    | IcebergProvideWalletAddress
    | IcebergChangeOwner

enum IcebergErrors {
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
    /// No tokens to claim
    NoTokensToClaim = 2639
    /// Invalid sender
    InvalidSender = 4429
    /// Not owner
    NotOwner = 14534
    /// Exceeds max supply
    ExceedsMaxSupply = 14796
    /// Invalid value
    InvalidValue = 16059
    /// Insufficient gas
    InsufficientGas = 23951
    /// TGE time already set
    TGETimeAlreadySet = 25623
    /// Invalid sender!
    InvalidSender2 = 42708
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// Minting is closed
    MintingIsClosed = 43555
    /// Invalid balance
    InvalidBalance = 62972
}

get fun getVestingInfo(name: string, schedule: IcebergVestingSchedule, currentTime: int257): IcebergUnlockInfo {
    throw 0;
}

get fun getUnlockSchedule(msg: IcebergGetUnlockInfo): IcebergUnlockSchedule {
    throw 0;
}

get fun getTgeStartTime(): int257 {
    throw 0;
}

get fun getUnlockDates(msg: IcebergGetUnlockDates): map<int257, Cell<IcebergUnlockDetail>> {
    throw 0;
}

get fun getDecimals(): int257 {
    throw 0;
}

get fun get_jetton_data(): IcebergJettonData {
    throw 0;
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
