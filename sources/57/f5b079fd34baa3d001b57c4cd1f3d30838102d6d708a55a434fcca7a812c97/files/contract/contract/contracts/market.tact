import "@stdlib/deploy";
import "./oracle_pool.tact"; // <--- ИМПОРТИРУЕМ ОБЩИЕ СООБЩЕНИЯ ОТСЮДА

message Bet { 
    side: Int; // 1 = YES, 2 = NO, 3 = TIE (Ничья)
}

message Resolve { 
    winner: Int; // 1 = YES, 2 = NO, 3 = TIE (Ничья)
}

message Extend { 
    new_deadline: Int as uint64; 
}

contract Market with Deployable {
    master: Address;
    service_wallet: Address;
    oracle_address: Address;
    oracle_pool_address: Address;
    deadline: Int as uint64;
    dispute_id: Int as uint64;

    status: Int = 0; // 0: Active, 1: Resolved, 2: Canceled
    extend_count: Int = 0;
    
    pool_yes: Int = 0;
    pool_no: Int = 0;
    pool_tie: Int = 0;
    winner: Int = 0; 

    bets_yes: map<Address, Int>;
    bets_no: map<Address, Int>;
    bets_tie: map<Address, Int>;

    init(master: Address, service: Address, oracle: Address, pool: Address, dl: Int, id: Int) {
        self.master = master;
        self.service_wallet = service;
        self.oracle_address = oracle;
        self.oracle_pool_address = pool;
        self.deadline = dl;
        self.dispute_id = id;
    }

    receive() {}

    receive(msg: Bet) {
        require(now() < self.deadline, "Time is up");
        require(self.status == 0, "Not active");
        let amount: Int = context().value;
        require(amount >= 100000000, "Min bet 0.1 TON");

        if (msg.side == 1) {
            let val: Int? = self.bets_yes.get(sender());
            let current_yes: Int = (val != null) ? val!! : 0;
            self.bets_yes.set(sender(), current_yes + amount);
            self.pool_yes = self.pool_yes + amount;
        } else if (msg.side == 2) {
            let val: Int? = self.bets_no.get(sender());
            let current_no: Int = (val != null) ? val!! : 0;
            self.bets_no.set(sender(), current_no + amount);
            self.pool_no = self.pool_no + amount;
        } else if (msg.side == 3) {
            let val: Int? = self.bets_tie.get(sender());
            let current_tie: Int = (val != null) ? val!! : 0;
            self.bets_tie.set(sender(), current_tie + amount);
            self.pool_tie = self.pool_tie + amount;
        }
    }

    receive(msg: Extend) {
        require(sender() == self.oracle_address, "Only oracle");
        require(self.extend_count < 3, "Max 3 extends");
        require(msg.new_deadline > self.deadline, "Must be longer");
        self.deadline = msg.new_deadline;
        self.extend_count = self.extend_count + 1;
    }

    receive(msg: Resolve) {
        require(sender() == self.oracle_address, "Only oracle");
        require(self.status == 0, "Already resolved");
        require(now() >= self.deadline, "Too early to resolve");
        require(msg.winner >= 1 && msg.winner <= 3, "Invalid winner code");

        if (msg.winner == 1) {
            require(self.pool_yes > 0, "Cannot resolve to option with 0 bets");
        } else if (msg.winner == 2) {
            require(self.pool_no > 0, "Cannot resolve to option with 0 bets");
        } else if (msg.winner == 3) {
            require(self.pool_tie > 0, "Cannot resolve to option with 0 bets");
        }

        self.status = 1;
        self.winner = msg.winner;

        let total: Int = self.pool_yes + self.pool_no + self.pool_tie;
        let fee: Int = total / 10; 

        send(SendParameters{
            to: self.oracle_pool_address, 
            value: fee * 5 / 10, 
            mode: 1,
            body: ProcessServiceFee{service_wallet: self.service_wallet}.toCell()
        }); 
        
        send(SendParameters{to: self.oracle_address, value: fee * 3 / 10, mode: 1}); 
        
        send(SendParameters{to: self.oracle_pool_address, value: fee * 2 / 10, mode: 1}); 
    }

    receive("cancel") {
        require(sender() == self.oracle_address, "Only oracle");
        require(self.status == 0, "Can only cancel active dispute");
        self.status = 2; 
    }

    receive("claim") {
        let amount_to_send: Int = 0;

        if (self.status == 1) { 
            let total_pool: Int = self.pool_yes + self.pool_no + self.pool_tie;
            if (self.winner == 1) {
                let val: Int? = self.bets_yes.get(sender());
                let bet_yes: Int = (val != null) ? val!! : 0;
                require(bet_yes > 0, "No winning bet");
                amount_to_send = (bet_yes * total_pool * 9 / 10) / self.pool_yes;
                self.bets_yes.set(sender(), 0);
            } else if (self.winner == 2) {
                let val: Int? = self.bets_no.get(sender());
                let bet_no: Int = (val != null) ? val!! : 0;
                require(bet_no > 0, "No winning bet");
                amount_to_send = (bet_no * total_pool * 9 / 10) / self.pool_no;
                self.bets_no.set(sender(), 0);
            } else if (self.winner == 3) {
                let val: Int? = self.bets_tie.get(sender());
                let bet_tie: Int = (val != null) ? val!! : 0;
                require(bet_tie > 0, "No winning bet");
                amount_to_send = (bet_tie * total_pool * 9 / 10) / self.pool_tie;
                self.bets_tie.set(sender(), 0);
            }
        } else if (self.status == 2) { 
            let v1: Int? = self.bets_yes.get(sender());
            let v2: Int? = self.bets_no.get(sender());
            let v3: Int? = self.bets_tie.get(sender());
            let b1: Int = (v1 != null) ? v1!! : 0;
            let b2: Int = (v2 != null) ? v2!! : 0;
            let b3: Int = (v3 != null) ? v3!! : 0;
            amount_to_send = b1 + b2 + b3;
            self.bets_yes.set(sender(), 0);
            self.bets_no.set(sender(), 0);
            self.bets_tie.set(sender(), 0);
        }

        require(amount_to_send > 0, "Nothing to claim");
        send(SendParameters{to: sender(), value: amount_to_send, mode: 64});
    }

    get fun pool_yes(): Int { return self.pool_yes; }
    get fun pool_no(): Int { return self.pool_no; }
    get fun pool_tie(): Int { return self.pool_tie; }
    get fun status(): Int { return self.status; }
    get fun winner(): Int { return self.winner; }
    get fun deadline(): Int { return self.deadline; }
}