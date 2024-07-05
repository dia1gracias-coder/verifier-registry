// Generated from the verified Tact contract ABI.
contract Marketplace {
    storage: MarketplaceData
    incomingMessages: MarketplaceIncomingMessage
    thrownErrors: MarketplaceErrors
}

struct (0x946a98b6) MarketplaceDeploy {
    queryId: uint64
}

struct (0x819dbe99) MarketplaceChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x05138d91) MarketplaceOwnershipAssigned {
    query_id: uint64
    prev_owner: address
    forward_payload: RemainingBitsAndRefs
}

struct (0x99eb6681) MarketplaceAddExchangeJetton {
    jetton_address: address
}

struct (0xe890579c) MarketplaceRemoveExchangeJetton {
    jetton_address: address
}

struct MarketplaceData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
}

type MarketplaceIncomingMessage =
    | MarketplaceOwnershipAssigned
    | MarketplaceAddExchangeJetton
    | MarketplaceRemoveExchangeJetton
    | MarketplaceChangeOwner
    | MarketplaceDeploy

enum MarketplaceErrors {
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

get fun owner(): address {
    throw 0;
}
