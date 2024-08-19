// Generated from the verified Tact contract ABI.
contract MiniTonMatchToncoinContract {
    storage: MiniTonMatchToncoinContractData
    incomingMessages: MiniTonMatchToncoinContractIncomingMessage
    thrownErrors: MiniTonMatchToncoinContractErrors
}

struct (0x946a98b6) MiniTonMatchToncoinContractDeploy {
    queryId: uint64
}

struct MiniTonMatchToncoinContractGame {
    id: uint32
    name: string
}

struct MiniTonMatchToncoinContractPlayerInfo {
    telegramId: string
    walletAddress: address?
    entryType: string
    entryFee: coins
}

struct MiniTonMatchToncoinContractRuleInfo {
    name: string
    value: string
}

struct MiniTonMatchToncoinContractWinnerInfo {
    telegramId: string
    walletAddress: address?
    score: string
    ranking: uint8
    prizeWon: coins
    prizeSentStatus: uint8
}

struct MiniTonMatchToncoinContractMatchInfo {
    matchId: uint64
    game: MiniTonMatchToncoinContractGame
    players: map<int257, Cell<MiniTonMatchToncoinContractPlayerInfo>>
    playerCount: uint32
    coin: string
    prizePool: coins
    tactContinuation: Cell<MiniTonMatchToncoinContractMatchInfoContinuation>
}

struct MiniTonMatchToncoinContractMatchInfoContinuation {
    prizeShare: string
    commissionFee: int257
    rules: map<int257, Cell<MiniTonMatchToncoinContractRuleInfo>>
    ruleCount: uint32
    status: uint8
    winners: map<int257, Cell<MiniTonMatchToncoinContractWinnerInfo>>
    winnerCount: uint32
}

struct MiniTonMatchToncoinContractMatchResults {
    winners: map<int257, Cell<MiniTonMatchToncoinContractWinnerInfo>>
    winnerCount: uint32
}

struct MiniTonMatchToncoinContractMasterActionRequest {
    id: int257
    timeout: uint32
    status: uint8
    weight: uint32
    amount: int257
    address: address
    voters: map<address, bool>
}

struct (0xd4c8d8f0) MiniTonMatchToncoinContractMasterActionRequestMsg {
    seqno: int257
    tactContinuation: Cell<MiniTonMatchToncoinContractMasterActionRequestMsgContinuation>
}

struct MiniTonMatchToncoinContractMasterActionRequestMsgContinuation {
    request: MiniTonMatchToncoinContractMasterActionRequest
}

struct (0x53fd0b95) MiniTonMatchToncoinContractVoteMsg {
    seqno: int257
    requestId: int257
}

struct (0xd06ec2e3) MiniTonMatchToncoinContractMatchInfoMsg {
    seqno: int257
    matchInfo: MiniTonMatchToncoinContractMatchInfo
}

struct (0x9814a7d8) MiniTonMatchToncoinContractSendPrizeMsg {
    seqno: int257
    matchId: uint64
    telegramId: string
    walletAddress: address?
    matchResults: MiniTonMatchToncoinContractMatchResults?
    commissionWalletAddress: address?
}

struct (0x86912852) MiniTonMatchToncoinContractRemoveMatchDumpMsg {
    seqno: int257
    matchIds: map<int257, uint64>
}

struct (0x04939755) MiniTonMatchToncoinContractMinBalanceMsg {
    seqno: int257
    value: coins
}

struct MiniTonMatchToncoinContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    voters: map<address, bool>
    voterCount: int257
    weightRequired: int257
    masterActionRequests: map<int257, Cell<MiniTonMatchToncoinContractMasterActionRequest>>
    tactContinuation: Cell<MiniTonMatchToncoinContractDataContinuation>
}

struct MiniTonMatchToncoinContractDataContinuation {
    masterActionRequestCounts: int257
    currentSeqno: int257
    matches: map<int257, Cell<MiniTonMatchToncoinContractMatchInfo>>
    matchCount: int257
    minBalance: coins
}

type MiniTonMatchToncoinContractIncomingMessage =
    | MiniTonMatchToncoinContractMatchInfoMsg
    | MiniTonMatchToncoinContractMasterActionRequestMsg
    | MiniTonMatchToncoinContractVoteMsg
    | MiniTonMatchToncoinContractSendPrizeMsg
    | MiniTonMatchToncoinContractRemoveMatchDumpMsg
    | MiniTonMatchToncoinContractMinBalanceMsg
    | MiniTonMatchToncoinContractDeploy

enum MiniTonMatchToncoinContractErrors {
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
    /// Invalid playerInfo
    InvalidPlayerInfo = 52677
    /// matchResults is invalid
    MatchResultsIsInvalid = 57905
}

get fun seqno(): int257 {
    throw 0;
}

get fun masterRequest(id: int257): MiniTonMatchToncoinContractMasterActionRequest? {
    throw 0;
}

get fun minBalance(): int257 {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}

get fun matchInfo(matchId: int257): MiniTonMatchToncoinContractMatchInfo? {
    throw 0;
}

get fun matchCount(): int257 {
    throw 0;
}
