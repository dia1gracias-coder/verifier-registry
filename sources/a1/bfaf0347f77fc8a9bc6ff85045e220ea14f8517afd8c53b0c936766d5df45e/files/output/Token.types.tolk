// Generated from the verified Tact contract ABI.
contract Token {
    storage: TokenData
    incomingMessages: TokenIncomingMessage
    thrownErrors: TokenErrors
}

struct (0xc9c38a04) Token_New {
    query_id: int257
    initial_sender: address
    amountIn: coins
    amountOut: int257
}

struct (0xf65b9d33) TokenCurve_Buy {
    query_id: int257
    amountIn: coins
    amountOut: int257
    slippage: int257
}

struct (0x2942cb6e) TokenCurve_Sell {
    query_id: int257
    amountIn: int257
    amountOut: coins
    slippage: int257
}

struct (0xf30a392b) TokenTOKEN_EXIT_START {
    token: address
    min_lp_out: coins
}

struct TokenJettonData {
    total_supply: int257
    mintable: bool
    owner: address
    content: cell
    wallet_code: cell
}

struct (0x7bdd97de) TokenBurnNotification {
    query_id: uint64
    amount: coins
    sender: address
    response_destination: address?
}

struct (0xaf1ca26a) TokenUpdateContent {
    content: cell
}

struct (0x2c76b973) TokenProvideWalletAddress {
    query_id: uint64
    owner_address: address
    include_address: bool
}

struct TokenData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    seqno: uint64
    total_supply: coins
    owner: address
    creator: address
    bonding_curve: bool
    content: cell
    max_supply: int257
    tactContinuation: Cell<TokenDataContinuation>
}

struct TokenDataContinuation {
    circulating_supply: int257
}

type TokenIncomingMessage =
    | Token_New
    | TokenCurve_Buy
    | TokenCurve_Sell
    | TokenTOKEN_EXIT_START
    | TokenUpdateContent
    | TokenBurnNotification
    | TokenProvideWalletAddress

enum TokenErrors {
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
    /// SLIPPAGE_EXCEEDED
    SLIPPAGEEXCEEDED = 1984
    /// CURVE_BONDING_DISABLED
    CURVEBONDINGDISABLED = 2833
    /// Invalid sender
    InvalidSender = 4429
    /// TOKEN_ALREADY_MINTED
    TOKENALREADYMINTED = 9312
    /// TOKEN_NOT_OWNER
    TOKENNOTOWNER = 10111
    /// CURVE_MAX_SUPPLY_REACHED
    CURVEMAXSUPPLYREACHED = 11174
    /// SENDER_NOT_MINTER
    SENDERNOTMINTER = 13911
    /// AMOUNT_IN_0
    AMOUNTIN0 = 14584
    /// Invalid value
    InvalidValue = 16059
    /// CURVE_NOT_EMPTY
    CURVENOTEMPTY = 17288
    /// USER_OUTPUT_BEYOND_SLIPPAGE
    USEROUTPUTBEYONDSLIPPAGE = 19804
    /// Insufficient gas
    InsufficientGas = 23951
    /// INSUFFICIENT_FUNDS
    INSUFFICIENTFUNDS = 27056
    /// CURVE_OUT_OF_FUNDS
    CURVEOUTOFFUNDS = 27267
    /// CURVE_SUPPLY_NEGATIVE
    CURVESUPPLYNEGATIVE = 30190
    /// MINTING_INSUFFICIENT_TONS
    MINTINGINSUFFICIENTTONS = 36398
    /// ONLY_OWNER
    ONLYOWNER = 37469
    /// INVALID_INPUT
    INVALIDINPUT = 39404
    /// CALLER_NOT_CREATOR
    CALLERNOTCREATOR = 40801
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// SENDER_NOT_WALLET_OWNER
    SENDERNOTWALLETOWNER = 44652
    /// USER_OUTPUT_UNDER_SLIPPAGE
    USEROUTPUTUNDERSLIPPAGE = 48330
    /// Token does not exist!
    TokenDoesNotExist = 48389
    /// Invalid balance
    InvalidBalance = 62972
}

get fun get_jetton_data(): TokenJettonData {
    throw 0;
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun estimate(tokens: int257, supply: int257): int257 {
    throw 0;
}

get fun buy_output(input_tons: int257, output_jettons: int257, supply: int257, slippage: int257): int257 {
    throw 0;
}

get fun sell_cost(input_jettons: int257, output_tons: int257, supply: int257, slippage: int257): int257 {
    throw 0;
}
