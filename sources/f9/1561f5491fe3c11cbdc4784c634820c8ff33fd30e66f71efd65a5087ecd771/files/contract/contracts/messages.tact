// OperatorControl messages
message GrantOperator {
  address: Address;
}

message RevokeOperator {
  address: Address;
}

// QstMeSponsorsMain messages
message RegisterSponsor {
  id: Int as uint64;
}

message SponsorRegistered {
  id: Int as uint64;
}

message WithdrawProtocolTon {
  address: Address;
}

message WithdrawProtocolUSDT {
  address: Address;
}

message ProtocolWithdrawn {
  address: Address;
  asset: String;
  amount: Int as coins;
}

message RewardUserTon {
  address: Address;
  amount: Int as coins;
}

message RewardUserUSDT {
  address: Address;
  amount: Int as coins;
}

message QstMeReward {
  asset: String;
  amount: Int as coins;
}

message QstMeWithdraw {
  asset: String;
  amount: Int as coins;
}

message UserRewarded {
  address: Address;
  amount: Balance;
}

message SetUSDTWallet {
  address: Address;
}

message USDTWalletSet {
  address: Address;
}

//QstMeSponsor messages
message Sponsor {
  sponsor: Int as uint64;
  amount: Int as coins;
}

message SponsorshipApproved {
  sponsor: Int as uint64;
  amount: Int as coins;
}

message RegisterSponsorship {
  sponsor: Int as uint64;
  amount: Balance;
}

message ApproveSponsorship {
  sponsor: Int as uint64;
  amount: Balance;
}

// Jetton messages
message(0x7362d09c) JettonTransferNotification {
  // Unique identifier used to trace transactions across multiple contracts
  // Defaults to 0, which means we don't mark messages to trace their chains
  queryId: Int as uint64;

  // Amount of Jettons transferred
  amount: Int as coins;

  // Address of the sender of the Jettons
  sender: Address;

  // Optional custom payload
  forwardPayload: Slice as remaining;
}

message(0xf8a7ea5) JettonTransfer {
  // Unique identifier used to trace transactions across multiple contracts
  queryId: Int as uint64;

  // Jetton amount to transfer
  amount: Int as coins;

  // Where to transfer Jettons:
  // this is an address of the Jetton wallet
  // owner and not the Jetton wallet itself
  destination: Address;

  // Where to send a confirmation notice of a successful transfer
  // and the rest of the incoming message value
  responseDestination: Address?;

  // Can be used for custom logic of Jettons themselves,
  // and without such can be set to null
  customPayload: Cell? = null;

  // Amount to transfer with JettonTransferNotification,
  // which is needed for the execution of custom logic
  forwardTonAmount: Int as coins; // if its 0, the notification won't be sent!

  // Compile-time way of expressing:
  //     beginCell().storeUint(0xF, 4).endCell().beginParse()
  // For more complicated transfers, adjust accordingly
  forwardPayload: Slice as remaining;
}