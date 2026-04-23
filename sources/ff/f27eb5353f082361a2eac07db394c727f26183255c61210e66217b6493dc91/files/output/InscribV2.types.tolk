// Generated from the verified Tact contract ABI.
contract InscribV2 {
    storage: InscribV2Data
    incomingMessages: InscribV2IncomingMessage
    thrownErrors: InscribV2Errors
}

struct (0x946a98b6) InscribV2Deploy {
    queryId: uint64
}

struct (0x89a35a1f) InscribV2Mint {
}

struct (0x2365d020) InscribV2Withdraw {
}

struct (0x0ce88726) InscribV2SetPrice {
    newPrice: coins
}

struct (0x9f517772) InscribV2SetMaxPerUser {
    newMax: uint8
}

struct InscribV2Data {
    tactDeploymentCompleted: bool
    owner: address
    totalSupply: uint32
    minted: uint32
    mintPrice: coins
    maxPerUser: uint8
    isPaused: bool
    userMints: map<address, uint8>
}

type InscribV2IncomingMessage =
    | InscribV2Mint
    | InscribV2Withdraw
    | InscribV2SetPrice
    | InscribV2SetMaxPerUser
    | InscribV2Deploy

enum InscribV2Errors {
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
    /// Max 20 mints per wallet
    Max20MintsPerWallet = 15252
    /// Price must be > 0
    PriceMustBe0 = 23732
    /// Sold out
    SoldOut = 30667
    /// Nothing to withdraw
    NothingToWithdraw = 40636
    /// Max must be > 0
    MaxMustBe0 = 43719
    /// Insufficient TON sent
    InsufficientTONSent = 48341
    /// Minting is paused
    MintingIsPaused = 54566
}

get fun minted(): int257 {
    throw 0;
}

get fun totalSupply(): int257 {
    throw 0;
}

get fun mintPrice(): int257 {
    throw 0;
}

get fun maxPerUser(): int257 {
    throw 0;
}

get fun isPaused(): bool {
    throw 0;
}

get fun remaining(): int257 {
    throw 0;
}

get fun userMintCount(addr: address): int257 {
    throw 0;
}

get fun canMint(addr: address): bool {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
