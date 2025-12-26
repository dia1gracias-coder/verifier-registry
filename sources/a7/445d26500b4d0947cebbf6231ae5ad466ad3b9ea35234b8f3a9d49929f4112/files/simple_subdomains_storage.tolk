struct (0x632844dc) UpdateRecords {
    prune: bool
    changes: map<int16, UpdateNameRecords>
}


const ERR_ACCESS_DENIED = 132;

type Name = cell;
type Category = uint256;

struct Storage {
    ownerAddress: address;
    subdomains: map<uint256, SubdomainState>
}

struct SubdomainState {
    name: Name
    records: map<Category, cell>
}

fun SubdomainState.processChanges(mutate self, update: UpdateNameRecords) {
    if (update.prune) {
        self.records = createEmptyMap();
    }
    var r = update.changes.findFirst();
    while (r.isFound) {
        val value = r.loadValue();
        if (value == null) {
            self.records.delete(r.getKey());
        } else {
            self.records.set(r.getKey(), value);
        }
        r = update.changes.iterateNext(r);
    }
}

fun Storage.load() {
    return Storage.fromCell(contract.getData())
}

fun Storage.save(self) {
    contract.setData(self.toCell())
}

struct UpdateRecord {
    name: Name
    category: Category
    newValue: cell?
}

struct Record {
    name: Name
    category: Category
    value: cell
}

struct UpdateNameRecords {
    name: Name
    prune: bool
    changes: map<Category, cell?>
}

fun Storage.processUpdate(mutate self, update: UpdateRecords) {
    if (update.prune) {
        self.subdomains = createEmptyMap();
    }
    val changes = update.changes;
    var r = changes.findFirst();
    while (r.isFound) {
        val nameChanges = r.loadValue();
        val nameHash = nameChanges.name.beginParse().hash();
        val existingState = self.subdomains.get(nameHash);
        var nameState = existingState.isFound ? existingState.loadValue() : SubdomainState {
            name: nameChanges.name,
            records: createEmptyMap(),
        };
        nameState.processChanges(nameChanges);
        self.subdomains.set(nameHash, nameState);
        r = changes.iterateNext(r);
    }
}

type AllowedMessage = UpdateRecords;

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessage.fromSlice(in.body);
    match (msg) {
        UpdateRecords => {
            var storage = lazy Storage.load();
            assert (in.senderAddress == storage.ownerAddress) throw ERR_ACCESS_DENIED;
            storage.processUpdate(msg);
            storage.save();
        }
        else => {
            assert (in.body.isEmpty()) throw 0xFFFF
        }
    }
}

get fun dnsresolve(subdomain: slice, category: int): (int, cell?) {
    val storage = lazy Storage.load();
    val domainBits = subdomain.remainingBitsCount();
    if (subdomain.preloadInt(8) == 0) {
        subdomain.skipBits(8)
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
