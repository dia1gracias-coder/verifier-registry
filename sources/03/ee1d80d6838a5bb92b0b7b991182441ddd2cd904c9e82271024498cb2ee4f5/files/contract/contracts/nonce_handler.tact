const HARD_MAX_MAP_SIZE: Int = 5000;

struct NonceHandler {
    m: map<Address, Int as uint16>;
    entries: Int as uint16;
}

fun newNonceHandler(): NonceHandler {
    return NonceHandler{m: emptyMap(), entries: 0};
}

extends fun getNextNonce(self: NonceHandler, address: Address): Int {
    let nextNonce: Int? = self.m.get(address);

    if (nextNonce == null) {
        return 0;
    }
    return nextNonce!!;
}

extends mutates fun consumeNonce(self: NonceHandler, address: Address) {
    let lastNonce: Int? = self.m.get(address);

    if (lastNonce == null) {
        require(self.entries < HARD_MAX_MAP_SIZE, "Map size too big");

        self.m.set(address, 1);
        self.entries += 1;

        return;
    }

    self.m.set(address, lastNonce!! + 1);
}
