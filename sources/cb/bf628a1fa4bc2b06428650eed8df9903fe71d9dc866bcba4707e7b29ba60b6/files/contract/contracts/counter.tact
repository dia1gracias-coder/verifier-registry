const MAX_NUMBER_OF_ENTRIES: Int = 16384;  // Total number of map entries cannot exceed 30_000

struct Counter {
    m: map<Address, Int as uint16>;
    entries: Int as uint16;
}

fun newCounter(): Counter {
    return Counter{m: emptyMap(), entries: 0};
}

extends fun getValue(self: Counter, address: Address): Int {
    let value: Int? = self.m.get(address);

    if (value == null) {
        return 0;
    }
    return value!!;
}

extends mutates fun increaseValue(self: Counter, address: Address, value: Int) {
    let currentValue: Int? = self.m.get(address);

    if (currentValue == null) {
        require(self.entries < MAX_NUMBER_OF_ENTRIES, "Cannot exceed max number of entries");

        self.m.set(address, value);
        self.entries += 1;

        return;
    }

    self.m.set(address, currentValue!! + value);
}

extends mutates fun decrementValue(self: Counter, address: Address) {
    let currentValue: Int? = self.m.get(address);
    require(currentValue != null, "Map entry does not exist");

    if (currentValue == 1) {
        self.m.del(address);
        self.entries -= 1;
        return;
    }

    self.m.set(address, currentValue!! - 1);
}
