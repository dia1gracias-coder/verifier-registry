// Generated from the verified Tact contract ABI.
contract KeyCollection {
    storage: KeyCollectionData
    incomingMessages: KeyCollectionIncomingMessage
    thrownErrors: KeyCollectionErrors
}

struct (0x946a98b6) KeyCollectionDeploy {
    queryId: uint64
}

struct (0x45edf83c) KeyCollectionPurchaseOnekey {
    keyNum: uint8
}

struct (0xd365a68e) KeyCollectionRedeem {
    keyId: uint128
}

struct KeyCollectionKeyInfo {
    owner: address
    keyNum: uint8
    price: uint256
}

struct KeyCollectionData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    keySupply: uint128
    keyShares: uint128
    subKeySharesMap: map<int257, int257>
    owner: address
    vLuckShares: uint256
    vLuckMap: map<int257, int257>
    tactContinuation: Cell<KeyCollectionDataContinuation>
}

struct KeyCollectionDataContinuation {
    rewardPreVluck: uint256
    uservLuckMap: map<address, int257>
    userAwardMap: map<address, int257>
    keyInfoMap: map<int257, Cell<KeyCollectionKeyInfo>>
    luckNum: uint8
    tactContinuation: Cell<KeyCollectionDataContinuation2>
}

struct KeyCollectionDataContinuation2 {
    userWalletMap: map<address, int257>
}

type KeyCollectionIncomingMessage =
    | KeyCollectionPurchaseOnekey
    | KeyCollectionRedeem
    | KeyCollectionDeploy

enum KeyCollectionErrors {
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
    /// Only owner can redeem
    OnlyOwnerCanRedeem = 45456
}

get fun currentPrice(): int257 {
    throw 0;
}

// Tact getter name: random
// Tact method ID: 92013
get fun random_(): int257 {
    throw 0;
}

get fun uservLuck(user: address): int257 {
    throw 0;
}

get fun keySupply(): int257 {
    throw 0;
}

get fun keyInfoById(id: int257): KeyCollectionKeyInfo? {
    throw 0;
}

get fun vLuckShares(): int257 {
    throw 0;
}

get fun vLuckByNum(num: int257): int257 {
    throw 0;
}

get fun luckNum(): int257 {
    throw 0;
}

get fun userAward(user: address): int257? {
    throw 0;
}

get fun rewardPreVluck(): int257 {
    throw 0;
}

get fun userWallet(user: address): int257? {
    throw 0;
}
