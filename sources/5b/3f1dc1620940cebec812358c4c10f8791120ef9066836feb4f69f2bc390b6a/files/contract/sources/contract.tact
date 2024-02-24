import "@stdlib/deploy";
import "@stdlib/ownable";

message Withdraw {}

struct Player {
    address: Address;
    bit: Int as coins;
}

struct Game {
    // Array with players 
    players: map<Int, Player>;
    currPlayerIdx: Int as int8;

    winPlayerIdx: Int as int8;
    timestamp: Int as uint32;
}

contract TheLottery with Deployable, Ownable {

    // Constants with game options
    const ContractFee: Int = 2500; // 2.5% in percent
    const MinTonForStorage: Int = ton("0.5");
    const MaxGameHistorySize: Int = 100;
    const minBet: Int = ton("1.0");
    const maxPlayers: Int = 5;

    owner: Address;

    // Array with games
    games: map<Int, Game>;
    currGameIdx: Int as uint64;

    lockedBalance: Int as coins = 0;
    totalRevenue: Int as uint128 = 0;

    init(owner: Address) {
        self.owner = owner;

        // Initialize empty array for games
        self.currGameIdx = 0;
        self.games = emptyMap();

        let players: map<Int, Player> = emptyMap();
        self.games.set(self.currGameIdx, Game{
            players: players, 
            currPlayerIdx: -1,
            winPlayerIdx: -1,
            timestamp: now()
        });
    }

    receive(msg: Withdraw) {
		self.requireOwner();	

		send(SendParameters{
            to: self.owner,
            bounce: true,
            value: myBalance() - self.lockedBalance - context().value - self.MinTonForStorage,
            mode: SendRemainingValue + SendIgnoreErrors,
            body: "Contract withdrawal".asComment()
		});
    }

    receive() {
        let ctx: Context = context();
        let currGame: Game = self.games.get(self.currGameIdx)!!;

        // Is User already a Player in current game?
        require(self.isUserInGame(ctx.sender, currGame) == false, "You are already in the game. Wait for the next one");
        require(ctx.value >= self.minBet, "Your bet is less then minimum");

        // If User is a good boy, get bit make him a Player
        let player: Player = Player {address: ctx.sender, bit: ctx.value};
        self.lockedBalance = self.lockedBalance + ctx.value;

        // Add player to the game
        currGame.currPlayerIdx = currGame.currPlayerIdx + 1;
        currGame.players.set(currGame.currPlayerIdx, player);
        currGame.timestamp = now();

        if (currGame.currPlayerIdx < self.maxPlayers) {
            self.games.set(self.currGameIdx, currGame);

        } else {
            // End the game if there are enough players
            // Do lottery
            nativeRandomizeLt();
            currGame.winPlayerIdx = random(0, currGame.currPlayerIdx + 1);
            self.games.set(self.currGameIdx, currGame);

            // Awarding the winner
            let winner: Player? = currGame.players.get(currGame.winPlayerIdx);
            if (winner != null) {
                self.rewardTheWinner(winner!!);
            }

            // Create new empty game
            self.currGameIdx = self.currGameIdx + 1;
            let players: map<Int, Player> = emptyMap();
            self.games.set(self.currGameIdx, Game{
                players: players,
                currPlayerIdx: -1,
                winPlayerIdx: -1,
                timestamp: now()
            });
        }
    }

    fun isUserInGame(address: Address, game: Game): Bool {
        let i: Int = 0;
        while (i < game.currPlayerIdx + 1) {
            if ((game.players.get(i)!!).address == address) {
                return true;
            }
            i = i + 1;
        }
        return false;
    }

    fun rewardTheWinner(player: Player) {

    }

    get fun balance(): String {
		self.requireOwner();
		return (myBalance() - self.lockedBalance).toCoinsString();
    }

    get fun totalGames(): Int {
        return self.currGameIdx;
    }

    get fun totalRevenue(): Int {
        return self.totalRevenue;
    }

}