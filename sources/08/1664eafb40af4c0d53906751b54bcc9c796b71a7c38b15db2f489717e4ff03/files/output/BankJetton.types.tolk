// Generated from the verified Tact contract ABI.
contract BankJetton {
    storage: BankJettonData
    incomingMessages: BankJettonIncomingMessage
    thrownErrors: BankJettonErrors
}

struct (0x946a98b6) BankJettonDeploy {
    queryId: uint64
}

struct (0x819dbe99) BankJettonChangeOwner {
    queryId: uint64
    newOwner: address
}

struct BankJettonJettonData {
    total_supply: coins
    mintable: bool
    admin_address: address
    jetton_content: cell
    jetton_wallet_code: cell
}

struct (0x89b71d09) BankJettonJettonMint {
    origin: address
    receiver: address
    amount: int257
    custom_payload: cell?
    forward_ton_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct (0x7362d09c) BankJettonJettonTransferNotification {
    query_id: uint64
    amount: coins
    sender: address
    forward_payload: RemainingBitsAndRefs
}

struct (0x7bdd97de) BankJettonJettonBurnNotification {
    query_id: uint64
    amount: coins
    sender: address
    response_destination: address
}

struct (0x106f2a88) BankJettonMint {
    to: address
    amount: int257
}

struct (0x022702dd) BankJettonAddingJettonAddress {
    this_contract_jettonWallet: address
}

struct BankJettonData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    total_supply: coins
    max_supply: coins
    mintable: bool
    owner: address
    jetton_content: cell
    firstCell: address
    tactContinuation: Cell<BankJettonDataContinuation>
}

struct BankJettonDataContinuation {
    lastCell: address
    ARCjetton: address
}

type BankJettonIncomingMessage =
    | BankJettonAddingJettonAddress
    | BankJettonJettonTransferNotification
    | BankJettonMint
    | BankJettonJettonBurnNotification
    | BankJettonJettonMint
    | BankJettonDeploy
    | BankJettonChangeOwner

enum BankJettonErrors {
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
    /// JettonWallet: Only Jetton master or Jetton wallet can call this function
    JettonWalletOnlyJettonMasterOrJettonWalletCanCallThisFunction = 2296
    /// wrong call
    WrongCall = 2299
    /// Invalid sender
    InvalidSender = 4429
    /// Sender is not a Jetton wallet
    SenderIsNotAJettonWallet = 9739
    /// No right to  AddingJettonAddress
    NoRightToAddingJettonAddress = 10706
    /// JettonWallet: Not enough jettons to transfer
    JettonWalletNotEnoughJettonsToTransfer = 13105
    /// Not owner
    NotOwner = 14534
    /// Only owner can call this function
    OnlyOwnerCanCallThisFunction = 27831
    /// JettonWallet: Not allow negative balance after internal transfer
    JettonWalletNotAllowNegativeBalanceAfterInternalTransfer = 29133
    /// JettonMaster: Jetton is not mintable
    JettonMasterJettonIsNotMintable = 30061
    /// Not enough funds to transfer
    NotEnoughFundsToTransfer = 37185
    /// JettonMaster: Sender is not a Jetton owner
    JettonMasterSenderIsNotAJettonOwner = 43365
    /// Not allowed sender
    NotAllowedSender = 45329
    /// JettonWallet: Only owner can burn tokens
    JettonWalletOnlyOwnerCanBurnTokens = 47048
    /// acсess denided
    AcEssDenided = 51765
    /// No staking amount
    NoStakingAmount = 53212
    /// Not right sender of stake message
    NotRightSenderOfStakeMessage = 58975
    /// JettonWallet: Not enough balance to burn tokens
    JettonWalletNotEnoughBalanceToBurnTokens = 60354
}

get fun calculate_stake_address(owner_address: address): address {
    throw 0;
}

get fun get_jetton_data(): BankJettonJettonData {
    throw 0;
}

get fun get_wallet_address(owner_address: address): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
