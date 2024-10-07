// Generated from the verified Tact contract ABI.
contract RouterBuyTon {
    storage: RouterBuyTonData
    incomingMessages: RouterBuyTonIncomingMessage
    thrownErrors: RouterBuyTonErrors
}

struct (0x1d0e4622) RouterBuyTonNewOwner {
    new_owner: address
}

struct (0x98a2322f) RouterBuyTonNewFee {
    new_fee: int257
}

struct (0xa2079904) RouterBuyTonStart {
}

struct (0xfbf571c2) RouterBuyTonStop {
}

struct (0x2365d020) RouterBuyTonWithdraw {
}

struct (0x7362d09c) RouterBuyTonJettonTransferNotification {
    query_id: uint64
    amount: coins
    sender: address
    forward_payload: RemainingBitsAndRefs
}

struct RouterBuyTonData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    fee: int257
    status: bool
}

type RouterBuyTonIncomingMessage =
    | RouterBuyTonJettonTransferNotification
    | RouterBuyTonNewOwner
    | RouterBuyTonNewFee
    | RouterBuyTonStart
    | RouterBuyTonStop
    | RouterBuyTonWithdraw

enum RouterBuyTonErrors {
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
}

get fun calculate_order(seller: address, nonce: int257): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun fee(): int257 {
    throw 0;
}

get fun status(): bool {
    throw 0;
}
