// Generated from the verified Tact contract ABI.
contract NftSale {
    storage: NftSaleData
    incomingMessages: NftSaleIncomingMessage
    thrownErrors: NftSaleErrors
}

struct (0x946a98b6) NftSaleDeploy {
    queryId: uint64
}

struct NftSaleNFTData {
    isComplete: bool
    startAt: uint32
    finishAt: uint32
    marketAddress: address
    nftAddress: address
    nftOwnerAddress: address
    fullPrice: coins
    tactContinuation: Cell<NftSaleNFTDataContinuation>
}

struct NftSaleNFTDataContinuation {
    jettonAddress: address
}

struct (0xfb082d6b) NftSaleBuyWithTon {
    query_id: uint64
}

struct (0x5759fadc) NftSaleBuyWithAnotherJetton {
    query_id: uint64
    buyer_address: address
    purchase_price: coins
}

struct (0x0b289c26) NftSaleCancelSaleNft {
}

struct NftSaleData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    isComplete: bool
    startAt: uint32
    finishAt: uint32
    marketAddress: address
    nftAddress: address
    nftOwnerAddress: address
    fullPrice: coins
    tactContinuation: Cell<NftSaleDataContinuation>
}

struct NftSaleDataContinuation {
    jettonAddress: address
}

type NftSaleIncomingMessage =
    | NftSaleBuyWithTon
    | NftSaleBuyWithAnotherJetton
    | NftSaleCancelSaleNft
    | NftSaleDeploy

enum NftSaleErrors {
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
    /// Invalid sub-op
    InvalidSubOp = 30974
    /// This jetton is not added to market exchange tokens
    ThisJettonIsNotAddedToMarketExchangeTokens = 31051
    /// Not enough funds to buy NFT
    NotEnoughFundsToBuyNFT = 61757
}

get fun get_sale_data(): NftSaleNFTData {
    throw 0;
}
