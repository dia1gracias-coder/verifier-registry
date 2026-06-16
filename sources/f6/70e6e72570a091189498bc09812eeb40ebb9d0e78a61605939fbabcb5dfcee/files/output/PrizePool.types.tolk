// Generated from the verified Tact contract ABI.
contract PrizePool {
    storage: PrizePoolData
    incomingMessages: PrizePoolIncomingMessage
    thrownErrors: PrizePoolErrors
}

struct (0x946a98b6) PrizePoolDeploy {
    queryId: uint64
}

struct (0x18fb3b31) PrizePoolFinalize {
    distribution: map<address, int257>
}

struct (0xfc264fcd) PrizePoolClaim {
}

struct (0x2e8351f0) PrizePoolSweep {
}

struct PrizePoolPoolInfo {
    balance: coins
    finalized: bool
    claimsOpenAt: int257
    sweepOpenAt: int257
}

struct PrizePoolData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    admin: address
    organizer: address
    claimTimelock: uint32
    sweepDelay: uint32
    finalized: bool
    claimsOpenAt: int257
    tactContinuation: Cell<PrizePoolDataContinuation>
}

struct PrizePoolDataContinuation {
    sweepOpenAt: int257
    distribution: map<address, int257>
}

type PrizePoolIncomingMessage =
    | PrizePoolFinalize
    | PrizePoolClaim
    | PrizePoolSweep
    | PrizePoolDeploy

enum PrizePoolErrors {
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
    /// zero share
    ZeroShare = 1273
    /// not finalized
    NotFinalized = 14050
    /// only admin
    OnlyAdmin = 21885
    /// sweep timelock active
    SweepTimelockActive = 28890
    /// timelock active
    TimelockActive = 36185
    /// pool too small
    PoolTooSmall = 50692
    /// already finalized
    AlreadyFinalized = 57851
    /// nothing to claim
    NothingToClaim = 62845
}

get fun claimable(addr: address): int257 {
    throw 0;
}

get fun info(): PrizePoolPoolInfo {
    throw 0;
}
