import "@stdlib/deploy";
import "@stdlib/ownable";

contract OrcMine with Deployable, Ownable {
    owner: Address;
    collectedJettons: Int;
    rewardsPool1: Int;  // 60% play-to-earn pool
    rewardsPool2: Int;  // 20% leaderboard & stake pool

    init() {
        self.owner = sender();
        self.collectedJettons = 0;
        self.rewardsPool1 = 0;
        self.rewardsPool2 = 0;
    }
}