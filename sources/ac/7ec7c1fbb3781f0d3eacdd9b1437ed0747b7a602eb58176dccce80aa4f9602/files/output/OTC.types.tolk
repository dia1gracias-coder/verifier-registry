// Generated from the verified Tact contract ABI.
contract OTC {
    storage: OTCData
    incomingMessages: OTCIncomingMessage
    thrownErrors: OTCErrors
}

struct (0x7362d09c) OTCTokenNotification {
    query_id: uint64
    amount: coins
    from: address
    forward_payload: RemainingBitsAndRefs
}

struct (0xd1735400) OTCTakeWalletAddress {
    query_id: uint64
    wallet_address: address
    owner_address: RemainingBitsAndRefs
}

struct (0xe94ce48e) OTCDepositTon {
    amount: coins
}

struct OTCSupply {
    input: coins
    output: coins
}

struct (0x2e670e03) OTCWithdrawInput {
    queryId: uint64
    amount: coins
}

struct (0x99efad87) OTCWithdrawOutput {
    queryId: uint64
    amount: coins
}

struct OTCFarmWithdrawData {
    farmAccount: address
    sendData: cell
}

struct (0x6b34e081) OTCProposeFarmAccount {
    queryId: uint64
    withdrawData: OTCFarmWithdrawData
}

struct (0x1c301f00) OTCSend {
    queryId: uint64
    forwardTonAmount: coins
}

struct (0x63acc429) OTCBuybackLaunchJetton {
    queryId: uint64
    amount: coins
}

struct OTCData {
    tactDeploymentCompleted: bool
    id: uint32
    inputMasterToken: address
    outputMasterToken: address
    inputWalletAddress: address
    tactContinuation: Cell<OTCDataContinuation>
}

struct OTCDataContinuation {
    outputWalletAddress: address
    admin: address
    client: address
    tonBalance: coins
    tactContinuation: Cell<OTCDataContinuation2>
}

struct OTCDataContinuation2 {
    outputTokenBalance: coins
    supplies: map<uint8, Cell<OTCSupply>>
    supplyCount: uint8
    indexSupply: uint8
    buybackPrice: coins
    minInputAmount: coins
    outputMinAmount: coins
    supplyLockEnd: uint64
    totalLockEnd: uint64
    isSupply: bool
    state: uint8
    withdrawData: OTCFarmWithdrawData?
    proposedAt: uint64?
}

type OTCIncomingMessage =
    | OTCTakeWalletAddress
    | OTCDepositTon
    | OTCWithdrawInput
    | OTCWithdrawOutput
    | OTCTokenNotification
    | OTCProposeFarmAccount
    | OTCSend
    | OTCBuybackLaunchJetton

enum OTCErrors {
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
    /// State must allow client voting
    StateMustAllowClientVoting = 4075
    /// Supply lock is active
    SupplyLockIsActive = 5585
    /// Not enough output token for buyback
    NotEnoughOutputTokenForBuyback = 7855
    /// Buyback only for TON inputs
    BuybackOnlyForTONInputs = 10832
    /// Amount must be greater than supply output
    AmountMustBeGreaterThanSupplyOutput = 11061
    /// Input token is not supply
    InputTokenIsNotSupply = 13776
    /// Only client can call
    OnlyClientCanCall = 14938
    /// Only admin
    OnlyAdmin = 16461
    /// Only client or admin can check output
    OnlyClientOrAdminCanCheckOutput = 19679
    /// Farm account must be proposed first
    FarmAccountMustBeProposedFirst = 20431
    /// Not enough POK for buyback
    NotEnoughPOKForBuyback = 22162
    /// State must be waiting for client answer or client rejected or canceled
    StateMustBeWaitingForClientAnswerOrClientRejectedOrCanceled = 24198
    /// Only client can withdraw TON
    OnlyClientCanWithdrawTON = 25194
    /// Output wallet address already set
    OutputWalletAddressAlreadySet = 26724
    /// Total lock is active
    TotalLockIsActive = 28027
    /// Only admin can initialize the contract
    OnlyAdminCanInitializeTheContract = 28207
    /// Input token is supply
    InputTokenIsSupply = 29194
    /// Value must be greater than min check input amount
    ValueMustBeGreaterThanMinCheckInputAmount = 29200
    /// Input sum must be greater than min input amount
    InputSumMustBeGreaterThanMinInputAmount = 31685
    /// Input wallet address already set
    InputWalletAddressAlreadySet = 31712
    /// Withdraw data must be set
    WithdrawDataMustBeSet = 37986
    /// Value must be greater than min admin send value
    ValueMustBeGreaterThanMinAdminSendValue = 38769
    /// Only admin can buyback
    OnlyAdminCanBuyback = 42340
    /// Only client can withdraw input jetton
    OnlyClientCanWithdrawInputJetton = 44747
    /// Only input master token or output master token can take wallet address
    OnlyInputMasterTokenOrOutputMasterTokenCanTakeWalletAddress = 46067
    /// Only client can withdraw output jetton
    OnlyClientCanWithdrawOutputJetton = 46861
    /// State must be replenishment of funds
    StateMustBeReplenishmentOfFunds = 47597
    /// Value must be greater than min check output amount
    ValueMustBeGreaterThanMinCheckOutputAmount = 50554
    /// Supply count must be greater than 0 if input master token is not null or equal to zero if input master token is null
    SupplyCountMustBeGreaterThan0IfInputMasterTokenIsNotNullOrEqualToZeroIfInputMasterTokenIsNull = 50790
    /// Input token is jetton
    InputTokenIsJetton = 51397
    /// Client must have accepted the proposal
    ClientMustHaveAcceptedTheProposal = 51446
    /// State must be supply provided
    StateMustBeSupplyProvided = 51964
    /// Propose farm account lock is active
    ProposeFarmAccountLockIsActive = 54152
    /// Only client or admin can check input
    OnlyClientOrAdminCanCheckInput = 55561
    /// Value must be greater than amount
    ValueMustBeGreaterThanAmount = 60484
    /// Output sum must be greater than output min amount
    OutputSumMustBeGreaterThanOutputMinAmount = 62916
    /// State must be supply of funds
    StateMustBeSupplyOfFunds = 62935
}

get fun outputTokenMaster(): address {
    throw 0;
}

get fun inputTokenMaster(): address {
    throw 0;
}

get fun inputWallet(): address {
    throw 0;
}

get fun outputWallet(): address {
    throw 0;
}

get fun adminAddress(): address {
    throw 0;
}

get fun clientAddress(): address {
    throw 0;
}

get fun tonBalanceAmount(): int257 {
    throw 0;
}

get fun outputTokenBalanceAmount(): int257 {
    throw 0;
}

get fun supplyCountValue(): int257 {
    throw 0;
}

get fun currentSupplyIndex(): int257 {
    throw 0;
}

get fun refundPrice(): int257 {
    throw 0;
}

get fun minInputAmountValue(): int257 {
    throw 0;
}

get fun minOutputAmount(): int257 {
    throw 0;
}

get fun supplyLockEndTime(): int257 {
    throw 0;
}

get fun totalLockEndTime(): int257 {
    throw 0;
}

get fun buybackPrice(): int257 {
    throw 0;
}

get fun currentState(): int257 {
    throw 0;
}

get fun withdrawDataInfo(): OTCFarmWithdrawData? {
    throw 0;
}

get fun proposedTime(): int257? {
    throw 0;
}

get fun contractId(): int257 {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}
