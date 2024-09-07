// Generated from the verified Tact contract ABI.
contract RubberDuckJetton {
    storage: RubberDuckJettonData
    incomingMessages: RubberDuckJettonIncomingMessage
    thrownErrors: RubberDuckJettonErrors
}

struct (0x819dbe99) RubberDuckJettonChangeOwner {
    queryId: uint64
    newOwner: address
}

struct RubberDuckJettonJettonData {
    total_supply: int257
    mintable: bool
    owner: address
    content: cell
    wallet_code: cell
}

struct (0x7bdd97de) RubberDuckJettonTokenBurnNotification {
    query_id: uint64
    amount: coins
    sender: address
    response_destination: address?
}

struct (0xaf1ca26a) RubberDuckJettonTokenUpdateContent {
    content: cell
}

struct (0x2c76b973) RubberDuckJettonProvideWalletAddress {
    query_id: uint64
    owner_address: address
    include_address: bool
}

struct (0xfc708bd2) RubberDuckJettonMint {
    amount: int257
    receiver: address
}

struct (0xa84b2cea) RubberDuckJettonSetRewardParameters {
    release_burn_threshold: coins
    squeeze_reward_floor: coins
    squeeze_reward_cap: coins
    cool_down: uint32
}

struct (0xf6670c4c) RubberDuckJettonGetDuckContent {
    release_burn_threshold: coins
    squeeze_reward_floor: coins
    squeeze_reward_cap: coins
    cool_down: uint32
    ocean_ducks: coins
}

struct (0x841d9d20) RubberDuckJettonReleaseDucksIntoOceanNotification {
    query_id: uint64
    amount: coins
    response_destination: address
}

struct (0xa419f91b) RubberDuckJettonSqueezeDuck {
    query_id: uint64
    response_destination: address?
}

struct RubberDuckJettonData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    total_supply: coins
    owner: address
    content: cell
    mintable: bool
    max_supply: coins
    ocean_ducks: coins
    cool_down: uint32
    squeeze_reward_cap: coins
    squeeze_reward_floor: coins
    tactContinuation: Cell<RubberDuckJettonDataContinuation>
}

struct RubberDuckJettonDataContinuation {
    release_burn_threshold: coins
}

type RubberDuckJettonIncomingMessage =
    | RubberDuckJettonMint
    | RubberDuckJettonSetRewardParameters
    | RubberDuckJettonSqueezeDuck
    | RubberDuckJettonReleaseDucksIntoOceanNotification
    | RubberDuckJettonTokenUpdateContent
    | RubberDuckJettonTokenBurnNotification
    | RubberDuckJettonProvideWalletAddress
    | RubberDuckJettonChangeOwner

enum RubberDuckJettonErrors {
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
    /// Invalid ocean ducks - ReleaseDucksIntoOcean
    InvalidOceanDucksReleaseDucksIntoOcean = 36795
    /// Invalid sender!
    InvalidSender2 = 42708
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// Not enough rubber ducks in the ocean - SqueezeDuck
    NotEnoughRubberDucksInTheOceanSqueezeDuck = 49309
    /// Invaild ocean ducks - SqueezeDuck
    InvaildOceanDucksSqueezeDuck = 52668
    /// On cooldown - SqueezeDuck
    OnCooldownSqueezeDuck = 62281
    /// Invalid balance
    InvalidBalance = 62972
}

get fun get_jetton_data(): RubberDuckJettonJettonData {
    throw 0;
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}

get fun get_duck_content(): RubberDuckJettonGetDuckContent {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
