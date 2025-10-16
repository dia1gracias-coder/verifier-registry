import "@stdlib/ownable";

message(0x555CDF) SetMasterPubKey {
    signature: Slice;
    body: SetMasterPubKeyBody;
}

struct SetMasterPubKeyBody {
    newMasterPubKey: Int as uint256;
    prevHash: Int as uint256;
}

message(0x5717D2) Withdraw {
    signature: Slice;
    body: WithdrawBody;
}

struct WithdrawBody {
    userId: Int as uint256;
    validUntil: Int as uint32;
    to: Address;
    prevHash: Int as uint256;
}

message(0xA110C8) AddAllocation {
    signature: Slice;
    body: AddAllocationBody;
}

struct AddAllocationBody {
    items: map<Int as uint256, Int as uint128>;
    validUntil: Int as uint32;
    prevHash: Int as uint256;
}

const MIN_RENT_RESERVE: Int = 50000000;

const OP_ALLOC_V1: Int = 0xA110C8;
const OP_WITHDRAW_V1: Int = 0x5717D2;
const OP_MASTER_V1: Int = 0x555CDF;

contract PayoutVault with Ownable {
    owner: Address;
    // -------- Storage --------
    masterPubKey: Int as uint256;

    balances: map<Int, Int>;
    headHash: Int as uint256;

    init(owner: Address, masterPubKey: Int as uint256) {
        self.owner = owner;

        self.masterPubKey = masterPubKey;

        self.balances = emptyMap();
        self.headHash = 0;
    }

    receive() {}

    receive(msg: SetMasterPubKey) {
        require(sender() == self.owner, "not_owner");
        require(msg.body.prevHash == self.headHash, "hash_match");

        let hash = msg.body.toCell().hash();
        require(checkSignature(hash, msg.signature, self.masterPubKey), "signature!");

        self.masterPubKey = msg.body.newMasterPubKey;
        self.headHash = hash;
    }

    receive(msg: AddAllocation) {
        require(sender() == self.owner, "not_owner");
        require(msg.body.prevHash == self.headHash, "hash_match");
        require(now() <= msg.body.validUntil, "valid_ttl");

        let hash = msg.body.toCell().hash();
        require(checkSignature(hash, msg.signature, self.masterPubKey), "signature!");

        // --- decode snake list from itemsRef ---
        foreach (uid, d in msg.body.items) {
            require(d > 0, "zero");

            let curOpt: Int? = self.balances.get(uid);
            let cur: Int = (curOpt == null) ? 0 : curOpt!!;

            let next: Int = cur + d;
            require(next >= cur, "overflow");

            self.balances.set(uid, next);
        }

        self.headHash = hash;
    }

    external(msg: Withdraw) {
        require(msg.body.prevHash == self.headHash, "hash_match");
        require(now() <= msg.body.validUntil, "valid_ttl");

        let hash = msg.body.toCell().hash();
        require(checkSignature(hash, msg.signature, self.masterPubKey), "signature!");

        let toSend: Int? = self.balances.get(msg.body.userId);

        if (toSend != null) {
            let safeCap: Int = max(0, myBalance() - MIN_RENT_RESERVE);
            require(safeCap >= toSend!!, "balance_limit");

            let _ = self.balances.del(msg.body.userId);
            acceptMessage();

            self.headHash = hash;

            let body: Cell = beginCell()
                .storeUint(0, 32)
                .storeSlice("Withdraw from #SignalHash".asSlice())
                .endCell();

            message(MessageParameters {
                to: msg.body.to,
                value: toSend!!,
                mode: SendPayFwdFeesSeparately + SendIgnoreErrors,
                body,
            });
        }
    }

    // -------- Getters --------
    get fun getAvailableById(userId: Int): Int? {
        return self.balances.get(userId);
    }

    get fun getHeadHash(): Int {
        return self.headHash;
    }

    get fun getMasterPubKey(): Int {
        return self.masterPubKey;
    }
}
