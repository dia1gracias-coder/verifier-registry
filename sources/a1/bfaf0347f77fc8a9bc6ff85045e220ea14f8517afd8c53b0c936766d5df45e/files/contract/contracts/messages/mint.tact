// Minter Contract Receives a "Minter_Create" message
message Minter_Create {
    query_id: Int as uint64;
    content: Cell;
    amountIn: Int as coins;
    amountOut: Int;
}
// Token Contract Receives a "Token_New" message
message Token_New {
    query_id: Int;
    initial_sender: Address;
    amountIn: Int as coins;
    amountOut: Int;
}