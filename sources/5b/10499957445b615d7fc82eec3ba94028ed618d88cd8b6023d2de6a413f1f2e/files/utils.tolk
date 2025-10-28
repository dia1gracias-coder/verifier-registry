type SnakeString = slice

fun SnakeString.unpackFromSlice(mutate s: slice) {
    assert (s.remainingRefsCount() <= 1) throw 5;
    val snakeRemainder = s;
    s = createEmptySlice();
    return snakeRemainder
}

fun SnakeString.packToBuilder(self, mutate b: builder) {
    b.storeSlice(self)
}

@pure
fun createBits256None(): bits256
    asm "x{0000000000000000000000000000000000000000000000000000000000000000} PUSHSLICE"