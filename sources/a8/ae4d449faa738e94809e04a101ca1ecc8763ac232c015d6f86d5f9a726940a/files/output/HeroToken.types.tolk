// Generated from the verified Tact contract ABI.
contract HeroToken {
    storage: HeroTokenData
    incomingMessages: HeroTokenIncomingMessage
    thrownErrors: HeroTokenErrors
}

struct (0x819dbe99) HeroTokenChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x946a98b6) HeroTokenDeploy {
    queryId: uint64
}

struct (0x5a909f07) HeroTokenMint {
    amount: int257
    to: address
}

struct (0xfd6261c3) HeroTokenUpdateContent {
    content: cell
}

struct (0x7bdd97de) HeroTokenBurnNotification {
    query_id: uint64
    amount: coins
    owner: address
    response_destination: address?
}

struct HeroTokenJettonData {
    owner: address
    content: cell
    mintable: bool
    totalSupply: int257
    walletCode: cell
}

struct HeroTokenData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    content: cell
    mintable: bool
    totalSupply: coins
    maxSupply: coins
}

type HeroTokenIncomingMessage =
    | HeroTokenMint
    | HeroTokenUpdateContent
    | HeroTokenBurnNotification
    | HeroTokenDeploy
    | HeroTokenChangeOwner

enum HeroTokenErrors {
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
    /// Token burn notification: Invalid sender
    TokenBurnNotificationInvalidSender = 1898
    /// Token mint: Max supply exceeded
    TokenMintMaxSupplyExceeded = 2461
    /// Token burn: Invalid sender
    TokenBurnInvalidSender = 4796
    /// Token transfer internal: Invalid sender
    TokenTransferInternalInvalidSender = 9944
    /// Token burn: Insufficient value
    TokenBurnInsufficientValue = 11259
    /// Token transfer internal: Insufficient balance
    TokenTransferInternalInsufficientBalance = 15236
    /// Token burn: Invalid balance
    TokenBurnInvalidBalance = 16931
    /// Token mint: Minting forbidden
    TokenMintMintingForbidden = 32425
    /// Token transfer: Insufficient balance
    TokenTransferInsufficientBalance = 40578
    /// Token transfer: Insufficient value
    TokenTransferInsufficientValue = 46739
    /// Token transfer: Invalid sender
    TokenTransferInvalidSender = 47602
}

get fun get_jetton_data(): HeroTokenJettonData {
    throw 0;
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
