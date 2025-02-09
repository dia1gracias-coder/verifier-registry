// Generated from the verified Tact contract ABI.
contract ProofOfCapital {
    storage: ProofOfCapitalData
    incomingMessages: ProofOfCapitalIncomingMessage
    thrownErrors: ProofOfCapitalErrors
}

struct (0x946a98b6) ProofOfCapitalDeploy {
    queryId: uint64
}

struct (0x819dbe99) ProofOfCapitalChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0xd1735400) ProofOfCapitalTakeWalletAddress {
    query_id: uint64
    wallet_address: address
}

struct (0xa2591ffa) ProofOfCapitalExtendLock {
    additionalTime: uint32
}

struct (0x7362d09c) ProofOfCapitalJettonTransferNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0x43dc0b54) ProofOfCapitalChangeMarketMaker {
    newMarketMakerAddress: address
}

struct (0x2b02b3ec) ProofOfCapitalChangeReturnWallet {
    newReturnWalletAddress: address
}

struct (0x4437c0ba) ProofOfCapitalWithdrawAllTons {
}

struct (0xa7c7dbfc) ProofOfCapitalWithdrawAllCoins {
}

struct (0xb981c4f4) ProofOfCapitalAddAdditionalJettonData {
    newAdditionalJettonMasterAddress: address
    newAdditionalJettonWalletAddress: address
    amount: coins
}

struct (0xec16033c) ProofOfCapitalWithdrawUnusedTons {
}

struct ProofOfCapitalData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    id: uint256
    owner: address
    jettonMasterAddress: address
    tactContinuation: Cell<ProofOfCapitalDataContinuation>
}

struct ProofOfCapitalDataContinuation {
    marketMakerAddress: address
    returnWalletAddress: address
    royaltyWalletAddress: address
    lockEndTime: uint64
    initialPricePerToken: coins
    tactContinuation: Cell<ProofOfCapitalDataContinuation2>
}

struct ProofOfCapitalDataContinuation2 {
    firstLevelJettonQuantity: coins
    priceIncrementMultiplier: uint16
    levelIncreaseMultiplier: uint16
    trendChangeStep: uint8
    levelIncreaseMultiplierafterTrend: uint16
    profitPercentage: uint16
    queryId: uint64
    totalJettonsSold: coins
    contractTonBalance: coins
    contractJettonBalance: coins
    tonBalanceRedemption: coins
    jettonsEarned: coins
    commission: coins
    tactContinuation: Cell<ProofOfCapitalDataContinuation3>
}

struct ProofOfCapitalDataContinuation3 {
    quantityJettonsPerLevel: coins
    actualProfit: coins
    currentPrice: coins
    anotherTokenAmount: coins
    currentStep: coins
    remainderOfStep: coins
    currentStepEarned: coins
    remainderOfStepEarned: coins
    tactContinuation: Cell<ProofOfCapitalDataContinuation4>
}

struct ProofOfCapitalDataContinuation4 {
    quantityJettonsPerLevelEarned: coins
    currentPriceEarned: coins
    contractJettonWalletAddress: address
    additionalJettonWalletAddress: address
    tactContinuation: Cell<ProofOfCapitalDataContinuation5>
}

struct ProofOfCapitalDataContinuation5 {
    additionalJettonMasterAddress: address
}

type ProofOfCapitalIncomingMessage =
    | ProofOfCapitalTakeWalletAddress
    | ProofOfCapitalExtendLock
    | ProofOfCapitalChangeMarketMaker
    | ProofOfCapitalChangeReturnWallet
    | ProofOfCapitalAddAdditionalJettonData
    | ProofOfCapitalJettonTransferNotification
    | ProofOfCapitalWithdrawAllCoins
    | ProofOfCapitalWithdrawAllTons
    | ProofOfCapitalWithdrawUnusedTons
    | ProofOfCapitalDeploy
    | ProofOfCapitalChangeOwner

enum ProofOfCapitalErrors {
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
    /// Invalid sender
    InvalidSender = 4429
    /// Amount must be greater than 0.15
    AmountMustBeGreaterThan015 = 11136
    /// Notification not from your jetton wallet!
    NotificationNotFromYourJettonWallet = 12495
    /// Not have tokensAvailableForBuyback
    NotHaveTokensAvailableForBuyback = 17187
    /// Additional addresses match addresses of the main jetton!
    AdditionalAddressesMatchAddressesOfTheMainJetton = 17381
    /// Amount must be greater than 0.05
    AmountMustBeGreaterThan005 = 17396
    /// Invalid time!
    InvalidTime = 24224
    /// Earned jettons are more than sold!
    EarnedJettonsAreMoreThanSold = 27349
    /// Lock period has not ended yet!
    LockPeriodHasNotEndedYet = 44995
    /// Amount tonToPay must be greater than 0
    AmountTonToPayMustBeGreaterThan0 = 53127
    /// Now can trade only MarketMaker
    NowCanTradeOnlyMarketMaker = 58951
}

get fun remaining_seconds(): int257 {
    throw 0;
}

get fun trading_opportunity(): bool {
    throw 0;
}

get fun jetton_balance(): int257 {
    throw 0;
}

get fun jetton_sold(): int257 {
    throw 0;
}

get fun jetton_available(): int257 {
    throw 0;
}

get fun ton_balance(): int257 {
    throw 0;
}

get fun profit(): int257 {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}

get fun market_maker_address(): address {
    throw 0;
}

get fun return_wallet_address(): address {
    throw 0;
}

get fun owner_address(): address {
    throw 0;
}

get fun jetton_wallet_address(): address {
    throw 0;
}

get fun current_step(): int257 {
    throw 0;
}

get fun step_remainder(): int257 {
    throw 0;
}

get fun ton_to_jetton_calculation(a: int257): int257 {
    throw 0;
}

get fun jetton_to_ton_calculation(a: int257): int257 {
    throw 0;
}

get fun jetton_to_return_calculation(a: int257): int257 {
    throw 0;
}

get fun contract_address(): address {
    throw 0;
}

get fun additional_jetton_master_address(): address {
    throw 0;
}

get fun additional_jetton_wallet_address(): address {
    throw 0;
}

get fun unused_tons(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
