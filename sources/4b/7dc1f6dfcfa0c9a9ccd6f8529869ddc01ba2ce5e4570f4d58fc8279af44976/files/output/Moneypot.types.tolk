// Generated from the verified Tact contract ABI.
contract Moneypot {
    storage: MoneypotData
    incomingMessages: MoneypotIncomingMessage
    thrownErrors: MoneypotErrors
}

struct (0x946a98b6) MoneypotDeploy {
    queryId: uint64
}

struct (0x7362d09c) MoneypotTransferNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: cell?
}

struct MoneypotBetDetails {
    player: address
    betKey: string
    symbol: string
    amount: coins
}

struct MoneypotArray {
    m: map<uint16, Cell<MoneypotBetDetails>>
    length: int257
}

struct (0x877acd55) MoneypotUpdateWhitelist {
    whitelist: map<address, address>
}

struct (0x58f7c081) MoneypotPlaceBet {
    betKey: string
    symbol: string
    master: address?
}

struct (0x9dc34f08) MoneypotEndRound {
    roundId: uint32
    tonPrice: uint256
    jettonPrice: map<address, uint256>
}

struct MoneypotData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    stopped: bool
    whitelistedJettonWallet: map<address, uint8>
    tactContinuation: Cell<MoneypotDataContinuation>
}

struct MoneypotDataContinuation {
    whitelistedJettonMaster: map<address, address>
    roundsSeqno: uint32
    lastWinner: address?
    roundStartBet: uint32
    roundTonTotal: coins
    roundJettonTotal: map<address, coins>
    bets: MoneypotArray
    betsSeqno: uint32
    lastBetter: address
}

type MoneypotIncomingMessage =
    | MoneypotPlaceBet
    | MoneypotTransferNotification
    | MoneypotEndRound
    | MoneypotUpdateWhitelist
    | MoneypotDeploy

enum MoneypotErrors {
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
    /// 'Unknown' error
    UnknownError = 11
    /// Fatal error
    FatalError = 12
    /// Out of gas error
    OutOfGasError = 13
    /// Virtualization error
    VirtualizationError = 14
    /// Action list is invalid
    ActionListIsInvalid = 32
    /// Action list is too long
    ActionListIsTooLong = 33
    /// Action is invalid or not supported
    ActionIsInvalidOrNotSupported = 34
    /// Invalid source address in outbound message
    InvalidSourceAddressInOutboundMessage = 35
    /// Invalid destination address in outbound message
    InvalidDestinationAddressInOutboundMessage = 36
    /// Not enough TON
    NotEnoughTON = 37
    /// Not enough extra-currencies
    NotEnoughExtraCurrencies = 38
    /// Outbound message does not fit into a cell after rewriting
    OutboundMessageDoesNotFitIntoACellAfterRewriting = 39
    /// Cannot process a message
    CannotProcessAMessage = 40
    /// Library reference is null
    LibraryReferenceIsNull = 41
    /// Library change action error
    LibraryChangeActionError = 42
    /// Exceeded maximum number of cells in the library or the maximum depth of the Merkle tree
    ExceededMaximumNumberOfCellsInTheLibraryOrTheMaximumDepthOfTheMerkleTree = 43
    /// Account state size exceeded limits
    AccountStateSizeExceededLimits = 50
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
    /// Missing bet information
    MissingBetInformation = 2596
    /// No items in the array!
    NoItemsInTheArray = 6947
    /// Invalid value
    InvalidValue = 16059
    /// No items in the array to delete!
    NoItemsInTheArrayToDelete = 17848
    /// Index of the item cannot be negative!
    IndexOfTheItemCannotBeNegative = 19333
    /// Index is out of array bounds!
    IndexIsOutOfArrayBounds = 24006
    /// Contract stopped
    ContractStopped2 = 40368
    /// No space in the array left for new items!
    NoSpaceInTheArrayLeftForNewItems = 42469
    /// Contract not stopped
    ContractNotStopped = 53296
}

get fun tonAddress(): address {
    throw 0;
}

get fun tonBalance(): int257 {
    throw 0;
}

get fun tonAmount(): int257 {
    throw 0;
}

get fun jettonAmount(): map<address, coins> {
    throw 0;
}

get fun totalBetsNumber(): int257 {
    throw 0;
}

get fun currentRoundNumber(): int257 {
    throw 0;
}

get fun betAddress(seqno: int257): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun stopped(): bool {
    throw 0;
}
