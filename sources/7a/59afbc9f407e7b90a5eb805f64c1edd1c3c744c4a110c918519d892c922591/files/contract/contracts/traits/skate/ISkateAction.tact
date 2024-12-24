struct Destination {
    chain_id: Int as uint256; // <- the target chain
    vm_type: Int as uint256; // <- Skate vmType convention || 1 = EVM, 2 = TON, 3 = Solana.
}

struct Payload {
    destination: Destination;
    kernel_address: Int as uint256; // <- Kernel's universal app address (even though TON workchain supports 512 bit address,
    kernel_calldata: Cell; // <- specific execution data for **Kernel Skate App**
}

struct ActionInfo {
    expiration: Int as uint32; // Unix time
    payload: Payload; // execution payload, i.e. struct type of input msg
}

struct StagedTokens {
    amounts: map<Address, Int>; // Jetton Master -> amount (raw, i.e. 9 dec for TON, 6 dec for USDT)
    // NOTE: Added struct for kernel verification.
    vault: Address; // The address that hold staged tokens, Kernel will simulate transaction and verify post-balance of this token.
}

/////////////////////////////////////////////////////
//////////////// Action definition //////////////////
struct SkateAction {
    processing_fee: Int as coins; // (Skate) fees in TON for message processing, exceeds amount is refunded
    action_info: ActionInfo;
    staged_tokens: StagedTokens?;
}

// NOTE: External message to be picked up off-chain
message SkateActionCreated {
    action_id: Int as uint64;
    action: SkateAction;
}

message InitiateSkateAction {
    action: SkateAction;
    excess_receiver: Address;
}

