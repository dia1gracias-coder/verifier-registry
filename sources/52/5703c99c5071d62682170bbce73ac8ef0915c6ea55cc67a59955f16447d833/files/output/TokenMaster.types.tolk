// Generated from the verified Tact contract ABI.
contract TokenMaster {
    storage: TokenMasterData2
    incomingMessages: TokenMasterIncomingMessage
    thrownErrors: TokenMasterErrors
}

struct (0x819dbe99) TokenMasterChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x946a98b6) TokenMasterDeploy {
    queryId: uint64
}

struct (0xd1735400) TokenMasterTakeWalletAddress {
    query_id: uint64
    wallet_address: address
    owner_address: cell?
}

struct TokenMasterData {
    owner: address
    jetton_wallet: address
    master: address
}

struct TokenMasterData2 {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    master: address
    jetton_wallet: address
    active: bool
}

type TokenMasterIncomingMessage =
    | TokenMasterTakeWalletAddress
    | TokenMasterChangeOwner
    | TokenMasterDeploy

enum TokenMasterErrors {
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
    /// Off
    Off = 1692
    /// Invalid sender
    InvalidSender = 4429
    /// Not owner
    NotOwner = 14534
    /// Balance
    Balance = 17287
    /// Small amount
    SmallAmount = 38885
}

get fun data(): TokenMasterData {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
