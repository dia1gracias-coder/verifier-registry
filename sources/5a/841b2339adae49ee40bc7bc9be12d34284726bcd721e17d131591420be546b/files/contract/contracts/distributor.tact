import "@stdlib/deploy";
import "./messages";
import "./jetton/messages";
import "./jetton/wallet";
import "./verifier.fc";

@name(set_code)
native setCode(code: Cell);

@name(set_data)
native setData(d: Cell);

@name(get_entry)
native getEntrySlice(proof: Cell, merkleRoot: Int, index: Int): Slice;

const ZERO_ADDRESS: Address = address("0:0000000000000000000000000000000000000000000000000000000000000000");
const DENOMINATOR: Int = 100000000;

contract Distributor with Deployable, OwnableTransferable {
    owner: Address;
    parent: Address;
    id: Int as uint32;
    token: Address;
    vault: Address;
    merkleRoot: Int as uint256;
    unlockPeriods: map<Int, UnlockPeriod>;
    refundDate: Int as uint32;
    totalAmount: Int as uint256;
    totalClaimedAmount: Int as uint256;
    claimedAmounts: map<Address, Int>;
    stoppedTime: Int as uint32;
    changedWallets: map<Address, Address>;
    refundRequested: map<Address, Bool>;
    refunded: map<Address, Bool>;

    init(parent: Address, id: Int) {
        self.owner = ZERO_ADDRESS;
        self.parent = parent;
        self.id = id;
        self.token = ZERO_ADDRESS;
        self.vault = ZERO_ADDRESS;
        self.merkleRoot = 0;
        self.refundDate = 0;
        self.totalAmount = 0;
        self.totalClaimedAmount = 0;
        self.stoppedTime = 0;
    }

    receive(msg: CreateDistributorInternal) {
        require(sender() == self.parent, "Parent only");
        require(self.verifyTotalPercentage(msg.unlockPeriods), "Invalid total percentage");

        self.owner = msg.creator;
        self.token = msg.token;
        self.vault = contractAddress(initOf JettonDefaultWallet(myAddress(), self.token));
        self.merkleRoot = msg.merkleRoot;
        self.unlockPeriods = msg.unlockPeriods;
        self.totalAmount = msg.totalAmount;
        self.refundDate = msg.refundDate;

        emit(DistributorCreatedEvent { id: self.id }.toCell());
    }

    receive(msg: Claim) {
        let entry = self.getEntry(msg.merkleProof, msg.index);
        require(entry.address == sender(), "Not allowed to claim");

        let amount = self.availableTokens(msg.merkleProof, msg.index);
        require(amount > 0, "Nothing to claim");

        if (self.refundDate > 0) {
            let refunded = self.refunded.get(entry.address);
            require(refunded == null || refunded!! == false, "Wallet refunded");

            if (now() > self.refundDate) {
                let refundRequested = self.refundRequested.get(entry.address);
                require(refundRequested == null || refundRequested!! == false, "Refund requested");
            }
            else {
                self.refundRequested.set(entry.address, null);
            }
        }

        send(SendParameters{
            to: self.vault,
            value: 0,
            mode: SendRemainingValue,
            body: TokenTransfer {
                query_id: 0,
                amount: amount,
                destination: entry.address,
                response_destination: entry.address,
                custom_payload: null,
                forward_ton_amount: 0,
                forward_payload: emptySlice()
            }.toCell()
        });

        let claimed: Int = self.getClaimedOrDefault(sender());
        self.claimedAmounts.set(sender(), claimed + amount);
        self.totalClaimedAmount += amount;

        emit(ClaimEvent { address: sender(), amount: amount }.toCell());
    }

    receive(msg: RequestRefund) {
        let entry = self.getEntry(msg.merkleProof, msg.index);
        require(entry.address == sender(), "Address not found");

        require(now() <= self.refundDate, "Refund not enabled or expired");

        let claimed = self.getClaimedOrDefault(entry.address);
        require(claimed == 0, "Already claimed");

        self.refundRequested.set(entry.address, true);

        emit(RequestRefundEvent { address: entry.address }.toCell());
        self.reply(emptyCell());
    }

    receive(msg: RevokeRefund) {
        let entry = self.getEntry(msg.merkleProof, msg.index);
        require(entry.address == sender(), "Address not found");

        require(now() <= self.refundDate, "Refund not enabled or expired");

        self.refundRequested.set(entry.address, null);

        emit(RevokeRefundEvent { address: entry.address }.toCell());
        self.reply(emptyCell());
    }

    receive(msg: ChangeWallet) {
        let entry = self.getEntry(msg.merkleProof, msg.index);
        require(entry.address == sender(), "Wallet not found");

        let claimed = self.getClaimedOrDefault(entry.address);

        if (claimed > 0) {
            self.claimedAmounts.set(msg.newWallet, claimed);
        }

        self.claimedAmounts.set(entry.address, null);
        self.changedWallets.set(entry.originalAddress, msg.newWallet);

        let refundRequested = self.refundRequested.get(entry.address);
        if (refundRequested != null && refundRequested!! == true) {
            self.refundRequested.set(msg.newWallet, true);
            self.refundRequested.set(entry.address, null);
        }

        let refunded = self.refunded.get(entry.address);
        if (refunded != null && refunded!! == true) {
            self.refunded.set(msg.newWallet, true);
            self.refunded.set(entry.address, null);
        }

        emit(ChangeWalletEvent { oldWallet: entry.address, newWallet: msg.newWallet }.toCell());
        self.reply(emptyCell());
    }

    receive(msg: StopVesting) {
        self.requireOwner();
        require(self.stoppedTime == 0, "Vesting already stopped");

        self.stoppedTime = now();

        let percentageBefore: Int = 0;

        foreach (key, unlockPeriod in self.unlockPeriods) {
            if (!unlockPeriod.airdrop && unlockPeriod.start < self.stoppedTime) {
                percentageBefore += unlockPeriod.percentage;
            }
        }

        let leftAmount: Int = self.totalAmount * percentageBefore / (DENOMINATOR * 100) - self.totalClaimedAmount;
        let amountToWithdraw: Int = 0;

        if (msg.balance > leftAmount) {
            amountToWithdraw = msg.balance - leftAmount;

            send(SendParameters{
                to: self.vault,
                value: 0,
                mode: SendRemainingValue,
                body: TokenTransfer {
                    query_id: 0,
                    amount: amountToWithdraw,
                    destination: sender(),
                    response_destination: sender(),
                    custom_payload: null,
                    forward_ton_amount: 0,
                    forward_payload: emptySlice()
                }.toCell()
            });
        }

        emit(StopVestingEvent { stoppedTime: self.stoppedTime, withdrawnAmount: amountToWithdraw }.toCell());
    }

    receive(msg: Withdraw) {
        self.requireOwner();

        send(SendParameters{
            to: self.vault,
            value: 0,
            mode: SendRemainingValue,
            body: TokenTransfer {
                query_id: 0,
                amount: msg.amount,
                destination: sender(),
                response_destination: sender(),
                custom_payload: null,
                forward_ton_amount: 0,
                forward_payload: emptySlice()
            }.toCell()
        });

        emit(WithdrawEvent { amount: msg.amount }.toCell());
    }

    receive(msg: UpdateMerkleRoot) {
        self.requireOwner();

        self.merkleRoot = msg.merkleRoot;

        emit(UpdateMerkleRootEvent { merkleRoot: msg.merkleRoot }.toCell());
        self.reply(emptyCell());
    }

    receive(msg: UpdateVault) {
        self.requireOwner();

        self.vault = msg.vault;

        emit(UpdateVaultEvent { vault: msg.vault }.toCell());
        self.reply(emptyCell());
    }

    receive(msg: UpdateRefundDate) {
        self.requireOwner();

        self.refundDate = msg.refundDate;

        emit(UpdateRefundDateEvent { refundDate: msg.refundDate }.toCell());
        self.reply(emptyCell());
    }

    receive(msg: SetRefunded) {
        self.requireOwner();

        foreach (address, refunded in msg.refunded) {
            self.refunded.set(address, refunded == true ? true : null);
        }

        self.reply(emptyCell());
    }

    receive(msg: UpgradeCode) {
        self.requireOwner();

        setCode(msg.newCode);
    }

    receive(msg: UpgradeData) {
        self.requireOwner();

        setData(msg.newData);
    }


    fun fromPercentage(amount: Int, percentage: Int): Int {
        return (amount * percentage / (100 * DENOMINATOR));
    }

    fun getEntry(merkleProof: Cell, index: Int): Entry {
        let entry: Slice = getEntrySlice(merkleProof, self.merkleRoot, index);

        let address: Address = entry.loadAddress();
        let amount: Int = entry.loadCoins();

        let changedAddress = self.changedWallets.get(address);
        let target = changedAddress != null ? changedAddress!! : address;

        return Entry {
            address: target,
            amount: amount,
            originalAddress: address
        }
    }

    fun getClaimedOrDefault(user: Address): Int {
        let claimedValue: Int? = self.claimedAmounts.get(user);
        let claimed: Int = claimedValue != null ? claimedValue!! : 0;
        return claimed;
    }

    fun verifyTotalPercentage(unlockPeriods: map<Int, UnlockPeriod>): Bool {
        let totalAmount: Int = 0;

        foreach (key, unlockPeriod in unlockPeriods) {
            totalAmount += unlockPeriod.percentage;
        }

        return ((totalAmount <= 100 * DENOMINATOR) && (totalAmount >= 99 * DENOMINATOR));
    }
    

    get fun availableTokens(merkleProof: Cell, index: Int): Int {
        let entry: Entry? = null;

        try {
            entry = self.getEntry(merkleProof, index);
        }
        catch (err) {
            return 0;
        }

        let user = entry!!.address;
        let amount = entry!!.amount;

        let now: Int = now();
        let available: Int = 0;
        let airdropped: Int = 0;

        foreach (key, unlockPeriod in self.unlockPeriods) {
            let stopped: Bool = self.stoppedTime > 0 && unlockPeriod.start >= self.stoppedTime;

            if (!stopped && unlockPeriod.percentage > 0 && now >= unlockPeriod.start) {
                if (unlockPeriod.airdrop) {
                    airdropped += unlockPeriod.percentage;
                }
                else {
                    if (now >= unlockPeriod.end) {
                        if (self.stoppedTime == 0 || self.stoppedTime >= unlockPeriod.end) {
                            available += unlockPeriod.percentage;
                        }
                        else {
                            available += (unlockPeriod.percentage / ((unlockPeriod.end - unlockPeriod.start) / unlockPeriod.duration + 1)) * ((self.stoppedTime - unlockPeriod.start) / unlockPeriod.duration + 1);
                        }
                    }
                    else {
                        let _end: Int = now;

                        if (_end > self.stoppedTime && self.stoppedTime > unlockPeriod.start) {
                             _end = self.stoppedTime; 
                        }

                        available += (unlockPeriod.percentage / ((unlockPeriod.end - unlockPeriod.start) / unlockPeriod.duration + 1)) * ((_end - unlockPeriod.start) / unlockPeriod.duration + 1);
                    }
                }
            }
        }

        if ((available + airdropped) > (100 * DENOMINATOR)) { 
            available = 100 * DENOMINATOR - airdropped; 
        }

        let result: Int = self.fromPercentage(amount, available);
        let claimed: Int = self.getClaimedOrDefault(user);

        if (result >= claimed) {
             return result - claimed;
        }
        else {
            return 0;
        }
    }

    get fun claimedPerWallet(merkleProof: Cell, index: Int): Int {
        let entry: Entry? = null;

        try {
            entry = self.getEntry(merkleProof, index);
        }
        catch (err) {
            return 0;
        }

        let user = entry!!.address;
        let amount = entry!!.amount;
        
        let unlockedBefore: Int = 0;

        foreach (key, unlockPeriod in self.unlockPeriods) {
            if (unlockPeriod.airdrop) {
                unlockedBefore += unlockPeriod.percentage;
            }
        }

        let claimed: Int = self.getClaimedOrDefault(user);

        return claimed + self.fromPercentage(amount, unlockedBefore);
    }

    get fun isRefundRequested(user: Address): Bool {
        let refundRequested = self.refundRequested.get(user);
        return refundRequested != null && refundRequested!! == true;
    }

    get fun details(): DistributorDetails {
        return DistributorDetails {
            token: self.token,
            vault: self.vault,
            merkleRoot: self.merkleRoot,
            unlockPeriods: self.unlockPeriods,
            totalAmount: self.totalAmount,
            totalClaimedAmount: self.totalClaimedAmount,
            refundDate: self.refundDate,
            stoppedTime: self.stoppedTime
        };
    }

    get fun refundRequests(): map<Address, Bool> {
        return self.refundRequested;
    }

    get fun refunds(): map<Address, Bool> {
        return self.refunded;
    }
}
