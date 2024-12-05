// Generated from the verified Tact contract ABI.
contract JettonMinter {
    storage: JettonMinterData
    incomingMessages: JettonMinterIncomingMessage
    thrownErrors: JettonMinterErrors
}

struct (0x819dbe99) JettonMinterChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x946a98b6) JettonMinterDeploy {
    queryId: uint64
}

struct (0xaf1ca26a) JettonMinterTokenUpdateContent {
    content: cell
}

struct (0x7bdd97de) JettonMinterTokenBurnNotification {
    query_id: uint64
    amount: coins
    sender: address
    response_destination: address
}

struct (0x2c76b973) JettonMinterProvideWalletAddress {
    query_id: uint64
    owner_address: address
    include_address: bool
}

struct (0xfc708bd2) JettonMinterMint {
    amount: int257
    receiver: address
}

struct JettonMinterJettonMasterState {
    totalSupply: coins
    mintable: bool
    adminAddress: address
    jettonContent: cell
    jettonWalletCode: cell
}

struct JettonMinterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    totalSupply: coins
    mintable: bool
    owner: address
    jettonContent: cell
    jettonWalletCode: cell
}

type JettonMinterIncomingMessage =
    | JettonMinterTokenBurnNotification
    | JettonMinterTokenUpdateContent
    | JettonMinterProvideWalletAddress
    | JettonMinterMint
    | JettonMinterChangeOwner
    | JettonMinterDeploy

enum JettonMinterErrors {
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
    /// Too little TONs for gas attached
    TooLittleTONsForGasAttached = 13140
    /// Unsufficient amount of TON attached
    UnsufficientAmountOfTONAttached = 15606
    /// Insufficient gas
    InsufficientGas = 23951
    /// Sender is not another JettonWallet or JettonMaster
    SenderIsNotAnotherJettonWalletOrJettonMaster = 30948
    /// Not wallet owner
    NotWalletOwner = 42487
    /// Invalid balance after burn
    InvalidBalanceAfterBurn = 57978
    /// Invalid workchain of destination address
    InvalidWorkchainOfDestinationAddress = 60555
    /// Invalid balance
    InvalidBalance = 62972
}

get fun get_jetton_data(): JettonMinterJettonMasterState {
    throw 0;
}

get fun get_wallet_address(ownerAddress: address): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
