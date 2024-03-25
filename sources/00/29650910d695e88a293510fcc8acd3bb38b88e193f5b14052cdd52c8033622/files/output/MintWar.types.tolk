// Generated from the verified Tact contract ABI.
contract MintWar {
    storage: MintWarData
    incomingMessages: MintWarMintJetton
    thrownErrors: MintWarErrors
}

struct (0x2a5bdc04) MintWarMintJetton {
    rate: uint256
}

struct MintWarAccountState {
    points: uint256
    fees: uint256
    totalPoints: uint256
    tactContinuation: Cell<MintWarAccountStateContinuation>
}

struct MintWarAccountStateContinuation {
    totalFees: uint256
}

struct MintWarData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    admin: address
    mintStartAt: int257
    mintEndAt: int257
    tactContinuation: Cell<MintWarDataContinuation>
}

struct MintWarDataContinuation {
    totalPoints: uint256
    totalFees: uint256
    pointsOf: map<address, uint256>
    feesOf: map<address, uint256>
}

enum MintWarErrors {
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
    /// Mint not start
    MintNotStart = 6852
    /// Mint ended
    MintEnded = 29082
    /// Invalid rate
    InvalidRate = 40176
    /// Insufficient fee
    InsufficientFee = 55259
    /// Only owner can claim fee
    OnlyOwnerCanClaimFee = 59445
}

get fun get_points_by_address(address: address): int257 {
    throw 0;
}

get fun get_shares_by_address(address: address): int257 {
    throw 0;
}

get fun get_totalPoints(): int257 {
    throw 0;
}

get fun get_all_accounts(): map<address, uint256> {
    throw 0;
}

get fun get_account_state(address: address): MintWarAccountState {
    throw 0;
}
