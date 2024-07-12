// Generated from the verified Tact contract ABI.
contract Curve {
    storage: CurveData
    incomingMessages: CurveIncomingMessage
    thrownErrors: CurveErrors
}

struct (0xd1a972eb) CurveInit {
    jetton_wallet_address: address
    jetton_balance: coins
    initial_buy: coins
    creator_address: address
}

struct (0x1ff7752e) CurveBuy {
    ton_amount: coins
}

struct (0xd442ade2) CurveSell {
    jetton_amount: coins
    to: address
}

struct CurveInformation {
    jetton_balance: coins
    jetton_wallet_address: address
}

struct CurveData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    router_address: address
    jetton_wallet_address: address
    jetton_balance: coins
}

type CurveIncomingMessage =
    | CurveBuy
    | CurveSell
    | CurveInit

enum CurveErrors {
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
    /// JettonWallet: Only Jetton master or Jetton wallet can call this function
    JettonWalletOnlyJettonMasterOrJettonWalletCanCallThisFunction = 2296
    /// Already initialized
    AlreadyInitialized = 2977
    /// Invalid sender
    InvalidSender = 4429
    /// JettonWallet: Not enough jettons to transfer
    JettonWalletNotEnoughJettonsToTransfer = 13105
    /// Not Router
    NotRouter = 13636
    /// Only owner can call this function
    OnlyOwnerCanCallThisFunction = 27831
    /// JettonWallet: Not allow negative balance after internal transfer
    JettonWalletNotAllowNegativeBalanceAfterInternalTransfer = 29133
    /// Not enough funds to transfer
    NotEnoughFundsToTransfer = 37185
    /// JettonWallet: Only owner can burn tokens
    JettonWalletOnlyOwnerCanBurnTokens = 47048
    /// Invalid query id
    InvalidQueryId = 47578
    /// Token factory not set
    TokenFactoryNotSet = 50725
    /// JettonWallet: Not enough balance to burn tokens
    JettonWalletNotEnoughBalanceToBurnTokens = 60354
    /// No tokens to sell
    NoTokensToSell = 60757
}

get fun token_balance(): CurveInformation {
    throw 0;
}
