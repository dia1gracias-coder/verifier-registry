// Generated from the verified Tact contract ABI.
contract QstMeRewards {
    storage: QstMeRewardsData
    incomingMessages: QstMeRewardsIncomingMessage
    thrownErrors: QstMeRewardsErrors
}

struct (0x946a98b6) QstMeRewardsDeploy {
    queryId: uint64
}

struct (0x819dbe99) QstMeRewardsChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x23799c2a) QstMeRewardsUpgradeContract {
    code: cell
    data: cell?
}

struct (0xefb58f85) QstMeRewardsGrantOperator {
    address: address
}

struct (0x4c84e793) QstMeRewardsRevokeOperator {
    address: address
}

struct (0x25ca8dc6) QstMeRewardsAcceptPubKey {
    pubKey: int257
}

struct (0x8318ca18) QstMeRewardsRevokePubKey {
    pubKey: int257
}

struct (0x7df857f2) QstMeRewardsResetNonce {
}

struct (0x7d6264ab) QstMeRewardsRewardUser {
    reward: QstMeRewardsUserReward
}

struct (0x7d900c0b) QstMeRewardsRewardUsers {
    rewards: QstMeRewardsRewardsArray
}

struct QstMeRewardsUserReward {
    user: address
    jettonWallet: address?
    amount: coins
}

struct QstMeRewardsRewardsArray {
    e: map<int257, Cell<QstMeRewardsUserReward>>
    length: int257
}

struct QstMeRewardsData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    operators: map<address, bool>
    pubKeys: map<int257, bool>
    nonce: int257
}

type QstMeRewardsIncomingMessage =
    | QstMeRewardsRewardUser
    | QstMeRewardsRewardUsers
    | QstMeRewardsDeploy
    | QstMeRewardsChangeOwner
    | QstMeRewardsUpgradeContract
    | QstMeRewardsGrantOperator
    | QstMeRewardsRevokeOperator
    | QstMeRewardsAcceptPubKey
    | QstMeRewardsRevokePubKey
    | QstMeRewardsResetNonce

enum QstMeRewardsErrors {
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
    /// OperatorControl: caller is not an owner
    OperatorControlCallerIsNotAnOwner = 6115
    /// No items in the array!
    NoItemsInTheArray = 6947
    /// OperatorControl: caller is not an operator
    OperatorControlCallerIsNotAnOperator = 9597
    /// RewardUserSigned: invalid signature
    RewardUserSignedInvalidSignature = 11159
    /// Index of the item cannot be negative!
    IndexOfTheItemCannotBeNegative = 19333
    /// NonceControl: nonce collision
    NonceControlNonceCollision = 20873
    /// Index is out of array bounds!
    IndexIsOutOfArrayBounds = 24006
    /// PubKeysControl: caller is not an owner
    PubKeysControlCallerIsNotAnOwner = 24955
    /// PubKeysControl: public key is not accepted
    PubKeysControlPublicKeyIsNotAccepted = 35631
    /// OperatorControl: caller is neither owner nor operator
    OperatorControlCallerIsNeitherOwnerNorOperator = 51333
    /// Upgradable: Sender is not a contract owner
    UpgradableSenderIsNotAContractOwner = 51409
    /// RewardUserSigned: timestamp is too old
    RewardUserSignedTimestampIsTooOld = 53442
    /// NonceControl: caller is not an owner
    NonceControlCallerIsNotAnOwner = 63183
}

get fun owner(): address {
    throw 0;
}

get fun isOperator(address: address): bool {
    throw 0;
}

get fun checkPubKey(pubKey: int257): bool {
    throw 0;
}

get fun hashWithDomain(data: cell): int257 {
    throw 0;
}

get fun nonce(): int257 {
    throw 0;
}
