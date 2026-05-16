// Generated from the verified Tact contract ABI.
contract BroSaleJettonMaster {
    storage: BroSaleJettonMasterData
    incomingMessages: BroSaleJettonMasterIncomingMessage
    thrownErrors: BroSaleJettonMasterErrors
}

struct (0x7bdd97de) BroSaleJettonMasterJettonBurnNotification {
    queryId: uint64
    amount: coins
    owner: address
    responseDestination: address?
}

struct (0x2c76b973) BroSaleJettonMasterProvideWalletAddress {
    queryId: uint64
    ownerAddress: address
    includeAddress: bool
}

struct (0x00000015) BroSaleJettonMasterMint {
    queryId: uint64
    receiver: address
    amount: coins
}

struct (0x00000003) BroSaleJettonMasterChangeOwner {
    newOwner: address
}

struct (0x00000004) BroSaleJettonMasterUpdateContent {
    content: cell
}

struct (0x42524f01) BroSaleJettonMasterUpdateSale {
    tokensPerTon: uint64
    hardCap: coins
    startTime: int64
    endTime: int64
}

struct (0x42524f02) BroSaleJettonMasterSetPaused {
    paused: bool
}

struct (0x42524f03) BroSaleJettonMasterSetTreasury {
    treasury: address
}

struct (0x42524f04) BroSaleJettonMasterWithdrawTon {
    amount: coins
}

struct BroSaleJettonMasterJettonData {
    totalSupply: coins
    mintable: bool
    adminAddress: address
    content: cell
    walletCode: cell
}

struct BroSaleJettonMasterData {
    tactSystemCell: cell
    totalSupply: coins
    owner: address
    treasury: address
    content: cell
    mintable: bool
    tokensPerTon: uint64
    hardCap: coins
    startTime: int64
    endTime: int64
    tactContinuation: Cell<BroSaleJettonMasterDataContinuation>
}

struct BroSaleJettonMasterDataContinuation {
    raised: coins
    soldTokens: uint128
    paused: bool
}

type BroSaleJettonMasterIncomingMessage =
    | BroSaleJettonMasterMint
    | BroSaleJettonMasterJettonBurnNotification
    | BroSaleJettonMasterProvideWalletAddress
    | BroSaleJettonMasterUpdateSale
    | BroSaleJettonMasterSetPaused
    | BroSaleJettonMasterSetTreasury
    | BroSaleJettonMasterWithdrawTon
    | BroSaleJettonMasterChangeOwner
    | BroSaleJettonMasterUpdateContent

enum BroSaleJettonMasterErrors {
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
    /// bad_supply
    BadSupply = 5435
    /// not_started
    NotStarted = 7493
    /// only_owner
    OnlyOwner = 11354
    /// bad_wallet
    BadWallet = 11956
    /// hard_cap
    HardCap = 22511
    /// bad_rate
    BadRate = 24680
    /// bad_sender
    BadSender = 25939
    /// ended
    Ended = 25952
    /// bad_time
    BadTime = 27060
    /// low_value
    LowValue = 37050
    /// mint_closed
    MintClosed = 40468
    /// paused
    Paused = 41067
    /// bad_cap
    BadCap = 50292
    /// low_balance
    LowBalance = 53360
    /// low_gas
    LowGas = 59526
    /// bad_amount
    BadAmount = 63637
}

get fun get_jetton_data(): BroSaleJettonMasterJettonData {
    throw 0;
}

get fun get_wallet_address(ownerAddress: address): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun treasury(): address {
    throw 0;
}

get fun tokensPerTon(): int257 {
    throw 0;
}

get fun hardCap(): int257 {
    throw 0;
}

get fun startTime(): int257 {
    throw 0;
}

get fun endTime(): int257 {
    throw 0;
}

get fun raised(): int257 {
    throw 0;
}

get fun soldTokens(): int257 {
    throw 0;
}

get fun paused(): bool {
    throw 0;
}
