// Generated from the verified Tact contract ABI.
contract Satoshi {
    storage: SatoshiData
    incomingMessages: SatoshiIncomingMessage
    thrownErrors: SatoshiErrors
}

struct (0x946a98b6) SatoshiDeploy {
    queryId: uint64
}

struct (0x819dbe99) SatoshiChangeOwner {
    queryId: uint64
    newOwner: address
}

struct SatoshiMiningParams {
    last_block: uint32
    last_block_time: uint32
    attempts: uint16
    subsidy: coins
    probability: uint8
}

struct SatoshiJettonData {
    total_supply: int257
    mintable: bool
    owner: address
    content: cell
    wallet_code: cell
}

struct (0x7bdd97de) SatoshiTokenBurnNotification {
    query_id: uint64
    amount: coins
    sender: address
    response_destination: address
}

struct (0x00000004) SatoshiTokenUpdateContent {
    content: cell
}

struct (0xe9b94603) SatoshiMine {
    receiver: address
}

struct (0x2c76b973) SatoshiProvideWalletAddress {
    query_id: uint64
    owner_address: address
    include_address: bool
}

struct SatoshiData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    max_supply: coins
    mintable: bool
    total_supply: coins
    owner: address
    content: cell
    block: uint32
    time: uint32
    attempts: uint16
}

type SatoshiIncomingMessage =
    | SatoshiMine
    | SatoshiTokenUpdateContent
    | SatoshiTokenBurnNotification
    | SatoshiProvideWalletAddress
    | SatoshiChangeOwner
    | SatoshiDeploy

enum SatoshiErrors {
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
    /// Insufficient value
    InsufficientValue = 2805
    /// Invalid sender
    InvalidSender = 4429
    /// Insufficient gas
    InsufficientGas = 23951
    /// Can't mint more than max supply
    CanTMintMoreThanMaxSupply = 49626
    /// Insufficient funds for operation
    InsufficientFundsForOperation = 57532
}

get fun get_mining_data(): SatoshiMiningParams {
    throw 0;
}

get fun get_mining_probability(minutes: int257, attempts: int257): int257 {
    throw 0;
}

get fun get_jetton_data(): SatoshiJettonData {
    throw 0;
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
