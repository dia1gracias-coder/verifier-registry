import "../../imports/signature-verifiable.tact";
message Withdrawal {
    info: WithdrawalInfo;
    signature: Slice;
    signatureMoreInfo: SignatureMoreInfo;
}
message WithdrawalInfo {
    requestId: String;
    receiver: Address;
    amount: Int as coins;
}