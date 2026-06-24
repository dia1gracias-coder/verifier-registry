// Generated from the verified Tact contract ABI.
contract MasterFactory {
    storage: MasterFactoryData
    incomingMessages: MasterFactoryIncomingMessage
    thrownErrors: MasterFactoryErrors
}

struct (0x946a98b6) MasterFactoryDeploy {
    queryId: uint64
}

struct (0x83efd5e0) MasterFactoryCreateMarket {
    chat_id: int64
    dispute_id: uint64
    oracle_address: address
    oracle_pool_address: address
    deadline: uint64
}

struct (0x5f805ddf) MasterFactorySetServiceWallet {
    new_service_wallet: address
}

struct (0x04865503) MasterFactoryTransferFactoryOwnership {
    new_owner: address
}

struct (0x0af91066) MasterFactorySetPlatformPublicKey {
    new_public_key: uint256
}

struct MasterFactoryData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    service_wallet: address
    public_key: uint256
    nonce: uint32
}

type MasterFactoryIncomingMessage =
    | MasterFactoryCreateMarket
    | MasterFactorySetServiceWallet
    | MasterFactorySetPlatformPublicKey
    | MasterFactoryTransferFactoryOwnership
    | MasterFactoryDeploy

enum MasterFactoryErrors {
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
    /// Can only cancel active dispute
    CanOnlyCancelActiveDispute = 4375
    /// Min bet 0.1 TON
    MinBet01TON = 7243
    /// Invalid winner code
    InvalidWinnerCode = 7837
    /// No winning bet
    NoWinningBet = 19862
    /// Only owner can transfer factory ownership
    OnlyOwnerCanTransferFactoryOwnership = 22831
    /// Only owner can change service wallet
    OnlyOwnerCanChangeServiceWallet = 27895
    /// Must be longer
    MustBeLonger = 28721
    /// Only oracle
    OnlyOracle = 29474
    /// Already resolved
    AlreadyResolved = 31038
    /// Max partner share is 100%
    MaxPartnerShareIs100 = 35042
    /// Nothing to withdraw
    NothingToWithdraw = 40636
    /// Cannot resolve to option with 0 bets
    CannotResolveToOptionWith0Bets = 40935
    /// Max 3 extends
    Max3Extends = 42460
    /// Only owner can change platform public key
    OnlyOwnerCanChangePlatformPublicKey = 43855
    /// Nothing to claim
    NothingToClaim = 44799
    /// Too early to resolve
    TooEarlyToResolve = 46179
    /// Only MasterFactory can change referrer settings
    OnlyMasterFactoryCanChangeReferrerSettings = 56336
    /// Time is up
    TimeIsUp = 58565
    /// Invalid server signature for referrer change
    InvalidServerSignatureForReferrerChange = 58978
    /// Not active
    NotActive = 61530
    /// Only owner can transfer ownership
    OnlyOwnerCanTransferOwnership = 62971
    /// Invalid server signature for deployment
    InvalidServerSignatureForDeployment = 63057
}

get fun service_wallet(): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun public_key(): int257 {
    throw 0;
}
