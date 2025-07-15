import "@stdlib/ownable"; // Tact's equivalent for ownership
import "@stdlib/deploy"; // For contract deployment

struct ClaimInfo {
    user: Address;
    amount: Int? as int256;
    time: Int as int256;
}

struct PoolInfo {
    //claim info
    claimInfos: map<Int as int256, ClaimInfo>;
    refundInfos: map<Int as int256, ClaimInfo>;
    partialRefundInfos: map<Int as int256, ClaimInfo>;
    bonusInfos: map<Int as int256, ClaimInfo>;

    //user info
    userClaimIds: map<Address, Int as int256>; //Address -> ClaimId
    userClaimStatus: map<Address, Int as int256>; // Address -> TGE_FLAG
    userClaimAmount: map<Address, Int as int256>; // Address -> Token Amount
    userBonusAmount: map<Address, Int as int256>; // Address -> Bonus Token Amoutn
    userRefunded: map<Address, Bool>; // Address -> Refunded
    userPartialRefunded: map<Address, Bool>; // Address => Partial Refunded
    totalClaims: Int as int256;
    totalBonuses: Int as int256;
}
// Messages for operations
message(0x01) Vesting {
    id: Int as int256;
    poolId: Int as int256;
    tgeFlag: Int as int256;
    token: Address;
    amount: Int as int256;
    startTime: Int as int256;
    signature: Slice;
}
message(0x02) Refund {
    id: Int as int256;
    poolId: Int as int256;
    startTime: Int as int256;
    endTime: Int as int256;
    signature: Slice;
}
message(0x03) PartialRefund {
    id: Int as int256;
    poolId: Int as int256;
    startTime: Int as int256;
    endTime: Int as int256;
    signature: Slice;
}
message(0x04) Bonus {
    id: Int as int256;
    poolId: Int as int256;
    token: Address;
    amount: Int as int256;
    startTime: Int as int256;
    signature: Slice;
}
message(0x05) SetSigner {
    signer: Int as uint256;
}
message(0x06) SetStartTime {
    startTime: Int as int256;
}
message(0x07) WithdrawJetton {
    token: Address;
    to: Address;
    amount: Int as int256;
}
message(0x08) SetSignerEvent {
    signer: Int as uint256;
}
message(0x09) SetStartTimeEvent {
    startTime: Int as int256;
}
message(0x10) VestingEvent {
    id: Int as int256;
    sender: Address;
    amount: Int as int256;
}
message(0x11) PartialRefundEvent {
    id: Int as int256;
    sender: Address;
}
message(0x12) RefundEvent {
    id: Int as int256;
    sender: Address;
}
message(0x13) BonusEvent {
    id: Int as int256;
    sender: Address;
    amount: Int as int256;
}

// JettonTransfer message as per TEP-74
message(0xf8a7ea5) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell? = null;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

contract TinyVesting with Ownable {
    poolInfos: map<Int as int256, PoolInfo>;
    owner: Address;
    signer: Int as uint256;

    startTime: Int as uint256;

    init(_signer: Int, _startTime: Int) {
        self.owner = sender();
        self.signer = _signer;
        self.startTime = _startTime;
        self.poolInfos = emptyMap();
    }

    receive() {}

    // Admin functions
    receive(msg: SetSigner) {
        self.requireOwner();
        self.signer = msg.signer;
        emit(SetSignerEvent { signer: msg.signer }.toCell());
    }

    receive(msg: SetStartTime) {
        self.requireOwner();
        self.startTime = msg.startTime;
        emit(SetStartTimeEvent { startTime: msg.startTime }.toCell());
    }

    receive(msg: WithdrawJetton) {
        self.requireOwner();
        require(msg.amount > 0, "Zero amount");
        // Send Jetton transfer message to the token contract
        send(SendParameters {
            to: msg.token,
            value: 0,
            mode: 64,
            bounce: true,
            body: JettonTransfer {
                queryId: now(),
                amount: msg.amount,
                destination: msg.to,
                responseDestination: sender(),
                customPayload: null,
                forwardTonAmount: 0,
                forwardPayload: emptySlice(),
            }.toCell(),
        });
    }

    receive(msg: Vesting) {
        if (self.poolInfos.get(msg.poolId) == null) {
            self.poolInfos.set(msg.poolId, PoolInfo {
                claimInfos: emptyMap(),
                refundInfos: emptyMap(),
                partialRefundInfos: emptyMap(),
                bonusInfos: emptyMap(),

                userClaimIds: emptyMap(),
                userClaimStatus: emptyMap(),
                userClaimAmount: emptyMap(),
                userBonusAmount: emptyMap(),
                userRefunded: emptyMap(),
                userPartialRefunded: emptyMap(),
                totalClaims: 0,
                totalBonuses: 0,
            });
        }
        let poolInfo = self.poolInfos.get(msg.poolId)!!;
        let claimInfo = poolInfo.claimInfos.get(msg.id);
        let userpartialRefunded = poolInfo.userPartialRefunded.get(sender());
        let userRefunded = poolInfo.userRefunded.get(sender());
        let userClaimAmount = poolInfo.userClaimAmount.get(sender());
        if (userClaimAmount == null) {
            userClaimAmount = 0;
        }

        require(userRefunded == null || !userRefunded!!, "Refunded");
        require((userpartialRefunded == null || !userpartialRefunded!!) || (userpartialRefunded == true && msg.tgeFlag == 1), "Partial Refunded");
        require(claimInfo == null || claimInfo!!.amount == 0, "Executed");
        require(now() >= msg.startTime, "Not Start");
        require(msg.amount > 0, "Zero Amount");
        require(userClaimAmount == null || (msg.amount > userClaimAmount!!), "Claimed");

        // Construct data for signature verification
        let data: Builder = beginCell();
        data = data.storeInt(1, 256); // 1 Vesting, 2 Partial Refund, 3 Refund, 4 Bonus
        data = data.storeInt(msg.id, 256);
        data = data.storeInt(msg.poolId, 256);
        data = data.storeInt(msg.tgeFlag, 256);
        data = data.storeAddress(msg.token);
        data = data.storeInt(msg.amount, 256);
        data = data.storeInt(msg.startTime, 256);
        data = data.storeAddress(sender());
        data = data.storeAddress(myAddress());
        let dataSlice: Slice = data.endCell().beginParse();
        require(checkDataSignature(dataSlice, msg.signature, self.signer), "Invalid signature");

        let claimable: Int = msg.amount - userClaimAmount!!;
        poolInfo.claimInfos.set(msg.id, ClaimInfo {
            user: sender(),
            amount: msg.amount,
            time: now(),
        });
        // Create updated userClaimIds
        poolInfo.userClaimIds.set(sender(), msg.id);
        poolInfo.userClaimAmount.set(sender(), userClaimAmount!! + claimable);
        poolInfo.userClaimStatus.set(sender(), msg.tgeFlag);

        // Create new PoolInfo struct
        let newPoolInfo = PoolInfo {
            claimInfos: poolInfo.claimInfos,
            refundInfos: poolInfo.refundInfos,
            partialRefundInfos: poolInfo.partialRefundInfos,
            bonusInfos: poolInfo.bonusInfos,

            userClaimIds: poolInfo.userClaimIds,
            userClaimStatus: poolInfo.userClaimStatus,
            userClaimAmount: poolInfo.userClaimAmount,
            userBonusAmount: poolInfo.userBonusAmount,
            userRefunded: poolInfo.userRefunded,
            userPartialRefunded: poolInfo.userPartialRefunded,

            totalClaims: poolInfo.totalClaims + claimable,
            totalBonuses: poolInfo.totalBonuses,
        };
        // Set updated struct back
        self.poolInfos.set(msg.poolId, newPoolInfo);

        send(SendParameters {
            to: msg.token,
            value: 0,
            mode: 64,
            bounce: true,
            body: JettonTransfer {
                queryId: now(),
                amount: claimable,
                destination: sender(),
                responseDestination: myAddress(),
                customPayload: null,
                forwardTonAmount: 0,
                forwardPayload: emptySlice(),
            }.toCell(),
        });

        emit(VestingEvent { id: msg.id, sender: sender(), amount: msg.amount }.toCell());
    }

    receive(msg: Refund) {
        require(self.signer != 0, "Invalid signer");
        require(now() >= msg.startTime && now() <= msg.endTime, "Invalid time");
        if (self.poolInfos.get(msg.poolId) == null) {
            self.poolInfos.set(msg.poolId, PoolInfo {
                claimInfos: emptyMap(),
                refundInfos: emptyMap(),
                partialRefundInfos: emptyMap(),
                bonusInfos: emptyMap(),
                userClaimIds: emptyMap(),
                userClaimStatus: emptyMap(),
                userClaimAmount: emptyMap(),
                userBonusAmount: emptyMap(),
                userRefunded: emptyMap(),
                userPartialRefunded: emptyMap(),
                totalClaims: 0,
                totalBonuses: 0,
            });
        }

        let poolInfo = self.poolInfos.get(msg.poolId)!!;
        let refundInfo = poolInfo.refundInfos.get(msg.id);
        let userPartialRefunded = poolInfo.userPartialRefunded.get(sender());
        let userRefunded = poolInfo.userRefunded.get(sender());
        let userClaimAmount = poolInfo.userClaimAmount.get(sender());

        require(userPartialRefunded == null || !userPartialRefunded!!, "Already partially refunded");
        require(userRefunded == null || !userRefunded!!, "Already refunded");
        require(userClaimAmount == null || userClaimAmount == 0, "Already claimed");
        require(refundInfo == null || refundInfo!!.amount == null || refundInfo!!.amount == 0, "Already executed");

        let data: Builder = beginCell();
        data = data.storeInt(3, 256); // 3 Refund
        data = data.storeInt(msg.id, 256);
        data = data.storeInt(msg.poolId, 256);
        data = data.storeInt(msg.startTime, 256);
        data = data.storeInt(msg.endTime, 256);
        data = data.storeAddress(sender());
        data = data.storeAddress(myAddress());
        let dataSlice: Slice = data.endCell().beginParse();
        require(checkDataSignature(dataSlice, msg.signature, self.signer), "Invalid signature");

        poolInfo.refundInfos.set(msg.id, ClaimInfo {
            user: sender(),
            amount: 1,
            time: now(),
        });
        poolInfo.userRefunded.set(sender(), true);

        let newPoolInfo = PoolInfo {
            claimInfos: poolInfo.claimInfos,
            refundInfos: poolInfo.refundInfos,
            partialRefundInfos: poolInfo.partialRefundInfos,
            bonusInfos: poolInfo.bonusInfos,
            userClaimIds: poolInfo.userClaimIds,
            userClaimStatus: poolInfo.userClaimStatus,
            userClaimAmount: poolInfo.userClaimAmount,
            userBonusAmount: poolInfo.userBonusAmount,
            userRefunded: poolInfo.userRefunded,
            userPartialRefunded: poolInfo.userPartialRefunded,
            totalClaims: poolInfo.totalClaims,
            totalBonuses: poolInfo.totalBonuses,
        };
        self.poolInfos.set(msg.poolId, newPoolInfo);

        emit(RefundEvent { id: msg.id, sender: sender() }.toCell());
    }

    receive(msg: PartialRefund) {
        require(self.signer != 0, "Invalid signer");
        require(now() >= msg.startTime && now() <= msg.endTime, "Invalid time");
        if (self.poolInfos.get(msg.poolId) == null) {
            self.poolInfos.set(msg.poolId, PoolInfo {
                claimInfos: emptyMap(),
                refundInfos: emptyMap(),
                partialRefundInfos: emptyMap(),
                bonusInfos: emptyMap(),
                userClaimIds: emptyMap(),
                userClaimStatus: emptyMap(),
                userClaimAmount: emptyMap(),
                userBonusAmount: emptyMap(),
                userRefunded: emptyMap(),
                userPartialRefunded: emptyMap(),
                totalClaims: 0,
                totalBonuses: 0,
            });
        }

        let poolInfo = self.poolInfos.get(msg.poolId)!!;
        let partialRefundInfo = poolInfo.partialRefundInfos.get(msg.id);
        let userPartialRefunded = poolInfo.userPartialRefunded.get(sender());
        let userRefunded = poolInfo.userRefunded.get(sender());
        let userClaimStatus = poolInfo.userClaimStatus.get(sender());

        require(userPartialRefunded == null || !userPartialRefunded!!, "Already partially refunded");
        require(userRefunded == null || !userRefunded!!, "Already refunded");
        require(userClaimStatus == null || userClaimStatus!! <= 1, "Vesting in progress");
        require(partialRefundInfo == null || partialRefundInfo!!.amount == null || partialRefundInfo!!.amount == 0, "Already executed");

        let data: Builder = beginCell();
        data = data.storeInt(2, 256); // 2 PartialRefund
        data = data.storeInt(msg.id, 256);
        data = data.storeInt(msg.poolId, 256);
        data = data.storeInt(msg.startTime, 256);
        data = data.storeInt(msg.endTime, 256);
        data = data.storeAddress(sender());
        data = data.storeAddress(myAddress());
        let dataSlice: Slice = data.endCell().beginParse();
        require(checkDataSignature(dataSlice, msg.signature, self.signer), "Invalid signature");

        poolInfo.partialRefundInfos.set(msg.id, ClaimInfo {
            user: sender(),
            amount: 1,
            time: now(),
        });
        poolInfo.userPartialRefunded.set(sender(), true);

        let newPoolInfo = PoolInfo {
            claimInfos: poolInfo.claimInfos,
            refundInfos: poolInfo.refundInfos,
            partialRefundInfos: poolInfo.partialRefundInfos,
            bonusInfos: poolInfo.bonusInfos,
            userClaimIds: poolInfo.userClaimIds,
            userClaimStatus: poolInfo.userClaimStatus,
            userClaimAmount: poolInfo.userClaimAmount,
            userBonusAmount: poolInfo.userBonusAmount,
            userRefunded: poolInfo.userRefunded,
            userPartialRefunded: poolInfo.userPartialRefunded,
            totalClaims: poolInfo.totalClaims,
            totalBonuses: poolInfo.totalBonuses,
        };
        self.poolInfos.set(msg.poolId, newPoolInfo);

        emit(PartialRefundEvent { id: msg.id, sender: sender() }.toCell());
    }

    receive(msg: Bonus) {
        require(self.signer != 0, "Invalid signer");
        require(msg.amount > 0, "Zero amount");
        if (self.poolInfos.get(msg.poolId) == null) {
            self.poolInfos.set(msg.poolId, PoolInfo {
                claimInfos: emptyMap(),
                refundInfos: emptyMap(),
                partialRefundInfos: emptyMap(),
                bonusInfos: emptyMap(),
                userClaimIds: emptyMap(),
                userClaimStatus: emptyMap(),
                userClaimAmount: emptyMap(),
                userBonusAmount: emptyMap(),
                userRefunded: emptyMap(),
                userPartialRefunded: emptyMap(),
                totalClaims: 0,
                totalBonuses: 0,
            });
        }

        let poolInfo = self.poolInfos.get(msg.poolId)!!;
        let bonusInfo = poolInfo.bonusInfos.get(msg.id);
        let userBonusAmount = poolInfo.userBonusAmount.get(sender());

        require(bonusInfo == null || bonusInfo!!.amount == null || bonusInfo!!.amount == 0, "Already executed");
        require(userBonusAmount == null || userBonusAmount == 0, "Already claimed");

        let data: Builder = beginCell();
        data = data.storeInt(4, 256); // 4 Bonus
        data = data.storeInt(msg.id, 256);
        data = data.storeInt(msg.poolId, 256);
        data = data.storeAddress(msg.token);
        data = data.storeInt(msg.amount, 256);
        data = data.storeInt(msg.startTime, 256);
        data = data.storeAddress(sender());
        data = data.storeAddress(myAddress());
        let dataSlice: Slice = data.endCell().beginParse();
        require(checkDataSignature(dataSlice, msg.signature, self.signer), "Invalid signature");

        poolInfo.bonusInfos.set(msg.id, ClaimInfo {
            user: sender(),
            amount: msg.amount,
            time: now(),
        });

        let newPoolInfo = PoolInfo {
            claimInfos: poolInfo.claimInfos,
            refundInfos: poolInfo.refundInfos,
            partialRefundInfos: poolInfo.partialRefundInfos,
            bonusInfos: poolInfo.bonusInfos,
            userClaimIds: poolInfo.userClaimIds,
            userClaimStatus: poolInfo.userClaimStatus,
            userClaimAmount: poolInfo.userClaimAmount,
            userBonusAmount: poolInfo.userBonusAmount,
            userRefunded: poolInfo.userRefunded,
            userPartialRefunded: poolInfo.userPartialRefunded,
            totalClaims: poolInfo.totalClaims,
            totalBonuses: poolInfo.totalBonuses + msg.amount,
        };

        send(SendParameters {
            to: msg.token,
            value: 0,
            mode: 64,
            bounce: true,
            body: JettonTransfer {
                queryId: now(),
                amount: msg.amount,
                destination: sender(),
                responseDestination: myAddress(),
                customPayload: null,
                forwardTonAmount: 0,
                forwardPayload: emptySlice(),
            }.toCell(),
        });

        emit(BonusEvent { id: msg.id, sender: sender(), amount: msg.amount }.toCell());
    }

    get fun getUserRefunded(poolId: Int, user: Address): Bool? {
        let poolInfo = self.poolInfos.get(poolId);
        return poolInfo!!.userRefunded.get(user);
    }

    get fun getUserParitalRefunded(poolId: Int, user: Address): Bool? {
        let poolInfo = self.poolInfos.get(poolId);
        if (poolInfo == null) {
            return null;
        }
        return poolInfo!!.userPartialRefunded.get(user);
    }

    get fun getUserClaimStatus(poolId: Int, user: Address): Int? {
        let poolInfo = self.poolInfos.get(poolId);
        if (poolInfo == null) {
            return null;
        }
        return poolInfo!!.userClaimIds.get(user);
    }

    get fun getSigner(): Int? {
        return self.signer
    }
    get fun getStartTime(): Int? {
        return self.startTime
    }

}
