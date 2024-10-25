const OP_JettonTransfer: Int = 0x0f8a7ea5;

message(0x0f8a7ea5) JettonTransfer {
    query_id: Int as uint64; // arbitrary request number
    amount: Int as coins; // amount of jettons to transfer
    destination: Address; // address of the new owner of the jettons
    response_destination: Address; // address where to send a response with confirmation of a successful transfer and the rest of the incoming message Toncoins.
    custom_payload: Cell?; // optional custom payload
    forward_ton_amount: Int as coins; // the amount of nanotons to be sent to the destination address.
    forward_payload: Slice as remaining; // optional custom data that should be sent to the destination address.
}
message(0x7362d09c) JettonTransferNotification {
    query_id: Int as uint64; // arbitrary request number
    amount: Int as coins; // amount of jettons to transfer
    sender: Address; // address of the sender of the jettons
    forward_payload: Slice as remaining; // optional custom payload
}
message(0x595f07bc) JettonBurn {
    query_id: Int as uint64; // arbitrary request number
    amount: Int as coins; // amount of jettons to burn
    response_destination: Address; // address where to send a response with confirmation of a successful burn and the rest of the incoming message coins.
    custom_payload: Cell?; // optional custom payload
}
message(0xd53276db) JettonExcesses {
    query_id: Int as uint64; // arbitrary request number
}
message(0x178d4519) JettonInternalTransfer {
    query_id: Int as uint64; // arbitrary request number
    amount: Int as coins; // amount of jettons to transfer
    from: Address; // address of the sender of the jettons
    response_address: Address?; // address where to send a response with confirmation of a successful transfer and the rest of the incoming message coins.
    forward_ton_amount: Int as coins; // the amount of nanotons to be sent to the destination address.
    forward_payload: Slice as remaining; // optional custom data that should be sent to the destination address.
}
message(0x7bdd97de) JettonBurnNotification {
    query_id: Int as uint64; // arbitrary request number
    amount: Int as coins; // amount of jettons to burn
    sender: Address; // address of the sender of the jettons
    response_destination: Address; // address where to send a response with confirmation of a successful burn and the rest of the incoming message coins.
}
struct WalletData {
    balance: Int as coins; // amount of jettons on wallet
    owner: Address; // address of wallet owner;
    jetton: Address; // address of Jetton master-address
    jetton_wallet_code: Cell; // with code of this wallet
}

const STATUS_SIZE: Int = 4;
fun pack_jetton_wallet_data(status: Int, balance: Int, owner: Address, jetton_master: Address): Cell {
    return beginCell()
        .storeUint(status, STATUS_SIZE)
        .storeCoins(balance)
        .storeAddress(owner)
        .storeAddress(jetton_master)
        .endCell();
}

fun calculate_jetton_wallet_state_init(owner: Address, jetton_master: Address, jetton_wallet_code: Cell): Cell {
    return beginCell()
        .storeUint(0, 2)
        .storeUint(1, 1)
        .storeRef(jetton_wallet_code)
        .storeUint(1, 1)
        .storeRef(pack_jetton_wallet_data(0, 0, owner, jetton_master))
        .storeUint(0, 1) // Empty libraries
        .endCell();
}

// NOTE: ref - https://github.com/tact-lang/tact/blob/b38457330dd34190367a036983ca7ef225128ae3/src/generator/writers/writeStdlib.ts#L106
fun calculate_jetton_wallet_address(owner: Address, jetton_master: Address, jetton_wallet_code: Cell): Address {
    let state_init = calculate_jetton_wallet_state_init(owner, jetton_master, jetton_wallet_code);
    return beginCell()
        .storeUint(2, 2)
        .storeUint(0, 1)
        .storeUint(0, 8)
        .storeUint(state_init.hash(), 256)
        .endCell()
        .asSlice()
        .loadAddress();
}
