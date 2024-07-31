// Generated from the verified Tact contract ABI.
contract BanksCrowdSaleV3 {
    storage: BanksCrowdSaleV3Data
    incomingMessages: BanksCrowdSaleV3IncomingMessage
    thrownErrors: BanksCrowdSaleV3Errors
}

struct (0x946a98b6) BanksCrowdSaleV3Deploy {
    queryId: uint64
}

struct (0x819dbe99) BanksCrowdSaleV3ChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x10d4afc9) BanksCrowdSaleV3ReferralAddress {
    referral: address
}

struct (0x315c9e69) BanksCrowdSaleV3SetBankOffset {
    offset: uint32
}

struct (0x77321783) BanksCrowdSaleV3SetJettonWallet {
    jetton_wallet: address
}

struct (0xc06de781) BanksCrowdSaleV3SetNewOwner {
    new_owner: address
}

struct BanksCrowdSaleV3Data {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    totalBanks: uint32
    saleEnabled: bool
    owner: address
    price1stage: uint32
    price2stage: uint32
    price3stage: uint32
    price4stage: uint32
    totalBanksOffset: uint32
    max_for_sale: uint32
    jetton_wallet: address
    tactContinuation: Cell<BanksCrowdSaleV3DataContinuation>
}

struct BanksCrowdSaleV3DataContinuation {
    jetton_master: address
}

type BanksCrowdSaleV3IncomingMessage =
    | BanksCrowdSaleV3SetJettonWallet
    | BanksCrowdSaleV3ReferralAddress
    | BanksCrowdSaleV3SetBankOffset
    | BanksCrowdSaleV3SetNewOwner
    | BanksCrowdSaleV3Deploy
    | BanksCrowdSaleV3ChangeOwner

enum BanksCrowdSaleV3Errors {
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
    /// Sale stopped
    SaleStopped = 12123
    /// JettonWallet: Not enough jettons to transfer
    JettonWalletNotEnoughJettonsToTransfer = 13105
    /// Sale ended
    SaleEnded = 26611
    /// Only owner can call this function
    OnlyOwnerCanCallThisFunction = 27831
    /// JettonWallet: Not allow negative balance after internal transfer
    JettonWalletNotAllowNegativeBalanceAfterInternalTransfer = 29133
    /// Referral wrong
    ReferralWrong = 30220
    /// Not enough funds to transfer
    NotEnoughFundsToTransfer = 37185
    /// JettonWallet: Only owner can burn tokens
    JettonWalletOnlyOwnerCanBurnTokens = 47048
    /// Access denied
    AccessDenied2 = 49469
    /// JettonWallet: Not enough balance to burn tokens
    JettonWalletNotEnoughBalanceToBurnTokens = 60354
}

get fun TotalBanks(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
