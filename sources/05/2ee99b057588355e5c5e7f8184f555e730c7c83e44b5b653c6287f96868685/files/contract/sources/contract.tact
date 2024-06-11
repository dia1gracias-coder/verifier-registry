import "@stdlib/deploy";
import "@stdlib/ownable";

struct Data {
    total_bet_a: Int as uint32;
    total_bet_b: Int as uint32;
    bets_a: Cell;
    bets_b: Cell;
    finalized: Bool;
    admin: Slice;
}

contract TestContract {
    data: Data;
    init() {
        self.data = Data{
            total_bet_a: 0,
            total_bet_b: 0,
            bets_a: emptyCell(),
            bets_b: emptyCell(),
            finalized: false,
            admin: beginCell().endCell().beginParse()
        };
    }

fun handle_bet(bet_on_a: Bool, bet_amount: Int) {
    require(!self.data.finalized, "Betting is over");

         if (bet_on_a) {
            // Update total_bet_a
            self.data.total_bet_a += bet_amount;
            // Store the bet in bets_a
            let bets_a_builder: Builder = beginCell()
                .storeSlice(self.data.bets_a.beginParse())
                .storeUint(bet_amount, 32);
            self.data.bets_a = bets_a_builder.endCell();
        } else {
            // Update total_bet_b
            self.data.total_bet_b += bet_amount;
            // Store the bet in bets_b
            let bets_b_builder: Builder = beginCell()
                .storeSlice(self.data.bets_b.beginParse())
                .storeUint(bet_amount, 32);
            self.data.bets_b = bets_b_builder.endCell();
        }

}

 get fun testValue(): Int {
        return 77;
    }

receive(msg: Slice) {
    let msg_body: Slice = msg;
    let bet_type: Int = msg_body.loadUint(1); 
    let bet_amount: Int = msg_body.loadCoins(); 

    let bet_on_a: Bool = (bet_type == 0);

    self.handle_bet(bet_on_a, bet_amount);
}


}