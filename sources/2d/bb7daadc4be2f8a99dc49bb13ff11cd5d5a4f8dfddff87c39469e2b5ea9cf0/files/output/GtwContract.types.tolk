// Generated from the verified Tact contract ABI.
contract GtwContract {
    storage: GtwContractData
    incomingMessages: GtwContractIncomingMessage
    thrownErrors: GtwContractErrors
}

struct (0x946a98b6) GtwContractDeploy {
    queryId: uint64
}

struct (0x6c1b24f2) GtwContractMakePayment {
    typeItem: uint8
    idItem: uint8
    sponsorAddress: address
}

struct (0x037994b8) GtwContractActivateReferralLink {
    sponsorAddress: address
}

struct (0xaf4da7cd) GtwContractActivateReferralLinkByOwner {
    referralAddress: address
    sponsorAddress: address
}

struct (0x15618782) GtwContractChangeReferralLinkByOwner {
    referralAddress: address
    sponsorAddress: address
}

struct (0x6992b272) GtwContractSetMinimalAmount {
    minAmount: coins
}

struct GtwContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    recipient: address
    referralTree: map<address, address>
    tonsTotalAmount: coins
    minAmount: coins
}

type GtwContractIncomingMessage =
    | GtwContractMakePayment
    | GtwContractActivateReferralLink
    | GtwContractActivateReferralLinkByOwner
    | GtwContractChangeReferralLinkByOwner
    | GtwContractSetMinimalAmount
    | GtwContractDeploy

enum GtwContractErrors {
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
    /// address same as yours
    AddressSameAsYours = 4486
    /// only owner can use this method
    OnlyOwnerCanUseThisMethod = 37776
    /// minimal amount is 1 ton
    MinimalAmountIs1Ton = 40874
}

get fun get_sponsor(referral: address): address? {
    throw 0;
}

get fun referral_tree(): map<address, address> {
    throw 0;
}

get fun get_total_tons(): int257 {
    throw 0;
}

get fun balance(): string {
    throw 0;
}

get fun min_amount(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
