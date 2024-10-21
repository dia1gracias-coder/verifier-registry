import "@stdlib/deploy";
import "@stdlib/ownable";

// Constants
const MAX_BET: Int = 10 * 1000000000; // 10 TON
const FEE_PERCENT: Int = 5 * 1000; // 5%

// Main contract
contract DiceGame with Deployable, Ownable {
    owner: Address;
    admin: map<Address, Bool>;
    publicKey: Int?;
    feePercent: Int;
    maxBet: Int;

    init(adminWallet: Address, publicKey: Int) {
        self.owner = sender();
        self.admin.set(adminWallet, true);
        self.publicKey = publicKey;
        self.feePercent = FEE_PERCENT;
        self.maxBet = MAX_BET;
    }

    // =============== Private Methods ============== //

    fun requireOwnerOrAdmin() {
        require(sender() == self.owner || self.isAdmin(sender()), "Only the owner or admin can call this function");
    }

    fun setAdmin(admin: Address, active: Bool) {
        self.requireOwnerOrAdmin();
        if (active == false) {
            self.admin.set(admin, null);
        } else {
            self.admin.set(admin, true);
        }
    }

    fun setFeePercent(percent: Int) {
        self.requireOwnerOrAdmin();
        require(percent >= 0 && percent <= 100000, "Fee percent must be between 0 and 1000");
        self.feePercent = percent;
    }

    fun setMaxBet(amount: Int) {
        self.requireOwnerOrAdmin();
        require(amount > 0, "Max bet amount must be greater than 0");
        self.maxBet = amount;
    }

    fun generateRandomNumber(): Int {
        return random(1, 7); // Random number between 1 and 6
    }

    get fun isAdmin(address: Address): Bool {
        return self.admin.get(address)!!;
    }

    get fun poolBalance(): Int {
        return myBalance();
    }

    get fun feePercent(): Int {
        return self.feePercent;
    }

    get fun maxBet(): Int {
        return self.maxBet;
    }

    // =============== Public Methods ============== //

    fun depositToPool() {
        require(context().value > 0, "Deposit amount must be greater than 0");
    }

    fun withdrawFromPool(amount: Int) {
        self.requireOwnerOrAdmin();
        require(amount > 0 && amount <= myBalance(), "Invalid withdraw amount");
        send(SendParameters{
            to: sender(),
            value: amount,
            mode: SendIgnoreErrors
        });
    }

    fun placeBet(choice: Bool) {
        let user: Address = sender();
        let betAmount: Int = context().value; // Lấy số TON được gửi kèm theo giao dịch
        require(betAmount > 0 && betAmount <= MAX_BET, "Bet amount must be between 1 and 10 TON");

        let randomNumber: Int = self.generateRandomNumber();
        let isEven: Bool = randomNumber % 2 == 0;
        let won: Bool = (isEven && choice) || (!isEven && !choice);

        if (won) {
            let winnings: Int = betAmount * 2;
            let fee: Int = winnings * self.feePercent / 100000;
            let payout: Int = winnings - fee;
            send(SendParameters{
                to: user,
                value: payout,
                mode: SendIgnoreErrors
            });
        }

        // Emit event to notify the user of the result
        emit(BetResultEvent{
            user,
            betAmount,
            choice,
            randomNumber,
            won
        }.toCell());
    }

    // =============== Receive Methods ============== //

    receive(msg: DepositToPool) {
        self.depositToPool();
    }

    receive(msg: WithdrawFromPool) {
        self.withdrawFromPool(msg.amount);
    }

    receive(msg: PlaceBet) {
        self.placeBet(msg.choice);
    }

    receive(msg: SetAdmin) {
        self.setAdmin(msg.admin, msg.active);
    }

    receive(msg: SetFeePercent) {
        self.setFeePercent(msg.percent);
    }

    receive(msg: SetMaxBet) {
        self.setMaxBet(msg.amount);
    }
}


    // =============== Structs and Messages ============== //

    struct Bet {
        amount: Int as uint32;
        choice: Bool;
        resolved: Bool;
        won: Bool;
    }

    message DepositToPool {}

    message WithdrawFromPool {
        amount: Int;
    }

    message PlaceBet {
        choice: Bool;
    }

    message SetAdmin {
        admin: Address;
        active: Bool;
    }

    message SetFeePercent {
        percent: Int;
    }

    message SetMaxBet {
        amount: Int;
    }

    // =============== Events ============== //

    message BetResultEvent {
        user: Address;
        betAmount: Int;
        choice: Bool;
        randomNumber: Int;
        won: Bool;
    }