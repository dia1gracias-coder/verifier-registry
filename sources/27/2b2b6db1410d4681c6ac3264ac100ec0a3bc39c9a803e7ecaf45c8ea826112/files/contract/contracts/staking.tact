import "./jetton_minter_feature_rich.tact";
import "./jetton_wallet_feature_rich.tact";
import "./messages.tact";
import "@stdlib/ownable";

// === Messages ===
message SetJettonAddressRequest {
    thisContractJettonWallet: Address;
}

message SetVestingContractAddressRequest {
    vestingContractAddress: Address;
}

message Unstake {
    stakeId: Int as uint64;
}

message UnstakeMultiple {
    stakeIds: map<Int as uint16, Int as uint64>;
    count: Int as uint16;
}

struct AddStake {
    owner: Address;
    jettonStakeAmount: Int as coins;
    lockDurationIndex: Int as uint8;
}

message Upgrade {
    stakeId: Int as uint64;
    lockDurationIndex: Int as uint8;
}

message SetLockDurations {
    durations: map<Int as uint8, Int as uint32>;
}

message AddAuthorizedStaker {
    staker: Address;
}

message RemoveAuthorizedStaker {
    staker: Address;
}

message(0x5354414b) StakeEvent {
    senderAddress: Address;
    jettonAmount: Int as coins;
    lockEndTime: Int as uint64;
    lockDurationIndex: Int as uint8;
    stakeId: Int as uint64;
}

message(0x554e5354) UnstakeEvent {
    senderAddress: Address;
    stakeId: Int as uint64;
}

message StakeError {
    senderAddress: Address;
    jettonAmount: Int as coins;
    errorMessage: String;
}

// === Structs ===
struct StakeRecord {
    owner: Address;
    jettonStakeAmount: Int as coins;
    lockEndTime: Int as uint64;
}

struct StakingData {
    thisContractJettonWallet: Address;
}

// === Contract ===
contract StakingContract with Ownable {
    owner: Address;
    jettonMaster: Address;
    thisContractJettonWallet: Address?;
    vestingContractAddress: Address?;
    nextStakeId: Int as uint64;  // Global counter for stake IDs
    stakes: map<Int as uint64, StakeRecord>;  // Map from global stake ID to stake record
    userStakeCount: map<Address, Int as uint16>;  // Track number of stakes per user
    lockDurations: map<Int as uint8, Int as uint32>;
    authorizedStakers: map<Address, Bool>;  // Wallets allowed to stake on behalf of others

    init(owner: Address, jettonMaster: Address) {
        self.owner = owner;
        self.jettonMaster = jettonMaster;
        self.nextStakeId = 0;
    }

    // Accept empty messages (e.g. cashback, simple TON transfers)
    receive() {}

    // Accept JettonExcesses (0xd53276db) messages from jetton wallets
    receive(msg: JettonExcesses) {}

    receive(stake: JettonNotification) {
        require(context().value >= ton("0.05"), "Not enough value");
        require(self.thisContractJettonWallet != null, "Jetton wallet not set");
        require(sender() == self.thisContractJettonWallet!!, "Invalid sender");
        require(stake.amount >= 1000000000, "Minimum stake is 1 jetton");

        // Parse lock duration index and stake owner address from forwardPayload.
        let lockDurationIndex: Int = stake.forwardPayload.loadUint(8);
        let stakerAddress: Address = stake.forwardPayload.loadAddress();

        let isVesting: Bool = stake.sender == self.vestingContractAddress;
        let isAuthorized: Bool = self.authorizedStakers.get(stake.sender) == true;
        require(
            stake.sender == stakerAddress || isVesting || isAuthorized,
            "Invalid staker address"
        );

        self.addStake(AddStake{
            owner: stakerAddress,
            lockDurationIndex: lockDurationIndex,
            jettonStakeAmount: stake.amount
        });

        // Vesting flow refunds gas to the user being credited; authorized / self
        // flows refund to the actual TON payer.
        if (isVesting) {
            cashback(stakerAddress);
        } else {
            cashback(stake.sender);
        }
    }

    receive(msg: SetJettonAddressRequest) {
        self.requireOwner();

        // Verify that the provided wallet address belongs to the correct jetton master
        let expectedWallet: Address = contractAddress(
            initOf JettonWalletFeatureRich(myAddress(), self.jettonMaster, 0)
        );
        require(msg.thisContractJettonWallet == expectedWallet, "Wallet address does not match jetton master");

        self.thisContractJettonWallet = msg.thisContractJettonWallet;
    }

    receive(msg: SetVestingContractAddressRequest) {
        self.requireOwner();
        self.vestingContractAddress = msg.vestingContractAddress;
    }

    receive(msg: SetLockDurations) {
        self.requireOwner();
        self.lockDurations = msg.durations;
    }

    receive(msg: AddAuthorizedStaker) {
        self.requireOwner();
        self.authorizedStakers.set(msg.staker, true);
    }

    receive(msg: RemoveAuthorizedStaker) {
        self.requireOwner();
        self.authorizedStakers.set(msg.staker, null);
    }

    receive(msg: ChangeOwner) {
        self.requireOwner();
        self.owner = msg.newOwner;
    }

    receive(msg: Unstake) {
        require(context().value >= ton("0.1"), "Not enough value");
        let stake = self.unstake(msg.stakeId);

        send(SendParameters {
            to: self.thisContractJettonWallet!!,
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors,
            bounce: false,
            body: JettonTransfer {
                queryId: 0,
                amount: stake.jettonStakeAmount,
                destination: stake.owner,
                responseDestination: stake.owner,
                customPayload: null,
                forwardTonAmount: ton("0.01"),
                forwardPayload: beginCell().storeUint(0, 1).endCell().beginParse()
            }.toCell()
        });
        cashback(sender());
    }

    receive(msg: UnstakeMultiple) {
        require(msg.count > 0, "Empty stake list");
        require(msg.count <= 50, "Too many stakes");
        require(context().value >= ton("0.02") * msg.count + ton("0.05"), "Not enough value");

        let totalAmount: Int = 0;
        let unstaker = sender();
        let i: Int = 0;
        while (i < msg.count) {
            let idOpt = msg.stakeIds.get(i);
            require(idOpt != null, "Missing stake id");
            let stake = self.unstake(idOpt!!);
            totalAmount = totalAmount + stake.jettonStakeAmount;
            i = i + 1;
        }

        send(SendParameters {
            to: self.thisContractJettonWallet!!,
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors,
            bounce: false,
            body: JettonTransfer {
                queryId: 0,
                amount: totalAmount,
                destination: unstaker,
                responseDestination: unstaker,
                customPayload: null,
                forwardTonAmount: ton("0.01"),
                forwardPayload: beginCell().storeUint(0, 1).endCell().beginParse()
            }.toCell()
        });
        cashback(unstaker);
    }

    fun unstake(stakeId: Int): StakeRecord {
        let user = sender();

        // Get the stake record by global stake ID
        let recordOpt = self.stakes.get(stakeId);
        require(recordOpt != null, "Stake not found");
        let record = recordOpt!!;

        // Verify ownership
        require(record.owner == user, "Not stake owner");
        require(record.jettonStakeAmount > 0, "No stake");
        require(now() >= record.lockEndTime, "Lock period not ended");

        // Remove stake record
        self.stakes.set(stakeId, null);

        // Decrement stake count
        let stakeCountOpt = self.userStakeCount.get(user);
        if (stakeCountOpt != null && stakeCountOpt!! > 0) {
            self.userStakeCount.set(user, stakeCountOpt!! - 1);
        }

        // Emit unstake event
        emit(UnstakeEvent {
            senderAddress: user,
            stakeId: stakeId
        }.toCell());

        return recordOpt!!;
    }

    receive(msg: Upgrade) {
        require(context().value >= ton("0.05"), "Not enough value");
        require(msg.lockDurationIndex > 0, "Lock duration can not be 0");
        let stake = self.unstake(msg.stakeId);

        self.addStake(AddStake{
            owner: stake.owner,
            lockDurationIndex: msg.lockDurationIndex,
            jettonStakeAmount: stake.jettonStakeAmount
        });

        cashback(sender());
    }

    fun addStake(msg: AddStake) {
        // Validate lock duration index exists and get the actual duration
        let durationOpt = self.lockDurations.get(msg.lockDurationIndex);
        require(durationOpt != null, "Invalid lock duration index");

        // Check maximum active stakes per user (20)
        let stakeCountOpt = self.userStakeCount.get(msg.owner);
        let stakeCount = stakeCountOpt != null ? stakeCountOpt!! : 0;
        require(stakeCount < 1000, "Maximum 1000 stakes allowed");

        let lockDuration: Int = durationOpt!!;
        let lockEndTime: Int = now() + lockDuration;

        // Get global stake ID and increment
        let globalStakeId: Int = self.nextStakeId;
        self.nextStakeId = self.nextStakeId + 1;

        // Store stake with global ID
        self.stakes.set(globalStakeId,
        StakeRecord {
            owner: msg.owner,
            jettonStakeAmount: msg.jettonStakeAmount,
            lockEndTime: lockEndTime
        }
        );

        // Increment user's stake count
        self.userStakeCount.set(msg.owner, stakeCount + 1);

        emit(StakeEvent {
            senderAddress: msg.owner,
            jettonAmount: msg.jettonStakeAmount,
            lockEndTime: lockEndTime,
            lockDurationIndex: msg.lockDurationIndex,
            stakeId: globalStakeId
        }.toCell());
    }

    get fun getStakeById(stakeId: Int): StakeRecord {
        let recOpt = self.stakes.get(stakeId);
        require(recOpt != null, "Stake not found");
        return recOpt!!;
    }

    get fun getReturnStakingData(): StakingData {
        return StakingData {
            thisContractJettonWallet: self.thisContractJettonWallet!!
        };
    }

    get fun getJettonMaster(): Address {
        return self.jettonMaster;
    }

    get fun getUserStakeCount(user: Address): Int {
        let countOpt = self.userStakeCount.get(user);
        return countOpt != null ? countOpt!! : 0;
    }

    get fun getNextStakeId(): Int {
        return self.nextStakeId;
    }

    get fun isAuthorizedStaker(staker: Address): Bool {
        return self.authorizedStakers.get(staker) == true;
    }
}
