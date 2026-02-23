// Generated from the verified Tact contract ABI.
contract ArmCoinMaster {
    storage: ArmCoinMasterData
    incomingMessages: ArmCoinMasterIncomingMessage
    thrownErrors: ArmCoinMasterErrors
}

struct ArmCoinMasterStateInit {
    code: cell
    data: cell
}

struct (0x946a98b6) ArmCoinMasterDeploy {
    queryId: uint64
}

struct ArmCoinMasterJettonData {
    totalSupply: int257
    mintable: bool
    adminAddress: address
    content: cell
    walletCode: cell
}

struct (0xfc708bd2) ArmCoinMasterMint {
    amount: int257
    receiver: address
}

struct (0x445be3d9) ArmCoinMasterMasterBurn {
    amount: int257
}

struct ArmCoinMasterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    total_supply: int257
    owner: address
    jetton_content: cell
    nonce: uint64
}

type ArmCoinMasterIncomingMessage =
    | ArmCoinMasterMint
    | ArmCoinMasterMasterBurn
    | ArmCoinMasterDeploy

enum ArmCoinMasterErrors {
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
    /// Not enough Toncoin
    NotEnoughToncoin = 37
    /// Not enough extra currencies
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
    /// Invalid standard address
    InvalidStandardAddress = 136
    /// Not a basechain address
    NotABasechainAddress = 138
    /// Invalid sender
    InvalidSender = 4429
    /// Only owner can burn
    OnlyOwnerCanBurn = 21543
    /// Only owner can transfer
    OnlyOwnerCanTransfer = 36952
    /// Hard Cap exceeded
    HardCapExceeded = 40464
    /// Only admin can trigger master burn
    OnlyAdminCanTriggerMasterBurn = 44628
    /// Only admin can mint
    OnlyAdminCanMint = 49384
    /// Insufficient balance
    InsufficientBalance = 54615
    /// Invalid balance
    InvalidBalance = 62972
}

get fun getJettonWalletInit(address: address): ArmCoinMasterStateInit {
    throw 0;
}

get fun get_jetton_data(): ArmCoinMasterJettonData {
    throw 0;
}
