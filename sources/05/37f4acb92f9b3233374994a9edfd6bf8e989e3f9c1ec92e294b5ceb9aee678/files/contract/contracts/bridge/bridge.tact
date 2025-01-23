import "./bridge_admin.tact";
import "./messages/bridge.tact";

contract EmmetBridge with BridgeAdmin {
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

    init(
        admin:                  Address,
        cfo:                    Address,
        validator:              Address
    ){
        self.admin              = admin;
        self.cfo                = cfo;
        self.chains             = emptyMap();
        self.chainId            = 65534;        // Emmet Internal
        self.consensus_fee      = 0;
        self.foreign_fees       = emptyMap();
        self.incomming_txs      = emptyMap();
        self.locked             = emptyMap();
        self.min_tx_fee         = ton("0.03");
        self.modules            = emptyMap();
        self.nonce              = 0;
        self.paused             = false;        // Unpaused
        self.protocol_fee       = 0;
        self.token_strategies   = emptyMap();
        self.threshold          = 0;
        self.tokens             = emptyMap();
        self.TVL                = 0;
        self.validators         = emptyMap();
        self.validator_count    = 0;

        self._grant_role(self.admin_role_id(),  admin);
        self._grant_role(self.cfo_role_id(),    cfo);
        self.set_validator(validator);
    }

    receive(msg: TokenExcesses){} // Accept TON cashback

    //********************************************//
    //             Receive Installment            //
    //********************************************//

    receive(msg: ReceiveInstallment) {
        self.only_validator();
       
        self.require_unpaused();

        let installment: Installment = msg.installment;

        let hash: Int = installment.toCell().hash();

        require(msg.tx_hash == hash, "EmmetBridge: Installment hash mismatch");

        require(!self._is_processed(hash), "EmmetBridge: Previously processed TX");

        self.verify_signatures(hash, msg.signatures);

        let from_token_slice:  Slice   = installment.from_token.asSlice();

        let from_token_key:    Int     = from_token_slice.loadUint(256);

        let to_token_slice:    Slice   = installment.to_token.asSlice();

        let to_token_key:      Int     = to_token_slice.loadUint(256);

        self.switch_incoming(
            installment.from_chain,
            from_token_key,
            to_token_key,
            installment.amount,
            installment.recipient
        );

        self.incomming_txs.set(hash, true);

        // 6. Populate the incomming TX with msg data
        let itx: IncomingTransaction =  IncomingTransaction{
            id:                 msg.id,
            amount:             installment.amount,
            from_token:         installment.from_token,
            to_token:           installment.to_token,
            target_chain_id:    installment.target_chain,
            to:                 installment.recipient
        };

        // 7. Notify the external entities
        emit(itx.toCell());

    }

    //********************************************//
    //               Send Installment             //
    //********************************************//

    receive(msg: FreezeTon){
       
        self.require_unpaused();

        let from_token_key: Int = msg.from_token.asSlice().loadUint(256);

        let to_token_key: Int = msg.to_token.asSlice().loadUint(256);

        require(from_token_key == TON_KEY, "EmmetBridge: in FreezeTon from_token must be TON");
        
        self.require_supported_credentials(msg.target_chain, from_token_key, to_token_key);

        // Switch Action
        self.switch_outgoing(msg.target_chain, from_token_key, to_token_key, msg.amount);

        // Notify external entities
        let otx: OutgoingTransaction = OutgoingTransaction{
            amount:             msg.amount,
            to:                 msg.to,
            id:                 self.nonce,
            target_chain_id:    msg.target_chain,
            from_token:         msg.from_token,
            to_token:           msg.to_token
        };

        emit(otx.toCell());

    }

    receive(msg: JettonBurnNotification){
        // Check whether paused
        self.require_unpaused();

        require(
            msg.forward_payload != emptySlice(),
            "EmmetBridge: Burned with no bridge instructions"
        );

        // Extract the chain, from- & to- tokens
        let target_chain:   Int   = msg.forward_payload.loadUint(64);

        // Do nothing if the target chain is this one
        if(target_chain == self.chainId){return;}

        let from_token:     Cell  = msg.forward_payload.loadRef();
        let to:             Cell  = msg.forward_payload.loadRef();
        let to_token:       Cell  = msg.forward_payload.loadRef();

        let from_slice:     Slice = from_token.asSlice();
        let from_token_key: Int   = from_slice.loadUint(256);

        let to_slice:       Slice = to_token.asSlice();
        let to_token_key:   Int   = to_slice.loadUint(256);

        // Ensure the chain, from- & to- tokens are supported
        self.require_supported_credentials(target_chain, from_token_key, to_token_key);

        let token: Token? = self.tokens.get(from_token_key);

        let token_master: Address = token!!.address;

        require(token_master != newAddress(0,0), "EmmetBridge: JettonWallet not set");

        // estimate the fee
        let cross_chain_fees: Int = self._estimate_fee(
            target_chain,
            from_token_key,
            to_token_key
        );

        require(
            context().value >= cross_chain_fees + self.min_tx_fee / 2,
            "EmmetBridge: Insufficient fee"
        );

        require(
            context().sender == token_master,
            "EmmetBridge: Unauthorised Burn notification"
        );

        self.nonce += 1;

        // Notify external entities
        let otx: OutgoingTransaction = OutgoingTransaction{
            amount:             msg.amount,
            to:                 to,
            id:                 self.nonce,
            target_chain_id:    target_chain,
            from_token:         from_token,
            to_token:           to_token
        };

        emit(otx.toCell());
     }

    /// Notification from a Jetton Wallet (sendInstallment)
    receive(msg: TokenTransferNotification){
        // Check whether paused
        self.require_unpaused();

        // Do nothing if no instructions
        if(msg.forward_payload == emptySlice()){return;}

        let local: Cell? = msg.forward_payload.loadRef();

        // Do nothing if no instructions
        if(local == null){return;}

        let local_slice = local!!.asSlice();

        // Extract the chain, from- & to- tokens
        let target_chain:   Int   = local_slice.loadUint(64);

        // Do nothing if the target chain is this one
        if(target_chain == self.chainId){return;}

        let from_token:     Cell  = local_slice.loadRef();
        let to:             Cell  = local_slice.loadRef();
        let to_token:       Cell  = local_slice.loadRef();

        let from_slice:     Slice = from_token.asSlice();
        let from_token_key: Int   = from_slice.loadUint(256);

        let to_slice:       Slice = to_token.asSlice();
        let to_token_key:   Int   = to_slice.loadUint(256);

        // Ensure the chain, from- & to- tokens are supported
        self.require_supported_credentials(target_chain, from_token_key, to_token_key);

        // Ensure legitimate sender
        let token: Token? = self.tokens.get(from_token_key);
        require(context().sender == token!!.wallet, "EmmetBridge: Invalid Sender");

        // Switch the outgoing operations
        self.switch_outgoing(target_chain, from_token_key, to_token_key, msg.amount);
        
        // Notify external entities
        let otx: OutgoingTransaction = OutgoingTransaction{
            amount:             msg.amount,
            to:                 to,
            id:                 self.nonce,
            target_chain_id:    target_chain,
            from_token:         from_token,
            to_token:           to_token
        };

        emit(otx.toCell());

    }
}