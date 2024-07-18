// Generated from the verified Tact contract ABI.
contract UXUYJetton {
    storage: UXUYJettonData
    incomingMessages: UXUYJettonIncomingMessage
    thrownErrors: UXUYJettonErrors
}

struct UXUYJettonJettonData {
    total_supply: int257
    mintable: bool
    owner: address
    content: cell
    wallet_code: cell
}

struct (0x7bdd97de) UXUYJettonTokenBurnNotification {
    query_id: uint64
    amount: coins
    sender: address
    response_destination: address?
}

struct (0xaf1ca26a) UXUYJettonTokenUpdateContent {
    content: cell
}

struct (0x2c76b973) UXUYJettonProvideWalletAddress {
    query_id: uint64
    owner_address: address
    include_address: bool
}

struct (0x35f24ceb) UXUYJettonCheckAndTransfer {
    query_id: uint64
    amount: coins
    from: address
    to: address
    response_destination: address?
    tactContinuation: Cell<UXUYJettonCheckAndTransferContinuation>
}

struct UXUYJettonCheckAndTransferContinuation {
    forward_ton_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct (0x1442ed9e) UXUYJettonSafeTransfer {
    query_id: uint64
    amount: int257
    receiver: address
}

struct (0xfc708bd2) UXUYJettonMint {
    amount: int257
    receiver: address
}

struct (0x4f6d30cc) UXUYJettonReward {
    amount: int257
    receiver: address
    transId: string?
    date: int257?
}

struct (0xd510ced8) UXUYJettonAddToBlacklist {
    address: address
}

struct (0xec835a1d) UXUYJettonRemoveFromBlacklist {
    address: address
}

struct (0x9703843b) UXUYJettonAuthorizeOperator {
    address: address
}

struct (0x4c84e793) UXUYJettonRevokeOperator {
    address: address
}

struct (0xa361cd23) UXUYJettonAddToWhitelist {
    address: address
}

struct (0x321c485d) UXUYJettonRemoveFromWhitelist {
    address: address
}

struct (0x4726502f) UXUYJettonSetUsingWhitelistStatus {
    status: bool
}

struct (0xafaa584e) UXUYJettonAddSafeTransferAddress {
    address: address
}

struct (0xa92ca481) UXUYJettonRemoveSafeTransferAddress {
    address: address
}

struct UXUYJettonData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    total_supply: coins
    owner: address
    content: cell
    mintable: bool
    max_supply: coins
    _blacklist: map<address, bool>
    tactContinuation: Cell<UXUYJettonDataContinuation>
}

struct UXUYJettonDataContinuation {
    _whitelist: map<address, bool>
    isUsingWhitelist: bool
    superOperators: map<address, bool>
    safeTransferAddressList: map<address, bool>
    _paused: bool
}

type UXUYJettonIncomingMessage =
    | UXUYJettonMint
    | UXUYJettonReward
    | UXUYJettonSafeTransfer
    | UXUYJettonAddToBlacklist
    | UXUYJettonRemoveFromBlacklist
    | UXUYJettonAuthorizeOperator
    | UXUYJettonRevokeOperator
    | UXUYJettonAddToWhitelist
    | UXUYJettonRemoveFromWhitelist
    | UXUYJettonSetUsingWhitelistStatus
    | UXUYJettonAddSafeTransferAddress
    | UXUYJettonRemoveSafeTransferAddress
    | UXUYJettonTokenUpdateContent
    | UXUYJettonTokenBurnNotification
    | UXUYJettonCheckAndTransfer
    | UXUYJettonProvideWalletAddress

enum UXUYJettonErrors {
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
    /// Not mintable
    NotMintable = 3688
    /// Invalid sender
    InvalidSender = 4429
    /// amount Cannot be the zero
    AmountCannotBeTheZero = 6809
    /// Pausable: paused
    PausablePaused = 9176
    /// Receiving address is blacklisted
    ReceivingAddressIsBlacklisted = 10660
    /// Not super operator
    NotSuperOperator = 11521
    /// Max supply exceeded
    MaxSupplyExceeded = 12241
    /// Not owner
    NotOwner = 14534
    /// Invalid value
    InvalidValue = 16059
    /// Can't Mint Anymore
    CanTMintAnymore = 18668
    /// Pausable: not paused
    PausableNotPaused = 19615
    /// Insufficient gas
    InsufficientGas = 23951
    /// Sending Or Receiving address is not on the whitelist
    SendingOrReceivingAddressIsNotOnTheWhitelist = 30921
    /// Sending address is blacklisted.
    SendingAddressIsBlacklisted = 31453
    /// User is already in the whitelist.
    UserIsAlreadyInTheWhitelist = 39932
    /// Invalid sender!
    InvalidSender2 = 42708
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// User is already on the blacklist.
    UserIsAlreadyOnTheBlacklist = 47725
    /// User is not on the SafeTransferList.
    UserIsNotOnTheSafeTransferList = 48024
    /// User is not on the whitelist.
    UserIsNotOnTheWhitelist = 48120
    /// User is already in the SafeTransferList.
    UserIsAlreadyInTheSafeTransferList = 50597
    /// User is not on the blacklist.
    UserIsNotOnTheBlacklist = 54945
    /// Sender not in SafeTransferList
    SenderNotInSafeTransferList = 57182
    /// Invalid balance
    InvalidBalance = 62972
}

get fun getSafeListStatus(address: address): bool {
    throw 0;
}

get fun get_jetton_data(): UXUYJettonJettonData {
    throw 0;
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}

get fun getBlackListStatus(_maker: address): bool {
    throw 0;
}

get fun getWhiteListStatus(_maker: address): bool {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
