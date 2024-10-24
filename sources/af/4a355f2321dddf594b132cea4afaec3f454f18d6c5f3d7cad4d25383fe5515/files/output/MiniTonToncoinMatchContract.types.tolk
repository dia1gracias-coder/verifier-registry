// Generated from the verified Tact contract ABI.
contract MiniTonToncoinMatchContract {
    storage: MiniTonToncoinMatchContractData
    incomingMessages: MiniTonToncoinMatchContractIncomingMessage
    thrownErrors: MiniTonToncoinMatchContractErrors
}

struct (0x946a98b6) MiniTonToncoinMatchContractDeploy {
    queryId: uint64
}

struct MiniTonToncoinMatchContractPlayerInfo {
    telegramId: string
}

struct MiniTonToncoinMatchContractRuleInfo {
    ranking: uint8
    prizesShare: string
}

struct MiniTonToncoinMatchContractWinnerInfo {
    telegramId: string
    walletAddress: address?
    ranking: uint8
    prizeWon: coins
    prizeSentStatus: uint8
}

struct MiniTonToncoinMatchContractMatchInfo {
    matchId: uint64
    game: string
    players: map<uint8, Cell<MiniTonToncoinMatchContractPlayerInfo>>
    playerCount: uint8
    prizePool: string
    tactContinuation: Cell<MiniTonToncoinMatchContractMatchInfoContinuation>
}

struct MiniTonToncoinMatchContractMatchInfoContinuation {
    commissionFee: string
    rules: map<uint8, Cell<MiniTonToncoinMatchContractRuleInfo>>
    ruleCount: uint8
}

struct MiniTonToncoinMatchContractMatchResult {
    winners: map<uint8, Cell<MiniTonToncoinMatchContractWinnerInfo>>
    winnerCount: uint8
}

struct MiniTonToncoinMatchContractMasterActionRequest {
    id: int257
    action: uint8
    timeout: uint32
    status: uint8
    weight: uint32
    amount: int257
    address: address
    voters: map<address, bool>
}

struct (0xef09b9dc) MiniTonToncoinMatchContractMasterActionRequestMsg {
    seqno: uint32
    request: MiniTonToncoinMatchContractMasterActionRequest
}

struct (0xc0f891ba) MiniTonToncoinMatchContractVoteMsg {
    seqno: uint32
    requestId: int257
    queryIdPrefix: uint64
}

struct (0xaccf8c43) MiniTonToncoinMatchContractCreateMatchMsg {
    seqno: uint32
    matchInfo: MiniTonToncoinMatchContractMatchInfo
}

struct MiniTonToncoinMatchContractRecipientInfo {
    telegramId: string
    winnerIndex: uint8
    sendMode: uint8
    walletAddress: address?
    txCommentCell: cell?
}

struct (0x9afb825b) MiniTonToncoinMatchContractSendPrizeMsg {
    seqno: uint32
    matchId: uint64
    recipients: map<uint8, Cell<MiniTonToncoinMatchContractRecipientInfo>>
    matchResult: MiniTonToncoinMatchContractMatchResult?
}

struct (0x94f04c35) MiniTonToncoinMatchContractRemoveMatchDumpMsg {
    seqno: uint32
    matchIds: map<int257, uint64>
}

struct (0x6bb86b91) MiniTonToncoinMatchContractRemoveAllMatchDumpMsg {
    seqno: uint32
}

struct (0xdbb62154) MiniTonToncoinMatchContractMinBalanceMsg {
    seqno: uint32
    value: coins
}

struct (0x00e2ca4d) MiniTonToncoinMatchContractSetUSDTJettonWalletAddressMsg {
    seqno: uint32
    value: address
}

struct (0xc02affa5) MiniTonToncoinMatchContractSetGasValueForJettonTransferMsg {
    seqno: uint32
    value: coins
}

struct (0x3a0b2dc4) MiniTonToncoinMatchContractUpgrade {
    seqno: uint32
    newCode: cell
    newData: cell?
}

struct (0x43e0dead) MiniTonToncoinMatchContractUpgradeCode {
    seqno: uint32
    newCode: cell
}

struct (0x1f35092d) MiniTonToncoinMatchContractUpgradeData {
    seqno: uint32
    newData: cell
}

struct (0xd53276db) MiniTonToncoinMatchContractExcesses {
    queryId: uint64
}

struct MiniTonToncoinMatchContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    voters: map<address, bool>
    voterCount: int257
    requiredWeight: int257
    masterActionRequests: map<int257, Cell<MiniTonToncoinMatchContractMasterActionRequest>>
    tactContinuation: Cell<MiniTonToncoinMatchContractDataContinuation>
}

struct MiniTonToncoinMatchContractDataContinuation {
    masterActionRequestCount: int257
    currentSeqno: uint32
    matches: map<int257, Cell<MiniTonToncoinMatchContractMatchInfo>>
    matchCount: int257
    matchResults: map<int257, Cell<MiniTonToncoinMatchContractMatchResult>>
    matchResultCount: int257
    minBalance: coins
    tactContinuation: Cell<MiniTonToncoinMatchContractDataContinuation2>
}

struct MiniTonToncoinMatchContractDataContinuation2 {
    myUSDTJettonWalletAddress: address
    isMyUSDTJettonWalletAddressValid: bool
    gasValueForJettonTransfer: coins
    contractIndex: int257
}

type MiniTonToncoinMatchContractIncomingMessage =
    | MiniTonToncoinMatchContractExcesses
    | MiniTonToncoinMatchContractCreateMatchMsg
    | MiniTonToncoinMatchContractMasterActionRequestMsg
    | MiniTonToncoinMatchContractVoteMsg
    | MiniTonToncoinMatchContractSetUSDTJettonWalletAddressMsg
    | MiniTonToncoinMatchContractSetGasValueForJettonTransferMsg
    | MiniTonToncoinMatchContractSendPrizeMsg
    | MiniTonToncoinMatchContractRemoveMatchDumpMsg
    | MiniTonToncoinMatchContractRemoveAllMatchDumpMsg
    | MiniTonToncoinMatchContractMinBalanceMsg
    | MiniTonToncoinMatchContractUpgrade
    | MiniTonToncoinMatchContractUpgradeCode
    | MiniTonToncoinMatchContractUpgradeData
    | MiniTonToncoinMatchContractDeploy

enum MiniTonToncoinMatchContractErrors {
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
    /// myUSDTJettonWalletAddress is not be set
    MyUSDTJettonWalletAddressIsNotBeSet = 5120
    /// Balance is not enough
    BalanceIsNotEnough = 5370
    /// Can not found this request
    CanNotFoundThisRequest = 6331
    /// Invalid sequence number
    InvalidSequenceNumber = 11749
    /// Only voter can call this function
    OnlyVoterCanCallThisFunction = 22944
    /// This id is already exists
    ThisIdIsAlreadyExists = 26033
    /// Only owner can call this function
    OnlyOwnerCanCallThisFunction = 27831
    /// This match has not submitted a result yet.
    ThisMatchHasNotSubmittedAResultYet = 31911
    /// This match was not found
    ThisMatchWasNotFound = 40530
}

get fun seqno(): int257 {
    throw 0;
}

get fun masterRequest(id: int257): MiniTonToncoinMatchContractMasterActionRequest? {
    throw 0;
}

get fun masterActionRequestCount(): int257 {
    throw 0;
}

get fun usdtJettonWalletAddress(): address {
    throw 0;
}

get fun gasValueForJettonTransfer(): int257 {
    throw 0;
}

get fun minBalance(): int257 {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}

get fun matchInfo(matchId: int257): MiniTonToncoinMatchContractMatchInfo? {
    throw 0;
}

get fun matchCount(): int257 {
    throw 0;
}

get fun matchResult(matchId: int257): MiniTonToncoinMatchContractMatchResult? {
    throw 0;
}

get fun matchResultCount(): int257 {
    throw 0;
}

get fun contractIndex(): int257 {
    throw 0;
}
