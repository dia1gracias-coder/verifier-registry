import "@stdlib/deploy";
import "@stdlib/ownable";
import "@stdlib/stoppable";

import "./imports/messages";
import "./imports/structs";
import "./imports/traits";

/**
 * @contract
 * @description A smart contract that implements the logic of blocking $HOLD tokens for
 * a certain period of time for their gradual unblocking and putting them into circulation.
 *
 * @traits Deployable, OwnableTransferable, Resumable, Freezeble, Calculate, Configuration
 * @dev $HOLD jetton minter contract address EQB02nFR04bDweU8FyR6CJuURYmUp_Y4hZQQ_Cn63SJ0FZga (mainnet, 0 workchain)
 */
contract HOLDVesting with Deployable, OwnableTransferable, Resumable, Freezeble, Calculate, Configuration {
    owner: Address;
    stopped: Bool;
    frozenAt: Int;
    jettonMasterAddress: Address;
    jettonWalletCode: Cell;
    configs: map<Int as uint8, Config>;
    totalAllocateJettons: map<Int as uint8, Int>;
    totalDebtJettons: Int as coins;

    /**
     * @constructor
     * @description Initializes the contract with the given owner, jettonMaster, and jettonWalletCode.
     * Sets initial values for other state fields.
     * 
     * @param owner: Address
     * @param jettonMaster: Address
     * @param jettonWalletCode: Cell
     */
    init(owner: Address, jettonMasterAddress: Address, jettonWalletCode: Cell) {
        self.owner = owner;
        self.stopped = false;
        self.frozenAt = 0;
        self.jettonMasterAddress = jettonMasterAddress;
        self.jettonWalletCode = jettonWalletCode;
        self.configs = emptyMap();
        self.totalAllocateJettons = emptyMap();
        self.totalDebtJettons = 0;
    }

    /**
     * @message WithdrawJettons
     * @description Allows the owner to withdraw jettons when the contract is not frozen or stopped.
     * @param msg: WithdrawJettons
     */
    receive(msg: WithdrawJettons) {
        self.requireOwner();
        self.requireNotFrozen();
        self.requireNotStopped();

        require(msg.amount > 0, "Amount must be greater than 0");

        self.transferJettons(msg.queryId, msg.amount, msg.receiver);
    }

    /**
     * @message WithdrawUnlockedJettons
     * @description Handles the allocate jettons request from the sender.
     * Ensures contract is not frozen or stopped, validates the sender, and updates the allocate jetton amounts.
     *
     * @param msg: WithdrawUnlockedJettons
     */
    receive(msg: WithdrawUnlockedJettons) {
        self.requireFrozen();
        self.requireNotStopped();

        require(msg.amount > 0, "Amount must be greater than 0");

        let config: Config = self.getConfig(msg.configId);
        self.requireSender(config.receiver);

        require(self.isCliffPeriodEnded(msg.configId), "The cliff period is not over yet");

        let unlockedJettons: Int = self.getUnlockedJettons(config.amount,
            config.cliffPeriodDuration, config.cycleReleaseDuration, config.cycleReleasePercent);

        let jettons: Int = self.getTotalAllocateJettons(msg.configId);
        let sumJettons: Int = jettons + msg.amount;

        require(unlockedJettons >= sumJettons, "Invalid amount");

        self.totalAllocateJettons.set(msg.configId, sumJettons);

        self.transferJettons(msg.queryId, msg.amount, config.receiver);
    }

    /**
     * @message WithdrawDebtJettons
     * @description Allows the owner to withdraw debt jettons when the contract is frozen and not stopped,
     * ensuring sufficient balance.
     *
     * @param msg: WithdrawDebtJettons
     */
    receive(msg: WithdrawDebtJettons) {
        self.requireOwner();
        self.requireFrozen();
        self.requireNotStopped();

        require(msg.amount > 0, "Amount must be greater than 0");
        require(self.totalDebtJettons >= msg.amount, "Insufficient balance");
        self.totalDebtJettons -= msg.amount;

        self.transferJettons(msg.queryId, msg.amount, msg.receiver);
    }

    /**
     * @event bounced<JettonTransfer>
     * @description Handles bounced jetton transfers by adding the amount back to total debt jettons.
     * @param src: bounced<JettonTransfer>
     */
    bounced(src: bounced<JettonTransfer>) {
        self.requireFrozen();
        self.requireSender(self.getJettonWalletAddress());

        self.totalDebtJettons += src.amount;
    }

    /**
     * @private
     * @description Ensures the sender matches the expected address.
     * @param sender: Address
     */
    fun requireSender(sender: Address) {
        nativeThrowUnless(132, sender() == sender);
    }

    /**
     * @private
     * @description Transfers jettons to the specified destination.
     * @param queryId: Int
     * @param amount: Int
     * @param destination: Address
     */
    fun transferJettons(queryId: Int, amount: Int, destination: Address) {
        send(SendParameters{
            to: self.getJettonWalletAddress(),
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: JettonTransfer{
                queryId: queryId,
                amount: amount,
                destination: destination,
                responseDestination: myAddress(),
                customPayload: beginCell().storeUint(0, 1).endCell(),
                forwardTonAmount: 0,
                forwardPayload: beginCell().storeUint(0, 1).asSlice()
            }.toCell(),
        });
    }

    /**
     * @private
     * @description Returns the jetton wallet address based on the state initialization.
     * @return Address
     */
    fun getJettonWalletAddress(): Address {
        let stateInit: StateInit = StateInit{
            code: self.jettonWalletCode,
            data: beginCell()
                .storeCoins(0)
                .storeAddress(myAddress())
                .storeAddress(self.jettonMasterAddress)
                .storeRef(self.jettonWalletCode)
                .endCell(),
        };

        return contractAddress(stateInit);
    }

    /**
     * @private
     * @description Returns the unlocked jettons amount.
     * @return Int
     */
    fun getUnlockedJettons(amount: Int, cliffPeriodDuration: Int, cycleReleaseDuration: Int, cycleReleasePercent: Int): Int {
        let frozenDuration: Int = self.getFrozenDuration();
        let currentReleaseDuration: Int = frozenDuration - cliffPeriodDuration;
        let currentCycle: Int = currentReleaseDuration / cycleReleaseDuration;
        let unlockedJettons: Int = currentCycle * self.calcPercent(amount, cycleReleasePercent);
        return unlockedJettons;
    }

    /**
     * @private
     * @description Returns the allocate jettons amount.
     * @return Int
     */
    fun getTotalAllocateJettons(configId: Int): Int {
        let val: Int? = self.totalAllocateJettons.get(configId);
        if (val == null) {
            return 0;
        }
        return val!!;
    }

    /**
     * @getter jettonMasterAddress
     * @description Returns the jetton master address.
     * @return Address
     */
    get fun jettonMasterAddress(): Address {
        return self.jettonMasterAddress;
    }

    /**
     * @getter jettonWalletAddress
     * @description Returns the jetton wallet address.
     * @return Address
     */
    get fun jettonWalletAddress(): Address {
        return self.getJettonWalletAddress();
    }

    /**
     * @getter allocateData
     * @description Returns the allocate data.
     * @param configId: Int
     * @return Int
     */
    get fun allocateData(configId: Int): AllocateData? {
        if (!self.isFrozen() || !self.isConfig(configId)) {
            return null;
        }

        let config: Config = self.getConfig(configId);

        let isCliffPeriodEnded: Bool = self.isCliffPeriodEnded(configId);
        let cycleReleaseNumber: Int = self.getCycleReleaseNumber(configId);
        let totalJettons: Int = config.amount;
        let totalAllocateJettons: Int = self.getTotalAllocateJettons(configId);
        let totalUnlockedJettons: Int = self.getUnlockedJettons(config.amount,
            config.cliffPeriodDuration, config.cycleReleaseDuration, config.cycleReleasePercent);
        let totalLockedJettons: Int = totalJettons - totalUnlockedJettons;

        let allocateData: AllocateData = AllocateData {
            isCliffPeriodEnded: isCliffPeriodEnded,
            cycleReleaseNumber: cycleReleaseNumber,
            totalJettons: totalJettons,
            totalAllocateJettons: totalAllocateJettons,
            totalUnlockedJettons: totalUnlockedJettons,
            totalLockedJettons: totalLockedJettons
        };

        return allocateData;
    }

    /**
     * @getter totalDebtJettons
     * @description Returns the total amount of debt jettons.
     * @return Int
     */
    get fun totalDebtJettons(): Int {
        return self.totalDebtJettons;
    }
}
