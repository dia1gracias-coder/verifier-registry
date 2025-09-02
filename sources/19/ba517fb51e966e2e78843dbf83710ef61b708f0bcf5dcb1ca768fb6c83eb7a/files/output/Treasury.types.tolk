// Generated from the verified Tact contract ABI.
contract Treasury {
    storage: TreasuryData
    incomingMessages: TreasuryIncomingMessage
    incomingExternal: TreasuryRewardRequest
    thrownErrors: TreasuryErrors
}

struct (0x946a98b6) TreasuryDeploy {
    queryId: uint64
}

struct (0x2f8d9659) TreasuryRewardRequest {
    signature: cell
    contract_: address
    recipient: address
    amount: coins
    nonce: uint64
    validUntil: uint32
}

struct (0x63e724e1) TreasurySetBackendKey {
    pubkey: uint256
}

struct (0xfbd38a87) TreasurySetMaxPayout {
    amount: coins
}

struct (0x287091e8) TreasurySetMinPayout {
    amount: coins
}

struct (0x7e179442) TreasurySetTreasuryWallet {
    addr: address
}

struct (0x096819ff) TreasurySetPaused {
    paused: bool
}

struct (0x5dc94942) TreasuryUpgrade {
    code: cell
}

struct TreasuryData {
    tactDeploymentCompleted: bool
    owner: address
    paused: bool
    jettonMaster: address
    treasuryJettonWallet: address
    tactContinuation: Cell<TreasuryDataContinuation>
}

struct TreasuryDataContinuation {
    backendPubKey: uint256
    nonce: uint64
    minPayout: coins
    maxPayout: coins
}

type TreasuryIncomingMessage =
    | TreasurySetPaused
    | TreasurySetBackendKey
    | TreasurySetMaxPayout
    | TreasurySetMinPayout
    | TreasurySetTreasuryWallet
    | TreasuryUpgrade
    | TreasuryDeploy

enum TreasuryErrors {
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
}

get fun backendKey(): int257 {
    throw 0;
}

get fun paused(): bool {
    throw 0;
}

get fun nonce(): int257 {
    throw 0;
}

get fun treasuryJettonWallet(): address {
    throw 0;
}

get fun maxPayout(): int257 {
    throw 0;
}

get fun minPayout(): int257 {
    throw 0;
}

get fun jettonMaster(): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
