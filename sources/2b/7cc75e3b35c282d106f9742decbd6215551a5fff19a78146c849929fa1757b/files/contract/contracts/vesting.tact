import "@stdlib/deploy";
import "./messages";

// === Structs ===
// fix TRV-01 & TRV-10 | Removed unused `totalAmount` and `claimedAmount` + explicit types
struct VestingSchedule {
    initialUnlock: Int as int32;
    cliffDuration: Int as int64;
    vestingDuration: Int as int64;
    startTime: Int as int64;
    claimInterval: Int as int64;
}

struct ClaimRecord {
    claims: map<Int as int32, Int as int64>;
    lastClaims: map<Int as int32, Int as int64>;
}

message(0x434c414d) ClaimEvent {
    senderAddress: Address;
    amount: Int as coins;
    vestingType: Int as int8;
}

// === Constants ===
const MAX_MERKLE_DEPTH: Int = 32;
const MAX_TOTAL_AMOUNT: Int = 1000000000 * 1000000000;  // 1B nano ton
const MAX_VESTING_DURATION: Int = 365 * 24 * 60 * 60 * 4;
const HI: Int = 1 << 255;

// === Messages ===

// fix TRV-11 | Correct type specifications and remove unused fields
message ClaimRequest {
    queryId: Int as uint64;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice;
    proof: Cell;
    vestingType: Int as int8;
    total: Int as coins;
    stakeLockDurationIndex: Int? as uint8;
}

message SetMerkleRootRequest {
    newRoot: Slice as bytes32;   // exactly 256 bits, no refs
}

message SetStakingContractAddressRequest {
    stakingContractAddress: Address;
}

message SetScheduleRequest {
    vestingType: Int as int8;
    unlock: Int as int32;
    cliff: Int as int64;
    duration: Int as int64;
    interval: Int as int64;
}

message BanUserRequest {
    user: Address;
}

message UnbanUserRequest {
    user: Address;
}

message SetJettonWalletRequest {
    wallet: Address;
}

message DrainRequest {
    queryId: Int as uint64;
    amount: Int as coins;
}

message ChangeAdminRequest {
    newAdmin: Address;
}

fun uless256(a: Int, b: Int): Bool {
    let sa = a < 0;   // a has MSB set?
    let sb = b < 0;   // b has MSB set?
    if (sa != sb) {
        // non-negative < negative in unsigned ordering
        return !sa;
    }
    // same sign → regular compare is fine
    return a < b;
}

fun verifyMerkleProof(proof: Slice, leaf: Slice, root: Slice): Bool {
    let rootHash: Int = root.loadUint(256);
    let current: Int = leaf.hash();   // leaf is hashed to 256 bits
    let p: Slice = proof;
    let depth: Int = 0;

    // Helper: check if there are more proof hashes available (in current cell or via ref)
    let hasMore: Bool = p.bits() >= 256 || (p.bits() == 0 && p.refs() > 0);

    // Continue while there is another 256-bit sibling available and we haven't reached the root
    while (depth < MAX_MERKLE_DEPTH && hasMore && !(current == rootHash)) {
        let sib: Int = 0;

        // Load next sibling hash, following the "snake" structure if needed
        if (p.bits() >= 256) {
            sib = p.loadUint(256);
        } else {
            // Move to next chunk via ref and continue
            let next: Cell = p.loadRef();
            p = next.beginParse();
            // Now we must have at least 256 bits (by construction of the proof)
            sib = p.loadUint(256);
        }

        // Sorted-pair Merkle tree: order siblings by unsigned comparison
        let x: Int = uless256(current, sib) ? current : sib;
        let y: Int = uless256(current, sib) ? sib     : current;

        let c = beginCell()
        .storeUint(x, 256)
        .storeUint(y, 256)
        .endCell();

        current = c.hash();
        depth += 1;

        // Update hasMore for next iteration
        hasMore = p.bits() >= 256 || (p.bits() == 0 && p.refs() > 0);
    }

    return current == rootHash;
}

// === Contract ===

contract Vesting {
    admin: Address;
    jettonWallet: Address?;
    drainJettonWallet: Address;
    merkleRoot: Slice as bytes32;   // store the 32 bytes directly (no ref)
    stakingContractAddress: Address?;
    startTime: Int as int64;
    schedules: map<Int as int32, VestingSchedule>;
    claimed: map<Address, ClaimRecord>; // fix TRV-07 | Unbounded structure noted (recommend sharding)
    banned: map<Address, Bool>; // fix TRV-07 | Unbounded structure noted (recommend sharding)

    init(admin: Address, root: Slice as bytes32, drainJettonWallet: Address, startTime: Int as int64) {
        self.admin = admin;
        self.merkleRoot = root;
        self.drainJettonWallet = drainJettonWallet;
        self.startTime = startTime;
        self.schedules = emptyMap();
        self.claimed = emptyMap();
        self.banned = emptyMap();
        self.jettonWallet = null;
    }

    fun requireAdmin() {
        if (self.admin != sender()) {
            throw(100);
        }
    }

    // === Admin Functions ===
    receive(msg: SetScheduleRequest) {
        self.requireAdmin();
        require(msg.unlock >= 0 && msg.unlock <= 100, "invalid unlock");
        require(msg.cliff >= 0, "invalid cliff");
        require(msg.duration > 0, "invalid vesting");
        require(msg.interval > 0, "invalid interval");
        require(msg.cliff + msg.duration <= MAX_VESTING_DURATION, "too long");
        require(msg.duration % msg.interval == 0, "duration must be divisible by interval");

        self.schedules.set(msg.vestingType,
            VestingSchedule {
                initialUnlock: msg.unlock,
                cliffDuration: msg.cliff,
                vestingDuration: msg.duration,
                startTime: self.startTime,
                claimInterval: msg.interval
            }
        );
    }

    receive(msg: SetMerkleRootRequest) {
        self.requireAdmin();
        self.merkleRoot = msg.newRoot;
    }

    receive(msg: SetStakingContractAddressRequest) {
        self.requireAdmin();
        self.stakingContractAddress = msg.stakingContractAddress;
    }

    receive(msg: BanUserRequest) {
        self.requireAdmin();
        self.banned.set(msg.user, true);
    }

    receive(msg: UnbanUserRequest) {
        self.requireAdmin();
        self.banned.set(msg.user, null);
    }

    receive(msg: SetJettonWalletRequest) {
        self.requireAdmin();
        require(self.jettonWallet == null, "already set");
        self.jettonWallet = msg.wallet;
    }

    receive(msg: ChangeAdminRequest) {
        self.requireAdmin();
        self.admin = msg.newAdmin;
    }

    receive(msg: DrainRequest) {
        self.requireAdmin();
        require(self.jettonWallet != null, "wallet not set");
        require(msg.amount > 0, "invalid amount");
        require(context().value >= ton("0.1"), "Insufficient gas");

        message(MessageParameters {
            to: self.jettonWallet!!,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: JettonTransfer {
                queryId: msg.queryId,
                amount: msg.amount,
                destination: self.drainJettonWallet,
                responseDestination: self.admin,
                forwardTonAmount: 1,
                forwardPayload: beginCell().storeUint(0, 1).endCell().beginParse()
            }.toCell(),
        });
    }

    // === Claim ===
    receive(msg: ClaimRequest) {
        require(self.banned.get(sender()) == null, "banned");
        require(msg.total >= 0, "negative total");
        require(msg.total <= MAX_TOTAL_AMOUNT, "too big");
        require(self.jettonWallet != null, "wallet not set");
        require(msg.stakeLockDurationIndex == null || self.stakingContractAddress != null, "Can not stake");

        if (msg.stakeLockDurationIndex == null) {
            require(context().value >= ton("0.12"), "Insufficient gas"); // fix TRV-05
        } else {
            require(context().value >= ton("0.15"), "Insufficient gas"); // fix TRV-05
        }

        let scheduleOpt = self.schedules.get(msg.vestingType);
        require(scheduleOpt != null, "bad schedule");
        let schedule = scheduleOpt!!;
        require(now() >= schedule.startTime, "not started"); // fix TRV-06
        let leafCell = beginCell()
            .storeAddress(sender())
            .storeInt(msg.vestingType, 8)
            .storeCoins(msg.total)
            .endCell();
        let leaf = leafCell.asSlice();
        require(verifyMerkleProof(msg.proof.asSlice(), leaf, self.merkleRoot), "bad proof");
        let userRecord = self.claimed.get(sender()) != null
            ? self.claimed.get(sender())!!
            : ClaimRecord{ claims: emptyMap(), lastClaims: emptyMap() };
        let claimedBefore = userRecord.claims.get(msg.vestingType) != null
            ? userRecord.claims.get(msg.vestingType)!!
            : 0;
        let lastClaimTime = userRecord.lastClaims.get(msg.vestingType) != null
            ? userRecord.lastClaims.get(msg.vestingType)!!
            : 0;
        require(now() - lastClaimTime >= schedule.claimInterval, "too soon");
        let unlocked = self.computeUnlocked(msg.total, schedule, now());
        let claimable = unlocked - claimedBefore;
        require(claimable > 0, "Nothing to claim");

        userRecord.claims.set(msg.vestingType, claimedBefore + claimable);
        userRecord.lastClaims.set(msg.vestingType, now());
        self.claimed.set(sender(), userRecord);
        if (msg.stakeLockDurationIndex != null) {
            message(MessageParameters {
                to: self.jettonWallet!!,
                value: ton("0.1"),
                mode: 0,
                bounce: true,
                body: JettonTransfer {
                    queryId: msg.queryId,
                    amount: claimable,
                    destination: self.stakingContractAddress!!,
                    responseDestination: self.stakingContractAddress!!,
                    forwardTonAmount: ton("0.05"),
                    forwardPayload: beginCell()
                    .storeUint(msg.stakeLockDurationIndex!!, 8)
                    .storeAddress(sender())
                    .endCell()
                    .beginParse()
                }.toCell(),
            });
        } else {
            message(MessageParameters {
                to: self.jettonWallet!!,
                value: ton("0.05"),
                mode: 0,
                bounce: true,
                body: JettonTransfer {
                    queryId: msg.queryId,
                    amount: claimable,
                    destination: sender(),
                    responseDestination: sender(),
                    forwardTonAmount: 1,
                    forwardPayload: beginCell().storeUint(0, 1).endCell().beginParse()
                }.toCell(),
            });
        }
        emit(ClaimEvent {
            senderAddress: sender(),
            amount: claimable,
            vestingType: msg.vestingType,
        }.toCell());
        cashback(sender())
    }

    // === Compute Unlocked ===
    get fun computeUnlocked(total: Int, s: VestingSchedule, now: Int): Int {
        if (now < s.startTime) {
            return 0;
        }
        let unlockedStart = (total * s.initialUnlock) / 100;
        if (now < s.startTime + s.cliffDuration) {
            return unlockedStart;
        }

        let totalUnlock = total - unlockedStart;
        let timeSinceCliff = now - (s.startTime + s.cliffDuration);

        if (timeSinceCliff >= s.vestingDuration) {
            return total;
        }

        let totalIntervals = s.vestingDuration / s.claimInterval;
        let tokensPerInterval = totalUnlock / totalIntervals;
        let intervalsElapsed = timeSinceCliff / s.claimInterval;

        let unlocked = unlockedStart + (tokensPerInterval * intervalsElapsed);
        return unlocked >= ton("1") ? unlocked : 0;
    }

    // === Getters ===

    get fun get_claimed(user: Address, vestingType: Int): Int {
        let record = self.claimed.get(user);
        if (record == null) {
            return 0;
        }
        let r = record!!;
        return r.claims.get(vestingType) != null ? r.claims.get(vestingType)!! : 0;
    }

    get fun get_last_claim(user: Address, vestingType: Int): Int {
        let record = self.claimed.get(user);
        if (record == null) {
            return 0;
        }
        let r = record!!;
        return r.lastClaims.get(vestingType) != null ? r.lastClaims.get(vestingType)!! : 0;
    }

    get fun get_schedule(vestingType: Int): VestingSchedule {
        let s = self.schedules.get(vestingType);
        require(s != null, "not found");
        return s!!;
    }

    get fun get_merkle_root(): Slice {
        return self.merkleRoot;
    }

    get fun is_banned(user: Address): Bool {
        return self.banned.get(user) != null;
    }

    get fun get_jetton_wallet(): Address? {
        return self.jettonWallet;
    }

    get fun get_drain_jetton_wallet(): Address {
        return self.drainJettonWallet;
    }
}
