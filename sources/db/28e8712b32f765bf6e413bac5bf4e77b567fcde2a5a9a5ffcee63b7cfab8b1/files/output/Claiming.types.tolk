// Generated from the verified Tact contract ABI.
contract Claiming {
    storage: ClaimingData
    incomingMessages: ClaimingIncomingMessage
    thrownErrors: ClaimingErrors
}

struct (0x946a98b6) ClaimingDeploy {
    queryId: uint64
}

struct (0x819dbe99) ClaimingChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x1c78fadf) ClaimingCreateDistributor {
    queryId: uint64
    token: address
    vault: address
    merkleRoot: uint256
    unlockPeriods: map<int257, Cell<ClaimingUnlockPeriod>>
    tactContinuation: Cell<ClaimingCreateDistributorContinuation>
}

struct ClaimingCreateDistributorContinuation {
    totalAmount: uint256
    refundDate: uint32
}

struct (0x8baf68d1) ClaimingSetAdmin {
    queryId: uint64
    address: address
    value: bool
}

struct (0xe0c62a05) ClaimingUpgradeCode {
    newCode: cell
}

struct (0x78d457a3) ClaimingUpgradeData {
    newData: cell
}

struct ClaimingUnlockPeriod {
    percentage: uint64
    start: uint32
    end: uint32
    duration: uint32
    airdrop: bool
}

struct ClaimingData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    distributorsCount: uint32
    admins: map<address, bool>
}

type ClaimingIncomingMessage =
    | ClaimingCreateDistributor
    | ClaimingSetAdmin
    | ClaimingUpgradeCode
    | ClaimingUpgradeData
    | ClaimingDeploy
    | ClaimingChangeOwner

enum ClaimingErrors {
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
    /// Address not found
    AddressNotFound = 2540
    /// Invalid sender
    InvalidSender = 4429
    /// Refund requested
    RefundRequested = 6544
    /// Invalid value
    InvalidValue = 16059
    /// Refund not enabled or expired
    RefundNotEnabledOrExpired = 23950
    /// Vesting already stopped
    VestingAlreadyStopped = 26974
    /// Invalid total percentage
    InvalidTotalPercentage = 31556
    /// Not allowed to claim
    NotAllowedToClaim = 33287
    /// Wallet refunded
    WalletRefunded = 37633
    /// Already claimed
    AlreadyClaimed = 42504
    /// Invalid sender!
    InvalidSender2 = 42708
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// Nothing to claim
    NothingToClaim = 44799
    /// Wallet not found
    WalletNotFound = 53491
    /// Parent only
    ParentOnly = 54404
    /// Invalid balance
    InvalidBalance = 62972
}

get fun distributorsCount(): int257 {
    throw 0;
}

get fun admins(): map<address, bool> {
    throw 0;
}

get fun isAdmin(user: address): bool {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
