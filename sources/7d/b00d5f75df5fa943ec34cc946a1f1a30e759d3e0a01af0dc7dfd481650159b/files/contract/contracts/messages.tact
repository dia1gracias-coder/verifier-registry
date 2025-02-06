import "./structs/assets.tact";
import "./structs/user_reward.tact";
import "./structs/rewards_array.tact";

// External messages
message GrantOperator {
  address: Address;
}

message RevokeOperator {
  address: Address;
}

message RegisterSponsor {
  sponsorId: Int;
  communityPercent: Int as uint16;
  threshold: Int as coins;
}

message SponsorWithTon {
  sponsorId: Int;
  amount: Int as coins;
}

message WithdrawProtocolTon {
  address: Address;
}

message WithdrawProtocolUSDT {
  address: Address;
}

message RewardUser {
  reward: UserReward;
}

message RewardUsers {
  rewards: RewardsArray;
}

message SetUSDTWallet {
  address: Address;
}

message SetCommunityPercent {
  sponsorId: Int;
  percent: Int as uint16;
}

//Interanal messages
message InternalSetCommunityPercent {
  percent: Int as uint16;
  initiator: Address;
}

message InternalRegisterSponsorship {
  amount: Assets;
  initiator: Address;
}

message InternalApproveSponsorship {
  sponsorId: Int;
  amount: Assets;
  communityPercent: Int as uint16;
  initiator: Address;
}

message InternalResetSponsor {
  sponsorId: Int;
  communityPercent: Int as uint16;
  threshold: Int as coins;
  initiator: Address;
}

// Success responses
message SponsorReset {
  sponsorId: Int;
  communityPercent: Int as uint16;
  threshold: Int as coins;
}

message ProtocolWithdrawnTon {
  address: Address;
  amount: Int as coins;
}

message ProtocolWithdrawnUsdt {
  address: Address;
  amount: Int as coins;
}

message UsersRewarded {
  usersAmount: Int;
  totalReward: Assets;
}

message USDTWalletSet {
  address: Address;
}

message CommunityPercentSet {
  sponsorId: Int;
  percent: Int as uint16;
}

message SponsorshipAccepted {
  sponsorId: Int;
  amount: Assets;
}

// Notification messages

message QstMeRewardTon {
  amount: Int as coins;
}

message QstMeRewardUsdt {
  amount: Int as coins;
}

message QstMeWithdrawalTon {
  amount: Int as coins;
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