tolk 1.1.0

struct Storage {
  owner: address;
  lottery_owner: address;
  executed: bool;
  win_number: uint64;
  tickets_count: uint64;
}

fun Storage.load() {
    return Storage.fromCell(contract.getData())
}

fun Storage.save(self) {
    contract.setData(self.toCell())
}

struct (0x000001) ChangeTicketsCount {
    queryId: uint64;  
    count: uint64;
}

struct (0x000002) ChangeLotteryOwner {
    queryId: uint64; 
    lottery_owner: address;
}
type AllowedMessage = ChangeTicketsCount | ChangeLotteryOwner


fun onInternalMessage(in: InMessage) {
  var storage = lazy Storage.load();
  if (in.body.isEmpty() && in.senderAddress == storage.lottery_owner) { 
      assert(!storage.executed) throw 1001; 
      assert(storage.tickets_count != 0) throw 1002; 
      random.initialize();
      do {
        storage.win_number = random.range(storage.tickets_count);
      }  while (storage.win_number == 0);
      storage.executed = true;
      storage.save();
      
  }
  else {
    assert(in.senderAddress == storage.lottery_owner) throw 1003;
    val msg = lazy AllowedMessage.fromSlice(in.body);

    match (msg) {
        ChangeTicketsCount => {
            storage.tickets_count = msg.count;
            storage.save();
        }

        ChangeLotteryOwner => {
            storage.lottery_owner = msg.lottery_owner;
            storage.save();
        }

        else => {
          throw 0xFFFF
        }
    }
  }
}  
    
get fun get_win_number(): int {
  val storage = lazy Storage.load();
  return storage.win_number;
}

get fun get_executed(): bool {
  val storage = lazy Storage.load();
  return storage.executed;
}

get fun get_tickets_count(): int {
  val storage = lazy Storage.load();
  return storage.tickets_count;
}

get fun get_owner(): address {
  val storage = lazy Storage.load();
  return storage.owner;
}

get fun get_lottery_owner(): address {
  val storage = lazy Storage.load();
  return storage.lottery_owner;
}
