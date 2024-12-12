// Generated from the verified Tact contract ABI.
contract StakeContract {
    storage: StakeContractData
    incomingMessages: StakeContractIncomingMessage
    thrownErrors: StakeContractErrors
}

struct (0x819dbe99) StakeContractChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x7362d09c) StakeContractTokenNotification {
    queryId: uint64
    amount: coins
    from: address
    forward_payload: RemainingBitsAndRefs
}

struct (0x230f429f) StakeContractTokenWithdraw {
    ton_amount: coins
    forward_ton_amount: coins
    token_amount: coins
    user_address: address
}

struct (0xb06d3544) StakeContractChangeJettonWalletAddress {
    queryId: uint64
    newJettonWalletAddress: address
}

struct (0x8827c925) StakeContractChangeBill {
    user_id: uint64
    amount: uint64
}

struct StakeContractUserData {
    amount: uint64
    settled_amount: uint64
}

struct (0xcf07cad3) StakeContractChangeBills {
    users: map<int257, int257>
}

struct (0x740884f6) StakeContractSettleBill {
    user_id: uint64
    user_address: address
}

struct StakeContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    myJettonWalletAddress: address?
    bill_list: map<int257, Cell<StakeContractUserData>>
}

type StakeContractIncomingMessage =
    | StakeContractChangeJettonWalletAddress
    | StakeContractTokenNotification
    | StakeContractChangeBill
    | StakeContractChangeBills
    | StakeContractSettleBill
    | StakeContractTokenWithdraw
    | StakeContractChangeOwner

enum StakeContractErrors {
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
    /// Invalid user
    InvalidUser = 2844
    /// Invalid settle amount
    InvalidSettleAmount = 59670
}

get fun allBills(): map<int257, Cell<StakeContractUserData>> {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
