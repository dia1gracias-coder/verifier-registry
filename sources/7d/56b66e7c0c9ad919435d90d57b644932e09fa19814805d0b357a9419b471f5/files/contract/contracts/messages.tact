message Propose {
    title: String;
    description: String;
    actionType: String;
    startTimestamp: Int as uint64;
    endTimestamp: Int as uint64;
    target: Address?;
    value: Int as coins;
}
message Vote {
    proposalId: Int as uint32;
    choice: Bool;
}
message ProposalLaunch {
    startTimestamp: Int as uint64;
    endTimestamp: Int as uint64;
    title: String;
    description: String;
    action: String; // "transfer" or "mint" for the moment
    target: Address?;
    value: Int as coins;
    executed: Bool;
}
message RouteProposalVote {
    proposalId: Int as uint32;
    sender: Address;
    choice: Bool;
}

message Unstake {
    amount: Int as coins;
}
message(0x7362d09c) JettonTransferNotification {
    // Unique identifier used to trace transactions across multiple contracts
    // Defaults to 0, which means we don't mark messages to trace their chains
    queryId: Int as uint64 = 0;
    // Amount of Jettons transferred
    amount: Int as coins;
    // Address of the sender of the Jettons
    sender: Address;
    // Optional custom payload
    forwardPayload: Slice as remaining;
}
message(0xf8a7ea5) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell? = null;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}