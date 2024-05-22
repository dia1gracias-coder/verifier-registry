struct Return {
    input: Int;
    output: Int;
}
// Token contract receives a "Token_Buy" message
message Curve_Buy {
    query_id: Int;
    amountIn: Int as coins;
    amountOut: Int;
    slippage: Int;
}
message Processed_Buy {
}