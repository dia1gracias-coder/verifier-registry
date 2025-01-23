import "@stdlib/deploy";

// Contract storage structure
struct GameData {
    bet_amount: Int as coins;
    game_state: Int as uint8;
    player1: Address;
    player2: Address;
    winner: Address;
    total_pot: Int as coins;
}

message PlaceBet {
    queryId: Int as uint64;
}

message EndGame {
    queryId: Int as uint64;
    winner_id: Int as uint8;
}

message Claim {
    queryId: Int as uint64;
}

// Constants
const STATE_WAITING: Int = 0;
const STATE_IN_PROGRESS: Int = 1;
const STATE_FINISHED: Int = 2;

contract QuizGame with Deployable {
    game: GameData;

    init(bet_amount: Int) {
        self.game = GameData{
            bet_amount: bet_amount,
            game_state: STATE_WAITING,
            player1: newAddress(0, 0),
            player2: newAddress(0, 0),
            winner: newAddress(0, 0),
            total_pot: 0
        };
    }

    // Place bet message handler
    receive(msg: PlaceBet) {
        require(self.game.game_state == STATE_WAITING, "Game is not in waiting state");
        require(context().value >= self.game.bet_amount, "Insufficient bet amount");

        if (self.game.player1 == newAddress(0, 0)) {
            self.game.player1 = sender();
            self.game.total_pot = self.game.total_pot + context().value;
        } else if (self.game.player2 == newAddress(0, 0)) {
            self.game.player2 = sender();
            self.game.total_pot = self.game.total_pot + context().value;
            self.game.game_state = STATE_IN_PROGRESS;
        } else {
            require(false, "Game is full");
        }
    }

    // End game message handler
    receive(msg: EndGame) {
        require(self.game.game_state == STATE_IN_PROGRESS, "Game is not in progress");
        require(sender() == self.game.player1 || sender() == self.game.player2, "Only players can end the game");
        
        if (msg.winner_id == 1) {
            self.game.winner = self.game.player1;
        } else {
            self.game.winner = self.game.player2;
        }
        
        self.game.game_state = STATE_FINISHED;
    }

    // Claim prize message handler
    receive(msg: Claim) {
        require(self.game.game_state == STATE_FINISHED, "Game is not finished");
        require(sender() == self.game.winner, "Only winner can claim");

        // Send the pot to the winner
        send(SendParameters{
            to: self.game.winner,
            value: self.game.total_pot,
            mode: SendRemainingValue
        });

        // Reset the game
        self.game.game_state = STATE_WAITING;
        self.game.player1 = newAddress(0, 0);
        self.game.player2 = newAddress(0, 0);
        self.game.winner = newAddress(0, 0);
        self.game.total_pot = 0;
    }

    // Getter methods
    get fun game_data(): GameData {
        return self.game;
    }

    get fun claimable_balance(addr: Address): Int {
        if (self.game.game_state != STATE_FINISHED) {
            return 0;
        }
        if (addr == self.game.winner) {
            return self.game.total_pot;
        }
        return 0;
    }
} 