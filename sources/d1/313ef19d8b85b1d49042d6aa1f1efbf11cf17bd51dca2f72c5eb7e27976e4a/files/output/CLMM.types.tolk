// Generated from the verified Tact contract ABI.
contract CLMM {
    storage: CLMMData
    incomingMessages: CLMMIncomingMessage
    thrownErrors: CLMMErrors
}

struct (0x946a98b6) CLMMDeploy {
    queryId: uint64
}

struct CLMMJettonData {
    totalSupply: int257
    mintable: bool
    owner: address
    content: cell
    walletCode: cell
}

struct (0x7362d09c) CLMMTokenNotification {
    queryId: uint64
    amount: coins
    from: address
    forward_payload: RemainingBitsAndRefs
}

struct (0x7bdd97de) CLMMTokenBurnNotification {
    queryId: uint64
    amount: coins
    owner: address
    response_destination: address?
}

struct (0xaf1ca26a) CLMMTokenUpdateContent {
    content: cell
}

struct (0xa1570d9c) CLMMSetFeeTier {
    fee: int257
    tickSpacing: int257
}

struct (0x8a0840a0) CLMMSetProtocolFee {
    newFee: int257
}

struct (0x25631a64) CLMMCollectFees {
    positionId: int257
}

struct (0xc7df2dba) CLMMAddLiquidity {
    amount0Desired: coins
    amount1Desired: coins
    amount0Min: coins
    amount1Min: coins
    tickLower: int257
    tactContinuation: Cell<CLMMAddLiquidityContinuation>
}

struct CLMMAddLiquidityContinuation {
    tickUpper: int257
    recipient: address
}

struct (0x067d96ef) CLMMSwap {
    tokenIn: address
    amountIn: coins
    amountOutMinimum: coins
    recipient: address
}

struct CLMMPosition {
    owner: address
    liquidity: coins
    tickLower: int257
    tickUpper: int257
    tactContinuation: Cell<CLMMPositionContinuation>
}

struct CLMMPositionContinuation {
    tokensOwed0: coins
    tokensOwed1: coins
    feeGrowthInside0LastX128: int257
    feeGrowthInside1LastX128: int257
}

struct CLMMPoolData {
    token0: address
    token1: address
    fee: int257
    tactContinuation: Cell<CLMMPoolDataContinuation>
}

struct CLMMPoolDataContinuation {
    tickSpacing: int257
    sqrtPriceX96: int257
    tick: int257
    tactContinuation: Cell<CLMMPoolDataContinuation2>
}

struct CLMMPoolDataContinuation2 {
    liquidity: int257
    reserve0: coins
    reserve1: coins
}

struct CLMMFeeGrowthGlobal {
    feeGrowthGlobal0X128: int257
    feeGrowthGlobal1X128: int257
}

struct CLMMFeeTier {
    fee: int257
    tickSpacing: int257
    active: bool
}

struct CLMMData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    token0: address
    token1: address
    tactContinuation: Cell<CLMMDataContinuation>
}

struct CLMMDataContinuation {
    fee: int257
    tickSpacing: int257
    mintable: bool
    content: cell
    max_supply: coins
    totalSupply: int257
    tactContinuation: Cell<CLMMDataContinuation2>
}

struct CLMMDataContinuation2 {
    sqrtPriceX96: int257
    tick: int257
    liquidity: int257
    tactContinuation: Cell<CLMMDataContinuation3>
}

struct CLMMDataContinuation3 {
    reserve0: int257
    reserve1: int257
    positions: map<int257, Cell<CLMMPosition>>
    nextPositionId: int257
    tactContinuation: Cell<CLMMDataContinuation4>
}

struct CLMMDataContinuation4 {
    feeGrowthGlobal: CLMMFeeGrowthGlobal
    feeTiers: map<int257, Cell<CLMMFeeTier>>
    protocolFee: int257
    tactContinuation: Cell<CLMMDataContinuation5>
}

struct CLMMDataContinuation5 {
    protocolFeeRecipient: address
}

type CLMMIncomingMessage =
    | CLMMTokenNotification
    | CLMMAddLiquidity
    | CLMMSwap
    | CLMMSetFeeTier
    | CLMMSetProtocolFee
    | CLMMCollectFees
    | CLMMDeploy
    | CLMMTokenUpdateContent
    | CLMMTokenBurnNotification

enum CLMMErrors {
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
    /// 'Unknown' error
    UnknownError = 11
    /// Fatal error
    FatalError = 12
    /// Out of gas error
    OutOfGasError = 13
    /// Virtualization error
    VirtualizationError = 14
    /// Action list is invalid
    ActionListIsInvalid = 32
    /// Action list is too long
    ActionListIsTooLong = 33
    /// Action is invalid or not supported
    ActionIsInvalidOrNotSupported = 34
    /// Invalid source address in outbound message
    InvalidSourceAddressInOutboundMessage = 35
    /// Invalid destination address in outbound message
    InvalidDestinationAddressInOutboundMessage = 36
    /// Not enough TON
    NotEnoughTON = 37
    /// Not enough extra-currencies
    NotEnoughExtraCurrencies = 38
    /// Outbound message does not fit into a cell after rewriting
    OutboundMessageDoesNotFitIntoACellAfterRewriting = 39
    /// Cannot process a message
    CannotProcessAMessage = 40
    /// Library reference is null
    LibraryReferenceIsNull = 41
    /// Library change action error
    LibraryChangeActionError = 42
    /// Exceeded maximum number of cells in the library or the maximum depth of the Merkle tree
    ExceededMaximumNumberOfCellsInTheLibraryOrTheMaximumDepthOfTheMerkleTree = 43
    /// Account state size exceeded limits
    AccountStateSizeExceededLimits = 50
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
    /// Not Owner
    NotOwner = 3734
    /// Invalid value!!
    InvalidValue = 4159
    /// Invalid sender
    InvalidSender = 4429
    /// The total supply will be overlapping.
    TheTotalSupplyWillBeOverlapping = 6898
    /// Not owner
    NotOwner2 = 14534
    /// Can't Mint Anymore
    CanTMintAnymore = 18668
    /// Invalid input token
    InvalidInputToken = 21397
    /// Invalid position
    InvalidPosition = 38079
    /// L
    L = 38320
    /// Invalid sender!
    InvalidSender2 = 42708
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// AI
    AI = 45875
    /// Fee too high
    FeeTooHigh = 46136
    /// T
    T = 58337
    /// Invalid balance
    InvalidBalance = 62972
}

get fun getPosition(id: int257): CLMMPosition? {
    throw 0;
}

get fun getPositions(): map<int257, Cell<CLMMPosition>> {
    throw 0;
}

get fun getPoolData(): CLMMPoolData {
    throw 0;
}

get fun getFeeGrowthInside(tickLower: int257, tickUpper: int257, currentTick: int257, feeGrowthGlobalX128: int257): int257 {
    throw 0;
}

get fun getFeeGrowthGlobal(): CLMMFeeGrowthGlobal {
    throw 0;
}

get fun getToken0(): address {
    throw 0;
}

get fun getToken1(): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun get_jetton_data(): CLMMJettonData {
    throw 0;
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}
