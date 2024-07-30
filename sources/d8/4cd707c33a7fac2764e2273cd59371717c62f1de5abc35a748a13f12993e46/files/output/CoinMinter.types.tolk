// Generated from the verified Tact contract ABI.
contract CoinMinter {
    storage: CoinMinterData
    incomingMessages: CoinMinterIncomingMessage
    thrownErrors: CoinMinterErrors
}

struct (0x946a98b6) CoinMinterDeploy {
    queryId: uint64
}

struct CoinMinterJettonData {
    totalSupply: int257
    mintable: bool
    owner: address
    content: cell
    walletCode: cell
}

struct (0x7bdd97de) CoinMinterTokenBurnNotification {
    queryId: uint64
    amount: coins
    owner: address
    response_destination: address?
}

struct (0xaf1ca26a) CoinMinterTokenUpdateContent {
    content: cell
}

struct (0x2c76b973) CoinMinterProvideWalletAddress {
    query_id: uint64
    owner_address: address
    include_address: bool
}

struct (0xfc708bd2) CoinMinterMint {
    amount: int257
    receiver: address
}

struct CoinMinterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    totalSupply: coins
    owner: address
    mintable: bool
    content: cell
}

type CoinMinterIncomingMessage =
    | CoinMinterMint
    | CoinMinterDeploy
    | CoinMinterTokenUpdateContent
    | CoinMinterTokenBurnNotification
    | CoinMinterProvideWalletAddress

enum CoinMinterErrors {
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
    /// Invalid sender
    InvalidSender = 4429
    /// Insufficient gas
    InsufficientGas = 23951
    /// sender is not owner
    SenderIsNotOwner = 29375
    /// insufficient funds
    InsufficientFunds = 30251
    /// invalid balance
    InvalidBalance = 43887
    /// not owner
    NotOwner = 49280
    /// invalid fee
    InvalidFee = 59876
    /// minting is disabled
    MintingIsDisabled = 61930
}

get fun get_jetton_data(): CoinMinterJettonData {
    throw 0;
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
