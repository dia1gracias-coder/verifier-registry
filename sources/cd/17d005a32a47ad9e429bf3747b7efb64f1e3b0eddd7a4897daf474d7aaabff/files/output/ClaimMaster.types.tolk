// Generated from the verified Tact contract ABI.
contract ClaimMaster {
    storage: ClaimMasterData
    incomingMessages: ClaimMasterIncomingMessage
    thrownErrors: ClaimMasterErrors
}

struct (0x946a98b6) ClaimMasterDeploy {
    queryId: uint64
}

struct (0x819dbe99) ClaimMasterChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x00000001) ClaimMasterMintChild {
    user: address
    referrer: address?
}

struct (0x00000002) ClaimMasterClaim {
    amount: coins
    boost: coins
    user: address
    referrer: address?
}

struct (0x00000006) ClaimMasterOwnerWithdrawalRequest {
    amount: coins
    tokenAddress: address
}

struct (0x00000007) ClaimMasterOwnerWithdrawalTonRequest {
}

struct (0x00000008) ClaimMasterTokenConfig {
    tokenAddress: address
    claimAmount: coins
    referralReward: coins
    boostReward: coins
}

struct (0x00000009) ClaimMasterCustomMessage {
    to: address
    payload: cell?
}

struct (0x7362d09c) ClaimMasterTokenNotification {
    queryId: uint64
    amount: coins
    from: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0xd53276db) ClaimMasterTokenExcesses {
    queryId: uint64
}

struct ClaimMasterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    queryId: uint64
    tokenAddress: address?
    randomSecure: uint64
    interval: uint32
    owner: address
    master: address
    tactContinuation: Cell<ClaimMasterDataContinuation>
}

struct ClaimMasterDataContinuation {
    claimAmount: int257
    referralReward: int257
    boostReward: int257
}

type ClaimMasterIncomingMessage =
    | ClaimMasterChangeOwner
    | ClaimMasterCustomMessage
    | ClaimMasterTokenNotification
    | ClaimMasterMintChild
    | ClaimMasterClaim
    | ClaimMasterTokenConfig
    | ClaimMasterTokenExcesses
    | ClaimMasterOwnerWithdrawalTonRequest
    | ClaimMasterOwnerWithdrawalRequest
    | ClaimMasterDeploy

enum ClaimMasterErrors {
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
}

get fun interval(): int257 {
    throw 0;
}

get fun tokenAddress(): address? {
    throw 0;
}

get fun queryId(): int257 {
    throw 0;
}

get fun get_user_address(user: address): address {
    throw 0;
}

get fun claimAmount(): int257 {
    throw 0;
}

get fun referralReward(): int257 {
    throw 0;
}

get fun boostReward(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
