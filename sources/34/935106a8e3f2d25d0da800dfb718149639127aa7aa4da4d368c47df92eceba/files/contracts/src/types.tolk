enum Errors {
    AccessDenied = 132
    InvalidMessage = 0xFFFF
}

type Name = cell;
type Category = uint256;

struct Storage {
    ownerAddress: address
    subdomains: map<uint256, SubdomainState>
}

struct SubdomainState {
    name: Name
    records: map<uint256, cell>
}

struct (0x632844dc) UpdateRecords {
    prune: bool
    changes: map<int16, UpdateNameRecords>
}

struct UpdateNameRecords {
    name: Name
    prune: bool
    changes: map<uint256, cell?>
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

struct (0xd53276db) Excesses {
    queryId: uint64
}

fun Storage.load(): Storage {
    return Storage.fromCell(contract.getData());
}

fun Storage.save(self) {
    contract.setData(self.toCell());
}

fun SubdomainState.processChanges(mutate self, update: UpdateNameRecords) {
    if (update.prune) {
        self.records = [];
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

fun Storage.processUpdate(mutate self, update: UpdateRecords) {
    if (update.prune) {
        self.subdomains = [];
    }
    val changes = update.changes;
    var r = changes.findFirst();
    while (r.isFound) {
        val nameChanges = r.loadValue();
        val nameHash = nameChanges.name.beginParse().hash();
        val existingState = self.subdomains.get(nameHash);
        var nameState = existingState.isFound ? existingState.loadValue() : SubdomainState {
            name: nameChanges.name,
            records: [],
        };
        nameState.processChanges(nameChanges);
        self.subdomains.set(nameHash, nameState);
        r = changes.iterateNext(r);
    }
}
