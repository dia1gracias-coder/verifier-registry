// Generated from the verified Tact contract ABI.
contract ArcJetton {
    storage: ArcJettonData
    incomingMessages: ArcJettonIncomingMessage
    thrownErrors: ArcJettonErrors
}

struct (0x946a98b6) ArcJettonDeploy {
    queryId: uint64
}

struct (0x819dbe99) ArcJettonChangeOwner {
    queryId: uint64
    newOwner: address
}

struct ArcJettonJettonData {
    total_supply: coins
    mintable: bool
    admin_address: address
    jetton_content: cell
    jetton_wallet_code: cell
}

struct (0x89b71d09) ArcJettonJettonMint {
    origin: address
    receiver: address
    amount: int257
    custom_payload: cell?
    forward_ton_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct (0x7bdd97de) ArcJettonJettonBurnNotification {
    query_id: uint64
    amount: coins
    sender: address
    response_destination: address
}

struct (0x106f2a88) ArcJettonMint {
    to: address
    amount: int257
}

struct (0xa20fc88d) ArcJettonChangeMinter {
    newMinter: address
    isMinter: bool
}

struct ArcJettonData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    total_supply: coins
    mintable: bool
    owner: address
    minter: map<address, bool>
    jetton_content: cell
}

type ArcJettonIncomingMessage =
    | ArcJettonChangeMinter
    | ArcJettonMint
    | ArcJettonJettonBurnNotification
    | ArcJettonJettonMint
    | ArcJettonDeploy
    | ArcJettonChangeOwner

enum ArcJettonErrors {
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
    /// JettonWallet: Not enough jettons to transfer
    JettonWalletNotEnoughJettonsToTransfer = 13105
    /// Not right owner
    NotRightOwner = 13623
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
    /// JettonWallet: Only owner can burn tokens
    JettonWalletOnlyOwnerCanBurnTokens = 47048
    /// No staking amount
    NoStakingAmount = 53212
    /// not right minter
    NotRightMinter = 59633
    /// JettonWallet: Not enough balance to burn tokens
    JettonWalletNotEnoughBalanceToBurnTokens = 60354
}

get fun get_jetton_data(): ArcJettonJettonData {
    throw 0;
}

get fun get_wallet_address(owner_address: address): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
