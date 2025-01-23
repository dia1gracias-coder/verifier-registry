message DeleteChain {
    chain_id:       Int;
}

message DeleteModule {
    step:           Int;
}

message DeleteStategies {
    chain_id:       Int;
    from_token:     Int;
    to_token:       Int;
}

message DeleteToken {
    symbol:         String;
}

message DeleteValidator {
    candidate:      Address;
}

message Pause {}

message SetAdmin {
    newAdmin:       Address;
}

message SetChain {
    name:           String;
    chain_id:       Int;
}

message SetCFO {
    newCFO:         Address;
}

message SetModule {
    step:           Int;
    module:         Address;
}

message SetValidator {
    candidate:      Address;
}

message SetStrategies {
    chain_id:       Int;
    from_token:     Int;
    to_token:       Int;
    foreign:        Steps;
    incomming:      Steps;
    local:          Steps;
}

message SetToken {
    address:        Address;
    decimals:       Int as uint8;
    emmet_lp:       Address;
    symbol:         String;
    swap_pool:      Address;
    swap_router:    Address;
    wallet:         Address;
}

message Unpause {}