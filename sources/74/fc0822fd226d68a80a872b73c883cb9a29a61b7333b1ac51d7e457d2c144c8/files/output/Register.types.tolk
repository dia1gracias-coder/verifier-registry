// Generated from the verified Tact contract ABI.
contract Register {
    storage: RegisterData
    incomingMessages: RegisterIncomingMessage
    thrownErrors: RegisterErrors
}

struct (0x4fef0a87) RegisterReigsterTokenTick {
    symbol: cell
    name: cell
    image: cell
    tactContinuation: Cell<RegisterReigsterTokenTickContinuation>
}

struct RegisterReigsterTokenTickContinuation {
    description: cell
    minting_info: cell
}

struct (0x69982b2a) RegisterAdminAddSymbol {
    symbol: cell
    theoryItemIndex: uint32
}

struct (0xf7e88dcb) RegisterAdminRemoveSymbol {
    symbol: cell
}

struct (0x693d3950) RegisterGetRoyaltyParams {
    query_id: uint64
}

struct RegisterCollectionData {
    next_item_index: int257
    collection_content: cell
    owner_address: address
}

struct RegisterRoyaltyParams {
    numerator: int257
    denominator: int257
    destination: address
}

struct RegisterAddressList {
    nftItemAddress: address
    jettonRootAddress: address
    jettonContent: cell
}

struct RegisterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    admin: address
    tactContinuation: Cell<RegisterDataContinuation>
}

struct RegisterDataContinuation {
    royalty_params: RegisterRoyaltyParams
    collection_content: cell
    next_item_index: uint32
    tactContinuation: Cell<RegisterDataContinuation2>
}

struct RegisterDataContinuation2 {
    treasury: address
    symbol_record: map<uint256, uint32>
    contractAddressRecord: map<uint32, Cell<RegisterAddressList>>
    tempTokenContent: map<uint256, cell>
    tactContinuation: Cell<RegisterDataContinuation3>
}

struct RegisterDataContinuation3 {
    jettonRootCode: cell
    jettonWalletCode: cell
    is_open: bool
}

type RegisterIncomingMessage =
    | RegisterAdminAddSymbol
    | RegisterAdminRemoveSymbol
    | RegisterReigsterTokenTick
    | RegisterGetRoyaltyParams

enum RegisterErrors {
    /// Stack undeflow
    StackUndeflow = 2
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
    /// Out of gas error
    OutOfGasError = 13
    /// Method ID not found
    MethodIDNotFound = 32
    /// Action is invalid or not supported
    ActionIsInvalidOrNotSupported = 34
    /// Not enough TON
    NotEnoughTON = 37
    /// Not enough extra-currencies
    NotEnoughExtraCurrencies = 38
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
    /// not owner of NFT item
    NotOwnerOfNFTItem = 7747
    /// init supply must be positive
    InitSupplyMustBePositive = 9172
    /// symbol too long
    SymbolTooLong = 14096
    /// minting info must be non-empty
    MintingInfoMustBeNonEmpty = 21446
    /// max supply must be positive
    MaxSupplyMustBePositive = 21967
    /// contract is closed
    ContractIsClosed = 26993
    /// initial mint rate must be positive
    InitialMintRateMustBePositive = 28496
    /// symbol already registered
    SymbolAlreadyRegistered = 35479
    /// total duration must be positive
    TotalDurationMustBePositive = 38017
    /// not admin
    NotAdmin = 47422
    /// not owner
    NotOwner = 49280
    /// percent_of_fee_back must be positive
    PercentOfFeeBackMustBePositive = 49707
    /// not collection
    NotCollection = 52504
    /// symbol must be lower case
    SymbolMustBeLowerCase = 53008
    /// the starting sholuld be higher than now
    TheStartingSholuldBeHigherThanNow = 53949
    /// cost per mint must be more than 0.25 TON
    CostPerMintMustBeMoreThan025TON = 57008
    /// symbol too short, at least 2 chars
    SymbolTooShortAtLeast2Chars = 57174
    /// the ratio is incorrect
    TheRatioIsIncorrect = 58633
    /// not enough value for tonCoin to register
    NotEnoughValueForTonCoinToRegister = 60108
    /// non-sequential NFTs
    NonSequentialNFTs = 62742
}

get fun get_collection_data(): RegisterCollectionData {
    throw 0;
}

get fun get_nft_content(index: int257, individual_content: cell): cell {
    throw 0;
}

get fun get_royalty_params(): RegisterRoyaltyParams {
    throw 0;
}

get fun registerCost(symbol_length: int257): int257 {
    throw 0;
}

get fun get_contractInfo_list_by_index(item_index: int257): RegisterAddressList {
    throw 0;
}

get fun get_nft_address_by_index(item_index: int257): address {
    throw 0;
}

get fun get_jettonRoot_minter_by_index(item_index: int257): address {
    throw 0;
}

get fun get_jetton_wallet_address_by_id_owner(item_index: int257, owner: address): address {
    throw 0;
}

get fun get_contractInfo_list_by_tickName(symbol_cell: cell): RegisterAddressList {
    throw 0;
}

get fun get_registerContract_balance(): int257 {
    throw 0;
}
