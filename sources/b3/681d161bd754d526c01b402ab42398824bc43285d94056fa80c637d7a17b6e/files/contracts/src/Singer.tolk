import "types"

contract Singer {
    author: "Acton User"
    version: "1.0.0"
    description: "Minimal singer contract with owner-controlled updates"
    storage: Storage
    incomingMessages: AllowedMessage
}

type AllowedMessage =
    | IncreaseSinger
    | DecreaseSinger
    | ResetSinger

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessage.fromSlice(in.body);

    match (msg) {
        IncreaseSinger => {
            var storage = lazy Storage.load();
            assert (storage.owner == in.senderAddress) throw Errors.NotOwner;

            storage.singer += msg.increaseBy;
            storage.save();
        }
        DecreaseSinger => {
            var storage = lazy Storage.load();
            assert (storage.owner == in.senderAddress) throw Errors.NotOwner;
            assert (storage.singer >= msg.decreaseBy) throw Errors.SingerUnderflow;

            storage.singer -= msg.decreaseBy;
            storage.save();
        }
        ResetSinger => {
            var storage = lazy Storage.load();
            assert (storage.owner == in.senderAddress) throw Errors.NotOwner;

            storage.singer = 0;
            storage.save();
        }
        else => {
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
        }
    }
}

fun onBouncedMessage(_in: InMessageBounced) {}

get fun currentSinger(): int {
    val storage = lazy Storage.load();

    return storage.singer;
}

get fun owner(): address {
    val storage = lazy Storage.load();

    return storage.owner;
}
