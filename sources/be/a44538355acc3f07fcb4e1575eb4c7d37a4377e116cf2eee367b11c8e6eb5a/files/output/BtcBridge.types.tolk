// Generated from the verified Tact contract ABI.
contract BtcBridge {
    storage: BtcBridgeData
    incomingMessages: BtcBridgeIncomingMessage
    thrownErrors: BtcBridgeErrors
}

struct (0x819dbe99) BtcBridgeChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x946a98b6) BtcBridgeDeploy {
    queryId: uint64
}

struct (0x8fc87794) BtcBridgeWithDrawConfig {
    withdrawFee: int257
    feeReceiver: address
}

struct (0x99aa734a) BtcBridgeDeployNewBridgeToken {
    content: cell
    max_supply: int257
    symbol: string
}

struct BtcBridgeDeployedJetton {
    symbol: string
    master: address
}

struct (0xd53276db) BtcBridgeTokenExcesses {
    query_id: uint64
}

struct BtcBridgeBridgeBasicInfo {
    owner: address
    tokenDeployer: address
    user0_key: uint256
    tactContinuation: Cell<BtcBridgeBridgeBasicInfoContinuation>
}

struct BtcBridgeBridgeBasicInfoContinuation {
    user1_key: uint256
    user2_key: uint256
}

struct BtcBridgeData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    tokenDeployer: address
    withdrawFee: int257
    tactContinuation: Cell<BtcBridgeDataContinuation>
}

struct BtcBridgeDataContinuation {
    feeReceiver: address
    seqNo: uint64
    user0_key: uint256
    user1_key: uint256
    tactContinuation: Cell<BtcBridgeDataContinuation2>
}

struct BtcBridgeDataContinuation2 {
    user2_key: uint256
    hasMadeClaim: map<int257, bool>
    validtors: map<int257, bool>
    bridgeTokenCount: uint8
    bridgeTokenWhitelist: map<address, bool>
    tactContinuation: Cell<BtcBridgeDataContinuation3>
}

struct BtcBridgeDataContinuation3 {
    bridgeTokenCreated: map<int257, bool>
    symbol2address: map<int257, Cell<BtcBridgeDeployedJetton>>
}

type BtcBridgeIncomingMessage =
    | BtcBridgeDeployNewBridgeToken
    | BtcBridgeTokenExcesses
    | BtcBridgeDeploy
    | BtcBridgeWithDrawConfig
    | BtcBridgeChangeOwner

enum BtcBridgeErrors {
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
    /// Not mintable
    NotMintable = 3688
    /// Same pub keys
    SamePubKeys = 3723
    /// Not Owner
    NotOwner = 3734
    /// Invalid sender
    InvalidSender = 4429
    /// Max supply exceeded
    MaxSupplyExceeded = 12241
    /// Not allowed to create bridge token
    NotAllowedToCreateBridgeToken = 12712
    /// Not owner
    NotOwner2 = 14534
    /// Invalid value
    InvalidValue = 16059
    /// Invalid seqno
    InvalidSeqno = 17654
    /// No jetton created with the input master address
    NoJettonCreatedWithTheInputMasterAddress = 17830
    /// Can't Mint Anymore
    CanTMintAnymore = 18668
    /// Invalid signatures
    InvalidSignatures = 19749
    /// Invalid pub keys
    InvalidPubKeys = 20464
    /// Invalid claimID
    InvalidClaimID = 21107
    /// Insufficient gas
    InsufficientGas = 23951
    /// The same token has been deployed
    TheSameTokenHasBeenDeployed = 36311
    /// Invalid sender!
    InvalidSender2 = 42708
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// Invalid withdrawID
    InvalidWithdrawID = 43721
    /// Invalid balance
    InvalidBalance = 62972
}

get fun seqNo(): int257 {
    throw 0;
}

get fun basicInfo(): BtcBridgeBridgeBasicInfo {
    throw 0;
}

get fun deployedJettonNumber(): int257 {
    throw 0;
}

get fun deployedJettonInfo(index: int257): BtcBridgeDeployedJetton? {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun withDrawFee(): int257 {
    throw 0;
}

get fun withDrawFeeReceiver(): address {
    throw 0;
}
