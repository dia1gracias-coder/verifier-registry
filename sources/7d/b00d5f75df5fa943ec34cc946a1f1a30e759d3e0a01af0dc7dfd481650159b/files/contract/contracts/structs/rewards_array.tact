import "./user_reward.tact";

struct RewardsArray {
  e: map<Int, UserReward>;
  length: Int;
}

extends fun getIdx(self: RewardsArray, idx: Int): UserReward {
  require(self.length > 0, "No items in the array!");
  require(idx >= 0, "Index of the item cannot be negative!");
  require(idx < self.length, "Index is out of array bounds!");

  return self.e.get(idx)!!;
}