// Token contract receives a "Token_Sell" message
message Curve_Sell{
    query_id: Int;
    amountIn: Int;
    amountOut: Int as coins;
    slippage: Int;
}