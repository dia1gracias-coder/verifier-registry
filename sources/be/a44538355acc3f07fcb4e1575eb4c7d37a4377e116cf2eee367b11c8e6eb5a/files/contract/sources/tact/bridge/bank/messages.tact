
message DeployNewBridgeToken {
    content: Cell;
    max_supply: Int;
    symbol:String;
}

message DebugDeployNewBridgeToken {
    content: Cell;
    max_supply: Int;
    symbol:String;
}

message DebugReceive {
    content: Cell;
    max_supply: Int;
    from: Address;
}

message MintBridgeToken {
    masterAddr: Address;
    receiver: Address;
    amount:     Int as uint256;
}

message JettonBasicInfo {
    name: String;
    description: String;
    symbol:String;
    image:String;
}

message LogNewBridgeTokenEvent {
    masterAddr: Address;
    symbol: String;
}

struct NewOracleClaim {
    seqNo: Int as uint64; //因为该字段最终会被填充到TokenTransferInternal的query_id，所以将数据类型定义为uint64
    receiver: Address;
    jettonMaster: Address;
    srcTxHash: Int as uint256;
    amount: Int as uint256;
}

struct DeployedJetton {
    symbol: String;
    master: Address;
}

message NewOracleClaimMulSigs {
    newOracleClaim: NewOracleClaim;
    claimID: Int as uint256;
    signature0: Slice;
    signature1: Slice;
    signature2: Slice;
}

message NewOracleClaimMulSigsDebug {
    newOracleClaim: NewOracleClaim;
    claimID: Int as uint256;
    signature1: Slice;
    signature2: Slice;
    claimID2: Int as uint256;
}

message LogProphecyProcessedEvent {
    claimID: Int as uint256;
    submitter: Address;
    seqNo: Int as uint64;
}

message LogMintProcessPhase {
    phase: Int as uint8;
}

message LogMintProcessDebugInfo {
    phase: Int as uint8;
    claimID: Int as uint256;
    hashValue: Int as uint256;
}

