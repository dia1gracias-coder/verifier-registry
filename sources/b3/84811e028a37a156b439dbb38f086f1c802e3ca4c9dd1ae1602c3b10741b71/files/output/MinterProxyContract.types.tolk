// Generated from the verified Tact contract ABI.
contract MinterProxyContract {
    storage: MinterProxyContractData
    incomingMessages: MinterProxyContractIncomingMessage
    thrownErrors: MinterProxyContractErrors
}

struct (0x946a98b6) MinterProxyContractDeploy {
    queryId: uint64
}

struct MinterProxyContractContractData {
    owner: address
    superOperator: address
    jettonMasterAddress: address
    tactContinuation: Cell<MinterProxyContractContractDataContinuation>
}

struct MinterProxyContractContractDataContinuation {
    jettonWalletAddress: address
}

struct (0x178d4519) MinterProxyContractOperation {
    query_id: uint64
    jetton_amount: coins
    from_address: address
    response_address: address
    forward_ton_amount: coins
    no_forward: bool
}

struct (0x642b7d07) MinterProxyContractJettonMint {
    query_id: uint64
    to_address: address
    ton_amount: coins
    tactContinuation: Cell<MinterProxyContractJettonMintContinuation>
}

struct MinterProxyContractJettonMintContinuation {
    operation: MinterProxyContractOperation
}

struct (0x5d40bc01) MinterProxyContractUpdateContractOwnerAddress {
    address: address
}

struct (0x5e7d4e2b) MinterProxyContractUpdateSuperOperatorAddress {
    address: address
}

struct (0x2b1ba631) MinterProxyContractUpdateJettonMasterAddress {
    address: address
}

struct (0x081dcfbf) MinterProxyContractUpdateJettonWalletAddress {
    address: address
}

struct MinterProxyContractJettonData {
    total_supply: int257
    mintable: bool
    owner: address
    content: cell
    wallet_code: cell
}

struct (0x5192842e) MinterProxyContractUpdateJettonData {
    data: MinterProxyContractJettonData
}

struct (0xd53276db) MinterProxyContractTokenExcesses {
    query_id: uint64
}

struct (0x0f8a7ea5) MinterProxyContractJettonTransfer {
    query_id: uint64
    amount: coins
    destination: address
    response_destination: address?
    custom_payload: cell?
    forward_ton_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct (0x6501f354) MinterProxyContractJettonChangeAdmin {
    query_id: uint64
    new_admin_address: address
}

struct MinterProxyContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    superOperator: address
    jettonMasterAddress: address
    tactContinuation: Cell<MinterProxyContractDataContinuation>
}

struct MinterProxyContractDataContinuation {
    jettonWalletAddress: address
    MinTonForStorage: int257
    tactContinuation: Cell<MinterProxyContractDataContinuation2>
}

struct MinterProxyContractDataContinuation2 {
    jettonData: MinterProxyContractJettonData
}

type MinterProxyContractIncomingMessage =
    | MinterProxyContractJettonMint
    | MinterProxyContractJettonChangeAdmin
    | MinterProxyContractJettonTransfer
    | MinterProxyContractTokenExcesses
    | MinterProxyContractUpdateContractOwnerAddress
    | MinterProxyContractUpdateSuperOperatorAddress
    | MinterProxyContractUpdateJettonMasterAddress
    | MinterProxyContractUpdateJettonWalletAddress
    | MinterProxyContractUpdateJettonData
    | MinterProxyContractDeploy

enum MinterProxyContractErrors {
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
    /// Not owner
    NotOwner = 14534
    /// Not operator
    NotOperator = 28880
}

get fun get_contract_data(): MinterProxyContractContractData {
    throw 0;
}

get fun get_jetton_data(): MinterProxyContractJettonData {
    throw 0;
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}
