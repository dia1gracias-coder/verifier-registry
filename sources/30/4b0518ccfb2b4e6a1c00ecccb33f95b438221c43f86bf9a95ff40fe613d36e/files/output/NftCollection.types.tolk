// Generated from the verified Tact contract ABI.
contract NftCollection {
    storage: NftCollectionData
    incomingMessages: NftCollectionIncomingMessage
    thrownErrors: NftCollectionErrors
}

struct NftCollectionStateInit {
    code: cell
    data: cell
}

struct NftCollectionCollectionData {
    next_item_index: int257
    collection_content: cell
    owner_address: address
}

struct NftCollectionRoyaltyParams {
    numerator: int257
    denominator: int257
    destination: address
}

struct (0x693d3950) NftCollectionGetRoyaltyParams {
    query_id: uint64
}

struct (0x693d3951) NftCollectionGetBeneficiary {
    query_id: uint64
}

struct (0xea733358) NftCollectionGetPricePerMint {
    query_id: uint64
}

struct (0xad8825a3) NftCollectionMint {
    query_id: uint64
    referer: address?
}

struct (0x160d4971) NftCollectionBuilkMint {
    query_id: uint64
    receiver: address
    amount: uint32
}

struct (0xf9430bb2) NftCollectionAssignBeneficiary {
    query_id: uint64
    beneficiary: address
}

struct (0x25b9709a) NftCollectionAssignPricePerMint {
    query_id: uint64
    price_per_mint: int257
}

struct NftCollectionData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    next_item_index: uint32
    owner_address: address
    beneficiary: address
    price_per_mint: int257
    tactContinuation: Cell<NftCollectionDataContinuation>
}

struct NftCollectionDataContinuation {
    price_per_mint_step: int257
    price_per_mint_step_rise: int257
    tactContinuation: Cell<NftCollectionDataContinuation2>
}

struct NftCollectionDataContinuation2 {
    royalty_params: NftCollectionRoyaltyParams
    collection_content: cell
    tactContinuation: Cell<NftCollectionDataContinuation3>
}

struct NftCollectionDataContinuation3 {
    referer_reward: int257
}

type NftCollectionIncomingMessage =
    | NftCollectionMint
    | NftCollectionBuilkMint
    | NftCollectionGetRoyaltyParams
    | NftCollectionGetBeneficiary
    | NftCollectionAssignBeneficiary
    | NftCollectionAssignPricePerMint
    | NftCollectionGetPricePerMint

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
    /// Insufficient funds for minting.
    InsufficientFundsForMinting = 4637
    /// Only owner can set beneficiary address
    OnlyOwnerCanSetBeneficiaryAddress = 13566
    /// Only owner can perform bulk minting
    OnlyOwnerCanPerformBulkMinting = 23845
    /// Insufficient funds for storage and gas.
    InsufficientFundsForStorageAndGas = 36704
    /// Only owner can set price per mint
    OnlyOwnerCanSetPricePerMint = 37425
    /// not owner
    NotOwner = 49280
    /// non-sequential NFTs
    NonSequentialNFTs = 62742
}

get fun get_collection_data(): NftCollectionCollectionData {
    throw 0;
}

get fun get_nft_address_by_index(item_index: int257): address? {
    throw 0;
}

get fun getNftItemInit(item_index: int257): NftCollectionStateInit {
    throw 0;
}

get fun get_nft_content(index: int257, individual_content: cell): cell {
    throw 0;
}

get fun royalty_params(): NftCollectionRoyaltyParams {
    throw 0;
}

get fun beneficiary(): address {
    throw 0;
}

get fun calc_price_per_mint(price: int257, item_index: int257, step: int257, rise: int257): int257 {
    throw 0;
}

get fun price_per_mint(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun referer_reward(): int257 {
    throw 0;
}
