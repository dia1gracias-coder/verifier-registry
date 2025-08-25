import "@stdlib/deploy";

// Jetton transfer notification (TEP-64)
message JettonTransferNotification {
    queryId: Int as uint64 = 0;
    amount: Int as coins;
    sender: Address;
    forwardPayload: Slice as remaining;
}

// Record of a single stake
struct Stake {
    amount: Int as coins;
    timestamp: Int as uint64;
}

// Per-user staking state
struct UserStake {
    total: Int as coins;
    count: Int as uint32;
    stakes: map<Int as uint32, Stake>;
}

// Data needed to compute a jetton wallet address
struct JettonWalletData {
    balance: Int as coins;
    ownerAddress: Address;
    jettonMasterAddress: Address;
    jettonWalletCode: Cell;
}

// Helper to compute this contract’s USDT jetton wallet address
fun calculateJettonWalletAddress(ownerAddress: Address,
                                 jettonMasterAddress: Address,
                                 jettonWalletCode: Cell): Address {
    let initData = JettonWalletData{
        balance: 0,
        ownerAddress: ownerAddress,
        jettonMasterAddress: jettonMasterAddress,
        jettonWalletCode: jettonWalletCode
    };
    return contractAddress(StateInit{
        code: jettonWalletCode,
        data: initData.toCell()
    });
}


contract UsdtStaking with Deployable {
    owner: Address;
    usdtMaster: Address;
    usdtWalletCode: Cell;
    usdtWallet: Address;
    stakes: map<Address, UserStake>;

    init(owner: Address, usdtMaster: Address, usdtWalletCode: Cell) {
        self.owner = owner;
        self.usdtMaster = usdtMaster;
        self.usdtWalletCode = usdtWalletCode;
        // compute the contract’s own jetton wallet address
        self.usdtWallet = calculateJettonWalletAddress(
            myAddress(), usdtMaster, usdtWalletCode);
    }

    // Default fallback handler (refund any stray TON)
    receive() { cashback(sender()); }

    // Handle incoming USDT (Jetton) transfers
    receive(msg: JettonTransferNotification) {
        // Ensure the notification is from our own jetton wallet
        require(sender() == self.usdtWallet, "Invalid Jetton sender");

        let user: Address = msg.sender;
        let amt: Int = msg.amount;

        // Look up or create the user’s staking record
        let optStake = self.stakes.get(user);

        if (optStake == null) {
            // The emptyMap() function does not need a full type declaration
            // in the angle brackets, as the type is inferred from the struct.
            let st = UserStake{
                total: amt,
                count: 1,
                stakes: emptyMap()
            };
            st.stakes.set(0, Stake{
                amount: amt,
                timestamp: now()
            });
            self.stakes.set(user, st);
        } else {
            let st = optStake!!;
            // Append this stake
            let idx: Int = st.count;
            st.stakes.set(idx, Stake{
                amount: amt,
                timestamp: now()
            });
            st.count = st.count + 1;
            st.total = st.total + amt;
            self.stakes.set(user, st);
        }

        // Return any excess TON from the notification
        self.forward(msg.sender, null, false, null);
    }

    // Getters
    get fun get_stake_count(user: Address): Int {
        let optStake = self.stakes.get(user);
        if (optStake == null) {
            return 0;
        }
        return optStake!!.count;
    }

    get fun get_total_staked(user: Address): Int {
        let optStake = self.stakes.get(user);
        if (optStake == null) {
            return 0;
        }
        return optStake!!.total;
    }

    get fun get_stake_info(user: Address, index: Int): Stake? {
        let optStake = self.stakes.get(user);
        if (optStake == null) {
            return null;
        }
        return optStake!!.stakes.get(index);
    }
}
