// Generated from the verified Tact contract ABI.
contract GDTapBooster {
    storage: GDTapBoosterData
    incomingMessages: GDTapBoosterIncomingMessage
    thrownErrors: GDTapBoosterErrors
}

struct (0x946a98b6) GDTapBoosterDeploy {
    queryId: uint64
}

struct (0xdd32ae06) GDTapBoosterBoost {
    queryId: uint64
    tierId: uint16
}

struct (0x2c45fef9) GDTapBoosterSetTierPrice {
    queryId: uint64
    tierId: uint16
    price: uint64
}

struct (0x8f5379b8) GDTapBoosterSetBeneficiary {
    queryId: uint64
    beneficiary: address
}

struct GDTapBoosterPurchase {
    tierId: uint16
    player: address
    timestamp: uint32
}

struct GDTapBoosterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    balance_to_keep: int257
    next_item_index: uint32
    purchases: map<uint64, Cell<GDTapBoosterPurchase>>
    latestPurchase: map<address, uint64>
    tactContinuation: Cell<GDTapBoosterDataContinuation>
}

struct GDTapBoosterDataContinuation {
    tierPrices: map<uint32, uint64>
    owner: address
    beneficiary: address
}

type GDTapBoosterIncomingMessage =
    | GDTapBoosterBoost
    | GDTapBoosterSetTierPrice
    | GDTapBoosterSetBeneficiary
    | GDTapBoosterDeploy

enum GDTapBoosterErrors {
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
    /// Hecker protection
    HeckerProtection = 5505
    /// Unauthorized: Only owner can set beneficiary
    UnauthorizedOnlyOwnerCanSetBeneficiary = 11304
    /// Not enough monies
    NotEnoughMonies = 14909
}

get fun tier_price(tierId: int257): int257 {
    throw 0;
}

get fun purchase(purchaseId: int257): GDTapBoosterPurchase? {
    throw 0;
}

get fun next_purchase_id(): int257 {
    throw 0;
}

get fun beneficiary(): address {
    throw 0;
}

get fun latestPurchase(player: address): int257 {
    throw 0;
}
