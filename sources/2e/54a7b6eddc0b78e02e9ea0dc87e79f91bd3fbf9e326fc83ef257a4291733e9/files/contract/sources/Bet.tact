import "@stdlib/deploy";
import "./goal.tact";
import "./Github.tact";
import "./GoalType.tact";
message LinkWallet {
  address: Address;
  github: String;
}
message CreateGoal {
  goalType: Int;
  name: String;
  description: String;
  requiredStake: Int;
  taskCount: Int;
}
message StakeAndUnlockGoal {
  goalId: Int;
}
message ConfirmTaskCompletion {
  goalId: Int;
  user: Address;
}
message ClaimStake {
  goalId: Int;
}
message SettleGoal {
  goalId: Int;
}
message CreateProject {
  projectId: String;
  name: String;
}
message CreateTask {
  id: String;
  name: String;
  projectId: String;
}
message ConfirmTask {
  taskId: String;
  github: String;
  taskPoints: Int;
}
message DonateToProject {
  projectId: String;
  amount: Int;
}
message ClaimReward {
  projectId: String;
}

contract Bet with Deployable {
  owner: Address;
  goals: map<Int as uint256, Goal>;
  goalsLen: Int as uint256;
  tasks: map<Int as uint256, Task>;
  tasksLen: Int as uint256;
  taskIndices: map<Int as uint256, Int as uint256>;
  userGoals: map<Address, UserGoals>;
  walletToGithub: map<Address, GithubUser>;
  githubToWallet: map<Int as uint256, Address>;
  userPoints: map<Address, Int as uint256>;
  userCompletedTasks: map<Address, CompletedTasks>;
  // reward realted
  projects: map<Int as uint256, Project>;            // stringHash => project
  projectIds: map<Int as uint256, Int as uint256>;  // index => stringHash
  projectCount: Int as uint256;
  totalRewards: map<Address, Int as uint256>;
  claimedRewards: map<Address, Int as uint256>;

  init(owner: Address){
    self.owner = owner;
    self.tasksLen = 0;
    self.goalsLen = 0;
    self.userGoals = emptyMap();
    self.goals = emptyMap();
    self.walletToGithub = emptyMap();
    self.githubToWallet = emptyMap();
    self.userPoints = emptyMap();
    self.userCompletedTasks = emptyMap();
    self.projects = emptyMap();
    self.projectIds = emptyMap();
    self.totalRewards = emptyMap();
    self.claimedRewards = emptyMap();
    self.projectCount = 0;
  }

  get fun walletToGithub(): map<Address, GithubUser> {
    return self.walletToGithub;
  }

  fun createGoalSolo(name: String,
    description: String,
    requiredStake: Int,
    taskCount: Int) {
    self.createGoalFunc(name,
      description,
      requiredStake,
      taskCount,
      GoalTypeSolo
    );
  }

  receive(msg: CreateGoal) {
    if (msg.goalType == GoalTypeSolo) {
      self.createGoalSolo(msg.name, msg.description, msg.requiredStake, msg.taskCount);
    } else {
      self.createGoal(msg.name, msg.description, msg.requiredStake, msg.taskCount);
    }
  }

  fun createGoal(name: String,
    description: String,
    requiredStake: Int,
    taskCount: Int) {
    self.createGoalFunc(name,
      description,
      requiredStake,
      taskCount,
      GoalTypeGambling
    );
  }

  fun createGoalFunc(name: String,
    description: String,
    requiredStake: Int,
    taskCount: Int,
    goalType: Int) {
    // Create new goal
    let goalId: Int = self.goalsLen;
    let goal: Goal = Goal{
      id: goalId,
      name: name,
      description: description,
      requiredStake: requiredStake,
      taskCount: taskCount,
      goalType: goalType,
      creator: self.owner,
      completed: false,
      participants: null,
      participantsCount: 0,
      isParticipant: null,
      isClaimed: null,
      completedTaskCount: null,
      rewards: null
    };
    self.goals.set(goalId, goal);
    self.goalsLen = self.goalsLen + 1;
  }

  receive(msg: LinkWallet){
    self.linkWallet(msg.address, msg.github);
  }

  fun linkWallet(address: Address, github: String) {
    let walletUser: GithubUser? = self.walletToGithub.get(address);
    require(walletUser == null, "Wallet already linked to a Github account");
    let githubUser: GithubUser = GithubUser{githubUsername: github};
    self.walletToGithub.set(address, githubUser);
    let githubHash: Int = sha256(github);
    self.githubToWallet.set(githubHash, address);
  }

  receive(msg: StakeAndUnlockGoal){
    self.stakeAndUnlockGoal(msg.goalId);
  }

  fun stakeAndUnlockGoal(goalId: Int) {
    let sender: Address = sender();
    require(goalId < self.goalsLen, "Goal does not exist.");
    let goal: Goal = self.goals.get(goalId)!!;
    if (goal.participants == null) {
      goal.participants = emptyMap();
    }
      goal.participants.set(goal.participantsCount, self.owner);
    goal.participantsCount = goal.participantsCount + 1;
    goal.isParticipant.set(sender, true);
    let userGoals: UserGoals? = self.userGoals.get(sender);
    if (userGoals == null) {
      userGoals = UserGoals{address: self.owner, goals: emptyMap(), goalsLen: 0};
    }
    let unwrappedUserGoals: UserGoals = userGoals!!;
    unwrappedUserGoals.goals.set(unwrappedUserGoals.goalsLen, goalId);
    unwrappedUserGoals.goalsLen = unwrappedUserGoals.goalsLen + 1;
    self.userGoals.set(sender, unwrappedUserGoals);
  }

  receive(msg: ConfirmTaskCompletion) {
    self.confirmTaskCompletion(msg.goalId, msg.user);
  }

  fun confirmTaskCompletion(goalId: Int, user: Address) {
    let goal: Goal = self.goals.get(goalId)!!;
    let completedTaskCount: Int = goal.completedTaskCount.get(user)!!;
    goal.completedTaskCount.set(user, completedTaskCount + 1);
  }

  receive(msg: ClaimStake) {
    self.claimStake(msg.goalId);
  }

  fun claimStake(goalId: Int) {
    let goal: Goal = self.goals.get(goalId)!!;
    let sender: Address = sender();

    let reward: Int = 0;
    if (goal.goalType == GoalTypeSolo) {
      reward = (goal.requiredStake*goal.completedTaskCount.get(sender)!!)/goal.taskCount;
    } else {
      reward = goal.rewards.get(sender)!!;
    }

    send(SendParameters{
      to: sender,
      value: reward,
    });
    goal.isClaimed.set(sender, true);
  }


  receive(msg: SettleGoal) {
    self.settleGoal(msg.goalId);
  }

  fun settleGoal(goalId: Int) {
    let goal: Goal = self.goals.get(goalId)!!;

    let totalStake: Int = 0;
    let totalCompletedTasks: Int = 0;
    let totalParticipants: Int = goal.participantsCount;
    let fee: Int = (totalParticipants*goal.requiredStake)/100;

    foreach (_, participant in goal.participants) {
      totalStake = totalStake + goal.requiredStake;
      totalCompletedTasks = totalCompletedTasks + goal.completedTaskCount.get(participant)!!;
    }

    totalStake = totalStake - fee;

    foreach (i, participant in goal.participants) {
      let userCompletedTaskCount: Int = goal.completedTaskCount.get(participant)!!;
      if (userCompletedTaskCount > 0) {
        let reward: Int = (totalStake*userCompletedTaskCount)/totalCompletedTasks;
        goal.rewards.set(participant, reward);
      }
    }

    goal.completed = true;
  }

  get fun allGoals(): map<Int as uint256, GoalInfo> {
    let results: map<Int as uint256, GoalInfo> = emptyMap();
    foreach (goalId, goal in self.goals) {
      let goalInfo: GoalInfo = GoalInfo{
        id: goal.id,
        name: goal.name,
        description: goal.description,
        requiredStake: goal.requiredStake,
        creator: goal.creator,
        completed: goal.completed,
        participants: goal.participants,
        goalType: goal.goalType
      };
      results.set(goalId, goalInfo);
    }
    return results;
  }

  

  get fun userGoals(address: Address): map<Int as uint256, Int as uint256> {
    let uGoals: UserGoals? = self.userGoals.get(address);
    if (uGoals == null) {
      return emptyMap();
    }
    return uGoals!!.goals;
  }

  get fun goalDetails(goalId: Int): GoalInfo {
    let goal: Goal = self.goals.get(goalId)!!;
    let goalInfo: GoalInfo = GoalInfo{
      id: goal.id,
      name: goal.name,
      description: goal.description,
      requiredStake: goal.requiredStake,
      creator: goal.creator,
      completed: goal.completed,
      participants: goal.participants,
      goalType: goal.goalType
    };
    return goalInfo;
  }

  get fun allTasks(): map<Int as uint256, Task> {
    return self.tasks;
  }

  get fun unconfirmedTasks(): map<Int as uint256, Task> {
    let results: map<Int as uint256, Task> = emptyMap();
    let count: Int = 0;
    foreach (taskId, task in self.tasks) {
      if (!task.completed) {
        results.set(count, task);
        count = count + 1;
      }
    }
    return results;
  }


  receive(msg: CreateProject) {
    self.createProject(msg.projectId, msg.name);
  }

  fun createProject(projectId: String, name: String) {
    let projectIdHash: Int = sha256(projectId);
    require(self.projects.get(projectIdHash) == null, "Project already exists.");
    let newProject: Project = Project{
      id: projectId,
      userPoints: emptyMap(),
      participants: emptyMap(),
      participantsCount: 0,
    };
    self.projects.set(projectIdHash, newProject);
    self.projectIds.set(self.projectCount, projectIdHash);
    self.projectCount = self.projectCount + 1;
  }

  receive(msg: CreateTask) {
    self.createTask(msg.id, msg.name, msg.projectId);
  }

  fun createTask(id: String, name: String, projectId: String) {
    // Check if the project exists, if not, create it
    let projectIdHash: Int = sha256(projectId);
    let project: Project? = self.projects.get(projectIdHash);
    if (project == null) {
      self.createProject(projectId, name);
    }

    // Ensure the task doesn't already exist
    let taskIdHash: Int = sha256(id);
    require(self.taskIndices.get(taskIdHash) == null, "Task already exists.");

    let task: Task = Task{
      id: id,
      name: name,
      completed: false,
      projectId: projectId,
      taskCompleter: self.owner,
    };
    self.tasks.set(self.tasksLen, task);
    self.taskIndices.set(taskIdHash, self.tasksLen);
    self.tasksLen = self.tasksLen + 1;
  }

  receive(msg: ConfirmTask) {
    self.confirmTask(msg.taskId, msg.github, msg.taskPoints);
  }

  fun confirmTask(taskId: String, github: String, taskPoints: Int) {
    let taskIndex: Int = self.taskIndices.get(sha256(taskId))!!;
    let task: Task = self.tasks.get(taskIndex)!!;
    let userAddress: Address = self.githubToWallet.get(sha256(github))!!;

    task.completed = true;
    task.taskCompleter = userAddress;
    let userCompletedTasks: CompletedTasks = self.userCompletedTasks.get(userAddress)!!;
    let taskIdHash: Int = sha256(taskId);
    userCompletedTasks.tasks.set(userCompletedTasks.tasksLen, taskIdHash);
    userCompletedTasks.tasksLen = userCompletedTasks.tasksLen + 1;
    self.userCompletedTasks.set(userAddress, userCompletedTasks);

    // Update user points for both global and project-specific records
    self.userPoints.set(userAddress, self.userPoints.get(userAddress)!! + taskPoints);
    let project: Project = self.projects.get(sha256(task.projectId))!!;

    let isParticipant: Bool = false;
    if (project.userPoints.get(userAddress) != null) {
      isParticipant = true;
    }
    if (!isParticipant) {
      project.participants.set(project.participantsCount, userAddress);
      project.participantsCount = project.participantsCount + 1;
    }
  }

  receive(msg: DonateToProject) {
    self.donateToProject(msg.projectId, msg.amount);
  }

  fun donateToProject(projectId: String, amount: Int) {
    let project: Project = self.projects.get(sha256(projectId))!!;
    let totalProjectPoints: Int = 0;
    let ctx: Context = context();
    foreach (_, participant in project.participants) {
      totalProjectPoints = totalProjectPoints + self.userPoints.get(participant)!!;
    }

    if (totalProjectPoints > 0) {
      // Distribute donation based on userPoints
      foreach (_, participant in project.participants) {
        let userShare: Int = (self.userPoints.get(participant)!!*ctx.value)/totalProjectPoints;
        self.totalRewards.set(participant, self.totalRewards.get(participant)!! + userShare);
      }
    }
  }

  // TODO: just get project ids
  get fun allProjectIds(): map<Int as uint256, Project> {
    let results: map<Int as uint256, Project> = emptyMap();
    foreach (projectId, _ in self.projectIds) {
      results.set(projectId, self.projects.get(projectId)!!);
    }
    return results;
  }

  get fun projectParticipants(projectId: String): map<Int as uint256, Address> {
    let project: Project = self.projects.get(sha256(projectId))!!;
    return project.participants;
  }

  get fun projectUserPoints(projectId: String, user: Address): Int {
    let project: Project = self.projects.get(sha256(projectId))!!;
    return project.userPoints.get(user)!!;
  }

  receive(msg: ClaimReward) {
    self.claimReward(msg.projectId);
  }

  fun claimReward(projectId: String) {
    let reward: Int = self.totalRewards.get(sender())!! - self.claimedRewards.get(sender())!!;
    self.claimedRewards.set(sender(), self.claimedRewards.get(sender())!! + reward);
    send(SendParameters{
      to: sender(),
      value: reward,
    });
  }

  get fun totalRewards(user: Address): Int {
    return self.totalRewards.get(user)!!;
  }

  get fun claimedRewards(user: Address): Int {
    return self.claimedRewards.get(user)!!;
  }

  get fun userPoints(user: Address): Int {
    return self.userPoints.get(user)!!;
  }

  get fun userCompletedTasks(user: Address): map<Int as uint256, Int as uint256> {
    return self.userCompletedTasks.get(user)!!.tasks;
  }

  get fun githubByWallet(wallet: Address): String {
    return self.walletToGithub.get(wallet)!!.githubUsername;
  }
}