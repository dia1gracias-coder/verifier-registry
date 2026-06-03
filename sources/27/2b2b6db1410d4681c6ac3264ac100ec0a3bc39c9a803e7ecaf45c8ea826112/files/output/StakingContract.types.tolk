// Generated from the verified Tact contract ABI.
contract StakingContract {
    storage: StakingContractData
    incomingMessages: StakingContractIncomingMessage
    thrownErrors: StakingContractErrors
}

struct (0x7362d09c) StakingContractJettonNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0xd53276db) StakingContractJettonExcesses {
    queryId: uint64
}

struct (0x819dbe99) StakingContractChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x7ee10a9e) StakingContractSetJettonAddressRequest {
    thisContractJettonWallet: address
}

struct (0xdf17d43b) StakingContractSetVestingContractAddressRequest {
    vestingContractAddress: address
}

struct (0xefb89d8e) StakingContractUnstake {
    stakeId: uint64
}

struct (0xe6261338) StakingContractUnstakeMultiple {
    stakeIds: map<uint16, uint64>
    count: uint16
}

struct (0x45e78cd3) StakingContractUpgrade {
    stakeId: uint64
    lockDurationIndex: uint8
}

struct (0xa683d3a4) StakingContractSetLockDurations {
    durations: map<uint8, uint32>
}

struct (0x871351b3) StakingContractAddAuthorizedStaker {
    staker: address
}

struct (0x49d72ab8) StakingContractRemoveAuthorizedStaker {
    staker: address
}

struct StakingContractStakeRecord {
    owner: address
    jettonStakeAmount: coins
    lockEndTime: uint64
}

struct StakingContractStakingData {
    thisContractJettonWallet: address
}

struct StakingContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    jettonMaster: address
    thisContractJettonWallet: address?
    tactContinuation: Cell<StakingContractDataContinuation>
}

struct StakingContractDataContinuation {
    vestingContractAddress: address?
    nextStakeId: uint64
    stakes: map<uint64, Cell<StakingContractStakeRecord>>
    userStakeCount: map<address, uint16>
    lockDurations: map<uint8, uint32>
    authorizedStakers: map<address, bool>
}

type StakingContractIncomingMessage =
    | StakingContractJettonExcesses
    | StakingContractJettonNotification
    | StakingContractSetJettonAddressRequest
    | StakingContractSetVestingContractAddressRequest
    | StakingContractSetLockDurations
    | StakingContractAddAuthorizedStaker
    | StakingContractRemoveAuthorizedStaker
    | StakingContractChangeOwner
    | StakingContractUnstake
    | StakingContractUnstakeMultiple
    | StakingContractUpgrade

enum StakingContractErrors {
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
    /// Incorrect balance after send
    IncorrectBalanceAfterSend = 2366
    /// Stake not found
    StakeNotFound = 2512
    /// Invalid sender
    InvalidSender = 4429
    /// Not enough value
    NotEnoughValue = 5165
    /// Incorrect sender
    IncorrectSender = 9215
    /// Lock duration can not be 0
    LockDurationCanNotBe0 = 10029
    /// Unauthorized burn
    UnauthorizedBurn = 10363
    /// Empty stake list
    EmptyStakeList = 12827
    /// Jetton wallet not set
    JettonWalletNotSet = 16651
    /// Forward state init is null with deploy send mode
    ForwardStateInitIsNullWithDeploySendMode = 18073
    /// Lock period not ended
    LockPeriodNotEnded = 20848
    /// Wallet address does not match jetton master
    WalletAddressDoesNotMatchJettonMaster = 22234
    /// Not stake owner
    NotStakeOwner = 23773
    /// No stake
    NoStake = 28115
    /// Insufficient amount of TON attached
    InsufficientAmountOfTONAttached = 32113
    /// Only owner
    OnlyOwner = 35499
    /// Only deployer can change burn flag
    OnlyDeployerCanChangeBurnFlag = 35681
    /// Insufficient gas for mint
    InsufficientGasForMint = 37629
    /// Invalid lock duration index
    InvalidLockDurationIndex = 39718
    /// Cannot change metadata after minting is closed
    CannotChangeMetadataAfterMintingIsClosed = 41194
    /// Invalid staker address
    InvalidStakerAddress = 42712
    /// Minimum stake is 1 jetton
    MinimumStakeIs1Jetton = 43884
    /// Maximum 1000 stakes allowed
    Maximum1000StakesAllowed = 44860
    /// Max supply reached
    MaxSupplyReached = 47714
    /// Deploy address doesn't match owner address
    DeployAddressDoesnTMatchOwnerAddress = 51864
    /// Mint is closed
    MintIsClosed = 51950
    /// Incorrect send amount
    IncorrectSendAmount = 52281
    /// Too many stakes
    TooManyStakes = 54231
    /// Burning is not allowed
    BurningIsNotAllowed = 60460
    /// Missing stake id
    MissingStakeId = 62216
}

get fun getStakeById(stakeId: int257): StakingContractStakeRecord {
    throw 0;
}

get fun getReturnStakingData(): StakingContractStakingData {
    throw 0;
}

get fun getJettonMaster(): address {
    throw 0;
}

get fun getUserStakeCount(user: address): int257 {
    throw 0;
}

get fun getNextStakeId(): int257 {
    throw 0;
}

get fun isAuthorizedStaker(staker: address): bool {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
