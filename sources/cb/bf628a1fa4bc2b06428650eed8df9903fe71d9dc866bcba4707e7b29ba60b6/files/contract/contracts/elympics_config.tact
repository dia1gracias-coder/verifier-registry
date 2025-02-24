message SetMatchAuthority {
    newMatchAuthority: Address;
}

message SetElympicsTreasury {
    newElympicsTreasury: Address;
}

message SetElympicsCommission {
    newElympicsCommission: Int;
}

trait ElympicsConfig {
    deployer: Address;

    matchAuthority: Address;
    elympicsTreasury: Address;
    elympicsCommission: Int;

    receive(msg: SetMatchAuthority) {
        require(sender() == self.deployer, "Unauthorized caller");
        self.matchAuthority = msg.newMatchAuthority;
        self.notify(null);
    }

    receive(msg: SetElympicsTreasury) {
        require(sender() == self.deployer, "Unauthorized caller");
        self.elympicsTreasury = msg.newElympicsTreasury;
        self.notify(null);
    }

    receive(msg: SetElympicsCommission) {
        require(sender() == self.deployer, "Unauthorized caller");
        require(msg.newElympicsCommission < SHARE_PRECISION, "Commission too high");
        self.elympicsCommission = msg.newElympicsCommission;
        self.notify(null);
    }

    get fun matchAuthority(): Address {
        return self.matchAuthority;
    }

    get fun elympicsTreasury(): Address {
        return self.elympicsTreasury;
    }

    get fun elympicsCommission(): Int {
        return self.elympicsCommission;
    }
}
