// Generated from the verified Tact contract ABI.
contract BanksCrowdSale {
    storage: BanksCrowdSaleData
    incomingMessages: BanksCrowdSaleIncomingMessage
    thrownErrors: BanksCrowdSaleErrors
}

struct (0x946a98b6) BanksCrowdSaleDeploy {
    queryId: uint64
}

struct (0x819dbe99) BanksCrowdSaleChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x10d4afc9) BanksCrowdSaleReferralAddress {
    referral: address
}

struct BanksCrowdSaleData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    bankersAccounts: map<address, uint32>
    totalBanks: uint32
    totalBankers: uint32
    saleEnabled: bool
    owner: address
}

type BanksCrowdSaleIncomingMessage =
    | BanksCrowdSaleReferralAddress
    | BanksCrowdSaleDeploy
    | BanksCrowdSaleChangeOwner

enum BanksCrowdSaleErrors {
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
    /// Referral doesn't have any banks
    ReferralDoesnTHaveAnyBanks = 12041
    /// Sale stopped
    SaleStopped = 12123
    /// Sale ended
    SaleEnded = 26611
    /// Referral wrong
    ReferralWrong = 30220
    /// Access denied
    AccessDenied2 = 49469
    /// Bank's must be not zero
    BankSMustBeNotZero = 50218
}

get fun Banks(addr: address): int257 {
    throw 0;
}

get fun TotalBanks(): int257 {
    throw 0;
}

get fun Bankers(): map<address, uint32> {
    throw 0;
}

get fun TotalBankers(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
