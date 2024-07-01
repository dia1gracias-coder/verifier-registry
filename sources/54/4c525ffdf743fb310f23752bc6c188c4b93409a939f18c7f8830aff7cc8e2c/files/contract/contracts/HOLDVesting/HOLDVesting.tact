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
 * @traits Deployable, OwnableTransferable, Resumable, Freezeble, Calculate, Configs
 * @dev $HOLD jetton minter contract address EQB02nFR04bDweU8FyR6CJuURYmUp_Y4hZQQ_Cn63SJ0FZga (mainnet)
 */
contract HOLDVesting with Deployable, OwnableTransferable, Resumable, Freezeble, Calculate, Configs {
    owner: Address;
    stopped: Bool;
    frozenAt: Int;
    jettonMaster: Address;
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
    init(owner: Address, jettonMaster: Address, jettonWalletCode: Cell) {
        self.owner = owner;
        self.stopped = false;
        self.frozenAt = 0;
        self.jettonMaster = jettonMaster;
        self.jettonWalletCode = jettonWalletCode;
        self.configs = emptyMap();
        self.totalAllocateJettons = emptyMap();
        self.totalDebtJettons = 0;
    }

    /**
     * @message AllocateJettons
     * @description Handles the allocate jettons request from the sender.
     * Ensures contract is not frozen or stopped, validates the sender, and updates the allocate jetton amounts.
     *
     * @param msg: AllocateJettons
     */
    receive(msg: AllocateJettons) {
        self.requireFrozen();
        self.requireNotStopped();
    
        require(msg.amount > 0, "Amount must be greater than 0");

        let config: Config = self.getConfig(msg.configId);
        self.requireSender(config.receiver);

        let frozenDuration: Int = now() - self.frozenAt;
        require(frozenDuration > config.cliffDuration, "The cliff date has not yet come");

        let currentReleaseDuration: Int = (frozenDuration - config.cliffDuration);
        let currentCycle: Int = currentReleaseDuration / config.cycleReleaseDuration;
        let availableAmount: Int = currentCycle * self.calcPercent(config.amount, config.cycleReleasePercent);
        require(availableAmount >= msg.amount, "Invalid amount");

        let totalAmount: Int? = self.totalAllocateJettons.get(msg.configId);
        if (totalAmount != null) {
            self.totalAllocateJettons.set(msg.configId, msg.amount + totalAmount!!);
        } else {
            self.totalAllocateJettons.set(msg.configId, msg.amount);
        }

        self.transferJettons(msg.queryId, msg.amount, config.receiver);
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
                customPayload: emptyCell(),
                forwardTonAmount: 0,
                forwardPayload: emptySlice()
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
                .storeAddress(self.jettonMaster)
                .storeRef(self.jettonWalletCode)
                .endCell(),
        };

        return contractAddress(stateInit);
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
     * @getter totalDebtJettons
     * @description Returns the total amount of debt jettons.
     * @return Int
     */
    get fun totalDebtJettons(): Int {
        return self.totalDebtJettons;
    }
}
