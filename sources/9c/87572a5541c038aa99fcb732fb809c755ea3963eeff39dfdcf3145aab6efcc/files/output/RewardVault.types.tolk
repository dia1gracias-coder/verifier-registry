// Generated from the verified Tact contract ABI.
contract RewardVault {
    storage: RewardVaultData
    incomingMessages: RewardVaultIncomingMessage
    thrownErrors: RewardVaultErrors
}

struct (0x946a98b6) RewardVaultDeploy {
    queryId: uint64
}

struct (0x80a57950) RewardVaultSetBoxManager {
    box_manager: address
}

struct RewardVaultVaultData {
    owner: address
    box_manager: address?
    gas_required: coins
    balance: coins
}

struct RewardVaultData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    box_manager: address?
    gas_required: coins
}

type RewardVaultIncomingMessage =
    | RewardVaultSetBoxManager
    | RewardVaultDeploy

enum RewardVaultErrors {
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
    /// Not enough TON [checkTonValue]
    NotEnoughTONCheckTonValue = 2466
    /// Only for Box Manager
    OnlyForBoxManager = 7900
    /// Not enough TON [checkTonBalance]
    NotEnoughTONCheckTonBalance = 11695
    /// Box Manager not set
    BoxManagerNotSet = 34655
    /// Only owner allowed
    OnlyOwnerAllowed = 51168
}

get fun getVaultData(): RewardVaultVaultData {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
