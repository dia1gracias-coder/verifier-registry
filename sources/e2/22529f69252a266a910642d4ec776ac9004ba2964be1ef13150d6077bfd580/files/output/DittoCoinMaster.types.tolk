// Generated from the verified Tact contract ABI.
contract DittoCoinMaster {
    storage: DittoCoinMasterData
    incomingMessages: DittoCoinMasterIncomingMessage
    thrownErrors: DittoCoinMasterErrors
}

struct DittoCoinMasterJettonData {
    totalSupply: int257
    mintable: bool
    owner: address
    content: cell?
    walletCode: cell
}

struct (0x0c087a9e) DittoCoinMasterTokenUpdateContent {
    content: cell?
}

struct (0x7bdd97de) DittoCoinMasterTokenBurnNotification {
    queryId: uint64
    amount: coins
    owner: address
    responseAddress: address?
}

struct (0x819dbe99) DittoCoinMasterChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x98b1748d) DittoCoinMasterMint {
    recipient: address
    amount: coins
}

struct DittoCoinMasterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    totalSupply: int257
    mintable: bool
    owner: address
    content: cell?
}

type DittoCoinMasterIncomingMessage =
    | DittoCoinMasterMint
    | DittoCoinMasterTokenUpdateContent
    | DittoCoinMasterTokenBurnNotification
    | DittoCoinMasterChangeOwner

enum DittoCoinMasterErrors {
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
    /// Invalid sender
    InvalidSender = 4429
    /// Invalid bounced message
    InvalidBouncedMessage = 13650
    /// Invalid value
    InvalidValue = 16059
    /// Can't Mint Anymore
    CanTMintAnymore = 18668
    /// Invalid balance
    InvalidBalance = 62972
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}

get fun get_jetton_data(): DittoCoinMasterJettonData {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
