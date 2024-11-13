struct Goal {
  id: Int as uint256;
  name: String;
  description: String;
  requiredStake: Int as uint256;
  creator: Address;
  completed: Bool;
  participants: map<Int as uint256, Address>; // TODO: change to parent-child
  participantsCount: Int as uint256;
  taskCount: Int as uint256;
  goalType: Int;
  isParticipant: map<Address, Bool>;
  isClaimed: map<Address, Bool>;
  completedTaskCount: map<Address, Int as uint256>;
  rewards: map<Address, Int as uint256>;
}
struct GoalInfo {
  id: Int as uint256;
  name: String;
  description: String;
  requiredStake: Int as uint256;
  creator: Address;
  completed: Bool;
  participants: map<Int as uint256, Address>;
  goalType: Int;
}
struct Task {
  id: String;
  name: String;
  completed: Bool;
  projectId: String;
  taskCompleter: Address;
}
struct Project {
  id: String;
  userPoints: map<Address, Int as uint256>;
  participants: map<Int as uint256, Address>;
  participantsCount: Int as uint256;
}
struct UserGoals {
  address: Address;
  goals: map<Int as uint256, Int as uint256>;
  goalsLen: Int as uint256;
}
struct CompletedTasks {
  address: Address;
  tasks: map<Int as uint256, Int as uint256>;
  tasksLen: Int as uint256;
}