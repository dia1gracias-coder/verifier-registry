const RESELL_OWNER_FEE: Int = 500;

struct RoyaltyCollector {
    collectorAddress: Address;
    royaltyFee: Int as int16;   // 10000 = 100.00%
}

// TODO: No more than 256 collectors
struct RoyaltyCollectorArray {
    royaltyCollectors: map<Int as uint8, RoyaltyCollector>;
    length: Int as uint8;
}

extends fun getCollectorByIndex(self: RoyaltyCollectorArray, index: Int): RoyaltyCollector {
    // TODO: requirements
    return self.royaltyCollectors.get(index)!!;
}

extends fun getFeeByIndex(self: RoyaltyCollectorArray, index: Int): Int {
    // TODO: requirements
    return self.royaltyCollectors.get(index)!!.royaltyFee;
}

extends mutates fun appendCollector(self: RoyaltyCollectorArray, address: Address, fee: Int) {
    let collector = RoyaltyCollector {
        collectorAddress: address,
        royaltyFee: fee,
    };

    let n = self.length;
    self.royaltyCollectors.set(n, collector);
    self.length += 1;
}