// Generated from the verified Tact contract ABI.
contract StableMaster {
    storage: StableMasterData
    incomingMessages: StableMasterIncomingMessage
    thrownErrors: StableMasterErrors
}

struct (0x946a98b6) StableMasterDeploy {
    queryId: uint64
}

struct (0xfc708bd2) StableMasterMint {
    amount: int257
    receiver: address
}

struct (0x7bdd97de) StableMasterTokenBurnNotification {
    queryId: uint64
    amount: coins
    owner: address
    response_destination: address?
}

struct (0x595f07bc) StableMasterTokenBurn {
    queryId: uint64
    amount: coins
    owner: address
    response_destination: address
}

struct (0xc81d8f08) StableMasterUpdateStatus {
    queryId: uint64
    owner: address
    status: int257
}

struct StableMasterRoleData {
    hasRole: map<address, bool>
}

struct (0x686e13b6) StableMasterGrantRole {
    role: int257
    account: address
}

struct (0x15a2e9a7) StableMasterRevokeRole {
    role: int257
    account: address
}

struct StableMasterMasterData {
    total_supply: int257
    mintable: bool
    owner: address
    jetton_content: cell
    jetton_wallet_code: cell
}

struct StableMasterContractRoles {
    default_role: int257
    minter_role: int257
    admin_role: int257
}

struct StableMasterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    totalSupply: coins
    mintable: bool
    burnable: bool
    owner: address
    jetton_content: cell
    roles: map<int257, Cell<StableMasterRoleData>>
    seqno: int257
}

type StableMasterIncomingMessage =
    | StableMasterUpdateStatus
    | StableMasterMint
    | StableMasterTokenBurn
    | StableMasterTokenBurnNotification
    | StableMasterDeploy
    | StableMasterGrantRole
    | StableMasterRevokeRole

enum StableMasterErrors {
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
    /// Invalid value!!
    InvalidValue = 4159
    /// Invalid sender
    InvalidSender = 4429
    /// Minting is not allowed
    MintingIsNotAllowed = 6167
    /// Only master
    OnlyMaster = 16588
    /// Invalid sender!
    InvalidSender2 = 42708
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// Wallet is locked
    WalletIsLocked = 45525
    /// Access denied
    AccessDenied2 = 49469
    /// Burning is not allowed
    BurningIsNotAllowed = 60460
    /// Invalid balance
    InvalidBalance = 62972
}

get fun getContractRoles(): StableMasterContractRoles {
    throw 0;
}

get fun get_jetton_data(): StableMasterMasterData {
    throw 0;
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}

get fun defaultRole(): int257 {
    throw 0;
}

get fun getRole(role: int257, account: address): bool {
    throw 0;
}
