// jetton types
message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining;
}

message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; 
}

message(0xd53276db) TokenExcesses {
  queryId: Int as uint64;
}

struct PersonDetails {
    name: String;
    address: String;
}

struct Commissions {
    // Transfership commission for the exclusive rights transfership
    transfershipCommissionPercentage: Int as uint256; // in per cent mille (1/1000)

    // Referral commission for the exclusive rights transfership.
    referralCustomerCommissionPercentage: Int as uint256; // in per cent mille (1/1000)
    referralFreelancerCommissionPercentage: Int as uint256; // in per cent mille (1/1000)
}

fun validateCommissions(commissions: Commissions) {
    require(commissions.transfershipCommissionPercentage >= 0, "Transfership commission percentage can't be less than 0");
    require(commissions.transfershipCommissionPercentage <= 1000, "Transfership commission percentage can't be greater than 1000");

    require(commissions.referralCustomerCommissionPercentage >= 0, "Referral customer commission percentage can't be less than 0");
    require(commissions.referralCustomerCommissionPercentage <= 1000, "Referral customer commission percentage can't be greater than 1000");

    require(commissions.referralFreelancerCommissionPercentage >= 0, "Referral freelancer commission percentage can't be less than 0");
    require(commissions.referralFreelancerCommissionPercentage <= 1000, "Referral freelancer commission percentage can't be greater than 1000");
}

message (1263034725) SetCommissions {
    commissions: Commissions;

    // if there is no address, the commision will be updated for the deal contract
    dealAddress: Address?;
}

message (0x56548561) SetOracleAddress {
  oracleAddress: Address;
  dealAddress: Address?;
}

message (0x70958879) GetFunds {
  amount: Int as coins;
  usdt: Bool?;
  dealAddress: Address?;
}
