const ONE_TON: Int = ton("1");

const FIXED_ONE: Int = 1 << 128;

const MAX_FEE: Int = 10000;

@name(muldivr)
native muldivr(x: Int, y: Int, z: Int): Int;
