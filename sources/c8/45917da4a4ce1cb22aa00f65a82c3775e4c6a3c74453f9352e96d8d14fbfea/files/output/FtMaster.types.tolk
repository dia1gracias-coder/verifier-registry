// Generated from the verified Tact contract ABI.
contract FtMaster {
    storage: FtMasterData
    incomingMessages: FtMasterIncomingMessage
    thrownErrors: FtMasterErrors
}

struct (0x946a98b6) FtMasterDeploy {
    queryId: uint64
}

struct (0x14b1a1a1) FtMasterSetupMaster {
}

struct (0x389f33c3) FtMasterSetupJoinPrice {
    newJoinPrice: coins
}

struct (0x94f6ed64) FtMasterSetupSquadPrice {
    newSquadPrice: coins
}

struct (0x062a2f22) FtMasterUpdateProgramAddress {
    programIndex: uint8
    programAddress: address
}

struct (0x402d64ce) FtMasterGiftJoin {
    userAddress: address
    invitedId: uint64
}

struct (0xd708ea18) FtMasterJoin {
    userAddress: address?
    invitedId: uint64
}

struct (0xa0aab1e2) FtMasterCreateSquad {
    owner: address?
}

struct FtMasterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    joinPrice: coins
    squadPrice: coins
    isSetup: bool
    index: uint32
    owner: address
    nextUserIndex: uint64
    programs: map<uint8, address>
}

type FtMasterIncomingMessage =
    | FtMasterSetupMaster
    | FtMasterSetupJoinPrice
    | FtMasterSetupSquadPrice
    | FtMasterUpdateProgramAddress
    | FtMasterGiftJoin
    | FtMasterJoin
    | FtMasterCreateSquad
    | FtMasterDeploy

enum FtMasterErrors {
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

get fun balance(): int257 {
    throw 0;
}

get fun joinPrice(): int257 {
    throw 0;
}

get fun squadPrice(): int257 {
    throw 0;
}

get fun lastUserIndex(): int257 {
    throw 0;
}

get fun programs(): map<uint8, address> {
    throw 0;
}

get fun userStorageAddress(address: address): address {
    throw 0;
}

get fun userMainAddress(id: int257): address {
    throw 0;
}

get fun userSquadAddress(address: address): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
