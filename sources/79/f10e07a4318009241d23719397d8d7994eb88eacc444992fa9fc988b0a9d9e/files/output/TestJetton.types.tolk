// Generated from the verified Tact contract ABI.
contract TestJetton {
    storage: TestJettonData
    incomingMessages: TestJettonIncomingMessage
    thrownErrors: TestJettonErrors
}

struct (0xfc708bd2) TestJettonMint {
    amount: int257
    receiver: address
}

struct TestJettonJettonData {
    totalSupply: int257
    mintable: bool
    owner: address
    content: cell
    walletCode: cell
}

struct (0x7bdd97de) TestJettonTokenBurnNotification {
    queryId: uint64
    amount: coins
    owner: address
    response_destination: address?
}

struct (0xaf1ca26a) TestJettonTokenUpdateContent {
    content: cell
}

struct TestJettonData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    totalSupply: coins
    owner: address
    content: cell
    mintable: bool
    max_supply: coins
}

type TestJettonIncomingMessage =
    | TestJettonMint
    | TestJettonTokenUpdateContent
    | TestJettonTokenBurnNotification

enum TestJettonErrors {
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
    /// Not Owner
    NotOwner = 3734
    /// Invalid sender
    InvalidSender = 4429
    /// The total supply will be overlapping.
    TheTotalSupplyWillBeOverlapping = 6898
    /// Can't Mint Anymore
    CanTMintAnymore = 18668
    /// Invalid sender!
    InvalidSender2 = 42708
    /// Invalid balance
    InvalidBalance = 62972
}

get fun get_jetton_data(): TestJettonJettonData {
    throw 0;
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
