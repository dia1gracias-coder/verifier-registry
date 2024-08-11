// Generated from the verified Tact contract ABI.
contract MintManager {
    storage: MintManagerData
    incomingMessages: MintManagerIncomingMessage
    thrownErrors: MintManagerErrors
}

struct (0x56e8229b) MintManagerAddTowhitelist {
    id: uint64
    whitelistThis: address
}

struct (0x819dbe99) MintManagerChangeOwner {
    queryId: uint64
    newOwner: address
}

struct MintManagerData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    cards_content: string
    pets_content: string
}

type MintManagerIncomingMessage =
    | MintManagerAddTowhitelist
    | MintManagerChangeOwner

enum MintManagerErrors {
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
    /// MakeWhitelist : Access denied
    MakeWhitelistAccessDenied = 5163
    /// MintMsg : Access denied
    MintMsgAccessDenied = 7813
    /// initialized tx need from collection
    InitializedTxNeedFromCollection = 27499
    /// not from collection check again
    NotFromCollectionCheckAgain = 39039
    /// Access denied on init
    AccessDeniedOnInit = 45058
    /// not owner
    NotOwner = 49280
    /// Only owner can mint
    OnlyOwnerCanMint = 57579
    /// non-sequential NFTs
    NonSequentialNFTs = 62742
}

get fun get_whitelist_info_address(whitelisted: address, id: int257): address? {
    throw 0;
}

get fun get_collection_test_cards(): address {
    throw 0;
}

get fun get_collection_test_pets(): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
