// Generated from the verified Tact contract ABI.
contract BondingContract {
    storage: BondingContractData
    incomingMessages: BondingContractIncomingMessage
    thrownErrors: BondingContractErrors
}

struct (0x7362d09c) BondingContractTokenNotification {
    query_Id: uint64
    amount: coins
    from: address
    forward_payload: RemainingBitsAndRefs
}

struct (0x05571247) BondingContractUpdateBondRate {
    usdt_bond_rate: uint64
    pro_ton_bond_rate: uint64
    pro_usdt_bond_rate: uint64
    ton_bond_rate: uint64
}

struct (0xe17184d0) BondingContractWithdrawOwner {
    jetton_wallet: address
    amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct (0x787c03d4) BondingContractAddingJettonAddress {
    usdt_wallet: address
    pro_ton_wallet: address
    pro_usdt_wallet: address
    tactContinuation: Cell<BondingContractAddingJettonAddressContinuation>
}

struct BondingContractAddingJettonAddressContinuation {
    pro_wallet: address
}

struct (0x31d628f0) BondingContractTransferOwner {
    new_owner: address
}

struct (0x5a1c970b) BondingContractWithdrawTON {
    amount: coins
}

struct (0x897aef72) BondingContractClaim {
    amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct (0x71ab1b7d) BondingContractBondTON {
}

struct BondingContractBondInfo {
    pending_amount: coins
    deposit_time: uint32
    period: uint32
}

struct BondingContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    usdt_wallet: address?
    usdt_bond_rate: uint64
    usdt_total_purchased: coins
    pro_ton_wallet: address?
    pro_ton_bond_rate: uint64
    pro_ton_total_purchased: coins
    tactContinuation: Cell<BondingContractDataContinuation>
}

struct BondingContractDataContinuation {
    pro_usdt_wallet: address?
    pro_usdt_bond_rate: uint64
    pro_usdt_total_purchased: coins
    ton_bond_rate: uint64
    ton_total_purchased: coins
    pro_wallet: address?
    owners: map<address, int257>
    bond_info: map<address, Cell<BondingContractBondInfo>>
    tactContinuation: Cell<BondingContractDataContinuation2>
}

struct BondingContractDataContinuation2 {
    total_bond_amount: coins
}

type BondingContractIncomingMessage =
    | BondingContractAddingJettonAddress
    | BondingContractUpdateBondRate
    | BondingContractTokenNotification
    | BondingContractBondTON
    | BondingContractClaim
    | BondingContractWithdrawOwner
    | BondingContractWithdrawTON
    | BondingContractTransferOwner

enum BondingContractErrors {
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
    /// !jetton_wallet
    JettonWallet = 25825
    /// !msg.amount
    MsgAmount = 43455
    /// !claimable_amount
    ClaimableAmount = 43859
    /// !owner
    Owner = 51336
}

get fun get_bond_amount(jetton_amount: int257, jetton_wallet: address): int257 {
    throw 0;
}

get fun get_user_bond_info(): map<address, Cell<BondingContractBondInfo>> {
    throw 0;
}

get fun get_usdt_total_purchased_amount(): int257 {
    throw 0;
}

get fun get_pro_usdt_total_purchased_amount(): int257 {
    throw 0;
}

get fun get_pro_ton_total_purchased_amount(): int257 {
    throw 0;
}

get fun get_ton_total_purchased_amount(): int257 {
    throw 0;
}

get fun get_usdt_bond_rate(): int257 {
    throw 0;
}

get fun get_pro_ton_bond_rate(): int257 {
    throw 0;
}

get fun get_pro_usdt_bond_rate(): int257 {
    throw 0;
}

get fun get_ton_bond_rate(): int257 {
    throw 0;
}

get fun get_usdt_wallet(): address? {
    throw 0;
}

get fun get_pro_ton_wallet(): address? {
    throw 0;
}

get fun get_pro_usdt_wallet(): address? {
    throw 0;
}

get fun get_pro_wallet(): address? {
    throw 0;
}

get fun get_owner(address: address): int257 {
    throw 0;
}
