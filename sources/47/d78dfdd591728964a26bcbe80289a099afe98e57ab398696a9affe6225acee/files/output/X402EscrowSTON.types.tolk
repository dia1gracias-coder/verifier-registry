// Generated from the verified Tact contract ABI.
contract X402EscrowSTON {
    storage: X402EscrowSTONData
    incomingMessages: X402EscrowSTONIncomingMessage
    thrownErrors: X402EscrowSTONErrors
}

struct (0x7362d09c) X402EscrowSTONJettonTransferNotification {
    queryId: uint64
    amount: coins
    from: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0x9a1b2c3d) X402EscrowSTONUnlockSTON {
    user: address
    amount: coins
    fee: coins
}

struct X402EscrowSTONBatchEntry {
    to: address
    tonAmount: int257
    stonAmount: int257
}

struct (0xf3893193) X402EscrowSTONBatchTransferTON {
    entries: map<uint8, Cell<X402EscrowSTONBatchEntry>>
    count: int257
}

struct (0x1e18a375) X402EscrowSTONWithdrawSTON {
    amount: coins
    destination: address
}

struct (0x2e18a376) X402EscrowSTONWithdrawTON {
    amount: coins
}

struct (0x8f3a9d2b) X402EscrowSTONSetJettonWallet {
    jettonWallet: address
}

struct X402EscrowSTONData {
    tactDeploymentCompleted: bool
    owner: address
    stonJetton: address
    balances: map<address, int257>
    tactContinuation: Cell<X402EscrowSTONDataContinuation>
}

struct X402EscrowSTONDataContinuation {
    userPubKeys: map<address, int257>
    totalLocked: int257
    myJettonWallet: address
    withdrawAddress: address
    admins: map<address, bool>
}

type X402EscrowSTONIncomingMessage =
    | X402EscrowSTONJettonTransferNotification
    | X402EscrowSTONBatchTransferTON
    | X402EscrowSTONWithdrawSTON
    | X402EscrowSTONWithdrawTON
    | X402EscrowSTONUnlockSTON
    | X402EscrowSTONSetJettonWallet

enum X402EscrowSTONErrors {
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
    /// Not enough Toncoin
    NotEnoughToncoin = 37
    /// Not enough extra currencies
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
    /// Invalid standard address
    InvalidStandardAddress = 136
    /// Not a basechain address
    NotABasechainAddress = 138
}

get fun balanceOf(user: address): int257 {
    throw 0;
}

get fun totalLockedAmount(): int257 {
    throw 0;
}

get fun tonBalance(): int257 {
    throw 0;
}

get fun myJettonWallet(): address {
    throw 0;
}

get fun userPubKey(user: address): int257? {
    throw 0;
}
