message UpdateMinTonsForStorage {
    min_tons_for_storage: Int as coins;
}

message UpdateGasConsumption {
    gas_consumption: Int as coins;
}

trait GasConsumption {
    admin: Address?;
    gas_consumption: Int as coins;
    min_tons_for_storage: Int as coins;

    receive(msg: UpdateMinTonsForStorage) {
        require(sender() == self.admin, "only admin can update min_tons_for_storage");
        self.min_tons_for_storage = msg.min_tons_for_storage;
    }

    receive(msg: UpdateGasConsumption) {
        require(sender() == self.admin, "only admin can update gas_consumption");
        self.gas_consumption = msg.gas_consumption;
    }

    get fun gasConsumption(): Int {
        return self.gas_consumption;
    }

    get fun minTonsForStorage(): Int {
        return self.min_tons_for_storage;
    }
}
