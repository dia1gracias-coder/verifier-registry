// Generated from the verified Tact contract ABI.
contract BIPChanger {
    storage: BIPChangerData
    incomingMessages: BIPChangerIncomingMessage
    thrownErrors: BIPChangerErrors
}

struct (0x946a98b6) BIPChangerDeploy {
    queryId: uint64
}

struct (0x7362d09c) BIPChangerTokenNotification {
    query_id: uint64
    amount: coins
    from: address
    forward_payload: RemainingBitsAndRefs
}

struct (0xa98f9950) BIPChangerNftOwnershipAssigned {
    query_id: uint64
    index: uint256
    prev_owner: address
    BIP_value: coins
    forward_payload: RemainingBitsAndRefs
}

struct BIPChangerData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    jetton_wallet_address: address
    nft_collection_content: cell
    nft_collection_address: address
}

type BIPChangerIncomingMessage =
    | BIPChangerDeploy
    | BIPChangerTokenNotification
    | BIPChangerNftOwnershipAssigned

enum BIPChangerErrors {
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
    /// Not Deployed
    NotDeployed = 11850
    /// Invalid value
    InvalidValue = 16059
    /// Invalid Sender
    InvalidSender2 = 23263
    /// Invalid Amount
    InvalidAmount = 30404
    /// Invalid Owner
    InvalidOwner = 42491
    /// Invalid sender!
    InvalidSender3 = 42708
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// Already Deployed
    AlreadyDeployed = 50324
    /// Too big commission
    TooBigCommission = 51252
    /// Devision by zero
    DevisionByZero = 54898
    /// Invalid balance
    InvalidBalance = 62972
}

get fun get_content(value: int257): cell {
    throw 0;
}
