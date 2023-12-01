// Generated from the verified Tact contract ABI.
contract TokenDistributionParent {
    storage: TokenDistributionParentData
    incomingMessages: TokenDistributionParentIncomingMessage
    thrownErrors: TokenDistributionParentErrors
}

struct (0x946a98b6) TokenDistributionParentDeploy {
    queryId: uint64
}

struct (0x8c7991ee) TokenDistributionParentTokenClaimRequest {
    user: address
    seqno: uint64
}

struct (0x5bf598cc) TokenDistributionParentOwnerWithdrawalRequest {
    to: address
}

struct (0x178d4519) TokenDistributionParentTokenNotification {
    queryId: uint64
    amount: coins
    from: address
    responseDestination: address
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

struct TokenDistributionParentData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    tokenAddress: address
    supply: coins
    claimAmount: coins
    tactContinuation: Cell<TokenDistributionParentDataContinuation>
}

struct TokenDistributionParentDataContinuation {
    claimInterval: int257
    seqno: uint64
    claimed: int257
}

type TokenDistributionParentIncomingMessage =
    | TokenDistributionParentTokenClaimRequest
    | TokenDistributionParentOwnerWithdrawalRequest
    | TokenDistributionParentTokenNotification
    | TokenDistributionParentDeploy

enum TokenDistributionParentErrors {
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
    /// Unauthorized request
    UnauthorizedRequest = 6635
    /// Access denied
    AccessDenied2 = 49469
    /// Supply empty
    SupplyEmpty = 49826
    /// Claim interval not met
    ClaimIntervalNotMet = 50302
}

get fun claimInterval(): int257 {
    throw 0;
}

get fun claimAmount(): int257 {
    throw 0;
}

get fun supply(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun claimed(): int257 {
    throw 0;
}

get fun childAddress(user: address): address {
    throw 0;
}
