// Generated from the verified Tact contract ABI.
contract CTonMint {
    storage: CTonMintData
    incomingMessages: CTonMintIncomingMessage
    thrownErrors: CTonMintErrors
}

struct (0x946a98b6) CTonMintDeploy {
    queryId: uint64
}

struct (0xe21f25d5) CTonMintTokenWithdraw {
    amount: uint256
    jettonWalletAddress: address
    receiver: address
}

struct (0x2fb545d1) CTonMintPublicMintMessage {
    amount: uint256
    receiver: address
    jettonWalletAddress: address
}

struct (0xf23e801c) CTonMintUpdateWlSignKey {
    pKey: uint256
}

struct CTonMintMintInfo {
    owner: address
    wlSignKey: uint256
    totalWlMintAmount: uint256
    tactContinuation: Cell<CTonMintMintInfoContinuation>
}

struct CTonMintMintInfoContinuation {
    totalPublicMintAmount: uint256
    totalMintAmount: uint256
    wlMintMinAmount: uint32
    wlMintMaxAmount: uint32
    publicMintMinAmount: uint32
    wlMintTonPrice: int257
    tactContinuation: Cell<CTonMintMintInfoContinuation2>
}

struct CTonMintMintInfoContinuation2 {
    publicMintTonPrice: int257
}

struct CTonMintData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    wlMintTonPrice: int257
    publicMintTonPrice: int257
    owner: address
    tactContinuation: Cell<CTonMintDataContinuation>
}

struct CTonMintDataContinuation {
    wlSignKey: uint256
    seqnoMap: map<address, int257>
    wlMintAmountMap: map<address, int257>
    publicMintAmountMap: map<address, int257>
    totalWlMintAmount: uint256
    totalPublicMintAmount: uint256
    tactContinuation: Cell<CTonMintDataContinuation2>
}

struct CTonMintDataContinuation2 {
    totalMintAmount: uint256
    wlMintMinAmount: uint32
    wlMintMaxAmount: uint32
    publicMintMinAmount: uint32
    publicMintMaxAmount: uint32
}

type CTonMintIncomingMessage =
    | CTonMintUpdateWlSignKey
    | CTonMintPublicMintMessage
    | CTonMintTokenWithdraw
    | CTonMintDeploy

enum CTonMintErrors {
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
    /// wrong receiver
    WrongReceiver = 13458
    /// Not owner
    NotOwner = 14534
    /// Invalid value
    InvalidValue = 16059
    /// wrong seqno
    WrongSeqno = 18445
    /// Max total amount limit
    MaxTotalAmountLimit = 41419
    /// Max amount limit
    MaxAmountLimit = 42659
    /// Only owner can update public key
    OnlyOwnerCanUpdatePublicKey = 46826
    /// Min amount limit
    MinAmountLimit = 47896
    /// Invalid signature
    InvalidSignature = 48401
    /// Only owner can claim fee
    OnlyOwnerCanClaimFee = 59445
}

get fun mintInfo(): CTonMintMintInfo {
    throw 0;
}

get fun whitelistAmountByAddress(userAddr: address): int257 {
    throw 0;
}

get fun publicAmountByAddress(userAddr: address): int257 {
    throw 0;
}
