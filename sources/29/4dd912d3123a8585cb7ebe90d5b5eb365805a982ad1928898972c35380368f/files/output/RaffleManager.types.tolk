// Generated from the verified Tact contract ABI.
contract RaffleManager {
    storage: RaffleManagerData
    incomingMessages: RaffleManagerIncomingMessage
    thrownErrors: RaffleManagerErrors
}

struct (0x946a98b6) RaffleManagerDeploy {
    queryId: uint64
}

struct (0x819dbe99) RaffleManagerChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x1c2722e0) RaffleManagerCreateTpot {
    tpotId: int257
    entryFee: int257
    startAt: int257
    tactContinuation: Cell<RaffleManagerCreateTpotContinuation>
}

struct RaffleManagerCreateTpotContinuation {
    endAt: int257
    ownerPercentage: int257
    referralPercentage: int257
}

struct (0x599503dc) RaffleManagerJoinTpot {
    tpotId: int257
    referralAddress: address
}

struct (0xc726f72e) RaffleManagerCloseTpot {
    tpotId: int257
}

struct (0x03c78cef) RaffleManagerSetWinner {
    tpotId: int257
    index: int257
    isExistsReferral: bool
    referralAddress: address
}

struct (0xb4578c08) RaffleManagerUpdateWinner {
    tpotId: int257
    index: int257
    isExistsReferral: bool
    referralAddress: address
}

struct (0xaab46bd6) RaffleManagerOwnerShareToTreasury {
    tpotId: int257
}

struct (0x961ad814) RaffleManagerClaimWinner {
    tpotId: int257
}

struct (0x2d871270) RaffleManagerClaimWinnersReferralReward {
    tpotId: int257
}

struct (0x10f0c005) RaffleManagerClaimJoinReferralReward {
}

struct (0x46f1399c) RaffleManagerSetTreasury {
    treasuryAddr: address
}

struct (0xbd1227f3) RaffleManagerSetStartEndTime {
    tpotId: int257
    startAt: int257
    endAt: int257
}

struct (0xdd01ae2c) RaffleManagerWithdrawAll {
}

struct (0x0c5db7d4) RaffleManagerWithdrawAllWithoutDestruction {
}

struct (0xa4db9f5f) RaffleManagerWithdrawAllExcludingPrize {
}

struct (0x33433d62) RaffleManagerSetJoinReferralPercentage {
    percentage: int257
}

struct (0xb2bb4979) RaffleManagerSetGasFeePercentage {
    percentage: int257
}

struct (0xefcee50c) RaffleManagerDeleteTpot {
    tpotId: int257
}

struct RaffleManagerWinner {
    address: address
    prizeAmount: uint128
    isClaimed: bool
    claimedAt: uint32
    claimAbleAt: uint32
}

struct RaffleManagerTPotOwnerInfo {
    amount: uint128
    isClaimed: bool
    isRemainingPrizeClaimed: bool
    claimedAt: uint32
}

struct RaffleManagerTpotInfo {
    tpotId: uint32
    totalAmount: uint128
    entryFee: uint128
    participants: map<uint32, address>
    participantsLength: uint32
    winner: RaffleManagerWinner
    tactContinuation: Cell<RaffleManagerTpotInfoContinuation>
}

struct RaffleManagerTpotInfoContinuation {
    referral: RaffleManagerWinner
    closed: bool
    createdAt: uint32
    startAt: uint32
    endAt: uint32
    ownerPercentage: uint8
    referralPercentage: uint8
    owner: RaffleManagerTPotOwnerInfo
}

struct RaffleManagerParticipantInfo {
    totalJoinReferralAmount: uint128
    currentReferralAmount: uint128
    lastEntryAt: uint32
    entryCount: uint32
    lastClaimedAt: uint32
    claimableAt: uint32
}

struct RaffleManagerData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    treasuryAddress: address
    tpots: map<uint32, Cell<RaffleManagerTpotInfo>>
    participantInfo: map<address, Cell<RaffleManagerParticipantInfo>>
    joinReferralPercentage: uint8
    gasFeePercentage: uint8
}

type RaffleManagerIncomingMessage =
    | RaffleManagerCreateTpot
    | RaffleManagerJoinTpot
    | RaffleManagerCloseTpot
    | RaffleManagerDeleteTpot
    | RaffleManagerSetWinner
    | RaffleManagerUpdateWinner
    | RaffleManagerOwnerShareToTreasury
    | RaffleManagerClaimWinner
    | RaffleManagerClaimWinnersReferralReward
    | RaffleManagerClaimJoinReferralReward
    | RaffleManagerSetTreasury
    | RaffleManagerSetStartEndTime
    | RaffleManagerWithdrawAllWithoutDestruction
    | RaffleManagerWithdrawAll
    | RaffleManagerWithdrawAllExcludingPrize
    | RaffleManagerSetJoinReferralPercentage
    | RaffleManagerSetGasFeePercentage
    | RaffleManagerDeploy
    | RaffleManagerChangeOwner

enum RaffleManagerErrors {
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
    /// Already taken!!
    AlreadyTaken = 2768
    /// Already taken.
    AlreadyTaken2 = 9770
    /// Claiming time is over
    ClaimingTimeIsOver = 9924
    /// T-Pot is closed
    TPotIsClosed = 15275
    /// T-Pot is still open
    TPotIsStillOpen = 15348
    /// Only deployer is allowed to withdraw
    OnlyDeployerIsAllowedToWithdraw = 15509
    /// Only the winner is allowed to claim
    OnlyTheWinnerIsAllowedToClaim = 15724
    /// No amount available for claim
    NoAmountAvailableForClaim = 16067
    /// Winner claim pending
    WinnerClaimPending = 16069
    /// Referral has already been claimed
    ReferralHasAlreadyBeenClaimed = 16214
    /// This T-Pot is no longer available
    ThisTPotIsNoLongerAvailable = 22932
    /// T-Pot is already closed
    TPotIsAlreadyClosed = 28668
    /// T-Pot is still open.
    TPotIsStillOpen2 = 32544
    /// Owner claim pending
    OwnerClaimPending = 36741
    /// Participant does not exist
    ParticipantDoesNotExist = 37142
    /// Owner’s share zeor
    OwnerSShareZeor = 37233
    /// Winner's referral claim pending
    WinnerSReferralClaimPending = 39921
    /// Winner has already been claimed
    WinnerHasAlreadyBeenClaimed = 41826
    /// Winner prize amount is 0!!
    WinnerPrizeAmountIs0 = 41972
    /// T-Pot participant does not exist
    TPotParticipantDoesNotExist = 43348
    /// Index out of bounds
    IndexOutOfBounds = 44718
    /// Address does not exist
    AddressDoesNotExist = 45737
    /// T-Pot does not exist
    TPotDoesNotExist = 47240
    /// Insufficient entry fee for T-Pot
    InsufficientEntryFeeForTPot = 48221
    /// T-Pot ID already exists
    TPotIDAlreadyExists = 54416
    /// Winner index not valid!
    WinnerIndexNotValid = 58645
    /// Contract balance is insufficient!!!
    ContractBalanceIsInsufficient = 62957
    /// The winner has already been selected
    TheWinnerHasAlreadyBeenSelected = 63155
    /// Winner is not registed yet
    WinnerIsNotRegistedYet = 63290
}

get fun balance(tpotId: int257): string {
    throw 0;
}

get fun tpotInfo(tpotId: int257): RaffleManagerTpotInfo {
    throw 0;
}

get fun participant(tpotId: int257, index: int257): address {
    throw 0;
}

get fun joinReferralRewardAmount(address: address): int257 {
    throw 0;
}

get fun participantInfo(address: address): RaffleManagerParticipantInfo {
    throw 0;
}

get fun allParticipantInfos(): map<address, Cell<RaffleManagerParticipantInfo>> {
    throw 0;
}

get fun treasuryAddress(): address {
    throw 0;
}

get fun currentPotEntryFee(tpotId: int257): int257 {
    throw 0;
}

get fun allTpots(): map<uint32, Cell<RaffleManagerTpotInfo>> {
    throw 0;
}

get fun pureTransactionSumExcludingPrize(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
