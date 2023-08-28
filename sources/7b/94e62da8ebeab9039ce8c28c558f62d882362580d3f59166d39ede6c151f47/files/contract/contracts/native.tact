struct ParsedAddress {
	wc: Int;
	hash: Int;
}

@name(parse_std_addr)
native parseAddress(addr: Address): ParsedAddress;

@name(cur_lt)
native now_lt(): Int;

@name(muldiv)
native muldiv(x: Int, y: Int, z: Int): Int;