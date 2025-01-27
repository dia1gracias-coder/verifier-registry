import "@stdlib/deploy";

struct TokenInfo {
    ticker: String;
    decimals: Int as uint8;
}

struct UserData {
    name: String;
    wallet: Address;
}

message Replace {
    items: map<Int, UserData>;
}
message Withdraw {
    amount: Int as coins;
}
contract TONLAUNCHPAD with Deployable {

    deployer: Address;
    userData: map<Int, UserData>;
    userCount: Int as uint8;

    init() {
        self.deployer = sender();
        self.userData = emptyMap(); // Initialize as an empty array
        self.userCount = 0; // Initialize user count
    }

    // This contract method can be called from within this contract and access its variables
    fun onlyDeployer() {
        require(sender() == self.deployer, "Only the deployer is permitted here");
    }

    receive("priviliged") {
        self.onlyDeployer();
    }

    // This contract method returns multiple return values using a struct
    fun getInfo(index: Int): TokenInfo {
        if (index == 1) {
            return TokenInfo{ticker: "TON", decimals: 9};
        }
        if (index == 2) {
            return TokenInfo{ticker: "ETH", decimals: 18};
        }
        return TokenInfo{ticker: "unknown", decimals: 0};
    }

    // Save user data to the array
    fun participate(name: String) {
        let user: UserData = UserData{name: name, wallet: sender()};
      
        self.userCount = self.userCount + 1; // Increment user count for next user
      
    }

    receive("best L1") {
        let best: TokenInfo = self.getInfo(1);
        self.reply(best.ticker.asComment());
    }
  receive("withdraw all") {
        require(sender() == self.deployer, "Only deployer is allowed to withdraw");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors
        });
    }
    receive(msg: String) {
       self.participate(msg); // Pass the actual name variable
}
  get fun balance(): String {
        return myBalance().toCoinsString();
    }
  
}
