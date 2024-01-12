// SPDX-License-Identifier: AGPL-3.0
// Copyright (C) Microcosm Labs 2023
// Authors: @0kenx
// GitHub: https://github.com/microcosm-labs

import "@stdlib/deploy";
import "@stdlib/ownable";
import "./utils/transfer_helpers";
import "./utils/string";

message ConsentReply {
    addr: Address;
    accepted: Bool;
}

message GiveConsent {
    addr: Address;
    referrer: Address;
}

message RescueJetton {
    jetton_wallet_address: Address;
    amount: Int as coins;
    receiver: Address;
}

// On-chain ToS registry. Users must sign the message with a 0 TON transaction to use the services.
// Timestamp and signature can be read off chain.
// If there's any update to the ToS this contract needs to be redeployed.
// Consent messages:
// I accept the ToS of TonUP. SHA256:8a5b220..37b75ca.
// I accept the ToS of TonUP. SHA256:8a5b220..37b75ca. Referrer:UQBdkc21GDk6qljMT1D4iW-xSCHSSSyXdw-zefAmqtqynejH
contract TonupTosRegistryV2 with Deployable, Ownable {
    const CURRENT_VERSION: Int = 2;
    const CONSENT_MSG: String = "I accept the ToS of TonUP. SHA256:8a5b220..37b75ca.";
    const STORAGE_GAS_RESERVE: Int = ton("0.2");
    const GAS_CHECK_ACCEPT: Int = ton("0.2");
    const GAS_CONSUMPTION: Int = ton("0.03");
    
    owner: Address;
    number_users: Int as uint32 = 0;
    
    init(owner: Address) {
        self.owner = owner;
    }

    // ======================== User Interface ========================

    /// Users send this message to accept ToS
    receive(msg: String) {
        require(context().value >= self.GAS_CHECK_ACCEPT, "Not enough gas");
        if (msg.ss_starts_with(self.CONSENT_MSG)) {
            let ref: Address = newAddress(0, 0);
            let s: Slice = msg.asSlice();
            if (s.bits() == 872) {
                s.skipBits(488);
                let refs: Slice = s.ss_parse_address();
                ref = refs.loadAddress();  
            }
            let winit: StateInit = self.user_child_init(sender());
            GiveConsent{
                addr: sender(),
                referrer: ref
            }.toCell().send_and_deploy(winit);
        }
    }

    // ======================== Inter Contract Interface ========================
    receive(msg: ConsentReply) {
        require(sender() == self.user_child_address(msg.addr), "Unauthorized");
        require(msg.accepted, "Consent error");
        self.number_users = self.number_users + 1;

        let msg_value: Int = self.msg_value(context().value);  
        let fwd_fee: Int = context().readForwardFee();
        msg_value = msg_value - fwd_fee;
        send_ton(msg.addr, msg_value, false, "Refund Gas".asComment()); 
    }

    // ======================== Admin Interface ========================
    // Fund the contract
    receive("fund gas") {}

    /// Withdraw dust
    receive("withdraw dust") {
        self.requireOwner();
        let dust_to_claim: Int = 0;
        dust_to_claim = myBalance() - context().value - self.STORAGE_GAS_RESERVE;
        send_ton(self.owner, dust_to_claim, false, "Withdraw dust".asComment());
    }

    receive(msg: RescueJetton) {
        self.requireOwner();
        send_jetton_text(msg.jetton_wallet_address, msg.receiver, msg.amount, 0, false, "Jetton rescue");
    }

    // ======================== Internal Methods ========================
    inline fun user_child_address(user: Address): Address {
        return contractAddress(initOf TonupTosV2Child(myAddress(), user));
    }

    inline fun user_child_init(user: Address): StateInit {
        return initOf TonupTosV2Child(myAddress(), user);
    }

    // ======================== View Interface ========================

    get fun msg_value(value: Int): Int {
        let msg_value: Int = value;
        let ton_balance_before_msg: Int = myBalance() - msg_value;
        let storage_fee: Int = self.STORAGE_GAS_RESERVE - min(ton_balance_before_msg, self.STORAGE_GAS_RESERVE);
        msg_value = msg_value - (storage_fee + self.GAS_CONSUMPTION);
        return msg_value;
    }

    get fun userChildAddress(user: Address): Address {
        return self.user_child_address(user);
    }

    get fun consentMessage(): String {
        return self.CONSENT_MSG;
    }

    get fun currentVersion(): Int {
        return self.CURRENT_VERSION;
    }

    get fun numberUsers(): Int {
        return self.number_users;
    }

    get fun balance(): Int {
        return myBalance();
    }
}

contract TonupTosV2Child {
    const STORAGE_GAS_RESERVE: Int = ton("0.02");
    const GAS_CONSUMPTION: Int = ton("0.015");

    owner: Address;
    master: Address;
    referrer: Address;

    consent_time: Int as uint64 = 0;

    init(master: Address, owner: Address) {
        self.owner = owner;
        self.master = master;
        self.referrer = newAddress(0, 0);
    }

    receive("fund gas") {}

    receive(msg: GiveConsent) {
        require(sender() == self.master, "Unauthorized");
        require(msg.addr == self.owner, "Unreachable");
        require(self.consent_time == 0, "Already consented");
        self.consent_time = now();
        self.referrer = msg.referrer;
        let msg_value: Int = self.msg_value(context().value);
        ConsentReply{addr: msg.addr, accepted: true}.toCell().reply_value(msg_value);
    }

    receive("read") {
        if (self.consent_time > 0) {
            let ctx: Context = context();
            let fwd_fee: Int = ctx.readForwardFee() + ctx.readForwardFee();  
            let final: Int =  2 * self.GAS_CONSUMPTION + self.STORAGE_GAS_RESERVE + fwd_fee;
            require(ctx.value > min(final, ton("0.02")), "Invalid value!!");
            let msg_value: Int = self.msg_value(context().value);
            ConsentReply{addr: self.owner, accepted: true}.toCell().reply_value(msg_value);
        }
    }

    // ------------------------ Getters ------------------------

    get fun msg_value(value: Int): Int {
        let msg_value: Int = value;
        let ton_balance_before_msg: Int = myBalance() - msg_value;
        let storage_fee: Int = self.STORAGE_GAS_RESERVE - min(ton_balance_before_msg, self.STORAGE_GAS_RESERVE);
        msg_value = msg_value - (storage_fee + self.GAS_CONSUMPTION);
        return msg_value;
    }

    get fun hasAccepted(): Bool {
        return self.consent_time > 0;
    }

    get fun consentTime(): Int {
        return self.consent_time;
    }

    get fun referrer(): Address {
        return self.referrer;
    }

    get fun balance(): Int {
        return myBalance();
    }
}
