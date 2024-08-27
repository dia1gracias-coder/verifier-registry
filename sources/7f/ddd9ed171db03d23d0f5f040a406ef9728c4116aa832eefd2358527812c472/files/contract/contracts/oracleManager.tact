import "@stdlib/ownable";

message ActivateOracle {
    oracle: Address;
    isActivated: Bool;
}

trait OracleManager with OwnableTransferable {
    owner: Address;
    oracles: map<Address, Bool>;

    fun requireOracle() {
        let isOracle: Bool? = self.oracles.get(sender());
        require(isOracle == true, "Only oracle allowed");
    }

    fun activateOracle(oracle: Address, isActivated: Bool) {
        self.oracles.set(oracle, isActivated);
        emit(ActivateOracle{
            oracle: oracle,
            isActivated: isActivated
        }.toCell());
    }

    get fun oracles(): map<Address, Bool> {
        return self.oracles;
    }

    // Owner activate/deactivate oracle
    receive(msg: ActivateOracle) {
        self.requireOwner();


        if (self.oracles.get(msg.oracle) != msg.isActivated) {
            self.activateOracle(msg.oracle, msg.isActivated);
        }
    }
}