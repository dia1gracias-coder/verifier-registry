//import "/home/suit/xlm/stellar/contracts/src/Stellar"
import "./Stellar"

enum Errors {
    //NotOwner = 100
    InvalidMessage = 0xFFFF
    NotAuthorized = 100
    //InvalidMessage = 101
    InvalidPrincipal = 102
    InvalidPeriod = 103
    StellarUnderflow = 0x1001
}

//STRUCT STORAGE
struct Storage {
    id: uint32
    owner: address
    calculations: array<CalculationRecord>
}

//FUN STORAGE LOAD
fun Storage.load(): Storage {
    return Storage.fromCell(contract.getData());
}

//could be mutate self
//FUN STORAGE SAVE

fun Storage.save(self) {
    contract.setData(self.toCell());
}

struct (0x2ce05111) ChangeOwner {
    newOwner: address
}
