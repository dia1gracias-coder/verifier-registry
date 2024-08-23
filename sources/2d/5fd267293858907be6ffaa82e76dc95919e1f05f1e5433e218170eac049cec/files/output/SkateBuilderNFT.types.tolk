// Generated from the verified Tact contract ABI.
contract SkateBuilderNFT {
    storage: SkateBuilderNFTData
    incomingMessages: SkateBuilderNFTIncomingMessage
    thrownErrors: SkateBuilderNFTErrors
}

struct SkateBuilderNFTNftData {
    initialized: bool
    index: uint64
    collection_address: address
    owner_address: address
    individual_content: cell
}

struct (0x5fcc3d14) SkateBuilderNFTTransfer {
    query_id: uint64
    new_owner: address
    response_destination: address
    custom_payload: cell?
    forward_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct (0x2fcb26a2) SkateBuilderNFTGetStaticData {
    query_id: uint64
}

struct SkateBuilderNFTData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    collection_address: address
    index: int257
    owner_address: address
    individual_content: cell
    initialized: bool
}

type SkateBuilderNFTIncomingMessage =
    | SkateBuilderNFTTransfer
    | SkateBuilderNFTGetStaticData

enum SkateBuilderNFTErrors {
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
    /// SkateBuilderNFT::Custom payload must contain NFT content
    SkateBuilderNFTCustomPayloadMustContainNFTContent = 4526
    /// SkateBuilder.MintTo()::Invalid skateboard part, must be within 0-3
    SkateBuilderMintToInvalidSkateboardPartMustBeWithin03 = 5387
    /// SkateBuilder::Not enough user fee!
    SkateBuilderNotEnoughUserFee = 5936
    /// SkateBuilderNFT::NFT is not transferable!
    SkateBuilderNFTNFTIsNotTransferable = 15872
    /// NFTItemBase::Not enough in message value!
    NFTItemBaseNotEnoughInMessageValue = 61335
}

get fun get_nft_data(): SkateBuilderNFTNftData {
    throw 0;
}
