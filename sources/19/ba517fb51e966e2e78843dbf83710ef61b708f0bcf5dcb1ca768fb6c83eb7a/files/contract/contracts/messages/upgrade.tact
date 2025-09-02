// Upgrade contract code
message Upgrade {
    code: Cell;
}

struct UpgradedEvent {
    codeHash: Int as uint256;
}