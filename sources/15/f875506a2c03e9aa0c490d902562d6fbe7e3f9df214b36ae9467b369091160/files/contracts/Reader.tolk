import "types"

contract Reader {
    author: "Acton User"
    version: "1.0.0"
    description: "Simple reader contract with owner-controlled updates"
    storage: Storage
    incomingMessages: AllowedMessage
}

type AllowedMessage =
    | IncreaseReader
    | DecreaseReader
    | ResetReader

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessage.fromSlice(in.body);

    match (msg) {
        IncreaseReader => {
            var storage = lazy Storage.load();
            assert (storage.owner == in.senderAddress) throw Errors.NotOwner;

            storage.reader += msg.increaseBy;
            storage.save();
        }
        DecreaseReader => {
            var storage = lazy Storage.load();
            assert (storage.owner == in.senderAddress) throw Errors.NotOwner;
            assert (storage.reader >= msg.decreaseBy) throw Errors.ReaderUnderflow;

            storage.reader -= msg.decreaseBy;
            storage.save();
        }
        ResetReader => {
            var storage = lazy Storage.load();
            assert (storage.owner == in.senderAddress) throw Errors.NotOwner;

            storage.reader = 0;
            storage.save();
        }
        else => {
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
        }
    }
}

fun onBouncedMessage(_in: InMessageBounced) {}

get fun currentReader(): int {
    val storage = lazy Storage.load();

    return storage.reader;
}

get fun owner(): address {
    val storage = lazy Storage.load();

    return storage.owner;
}
