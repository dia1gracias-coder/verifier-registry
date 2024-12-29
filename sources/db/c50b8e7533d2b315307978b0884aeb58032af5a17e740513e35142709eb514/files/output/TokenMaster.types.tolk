// Generated from the verified Tact contract ABI.
contract TokenMaster {
    storage: TokenMasterData
    incomingMessages: TokenMasterIncomingMessage
    thrownErrors: TokenMasterErrors
}

struct (0x946a98b6) TokenMasterDeploy {
    queryId: uint64
}

struct (0x10590ef2) TokenMasterChangeContent {
    jetton_content: cell
}

struct (0xe4dca6e3) TokenMasterChangeMinter {
    minter: address
}

struct (0x89a35a1f) TokenMasterMint {
}

struct TokenMasterMasterData {
    total_supply: int257
    mintable: bool
    owner: address
    jetton_content: cell
    jetton_wallet_code: cell
}

struct TokenMasterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    total_supply: coins
    mintable: bool
    owner: address
    minter: address
    jetton_content: cell
    is_initial_supply: bool
    supply_amount: int257
    tactContinuation: Cell<TokenMasterDataContinuation>
}

struct TokenMasterDataContinuation {
    mint_amount: int257
    day: int257
    last_claim_day: int257
}

type TokenMasterIncomingMessage =
    | TokenMasterChangeContent
    | TokenMasterChangeMinter
    | TokenMasterMint
    | TokenMasterDeploy

enum TokenMasterErrors {
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
    /// Invalid sender
    InvalidSender = 4429
    /// Claimed today
    ClaimedToday = 6854
    /// Invalid minter
    InvalidMinter = 10127
    /// Only admin
    OnlyAdmin = 16461
    /// Blocked
    Blocked = 46004
    /// Mint stopped
    MintStopped = 49345
    /// Invalid ton amount
    InvalidTonAmount = 51724
    /// Invalid token amount
    InvalidTokenAmount = 54227
    /// Initial Supply has been minted
    InitialSupplyHasBeenMinted = 63331
}

get fun get_jetton_data(): TokenMasterMasterData {
    throw 0;
}

get fun get_wallet_address(owner_address: address): address {
    throw 0;
}

get fun get_minter_address(): address {
    throw 0;
}

get fun get_owner_address(): address {
    throw 0;
}

get fun get_last_claim_day(): int257 {
    throw 0;
}

get fun get_today(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
