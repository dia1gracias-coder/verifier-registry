/// Skate Inter Contract Communication Interface (ICCI)
//
// NOTE: DISCUSSION POINT (RESOLVED)
// INTENDED FLOW:
// 1. SkateApp implementations takes request initiation from skate_app.
// 2. SkateApp construct payload and request Skate Gateway.
// 3. Skate Gateway emit Event collected by off-chain actor then:
//    a. Executor processIntent(), i.e. reserve it => emit event
//    b. Skate Kernel process.
//    c. Skate AVS process.
//    d. Executor do their jobs on destination chain, i.e. PolyMarket on Polygon
//    e. Relayer sign the confirmation
// 4. Executor with relayer signature:
//    a. execute on Skate Gateway (which verify)
//    b. Execution dispatch to SkateApp (TON periphery)
// 6. SkateApp performs assets transfer based on verified state (STATELESS)
// 7. Assets released on destination chains

struct Destination {
    chain_id: Int as uint256; // <- the target chain
    vm_type: Int as uint256; // <- Skate vmType convention || 1 = EVM, 2 = TON, 3 = Solana.
    address: Int as uint256; // <- universal address (even though TON workchain supports 512 bit address,
}

struct Payload {
    destination: Cell; // NOTE: as Destination, to by pass 1023 bits limit
    data: Cell; // <- specific execution data, intepreted by Skate kernel. Developers can write their own intepretation plugins for executor.
}

struct ExecutionInfo {
    value: Int as coins; // nanoTONs value
    expiration: Int as uint32; // Unix time
    payload: Payload; // execution payload, i.e. struct type of input msg
}

// SkateApp
struct SkateInitiateTask {
    query_id: Int as uint64;
    user: Address;
    processing_fee: Int as coins; // in nanoTONs, set by Skate.
    execution_info: ExecutionInfo;
    callback: Bool; // NOTE: whether the app request a callback
}

// NOTE: External message
message(0x7560bbc5) SkateInitiateTaskEvent {
    query_id: Int as uint64;
    user: Address;
    skate_app: Address;
    execution_info: ExecutionInfo;
}

// For Skate App
message(0xf5eb6224) SkateInitiateTaskNotification {
    query_id: Int as uint64;
    user: Address;
    execution_info: ExecutionInfo;
    callback: Bool; // NOTE: whether the app request a callback
}

message(0xaac7c1cc) SkateInitiateTaskCallback {
    query_id: Int as uint64;
}

// For Skate executors
message(0x23dc99bb) SkateExecuteTask {
    query_id: Int as uint64;
    nonce: Int as uint32; // 16 cell index + 10 bit index. Ideally only need 26 bits.
    created_at: Int as uint64; // timestamp at which TON relayer sign this, NOT WHEN TASK FIRST CREATED ON KERNEL.
    target_app: Address;
    execution_info: ExecutionInfo;
    relayer_signature: Slice;
}

