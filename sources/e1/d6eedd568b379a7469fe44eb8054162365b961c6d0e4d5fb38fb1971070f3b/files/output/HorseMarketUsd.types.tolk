// Generated from the verified Tact contract ABI.
contract HorseMarketUsd {
    storage: HorseMarketUsdData
    incomingMessages: HorseMarketUsdIncomingMessage
    thrownErrors: HorseMarketUsdErrors
}

struct (0x946a98b6) HorseMarketUsdDeploy {
    queryId: uint64
}

struct (0x7362d09c) HorseMarketUsdTokenNotification {
    queryId: uint64
    amount: coins
    from: address
    forward_payload: RemainingBitsAndRefs
}

struct (0x022702dd) HorseMarketUsdAddingJettonAddress {
    this_contract_jettonWallet: address
}

struct (0x8515738f) HorseMarketUsdUnstake {
    index_id: uint32
}

struct (0x134c687a) HorseMarketUsdGetWeighted {
    applied_user_address: address
}

struct HorseMarketUsdStakingData {
    index: uint64
    this_contract_jettonWallet: address
    total_score: coins
    parameter: uint16
}

struct HorseMarketUsdStakeRecord {
    stake_address: address
    jjj_stake_amount: coins
    score: uint128
}

struct HorseMarketUsdData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    this_contract_jettonWallet: address
    owner: address
    index: uint32
    stake_record: map<int257, Cell<HorseMarketUsdStakeRecord>>
    score_list: map<address, int257>
    start_time: uint32
    total_score: uint128
    parameter: uint16
    horseType: uint8
    telegramId: uint64
    total_amount: coins
}

type HorseMarketUsdIncomingMessage =
    | HorseMarketUsdAddingJettonAddress
    | HorseMarketUsdTokenNotification
    | HorseMarketUsdGetWeighted
    | HorseMarketUsdUnstake
    | HorseMarketUsdDeploy

enum HorseMarketUsdErrors {
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
    /// no Record
    NoRecord = 6582
    /// don't have value
    DonTHaveValue = 7013
    /// not from one of any jetton wallet
    NotFromOneOfAnyJettonWallet = 17054
    /// not in the list
    NotInTheList = 57660
    /// not from owner
    NotFromOwner = 61324
}

get fun get_ratio_of_stake(StakeTokenAmount: int257): int257 {
    throw 0;
}

get fun get_ratio_of_stake_2(StakeTokenAmount: int257): int257 {
    throw 0;
}

get fun get_ratio_of_stake_3(StakeTokenAmount: int257): int257 {
    throw 0;
}

get fun get_user_stake_record(): map<int257, Cell<HorseMarketUsdStakeRecord>> {
    throw 0;
}

get fun get_user_stake_amount(): map<address, int257> {
    throw 0;
}

get fun get_return_staking_data(): HorseMarketUsdStakingData {
    throw 0;
}

get fun get_contract_jettonWallet(): address {
    throw 0;
}

get fun get_address_score(target: address): int257 {
    throw 0;
}

get fun getHorseType(): int257 {
    throw 0;
}

get fun getTelegramId(): int257 {
    throw 0;
}

get fun getTotalAmount(): int257 {
    throw 0;
}

get fun getIndex(): int257 {
    throw 0;
}
