struct Storage {
    id: uint32
    counter: uint32
    // other: int32
    // data: NestedData2
}

struct NestedData2 {
    boolean: bool
    data: bits40
    value: coins
    data2: Cell<NestedData3>
}

struct NestedData3 {
    boolean: bool
    data: cell
    snake: SnakeString
}

type SnakeString = slice

fun SnakeString.unpackFromSlice(mutate s: slice) {
    val snakeRemainder = s;
    s = createEmptySlice();
    return snakeRemainder
}

fun SnakeString.packToBuilder(self, mutate b: builder) {
    b.storeSlice(self)
}

fun Storage.load() {
    return Storage.fromCell(contract.getData());
}

fun Storage.save(self) {
    contract.setData(self.toCell());
}
