import "types"
// import "lib/profiler/profiler"


type AllowedMessage = IncreaseCounter | ResetCounter

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessage.fromSlice(in.body);
    // debug.print(in.body);

    match (msg) {
        IncreaseCounter => {
            // profiler.begin("increase");
            var storage = lazy Storage.load();
            storage.counter += msg.increaseBy;
            // profiler.begin("increase save");
            storage.save();
            // profiler.end("increase save");
            // profiler.end("increase");
            // debug.print(msg.increaseBy + 1);
        }
        ResetCounter => {
            var storage = lazy Storage.load();
            storage.counter = 0;
            storage.save();
        }
        else => {
            assert (in.body.isEmpty()) throw 0xFF7;
        }
    }
}

fun onBouncedMessage(in: InMessageBounced) {}

get fun currentCounter(): int {
    val storage = lazy Storage.load();
    return storage.counter;
}

get fun currentCounter2(arg: int): int {
    return arg
}
