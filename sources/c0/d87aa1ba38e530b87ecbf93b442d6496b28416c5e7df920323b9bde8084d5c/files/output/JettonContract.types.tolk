// Generated from the verified Tact contract ABI.
contract JettonContract {
    storage: JettonContractData
    incomingMessages: JettonContractIncomingMessage
    thrownErrors: JettonContractErrors
}

struct JettonContractDevData {
    Address: address
    Value: int257
    Message: string
}

struct JettonContractJettonData {
    TotalSupply: coins
    Mintable: bool
    AdminAddress: address
    JettonContent: cell
    JettonWalletCode: cell
}

struct (0x00000001) JettonContractMint {
    Address: address
    Value: coins
}

struct (0x00000002) JettonContractUpdateContent {
    Name: string
    Desc: string
    tactContinuation: Cell<JettonContractUpdateContentContinuation>
}

struct JettonContractUpdateContentContinuation {
    Symbol: string
    Img: string
}

struct (0x00000003) JettonContractUpdateContractOwner {
    Address: address
}

struct (0x00000004) JettonContractMintClose {
}

struct (0x00000005) JettonContractWithdrawalMaster {
    Address: address
}

struct (0x00000006) JettonContractRevokeContractOwner {
}

struct (0x7bdd97de) JettonContractJettonWalletBurnNotify {
    query_id: uint64
    amount: coins
    sender: address
    response_destination: address
}

struct (0x2c76b973) JettonContractProvideWalletAddress {
    query_id: uint64
    owner: address
    include_address: bool
}

struct JettonContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    AdminAddress: address
    Mintable: bool
    MetaDataContent: cell
    TotalSupply: coins
    tactContinuation: Cell<JettonContractDataContinuation>
}

struct JettonContractDataContinuation {
    DevData: JettonContractDevData
    WalletCode: cell
    LockedContentDecimals: string
    GlobalID: int257
    IsDevFeeSended: bool
}

type JettonContractIncomingMessage =
    | JettonContractMint
    | JettonContractUpdateContent
    | JettonContractUpdateContractOwner
    | JettonContractMintClose
    | JettonContractWithdrawalMaster
    | JettonContractRevokeContractOwner
    | JettonContractJettonWalletBurnNotify
    | JettonContractProvideWalletAddress

enum JettonContractErrors {
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
    Error8610 = 8610
}

get fun get_jetton_data(): JettonContractJettonData {
    throw 0;
}

get fun get_wallet_address(V: address): address {
    throw 0;
}
