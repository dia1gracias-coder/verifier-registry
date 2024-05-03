// Generated from the verified Tact contract ABI.
contract RTendoTokenMaster {
    storage: RTendoTokenMasterData
    incomingMessages: RTendoTokenMasterIncomingMessage
    thrownErrors: RTendoTokenMasterErrors
}

struct (0x946a98b6) RTendoTokenMasterDeploy {
    queryId: uint64
}

struct RTendoTokenMasterJettonData {
    total_supply: coins
    mintable: bool
    admin_address: address
    jetton_content: cell
    jetton_wallet_code: cell
}

struct (0x89b71d09) RTendoTokenMasterJettonMint {
    origin: address
    receiver: address
    amount: int257
    custom_payload: cell?
    forward_ton_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct (0x7bdd97de) RTendoTokenMasterJettonBurnNotification {
    query_id: uint64
    amount: coins
    sender: address
    response_destination: address
}

struct RTendoTokenMasterRole {
    hasRole: map<address, bool>
    adminRole: int257
}

struct (0xc5f9f75e) RTendoTokenMasterGrantRole {
    role: int257
    assignee: address
}

struct (0x3e75bf52) RTendoTokenMasterRevokeRole {
    role: int257
    assignee: address
}

struct (0x546b18b7) RTendoTokenMasterMint {
    to: address
    amount: coins
}

struct (0x20288c35) RTendoTokenMasterClaimRTendoFromIGP {
    signature: cell
    amount: int257
}

struct RTendoTokenMasterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    roles: map<int257, Cell<RTendoTokenMasterRole>>
    total_supply: coins
    mintable: bool
    owner: address
    jetton_content: cell
    public_key: int257
}

type RTendoTokenMasterIncomingMessage =
    | RTendoTokenMasterMint
    | RTendoTokenMasterClaimRTendoFromIGP
    | RTendoTokenMasterDeploy
    | RTendoTokenMasterJettonBurnNotification
    | RTendoTokenMasterJettonMint
    | RTendoTokenMasterGrantRole
    | RTendoTokenMasterRevokeRole

enum RTendoTokenMasterErrors {
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
    /// JettonWallet: Only Jetton master or Jetton wallet can call this function
    JettonWalletOnlyJettonMasterOrJettonWalletCanCallThisFunction = 2296
    /// Sender is not a Jetton wallet
    SenderIsNotAJettonWallet = 9739
    /// JettonWallet: Not enough jettons to transfer
    JettonWalletNotEnoughJettonsToTransfer = 13105
    /// AccessControl: Only user with adminRole can assign a role from a user
    AccessControlOnlyUserWithAdminRoleCanAssignARoleFromAUser = 19358
    /// Only owner can call this function
    OnlyOwnerCanCallThisFunction = 27831
    /// JettonWallet: Not allow negative balance after internal transfer
    JettonWalletNotAllowNegativeBalanceAfterInternalTransfer = 29133
    /// JettonMaster: Jetton is not mintable
    JettonMasterJettonIsNotMintable = 30061
    /// JettonMaster: Caller is not authorized to mint Jetton
    JettonMasterCallerIsNotAuthorizedToMintJetton = 33193
    /// Not enough funds to transfer
    NotEnoughFundsToTransfer = 37185
    /// JettonMaster: Sender is not a Jetton owner
    JettonMasterSenderIsNotAJettonOwner = 43365
    /// JettonWallet: Only owner can burn tokens
    JettonWalletOnlyOwnerCanBurnTokens = 47048
    /// RTendoTokenMaster: Invalid signature
    RTendoTokenMasterInvalidSignature = 47602
    /// AccessControl: Only user with adminRole can revoke a role to a user
    AccessControlOnlyUserWithAdminRoleCanRevokeARoleToAUser = 59314
    /// JettonWallet: Not enough balance to burn tokens
    JettonWalletNotEnoughBalanceToBurnTokens = 60354
}

get fun verifySignature(signature: cell, callerAddress: address, amount: int257): bool {
    throw 0;
}

get fun ton_balance(): int257 {
    throw 0;
}

get fun minter_role(): int257 {
    throw 0;
}

get fun get_jetton_data(): RTendoTokenMasterJettonData {
    throw 0;
}

get fun get_wallet_address(owner_address: address): address {
    throw 0;
}

get fun hasAdminRole(roleHash: int257, user: address): bool {
    throw 0;
}

get fun hasRole(roleHash: int257, user: address): bool {
    throw 0;
}

get fun defaultAdminRole(): int257 {
    throw 0;
}
