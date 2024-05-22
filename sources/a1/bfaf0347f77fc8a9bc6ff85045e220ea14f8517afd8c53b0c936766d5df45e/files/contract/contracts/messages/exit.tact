message(0xfcf9e58f) PROVIDE_LP {
    token_wallet1: Address;
    min_lp_out: Int as coins;
}
message Minter_Exit {
    query_id: Int as uint64;
    token: Address;
    amount0: Int as coins;
    amount1: Int as coins;
}
message TOKEN_EXIT_START {
    token: Address;
    min_lp_out: Int as coins;
}
message TOKEN_EXIT {
    creator: Address;
    min_lp_out: Int as coins;
}