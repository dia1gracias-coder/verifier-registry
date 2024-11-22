import "@stdlib/ownable";
import "./staking_messages";

struct StakingInfo {
    balance: Int as coins;
    lastUpdate: Int as uint64;
    apr: Int as uint16;
    debt: Int as coins;
}

contract StakingChild with Ownable {
    // const minTonsForStorage: Int = ton("0.01");
    // const gasConsumption: Int = ton("0.01");

    owner: Address;
    masterStaking: Address;

    info: StakingInfo;

    init(
        owner: Address,
        masterStaking: Address
    ) {

        self.info = StakingInfo{
            balance: 0,
            lastUpdate: 0,
            apr: 0,
            debt: 0
        };

        self.owner = owner;
        self.masterStaking = masterStaking;
    }

    // master functional

    receive(msg: SetAPR) {
        require(context().sender == self.masterStaking, "not from master");
        self.updateAPR(msg.apr);
    }

    receive(msg: Deposit) {
        require(context().sender == self.masterStaking, "not from master");
        self.updateAPR(msg.apr);
        self.info.balance = self.info.balance + msg.amount;
    }

    // user functional

    receive("claimRewards") {
        self.requireOwner();
        require(context().value > ton("0.2"), "low value");
        self.updateDebt();
        let _debt: Int = self.info.debt;
        self.info.debt = 0;
        send(SendParameters{
            to: self.masterStaking,
            value: 0,
            mode: SendRemainingValue, 
            body: SendCoins{
                amount: _debt,
                to: self.owner,
                update: true
            }.toCell()
        });
    }

    receive("withdraw") {
        self.requireOwner();
        self.updateDebt();
        let _debt: Int = self.info.debt + self.info.balance;
        self.info.debt = 0;
        self.info.balance = 0;
        send(SendParameters{
            to: self.masterStaking,
            value: 0,
            mode: SendRemainingValue, 
            body: SendCoins{
                amount: _debt,
                to: self.owner,
                update: false
            }.toCell()
        });
    }

    get fun pendingRewards(): Int {
        return self.calculateRewards();
    }

    get fun stakingInfo(): StakingInfo {
        return self.info;
    }

    fun calculateRewards(): Int {
        if (self.info.balance > 0) {
            return self.info.balance * (now() - self.info.lastUpdate) * self.info.apr / (86400 * 365 * 100_00) + self.info.debt;
        } else {
            return self.info.debt;
        }
    }

    fun updateAPR(_apr: Int) {
        // update rewards
        self.updateDebt();
        // update apr
        self.info.apr = _apr;
    }

    fun updateDebt() {
        self.info.debt = self.calculateRewards();
        self.info.lastUpdate = now();
    }
}
