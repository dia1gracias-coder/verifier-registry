tolk 1.2

// Keep WINNERS_COUNT <= 31
const WINNERS_COUNT = 30;
const DELAY_SECONDS = 60;

// ============================================================
//  Messages
// ============================================================

struct (0x00000001) SetParticipants {
    totalParticipants: uint32
}

struct (0x00000002) TriggerRandom {}

type RaffleMessage = SetParticipants | TriggerRandom

// ============================================================
//  Storage
// ============================================================

struct Storage {
    owner: address
    totalParticipants: uint32
    triggerTime: uint32
    isFinalized: bool
    winnersCell: cell?
}

fun Storage.load() {
    return Storage.fromCell(contract.getData())
}

fun Storage.save(self) {
    contract.setData(self.toCell())
}

// ============================================================
//  Winners helpers
// ============================================================

// NOTE: 32-bit IDs are packed into a single cell.
// Keep WINNERS_COUNT <= 31 (31 * 32 = 992 bits, max 1023 per cell).
fun packWinners(winners: tuple): cell {
    var b = beginCell();
    var i = 0;
    while (i < WINNERS_COUNT) {
        b.storeUint(winners.get<int>(i), 32);
        i += 1;
    }
    return b.endCell()
}

fun unpackWinners(c: cell): tuple {
    var s = c.beginParse();
    var winners = createEmptyTuple();
    repeat (WINNERS_COUNT) {
        winners.push(s.loadUint(32));
    }
    return winners
}

// ============================================================
//  Random selection — partial Fisher-Yates with dict
// ============================================================

fun generateUniqueWinners(total: int): tuple {
    random.initialize();

    var swaps: map<uint32, uint32> = createEmptyMap();
    var winners = createEmptyTuple();

    var i = 0;
    while (i < WINNERS_COUNT) {
        val r = i + random.range(total - i);

        // Virtual array: swaps stores only modified positions
        // Default value at any position p is p itself
        val lookupR = swaps.get(r);
        var valR: int;
        if (lookupR.isFound) {
            valR = lookupR.loadValue() as int;
        } else {
            valR = r;
        }

        val lookupI = swaps.get(i);
        var valI: int;
        if (lookupI.isFound) {
            valI = lookupI.loadValue() as int;
        } else {
            valI = i;
        }

        // Swap: move value from i to position r
        swaps.set(r, valI);

        // IDs are 1-based
        winners.push(valR + 1);
        i += 1;
    }

    return winners
}

// ============================================================
//  Main handler
// ============================================================

fun onInternalMessage(in: InMessage) {
    if (in.body.isEmpty()) {
        return;
    }

    val msg = lazy RaffleMessage.fromSlice(in.body);

    match (msg) {
        SetParticipants => {
            var storage = lazy Storage.load();

            assert (in.senderAddress == storage.owner) throw 401;
            assert (!storage.isFinalized) throw 402;

            storage.totalParticipants = msg.totalParticipants;
            storage.triggerTime = (blockchain.now() + DELAY_SECONDS);
            storage.save();
        }

        TriggerRandom => {
            var storage = lazy Storage.load();

            assert (in.senderAddress == storage.owner) throw 401;
            assert (!storage.isFinalized) throw 402;
            assert (storage.totalParticipants > 0) throw 403;
            assert (blockchain.now() >= storage.triggerTime) throw 404;
            assert (storage.totalParticipants >= WINNERS_COUNT) throw 405;

            val winners = generateUniqueWinners(storage.totalParticipants);

            storage.isFinalized = true;
            storage.winnersCell = packWinners(winners);
            storage.save();
        }

        else => {
            throw 0xFFFF;
        }
    }
}

// ============================================================
//  Getters
// ============================================================

get fun getState(): (int, int, bool) {
    val storage = lazy Storage.load();
    return (
        storage.totalParticipants,
        storage.triggerTime,
        storage.isFinalized,
    )
}

get fun getTimeLeft(): int {
    val storage = lazy Storage.load();
    if (storage.triggerTime > blockchain.now()) {
        return storage.triggerTime - blockchain.now()
    }
    return 0
}

get fun getWinners(): tuple {
    val storage = lazy Storage.load();
    assert (storage.isFinalized) throw 500;
    return unpackWinners(storage.winnersCell!)
}

get fun getWinnerAt(index: int): int {
    val storage = lazy Storage.load();
    assert (storage.isFinalized) throw 500;
    assert (index >= 0) throw 501;
    assert (index < WINNERS_COUNT) throw 502;

    val winners = unpackWinners(storage.winnersCell!);
    return winners.get(index)
}
