// Generated from the verified Tact contract ABI.
contract RubberDuck {
    storage: RubberDuckData
    incomingMessages: RubberDuckIncomingMessage
    thrownErrors: RubberDuckErrors
}

struct (0x819dbe99) RubberDuckChangeOwner {
    queryId: uint64
    newOwner: address
}

struct RubberDuckJettonData {
    total_supply: int257
    mintable: bool
    owner: address
    ocean: int257
    tactContinuation: Cell<RubberDuckJettonDataContinuation>
}

struct RubberDuckJettonDataContinuation {
    squeeze_reward_cap: int257
    cool_down: int257
    content: cell
    wallet_code: cell
}

struct (0x7bdd97de) RubberDuckTokenBurnNotification {
    query_id: uint64
    amount: coins
    sender: address
    response_destination: address?
}

struct (0xaf1ca26a) RubberDuckTokenUpdateContent {
    content: cell
}

struct (0x2c76b973) RubberDuckProvideWalletAddress {
    query_id: uint64
    owner_address: address
    include_address: bool
}

struct (0x4e0be1b7) RubberDuckSetRewardParameters {
    squeeze_reward_floor: int257
    squeeze_reward_cap: int257
    cool_down: uint32
}

struct (0xfc708bd2) RubberDuckMint {
    amount: int257
    receiver: address
}

struct (0x97135d49) RubberDuckDumpIntoOceanNotification {
    query_id: uint64
    amount: coins
    response_destination: address?
}

struct (0xa419f91b) RubberDuckSqueezeDuck {
    query_id: uint64
    response_destination: address?
}

struct RubberDuckData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    total_supply: coins
    owner: address
    content: cell
    mintable: bool
    ocean: int257
    squeeze_reward_floor: int257
    tactContinuation: Cell<RubberDuckDataContinuation>
}

struct RubberDuckDataContinuation {
    squeeze_reward_cap: int257
    cool_down: uint32
}

type RubberDuckIncomingMessage =
    | RubberDuckMint
    | RubberDuckSetRewardParameters
    | RubberDuckSqueezeDuck
    | RubberDuckTokenUpdateContent
    | RubberDuckTokenBurnNotification
    | RubberDuckProvideWalletAddress
    | RubberDuckDumpIntoOceanNotification
    | RubberDuckChangeOwner

enum RubberDuckErrors {
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
    /// Not enough rubber ducks in the ocean - Squeeze
    NotEnoughRubberDucksInTheOceanSqueeze = 1657
    /// Not mintable
    NotMintable = 3688
    /// Invalid sender
    InvalidSender = 4429
    /// Not owner
    NotOwner = 14534
    /// Invalid value
    InvalidValue = 16059
    /// Can't Mint Anymore
    CanTMintAnymore = 18668
    /// Insufficient gas
    InsufficientGas = 23951
    /// On cooldown - Squeeze
    OnCooldownSqueeze = 24382
    /// Invalid sender!
    InvalidSender2 = 42708
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// Invaild ocean ducks - Squeeze
    InvaildOceanDucksSqueeze = 62087
    /// Invalid balance
    InvalidBalance = 62972
    /// Invalid ocean ducks - Dump
    InvalidOceanDucksDump = 63429
}

get fun get_jetton_data(): RubberDuckJettonData {
    throw 0;
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
