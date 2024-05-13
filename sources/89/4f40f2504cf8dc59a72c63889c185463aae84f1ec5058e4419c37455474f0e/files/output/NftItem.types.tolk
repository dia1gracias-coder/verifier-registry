// Generated from the verified Tact contract ABI.
contract NftItem {
    storage: NftItemData
    incomingMessages: NftItemIncomingMessage
    thrownErrors: NftItemErrors
}

struct NftItemNftData {
    deployed: bool
    index: int257
    collection: address
    owner: address
    content: cell
}

struct NftItemNftRoyaltyParams {
    numerator: int257
    denominator: int257
    royalty_destination: address
}

struct (0x5fcc3d14) NftItemNftTransfer {
    query_id: uint64
    new_owner: address
    response_destination: address
    custom_payload: cell?
    forward_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct (0x2fcb26a2) NftItemNftGetStaticData {
    query_id: uint64
}

struct (0x693d3950) NftItemNftGetRoyaltyParams {
    query_id: uint64
}

struct (0x1f04537a) NftItemNftDestroy {
    query_id: uint64
}

struct (0x8de43f1e) NftItemNftDeploy {
    owner: address
    content: cell
    lastOwner: address
}

struct (0x0ba69751) NftItemWithdraw {
    amount: coins
}

struct NftItemData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    deployed: bool
    collection: address
    owner: address
    index: uint256
    content: cell
    tactContinuation: Cell<NftItemDataContinuation>
}

struct NftItemDataContinuation {
    royalty_destination: address
    numerator: uint16
    denominator: uint16
}

type NftItemIncomingMessage =
    | NftItemNftDeploy
    | NftItemNftDestroy
    | NftItemWithdraw
    | NftItemNftTransfer
    | NftItemNftGetStaticData
    | NftItemNftGetRoyaltyParams

enum NftItemErrors {
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
    /// Not Deployed
    NotDeployed = 11850
    /// Wrong amount
    WrongAmount = 18451
    /// Invalid Sender
    InvalidSender = 23263
    /// wrong amount of tons
    WrongAmountOfTons = 37956
    /// Invalid Owner
    InvalidOwner = 42491
    /// Invalid Index
    InvalidIndex = 44083
    /// Already Deployed
    AlreadyDeployed = 50324
    /// Not an owner
    NotAnOwner = 56837
}

get fun get_nft_data(): NftItemNftData {
    throw 0;
}

get fun royalty_params(): NftItemNftRoyaltyParams {
    throw 0;
}
