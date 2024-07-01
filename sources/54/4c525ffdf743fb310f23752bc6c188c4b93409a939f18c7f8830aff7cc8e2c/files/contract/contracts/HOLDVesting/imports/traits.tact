import "@stdlib/ownable";
import "@stdlib/stoppable";

import "./messages";

/**
 * @interface hold.vesting.freezeble
 * @description Trait that implements the freeze logic.
 */
@interface("hold.vesting.freezeble")
trait Freezeble with Ownable {
    owner: Address;
    frozenAt: Int;

    /**
     * @message Freeze
     * @description Freezes the contract, preventing certain actions until unfrozen.
     * Only the owner can freeze the contract.
     */
    receive("Freeze") {
        self.requireOwner();
        self.requireNotFrozen();

        self.frozenAt = now();
    }

    /**
     * @message SetFreeze
     * @description Sets a specific freezing time for the contract. Only the owner can set the freeze time.
     * @param msg: SetFreeze
     */
    receive(msg: SetFreeze) {
        self.requireOwner();
        self.requireNotFrozen();
        require(msg.newFrozenAt >= now(), "Freezing time cannot be in the past");

        self.frozenAt = msg.newFrozenAt;
    }

    /**
     * @private
     * @description Ensures the contract is not currently frozen.
     */
    fun requireNotFrozen() {
        require(self.frozenAt == 0 || self.frozenAt > now(), "Contract frozen");
    }

    /**
     * @private
     * @description Ensures the contract is currently frozen.
     */
    fun requireFrozen() {
        require(self.frozenAt != 0 && self.frozenAt <= now(), "Contract not frozen");
    }

    /**
     * @getter isFrozen
     * @description Returns true if the contract is currently frozen.
     * @return Bool
     */
    get fun isFrozen(): Bool {
        return self.frozenAt != 0 && self.frozenAt <= now();
    }

    /**
     * @getter frozenAt
     * @description Returns the freezing timestamp of the contract.
     * @return Int
     */
    get fun frozenAt(): Int {
        return self.frozenAt;
    }
}

/**
 * @interface hold.vesting.configs
 * @description Trait that implements the logic of working with cofigs, initializing, receipt, etc.
 */
@interface("hold.vesting.configs")
trait Configs with Ownable, Resumable, Freezeble {
    owner: Address;
    stopped: Bool;
    frozenAt: Int;
    configs: map<Int as uint8, Config>;

    /**
     * @message SetConfig
     * @description Sets a configuration for the vesting schedule. Only the owner can set configurations.
     * @param msg: SetConfig
     */
    receive(msg: SetConfig) {
        self.requireOwner();
        self.requireNotFrozen();
        self.requireNotStopped();

        let config: Config = Config{
            amount: msg.amount,
            receiver: msg.receiver,
            cliffDuration: msg.cliffDuration,
            cycleReleaseDuration: msg.cycleReleaseDuration,
            cycleReleasePercent: msg.cycleReleasePercent
        };

        self.configs.set(msg.configId, config);
    }

    /**
     * @private
     * @description Retrieves a configuration by its ID. Throws an error if the configuration is not found.
     * @param configId: Int
     * @return Config
     */
    fun getConfig(configId: Int): Config {
        let config: Config? = self.configs.get(configId);
        require(config != null, "Config is not found");
        return config!!;
    }

    /**
     * @getter config
     * @description Returns a configuration by its ID.
     * @param configId: Int
     * @return Config?
     */
    get fun config(configId: Int): Config? {
        return self.configs.get(configId);
    }
}

/**
 * @interface hold.vesting.calculate
 * @description Trait that implements the logic of working with mathematical calculations.
 */
@interface("hold.vesting.calculate")
trait Calculate {
    virtual const PERCENT_DECIMALS: Int = 2;

    /**
     * @private
     * @description Calculates the percentage of a total amount.
     * @param total: Int
     * @param percent: Int
     * @return Int
     */
    fun calcPercent(total: Int, percent: Int): Int {
        return total * pow(10, self.PERCENT_DECIMALS) / percent;
    }
}
