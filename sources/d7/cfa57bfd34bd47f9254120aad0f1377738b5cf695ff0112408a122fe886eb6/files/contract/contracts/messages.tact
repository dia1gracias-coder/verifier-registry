message Mint {
    index   : Int as uint32;
    amount  : Int as coins;
    content : String;
    owner   : Address;
}

message NftDeploy {
    index   : Int as uint32;
    content : String;
    owner   : Address;
}

message NftTransfer {
    query_id  : Int as uint64;
    new_owner : Address;
    response_destination: Address;
    custom_payload  : Cell?;
    forward_amount  : Int as coins;
    forward_payload : Slice as remaining;
}

message NftOwnershipAssigned {
    query_id   : Int as uint64;
    prev_owner : Address;
    forward_payload: Slice as remaining;
}

message NftExcesses {
    query_id: Int as uint64;
}

message NftGetStaticData {
    query_id: Int as uint64;
}

message NftReportStaticData {
    query_id : Int as uint64;
    index    : Int as uint32;
    collection_address : Address;
} 

message UpdateSettings {
    queryId   : Int as uint64;
    maxSupply : Int as uint32;
}

message Withdraw {
    queryId     : Int as uint64;
    amount      : Int as coins;
    destination : Address;
}
