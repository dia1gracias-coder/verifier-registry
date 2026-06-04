enum Errors {
    NotOwner = 100
    InvalidMessage = 0xFFFF
}

const PRODUCE_ERROR: uint8 = 1
const NOT_PRODUCE_ERROR: uint8 = 0

struct Storage {
    owner: address
    id: uint64
    lastBouncedBody: cell
    childContractCode: cell
}

fun Storage.load(): Storage {
    return Storage.fromCell(contract.getData());
}

fun Storage.save(self) {
    contract.setData(self.toCell());
}

struct (0x2ce05111) ChangeOwner {
    newOwner: address
}

struct (0x4d794d73) MyMessage {
    seqno: uint256
    salt: uint256
    traceId: uint256
    extraData: cell
    produceError: bool
}

struct (0x6465706c) DeployChild {}

struct (0x74627374) TestBounce {
    produceError: bool
    sendWithoutStateInit: bool
}

struct ChildStorage {
    parent: address
    seqno: uint256
}
