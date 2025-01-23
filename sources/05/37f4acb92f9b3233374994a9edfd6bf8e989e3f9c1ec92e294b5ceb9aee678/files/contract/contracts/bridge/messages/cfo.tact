

message UpdateChainFee {
    chain_id:       Int;
    strategy_step:  Int as uint8;
    gas_amount:     Int; // in TON
}

message UpdateConsensusFee {
    amount:         Int;
}

message UpdateMinimumTxFee {
    amount:         Int;
}

message UpdateProtocolFee {
    amount:         Int;
}

message WithdrawGas {
    amount:         Int;
}