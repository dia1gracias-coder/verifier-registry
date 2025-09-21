// Generated from the verified Tact contract ABI.
contract TaxJettonMaster {
    storage: TaxJettonMasterData
    incomingMessages: TaxJettonMasterIncomingMessage
    thrownErrors: TaxJettonMasterErrors
}

struct TaxJettonMasterStateInit {
    code: cell
    data: cell
}

struct (0x946a98b6) TaxJettonMasterDeploy {
    queryId: uint64
}

struct (0x178d4519) TaxJettonMasterTokenTransferInternal {
    query_id: uint64
    amount: coins
    from: address
    response_destination: address?
    forward_ton_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct (0x7bdd97de) TaxJettonMasterTokenBurnNotification {
    query_id: uint64
    amount: coins
    from: address
    response_destination: address?
}

struct (0x0c087a9e) TaxJettonMasterTokenUpdateContent {
    content: cell?
}

struct (0x91224894) TaxJettonMasterProvideWalletAddress {
    query_id: uint64
    owner_address: address
    include_address: bool
}

struct (0xfc708bd2) TaxJettonMasterMint {
    amount: int257
    receiver: address
}

struct TaxJettonMasterJettonData {
    total_supply: int257
    mintable: bool
    admin_address: address
    jetton_content: cell?
    jetton_wallet_code: cell
}

struct TaxJettonMasterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    total_supply: int257
    mintable: bool
    owner: address
    content: cell?
    dev_address: address
    stopped: bool
}

type TaxJettonMasterIncomingMessage =
    | TaxJettonMasterMint
    | TaxJettonMasterTokenUpdateContent
    | TaxJettonMasterTokenBurnNotification
    | TaxJettonMasterProvideWalletAddress
    | TaxJettonMasterTokenTransferInternal
    | TaxJettonMasterDeploy

enum TaxJettonMasterErrors {
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
    /// Not mintable
    NotMintable = 3688
    /// Not Owner
    NotOwner = 3734
    /// Invalid sender
    InvalidSender = 4429
    /// Insufficient gas for transfer
    InsufficientGasForTransfer = 6891
    /// Invalid burn amount
    InvalidBurnAmount = 8723
    /// Invalid amount
    InvalidAmount = 17062
    /// Insufficient gas
    InsufficientGas = 23951
    /// Contract not stopped
    ContractNotStopped = 53296
    /// Insufficient balance
    InsufficientBalance = 54615
}

get fun get_jetton_data(): TaxJettonMasterJettonData {
    throw 0;
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}

get fun getJettonWalletInit(owner: address): TaxJettonMasterStateInit {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun stopped(): bool {
    throw 0;
}
