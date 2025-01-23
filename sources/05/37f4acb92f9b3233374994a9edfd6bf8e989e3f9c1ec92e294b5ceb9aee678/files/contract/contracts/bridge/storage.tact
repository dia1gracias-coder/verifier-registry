
import "./strategies.tact";
import "../utils/access_control.tact";

const TON_KEY: Int = sha256("TON");
const STON_FI_SWAP_FEE: Int = ton("0.5");

struct Token {
    address:        Address;
    decimals:       Int as uint8;
    emmet_lp:       Address;
    symbol:         String;
    swap_pool:      Address;
    swap_router:    Address;
    wallet:         Address;
}

struct Chain {
    name:       String;
    chain_id:   Int;
}

struct ForeignFees {
    // step -> amount
    i: map<Int, Int>;
}

trait Storage with AccessControl, EmmetTokenStrategy {
    admin:              Address;                // Contract admin address
    cfo:                Address;                // This contract's Chief Financial Officer
    chains:             map<Int, Chain>;        // Supported chains map
    chainId:            Int;                    // EIP-155-like of the current chain {TON}
    consensus_fee:      Int;                    // Fee for validator consensus in TON
    foreign_fees:       map<Int, ForeignFees>;  // Foreign Chain fees (in TON)
    incomming_txs:      map<Int, Bool>;         // Processed incoming transactions
    locked:             map<Int, Int>;          // Locked Jettons Amounts map
    min_tx_fee:         Int;                    // Minimum Transaction fee
    modules:            map<Int, Address>;      // Bridge modules map
    nonce:              Int;                    // Index of the last outgoing transaction.
    paused:             Bool;                   // Paused flag
    protocol_fee:       Int;                    // Community fee, ex. $ 0.5 (in TON)
    roles:              map<Int, RoleData>;     // AccessControl roles hashmap
    token_strategies:   map<Int, FromTokenMap>; // Token Strategies map
    threshold:          Int;                    // BFT threshold
    tokens:             map<Int, Token>;        // Supposted token map
    TVL:                Int;                    // Locked TON tracker
    validators:         map<Int, Address>;      // Indexed validator map
    validator_count:    Int;                    // The number of available validators

    // ============ G E T T E R S ============ //

    get fun estimate_fee(chain_id: Int, from_token: Int, to_token: Int): Int {

        return self._estimate_fee(chain_id, from_token, to_token);
    }

    get fun get_admin(): Address {

        return self.admin;
    }

    get fun get_cfo(): Address {

        return self.cfo;
    }

    get fun get_chain(chain_id: Int): Chain {

        let chain: Chain? = self.chains.get(chain_id);

        if(chain == null){
            return Chain{name:"Unsupported", chain_id:0};
        }

        return chain!!;
    }

    get fun get_min_tx_fee(): Int {

        return self.min_tx_fee;
    }

    get fun get_module(step: Int): Address {

        let module: Address? = self.modules.get(step);

        if(module == null){return newAddress(0,0);}

        return module!!;
    }

    get fun get_nonce(): Int {

        return self.nonce;
    }

    get fun get_chain_id(): Int {

        return self.chainId;
    }

    get fun get_consensus_fee(): Int {

        return self.consensus_fee;
    }

    get fun get_locked(token: Int): Int {

        let _locked: Int? = self.locked.get(token);

        return _locked == null
            ? 0
            : _locked!!;
    }

    get fun get_paused(): Bool {

        return self.paused;
    }

    get fun get_protocol_fee(): Int {

        return self.protocol_fee;
    }

    get fun get_step_fee(chain_id: Int, step: Int): Int {

        return self._get_step_fee(chain_id, step);
    }

    get fun get_threshold(): Int {

        return self.threshold;
    }

    get fun get_token(key: Int): Token {
        let token: Token? = self.tokens.get(key);
        if(token == null){
            return Token {
                address:        newAddress(0, 0),
                decimals:       0,
                emmet_lp:       newAddress(0, 0),
                symbol:         "Unsupported",
                swap_pool:      newAddress(0, 0),
                swap_router:    newAddress(0, 0),
                wallet:         newAddress(0, 0)
            }
        }
        return token!!;
    }

    get fun get_tvl(): Int {
        return self.TVL;
    }

    get fun get_validator(index: Int): Address {

        let validator: Address? = self.validators.get(index);

        if(validator == null){return newAddress(0, 0);}

        return validator!!;
    }

    get fun get_validator_count(): Int {

        return self.validator_count;
    }

    get fun is_processed(hash: Int): Bool {

        return self._is_processed(hash);
    }

    get fun is_validator(address: Address): Bool {

        return self._is_validator(address);
    }

    //  P R I V A T E  F U N C T I O N S //

    inline fun burn(from_token: Int, amount: Int) {
        require(
            false, 
            "EmmetBridge: Unsupported flow. Instead burn & notify the bridge!"
        );
    }

    inline fun delete_chain(chain_id: Int){

        let chain: Chain? = self.chains.get(chain_id);

        if(chain != null){self.chains.del(chain_id);}
    }

    inline fun delete_module(step: Int){

        self.require_supported_step(step);

        let module: Address? = self.modules.get(step);

        if(module != null){self.modules.del(step);}
    }

    inline fun delete_token(symbol: String){

        let id: Int = sha256(symbol);

        let token: Token? = self.tokens.get(id);

        if(token != null){self.tokens.del(id);}
    }

    inline fun delete_validator(candidate: Address) {

        let key: Int = sha256(candidate.toString());

        if(self.validators.get(key) == candidate){

            self.validators.del(key);

            self.validator_count -= 1;

            self.update_threshold();

            self._revoke_role(self.validator_role_id(), candidate);
        }
    }

    inline fun _estimate_fee(chain_id: Int, from_token: Int, to_token: Int): Int {

        let fee: Int = self.protocol_fee + self.consensus_fee;

        let steps: Steps? = self._get_foreign_strategies(
            chain_id, 
            from_token, 
            to_token
        );

        if(steps != null){
            let i: Int = 0;
            while(i < steps!!.size){
                let step: Int? = steps!!.path.get(i);
                fee += (step != null) 
                    ? self._get_step_fee(chain_id, step!!)
                    : 0;
                i += 1;
            }
        }

        return fee;
    }

    inline fun _generate_tx_hash(
        chain_id:   Int,
        from_token: Int,
        to_token:   Int,
        amount:     Int,
        nonce:      Int,
        timestamp:  Int
    ): Int {

        // Build the message to be hashed
        let builder: StringBuilder = beginString();
        builder.append( chain_id.toString()  );
        builder.append( from_token.toString());
        builder.append( to_token.toString()  );
        builder.append( amount.toString()    );
        builder.append( nonce.toString()     );
        builder.append( timestamp.toString() );

        // Digest & return
        return sha256(builder.toString());
    }

    inline fun _get_step_fee(chain_id: Int, step: Int): Int {

        let f_fees: ForeignFees? = self.foreign_fees.get(chain_id);

        if(f_fees == null){return 0;}

        let step_fee: Int? = f_fees!!.i.get(step);

        if(step_fee == null){return 0;}

        return step_fee!!;
    }

    inline fun _is_processed(hash: Int): Bool {

        let processed: Bool? = self.incomming_txs.get(hash);

        if(processed == null){return false;}

        return processed!!;
    }

    inline fun _is_validator(address: Address): Bool {

        let validator: Address? = self.validators.get(sha256(address.toString()));

        if(validator == null){return false;}

        return self._has_role(address, self.validator_role_id());
    }

    inline fun lock_jetton(from_token: Int, amount: Int) {

        let alreadyLocked: Int? = self.locked.get(from_token);

        let newLocked = alreadyLocked == null
            ? amount
            : amount + alreadyLocked!!;

        self.locked.set(from_token, newLocked);
    }

    inline fun lock_toncoin(amount: Int) {

        self.TVL += amount;
    }

    inline fun lp_jetton_lock(from_token: Int, amount: Int) {

        let token: Token? = self.tokens.get(from_token);

        let token_wallet: Address = token!!.wallet;

        let lp_master: Address = token!!.emmet_lp;

        require(token_wallet != newAddress(0,0), "EmmetBridge: Wallet for Jetton not set");

        let lpLockBody: Cell = beginCell()
            .storeUint(0xf8a7ea5, 32)       // op::transfer
            .storeUint(self.nonce, 64)      // query_id
            .storeCoins(amount)             // amount
            .storeAddress(lp_master)        // to
            .storeAddress(lp_master)        // response_destinaiton
            .storeMaybeRef(null)            // custom payload
            .storeCoins(self.min_tx_fee)    // forward_ton_amount
            .storeMaybeRef(null)            // forward_payload
            .endCell();

        send(SendParameters{
            value:  self.min_tx_fee * 2,
            mode:   SendPayGasSeparately | SendIgnoreErrors,
            body:   lpLockBody,
            to:     token_wallet
        });
    }

    inline fun lp_ton_lock(amount: Int) {

        let token: Token? = self.tokens.get(TON_KEY);

        let ton_lp_master: Address = token!!.emmet_lp;

        send(SendParameters{
            value:  amount + self.min_tx_fee / 2,
            mode:   SendPayGasSeparately | SendIgnoreErrors,
            to:     ton_lp_master
        });
    }

    inline fun lp_release(
        to_token:   Int,
        amount:     Int,
        recipient:  Address
    ){
        let token: Token? = self.tokens.get(to_token);

        let lp_master: Address = token!!.emmet_lp;

        send(SendParameters{
            to:     lp_master,
            mode:   SendPayGasSeparately | SendIgnoreErrors,
            value:  self.min_tx_fee * 2,
            body:   ReleaseTokens {
                amount:     amount,
                to:         recipient,
                body:       beginCell().endCell()
            }.toCell()
        });
    }

    inline fun mint(
        to_token:   Int,
        amount:     Int,
        recipient:  Address
    ){
        let token: Token? = self.tokens.get(to_token);

        let wrapped_master: Address = token!!.address;

        let comment: StringBuilder = beginString();

        comment.append("EmmetBridge: MINT");

        send(SendParameters{
            mode:   SendPayGasSeparately | SendIgnoreErrors,
            to:     wrapped_master,
            value:  self.min_tx_fee * 2,
            body:   JettonMint {
                amount:                 amount,
                origin:                 myAddress(),
                receiver:               recipient,
                custom_payload:         null,
                forward_payload:        comment.toSlice(),
                forward_ton_amount:     self.min_tx_fee
            }.toCell()
        });
    }

    inline fun pause() {
        if(!self.paused){self.paused = true;}
    }

    inline fun require_supported_step(step: Int){
        require(step > 2 && step < SWAP_3, "EmmetBridge: Unsupported step");
    }

    inline fun require_supported_credentials(chain_id: Int, from_token: Int, to_token: Int){
        // Check the chain
        let chain: Chain? = self.chains.get(chain_id);
        require(chain != null, "EmmetBridge: unsupported chain");
        // Check the from Token
        let from_token_opt: Token? = self.tokens.get(from_token);
        require(from_token_opt != null, "EmmetBridge: unsupported from_token");
        // Check the to Token
        let to_token_opt: Token? = self.tokens.get(to_token);
        require(to_token_opt != null, "EmmetBridge: unsupported to_token");
    }

    inline fun require_unpaused(){
        require(!self.paused, "EmmetBridge: The contract is paused");
    }

    inline fun set_chain(name: String, chain_id: Int){
        self.chains.set(chain_id, Chain{
            name:       name, 
            chain_id:   chain_id
        });
    }

    inline fun switch_incoming(
        chain_id:   Int, 
        from_token: Int, 
        to_token:   Int,
        amount:     Int,
        recipient:  Address
    ){
        let steps: Steps = self._get_incoming_strategies(chain_id, from_token, to_token);

        require(steps.size != 0, "EmmetBridge: unsupported incoming strategy");

        foreach(step_key, step_value in steps.path) {

            self.require_supported_step(step_value);

            if(step_value == UNLOCK){

                if(to_token == TON_KEY){

                    require(
                        context().value >= self.min_tx_fee / 3,
                        "EmmetBridge: Insufficient fee"
                    );

                    self.unlock_toncoin(amount, recipient);
                } else {

                    require(
                        context().value >= self.min_tx_fee * 3,
                        "EmmetBridge: Insufficient fee"
                    );

                    self.unlock_jetton(to_token, amount, recipient);
                }

            } else if (step_value == MINT){

                require(to_token != TON_KEY, "EmmetBridge: Cannot MINT Toncoin");

                require(
                    context().value >= self.min_tx_fee * 2,
                    "EmmetBridge: Insufficient fee"
                );

                self.mint(to_token, amount, recipient);

            } else if (step_value == LP_RELEASE) {

                require(
                    context().value >= self.min_tx_fee * 2,
                    "EmmetBridge: Insufficient fee"
                );

                self.lp_release(to_token, amount, recipient);

            // } else if(step_value == SWAP_1){

            // } else if(step_value == SWAP_2){
                
            } else {

                require(false, "EmmetBridge: unsupported incoming strategy");
            }
        }
    }

    inline fun switch_outgoing(
        chain_id:   Int, 
        from_token: Int, 
        to_token:   Int,
        amount:     Int
    ){
        let steps: Steps = self._get_local_strategies(chain_id, from_token, to_token);

        require(steps.size != 0, "EmmetBridge: unsupported outgoing strategy");

        let cross_chain_fees: Int = self._estimate_fee(
            chain_id,
            from_token,
            to_token
        );

        self.nonce += 1;

        foreach(step_key, step_value in steps.path) {

            self.require_supported_step(step_value);

            if(step_value == LOCK){

                if(from_token == TON_KEY){

                    require(
                        context().value >= amount 
                            + cross_chain_fees 
                            + self.min_tx_fee,
                        "EmmetBridge: Insufficient fee"
                    );

                    self.lock_toncoin(amount);

                } else {

                    require(
                        context().value >= cross_chain_fees
                            + self.min_tx_fee * 2,
                        "EmmetBridge: Insufficient fee"
                    );

                    self.lock_jetton(from_token, amount);
                }
            } else if(step_value == BURN){

                require(
                    context().value >= cross_chain_fees
                        + self.min_tx_fee * 3,
                    "EmmetBridge: Insufficient fee"
                );

                self.burn(from_token, amount);

            } else if (step_value == LP_LOCK){

                if(from_token == TON_KEY){

                    require(
                        context().value >= amount 
                            + cross_chain_fees 
                            + self.min_tx_fee,
                        "EmmetBridge: Insufficient fee"
                    );

                    self.lp_ton_lock(amount);

                } else {

                    require(
                        context().value >= cross_chain_fees
                            + self.min_tx_fee * 3,
                        "EmmetBridge: Insufficient fee"
                    );

                    self.lp_jetton_lock(from_token, amount);
                }
            // } else if(step_value == SWAP_1){

            // } else if(step_value == SWAP_2){
                
            } else {

                require(false, "EmmetBridge: unsupported outgoing strategy");
            }
        }
    }

    inline fun set_consensus_fee(amount: Int){

        require(amount >= 0, "EmmetBridge: Negative consensus fee prohibited");

        self.consensus_fee = amount;
    }

    inline fun set_min_tx_fee(amount: Int){

        require(amount >= 0, "Negative TX fee prohibited");

        self.min_tx_fee = amount;
    }

    inline fun set_module(step: Int, module: Address){

        self.require_supported_step(step);

        self.modules.set(step, module);
    }

    inline fun set_protocol_fee(amount: Int){

        require(amount >= 0, "Negative protocol fee prohibited");

        self.protocol_fee = amount;
    }

    inline fun set_step_fee(chain_id: Int, step: Int, amount: Int){

        let f_fees: ForeignFees? = self.foreign_fees.get(chain_id);

        let temp_f_fees: ForeignFees = f_fees == null 
            ? ForeignFees{i: emptyMap()}
            : f_fees!!;

        temp_f_fees.i.set(step, amount);

        self.foreign_fees.set(chain_id, temp_f_fees);
    }

    inline fun set_token(
        address:        Address,
        decimals:       Int,
        emmet_lp:       Address,
        symbol:         String,
        swap_pool:      Address,
        swap_router:    Address,
        wallet:         Address
    ) {

        self.tokens.set(sha256(symbol), Token{
            address:        address,
            decimals:       decimals,
            emmet_lp:       emmet_lp,
            symbol:         symbol,
            swap_pool:      swap_pool,
            swap_router:    swap_router,
            wallet:         wallet
        });
    }

    inline fun set_validator(candidate: Address) {

        let key: Int = sha256(candidate.toString());

        require(
            self.validators.get(key) != candidate, 
            "Validator already exists"
        ); 

        self.validators.set(key, candidate);
            
        self.validator_count += 1;

        self.update_threshold();

        self._grant_role(self.validator_role_id(), candidate);

    }

    inline fun unlock_jetton(
        to_token:   Int,
        amount:     Int,
        recipient:  Address
    ) {

        let token: Token? = self.tokens.get(to_token);

        let wallet: Address = token!!.wallet;

        send(SendParameters{
            bounce: true,
            mode:   SendPayGasSeparately | SendIgnoreErrors,
            to:     wallet,
            value:  self.min_tx_fee * 2,
            body:   JettonTransfer {
                query_id:               self.nonce,
                amount:                 amount,
                destination:            recipient,
                response_destination:   recipient,
                custom_payload:         null,
                forward_ton_amount:     0,
                forward_payload:        "EmmetBridge: Token UNLOCK".asComment()
            }.toCell()
        });

    }

    inline fun unlock_toncoin(
        amount:     Int,
        recipient:  Address
    ) {

        send(SendParameters{
            body:   "EmmetBridge: TON UNLOCK".asComment(),
            bounce: true,
            mode:   SendPayGasSeparately | SendIgnoreErrors,
            to:     recipient,
            value:  amount + ton("0.000124")
        });

        self.TVL -= amount;
 
    }

    inline fun unpause() {
        if(self.paused){self.paused = false; }
    }

    inline fun update_threshold() {
        self.threshold = self.validator_count * 2 / 3;
    }

    inline fun verify_signatures(
        hash:   Int, 
        sigs:   map<Int, SignerAndSignature>
    ) {
        let valid_count: Int = 0;
        foreach (c, sig in sigs) {
            // 2.2 Ensure the signature is not empty
            if (self.validators.get(sig.key) != null) {
                // 2.2.1 Verify the signature
                let ok: Bool = checkSignature(hash, sig.signature, sig.key);
                // 2.2.2 Increment the counter only if ok.
                if (ok) {valid_count += 1;}
            } // otherwise exclude the signature count
        } // 3. Ensure the threshold is reached
        require(valid_count >= self.threshold, "EmmetBridge: BFT threshold not reached.");
    }

}