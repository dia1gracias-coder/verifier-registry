message CreateCampaign {
    id: Int as uint32;
    name: String;
}

message NewCampaign{
    parent: Address;
    name: String;
}

message WithdrawCampaign{
    amount: Int as uint32;
    recipient: Address;
}

message ChangeStatusCampaign{
    active: Bool;
}

message ReceiveDonate{
    amount: Int as uint32;
}

message DeleteCampaign{
    id: Int as uint32;
}

message RemoveCampaign{
    parent: Address;
}
