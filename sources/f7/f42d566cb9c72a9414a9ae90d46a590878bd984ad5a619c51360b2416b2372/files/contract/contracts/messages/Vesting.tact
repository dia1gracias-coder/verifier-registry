/**
 * @dev This message vests an amount of jettons on the master contract.
 */
message Vest {
    query_id: Int as uint64; // Query identifier
    amount: Int as coins;    // Amount of vested jettons
    to: Address;             // Address of the owner of jettons
    start: Int as uint32;    // Vesting start timestamp in seconds
    duration: Int as uint32; // Vesting duration in seconds
    force: Bool?;            // Flag to override vesting start timestamp and duration parameters
}

/**
 * @dev This message vests an amount of jettons for a given owner address.
 */
message InternalVest {
    query_id: Int as uint64;       // Query identifier
    amount: Int as coins;          // Amount of vested jettons
    start: Int as uint32;          // Vesting start timestamp in seconds
    duration: Int as uint32;       // Vesting duration in seconds
    response_destination: Address; // Address where to return excessive Toncoins
    force: Bool?;                  // Flag to override vesting start timestamp and duration parameters
}

/**
 * @dev This message releases an amount of vested jettons.
 */
message Release {
    query_id: Int as uint64; // Query identifier
    amount: Int as coins;    // Amount of vested jettons
}
