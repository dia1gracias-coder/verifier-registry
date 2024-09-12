import "@stdlib/deploy";
import "@stdlib/ownable";
import "./traits/skate/ISkate.tact"; // implicit
import "./asm/cell_ext.tact";

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

message(0x4c2925bc) ChangeTimeout {
    new_timeout: Int as uint16;
}

message(0x75a6e8ec) TopUpTON {}
message(0x44807e69) WithdrawTON {}

const CELL_BIT_SIZE: Int = 1023;

contract SkateGateway with Deployable, OwnableTransferable  {
    owner: Address;
    relayer: Int; // Relayer is an ED25519 public key
    executors: map<Address, Bool>;

    nonces: map<Int as uint16, Cell> = null; // use Cell as 1023 bits map
    old_nonces: map<Int as uint16, Cell> = null; // replay protection
    const MAX_NONCE_CELL: Int = 65535; // 2^16 - 1
    const MAX_NONCE: Int = 67043327; // MAX_NONCE_CELL * CELL_BIT_SIZE - 1 = 65535 * 1023 - 1
    last_used_nonce: Int as uint32 = 0; // NOTE: for contract to schedule nonce
    get fun last_nonce(): Int {
        return self.last_used_nonce;
    }

    timeout: Int as uint16 = 43200; // In seconds, equivalently: max = 65535s = 18 hours 12 min 15 sec. Default = 12 hours.
    get fun timeout(): Int {
        return self.timeout;
    }
    last_clean_timestamp: Int as uint64 = 0; // Unix timestamp, use 64 bits

    const CREATION_MSG: String = "DeployGateway";
    get fun creationMsg(): String {
        return self.CREATION_MSG;
    }
    init(owner: Address, relayer: Int, signature: Slice) {
        let isValid: Bool = checkSignature(sha256(self.CREATION_MSG), signature, relayer);
        require(isValid, "SkateGateway::validate_relayer_signature()::Invalid relayer signature!");

        self.owner = owner;
        self.relayer = relayer;
        self.executors = emptyMap();
    }

    receive(msg: TopUpTON) {
        // Do nothing, just accept TON.
    }

    receive(msg: WithdrawTON) {
        send(SendParameters{
            to: self.owner,
            value: 0,
            mode: SendRemainingBalance,
        })
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

    // NOTE: This timeout is a tradeoff between:
    //  1. shorter timeout -> higher throughput, need to clear map more frequent.
    //  2. higher timeout -> lower throughput, less gas to clear map.
    // Also when the map is big. Skate should clear it so nonce check and ugprade for each execution is cheap
    receive(msg: ChangeTimeout) {
        self.requireOwner();
        self.timeout = msg.new_timeout;
    }
    /////////////////////////////////////////////////////////

    //////////////////// Execution Layer ////////////////////
    // TODO: Fine tune these for mainnet.
    const SKATE_NOTIFICATION_FEE: Int = ton("0.00"); // fee required to emit event to skate infra

    // NOTE: Skate App entry point.
    // 1. App relay user intent to this gateway
    // 2. Gateway emit event -> Skate kernel + Execution network pick up
    receive(msg: SkateInitiateTaskNotification) {
        let ctx: Context = context();
        require(ctx.value >= self.SKATE_NOTIFICATION_FEE, "SkateGateway::SkateInitiateTaskNotification::Not enough processing fee!");

        emit(SkateInitiateTaskEvent{
            query_id: msg.query_id,
            user: msg.user,
            skate_app: ctx.sender,
            execution_info: msg.execution_info,
        }.toCell());

        // NOTE: self.storageReserve is const, not works for our usecase
        let balanceBeforeMessage: Int = myBalance() - ctx.value;
        nativeReserve(balanceBeforeMessage + self.SKATE_NOTIFICATION_FEE, ReserveExact);

        if (msg.callback) {
            let callbackBody = SkateInitiateTaskCallback{
                query_id: msg.query_id,
            }.toCell();
            send(SendParameters{
                bounce: false,
                to: ctx.sender, // a SkateApp
                value: 0,
                mode: SendRemainingBalance | SendIgnoreErrors,
                // NOTE: It's up to the app to identify payload given query_id.
                // This callback enable supports for DApp to update states if intent registration is confirmed.
                //  E.g. a DeFi app might optimistically (and partially, depending on intent success %)
                //  enable user margin once intent is confirmed.
                body: callbackBody,
            })
        }
    }

    // NOTE: Skate executor entry point.
    const MIN_EXECUTION_VALUE: Int = ton("0.008"); // NOTE: This is the base value for msg to pass, must adjust accordingly for each app.
    receive(msg: SkateExecuteTask) {
        self.require_executor();
        let execution_info: ExecutionInfo = msg.execution_info;

        // 1.a Expiry validation
        let now: Int = now();
        require(now <= execution_info.expiration, "SkateGateway::SkateExecuteTask::Task expired!");
        require(msg.created_at <= now && msg.created_at > now - self.timeout, "SkateGateway::SkateExecuteTask::Invalid created_at!");

        // 1.b Value validation
        require(execution_info.value >= self.MIN_EXECUTION_VALUE, "SkateGateway::SkateExecuteTask::Insufficient execution value");

        // 1.c Signature validation
        let msg_hash: Int = self._encode_payload(
            msg.query_id, msg.target_app, execution_info.payload,
            execution_info.expiration, msg.nonce, msg.created_at
        );
        self.validate_relayer_signature(msg_hash, msg.relayer_signature);

        // 1.d Nonce validation
        self.try_refresh_nonce_map();
        require(msg.nonce >= 0 && msg.nonce <= self.MAX_NONCE, "SkateGateway::SkateExecuteTask::Nonce out of bound!");
        let cell_index = msg.nonce / CELL_BIT_SIZE;
        let bit_index = msg.nonce % CELL_BIT_SIZE;
        let new_cell = self.check_nonce_and_calculate_updated_cell(cell_index, bit_index);

        // 2. Update states
        // NOTE: This must happen before sending messages to prevent exploitation:
        //  + Executor set gas just enough to make sure state not update => replay attack
        if (msg.nonce > self.last_used_nonce) {
            self.last_used_nonce = msg.nonce;
        }
        self.nonces.set(cell_index, new_cell);

        // 3. Dispatch execution message
        // WARN: This step might false due to out of gas error.
        // In this case, executor must request for a new (nonce, signature) pair
        // => It's up to executor to plan their gas action.
        send(SendParameters{
            to: msg.target_app,
            value: execution_info.value,
            mode: SendPayGasSeparately,
            body: execution_info.payload.data,
        });

    }

    inline fun try_refresh_nonce_map() {
        self.last_used_nonce = 0;
        let now: Int = now();
        if (now - 2 * self.timeout > self.last_clean_timestamp) {
            self.old_nonces = null;
            self.nonces = null;
            self.last_clean_timestamp = now;
        } else if (now - self.timeout > self.last_clean_timestamp) {
            self.old_nonces = self.nonces;
            self.nonces = null;
            self.last_clean_timestamp = now;
        }
    }

    inline fun check_nonce_and_calculate_updated_cell(cell_index: Int, bit_index: Int): Cell {
        require(bit_index < CELL_BIT_SIZE, "SkateGateway::Bit index out of bound!");
        require(cell_index <= self.MAX_NONCE_CELL, "SkateGateway::Cell index out of bound!");

        // NOTE: This is essential to prevent replay attack. For example, if there is no old_nonces map.
        //   1. Let timeout = 3. A message arrive at time 1, created_at = 1
        //   2. Somebody cleanup at time 2
        //   3. Message resubmitted at time 3, meet the created_at requirements 3 - 1 = 2 < 3 (timeout/expiry value)
        // => Same message is submitted twice
        let old_nonce = self.old_nonces.get(cell_index);
        if (old_nonce != null) {
            let nonce_slice = old_nonce!!.beginParse();
            let head = nonce_slice.loadBits(bit_index);
            let is_set = nonce_slice.loadBool();
            require(!is_set, "SkateGateway::Nonce used, please request for new signature!");
        }

        let nonce_cell = self.nonces.get(cell_index);
        let b = beginCell();
        if (nonce_cell != null) {
            let nonce_slice = nonce_cell!!.beginParse();
            let head = nonce_slice.loadBits(bit_index);
            let is_set = nonce_slice.loadBool();
            require(!is_set, "SkateGateway::Nonce used, please request for new signature!");
            b = b.storeSlice(head).storeBool(true).storeSlice(nonce_slice);
        } else {
            b = b.storeZeroes(bit_index).storeBool(true).storeZeroes(CELL_BIT_SIZE - bit_index - 1);
        }
        let new_cell = b.endCell();
        return new_cell;
    }

    inline fun _encode_payload(query_id: Int, target: Address, payload: Payload, expiration: Int, nonce: Int, created_at: Int): Int {
        let cell_hash = beginCell()
            .storeUint(query_id, 64)
            .storeUint(payload.toCell().hash(), 256)
            .storeUint(expiration, 32)
            .storeInt(nonce, 32)
            .storeInt(created_at, 32)
            .storeAddress(target)
            .endCell()
            .hash();
        return cell_hash;
    }
    get fun payload_hash(query_id: Int, target: Address, payload: Payload, expiration: Int, nonce: Int, created_at: Int): Int {
        return self._encode_payload(query_id, target, payload, expiration, nonce, created_at);
    }

    /////////////////////////////////////////////////////////
    inline fun require_executor() {
        nativeThrowUnless(132, self.is_executor(sender()))
    }

    inline fun validate_relayer_signature(hash: Int /* bytes32 */, signature: Slice) {
        let isValid: Bool = checkSignature(hash, signature, self.relayer);
        require(isValid, "SkateGateway::validate_relayer_signature()::Invalid relayer signature!");
    }
}

