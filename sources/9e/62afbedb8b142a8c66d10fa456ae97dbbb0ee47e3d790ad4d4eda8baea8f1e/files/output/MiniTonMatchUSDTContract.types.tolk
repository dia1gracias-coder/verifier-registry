// Generated from the verified Tact contract ABI.
contract MiniTonMatchUSDTContract {
    storage: MiniTonMatchUSDTContractData
    incomingMessages: MiniTonMatchUSDTContractIncomingMessage
    thrownErrors: MiniTonMatchUSDTContractErrors
}

struct (0x946a98b6) MiniTonMatchUSDTContractDeploy {
    queryId: uint64
}

struct MiniTonMatchUSDTContractGame {
    id: uint32
    name: string
}

struct MiniTonMatchUSDTContractPlayerInfo {
    telegramId: string
    walletAddress: address?
    entryType: string
    entryFee: coins
}

struct MiniTonMatchUSDTContractRuleInfo {
    name: string
    value: string
}

struct MiniTonMatchUSDTContractWinnerInfo {
    telegramId: string
    walletAddress: address?
    score: string
    ranking: uint8
    prizeWon: coins
    prizeSentStatus: uint8
}

struct MiniTonMatchUSDTContractMatchInfo {
    matchId: uint64
    game: MiniTonMatchUSDTContractGame
    players: map<int257, Cell<MiniTonMatchUSDTContractPlayerInfo>>
    playerCount: uint32
    coin: string
    prizePool: coins
    tactContinuation: Cell<MiniTonMatchUSDTContractMatchInfoContinuation>
}

struct MiniTonMatchUSDTContractMatchInfoContinuation {
    prizeShare: string
    commissionFee: int257
    rules: map<int257, Cell<MiniTonMatchUSDTContractRuleInfo>>
    ruleCount: uint32
    status: uint8
    winners: map<int257, Cell<MiniTonMatchUSDTContractWinnerInfo>>
    winnerCount: uint32
}

struct MiniTonMatchUSDTContractMatchResults {
    winners: map<int257, Cell<MiniTonMatchUSDTContractWinnerInfo>>
    winnerCount: uint32
}

struct MiniTonMatchUSDTContractMasterActionRequest {
    id: int257
    action: uint8
    timeout: uint32
    status: uint8
    weight: uint32
    amount: int257
    address: address
    voters: map<address, bool>
}

struct (0xd7da8740) MiniTonMatchUSDTContractMasterActionRequestMsg {
    seqno: int257
    usdtBalance: coins?
    tactContinuation: Cell<MiniTonMatchUSDTContractMasterActionRequestMsgContinuation>
}

struct MiniTonMatchUSDTContractMasterActionRequestMsgContinuation {
    request: MiniTonMatchUSDTContractMasterActionRequest
}

struct (0xf5622af4) MiniTonMatchUSDTContractVoteMsg {
    seqno: int257
    requestId: int257
    queryIdPrefix: uint64
}

struct (0xa1f0b03a) MiniTonMatchUSDTContractMatchInfoMsg {
    seqno: int257
    usdtBalance: coins?
    matchInfo: MiniTonMatchUSDTContractMatchInfo
}

struct (0x41073e2e) MiniTonMatchUSDTContractSendPrizeMsg {
    seqno: int257
    usdtBalance: coins?
    queryIdPrefix: uint64
    matchId: uint64
    telegramId: string
    walletAddress: address?
    matchResults: MiniTonMatchUSDTContractMatchResults?
    tactContinuation: Cell<MiniTonMatchUSDTContractSendPrizeMsgContinuation>
}

struct MiniTonMatchUSDTContractSendPrizeMsgContinuation {
    commissionWalletAddress: address?
}

struct (0x86912852) MiniTonMatchUSDTContractRemoveMatchDumpMsg {
    seqno: int257
    matchIds: map<int257, uint64>
}

struct (0x04939755) MiniTonMatchUSDTContractMinBalanceMsg {
    seqno: int257
    value: coins
}

struct (0x5f3d0ab3) MiniTonMatchUSDTContractSetJettonWalletAddressMsg {
    seqno: int257
    value: address
}

struct (0x636e4e1f) MiniTonMatchUSDTContractSetGasValueForJettonTransferMsg {
    seqno: int257
    value: coins
}

struct (0x0a4f3f8b) MiniTonMatchUSDTContractSetUSDTBalanceMsg {
    seqno: int257
    value: coins
}

struct (0xd53276db) MiniTonMatchUSDTContractExcesses {
    queryId: uint64
}

struct MiniTonMatchUSDTContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    voters: map<address, bool>
    voterCount: int257
    weightRequired: int257
    masterActionRequests: map<int257, Cell<MiniTonMatchUSDTContractMasterActionRequest>>
    tactContinuation: Cell<MiniTonMatchUSDTContractDataContinuation>
}

struct MiniTonMatchUSDTContractDataContinuation {
    masterActionRequestCount: int257
    currentSeqno: int257
    matches: map<int257, Cell<MiniTonMatchUSDTContractMatchInfo>>
    matchCount: int257
    minBalance: coins
    tactContinuation: Cell<MiniTonMatchUSDTContractDataContinuation2>
}

struct MiniTonMatchUSDTContractDataContinuation2 {
    myJettonWalletAddress: address
    usdtBalance: coins
    gasValueForJettonTransfer: coins
}

type MiniTonMatchUSDTContractIncomingMessage =
    | MiniTonMatchUSDTContractExcesses
    | MiniTonMatchUSDTContractMatchInfoMsg
    | MiniTonMatchUSDTContractMasterActionRequestMsg
    | MiniTonMatchUSDTContractVoteMsg
    | MiniTonMatchUSDTContractSetJettonWalletAddressMsg
    | MiniTonMatchUSDTContractSetGasValueForJettonTransferMsg
    | MiniTonMatchUSDTContractSetUSDTBalanceMsg
    | MiniTonMatchUSDTContractSendPrizeMsg
    | MiniTonMatchUSDTContractRemoveMatchDumpMsg
    | MiniTonMatchUSDTContractMinBalanceMsg
    | MiniTonMatchUSDTContractDeploy

enum MiniTonMatchUSDTContractErrors {
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
    /// Balance is not enough
    BalanceIsNotEnough = 5370
    /// Can not found this request
    CanNotFoundThisRequest = 6331
    /// Invalid sequence number
    InvalidSequenceNumber = 11749
    /// USDT Balance is not enough
    USDTBalanceIsNotEnough = 14224
    /// Only voter can call this function
    OnlyVoterCanCallThisFunction = 22944
    /// This id is already exists
    ThisIdIsAlreadyExists = 26033
    /// Only owner can call this function
    OnlyOwnerCanCallThisFunction = 27831
    /// totalPrize cannot be greater than prizePool
    TotalPrizeCannotBeGreaterThanPrizePool = 39374
    /// This match was not found
    ThisMatchWasNotFound = 40530
    /// myJettonWalletAddress is not be set
    MyJettonWalletAddressIsNotBeSet = 50304
    /// Invalid playerInfo
    InvalidPlayerInfo = 52677
    /// matchResults is invalid
    MatchResultsIsInvalid = 57905
}

get fun seqno(): int257 {
    throw 0;
}

get fun masterRequest(id: int257): MiniTonMatchUSDTContractMasterActionRequest? {
    throw 0;
}

get fun masterActionRequestCount(): int257 {
    throw 0;
}

get fun jettonWalletAddress(): address {
    throw 0;
}

get fun gasValueForJettonTransfer(): int257 {
    throw 0;
}

get fun recordedUSDTBalance(): int257 {
    throw 0;
}

get fun minBalance(): int257 {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}

get fun matchInfo(matchId: int257): MiniTonMatchUSDTContractMatchInfo? {
    throw 0;
}

get fun matchCount(): int257 {
    throw 0;
}
