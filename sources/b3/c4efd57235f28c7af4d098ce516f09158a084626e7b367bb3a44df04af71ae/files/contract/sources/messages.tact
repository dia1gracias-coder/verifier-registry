// Message representing the assignment of ownership for an NFT item.
message(0x05138d91) OwnershipAssigned {
    queryId: Int as uint64;        // Unique identifier for the ownership assignment query.
    previousOwner: Address;       // Address of the previous owner of the NFT item.
    forwardPayload: Cell?;        // Optional payload containing additional data for the recipient.
}

// Message for transferring ownership of an NFT item.
message(0x5fcc3d14) NFTTransfer {
    queryId: Int as uint64;           // Unique identifier for the transfer query.
    newOwner: Address;               // Address of the new owner of the NFT item.
    responseDestination: Address;    // Address to send a response confirming the transfer and remaining funds.
    customPayload: Cell? = null;     // Optional custom data, typically null.
    forwardAmount: Int as coins;     // Amount (in nanotons) to be forwarded to the new owner.
    forwardPayload: Slice as remaining; // Optional custom data to be sent to the new owner.
}

// Message for setting up the reward amount in the CollectorContract.
message SetupMessage {
    rewardAmount: Int as uint32;     // The reward amount to be paid to the previous NFT owner.
}
