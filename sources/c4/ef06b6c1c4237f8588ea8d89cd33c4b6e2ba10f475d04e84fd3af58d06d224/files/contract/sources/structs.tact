message AttestRequest {
    queryId: Int as uint64;
    media: Int;
    seed: Int;
    sign: Slice;
    update: Bool;
    response_destination: Address?;
}

message AttestSuccess {
    queryId: Int as uint64;
    address: Address;
    media: Int;
}

message ChangePublicKey {
    queryId: Int as uint64;
    publicKey: Int as uint256;
}

message ChangePublicKeyOk {
    queryId: Int as uint64;
}

message ChangeAttestFee {
    queryId: Int as uint64;
    attestFee: Int;
}

message ChangeAttestFeeOk {
    queryId: Int as uint64;
}

message AttestInternal {
    queryId: Int as uint64;
    media: Int;
    address: Address;
    update: Bool;
    response_destination: Address?;
}

message(0xd53276db) TokenExcesses {
    queryId: Int as uint64;
}

message Withdraw {
    amount: Int as coins;
}

struct AttestChildData {
    owner: Address;
    master: Address;
    media: Int;
    attestTime: Int as uint32;
    code: Cell?;
}

struct AttestParentData {
    owner: Address;
    initOwner: Address;
    publicKey: Int as uint256;
    initPublicKey: Int as uint256;
    attestFee: Int;
    code: Cell?;
}