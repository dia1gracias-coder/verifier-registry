/// SPDX-License-Identifier: AGPL-3.0
/// Copyright (C) Microcosm Labs 2023
/// Tact transfer helper library
/// Author: @0kenx
/// Version: 0.2.0
/// GitHub: https://github.com/microcosm-labs

message(0xf8a7ea5) JettonTransfer {
    query_id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x7362d09c) JettonTransferNotification {
    query_id: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forward_payload: Slice as remaining;
}

message(0x595f07bc) JettonBurn {
    query_id: Int as uint64;
    amount: Int as coins;
    response_destination: Address;
    custom_payload: Cell?;
}

message(0x7bdd97de) JettonBurnNotification {
    query_id: Int as uint64;
    amount: Int as coins;
    sender: Address;
    response_destination: Address?;
}

message(0xd53276db) JettonExcesses {
    query_id: Int as uint64;
}

extends inline fun send_to(self: Cell, to: Address) {
    send(SendParameters{
        to: to,
        value: 0,
        bounce: false,
        mode: SendRemainingValue + SendIgnoreErrors,
        body: self
    });
}

extends inline fun send_and_deploy(self: Cell, to: StateInit) {
    send(SendParameters{
        to: contractAddress(to),
        value: 0,
        bounce: false,
        mode: SendRemainingValue + SendIgnoreErrors,
        body: self,
        code: to.code,
        data: to.data
    });
}

extends inline fun reply(self: Cell) {
    send(SendParameters{
        to: sender(),
        value: 0,
        bounce: false,
        mode: SendRemainingValue + SendIgnoreErrors,
        body: self
    });
}

extends inline fun reply_value(self: Cell, value: Int) {
    send(SendParameters{
        to: sender(),
        value: value,
        bounce: false,
        mode: SendIgnoreErrors,
        body: self
    });
}

/// Refund all remaining value to sender
/// The contract would pay approximately 0.01 TON 
inline fun refund_gas() {
    send(SendParameters{
        to: sender(),
        value: 0,
        mode: SendRemainingValue + SendIgnoreErrors,
        bounce: false
    });
}

inline fun refund_gas_to_user(user: Address) {
    send(SendParameters{
        to: user,
        value: 0,
        mode: SendRemainingValue + SendIgnoreErrors,
        bounce: false
    });
}

inline fun send_ton(
    to: Address, 
    value: Int, 
    bounce: Bool, 
    body: Cell? 
) {
    if (value > 0) {
        send(SendParameters{
            value: value, 
            to: to, 
            bounce: bounce, 
            mode: SendIgnoreErrors, 
            body: body 
        });
    }
}

inline fun send_ton_with_ramaining(
    to: Address, 
    value: Int, 
    bounce: Bool, 
    body: Cell?
) {
    if (value > 0) {
        send(SendParameters{
            value: value, 
            to: to, 
            bounce: bounce, 
            mode: SendIgnoreErrors + SendRemainingValue, 
            body: body
        });
    }
}

inline fun send_ton_text(
    to: Address, 
    value: Int, 
    bounce: Bool, 
    msg: String 
) {
    if (value > 0) {
        send(SendParameters{
            value: value, 
            to: to, 
            bounce: bounce, 
            mode: SendIgnoreErrors, 
            body: msg.asSlice().asCell()
        });
    }
}

inline fun send_ton_with_ramaining_text(
    to: Address, 
    value: Int, 
    bounce: Bool, 
    msg: String
) {
    if (value > 0) {
        send(SendParameters{
            value: value, 
            to: to, 
            bounce: bounce, 
            mode: SendIgnoreErrors + SendRemainingValue, 
            body: msg.asSlice().asCell()
        });
    }
}

/// `jetton_address`: my jetton wallet address
/// `to`: destination user address (smart contract or wallet contract)
/// `amount`: amount of jetton to send
/// `query_id`: custom query id
/// `bounce`: bounce flag
/// `forward_payload`: payload to forward as JettonNotification to destination's user address
inline fun send_jetton(
    jetton_address: Address, 
    to: Address, 
    amount: Int, 
    query_id: Int, 
    bounce: Bool,
    forward_payload: Slice
) {
    if (amount > 0) {
        send(SendParameters{
            value: ton("0.1"), 
            to: jetton_address, 
            mode: 0,
            body: JettonTransfer {
                query_id: query_id,
                amount: amount,
                destination: to,
                response_destination: myAddress(),
                custom_payload: null,
                forward_ton_amount: ton("0.01"),  // forward for notification
                forward_payload: forward_payload
            }.toCell(),
            bounce: bounce 
        });
    }
}

inline fun send_jetton_with_ton(
    jetton_address: Address, 
    to: Address, 
    amount: Int, 
    amount_ton: Int,
    query_id: Int, 
    bounce: Bool,
    forward_payload: Slice
) {
    if (amount > 0) {
        send(SendParameters{
            value: ton("0.1") + amount_ton, 
            to: jetton_address, 
            mode: 0,
            body: JettonTransfer {
                query_id: query_id,
                amount: amount,
                destination: to,
                response_destination: myAddress(),
                custom_payload: null,
                forward_ton_amount: amount_ton,
                forward_payload: forward_payload
            }.toCell(),
            bounce: bounce 
        });
    }
}

inline fun send_jetton_text(
    jetton_address: Address, 
    to: Address, 
    amount: Int, 
    query_id: Int, 
    bounce: Bool,
    forward_payload: String
) {
    if (amount > 0) {
        send(SendParameters{
            value: ton("0.1"), 
            to: jetton_address, 
            mode: 0,
            body: JettonTransfer {
                query_id: query_id,
                amount: amount,
                destination: to,
                response_destination: myAddress(),
                custom_payload: null,
                forward_ton_amount: ton("0.01"),  // forward for notification
                forward_payload: forward_payload.asSlice()
            }.toCell(),
            bounce: bounce 
        });
    }
}

inline fun send_jetton_with_ton_text(
    jetton_address: Address, 
    to: Address, 
    amount: Int, 
    amount_ton: Int,
    query_id: Int, 
    bounce: Bool,
    forward_payload: String
) {
    if (amount > 0) {
        send(SendParameters{
            value: ton("0.1") + amount_ton, 
            to: jetton_address, 
            mode: 0,
            body: JettonTransfer {
                query_id: query_id,
                amount: amount,
                destination: to,
                response_destination: myAddress(),
                custom_payload: null,
                forward_ton_amount: amount_ton,
                forward_payload: forward_payload.asSlice()
            }.toCell(),
            bounce: bounce 
        });
    }
}

/// `jetton_address`: my jetton wallet address
inline fun burn_jetton(
    jetton_address: Address, 
    amount: Int, 
    query_id: Int, 
    bounce: Bool,
    custom_payload: Cell?
) {
    if (amount > 0) {
        send(SendParameters{
            value: ton("0.1"), 
            to: jetton_address, 
            mode: 0,
            body: JettonBurn {
                query_id: query_id,
                amount: amount,
                response_destination: myAddress(),
                custom_payload: custom_payload
            }.toCell(),
            bounce: bounce 
        });
    }
}

