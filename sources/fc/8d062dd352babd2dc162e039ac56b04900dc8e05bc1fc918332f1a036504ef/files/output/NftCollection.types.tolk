// Generated from the verified Tact contract ABI.
contract NftCollection {
    storage: NftCollectionData
    incomingMessages: NftCollectionIncomingMessage
    thrownErrors: NftCollectionErrors
}

struct (0x946a98b6) NftCollectionDeploy {
    queryId: uint64
}

struct NftCollectionNftRoyaltyParams {
    numerator: int257
    denominator: int257
    royalty_destination: address
}

struct (0x693d3950) NftCollectionNftGetRoyaltyParams {
    query_id: uint64
}

struct (0xed546730) NftCollectionRequestNftDeploy {
    asset_metadata: cell
}

struct NftCollectionCollectionData {
    next_index: int257
    content: cell
    owner: address
}

struct (0x5f30495e) NftCollectionAdminWithdraw {
    queryId: uint64
}

struct (0x1a0e9a46) NftCollectionClearStuckMint {
    queryId: uint64
    index: uint256
}

struct (0x6019823a) NftCollectionClearMintCooldown {
    queryId: uint64
    addr: address
}

struct NftCollectionData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    next_index: uint256
    content: cell
    royalty_destination: address
    numerator: uint16
    denominator: uint16
    tactContinuation: Cell<NftCollectionDataContinuation>
}

struct NftCollectionDataContinuation {
    supply: int257
    pending_mints: map<int257, bool>
    last_mint_time: map<address, int257>
}

type NftCollectionIncomingMessage =
    | NftCollectionRequestNftDeploy
    | NftCollectionAdminWithdraw
    | NftCollectionClearStuckMint
    | NftCollectionClearMintCooldown
    | NftCollectionDeploy
    | NftCollectionNftGetRoyaltyParams

enum NftCollectionErrors {
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
    /// Not Deployed
    NotDeployed = 11850
    /// Please wait before minting again
    PleaseWaitBeforeMintingAgain = 13560
    /// Invalid Sender
    InvalidSender = 23263
    /// only owner!
    OnlyOwner = 24775
    /// Invalid Amount
    InvalidAmount = 30404
    /// Drop ended
    DropEnded = 30428
    /// This index is being minted
    ThisIndexIsBeingMinted = 30984
    /// Invalid Owner
    InvalidOwner = 42491
    /// Invalid Index
    InvalidIndex = 44083
    /// Already Deployed
    AlreadyDeployed = 50324
}

get fun get_collection_data(): NftCollectionCollectionData {
    throw 0;
}

get fun get_nft_address_by_index(index: int257): address {
    throw 0;
}

get fun get_nft_content(index: int257, individual_content: cell): cell {
    throw 0;
}

get fun get_next_index(): int257 {
    throw 0;
}

get fun get_mint_state(index: int257): bool {
    throw 0;
}

get fun can_user_mint(addr: address): bool {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun royalty_params(): NftCollectionNftRoyaltyParams {
    throw 0;
}
