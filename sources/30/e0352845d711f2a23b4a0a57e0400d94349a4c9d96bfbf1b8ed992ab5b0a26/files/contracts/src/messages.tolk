import "common"

struct (0x632844dc) UpdateRecords {
    prune: bool
    changes: array<UpdateNameRecords>
}

struct UpdateNameRecords {
    name: string
    prune: bool
    changes: map<uint256, cell?>
}

struct UpdateRecord {
    name: Name
    category: Category
    newValue: cell?
}

struct (0x2e8c24a1) AddEditor {
    editor: address
}

struct (0x7b5cf2f8) RemoveEditor {
    editor: address
}

// Excesses is recommended opcode for gas excesses
// https://docs.ton.org/contract-dev/techniques/security#return-gas-excesses-carefully
struct (0xd53276db) Excesses {}
