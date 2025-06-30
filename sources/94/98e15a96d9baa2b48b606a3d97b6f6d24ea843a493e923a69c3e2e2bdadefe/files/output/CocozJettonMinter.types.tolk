// Generated from the verified Tact contract ABI.
contract CocozJettonMinter {
    storage: CocozJettonMinterData
    incomingMessages: CocozJettonMinterIncomingMessage
    thrownErrors: CocozJettonMinterErrors
}

struct (0x00000004) CocozJettonMinterJettonUpdateContent {
    queryId: uint64
    content: cell
}

struct (0x178d4519) CocozJettonMinterJettonTransferInternal {
    queryId: uint64
    amount: coins
    sender: address
    responseDestination: address?
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

struct (0x7bdd97de) CocozJettonMinterJettonBurnNotification {
    queryId: uint64
    amount: coins
    sender: address
    responseDestination: address?
}

struct (0x2c76b973) CocozJettonMinterProvideWalletAddress {
    queryId: uint64
    ownerAddress: address
    includeAddress: bool
}

struct (0x00000015) CocozJettonMinterMint {
    queryId: uint64
    destination: address
    tonAmount: coins
    tactContinuation: Cell<CocozJettonMinterMintContinuation>
}

struct CocozJettonMinterMintContinuation {
    mintMessage: CocozJettonMinterJettonTransferInternal
}

struct (0x00000016) CocozJettonMinterCloseMinting {
}

struct (0x00000017) CocozJettonMinterMintForReward {
    queryId: uint64
    destination: address
    tonAmount: coins
    tactContinuation: Cell<CocozJettonMinterMintForRewardContinuation>
}

struct CocozJettonMinterMintForRewardContinuation {
    mintMessage: CocozJettonMinterJettonTransferInternal
}

struct (0x00000018) CocozJettonMinterMintForOperation {
    queryId: uint64
    destination: address
    tonAmount: coins
    tactContinuation: Cell<CocozJettonMinterMintForOperationContinuation>
}

struct CocozJettonMinterMintForOperationContinuation {
    mintMessage: CocozJettonMinterJettonTransferInternal
}

struct (0x00000019) CocozJettonMinterMintForMarinaProtocol {
    queryId: uint64
    destination: address
    tonAmount: coins
    tactContinuation: Cell<CocozJettonMinterMintForMarinaProtocolContinuation>
}

struct CocozJettonMinterMintForMarinaProtocolContinuation {
    mintMessage: CocozJettonMinterJettonTransferInternal
}

struct (0x0000001a) CocozJettonMinterMintForCocozNft {
    queryId: uint64
    destination: address
    tonAmount: coins
    tactContinuation: Cell<CocozJettonMinterMintForCocozNftContinuation>
}

struct CocozJettonMinterMintForCocozNftContinuation {
    mintMessage: CocozJettonMinterJettonTransferInternal
}

struct (0x0000001b) CocozJettonMinterMintForOpenNetwork {
    queryId: uint64
    destination: address
    tonAmount: coins
    tactContinuation: Cell<CocozJettonMinterMintForOpenNetworkContinuation>
}

struct CocozJettonMinterMintForOpenNetworkContinuation {
    mintMessage: CocozJettonMinterJettonTransferInternal
}

struct (0x00000003) CocozJettonMinterChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x0393b1ce) CocozJettonMinterClaimTON {
    destination: address
}

struct (0xaaaa0001) CocozJettonMinterAllocateRewardClaim {
    queryId: uint64
    destinations: map<address, coins>
}

struct (0xaaaa0002) CocozJettonMinterRewardClaimJetton {
    queryId: uint64
}

struct (0xaaaa0003) CocozJettonMinterAllocateOperationClaim {
    queryId: uint64
    destinations: map<address, coins>
}

struct (0xaaaa0004) CocozJettonMinterOperationClaimJetton {
    queryId: uint64
}

struct (0xaaaa0005) CocozJettonMinterAllocateMarinaProtocolClaim {
    queryId: uint64
    destinations: map<address, coins>
}

struct (0xaaaa0006) CocozJettonMinterMarinaProtocolClaimJetton {
    queryId: uint64
}

struct (0xaaaa0007) CocozJettonMinterAllocateCocozNftClaim {
    queryId: uint64
    destinations: map<address, coins>
}

struct (0xaaaa0008) CocozJettonMinterCocozNftClaimJetton {
    queryId: uint64
}

struct (0xaaaa0009) CocozJettonMinterAllocateOpenNetworkClaim {
    queryId: uint64
    destinations: map<address, coins>
}

struct (0xaaaa000a) CocozJettonMinterOpenNetworkClaimJetton {
    queryId: uint64
}

struct (0xaaaa000b) CocozJettonMinterWithdrawAll {
}

struct CocozJettonMinterJettonMinterState {
    totalSupply: coins
    mintable: bool
    adminAddress: address
    jettonContent: cell
    jettonWalletCode: cell
}

struct CocozJettonMinterCocozSupplyState {
    totalSupply: coins
    totalReserveSupply: coins
    rewardTotalSupply: coins
    rewardReserveSupply: coins
    operationTotalSupply: coins
    operationReserveSupply: coins
    marinaProtocolTotalSupply: coins
    marinaProtocolReserveSupply: coins
    tactContinuation: Cell<CocozJettonMinterCocozSupplyStateContinuation>
}

struct CocozJettonMinterCocozSupplyStateContinuation {
    cocozNftTotalSupply: coins
    cocozNftReserveSupply: coins
    openNetworkTotalSupply: coins
    openNetworkReserveSupply: coins
}

struct CocozJettonMinterClaimableSupplyState {
    maxSupply: coins
    totalSupply: coins
    reserveSupply: coins
    claimables: map<address, coins>
}

struct CocozJettonMinterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    jettonContent: cell
    mintable: bool
    totalSupply: coins
    totalReserveSupply: coins
    tactContinuation: Cell<CocozJettonMinterDataContinuation>
}

struct CocozJettonMinterDataContinuation {
    reward: CocozJettonMinterClaimableSupplyState
    operation: CocozJettonMinterClaimableSupplyState
    tactContinuation: Cell<CocozJettonMinterDataContinuation2>
}

struct CocozJettonMinterDataContinuation2 {
    marinaProtocol: CocozJettonMinterClaimableSupplyState
    cocozNft: CocozJettonMinterClaimableSupplyState
    tactContinuation: Cell<CocozJettonMinterDataContinuation3>
}

struct CocozJettonMinterDataContinuation3 {
    openNetwork: CocozJettonMinterClaimableSupplyState
}

type CocozJettonMinterIncomingMessage =
    | CocozJettonMinterAllocateRewardClaim
    | CocozJettonMinterRewardClaimJetton
    | CocozJettonMinterMintForReward
    | CocozJettonMinterAllocateOperationClaim
    | CocozJettonMinterOperationClaimJetton
    | CocozJettonMinterMintForOperation
    | CocozJettonMinterAllocateMarinaProtocolClaim
    | CocozJettonMinterMarinaProtocolClaimJetton
    | CocozJettonMinterMintForMarinaProtocol
    | CocozJettonMinterAllocateCocozNftClaim
    | CocozJettonMinterCocozNftClaimJetton
    | CocozJettonMinterMintForCocozNft
    | CocozJettonMinterAllocateOpenNetworkClaim
    | CocozJettonMinterOpenNetworkClaimJetton
    | CocozJettonMinterMintForOpenNetwork
    | CocozJettonMinterMint
    | CocozJettonMinterProvideWalletAddress
    | CocozJettonMinterJettonBurnNotification
    | CocozJettonMinterJettonUpdateContent
    | CocozJettonMinterChangeOwner
    | CocozJettonMinterCloseMinting
    | CocozJettonMinterClaimTON
    | CocozJettonMinterWithdrawAll

enum CocozJettonMinterErrors {
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
    /// Incorrect balance after send
    IncorrectBalanceAfterSend = 2366
    /// Invalid forward payload in message
    InvalidForwardPayloadInMessage = 2448
    /// State pool is full
    StatePoolIsFull = 4071
    /// Incorrect sender
    IncorrectSender = 9215
    /// Unauthorized burn
    UnauthorizedBurn = 10363
    /// Not admin
    NotAdmin = 20169
    /// Insufficient amount of TON attached
    InsufficientAmountOfTONAttached = 32113
    /// Insufficient gas for mint
    InsufficientGasForMint = 37629
    /// Nothing to claim
    NothingToClaim = 44799
    /// Max pool is full
    MaxPoolIsFull = 47628
    /// Mint is closed
    MintIsClosed = 51950
}

get fun get_jetton_data(): CocozJettonMinterJettonMinterState {
    throw 0;
}

get fun get_wallet_address(ownerAddress: address): address {
    throw 0;
}

get fun get_supply_status(): CocozJettonMinterCocozSupplyState {
    throw 0;
}

get fun get_reward_supply_state(): CocozJettonMinterClaimableSupplyState {
    throw 0;
}

get fun get_operation_supply_state(): CocozJettonMinterClaimableSupplyState {
    throw 0;
}

get fun get_marina_protocol_supply_state(): CocozJettonMinterClaimableSupplyState {
    throw 0;
}

get fun get_cocoz_nft_supply_state(): CocozJettonMinterClaimableSupplyState {
    throw 0;
}

get fun get_open_network_supply_state(): CocozJettonMinterClaimableSupplyState {
    throw 0;
}

get fun get_reward_claimable_amount(address: address): int257 {
    throw 0;
}

get fun get_operation_claimable_amount(address: address): int257 {
    throw 0;
}

get fun get_marina_protocol_claimable_amount(address: address): int257 {
    throw 0;
}

get fun get_cocoz_nft_claimable_amount(address: address): int257 {
    throw 0;
}

get fun get_open_network_claimable_amount(address: address): int257 {
    throw 0;
}
