// Generated from the verified Tact contract ABI.
contract PolymarketMaster {
    storage: PolymarketMasterData
    incomingMessages: PolymarketMasterIncomingMessage
    thrownErrors: PolymarketMasterErrors
}

struct (0x946a98b6) PolymarketMasterDeploy {
    queryId: uint64
}

struct (0x834638b4) PolymarketMasterPlaceBuyOrderNotification {
    action_id: uint64
    token_id: int257
    usd_amount: coins
    expiration: uint32
    user: address
}

struct (0x3e1ee20f) PolymarketMasterWithdrawBuyOrderNotification {
    action_id: uint64
    timestamp: uint32
    user: address
}

struct (0x2bcfa777) PolymarketMasterPlaceSellOrderNotification {
    action_id: uint64
    token_id: int257
    ct_amount: coins
    expiration: uint32
    user: address
}

struct (0x3a85da69) PolymarketMasterClaimResolvedMarketNotification {
    action_id: uint64
    token_id: int257
    user: address
}

struct (0x79b77b52) PolymarketMasterDeployUserWallet {
}

struct (0x18215f57) PolymarketMasterDeployExecutorWallet {
    executor: address
}

struct (0x3ace80fe) PolymarketMasterSetBuyFee {
    new_buy_fee: uint16
}

struct (0x59a9d1f3) PolymarketMasterSetSellFee {
    new_sell_fee: uint16
}

struct (0x5b40a8cd) PolymarketMasterFillBuyOrder {
    action_id: uint64
    user: address
    executor: address
}

struct (0xac863858) PolymarketMasterFillSellOrder {
    action_id: uint64
    user: address
    executor: address
    usd_amount: coins
}

struct PolymarketMasterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    usdt_wallet_code: cell
    usdt_master: address
    skate_gateway: address
    tactContinuation: Cell<PolymarketMasterDataContinuation>
}

struct PolymarketMasterDataContinuation {
    version_id: int257
    emergency_signer: int257
    buy_fee_bps: int257
    tactContinuation: Cell<PolymarketMasterDataContinuation2>
}

struct PolymarketMasterDataContinuation2 {
    sell_fee_bps: int257
}

type PolymarketMasterIncomingMessage =
    | PolymarketMasterDeployUserWallet
    | PolymarketMasterPlaceBuyOrderNotification
    | PolymarketMasterPlaceSellOrderNotification
    | PolymarketMasterClaimResolvedMarketNotification
    | PolymarketMasterWithdrawBuyOrderNotification
    | PolymarketMasterDeployExecutorWallet
    | PolymarketMasterSetBuyFee
    | PolymarketMasterFillBuyOrder
    | PolymarketMasterSetSellFee
    | PolymarketMasterFillSellOrder
    | PolymarketMasterDeploy

enum PolymarketMasterErrors {
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
    /// PolymarketUserWallet::Insufficient gas for SELL order!
    PolymarketUserWalletInsufficientGasForSELLOrder = 9980
    /// PolymarketMaster::Insufficient value to fill SELL order!
    PolymarketMasterInsufficientValueToFillSELLOrder = 17548
    /// PolymarketUserWallet::Insufficient gas for withdrawal!
    PolymarketUserWalletInsufficientGasForWithdrawal = 19792
    /// PolymarketMaster::New BUY fee exceeds maximum value allowed!
    PolymarketMasterNewBUYFeeExceedsMaximumValueAllowed = 25074
    /// PolymarketMaster::New SELL fee exceeds maximum value allowed!
    PolymarketMasterNewSELLFeeExceedsMaximumValueAllowed = 27549
    /// PolymarketUserWallet::Withdrawal nonce used!
    PolymarketUserWalletWithdrawalNonceUsed = 32686
    /// PolymarketUserWallet::Invalid withdraw request!
    PolymarketUserWalletInvalidWithdrawRequest = 34923
    /// PolymarketUserWallet::Withdrawal signature expired!
    PolymarketUserWalletWithdrawalSignatureExpired = 35605
    /// PolymarketMaster::set_emergency_signer()::Not approved by new signer!
    PolymarketMasterSetEmergencySignerNotApprovedByNewSigner = 37419
    /// PolymarketMaster::Insufficient value to deploy user wallet!
    PolymarketMasterInsufficientValueToDeployUserWallet = 42389
    /// PolymarketUserWallet::Invalid emergency signer signature!
    PolymarketUserWalletInvalidEmergencySignerSignature = 43633
    /// PolymarketMaster::Insufficient value to deploy executor wallet!
    PolymarketMasterInsufficientValueToDeployExecutorWallet = 44460
    /// PolymarketMaster::Insufficient value to fill BUY order!
    PolymarketMasterInsufficientValueToFillBUYOrder = 44754
    /// PolymarketMaster::Not user wallet!
    PolymarketMasterNotUserWallet = 45677
    /// PolymarketUserWallet::Bet is not expired yet!
    PolymarketUserWalletBetIsNotExpiredYet = 47956
    /// PolymarketMaster::set_emergency_signer()::Not approved by current signer!
    PolymarketMasterSetEmergencySignerNotApprovedByCurrentSigner = 54816
    /// PolymarketUserWallet::BUY order does not exists!
    PolymarketUserWalletBUYOrderDoesNotExists = 55661
    /// PolymarketUserWallet::Insufficient gas for BUY order!
    PolymarketUserWalletInsufficientGasForBUYOrder = 56362
}

get fun skate_gateway(): address {
    throw 0;
}

get fun version_id(): int257 {
    throw 0;
}

get fun emergency_signer(): int257 {
    throw 0;
}

get fun change_emergency_signer_message(): string {
    throw 0;
}

get fun user_wallet(user: address): address {
    throw 0;
}

get fun executor_wallet(executor: address): address {
    throw 0;
}

get fun buy_fee(): int257 {
    throw 0;
}

get fun sell_fee(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
