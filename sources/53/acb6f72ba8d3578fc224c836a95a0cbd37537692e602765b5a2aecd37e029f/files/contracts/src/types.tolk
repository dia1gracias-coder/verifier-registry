enum Errors {
    // NotOwner = 100
    // InvalidMessage = 0xFFFF
    NotAuthorized = 100
    InvalidMessage = 101
    InvalidPrincipal = 102
    InvalidPeriod = 103
}

/* struct Storage {
    owner: address
    calculations: array<CalculationRecord>
}

fun Storage.load(): Storage {
    return Storage.fromCell(contract.getData());
}
//could be mutate self
fun Storage.save(self) {
    contract.setData(self.toCell());
} */

/* // In your contract file or types file
get fun owner(): address {
    val storage = lazy Storage.load();
    return storage.owner;
}*/

struct (0x2ce05111) ChangeOwner {
    newOwner: address
}
