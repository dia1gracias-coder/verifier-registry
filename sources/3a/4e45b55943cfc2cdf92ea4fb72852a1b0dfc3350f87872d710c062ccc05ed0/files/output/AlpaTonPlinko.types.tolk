// Generated from the verified Tact contract ABI.
contract AlpaTonPlinko {
    storage: AlpaTonPlinkoData
    incomingMessages: AlpaTonPlinkoIncomingMessage
    thrownErrors: AlpaTonPlinkoErrors
}

struct (0x946a98b6) AlpaTonPlinkoDeploy {
    queryId: uint64
}

struct (0xbb51ef8b) AlpaTonPlinkoFundPayout {
    value: coins
}

struct (0x64852be8) AlpaTonPlinkoGamePayoutSlim {
    value: coins
    rows: int257
    risks: int257
}

struct (0x11ee0c5f) AlpaTonPlinkoMultiGamePayoutSlim {
    valuePerIteration: coins
    iterations: int257
    rows: int257
    risks: int257
}

struct (0x0ba69751) AlpaTonPlinkoWithdraw {
    amount: coins
}

struct AlpaTonPlinkoSlotInfo {
    slot: map<int257, int257>
    slot_count: int257
}

struct AlpaTonPlinkoSlotRisk {
    slot_risk: map<int257, Cell<AlpaTonPlinkoSlotInfo>>
    slot_risk_count: int257
}

struct AlpaTonPlinkoSlotUniverse {
    slots: map<int257, Cell<AlpaTonPlinkoSlotRisk>>
    slots_count: int257
}

struct AlpaTonPlinkoData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    slot_universe: AlpaTonPlinkoSlotUniverse
    owner: address
}

type AlpaTonPlinkoIncomingMessage =
    | AlpaTonPlinkoGamePayoutSlim
    | AlpaTonPlinkoMultiGamePayoutSlim
    | AlpaTonPlinkoFundPayout
    | AlpaTonPlinkoWithdraw
    | AlpaTonPlinkoDeploy

enum AlpaTonPlinkoErrors {
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
    /// message malformed, ton value not matching
    MessageMalformedTonValueNotMatching = 8464
    /// enough funds in balance for payout
    EnoughFundsInBalanceForPayout = 13378
    /// minimum 2 iterations
    Minimum2Iterations = 30026
    /// sender not permitted
    SenderNotPermitted = 53480
    /// Insufficient balance
    InsufficientBalance = 54615
    /// not less than 0.01 TON to play
    NotLessThan001TONToPlay = 58518
}

get fun totalBalance(): int257 {
    throw 0;
}

get fun totalBalanceString(): string {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
