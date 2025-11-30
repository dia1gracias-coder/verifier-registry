import "@stdlib/gas-payments"
import "./storage"

tolk 1.0

struct (0x7e8764ef) IncreaseCounter {
    queryId: uint64
    increaseBy: uint32
    increaseBy2: uint32
    increaseBy3: uint32
}

struct (0x3a752f06) ResetCounter {
    queryId: int32
    data: ResetData
}

struct ResetData {
    foo: int32
    bar: NestedData
}

struct NestedData {
    foo: int32
}

struct (0x2) Bounce {}
struct (0x3) Destroy {
    value: int32 = 10
}

type AllowedMessage = IncreaseCounter | ResetCounter

const OH_NO = 100

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessage.fromSlice(in.body);

    match (msg) {
        IncreaseCounter => {
            var storage = lazy Storage.load();
            storage.counter += msg.increaseBy;
            assert (storage.counter < 10) throw OH_NO;
            storage.save();

            // // send Destroy to other
            // val outMsg = createMessage({
            //     dest: address("EQCh0bXhBaHt0qnGl6GJSHBzbvXn2qCyGTbZYmzCWW2CI2MX"),
            //     body: Destroy {},
            //     bounce: false,
            //     value: ton("0.2"),
            // });
            // outMsg.send(SEND_MODE_REGULAR);

            // val logMsg = createExternalLogMessage({
            //     body: Destroy {},
            //     dest: {
            //         topic: 100
            //     },
            // });
            // logMsg.send(SEND_MODE_REGULAR);
        }

        ResetCounter => {
            var storage = lazy Storage.load();
            storage.counter = 0;
            storage.save();

            // send Bounce to other
            // val msg = createMessage({
            //     dest: address("EQCh0bXhBaHt0qnGl6GJSHBzbvXn2qCyGTbZYmzCWW2CI2MX"),
            //     body: Bounce {},
            //     bounce: true,
            //     value: ton("0.1"),
            // });
            // msg.send(SEND_MODE_REGULAR);
        }

        else => {
            assert (in.body.isEmpty()) throw 0xFFFF;
        }
    }
}

fun onBouncedMessage(in: InMessageBounced) {
    val msg = lazy Bounce.fromSlice(in.bouncedBody.skipBouncedPrefix());

    match (msg) {
        Bounce => {
            var storage = lazy Storage.load();
            storage.counter = 9999;
            storage.save();
        }
        else => {}
    }
}

fun onExternalMessage(inMsg: slice) {
    if (inMsg.remainingBitsCount() == 0) {
        return;
    }

    acceptExternalMessage();

    val msg = lazy IncreaseCounter.fromSlice(inMsg);
    match (msg) {
        IncreaseCounter => {
            var storage = lazy Storage.load();
            storage.counter += msg.increaseBy;
            storage.save();
        },
        else => {
            throw 0xFFFF;
        },
    }
}

get fun currentCounter(): int {
    val storage = lazy Storage.load();
    return storage.counter;
}

get fun initialId(): int {
    val storage = lazy Storage.load();
    return storage.id;
}
