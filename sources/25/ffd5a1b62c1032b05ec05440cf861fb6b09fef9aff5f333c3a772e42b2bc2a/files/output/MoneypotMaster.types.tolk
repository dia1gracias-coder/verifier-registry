// Generated from the verified Tact contract ABI.
contract MoneypotMaster {
    storage: MoneypotMasterData
    incomingMessages: MoneypotMasterIncomingMessage
    thrownErrors: MoneypotMasterErrors
}

struct (0x946a98b6) MoneypotMasterDeploy {
    queryId: uint64
}

struct (0xf6ad3aec) MoneypotMasterEndRound {
    tonPrice: uint32
    jettonPrice: map<address, uint32>
}

struct (0xd90aaa12) MoneypotMasterPayoutOk {
    address: address
    value: coins
}

struct (0x25bd488e) MoneypotMasterPayoutFailed {
    address: address
    value: coins
}

struct (0x7362d09c) MoneypotMasterJettonTransferNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0x809b3384) MoneypotMasterPlaceBet {
    betKey: string
}

struct MoneypotMasterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    stopped: bool
    jettonWalletAddress: address
    jettonAmount: coins
    bets_seqno: uint32
    last_better: address
}

type MoneypotMasterIncomingMessage =
    | MoneypotMasterJettonTransferNotification
    | MoneypotMasterPlaceBet
    | MoneypotMasterEndRound
    | MoneypotMasterPayoutOk
    | MoneypotMasterPayoutFailed
    | MoneypotMasterDeploy

enum MoneypotMasterErrors {
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
    /// Invalid sender
    InvalidSender = 4429
    /// Notification not from your jetton wallet!
    NotificationNotFromYourJettonWallet = 12495
    /// Invalid value
    InvalidValue = 16059
    /// Insufficient balance on master
    InsufficientBalanceOnMaster = 19204
    /// Contract stopped
    ContractStopped2 = 40368
    /// Contract not stopped
    ContractNotStopped = 53296
    /// Check withdraw min value
    CheckWithdrawMinValue = 57826
}

get fun tonAddress(): address {
    throw 0;
}

get fun jettonAddress(): address {
    throw 0;
}

get fun jettonAmount(): int257 {
    throw 0;
}

get fun totalBetsNumber(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun stopped(): bool {
    throw 0;
}
