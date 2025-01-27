// Generated from the verified Tact contract ABI.
contract MadWorld {
    storage: MadWorldData
    incomingMessages: MadWorldIncomingMessage
    thrownErrors: MadWorldErrors
}

struct (0x946a98b6) MadWorldDeploy {
    queryId: uint64
}

struct (0xd53276db) MadWorldExcesses {
    query_id: uint64
}

struct (0x7a308481) MadWorldAdminMint {
    country: uint16
    amount: coins
    receiver: address
}

struct (0x7a308482) MadWorldBuyToken {
    country: uint16
    amount: coins
}

struct (0x7a308485) MadWorldDeployCountry {
    id: uint16
    jetton_content: cell
    nft_content: cell
    royalty_params: MadWorldRoyaltyParams
}

struct (0x7a308486) MadWorldChangeTransactionFee {
    tx_fee: uint16
}

struct (0x7a308487) MadWorldChangeFeeWallet {
    fee_wallet: address
}

struct (0x7a308488) MadWorldBatchAddUserHoldings {
    country: uint16
    user_amount: map<address, int257>
    length: uint16
}

struct (0x7a308489) MadWorldBatchRemoveUserHoldings {
    country: uint16
    user_amount: map<address, int257>
    length: uint16
}

struct (0x7a30848a) MadWorldChangeAsymptote {
    country: uint16
    asymptote: int257
}

struct (0x7a30848b) MadWorldChangeScaleParam {
    country: uint16
    scale_param: int257
}

struct (0x7a30848c) MadWorldChangeTokenLockStatus {
    country: uint16
    status: bool
}

struct (0x7a30848d) MadWorldRedeemTokens {
    country: uint16
    amount: coins
    receiver: address
}

struct (0x7a30848e) MadWorldStakeTokens {
    country: uint16
    amount: coins
}

struct (0x8a29df8f) MadWorldBatchUpdateAsymptote {
    query_id: int257
    country_asymptotes: map<uint16, int257>
    length: uint16
}

struct (0x8a29df90) MadWorldBatchUpdateScaleParam {
    query_id: int257
    country_scale_params: map<uint16, int257>
    length: uint16
}

struct (0x8a29df91) MadWorldRemoveCountryHolding {
    country: uint64
    percentage: uint32
}

struct (0x8a29df92) MadWorldBatchRemoveCountryHolding {
    query_id: int257
    country_percentage: map<uint16, uint32>
    length: uint16
}

struct (0x8a29df93) MadWorldAddCountryHolding {
    country: uint64
    amount: coins
}

struct (0x8a29df94) MadWorldBatchAddCountryHolding {
    query_id: int257
    country_amount: map<uint16, int257>
    length: uint16
}

struct (0x8a29df95) MadWorldMintCustomAttack {
    query_id: int257
    country: uint16
    owner: address
}

struct (0x8a29df97) MadWorldWithdrawAllTon {
    query_id: int257
}

struct (0x8a29df98) MadWorldChangeGrowthRate {
    country: uint16
    growth_rate: int257
}

struct (0x8a29df99) MadWorldBatchUpdateGrowthRate {
    query_id: int257
    country_growth_rates: map<uint16, int257>
    length: uint16
}

struct (0x8a29df9a) MadWorldBatchDeployCountries {
    query_id: int257
    countries: map<uint16, Cell<MadWorldCountryForDeployment>>
    length: uint16
}

struct (0x8a29df9b) MadWorldBatchMint {
    query_id: int257
    mints: map<uint16, Cell<MadWorldTokenToMint>>
    length: uint16
}

struct MadWorldUserRoles {
    roles: map<uint8, bool>
}

struct (0x7744d640) MadWorldGrantRole {
    role: uint8
    user: address
}

struct (0x7744d641) MadWorldRevokeRole {
    role: uint8
    user: address
}

struct MadWorldCountryData {
    buyable: bool
    sellable: bool
    token_locked: bool
    asymptote: int257
    scale_param: int257
    growth_rate: int257
    total_holding: coins
    tactContinuation: Cell<MadWorldCountryDataContinuation>
}

struct MadWorldCountryDataContinuation {
    token_address: address
}

struct MadWorldCountryForDeployment {
    id: uint16
    jetton_content: cell
    nft_content: cell
    royalty_params: MadWorldRoyaltyParams
}

struct MadWorldTokenToMint {
    country: uint16
    amount: coins
    receiver: address
}

struct MadWorldRoyaltyParams {
    numerator: uint16
    denominator: uint16
    destination: address
}

struct MadWorldData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    min_fee: int257
    burn_fee: int257
    tx_fee: uint16
    fee_wallet: address
    tactContinuation: Cell<MadWorldDataContinuation>
}

struct MadWorldDataContinuation {
    nonce: int257
    admin_initialized: bool
    user_roles: map<address, Cell<MadWorldUserRoles>>
    countries: map<uint16, Cell<MadWorldCountryData>>
    custom_attacks: map<uint16, address>
}

type MadWorldIncomingMessage =
    | MadWorldAdminMint
    | MadWorldBatchMint
    | MadWorldDeployCountry
    | MadWorldBatchDeployCountries
    | MadWorldBatchAddUserHoldings
    | MadWorldBatchRemoveUserHoldings
    | MadWorldChangeTransactionFee
    | MadWorldChangeFeeWallet
    | MadWorldChangeAsymptote
    | MadWorldChangeScaleParam
    | MadWorldChangeGrowthRate
    | MadWorldChangeTokenLockStatus
    | MadWorldRedeemTokens
    | MadWorldRemoveCountryHolding
    | MadWorldBatchRemoveCountryHolding
    | MadWorldAddCountryHolding
    | MadWorldBatchAddCountryHolding
    | MadWorldMintCustomAttack
    | MadWorldWithdrawAllTon
    | MadWorldBatchUpdateAsymptote
    | MadWorldBatchUpdateScaleParam
    | MadWorldBatchUpdateGrowthRate
    | MadWorldBuyToken
    | MadWorldStakeTokens
    | MadWorldExcesses
    | MadWorldDeploy
    | MadWorldGrantRole
    | MadWorldRevokeRole

enum MadWorldErrors {
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
    /// JettonWallet: Only Jetton master or Jetton wallet can call this function
    JettonWalletOnlyJettonMasterOrJettonWalletCanCallThisFunction = 2296
    /// Already initialized
    AlreadyInitialized = 2977
    /// NFTItemStandard: Only the collection can initialize the NFT item
    NFTItemStandardOnlyTheCollectionCanInitializeTheNFTItem = 4020
    /// Cannot sell more than the total holding
    CannotSellMoreThanTheTotalHolding = 6075
    /// Sender is not a Jetton wallet
    SenderIsNotAJettonWallet = 9739
    /// User role already granted
    UserRoleAlreadyGranted = 9965
    /// Invalid address
    InvalidAddress2 = 10905
    /// JettonWallet: Not enough jettons to transfer
    JettonWalletNotEnoughJettonsToTransfer = 13105
    /// No user roles granted
    NoUserRolesGranted = 13952
    /// Not owner
    NotOwner = 14534
    /// Invalid value
    InvalidValue = 16059
    /// Invalid amount
    InvalidAmount = 17062
    /// Country token not buyable
    CountryTokenNotBuyable = 18625
    /// Only owner can call this function
    OnlyOwnerCanCallThisFunction = 27831
    /// JettonWallet: Not allow negative balance after internal transfer
    JettonWalletNotAllowNegativeBalanceAfterInternalTransfer = 29133
    /// JettonMaster: Jetton is not mintable
    JettonMasterJettonIsNotMintable = 30061
    /// Total holding cannot be negative
    TotalHoldingCannotBeNegative = 30900
    /// NFTItemStandard: Only the owner or collection can transfer the NFT item
    NFTItemStandardOnlyTheOwnerOrCollectionCanTransferTheNFTItem = 32575
    /// Not enough funds to transfer
    NotEnoughFundsToTransfer = 37185
    /// Insufficient funds to shoulder fee
    InsufficientFundsToShoulderFee = 39782
    /// UserAmount is empty
    UserAmountIsEmpty = 41933
    /// JettonMaster: Sender is not a Jetton owner
    JettonMasterSenderIsNotAJettonOwner = 43365
    /// Unauthorized user
    UnauthorizedUser = 43784
    /// User role not granted
    UserRoleNotGranted = 46318
    /// JettonWallet: Only owner can burn tokens
    JettonWalletOnlyOwnerCanBurnTokens = 47048
    /// Country token is locked
    CountryTokenIsLocked = 56014
    /// JettonWallet: Not enough balance to burn tokens
    JettonWalletNotEnoughBalanceToBurnTokens = 60354
    /// Country token not found
    CountryTokenNotFound = 62849
}

get fun balance(): int257 {
    throw 0;
}

get fun country(id: int257): MadWorldCountryData {
    throw 0;
}

get fun country_custom_attack(id: int257): address {
    throw 0;
}

get fun countries(): map<uint16, Cell<MadWorldCountryData>> {
    throw 0;
}

get fun total_holding(country: int257): int257 {
    throw 0;
}

get fun buy_price(country: int257, amount: int257): int257 {
    throw 0;
}

get fun sell_price(country: int257, amount: int257): int257 {
    throw 0;
}

get fun tx_fee_amount(base_price: int257): int257 {
    throw 0;
}

get fun current_price(country: int257): int257 {
    throw 0;
}

get fun tx_fee(): int257 {
    throw 0;
}

get fun fee_wallet(): address {
    throw 0;
}

get fun from_string_to_cell(link: string): cell {
    throw 0;
}

get fun user_exist(user: address): bool {
    throw 0;
}

get fun user_roles(user: address): MadWorldUserRoles {
    throw 0;
}

get fun has_role(role: int257, user: address): bool {
    throw 0;
}
