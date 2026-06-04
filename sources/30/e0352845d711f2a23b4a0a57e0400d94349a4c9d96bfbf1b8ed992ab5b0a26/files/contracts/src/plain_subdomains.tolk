import "common"
import "messages"
import "storage"

contract plain_subdomains {
    storage: Storage
    incomingMessages: AllowedMessage
}

type AllowedMessage =
    | UpdateRecords
    | AddEditor
    | RemoveEditor

const DNS_NEXT_RESOLVER_CATEGORY = "dns_next_resolver".sha256()

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessage.fromSlice(in.body);

    match (msg) {
        UpdateRecords => {
            var storage = lazy Storage.load();
            assert (storage.canUpdateRecords(in.senderAddress)) throw Errors.AccessDenied;

            storage.processUpdate(msg);
            storage.save();

            sendExcesses(in.senderAddress);
        }
        AddEditor => {
            var storage = lazy Storage.load();
            assert (storage.isOwner(in.senderAddress)) throw Errors.AccessDenied;

            storage.addEditor(msg.editor);
            storage.save();

            sendExcesses(in.senderAddress);
        }
        RemoveEditor => {
            var storage = lazy Storage.load();
            assert (storage.isOwner(in.senderAddress)) throw Errors.AccessDenied;

            storage.removeEditor(msg.editor);
            storage.save();

            sendExcesses(in.senderAddress);
        }
        else => {
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
        }
    }
}

fun onBouncedMessage(_in: InMessageBounced) {}

fun sendExcesses(dest: address) {
    val excessesMsg = createMessage({
        bounce: BounceMode.NoBounce,
        value: ton("0"),
        dest,
        body: Excesses {},
    });
    excessesMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS);
}

get fun dnsresolve(subdomain: slice, category: int): (int, cell?) {
    val storage = lazy Storage.load();
    val originalBits = subdomain.remainingBitsCount();
    var skippedBits = 0;
    if (originalBits >= 8 && subdomain.preloadUint(8) == 0) {
        subdomain.skipBits(8);
        skippedBits = 8;
    }
    val domainBits = subdomain.remainingBitsCount();
    val nameHash = subdomain.hash();
    val data = storage.subdomains.get(nameHash);
    if (data.isFound) {
        val data = data.loadValue();
        if (category == 0) {
            return (originalBits, data.records.toLowLevelDict());
        }
        val result = data.records.get(category);
        if (result.isFound) {
            return (originalBits, result.loadValue());
        }
    }

    // Names are reversed DNS labels separated by zero bytes: level0\0level1\0level2.
    var prefixBits = findPreviousSegmentPrefixBits(subdomain, domainBits);
    while (prefixBits > 0) {
        val prefix = subdomain.getFirstBits(prefixBits);
        val prefixData = storage.subdomains.get(prefix.hash());
        if (prefixData.isFound) {
            val prefixState = prefixData.loadValue();
            val nextResolver = prefixState.records.get(DNS_NEXT_RESOLVER_CATEGORY);
            if (nextResolver.isFound) {
                return (skippedBits + prefixBits, nextResolver.loadValue());
            }
        }
        prefixBits = findPreviousSegmentPrefixBits(subdomain, prefixBits);
    }
    return (0, null);
}

fun findPreviousSegmentPrefixBits(subdomain: slice, limitBits: int): int {
    var cursor = subdomain;
    var offset = 0;
    var prefixBits = 0;
    while (offset + 8 < limitBits) {
        if (cursor.preloadUint(8) == 0) {
            prefixBits = offset;
        }
        cursor.skipBits(8);
        offset += 8;
    }
    return prefixBits;
}

get fun dnssubdomains(): array<Record> {
    val storage = lazy Storage.load();
    var records: array<Record> = [];
    var subdomain = storage.subdomains.findFirst();
    while (subdomain.isFound) {
        val state = subdomain.loadValue();
        var record = state.records.findFirst();
        while (record.isFound) {
            records.push(Record {
                name: state.name,
                category: record.getKey(),
                value: record.loadValue(),
            });
            record = state.records.iterateNext(record);
        }
        subdomain = storage.subdomains.iterateNext(subdomain);
    }
    return records;
}

get fun get_owner(): address {
    val storage = lazy Storage.load();
    return storage.ownerAddress;
}

get fun get_editors(): array<address> {
    val storage = lazy Storage.load();
    var editors: array<address> = [];
    var editor = storage.editors.findFirst();
    while (editor.isFound) {
        editors.push(editor.getKey());
        editor = storage.editors.iterateNext(editor);
    }
    return editors;
}
