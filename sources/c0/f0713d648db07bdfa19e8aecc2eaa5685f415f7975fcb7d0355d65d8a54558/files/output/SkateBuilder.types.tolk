// Generated from the verified Tact contract ABI.
contract SkateBuilder {
    storage: SkateBuilderData
    incomingMessages: SkateBuilderIncomingMessage
    thrownErrors: SkateBuilderErrors
}

struct (0x946a98b6) SkateBuilderDeploy {
    queryId: uint64
}

struct SkateBuilderCollectionData {
    next_item_index: uint64
    collection_content: cell
    owner_address: address
}

struct (0x605a9218) SkateBuilderRequestMint {
}

struct (0x4dc16665) SkateBuilderRequestBuild {
}

struct (0x775281a7) SkateBuilderMintTo {
    user: address
    token_id: uint256
    part: uint8
}

struct (0x44807e69) SkateBuilderWithdrawTON {
}

struct SkateBuilderData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    query_id: uint64
    skate_gateway: address
    next_item_index: int257
    collection_content: cell
    owner_address: address
    tactContinuation: Cell<SkateBuilderDataContinuation>
}

struct SkateBuilderDataContinuation {
    nft_parts_content: map<int257, cell>
    deployment_nonce: int257
}

type SkateBuilderIncomingMessage =
    | SkateBuilderWithdrawTON
    | SkateBuilderRequestMint
    | SkateBuilderRequestBuild
    | SkateBuilderMintTo
    | SkateBuilderDeploy

enum SkateBuilderErrors {
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

get fun query_id(): int257 {
    throw 0;
}

get fun gateway(): address {
    throw 0;
}

get fun mint_hash(receiver_address: address): int257 {
    throw 0;
}

get fun is_valid_mint_signature(user_public_key: int257, receiver_address: address, signature: slice): bool {
    throw 0;
}

get fun build_hash(receiver_address: address): int257 {
    throw 0;
}

get fun is_valid_build_signature(user_public_key: int257, receiver_address: address, signature: slice): bool {
    throw 0;
}

get fun get_nft_address_by_index(index: int257): address {
    throw 0;
}

get fun get_collection_data(): SkateBuilderCollectionData {
    throw 0;
}

get fun get_nft_content(index: int257, individual_content: cell): cell {
    throw 0;
}
