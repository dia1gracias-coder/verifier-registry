/**
 * @dev This message updates Jetton's content (metadata).
 */
message UpdateContent {
    query_id: Int as uint64; // Query identifier
    content: Cell;           // Jetton's content (metadata)
}

/**
 * @dev This message confirms a successful update of Jetton's content.
 */
message UpdateContentOk {
    query_id: Int as uint64; // Query identifier
}

/**
 * @dev This message mints an amount of jettons to the new owner.
 */
message Mint {
    query_id: Int as uint64;       // Query identifier
    amount: Int as coins;          // Amount of minted jettons
    to: Address;                   // Address of the new owner of jettons
    response_destination: Address; // Address where to return excessive Toncoins
}

/**
 * @dev This message transfers jettons from the sender's TON wallet address to her
 * jetton wallet address.
 */
message(0xf8a7ea5) Transfer {
    query_id: Int as uint64;             // Query identifier
    amount: Int as coins;                // Amount of transferred jettons
    destination: Address;                // Address of the new owner of jettons
    response_destination: Address;       // Address where to return excessive Toncoins
    custom_payload: Cell?;               // Optional custom data for inner logic
    forward_ton_amount: Int as coins;    // Toncoins which should be send along with a transfer notification
    forward_payload: Slice as remaining; // Optional custom data sent to the recipient address
}

/**
 * @dev This message transfers jettons from the sender's jetton wallet address to the
 * recipient's jetton wallet address.
 */
message(0x178d4519) InternalTransfer {
    query_id: Int as uint64;             // Query identifier
    amount: Int as coins;                // Amount of transferred jettons
    from: Address;                       // Sender address
    response_destination: Address;       // Address where to return excessive Toncoins
    forward_ton_amount: Int as coins;    // Toncoins which should be send along with a transfer notification
    forward_payload: Slice as remaining; // Optional custom data sent to the recipient address
}

/**
 * @dev This message sends excessive Toncoins to a given address.
 */
message(0xd53276db) Excesses {
    query_id: Int as uint64; // Query identifier
}

/**
 * @dev This message notifies a recipient address about a jetton transfer.
 */
message(0x7362d09c) TransferNotification {
    query_id: Int as uint64;             // Query identifier
    amount: Int as coins;                // Amount of transferred jettons
    from: Address;                       // Sender address
    forward_payload: Slice as remaining; // Optional custom data sent to the recipient address
}

/**
 * @dev This message burns an amount of jettons.
 */
message(0x595f07bc) Burn {
    query_id: Int as uint64;       // Query identifier
    amount: Int as coins;          // Amount of burned jettons
    response_destination: Address; // Address where to return excessive Toncoins
    custom_payload: Cell?;         // Optional custom data for inner logic
}

/**
 * @dev This message notifies a recipient address about a jetton burn.
 */
message(0x7bdd97de) BurnNotification {
    query_id: Int as uint64;        // Query identifier
    amount: Int as coins;           // Amount of burned jettons
    owner: Address;                 // Owner address of burned jettons
    response_destination: Address?; // Address where to return excessive Toncoins

}
