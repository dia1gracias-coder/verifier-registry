// Generated from the verified Tact contract ABI.
contract SmartTAXSDEX {
    storage: SmartTAXSDEXData
    incomingMessages: SmartTAXSDEXIncomingMessage
    thrownErrors: SmartTAXSDEXErrors
}

struct (0x946a98b6) SmartTAXSDEXDeploy {
    queryId: uint64
}

struct (0x38000c15) SmartTAXSDEXBuyTokens {
    min_taxs_out: coins
    current_taxs_balance: coins
}

struct (0x37e77de9) SmartTAXSDEXSetDEXWallet {
    dex_taxs_wallet: address
}

struct (0x349970f6) SmartTAXSDEXRequestSell {
    amount: coins
    current_taxs_balance: coins
}

struct (0x178d4519) SmartTAXSDEXTokenTransferInternal {
    query_id: uint64
    amount: coins
    from: address
    response_destination: address?
    forward_ton_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct SmartTAXSDEXData {
    tactDeploymentCompleted: bool
    ton_fees_collected: int257
    owner: address
    treasury: address
    tactContinuation: Cell<SmartTAXSDEXDataContinuation>
}

struct SmartTAXSDEXDataContinuation {
    taxs_master: address
    dex_taxs_wallet: address?
    base_price: int257
    tactContinuation: Cell<SmartTAXSDEXDataContinuation2>
}

struct SmartTAXSDEXDataContinuation2 {
    price_multiplier: int257
    ton_fee_percent: int257
    gas_reserve: int257
    tactContinuation: Cell<SmartTAXSDEXDataContinuation3>
}

struct SmartTAXSDEXDataContinuation3 {
    transfer_gas: int257
    forward_gas: int257
    percentage_base: int257
    tactContinuation: Cell<SmartTAXSDEXDataContinuation4>
}

struct SmartTAXSDEXDataContinuation4 {
    decimals_divisor: int257
}

type SmartTAXSDEXIncomingMessage =
    | SmartTAXSDEXSetDEXWallet
    | SmartTAXSDEXBuyTokens
    | SmartTAXSDEXRequestSell
    | SmartTAXSDEXTokenTransferInternal
    | SmartTAXSDEXDeploy

enum SmartTAXSDEXErrors {
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
    /// No TAXSTR liquidity
    NoTAXSTRLiquidity = 17114
    /// DEX wallet not set
    DEXWalletNotSet = 29912
    /// Slippage exceeded
    SlippageExceeded = 41529
    /// Amount too small
    AmountTooSmall = 46710
    /// Insufficient TON sent
    InsufficientTONSent = 48341
    /// Only owner can set wallet
    OnlyOwnerCanSetWallet = 50308
    /// Insufficient TAXSTR reserves
    InsufficientTAXSTRReserves = 63832
}

get fun get_ton_fees_collected(): int257 {
    throw 0;
}

get fun get_price(): int257 {
    throw 0;
}

get fun get_price_for_balance(current_balance: int257): int257 {
    throw 0;
}

get fun get_dex_taxs_wallet(): address? {
    throw 0;
}

get fun get_treasury(): address {
    throw 0;
}

get fun get_taxs_master(): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
