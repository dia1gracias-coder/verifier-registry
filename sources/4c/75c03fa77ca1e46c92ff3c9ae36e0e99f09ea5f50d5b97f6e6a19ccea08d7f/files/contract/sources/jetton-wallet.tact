//  SPDX-License-Identifier: MIT
//  Copyright © 2025 Rubeton Studio

import "./messages";
import "./constants";

contract JettonWallet(
    owner: Address,
    minter: Address,
    distributor: Address,
    balance: Int as coins,
) {
    receive(msg: JettonTransfer) {
        forceBasechain(msg.destination);
        require(sender() == self.owner, "Incorrect sender");

        let maybeOp = self.readOpFromForward(msg.forwardPayload);
        let isSwap: Bool = (maybeOp != null) && (
            maybeOp!! == op_stonfi_swap
            || maybeOp!! == op_stonfi_swap_ok
            || maybeOp!! == op_dedust_swap
            || maybeOp!! == op_dedust_swap1   
            || maybeOp!! == op_dedust_swap3
            || maybeOp!! == op_dedust_swap4
            || maybeOp!! == op_dedust_swap5
        );

        self.balance -= msg.amount;
        let inc: Int = muldivc(msg.amount, 75, 100);
        let ctx = context();
        
        require(self.balance >= 0, "Incorrect balance after send");

        deploy(DeployParameters {
            value: ton("0.05") + msg.forwardTonAmount,
            mode: SendDefaultMode,
            bounce: true,
            body: JettonTransferInternal {
                queryId: msg.queryId,
                amount: isSwap ? inc : msg.amount,
                sender: self.owner,
                responseDestination: msg.responseDestination,
                forwardTonAmount: msg.forwardTonAmount,
                forwardPayload: msg.forwardPayload,
            }.toCell(),
            init: initOf JettonWallet(msg.destination, self.minter, self.distributor, 0),
        });


        if(isSwap) {
            self.sendShare(msg.queryId, msg.amount - inc, msg.responseDestination);
        }
    }

    inline fun readOpFromForward(sl: Slice): Int? {
        
        if (sl.bits() >= 32) {
            return sl.preloadUint(32);
        }
       
        if (sl.refs() > 0) {
            let s1: Slice = sl.preloadRef().beginParse();
            if (s1.bits() >= 32) {
                return s1.preloadUint(32);
            }
        }
        return null;
    }

    receive(msg: JettonTransferInternal) {
        let wallet: StateInit = initOf JettonWallet(msg.sender, self.minter, self.distributor, 0);
        if (!wallet.hasSameBasechainAddress(sender())) {
            require(self.minter == sender(), "Incorrect sender");
        }

        let ctx: Context = context();
          
        self.balance += msg.amount;

        let msgValue: Int = ctx.value;
        let tonBalanceBeforeMsg = myBalance() - msgValue;

        if (msg.forwardTonAmount > 0) {
            let fwdFee: Int = ctx.readForwardFee();
            msgValue -= msg.forwardTonAmount + fwdFee;
            message(MessageParameters {
                to: self.owner,
                value: msg.forwardTonAmount,
                mode: SendPayGasSeparately,
                bounce: false,
                body: JettonNotification { 
                    queryId: msg.queryId,
                    amount: msg.amount,
                    sender: msg.sender,
                    forwardPayload: msg.forwardPayload,
                }.toCell(),
            });
        }
        nativeReserve(max(tonBalanceBeforeMsg, minTonsForStorage), ReserveAtMost);
        if (msg.responseDestination != null && msgValue > 0) {
            message(MessageParameters {
                to: msg.responseDestination!!,
                value: msgValue,
                mode: SendRemainingBalance + SendIgnoreErrors,
                bounce: false,
                body: JettonExcesses { queryId: msg.queryId }.toCell(),
            });
        }
    }

    inline fun sendShare(queryId: Int, amount: Int, responseDestination: Address?) {
         deploy(DeployParameters {
                value: ton("0.02"),
                mode: SendDefaultMode,
                bounce: true,
                body: JettonTransferInternal {
                    queryId: queryId,
                    amount: amount,
                    sender: self.owner,
                    responseDestination: responseDestination,
                    forwardTonAmount: 0,
                    forwardPayload: beginCell().storeUint(queryId, 64).asSlice(),
                }.toCell(),
                init: initOf JettonWallet(self.distributor, self.minter, self.distributor, 0),
            });
    }

    receive(msg: ProvideWalletBalance) {
        let info: VerifyInfo? = null;
        if (msg.includeVerifyInfo) {
            info = VerifyInfo {
                minter: self.minter,
                owner: self.owner,
                code: myCode(),
            };
        }

        message(MessageParameters {
            body: TakeWalletBalance {
                balance: self.balance,
                verifyInfo: info,
            }.toCell(),
            to: msg.receiver,
            value: 0,
            mode: SendRemainingValue,
        });
    }

    receive(msg: JettonBurn) {
        require(sender() == self.owner, "Incorrect sender");

        self.balance -= msg.amount;
        require(self.balance >= 0, "Incorrect balance after send");

        let ctx = context();
        let fwdFee: Int = ctx.readForwardFee();
        require(ctx.value > (fwdFee + 2 * getComputeFee(gasForBurn, false)), "Insufficient amount of TON attached");

        message(MessageParameters {
            to: self.minter,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: JettonBurnNotification {
                queryId: msg.queryId,
                amount: msg.amount,
                sender: self.owner,
                responseDestination: msg.responseDestination,
            }.toCell(),
        });
    }

    receive(msg: ClaimTON) {
        require(sender() == self.owner, "Incorrect sender");
        nativeReserve(minTonsForStorage, ReserveExact | ReserveBounceIfActionFail);

        message(MessageParameters {
            to: msg.receiver,
            value: 0,
            mode: SendRemainingBalance,
        });
    }

    receive() {
        //do nothing
    }

    receive(_: JettonExcesses) {
        //do nothing
    }

    bounced(msg: bounced<JettonTransferInternal>) {
        self.balance += msg.amount;
    }

    bounced(msg: bounced<JettonBurnNotification>) {
        self.balance += msg.amount;
    }

    get fun get_wallet_data(): JettonWalletData {
        return JettonWalletData {
            balance: self.balance,
            owner: self.owner,
            minter: self.minter,
            code: myCode(),
        };
    }
}
