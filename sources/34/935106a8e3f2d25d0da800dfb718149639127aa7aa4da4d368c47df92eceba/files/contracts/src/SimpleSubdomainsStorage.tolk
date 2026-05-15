import "types"

contract SimpleSubdomainsStorage {
    storage: Storage
    incomingMessages: AllowedMessage
}

type AllowedMessage =
    | UpdateRecords

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessage.fromSlice(in.body);

    match (msg) {
        UpdateRecords => {
            var storage = lazy Storage.load();
            assert (in.senderAddress == storage.ownerAddress) throw Errors.AccessDenied;

            storage.processUpdate(msg);
            storage.save();

            val excessesMsg = createMessage({
                bounce: BounceMode.NoBounce,
                value: ton("0"),
                dest: in.senderAddress,
                body: Excesses { queryId: 0 },
            });
            excessesMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS);
        }
        else => {
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
        }
    }
}

fun onBouncedMessage(_in: InMessageBounced) {}

get fun dnsresolve(subdomain: slice, category: int): (int, cell?) {
    val storage = lazy Storage.load();
    val domainBits = subdomain.remainingBitsCount();
    if (subdomain.preloadInt(8) == 0) {
        subdomain.skipBits(8);
    }
    val nameHash = subdomain.hash();
    val data = storage.subdomains.get(nameHash);
    if (data.isFound) {
        val data = data.loadValue();
        if (category == 0) {
            return (domainBits, data.records.toLowLevelDict());
        }
        val result = data.records.get(category);
        if (result.isFound) {
            return (domainBits, result.loadValue());
        }
    }
    return (0, null);
}

get fun getallrecords(): map<uint256, SubdomainState> {
    val storage = lazy Storage.load();
    return storage.subdomains;
}
