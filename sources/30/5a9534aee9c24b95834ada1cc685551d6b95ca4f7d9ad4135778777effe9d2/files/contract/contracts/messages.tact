import "./structs/assets.tact";
import "./structs/user_reward.tact";
import "./structs/rewards_array.tact";

// External messages
message RewardUser {
  reward: UserReward;
}

message RewardUserSigned {
  reward: UserReward;
  nonce: Int;
  timestamp: Int;
  pubKey: Int;
  signature: Slice;
}

message RewardUsers {
  rewards: RewardsArray;
}

// Success responses
message UsersRewarded {
  usersAmount: Int;
}
// Notification messages

message QstMeRewardTon {
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