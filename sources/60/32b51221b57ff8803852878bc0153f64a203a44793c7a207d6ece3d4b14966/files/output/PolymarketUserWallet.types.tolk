// Generated from the verified Tact contract ABI.
contract PolymarketUserWallet {
    storage: PolymarketUserWalletData
    incomingMessages: PolymarketUserWalletIncomingMessage
    thrownErrors: PolymarketUserWalletErrors
}

struct (0x7362d09c) PolymarketUserWalletJettonTransferNotification {
    query_id: uint64
    amount: coins
    sender: address
    forward_payload: RemainingBitsAndRefs
}

struct (0xd53276db) PolymarketUserWalletJettonExcesses {
    query_id: uint64
}

struct (0x44807e69) PolymarketUserWalletWithdrawTON {
}

struct (0xbbd041b9) PolymarketUserWalletInitializeUserWallet {
}

struct PolymarketUserWalletStagedUSDT {
    amount: coins
    expiration: uint32
}

struct (0x84191731) PolymarketUserWalletPlaceSellOrder {
    token_id: int257
    ct_amount: coins
}

struct (0x4e7bac91) PolymarketUserWalletClaimResolvedMarket {
    token_id: int257
}

struct (0x2336dc57) PolymarketUserWalletConfirmBuyOrder {
    action_id: uint64
    executor: address
    executor_wallet: address
    fee: uint16
}

struct (0xe7471374) PolymarketUserWalletWithdrawBuyOrder {
    action_id: uint64
}

struct PolymarketUserWalletData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    master: address
    owner: address
    usdt_wallet: address
    tactContinuation: Cell<PolymarketUserWalletDataContinuation>
}

struct PolymarketUserWalletDataContinuation {
    emergency_signer: int257
    used_emergency_nonce: map<uint32, bool>
    action_id: uint64
    staged_usdt_map: map<uint64, Cell<PolymarketUserWalletStagedUSDT>>
}

type PolymarketUserWalletIncomingMessage =
    | PolymarketUserWalletInitializeUserWallet
    | PolymarketUserWalletJettonExcesses
    | PolymarketUserWalletWithdrawTON
    | PolymarketUserWalletWithdrawBuyOrder
    | PolymarketUserWalletJettonTransferNotification
    | PolymarketUserWalletPlaceSellOrder
    | PolymarketUserWalletClaimResolvedMarket
    | PolymarketUserWalletConfirmBuyOrder

enum PolymarketUserWalletErrors {
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

get fun master(): address {
    throw 0;
}

get fun usdt_wallet(): address {
    throw 0;
}

get fun emergency_signer(): int257 {
    throw 0;
}

get fun used_emergency_nonce(): map<uint32, bool> {
    throw 0;
}

get fun emergency_withdrawal_hash(amount: int257, expiration: int257, nonce: int257): int257 {
    throw 0;
}

get fun action_id(): int257 {
    throw 0;
}

get fun staged_usdt_map(): map<uint64, Cell<PolymarketUserWalletStagedUSDT>> {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
