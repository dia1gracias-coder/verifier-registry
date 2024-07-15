// Generated from the verified Tact contract ABI.
contract HeroCoin {
    storage: HeroCoinData
    incomingMessages: HeroCoinIncomingMessage
    thrownErrors: HeroCoinErrors
}

struct (0x946a98b6) HeroCoinDeploy {
    queryId: uint64
}

struct (0x819dbe99) HeroCoinChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x62b62b41) HeroCoinUpdateContent {
    query_id: uint64
    content: cell
}

struct (0xa0b093f9) HeroCoinMint {
    query_id: uint64
    amount: coins
    to: address
    response_destination: address
}

struct (0x7bdd97de) HeroCoinBurnNotification {
    query_id: uint64
    amount: coins
    owner: address
    response_destination: address?
}

struct (0x14836e42) HeroCoinVest {
    query_id: uint64
    amount: coins
    to: address
    start: uint32
    duration: uint32
    force: bool?
}

struct HeroCoinJettonData {
    totalSupply: int257
    mintable: bool
    owner: address
    content: cell
    walletCode: cell
}

struct HeroCoinData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    content: cell
    mintable: bool
    totalSupply: coins
    cap: coins
}

type HeroCoinIncomingMessage =
    | HeroCoinUpdateContent
    | HeroCoinMint
    | HeroCoinVest
    | HeroCoinBurnNotification
    | HeroCoinDeploy
    | HeroCoinChangeOwner

enum HeroCoinErrors {
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
    /// Transfer: Insufficient value
    TransferInsufficientValue = 10682
    /// Internal Vest: Zero duration
    InternalVestZeroDuration = 12076
    /// Vest: Forbidden
    VestForbidden = 22973
    /// Mint: Forbidden
    MintForbidden = 26463
    /// Release: Too high released amount
    ReleaseTooHighReleasedAmount = 27269
    /// Internal Vest: Zero start
    InternalVestZeroStart = 47721
    /// Burn: Insufficient balance
    BurnInsufficientBalance = 49434
    /// Mint: Cap reached
    MintCapReached = 56122
    /// Release: Too high message amount
    ReleaseTooHighMessageAmount = 58904
    /// Transfer: Insufficient balance
    TransferInsufficientBalance = 61054
    /// Internal Transfer: Insufficient balance
    InternalTransferInsufficientBalance = 61583
    /// Burn: Insufficient value
    BurnInsufficientValue = 62650
    /// Vest: Cap reached
    VestCapReached = 62987
}

get fun get_jetton_data(): HeroCoinJettonData {
    throw 0;
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}

get fun get_vesting_address(owner: address): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
