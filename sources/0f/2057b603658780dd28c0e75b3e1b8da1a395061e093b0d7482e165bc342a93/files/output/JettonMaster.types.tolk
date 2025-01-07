// Generated from the verified Tact contract ABI.
contract JettonMaster {
    storage: JettonMasterData2
    incomingMessages: JettonMasterIncomingMessage
    thrownErrors: JettonMasterErrors
}

struct (0x946a98b6) JettonMasterDeploy {
    queryId: uint64
}

struct (0x819dbe99) JettonMasterChangeOwner {
    queryId: uint64
    newOwner: address
}

struct JettonMasterData {
    total_supply: int257
    mintable: bool
    owner: address
    jetton_content: cell
    jetton_wallet_code: cell
}

struct (0x00133704) JettonMasterJettonMint {
    query_id: uint64
    destination: address
    amount: coins
}

struct JettonMasterOnchainMetadata {
    inner: map<uint256, cell>
}

struct (0x7bdd97de) JettonMasterJettonBurnInternal {
    query_id: uint64
    amount: coins
    sender: address
    response_destination: address
}

struct (0x2c76b973) JettonMasterProvideWalletAddress {
    query_id: uint64
    owner_address: address
    include_address: bool
}

struct JettonMasterData2 {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    max_supply: int257
    current_supply: int257
    mintable: bool
    owner: address
    jetton_wallet_code: cell
    tactContinuation: Cell<JettonMasterDataContinuation>
}

struct JettonMasterDataContinuation {
    jetton_wallet_system: cell
    metadata: JettonMasterOnchainMetadata
    deployed: bool
}

type JettonMasterIncomingMessage =
    | JettonMasterJettonMint
    | JettonMasterJettonBurnInternal
    | JettonMasterProvideWalletAddress
    | JettonMasterDeploy
    | JettonMasterChangeOwner

enum JettonMasterErrors {
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

get fun tact_system_cell(): cell {
    throw 0;
}

get fun get_jetton_data(): JettonMasterData {
    throw 0;
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
