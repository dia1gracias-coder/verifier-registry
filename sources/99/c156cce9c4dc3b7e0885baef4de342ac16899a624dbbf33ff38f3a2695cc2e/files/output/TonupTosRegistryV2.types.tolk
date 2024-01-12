// Generated from the verified Tact contract ABI.
contract TonupTosRegistryV2 {
    storage: TonupTosRegistryV2Data
    incomingMessages: TonupTosRegistryV2IncomingMessage
    thrownErrors: TonupTosRegistryV2Errors
}

struct (0x946a98b6) TonupTosRegistryV2Deploy {
    queryId: uint64
}

struct (0xcbc1a22e) TonupTosRegistryV2ConsentReply {
    addr: address
    accepted: bool
}

struct (0xe49e8873) TonupTosRegistryV2RescueJetton {
    jetton_wallet_address: address
    amount: coins
    receiver: address
}

struct TonupTosRegistryV2Data {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    number_users: uint32
}

type TonupTosRegistryV2IncomingMessage =
    | TonupTosRegistryV2ConsentReply
    | TonupTosRegistryV2RescueJetton
    | TonupTosRegistryV2Deploy

enum TonupTosRegistryV2Errors {
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
    /// Strlib::ss_address_to_hex: Invalid address
    StrlibSsAddressToHexInvalidAddress = 4023
    /// Invalid value!!
    InvalidValue = 4159
    /// Strlib::ss_parse_address: Invalid address
    StrlibSsParseAddressInvalidAddress = 5047
    /// Strlib::toBase64: Base64 string too long
    StrlibToBase64Base64StringTooLong = 10368
    /// Strlib::_strlib_crc16: Invalid data
    StrlibStrlibCrc16InvalidData = 14117
    /// Unreachable
    Unreachable = 19149
    /// Already consented
    AlreadyConsented = 28512
    /// Consent error
    ConsentError = 29763
    /// Not enough gas
    NotEnoughGas = 33150
    /// Unauthorized
    Unauthorized = 49729
}

get fun msg_value(value: int257): int257 {
    throw 0;
}

get fun userChildAddress(user: address): address {
    throw 0;
}

get fun consentMessage(): string {
    throw 0;
}

get fun currentVersion(): int257 {
    throw 0;
}

get fun numberUsers(): int257 {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
