// Generated from the verified Tact contract ABI.
contract SampleJetton {
    storage: SampleJettonData2
    incomingMessages: SampleJettonIncomingMessage
    thrownErrors: SampleJettonErrors
}

struct (0x7bdd97de) SampleJettonTokenBurnNotification {
    queryId: uint64
    amount: coins
    owner: address
    responseAddress: address?
}

struct (0x0c087a9e) SampleJettonTokenUpdateContent {
    content: cell?
}

struct SampleJettonJettonData {
    totalSupply: int257
    mintable: bool
    owner: address
    content: cell?
    walletCode: cell
}

struct SampleJettonData {
    totalSupply: int257
    availableBalance: int257
    price: int257
    mintable: bool
    tactContinuation: Cell<SampleJettonDataContinuation>
}

struct SampleJettonDataContinuation {
    owner: address
    content: cell?
    walletCode: cell
}

struct (0xfc708bd2) SampleJettonMint {
    amount: int257
    receiver: address
}

struct (0xca2c14e7) SampleJettonSetPrice {
    amount: int257
}

struct (0xf9294621) SampleJettonWithdraw {
    amount: int257
    to: address?
}

struct SampleJettonData2 {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    totalSupply: coins
    owner: address
    content: cell?
    mintable: bool
    price: coins
    availableBalance: coins
}

type SampleJettonIncomingMessage =
    | SampleJettonMint
    | SampleJettonSetPrice
    | SampleJettonWithdraw
    | SampleJettonTokenUpdateContent
    | SampleJettonTokenBurnNotification

enum SampleJettonErrors {
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
    /// Invalid value!!
    InvalidValue = 4159
    /// Invalid sender
    InvalidSender = 4429
    /// Only Owner
    OnlyOwner = 6141
    /// Target Amount is not Enough
    TargetAmountIsNotEnough = 7421
    /// Invalid bounced message
    InvalidBouncedMessage = 13650
    /// Invalid value
    InvalidValue2 = 16059
    /// Mintable is Disabled
    MintableIsDisabled = 41245
    /// Mintable is Disabled Already
    MintableIsDisabledAlready = 41480
    /// Over Amount
    OverAmount = 47904
    /// Balance is not Enough
    BalanceIsNotEnough = 53558
    /// Invalid Price!
    InvalidPrice = 55135
    /// Invalid Balance
    InvalidBalance = 61019
    /// Invalid balance
    InvalidBalance2 = 62972
}

get fun balance(): int257 {
    throw 0;
}

get fun sample_jetton_data(): SampleJettonData {
    throw 0;
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}

get fun get_jetton_data(): SampleJettonJettonData {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
