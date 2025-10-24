tolk 1.1

// this struct defines storage layout of the contract
struct Storage {
    owner: address
    ticketsCount: uint64
    winnerCount: uint64
    winNumbers: map<uint64, uint64>
}

// load contract data from the persistent storage
fun Storage.load() {
    return Storage.fromCell(contract.getData())
}

// save contract data into the persistent storage
fun Storage.save(self) {
    contract.setData(self.toCell())
}

// the struct uses a 32-bit opcode prefix for message identification
struct (0x11111111) UpdateTicketsCount {
    queryId: uint64  // query id, typically included in messages
    ticketsCount: uint64
}

struct (0x33333333) UpdateWinnerCount {
    queryId: uint64  // query id, typically included in messages
    winnerCount: uint64
}
struct (0x22222222) Draw {
    queryId: uint64
}

// using unions to represent available messages
// this allows processing them with pattern matching
type AllowedMessage = UpdateTicketsCount | UpdateWinnerCount | Draw



// the main entrypoint: called when a contract receives an message from other contracts
fun onInternalMessage(in: InMessage) {
    // use `lazy` to defer loading fields until they are accessed
    val msg = lazy AllowedMessage.fromSlice(in.body);


    
    match (msg) {
        UpdateTicketsCount => {
            var storage = lazy Storage.load();
            if(in.senderAddress != storage.owner) {
        throw 101;
            }
            storage.ticketsCount = msg.ticketsCount;
            storage.save();
        
        }

        UpdateWinnerCount => {
            var storage = lazy Storage.load();
            if(in.senderAddress != storage.owner) {
        throw 101;
            }
            storage.winnerCount = msg.winnerCount;
            storage.save();
        
        }

        Draw => {
           var storage = lazy Storage.load();
            var winNumbersTemp: map<int64, int64> = createEmptyMap();
          
            random.initialize();
            var i = 1;
            var number = 0;
            
            repeat(storage.winnerCount) { 
                do {    
                    number = random.range(storage.ticketsCount);
                }
               
                while(winNumbersTemp.get(number).isFound || number == 0);
                winNumbersTemp.set(number, 1);
                storage.winNumbers.set(i, number); 
                i+=1;               
            }
            storage.save();
        }

        else => {
            // ignore empty messages, "wrong opcode" for others
            assert (in.body.isEmpty()) throw 0xFFFF
        }
    }
}

// a handler for bounced messages (not used here, may be ommited)
fun onBouncedMessage(in: InMessageBounced) {
}


get fun get_win_number(index:uint64): uint64 {
    val storage = lazy Storage.load();
    return storage.winNumbers.get(index).loadValue();
}

get fun get_win_numbers(): tuple {
    val storage = lazy Storage.load();
    var tup: tuple = createEmptyTuple();
    var i = 1;
    repeat(storage.winnerCount) {
        var number = storage.winNumbers.get(i);   
        tup.push(number.loadValue());    
        i+=1;
    }
    return tup;
}

get fun get_tickets_count(): uint64 {
    val storage = lazy Storage.load();
    return storage.ticketsCount;
}

get fun get_winner_count(): uint64 {
    val storage = lazy Storage.load();
    return storage.winnerCount;
}

get fun get_lottery_id(): uint32 {
  return 1;
}

get fun get_draw_id(): uint32 {
  return 2;
}
