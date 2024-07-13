// Generated from the verified Tact contract ABI.
contract StakingContract {
    storage: StakingContractData
    incomingMessages: StakingContractIncomingMessage
    thrownErrors: StakingContractErrors
}

struct StakingContractStakingData {
    index: uint64
    this_contract_jettonWallet: address
    total_score: coins
    parameter: uint16
}

struct StakingContractStakeRecord {
    stake_address: address
    jettonStakeAmount: coins
    score: uint128
}

struct (0x8515738f) StakingContractUnstake {
    index_id: uint32
}

struct (0x134c687a) StakingContractGetWeighted {
    applied_user_address: address
}

struct (0x7362d09c) StakingContractTokenNotification {
    query_id: uint64
    amount: coins
    from: address
    forward_payload: RemainingBitsAndRefs
}

struct StakingContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    this_contract_jettonWallet: address?
    owner: address
    index: uint32
    stake_record: map<int257, Cell<StakingContractStakeRecord>>
    score_list: map<address, int257>
    start_time: uint32
    total_score: uint128
    parameter: uint16
}

type StakingContractIncomingMessage =
    | StakingContractTokenNotification
    | StakingContractGetWeighted
    | StakingContractUnstake

enum StakingContractErrors {
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
    /// Not mintable
    NotMintable = 3688
    /// Invalid value!!
    InvalidValue = 4159
    /// Invalid sender
    InvalidSender = 4429
    /// no Record
    NoRecord = 6582
    /// don't have value
    DonTHaveValue = 7013
    /// Max supply exceeded
    MaxSupplyExceeded = 12241
    /// Not owner
    NotOwner = 14534
    /// not from one of any jetton wallet
    NotFromOneOfAnyJettonWallet = 17054
    /// Can't Mint Anymore
    CanTMintAnymore = 18668
    /// Insufficient gas
    InsufficientGas = 23951
    /// Invalid sender!
    InvalidSender2 = 42708
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// not enough value
    NotEnoughValue = 57218
    /// not in the list
    NotInTheList = 57660
    /// Invalid balance
    InvalidBalance = 62972
}

get fun get_user_stake_record(): map<int257, Cell<StakingContractStakeRecord>> {
    throw 0;
}

get fun get_user_stake_amount(): map<address, int257> {
    throw 0;
}

get fun get_return_staking_data(): StakingContractStakingData {
    throw 0;
}
