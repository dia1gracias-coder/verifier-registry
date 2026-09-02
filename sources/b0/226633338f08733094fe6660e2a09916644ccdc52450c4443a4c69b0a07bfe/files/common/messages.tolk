tolk 1.4.1

// ---- Standard TEP-74 messages ----

struct (0x0f8a7ea5) JettonTransfer {
    queryId: uint64;
    jettonAmount: coins;
    transferRecipient: address;     // destination owner
    sendExcessesTo: address;        // response_destination
    customPayload: cell?;           // (Maybe ^Cell)
    forwardTonAmount: coins;
    forwardPayload: RemainingBitsAndRefs;   // (Either Cell ^Cell)
}

struct (0x178d4519) InternalTransferStep {
    queryId: uint64;
    jettonAmount: coins;
    transferInitiator: address;     // 'from' owner (minter address for mints)
    sendExcessesTo: address;        // response_destination
    forwardTonAmount: coins;
    forwardPayload: RemainingBitsAndRefs;
}

struct (0x7362d09c) TransferNotificationForRecipient {
    queryId: uint64;
    jettonAmount: coins;
    transferInitiator: address;     // 'sender'
    forwardPayload: RemainingBitsAndRefs;
}

struct (0xd53276db) ReturnExcessesBack {
    queryId: uint64;
}

struct (0x595f07bc) JettonBurn {
    queryId: uint64;
    jettonAmount: coins;
    sendExcessesTo: address;        // response_destination
    customPayload: cell?;
}

struct (0x7bdd97de) BurnNotificationForMinter {
    queryId: uint64;
    jettonAmount: coins;
    burnInitiator: address;         // 'sender' owner
    sendExcessesTo: address;        // response_destination
}

// ---- Custom permissioning / admin messages ----

struct (0x74630001) MintRequest {
    queryId: uint64;
    toOwner: address;
    jettonAmount: coins;
    forwardTonAmount: coins;
}

struct (0x74630002) ActivateWallet {
    queryId: uint64;
    ownerAddress: address;
}

struct (0x74630003) BlockWallet {
    queryId: uint64;
    ownerAddress: address;
}

struct (0x74630004) SetWalletStatus {
    queryId: uint64;
    newStatus: uint8;
}

struct (0x74630005) ChangeAdmin {
    queryId: uint64;
    newAdmin: address;
}

struct (0x74630006) ChangeContent {
    queryId: uint64;
    newContent: cell;
}

struct (0x74630007) SetMintingEnabled {
    queryId: uint64;
    enabled: bool;
}

struct (0x74630008) SetGlobalPause {
    queryId: uint64;
    isPaused: bool;
}

struct (0x74630009) ChangeTreasuryOwner {
    queryId: uint64;
    newTreasuryOwner: address;
}
