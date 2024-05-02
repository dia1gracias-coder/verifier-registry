// Generated from the verified Tact contract ABI.
contract Escrow {
    storage: EscrowData
    incomingMessages: EscrowIncomingMessage
    thrownErrors: EscrowErrors
}

struct (0x946a98b6) EscrowDeploy {
    queryId: uint64
}

struct (0x819dbe99) EscrowChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x7362d09c) EscrowTokenNotification {
    queryId: uint64
    amount: coins
    from: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0x5d7a8d75) EscrowSetOperator {
    operator_: address
}

struct (0x621c3de9) EscrowUpdatePledgeRate {
    pledgeRate: uint64
}

struct (0x9dcfa1bf) EscrowPayTo {
    offerId: uint64?
    queryId: uint64
    fromWallet: address
    amount: coins
    destination: address
    tactContinuation: Cell<EscrowPayToContinuation>
}

struct EscrowPayToContinuation {
    responseDestination: address?
}

struct (0x21381fb0) EscrowCallSettleOffer {
    queryId: uint64
    offerId: uint64
}

struct (0xb9643f85) EscrowCallConfirmOffer {
    queryId: uint64
    offerId: uint64
}

struct EscrowData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    operator_: address
    pledgeRate: uint64
    lastOfferId: uint256
}

type EscrowIncomingMessage =
    | EscrowSetOperator
    | EscrowUpdatePledgeRate
    | EscrowPayTo
    | EscrowTokenNotification
    | EscrowCallSettleOffer
    | EscrowCallConfirmOffer
    | EscrowDeploy
    | EscrowChangeOwner

enum EscrowErrors {
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
    /// Invalid amount
    InvalidAmount = 17062
    /// Invalid pledgeRate
    InvalidPledgeRate = 22964
    /// Only accept call from operator
    OnlyAcceptCallFromOperator = 25999
    /// Invalid offerId
    InvalidOfferId = 33232
    /// Invalid caller
    InvalidCaller = 43129
    /// Invalid offer status
    InvalidOfferStatus = 44732
    /// Only escrow contract
    OnlyEscrowContract = 51144
    /// Insufficient fee
    InsufficientFee = 55259
    /// Only offer contract
    OnlyOfferContract = 60185
}

get fun get_offer_address(offerId: int257): address {
    throw 0;
}

get fun get_last_offer_id(): int257 {
    throw 0;
}

get fun get_pledge_rate(): int257 {
    throw 0;
}

get fun get_operator(): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
