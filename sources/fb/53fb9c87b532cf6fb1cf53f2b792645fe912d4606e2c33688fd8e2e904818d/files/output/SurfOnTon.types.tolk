// Generated from the verified Tact contract ABI.
contract SurfOnTon {
    storage: SurfOnTonData
    incomingMessages: SurfOnTonIncomingMessage
    thrownErrors: SurfOnTonErrors
}

struct (0x819dbe99) SurfOnTonChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x5a114718) SurfOnTonUpdateTokenData {
    owner: address?
    launchFee: int257?
    orderFeeBps: int257?
}

struct (0xa91e4c38) SurfOnTonSellOrder {
    sellSize: coins
    amountOutMin: coins
    seller: address?
}

struct (0xc1c8b51c) SurfOnTonDeploy {
    tokenDeployer: address?
}

struct SurfOnTonJettonData {
    total_supply: int257
    mintable: bool
    owner: address
    content: cell
    wallet_code: cell
}

struct (0x7362d09c) SurfOnTonTokenNotification {
    query_id: uint64
    amount: coins
    from: address
    forward_payload: RemainingBitsAndRefs
}

struct (0x7bdd97de) SurfOnTonTokenBurnNotification {
    query_id: uint64
    amount: coins
    sender: address
    response_destination: address?
}

struct (0xd53276db) SurfOnTonTokenExcesses {
    query_id: uint64
}

struct (0xaf1ca26a) SurfOnTonTokenUpdateContent {
    content: cell
}

struct (0x2c76b973) SurfOnTonProvideWalletAddress {
    query_id: uint64
    owner_address: address
    include_address: bool
}

struct (0xd1735400) SurfOnTonTakeWalletAddress {
    query_id: uint64
    wallet_address: address
    owner_address: RemainingBitsAndRefs
}

struct SurfOnTonLocalState {
    reserveTon: coins
    reserveSurf: coins
    launchFee: coins
    proxyTonWallet: address
    orderFeeBps: uint32
    launched: bool
    dexRouterTonWallet: address
    tactContinuation: Cell<SurfOnTonLocalStateContinuation>
}

struct SurfOnTonLocalStateContinuation {
    total_supply: int257
    owner: address
}

struct SurfOnTonData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    vx1: coins
    vy1: coins
    reserveTon: coins
    reserveSurf: coins
    tonThreshold: coins
    launchFee: coins
    factory: address
    tactContinuation: Cell<SurfOnTonDataContinuation>
}

struct SurfOnTonDataContinuation {
    proxyTonWallet: address
    orderFeeBps: uint32
    launched: bool
    dexRouter: address
    dexRouterTonWallet: address
    tactContinuation: Cell<SurfOnTonDataContinuation2>
}

struct SurfOnTonDataContinuation2 {
    tokenDeployer: address?
    launchTimestamp: uint32
    total_supply: int257
    mintable: bool
    owner: address
    content: cell
}

type SurfOnTonIncomingMessage =
    | SurfOnTonDeploy
    | SurfOnTonTakeWalletAddress
    | SurfOnTonTokenNotification
    | SurfOnTonTokenExcesses
    | SurfOnTonSellOrder
    | SurfOnTonUpdateTokenData
    | SurfOnTonTokenUpdateContent
    | SurfOnTonTokenBurnNotification
    | SurfOnTonProvideWalletAddress
    | SurfOnTonChangeOwner

enum SurfOnTonErrors {
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
    /// not enough funds
    NotEnoughFunds = 3235
    /// wrong teamWalletShareBps
    WrongTeamWalletShareBps = 3562
    /// Invalid sender
    InvalidSender = 4429
    /// wrong ton threshold
    WrongTonThreshold = 6734
    /// wrong launch fee 2
    WrongLaunchFee2 = 9623
    /// Gas amount too small
    GasAmountTooSmall = 15695
    /// Invalid value
    InvalidValue = 16059
    /// Not sufficient liquidity
    NotSufficientLiquidity = 17475
    /// Can't Mint Anymore
    CanTMintAnymore = 18668
    /// Insufficient gas
    InsufficientGas = 23951
    /// wrong total supply
    WrongTotalSupply = 25865
    /// Token launched on DEX
    TokenLaunchedOnDEX = 30867
    /// Not enough gas
    NotEnoughGas = 33150
    /// Contract stopped
    ContractStopped2 = 40368
    /// Invalid sender!
    InvalidSender2 = 42708
    /// wrong launch fee 1
    WrongLaunchFee1 = 43288
    /// factory only allowed
    FactoryOnlyAllowed = 49347
    /// Contract not stopped
    ContractNotStopped = 53296
    /// access denied
    AccessDenied2 = 61686
    /// Slippage too small
    SlippageTooSmall = 62322
    /// Invalid balance
    InvalidBalance = 62972
}

get fun GetAmountInTon(surfSize: int257): int257 {
    throw 0;
}

get fun GetAmountOutSurf(tonSize: int257): int257 {
    throw 0;
}

get fun GetAmountInSurf(tonSize: int257): int257 {
    throw 0;
}

get fun GetAmountOutTon(surfSize: int257): int257 {
    throw 0;
}

get fun GetDexRouterPTonWallet(): address {
    throw 0;
}

get fun GetPTonWallet(): address {
    throw 0;
}

get fun GetCurrentPrice(): int257 {
    throw 0;
}

get fun GetTonReserve(): SurfOnTonLocalState {
    throw 0;
}

get fun get_jetton_data(): SurfOnTonJettonData {
    throw 0;
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
