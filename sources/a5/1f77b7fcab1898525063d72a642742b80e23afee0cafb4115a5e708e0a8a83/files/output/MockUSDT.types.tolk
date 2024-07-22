// Generated from the verified Tact contract ABI.
contract MockUSDT {
    storage: MockUSDTData
    incomingMessages: MockUSDTIncomingMessage
    thrownErrors: MockUSDTErrors
}

struct (0x946a98b6) MockUSDTDeploy {
    queryId: uint64
}

struct MockUSDTJettonData {
    total_supply: int257
    mintable: bool
    owner: address
    content: cell
    wallet_code: cell
}

struct (0x7bdd97de) MockUSDTTokenBurnNotification {
    query_id: uint64
    amount: coins
    sender: address
    response_destination: address?
}

struct (0xaf1ca26a) MockUSDTTokenUpdateContent {
    content: cell
}

struct (0x2c76b973) MockUSDTProvideWalletAddress {
    query_id: uint64
    owner_address: address
    include_address: bool
}

struct (0xfc708bd2) MockUSDTMint {
    amount: int257
    receiver: address
}

struct MockUSDTData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    total_supply: coins
    owner: address
    content: cell
    mintable: bool
    max_supply: coins
}

type MockUSDTIncomingMessage =
    | MockUSDTMint
    | MockUSDTDeploy
    | MockUSDTTokenUpdateContent
    | MockUSDTTokenBurnNotification
    | MockUSDTProvideWalletAddress

enum MockUSDTErrors {
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
    /// Max supply exceeded
    MaxSupplyExceeded = 12241
    /// Not owner
    NotOwner = 14534
    /// Invalid value
    InvalidValue = 16059
    /// Can't Mint Anymore
    CanTMintAnymore = 18668
    /// Insufficient gas
    InsufficientGas = 23951
    /// Invalid sender!
    InvalidSender2 = 42708
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// Invalid balance
    InvalidBalance = 62972
}

get fun get_jetton_data(): MockUSDTJettonData {
    throw 0;
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
