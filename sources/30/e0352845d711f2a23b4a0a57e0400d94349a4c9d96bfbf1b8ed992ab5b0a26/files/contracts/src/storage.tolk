import "common"
import "messages"

struct Storage {
    ownerAddress: address
    editors: map<address, ()>
    subdomains: map<uint256, SubdomainState>
}

struct SubdomainState {
    name: Name
    records: map<uint256, cell>
}

struct Record {
    name: Name
    category: Category
    value: cell
}

fun Storage.load(): Storage {
    return Storage.fromCell(contract.getData());
}

fun Storage.save(self) {
    contract.setData(self.toCell());
}

fun Storage.isOwner(self, sender: address): bool {
    return sender == self.ownerAddress;
}

fun Storage.isEditor(self, sender: address): bool {
    return self.editors.exists(sender);
}

fun Storage.canUpdateRecords(self, sender: address): bool {
    return self.isOwner(sender) || self.isEditor(sender);
}

fun Storage.addEditor(mutate self, editor: address) {
    self.editors.set(editor, ());
}

fun Storage.removeEditor(mutate self, editor: address) {
    self.editors.delete(editor);
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
    var i = 0;
    repeat (changes.size()) {
        val nameChanges = changes.get(i);
        val nameHash = nameChanges.name.beginParse().hash();
        val existingState = self.subdomains.get(nameHash);
        var nameState = existingState.isFound
            ? existingState.loadValue()
            : SubdomainState {
                name: nameChanges.name,
                records: [],
            };
        nameState.processChanges(nameChanges);
        self.subdomains.set(nameHash, nameState);
        i += 1;
    }
}
