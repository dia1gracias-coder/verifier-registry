// Generated from the verified Tact contract ABI.
contract JettonSale {
    storage: JettonSaleData
    incomingMessages: JettonSaleIncomingMessage
    thrownErrors: JettonSaleErrors
}

struct (0x946a98b6) JettonSaleDeploy {
    queryId: uint64
}

struct (0xd1735400) JettonSaleTakeWalletAddress {
    query_id: uint64
    wallet_address: address
    owner_address: address?
}

struct (0x7362d09c) JettonSaleTransferNotification {
    query_id: uint64
    amount: coins
    sender: address
    forward_payload: RemainingBitsAndRefs
}

struct JettonSalePriceInfo {
    jetton_amount: int257
    full_price: int257
    service_fee: int257
    tactContinuation: Cell<JettonSalePriceInfoContinuation>
}

struct JettonSalePriceInfoContinuation {
    service_address: address
}

struct JettonSaleSaleInfo {
    sale_ended: bool
    owner: address
    jetton_master: address
    jetton_wallet: address?
    tactContinuation: Cell<JettonSaleSaleInfoContinuation>
}

struct JettonSaleSaleInfoContinuation {
    jetton_amount: int257
    tactContinuation: Cell<JettonSaleSaleInfoContinuation2>
}

struct JettonSaleSaleInfoContinuation2 {
    price_info: JettonSalePriceInfo
}

struct JettonSaleData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    jetton_master: address
    jetton_wallet: address?
    sale_ended: bool
    jetton_amount: uint16
    price_per_ton: coins
}

type JettonSaleIncomingMessage =
    | JettonSaleTakeWalletAddress
    | JettonSaleTransferNotification
    | JettonSaleDeploy

enum JettonSaleErrors {
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
    /// Not enough jettons available for sale
    NotEnoughJettonsAvailableForSale = 6399
    /// Sale has ended
    SaleHasEnded = 9018
    /// Insufficient TON provided
    InsufficientTONProvided = 59968
}

get fun get_price_info(): JettonSalePriceInfo {
    throw 0;
}

get fun get_sale_info(): JettonSaleSaleInfo {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
