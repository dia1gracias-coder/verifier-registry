import "@stdlib/deploy";
import "@stdlib/ownable";

// -------------------------------------------------------------
message BetResult {
    choice: Bool;
    win: Bool;
    timestamp: Int as uint32;
}

// struct BetChoice {
//     choice: Bool;
//     win: Bool;
//     timestamp: Int as uint32;
// }

struct BetChoices {
    m: map<Int as uint32, BetResult>;
    length: Int = 0;
}

const MaxArraySize: Int = 5_000;

// Extension mutation function for adding new entries to the end of the array

extends mutates fun append(self: BetChoices, bc: BetResult) {
    require((self.length + 1) <= MaxArraySize, "No space in the array left for new items!");
    self.m.set(self.length, bc); // set the entry (key-value pair)
    self.length += 1; // increase the length field
}

// Extension function for getting the value at the given index

extends mutates fun getIdx(self: BetChoices, idx: Int): BetResult {
    require(self.length > 0, "No items in the array!");
    require(idx >= 0, "Index of the item cannot be negative!");
    require(idx < self.length, "Index is out of array bounds!");
    // Note, that we use !! operator as we know for sure that the value would be there
    return self.m.get(idx)!!;
}

// Extension function for returning the last value

extends mutates fun get1Last(self: BetChoices): BetResult {
    require(self.length > 0, "No items in the array!");
    return self.m.get(self.length - 1)!!;
}

extends mutates fun getnLast(self: BetChoices, count: Int): map<Int as uint8, BetResult> {
    require(self.length > 0, "No items in the array!");
    let tmp : map<Int as uint8, BetResult> = emptyMap();
    let idx: Int = 0;
    while (idx < count) {
        tmp.set(idx,self.m.get(self.length - 1 - idx));
        idx+=1;
    }
    return tmp;
}

contract UserChoice with Deployable, Ownable {
    owner: Address;
    player: Address;
    betChoices: BetChoices;
    init(player: Address){
        self.owner = sender();
        self.betChoices = BetChoices{m: emptyMap(), length: 0};
        self.player = player;
    }

    receive(){
        dump("empty message received");
    }

    receive(msg: BetResult){
        self.requireOwner();
        
        self.betChoices.append(msg);
        let textWin: String = "";
        if (msg.win == true) {
            textWin = "You Win.";
            dump("Win");
        } else {
            textWin = "You Lost."; 
            dump("Lost");
        }
        send(SendParameters{to: sender(), value: 0, mode: SendRemainingValue | SendIgnoreErrors, body: textWin.asComment()});
    }

    get fun getBetChoices(): BetChoices {
        return self.betChoices;
    }

    get fun get1LastBetChoices(): BetResult {
        return self.betChoices.get1Last();
    }

    get fun getNLastBetChoices(count:Int): map<Int as uint8, BetResult> {
        return self.betChoices.getnLast(count);
    }

    get fun getPlayer(): String {
        return self.player.toString();
    }
}