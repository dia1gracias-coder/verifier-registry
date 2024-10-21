// Generated from the verified Tact contract ABI.
contract Router {
    storage: RouterData2
    incomingMessages: RouterIncomingMessage
    thrownErrors: RouterErrors
}

struct RouterStateInit {
    code: cell
    data: cell
}

struct (0x946a98b6) RouterDeploy {
    queryId: uint64
}

struct (0xd35826fb) RouterPayTo {
    queryId: uint64
    owner: address
    exitCode: uint32
    amount0Out: coins
    token0Address: address
    amount1Out: coins
    tactContinuation: Cell<RouterPayToContinuation>
}

struct RouterPayToContinuation {
    token1Address: address
}

struct (0xba7f7b2f) RouterSetFees {
    queryId: uint64
    newLpFee: coins
    newProtocolFee: coins
    newRefFee: coins
    newProtocolFeeAddress: address
    jettonWallet0: address
    tactContinuation: Cell<RouterSetFeesContinuation>
}

struct RouterSetFeesContinuation {
    jettonWallet1: address
}

struct (0xdc5bfbae) RouterCollectFees {
    queryId: uint64
    jettonWallet0: address
    jettonWallet1: address
}

struct (0x7d5a7a2d) RouterLock {
    queryId: uint64
}

struct (0x784a368a) RouterUnlock {
    queryId: uint64
}

struct (0xb3257496) RouterResetGas {
    queryId: uint64
}

struct (0x9f0198f5) RouterResetPoolGas {
    queryId: uint64
    jettonWallet0: address
    jettonWallet1: address
}

struct (0x153ad2cc) RouterGetterPoolAddress {
    queryId: uint64
    token0: address
    token1: address
}

struct (0x12d97516) RouterInitCodeUpgrade {
    queryId: uint64
    code: cell
}

struct (0x803aa9fe) RouterInitAdminUpgrade {
    queryId: uint64
    admin: address
}

struct (0xcd640d5b) RouterCancelAdminUpgrade {
    queryId: uint64
}

struct (0xda637bb7) RouterCancelCodeUpgrade {
    queryId: uint64
}

struct (0xc917670d) RouterFinalizeUpgrades {
    queryId: uint64
}

struct (0x72210d3a) RouterCbSwap {
    queryId: uint64
    fromUserAddress: address
    tokenWallet: address
    amount: coins
    fromRealUser: address
    tactContinuation: Cell<RouterCbSwapContinuation>
}

struct RouterCbSwapContinuation {
    refAddress: address?
    refMessageValue: coins
    next: RouterSwapNext
}

struct RouterSwapNext {
    tokenAddress: address
    minOut: coins
    next: cell?
}

struct (0x7362d09c) RouterTokenNotification {
    queryId: uint64
    amount: coins
    from: address
    forwardPayload: cell?
}

struct RouterUpgrade {
    endCode: uint64
    endAdmin: uint64
    admin: address?
    code: cell?
}

struct RouterData {
    locked: bool
    adminAddress: address
    tempUpgrade: RouterUpgrade
}

struct RouterData2 {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    tempUpgrade: RouterUpgrade
    locked: bool
    adminAddress: address
}

type RouterIncomingMessage =
    | RouterPayTo
    | RouterTokenNotification
    | RouterCbSwap
    | RouterSetFees
    | RouterCollectFees
    | RouterLock
    | RouterUnlock
    | RouterResetGas
    | RouterResetPoolGas
    | RouterGetterPoolAddress
    | RouterInitCodeUpgrade
    | RouterInitAdminUpgrade
    | RouterCancelAdminUpgrade
    | RouterCancelCodeUpgrade
    | RouterFinalizeUpgrades
    | RouterDeploy

enum RouterErrors {
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
}

get fun getPoolStateInit(jettonWallet0: address, jettonWallet1: address): RouterStateInit {
    throw 0;
}

get fun getPoolAddress(jettonWallet0: address, jettonWallet1: address): address {
    throw 0;
}

get fun getRouterData(): RouterData {
    throw 0;
}
