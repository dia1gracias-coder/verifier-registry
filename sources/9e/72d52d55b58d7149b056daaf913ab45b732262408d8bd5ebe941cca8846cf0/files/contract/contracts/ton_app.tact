// This file is part of the SORA network and Polkaswap app.

// Copyright (c) 2020, 2021, Polka Biome Ltd. All rights reserved.
// SPDX-License-Identifier: BSD-4-Clause

// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:

// Redistributions of source code must retain the above copyright notice, this list
// of conditions and the following disclaimer.
// Redistributions in binary form must reproduce the above copyright notice, this
// list of conditions and the following disclaimer in the documentation and/or other
// materials provided with the distribution.
//
// All advertising materials mentioning features or use of this software must display
// the following acknowledgement: This product includes software developed by Polka Biome
// Ltd., SORA, and Polkaswap.
//
// Neither the name of the Polka Biome Ltd. nor the names of its contributors may be used
// to endorse or promote products derived from this software without specific prior written permission.

// THIS SOFTWARE IS PROVIDED BY Polka Biome Ltd. AS IS AND ANY EXPRESS OR IMPLIED WARRANTIES,
// INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Polka Biome Ltd. BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
// OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
// USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

//! A collection of node-specific RPC methods.
//! Substrate provides the `sc-rpc` crate, which defines the core RPC layer
//! used by Substrate nodes. This file extends those RPC definitions with
//! capabilities that are specific to this project's runtime configuration.

import "@stdlib/deploy";
import "@stdlib/ownable";
import "./bridge_call.tact";
import "./channel.tact";

message SendTon {
    soraAddress: Bytes32;
    amount: Int;
}

message Migrate {
    receiver: Address;
}

message MigrateInternal {}

contract TonApp with Deployable, OwnableTransferable {
    owner: Address; // Channel
    lockedAmount: Int as uint128 = 0;
    stopped: Bool = false;

    init(channel: Address){
        self.owner = channel;
    }

    fun requireOperational() {
        require(self.stopped == false, "App is stopped");
    }

    // lock TON to send it to SORA
    receive(msg: SendTon){
        self.requireOperational();
        require(context().value > msg.amount, "Amount should be greater than value");
        let sender: Address = sender();
        let soraMessage: SoraTonTransferMessage = SoraTonTransferMessage{
            recipient: msg.soraAddress,
            sender: sender,
            amount: msg.amount
        };
        nativeReserve(msg.amount, 4);
        self.lockedAmount += msg.amount;
        send(
            SendParameters {
                to: self.owner,
                value: 0,
                mode: SendRemainingBalance | SendBounceIfActionFail,
                body: SendOutboundMessage {
                    message: soraMessage.encode(),
                    sender: sender()
                }.toCell()
            }
        );
    }
    
    receive(msg: MigrateInternal) {
        self.requireOperational();
        self.lockedAmount += context().value;
    }
    
    receive(msg: Migrate) {
        self.requireOwner();
        self.requireOperational();
        self.stopped = true;
        send(SendParameters{
            to: msg.receiver,
            value: 0,
            mode: SendRemainingBalance | SendIgnoreErrors | SendDestroyIfZero,
            body: MigrateInternal {}.toCell()
        });
    }

    get fun lockedAmount(): Int {
        return self.lockedAmount;
    }

    get fun isStopped(): Bool {
        return self.stopped;
    }
}