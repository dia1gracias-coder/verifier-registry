// Generated from the verified Tact contract ABI.
contract QstMeSponsorsMain {
    storage: QstMeSponsorsMainData
    incomingMessages: QstMeSponsorsMainIncomingMessage
    thrownErrors: QstMeSponsorsMainErrors
}

struct (0x946a98b6) QstMeSponsorsMainDeploy {
    queryId: uint64
}

struct (0x819dbe99) QstMeSponsorsMainChangeOwner {
    queryId: uint64
    newOwner: address
}

struct QstMeSponsorsMainBalance {
    ton: coins
    usdt: coins
}

struct (0xefb58f85) QstMeSponsorsMainGrantOperator {
    address: address
}

struct (0x4c84e793) QstMeSponsorsMainRevokeOperator {
    address: address
}

struct (0xd58f9b58) QstMeSponsorsMainRegisterSponsor {
    id: uint64
}

struct (0xc3ce98d2) QstMeSponsorsMainWithdrawProtocolTon {
    address: address
}

struct (0xdcec4c31) QstMeSponsorsMainWithdrawProtocolUSDT {
    address: address
}

struct (0x7c17728c) QstMeSponsorsMainRewardUserTon {
    address: address
    amount: coins
}

struct (0x92aaef11) QstMeSponsorsMainRewardUserUSDT {
    address: address
    amount: coins
}

struct (0x6c4ec0cc) QstMeSponsorsMainSetUSDTWallet {
    address: address
}

struct (0x7014340d) QstMeSponsorsMainApproveSponsorship {
    sponsor: uint64
    amount: QstMeSponsorsMainBalance
}

struct (0x7362d09c) QstMeSponsorsMainJettonTransferNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

struct QstMeSponsorsMainData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    operators: map<address, bool>
    protocol_balance: QstMeSponsorsMainBalance
    community_balance: QstMeSponsorsMainBalance
    tactContinuation: Cell<QstMeSponsorsMainDataContinuation>
}

struct QstMeSponsorsMainDataContinuation {
    usdt_wallet: address
}

type QstMeSponsorsMainIncomingMessage =
    | QstMeSponsorsMainRegisterSponsor
    | QstMeSponsorsMainWithdrawProtocolTon
    | QstMeSponsorsMainWithdrawProtocolUSDT
    | QstMeSponsorsMainRewardUserTon
    | QstMeSponsorsMainRewardUserUSDT
    | QstMeSponsorsMainSetUSDTWallet
    | QstMeSponsorsMainApproveSponsorship
    | QstMeSponsorsMainJettonTransferNotification
    | QstMeSponsorsMainDeploy
    | QstMeSponsorsMainChangeOwner
    | QstMeSponsorsMainGrantOperator
    | QstMeSponsorsMainRevokeOperator

enum QstMeSponsorsMainErrors {
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
    /// Only main contract can register sponsorship
    OnlyMainContractCanRegisterSponsorship = 2096
    /// OperatorControl: caller is not an operator
    OperatorControlCallerIsNotAnOperator = 9597
    /// Invalid sponsor id
    InvalidSponsorId = 10968
    /// Only owner can set USDT wallet
    OnlyOwnerCanSetUSDTWallet = 11981
    /// Only appropriate sponsor contract can approve sponsorship
    OnlyAppropriateSponsorContractCanApproveSponsorship = 47928
    /// Only USDT Jetton notifications are acceptable
    OnlyUSDTJettonNotificationsAreAcceptable = 51832
    /// Only owner can register sponsors
    OnlyOwnerCanRegisterSponsors = 63770
}

get fun sponsorContractAddress(id: int257): address {
    throw 0;
}

get fun getCommunityBalance(): QstMeSponsorsMainBalance {
    throw 0;
}

get fun getProtocolBalance(): QstMeSponsorsMainBalance {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun isOperator(address: address): bool {
    throw 0;
}
