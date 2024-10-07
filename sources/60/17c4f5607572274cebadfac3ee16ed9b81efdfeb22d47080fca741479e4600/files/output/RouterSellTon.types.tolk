// Generated from the verified Tact contract ABI.
contract RouterSellTon {
    storage: RouterSellTonData
    incomingMessages: RouterSellTonIncomingMessage
    thrownErrors: RouterSellTonErrors
}

struct (0xe8ec4df1) RouterSellTonRequest {
    order_jetton_buy_wallet: address
    jetton_buy_master: address
    amount_sell: coins
    amount_buy: coins
    expiration_time: uint64
}

struct (0x1d0e4622) RouterSellTonNewOwner {
    new_owner: address
}

struct (0x98a2322f) RouterSellTonNewFee {
    new_fee: int257
}

struct (0xa2079904) RouterSellTonStart {
}

struct (0xfbf571c2) RouterSellTonStop {
}

struct (0x2365d020) RouterSellTonWithdraw {
}

struct (0xe31831ef) RouterSellTonTonTransferNotification {
    request: RouterSellTonRequest
    tactContinuation: Cell<RouterSellTonTonTransferNotificationContinuation>
}

struct RouterSellTonTonTransferNotificationContinuation {
    seller: address
    nonce: int257
}

struct RouterSellTonData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    fee: int257
    status: bool
}

type RouterSellTonIncomingMessage =
    | RouterSellTonTonTransferNotification
    | RouterSellTonNewOwner
    | RouterSellTonNewFee
    | RouterSellTonStart
    | RouterSellTonStop
    | RouterSellTonWithdraw

enum RouterSellTonErrors {
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
