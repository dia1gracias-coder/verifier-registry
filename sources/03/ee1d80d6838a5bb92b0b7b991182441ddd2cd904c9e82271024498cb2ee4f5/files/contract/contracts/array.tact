const HARD_MAX_ARRAY_SIZE: Int = 1000;  // cannot exceed 30_000

struct PlayerRecord {
    score: Int as int64;
    userAddress: Address;
}

struct MapArray {
    m: map<Int as uint16, PlayerRecord>;
    length: Int = 0;
    maxSize: Int as uint16;
}

fun emptyArray(maxSize: Int): MapArray {
    require(maxSize <= HARD_MAX_ARRAY_SIZE, "Array size too big");
    return MapArray{m: emptyMap(), length: 0, maxSize};
}

extends fun get(self: MapArray, idx: Int): PlayerRecord {
    require(idx >= 0, "Invalid index");
    require(idx < self.length, "Index out of bounds");

    return self.m.get(idx)!!;
}

extends mutates fun insertAt(self: MapArray, item: PlayerRecord, idx: Int) {
    require(idx >= 0, "Invalid index");
    require(idx < self.maxSize, "Index out of bounds");

    let i: Int = self.length;
    while (i > idx) {
        self.m.set(i, self.m.get(i - 1)!!);
        i -= 1;
    }

    self.m.set(idx, item);

    if (self.length == self.maxSize) {
        self.m.del(self.length);
    } else {
        self.length += 1;
    }
}

extends mutates fun deleteAt(self: MapArray, idx: Int) {
    require(idx >= 0, "Invalid index");
    require(idx < self.length, "Index out of bounds");

    let i: Int = idx;
    let length = self.length;
    while (i + 1 < length) {
        self.m.set(i, self.m.get(i + 1)!!);
        i += 1;
    }

    self.m.del(length);
    self.length -= 1;
}
