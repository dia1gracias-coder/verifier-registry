import "@stdlib/deploy";
import "@stdlib/ownable";
import "./traits/skate/ISkate.tact"; // implicit

message(0xedf05063) ChangeRelayer {
    newRelayer: Int;
    currentSignature: Slice;
    newSignature: Slice;
}

message(0xc8c28f2d) SetExecutor {
    executor: Address;
}

message(0x471c2809) RevokeExecutor {
    executor: Address;
}

message TopUpTON {}

contract SkateGateway with Deployable, OwnableTransferable  {
    const SKATE_FEE: Int = ton("0.00"); // Gas required to process intent.
    owner: Address;
    relayer: Int; // Relayer is an ED25519 public key
    executors: map<Address, Bool>;
    nonce: Int as uint64 = 0; // Nonce to mitigate precomputation attack, also ensures intents is submitted in order
    get fun currentNonce(): Int {
        return self.nonce;
    }

    init(owner: Address, relayer: Int) {
        self.owner = owner;
        self.relayer = relayer;
        self.executors = emptyMap();
    }

    receive(msg: TopUpTON) {
        // Do nothing, just accept TON.
    }

    ////////////////////// GOVERNANCE /////////////////////
    get fun relayer(): Int {
        return self.relayer;
    }

    inline fun is_executor(addr: Address): Bool {
        let executor: Bool? = self.executors.get(addr);
        return executor != null && executor!!;
    }
    get fun isExecutor(addr: Address): Bool {
        return self.is_executor(addr);
    }
    get fun executors(): map<Address, Bool> {
        return self.executors;
    }

    receive(msg: SetExecutor) {
        self.requireOwner();
        self.set_executor(msg.executor);
    }

    fun set_executor(executor: Address) {
        self.executors.set(executor, true);
        emit(SetExecutor{executor: executor}.toCell());
    }

    receive(msg: RevokeExecutor) {
        self.requireOwner();
        self.revoke_executor(msg.executor);
    }

    fun revoke_executor(executor: Address) {
        self.executors.del(executor);
        emit(RevokeExecutor{executor: executor}.toCell());
    }

    const CHANGE_RELAYER_MSG: String = "Skate::RELAYER_CHANGE";
    get fun changeRelayerMsg(): String {
        return self.CHANGE_RELAYER_MSG;
    }

    receive(msg: ChangeRelayer) {
        self.requireOwner();
        self.set_relayer(msg.newRelayer, msg.currentSignature, msg.newSignature);
    }
    inline fun set_relayer(newRelayer: Int, currentSignature: Slice, newSignature: Slice) {
        let messageHash: Int = sha256(self.CHANGE_RELAYER_MSG);
        self.validate_relayer_signature(messageHash, currentSignature);
        let isValid: Bool = checkSignature(messageHash, newSignature, newRelayer);
        require(isValid, "SkateGateway::set_relayer()::Not approved by new relayer!");
        self.relayer = newRelayer;
    }
    /////////////////////////////////////////////////////////

    //////////////////// Execution Layer ////////////////////
    // NOTE: Skate App entry point.
    // 1. App relay user intent to this gateway
    // 2. Gateway emit event -> Skate kernel + Execution network pick up
    receive(msg: SkateInitiateTaskNotification) {
        let ctx: Context = context();
        require(ctx.value >= self.SKATE_FEE, "SkateGateway::SkateInitiateTaskNotification::Not enough processing fee!");

        emit(SkateInitiateTaskEvent{
            query_id: msg.query_id,
            user: msg.user,
            skate_app: ctx.sender,
            execution_info: msg.execution_info,
        }.toCell());

        // TODO: DISCUSSION POINT
        // This callback enable supports for different type of use cases:
        //  a. default gateway => empty callback, for app with user = normal wallet (e.g. walletV4) uses.
        //  b. contract only gateway => send a notification with extra context to app,
        //      for contracts with user = contracts (e.g. to acts as arbitrary middleware between user defined contracts).
        // self._initiate_task_callback(ctx, msg);
    }
    inline fun _initiate_task_callback(ctx: Context, msg: SkateInitiateTaskNotification) {}

    // NOTE: Skate executor entry point.
    receive(msg: SkateExecuteTask) {
        self.only_executor();
        let execution_info: ExecutionInfo = msg.execution_info;
        require(now() <= execution_info.expiration, "SkateGateway::SkateExecuteTask::Task expired!");

        // Construct the message hash = keccak256(encode(payload)).
        let msg_hash: Int = self._encode_payload(execution_info.payload);
        self.nonce += 1;

        // validate signature
        self.validate_relayer_signature(msg_hash, msg.relayer_signature);

        // TODO: what to do with Payload.destination?
        // This information must be pushed on-chain so it can be verified later.

        send(SendParameters{
            to: msg.target_app,
            value: execution_info.value,
            mode: SendPayGasSeparately,
            body: execution_info.payload.data,
        })
    }

    inline fun _encode_payload(execution_payload: Payload): Int {
        let msg_slice = beginCell()
            .storeUint(execution_payload.data.hash(), 256)
            .storeUint(execution_payload.destination.hash(), 256)
            .storeInt(self.nonce, 64)
            .endCell()
            .asSlice();
        let hashed_msg = sha256(msg_slice);
        return hashed_msg;
    }
    get fun payload_hash(payload: Payload): Int {
        return self._encode_payload(payload);
    }
    /////////////////////////////////////////////////////////
    inline fun only_executor() {
        nativeThrowUnless(132, self.is_executor(sender()))
    }

    inline fun validate_relayer_signature(hash: Int /* bytes32 */, signature: Slice) {
        let isValid: Bool = checkSignature(hash, signature, self.relayer);
        require(isValid, "SkateGateway::validate_relayer_signature()::Invalid relayer signature!");
    }
}
