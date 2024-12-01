// Generated from the verified Tact contract ABI.
contract MemeTVFinal {
    storage: MemeTVFinalData
    incomingMessages: MemeTVFinalIncomingMessage
    thrownErrors: MemeTVFinalErrors
}

struct (0xfc708bd2) MemeTVFinalMint {
    amount: int257
    receiver: address
}

struct (0x152087bf) MemeTVFinalMintPublic {
    amount: int257
}

struct (0x053bf3f3) MemeTVFinalMintCloseOrOpen {
    status: bool
}

struct (0xc0624b87) MemeTVFinalWhitelistedMint {
}

struct MemeTVFinalJettonData {
    totalSupply: int257
    mintable: bool
    owner: address
    content: cell
    walletCode: cell
}

struct (0x7bdd97de) MemeTVFinalTokenBurnNotification {
    queryId: uint64
    amount: coins
    owner: address
    response_destination: address?
}

struct (0xaf1ca26a) MemeTVFinalTokenUpdateContent {
    content: cell
}

struct MemeTVFinalData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    totalSupply: coins
    owner: address
    content: cell
    mintable: bool
    max_supply: coins
    whitelist: map<address, int257>
}

type MemeTVFinalIncomingMessage =
    | MemeTVFinalMint
    | MemeTVFinalMintPublic
    | MemeTVFinalMintCloseOrOpen
    | MemeTVFinalWhitelistedMint
    | MemeTVFinalTokenUpdateContent
    | MemeTVFinalTokenBurnNotification

enum MemeTVFinalErrors {
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
    /// Only owner can add to whitelist
    OnlyOwnerCanAddToWhitelist = 1827
    /// Not authorized to mint
    NotAuthorizedToMint = 2746
    /// Not Owner
    NotOwner = 3734
    /// Invalid value!!
    InvalidValue = 4159
    /// Invalid sender
    InvalidSender = 4429
    /// The total supply will be overlapping.
    TheTotalSupplyWillBeOverlapping = 6898
    /// Can't Mint Anymore
    CanTMintAnymore = 18668
    /// Invalid sender!
    InvalidSender2 = 42708
    /// Only Owner can call this function
    OnlyOwnerCanCallThisFunction = 42878
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// Only Owner is allowed to withdraw
    OnlyOwnerIsAllowedToWithdraw = 44443
    /// No points available for minting
    NoPointsAvailableForMinting = 49093
    /// Address not whitelisted
    AddressNotWhitelisted = 51006
    /// Invalid balance
    InvalidBalance = 62972
}

get fun get_jetton_data(): MemeTVFinalJettonData {
    throw 0;
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
