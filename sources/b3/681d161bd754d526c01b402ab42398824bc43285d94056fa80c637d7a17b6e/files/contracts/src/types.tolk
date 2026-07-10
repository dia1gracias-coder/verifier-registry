enum Errors {
    NotOwner = 100
    SingerUnderflow = 0x1001
    InvalidMessage = 0xFFFF
}

struct Storage {
    id: uint32
    owner: address
    singer: uint32
}

fun Storage.load(): Storage {
    return Storage.fromCell(contract.getData());
}

fun Storage.save(self) {
    contract.setData(self.toCell());
}

struct (0x7e8764ef) IncreaseSinger {
    increaseBy: uint32
}

struct (0x283b4c3f) DecreaseSinger {
    decreaseBy: uint32
}

struct (0x3a752f06) ResetSinger {}
