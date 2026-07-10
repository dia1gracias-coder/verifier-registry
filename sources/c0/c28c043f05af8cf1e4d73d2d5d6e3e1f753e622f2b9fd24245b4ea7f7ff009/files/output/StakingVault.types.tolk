// Generated from the verified Tact contract ABI.
contract StakingVault {
    storage: StakingVaultData
    incomingMessages: StakingVaultIncomingMessage
    thrownErrors: StakingVaultErrors
}

struct (0x946a98b6) StakingVaultDeploy {
    queryId: uint64
}

struct (0x7362d09c) StakingVaultStakeNotification {
    queryId: uint64
    amount: coins
    from: address
    forward_payload: RemainingBitsAndRefs
}

struct (0xd53276db) StakingVaultTokenExcesses {
    queryId: uint64
}

struct (0xa0645704) StakingVaultSetStakingJettonWallet {
    jettonWallet: address
}

struct (0x5eb46ee3) StakingVaultSetRewardSigner {
    publicKey: uint256
}

struct (0xee852a09) StakingVaultSetStakeSigner {
    publicKey: uint256
}

struct (0x85fcfb44) StakingVaultSetMinStake {
    amount: coins
}

struct (0x25255408) StakingVaultSetMaxWithdrawPerTx {
    amount: coins
}

struct (0x790b5039) StakingVaultStakingPause {
}

struct (0xf91d5e43) StakingVaultStakingUnpause {
}

struct (0x3ebb8c65) StakingVaultDefundTreasury {
    amount: coins
    to: address
}

struct (0xfe53d81c) StakingVaultWithdrawStakingTon {
    amount: coins
}

struct (0xaaba03cc) StakingVaultPrunePayout {
    id: uint64
}

struct (0x60362b3a) StakingVaultClaimStray {
}

struct (0x3e2a9a60) StakingVaultStakingWithdraw {
    user: address
    principal: coins
    reward: coins
    nonce: uint64
    deadline: uint64
    signature: cell
}

struct StakingVaultPayoutRecord {
    user: address
    principal: coins
    reward: coins
}

struct StakingVaultVaultState {
    owner: address
    jettonWallet: address?
    rewardSigner: uint256
    tactContinuation: Cell<StakingVaultVaultStateContinuation>
}

struct StakingVaultVaultStateContinuation {
    stakeSigner: uint256
    paused: bool
    minStake: coins
    totalStakedPrincipal: coins
    rewardTreasury: coins
    tonBalance: coins
}

struct StakingVaultData {
    tactDeploymentCompleted: bool
    owner: address
    jettonWallet: address?
    rewardSignerPublicKey: uint256
    tactContinuation: Cell<StakingVaultDataContinuation>
}

struct StakingVaultDataContinuation {
    stakeSignerPublicKey: uint256
    minStake: coins
    paused: bool
    totalStakedPrincipal: coins
    rewardTreasury: coins
    maxWithdrawPerTx: coins
    lastNonce: map<address, int257>
    payoutSeq: uint64
    pendingPayouts: map<int257, Cell<StakingVaultPayoutRecord>>
    strayCredit: map<address, coins>
}

type StakingVaultIncomingMessage =
    | StakingVaultSetStakingJettonWallet
    | StakingVaultSetRewardSigner
    | StakingVaultSetStakeSigner
    | StakingVaultSetMinStake
    | StakingVaultSetMaxWithdrawPerTx
    | StakingVaultStakingPause
    | StakingVaultStakingUnpause
    | StakingVaultDefundTreasury
    | StakingVaultWithdrawStakingTon
    | StakingVaultStakeNotification
    | StakingVaultStakingWithdraw
    | StakingVaultTokenExcesses
    | StakingVaultPrunePayout
    | StakingVaultClaimStray
    | StakingVaultDeploy

enum StakingVaultErrors {
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
    /// Exceeds reward treasury
    ExceedsRewardTreasury = 1391
    /// Attach at least 0.05 TON for gas
    AttachAtLeast005TONForGas = 1522
    /// Wallet not set
    WalletNotSet = 5673
    /// Amount must be > 0
    AmountMustBe0 = 6243
    /// No TON available
    NoTONAvailable = 9929
    /// cap >= 0
    Cap0 = 11412
    /// Exceeds available
    ExceedsAvailable = 12584
    /// Attach at least 0.08 TON for gas
    AttachAtLeast008TONForGas = 19047
    /// No stray credit
    NoStrayCredit = 24371
    /// Nonce must increase
    NonceMustIncrease = 32669
    /// Negative amount
    NegativeAmount = 32899
    /// min > 0
    Min0 = 37419
    /// Signer not set
    SignerNotSet = 38301
    /// Nothing to withdraw
    NothingToWithdraw = 40636
    /// Signature expired
    SignatureExpired = 41096
    /// Exceeds max per tx
    ExceedsMaxPerTx = 42856
    /// Invalid signature length
    InvalidSignatureLength = 43253
    /// Unknown jetton wallet
    UnknownJettonWallet = 43382
    /// Principal exceeds staked
    PrincipalExceedsStaked = 43956
    /// Invalid signature
    InvalidSignature = 48401
    /// Insufficient reward treasury
    InsufficientRewardTreasury = 48861
    /// Paused
    Paused = 59457
}

get fun get_vault_state(): StakingVaultVaultState {
    throw 0;
}

get fun get_ton_balance(): int257 {
    throw 0;
}

get fun is_operational(): bool {
    throw 0;
}

get fun get_pending_payout(nonce: int257): StakingVaultPayoutRecord? {
    throw 0;
}

get fun get_stray_credit(user: address): int257 {
    throw 0;
}

get fun get_owner(): address {
    throw 0;
}

get fun getJettonWallet(): address? {
    throw 0;
}

get fun get_min_stake(): int257 {
    throw 0;
}

get fun is_paused(): bool {
    throw 0;
}

get fun get_reward_signer(): int257 {
    throw 0;
}

get fun get_stake_signer(): int257 {
    throw 0;
}

get fun next_nonce(user: address): int257 {
    throw 0;
}

get fun get_treasury_stats(): cell {
    throw 0;
}

get fun total_staked_principal(): int257 {
    throw 0;
}

get fun reward_treasury(): int257 {
    throw 0;
}

get fun get_max_withdraw_per_tx(): int257 {
    throw 0;
}

get fun get_payout_seq(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
