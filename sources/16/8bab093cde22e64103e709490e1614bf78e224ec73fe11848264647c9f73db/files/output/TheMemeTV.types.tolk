// Generated from the verified Tact contract ABI.
contract TheMemeTV {
    storage: TheMemeTVData
    incomingMessages: TheMemeTVIncomingMessage
    thrownErrors: TheMemeTVErrors
}

struct (0x946a98b6) TheMemeTVDeploy {
    queryId: uint64
}

struct (0x49079133) TheMemeTVMint {
    amount: coins
    receiver: address
}

struct (0x152087bf) TheMemeTVMintPublic {
    amount: int257
}

struct (0x053bf3f3) TheMemeTVMintCloseOrOpen {
    status: bool
}

struct (0x51b7dea0) TheMemeTVMintLiquidityAndTreasuryTokens {
    receiver: address
}

struct (0x33407786) TheMemeTVMintEcosystemDevelopmentTokens {
    receiver: address
}

struct (0x96191fe3) TheMemeTVMintTeamTokens {
    receiver: address
}

struct (0x2b23b66c) TheMemeTVMintCompanyTokens {
    receiver: address
}

struct (0xeede2cf1) TheMemeTVMintPartnershipTokens {
    receiver: address
}

struct (0x7ede3ee1) TheMemeTVMintSmartFutureReserveTokens {
    receiver: address
}

struct TheMemeTVJettonData {
    totalSupply: int257
    mintable: bool
    owner: address
    content: cell
    walletCode: cell
}

struct (0x7bdd97de) TheMemeTVTokenBurnNotification {
    queryId: uint64
    amount: coins
    owner: address
    response_destination: address?
}

struct (0xaf1ca26a) TheMemeTVTokenUpdateContent {
    content: cell
}

struct TheMemeTVData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    totalSupply: coins
    owner: address
    content: cell
    mintable: bool
    max_supply: coins
    liquidity_tokens: coins
    community_activation_cultivation_tokens: coins
    ecosystem_development_tokens: coins
    team_tokens: coins
    tactContinuation: Cell<TheMemeTVDataContinuation>
}

struct TheMemeTVDataContinuation {
    company_tokens: coins
    partnership_tokens: coins
    smart_future_reserve_tokens: coins
    company_minted_tokens: coins
    liquidity_tokens_minted: bool
    community_activation_cultivation_tokens_minted: bool
    ecosystem_development_tokens_minted: bool
    team_first_phase_minted: bool
    team_tokens_minted: bool
    company_first_phase_minted: bool
    company_token_completed_phase: int257
    company_tokens_minted: bool
    partnership_tokens_minted: bool
    smart_future_reserve_tokens_minted: bool
    tge_timestamp: int257
    tactContinuation: Cell<TheMemeTVDataContinuation2>
}

struct TheMemeTVDataContinuation2 {
    one_year_time_in_seconds: int257
    three_months_in_seconds: int257
    pub: int257
}

type TheMemeTVIncomingMessage =
    | TheMemeTVMint
    | TheMemeTVMintLiquidityAndTreasuryTokens
    | TheMemeTVMintEcosystemDevelopmentTokens
    | TheMemeTVMintTeamTokens
    | TheMemeTVMintCompanyTokens
    | TheMemeTVMintPartnershipTokens
    | TheMemeTVMintSmartFutureReserveTokens
    | TheMemeTVMintPublic
    | TheMemeTVMintCloseOrOpen
    | TheMemeTVTokenUpdateContent
    | TheMemeTVTokenBurnNotification
    | TheMemeTVDeploy

enum TheMemeTVErrors {
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
    /// Smart future reserve tokens already minted
    SmartFutureReserveTokensAlreadyMinted = 1659
    /// liquidity tokens already minted
    LiquidityTokensAlreadyMinted = 2453
    /// Not Owner
    NotOwner = 3734
    /// Invalid value!!
    InvalidValue = 4159
    /// Invalid sender
    InvalidSender = 4429
    /// Minting is paused, can't mint anymore
    MintingIsPausedCanTMintAnymore = 4704
    /// The total supply will be overlapping.
    TheTotalSupplyWillBeOverlapping = 6898
    /// Smart future reserve tokens can only be minted after 1 year from TGE
    SmartFutureReserveTokensCanOnlyBeMintedAfter1YearFromTGE = 8115
    /// Minting is paused, Minting is paused, can't Mint Anymore
    MintingIsPausedMintingIsPausedCanTMintAnymore = 13356
    /// Can't Mint Anymore
    CanTMintAnymore = 18668
    /// Second phase of team minting not available yet
    SecondPhaseOfTeamMintingNotAvailableYet = 22671
    /// Minting is paused, can't Mint Anymore
    MintingIsPausedCanTMintAnymore2 = 29112
    /// ecosystem development tokens already minted
    EcosystemDevelopmentTokensAlreadyMinted = 29996
    /// Team tokens already minted
    TeamTokensAlreadyMinted = 32568
    /// Invalid sender!
    InvalidSender2 = 42708
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// Only Owner is allowed to withdraw
    OnlyOwnerIsAllowedToWithdraw = 44443
    /// Invalid signature
    InvalidSignature = 48401
    /// Partnership tokens already minted
    PartnershipTokensAlreadyMinted = 50423
    /// Company tokens already fully minted
    CompanyTokensAlreadyFullyMinted = 54034
    /// Invalid balance
    InvalidBalance = 62972
    /// Company Token already minted for this Quater
    CompanyTokenAlreadyMintedForThisQuater = 63994
}

get fun get_liquidity_tokens_minted(): bool {
    throw 0;
}

get fun get_ecosystem_development_tokens_minted(): bool {
    throw 0;
}

get fun unixTime(): int257 {
    throw 0;
}

get fun get_team_tokens_minted(): bool {
    throw 0;
}

get fun get_team_first_phase_minted(): bool {
    throw 0;
}

get fun get_company_tokens_minted(): bool {
    throw 0;
}

get fun get_company_first_phase_minted(): bool {
    throw 0;
}

get fun get_company_token_completed_phase(): int257 {
    throw 0;
}

get fun get_company_minted_tokens(): int257 {
    throw 0;
}

get fun get_partnership_tokens_minted(): bool {
    throw 0;
}

get fun get_smart_future_reserve_tokens_minted(): bool {
    throw 0;
}

get fun balance(): string {
    throw 0;
}

get fun get_jetton_data(): TheMemeTVJettonData {
    throw 0;
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
