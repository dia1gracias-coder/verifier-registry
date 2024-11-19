// Generated from the verified Tact contract ABI.
contract JettonMaster {
    storage: JettonMasterData
    incomingMessages: JettonMasterIncomingMessage
    thrownErrors: JettonMasterErrors
}

struct (0x946a98b6) JettonMasterDeploy {
    queryId: uint64
}

struct (0xfc708bd2) JettonMasterMint {
    amount: int257
    receiver: address
}

struct (0x7bdd97de) JettonMasterTokenBurnNotification {
    queryId: uint64
    amount: coins
    owner: address
    response_destination: address?
}

struct (0xaf1ca26a) JettonMasterTokenUpdateContent {
    content: cell
}

struct (0x84e8889e) JettonMasterMintPrivateSale {
    totalSupply: int257
}

struct JettonMasterJettonWalletData {
    totalSupply: int257
    mintable: bool
    owner: address
    content: cell
    walletCode: cell
}

struct JettonMasterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    totalSupply: coins
    owner: address
    content: cell
    mintable: bool
    max_supply: coins
}

type JettonMasterIncomingMessage =
    | JettonMasterMint
    | JettonMasterMintPrivateSale
    | JettonMasterTokenUpdateContent
    | JettonMasterTokenBurnNotification
    | JettonMasterDeploy

enum JettonMasterErrors {
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
    /// Not mintable
    NotMintable = 3688
    /// Invalid value!!
    InvalidValue = 4159
    /// Invalid sender
    InvalidSender = 4429
    /// Sale not started
    SaleNotStarted = 6472
    /// The total supply will be overlapping.
    TheTotalSupplyWillBeOverlapping = 6898
    /// Claim unavalable
    ClaimUnavalable = 9038
    /// Max supply exceeded
    MaxSupplyExceeded = 12241
    /// Claim ended
    ClaimEnded = 13503
    /// Only master
    OnlyMaster = 16588
    /// Can't Mint Anymore
    CanTMintAnymore = 18668
    /// Not enough balance
    NotEnoughBalance = 22565
    /// Invalid Sender
    InvalidSender2 = 23263
    /// Sale ended
    SaleEnded = 26611
    /// Insufficient amount to buy
    InsufficientAmountToBuy = 26739
    /// Cant buy more tokens
    CantBuyMoreTokens = 27653
    /// Claim not started
    ClaimNotStarted = 34419
    /// Contract stopped
    ContractStopped2 = 40368
    /// Invalid sender!
    InvalidSender3 = 42708
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// Master Only
    MasterOnly = 50062
    /// Contract not stopped
    ContractNotStopped = 53296
    /// Insufficient balance
    InsufficientBalance = 54615
    /// Can't buy more than max amount
    CanTBuyMoreThanMaxAmount = 58341
    /// Invalid balance
    InvalidBalance = 62972
}

get fun private_sale_addres(): address {
    throw 0;
}

get fun get_jetton_data(): JettonMasterJettonWalletData {
    throw 0;
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
