// Generated from the verified Tact contract ABI.
contract ExampleJettonMaster {
    storage: ExampleJettonMasterData
    incomingMessages: ExampleJettonMasterIncomingMessage
    thrownErrors: ExampleJettonMasterErrors
}

struct (0x946a98b6) ExampleJettonMasterDeploy {
    queryId: uint64
}

struct ExampleJettonMasterJettonData {
    total_supply: coins
    mintable: bool
    admin_address: address
    jetton_content: cell
    jetton_wallet_code: cell
}

struct (0x89b71d09) ExampleJettonMasterJettonMint {
    origin: address
    receiver: address
    amount: int257
    custom_payload: cell?
    forward_ton_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct (0x7bdd97de) ExampleJettonMasterJettonBurnNotification {
    query_id: uint64
    amount: coins
    sender: address
    response_destination: address
}

struct ExampleJettonMasterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    total_supply: coins
    mintable: bool
    owner: address
    jetton_content: cell
}

type ExampleJettonMasterIncomingMessage =
    | ExampleJettonMasterJettonBurnNotification
    | ExampleJettonMasterJettonMint
    | ExampleJettonMasterDeploy

enum ExampleJettonMasterErrors {
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
    /// JettonWallet: Only Jetton master or Jetton wallet can call this function
    JettonWalletOnlyJettonMasterOrJettonWalletCanCallThisFunction = 2296
    /// NFTItemStandard: Only the collection can initialize the NFT item
    NFTItemStandardOnlyTheCollectionCanInitializeTheNFTItem = 4020
    /// Sender is not a Jetton wallet
    SenderIsNotAJettonWallet = 9739
    /// JettonWallet: Not enough jettons to transfer
    JettonWalletNotEnoughJettonsToTransfer = 13105
    /// Only owner can call this function
    OnlyOwnerCanCallThisFunction = 27831
    /// JettonWallet: Not allow negative balance after internal transfer
    JettonWalletNotAllowNegativeBalanceAfterInternalTransfer = 29133
    /// JettonMaster: Jetton is not mintable
    JettonMasterJettonIsNotMintable = 30061
    /// NFTItemStandard: Only the owner or collection can transfer the NFT item
    NFTItemStandardOnlyTheOwnerOrCollectionCanTransferTheNFTItem = 32575
    /// Not enough funds to transfer
    NotEnoughFundsToTransfer = 37185
    /// Contract stopped
    ContractStopped2 = 40368
    /// JettonMaster: Sender is not a Jetton owner
    JettonMasterSenderIsNotAJettonOwner = 43365
    /// JettonWallet: Only owner can burn tokens
    JettonWalletOnlyOwnerCanBurnTokens = 47048
    /// Message is not from real NFT
    MessageIsNotFromRealNFT = 48002
    /// Contract not stopped
    ContractNotStopped = 53296
    /// JettonWallet: Not enough balance to burn tokens
    JettonWalletNotEnoughBalanceToBurnTokens = 60354
}

get fun get_jetton_data(): ExampleJettonMasterJettonData {
    throw 0;
}

get fun get_wallet_address(owner_address: address): address {
    throw 0;
}
