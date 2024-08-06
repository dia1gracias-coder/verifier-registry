struct JettonData {
    total_supply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell;
    wallet_code: Cell;
}
struct JettonWalletData {
    balance: Int;
    owner: Address;
    master: Address;
    code: Cell;
}
struct JettonTransferForwardPayload {
    is_right: Bool;
    value: Slice as remaining;
}
message(0xf8a7ea5) TokenTransfer {
    query_id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}
message(0xf8a7ea5) JettonTransfer {
    query_id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: JettonTransferForwardPayload;
}
message(0x178d4519) TokenTransferInternal {
    query_id: Int as uint64;
    amount: Int as coins;
    from: Address;
    response_destination: Address?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}
message(0x7362d09c) TokenNotification {
    query_id: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining;
}
message(0x595f07bc) TokenBurn {
    query_id: Int as uint64;
    amount: Int as coins;
    response_destination: Address?;
    custom_payload: Cell?;
}
message(0x7bdd97de) TokenBurnNotification {
    query_id: Int as uint64;
    amount: Int as coins;
    sender: Address;
    response_destination: Address?;
}
message(0xd53276db) TokenExcesses {
    query_id: Int as uint64;
}
message TokenUpdateContent {
    content: Cell;
}
// ==== TEP89: Jetton Wallet Discovery ====
message(0x2c76b973) ProvideWalletAddress {
    query_id: Int as uint64;
    owner_address: Address;
    include_address: Bool;
}
// take_wallet_address#d1735400
// query_id:uint64 wallet_address:MsgAddress owner_address:(Maybe ^MsgAddress) = InternalMsgBody;
message(0xd1735400) TakeWalletAddress {
    query_id: Int as uint64;
    wallet_address: Address;
    owner_address: Slice as remaining;
}
struct SwapInfo {
    tokenA: Address;
    amount: Int;
}

struct StonFiJettonInfo {
    op: Int as uint32;
    tokenB: Address;
    minReturn: Int as coins;
    recipient_addr: Address;
    referral_addr: Address?;
    invalidQuery: Slice as remaining;
}
struct DedustSuccessInfo {
    op: Int as uint32;
    query_id: Int as uint64;
    user: Address;
}
struct DedustFailInfo {
    op: Int as uint32;
    query_id: Int as uint64;
    user: Address;
    tokenA: Address;
}
struct DedustJettonSwapInfo {
    op: Int as uint32;
    pool: Address;
    kind: Bool;
    minReturn: Int as coins;
    next: Cell?;
    swapParams: Cell;
}
struct DedustNativeSwapInfo {
    op: Int as uint32;
    query_id: Int as uint64;
    amount: Int as coins;
    pool: Address;
    kind: Bool;
    minReturn: Int as coins;
    next: Cell?;
    swapParams: Cell;
}
struct DedustSwapParams {
    deadline: Int as uint32;
    recipient_addr: Address?;
    referral_addr: Address?;
    fufill_payload: Cell?;
    reject_payload: Cell?;
}
struct SwapJettonInDedust {
    op: Int as uint32;
    vaultA: Address;
    pool: Address;
    minReturn: Int as coins;
    recipient_addr: Address?;
    referral_addr: Address?;
    next: Cell?;
    invalidQuery: Slice as remaining;
}
message(0x474f86cf) DedustPayOut {
    query_id: Int as uint64;
    payload: Slice?;
}
message SwapNativeInDedust {
    query_id: Int as uint64;
    amount: Int as coins;
    pool: Address;
    minReturn: Int as coins;
    recipient_addr: Address?;
    referral_addr: Address?;
    next: Cell?;
    invalidQuery: Slice as remaining;
}
struct ValidInfo {
    isValid: Bool;
    op: Int as uint32;
    payload: Slice;
}
message SwapNativeInStonfi {
    query_id: Int as uint64;
    amount: Int as coins;
    tokenB: Address;
    minReturn: Int as coins;
    recipient_addr: Address;
    referral_addr: Address?;
    invalidQuery: Slice as remaining;
}
message WithdrawInfo {
    token: Address?;
    amount: Int? as coins;
    to: Address?;
    value: Int? as coins;
    isNative: Bool;
}
message ChangeFwdFee {
    stonfi_fwd: Int as uint64;
}
message ChangeProcessFee {
    process_fee: Int as uint64;
}
message ChangeMinimumFee {
    minimum_fee: Int as uint64;
}
message ChangeTransferJettonFee {
    transfer_jetton_fee: Int as uint64;
}
message DeleteRecord {
    query_id: Int as uint64;
}
message ChangePub {
    signer_pub: Int as uint256;
}
