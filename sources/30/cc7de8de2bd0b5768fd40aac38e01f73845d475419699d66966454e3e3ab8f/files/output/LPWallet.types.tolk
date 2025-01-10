// Generated from the verified Tact contract ABI.
contract LPWallet {
    storage: LPWalletData
    incomingMessages: LPWalletIncomingMessage
    thrownErrors: LPWalletErrors
}

struct LPWalletJettonWalletData {
    balance: int257
    owner: address
    master: address
    code: cell
}

struct (0x0f8a7ea5) LPWalletTokenTransfer {
    query_id: uint64
    amount: coins
    sender: address
    response_destination: address?
    custom_payload: cell?
    forward_ton_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct (0x178d4519) LPWalletTokenTransferInternal {
    query_id: uint64
    amount: coins
    from: address
    response_destination: address?
    forward_ton_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct (0x595f07bc) LPWalletTokenBurn {
    query_id: uint64
    amount: coins
    response_destination: address?
    custom_payload: cell?
}

struct (0xd53276db) LPWalletTokenExcesses {
    query_id: uint64
}

struct (0x23e3b324) LPWalletWithdrawGas {
    amount: int257
}

struct LPWalletData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    balance: coins
    owner: address
    master: address
}

type LPWalletIncomingMessage =
    | LPWalletTokenExcesses
    | LPWalletTokenTransfer
    | LPWalletTokenTransferInternal
    | LPWalletTokenBurn
    | LPWalletWithdrawGas

enum LPWalletErrors {
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
    /// AccessControl: Role ID doesn't exist
    AccessControlRoleIDDoesnTExist = 2927
    /// Invalid sender
    InvalidSender = 4429
    /// AccessControl: Role ADMIN is undefined
    AccessControlRoleADMINIsUndefined = 5524
    /// AccessControl: Doesn't have the CFO role
    AccessControlDoesnTHaveTheCFORole = 6187
    /// AccessControl: BadConfirmation
    AccessControlBadConfirmation = 7947
    /// Boost: no deposit to convert to rewards
    BoostNoDepositToConvertToRewards = 10852
    /// AccessControl: Doesn't have the BRIDGE role
    AccessControlDoesnTHaveTheBRIDGERole = 10858
    /// Insufficient LP balance to withdraw rewards
    InsufficientLPBalanceToWithdrawRewards = 11399
    /// AccessControl: Role BRIDGE is undefined
    AccessControlRoleBRIDGEIsUndefined = 12450
    /// LPWallet: Invalid sender
    LPWalletInvalidSender = 14981
    /// AccessControl: Doesn't have the ADMIN role
    AccessControlDoesnTHaveTheADMINRole = 17039
    /// Deposit amount must be greater than zero.
    DepositAmountMustBeGreaterThanZero = 17389
    /// LPWallet: Insufficient gas
    LPWalletInsufficientGas = 18429
    /// AccessControl: Role doesn't exist
    AccessControlRoleDoesnTExist = 21733
    /// LPWallet: Can't Mint Anymore
    LPWalletCanTMintAnymore = 24034
    /// TokenNotification: Unauthorised call
    TokenNotificationUnauthorisedCall = 26241
    /// ReleaseTokens: Unauthorized release tokens call.
    ReleaseTokensUnauthorizedReleaseTokensCall = 26704
    /// The caller has no staking position to withdraw
    TheCallerHasNoStakingPositionToWithdraw = 29285
    /// Protocol fee cannot exceed token fee.
    ProtocolFeeCannotExceedTokenFee = 29451
    /// Gas cost must be positive.
    GasCostMustBePositive = 33665
    /// Protocol fee cannot exceed the token fee.
    ProtocolFeeCannotExceedTheTokenFee = 33951
    /// TokenBurnNotification: Missing staker position
    TokenBurnNotificationMissingStakerPosition = 34727
    /// TokenBurn: burn amount exceeds balance
    TokenBurnBurnAmountExceedsBalance = 36832
    /// Insufficient staker's balance to withdraw the amount.
    InsufficientStakerSBalanceToWithdrawTheAmount = 36999
    /// WithdrawProtocolFee: No protocol fee to withdraw
    WithdrawProtocolFeeNoProtocolFeeToWithdraw = 38716
    /// WithdrawRebalance: Insufficient balance for rebalancing
    WithdrawRebalanceInsufficientBalanceForRebalancing = 39774
    /// UpdateDeposit must originate from the LP wallet.
    UpdateDepositMustOriginateFromTheLPWallet = 41817
    /// Invalid sender!
    InvalidSender2 = 42708
    /// AccessControl: Doesnt have the role
    AccessControlDoesntHaveTheRole = 50413
    /// Withdraw amount must be greater than zero.
    WithdrawAmountMustBeGreaterThanZero = 51942
    /// WithdrawGas: Unauthorised call
    WithdrawGasUnauthorisedCall = 52858
    /// AccessControl: Role CFO is undefined
    AccessControlRoleCFOIsUndefined = 53581
    /// TokenTransfer: Insufficient TON value
    TokenTransferInsufficientTONValue = 59055
    /// TokenTransferInternal: Invalid balance
    TokenTransferInternalInvalidBalance = 60960
    /// TokenTransfer: Invalid balance
    TokenTransferInvalidBalance = 61410
}

get fun get_wallet_data(): LPWalletJettonWalletData {
    throw 0;
}
