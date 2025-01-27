import "../imports/mathlib.fc";
//import "../imports/mathlib64.fc";

const ONE_TON: Int = ton("1");

const FIXED_ONE: Int = 1 << 248;

const SCALE: Int = 10000000000000000000;
const FEE_SCALE: Int = 10000;

@name(muldivr)
native muldivr(x: Int, y: Int, z: Int): Int;

@name(fixed248::mul)
native fixed248mul(x: Int, y: Int): Int;

@name(fixed248::pow)
native fixed248Pow(x: Int, y: Int): Int;

@name(fixed248::exp)
native fixed248Exp(x: Int): Int;
