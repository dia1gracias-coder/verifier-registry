// Generated from the verified Tact contract ABI.
contract NftSale {
    storage: NftSaleData
    incomingMessages: NftSaleIncomingMessage
    thrownErrors: NftSaleErrors
}

struct (0x946a98b6) NftSaleDeploy {
    queryId: uint64
}

struct (0xd1735400) NftSaleTakeWalletAddress {
    query_id: uint64
    wallet_address: address
    owner_address: address?
}

struct (0x05138d91) NftSaleNftOwnershipAssigned {
    query_id: uint64
    prev_owner: address
    forward_payload: RemainingBitsAndRefs
}

struct (0x7362d09c) NftSaleTransferNotification {
    query_id: uint64
    amount: coins
    sender: address
    forward_payload: RemainingBitsAndRefs
}

struct NftSalePriceInfo {
    price: int257
    full_price: int257
    royalty_fee: int257
    tactContinuation: Cell<NftSalePriceInfoContinuation>
}

struct NftSalePriceInfoContinuation {
    royalty_destination: address?
    service_fee: int257
    service_address: address
}

struct NftSaleSaleInfo {
    sale_ended: bool
    owner: address
    nft: address
    nft_received: bool
    jetton_master: address
    tactContinuation: Cell<NftSaleSaleInfoContinuation>
}

struct NftSaleSaleInfoContinuation {
    jetton_wallet: address?
    tactContinuation: Cell<NftSaleSaleInfoContinuation2>
}

struct NftSaleSaleInfoContinuation2 {
    price_info: NftSalePriceInfo
}

struct NftSaleData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    nft: address
    nft_received: bool
    jetton_master: address
    tactContinuation: Cell<NftSaleDataContinuation>
}

struct NftSaleDataContinuation {
    jetton_wallet: address?
    numerator: uint16
    denominator: uint16
    royalty_destination: address?
    sale_ended: bool
    price: coins
}

type NftSaleIncomingMessage =
    | NftSaleTakeWalletAddress
    | NftSaleNftOwnershipAssigned
    | NftSaleTransferNotification
    | NftSaleDeploy

enum NftSaleErrors {
    /// Stack undeflow
    StackUndeflow = 2
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
    /// Out of gas error
    OutOfGasError = 13
    /// Method ID not found
    MethodIDNotFound = 32
    /// Action is invalid or not supported
    ActionIsInvalidOrNotSupported = 34
    /// Not enough TON
    NotEnoughTON = 37
    /// Not enough extra-currencies
    NotEnoughExtraCurrencies = 38
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
}

get fun get_price_info(): NftSalePriceInfo {
    throw 0;
}

get fun get_sale_info(): NftSaleSaleInfo {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
