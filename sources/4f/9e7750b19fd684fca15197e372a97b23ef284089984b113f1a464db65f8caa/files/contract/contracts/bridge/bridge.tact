import "@stdlib/deploy";
import "../token/jetton-wallet.tact";
import "../token/jetton-dynasty.tact";
import "../token/wrapped.tact";
import "../utils/access_control.tact";
import "./storage.tact";
import "./utils.tact";
import "./bridge-messages";

contract Bridge with Deployable, BridgeUtils, AccessControl {
    // Nonce of the transaction handled.
    nonce: Int;
    // ID of the native coin on the chain {TON}.
    native_coin: Int;
    // Total Fees collected by the contract until now
    fees: Int;
    // Total Value Locked inside the contract.
    TVL: Int;
    // Nonce of the current chain {TON}
    chain_nonce: Int;
    // Mapping to handle incoming installments so as to avoid collision or duplicate transactions.
    incoming: map<Int, IncomingTransaction>;
    // Mapping to handle outgoing installments so as to avoid collision or duplicate transactions.
    outgoing: map<Int, OutgoingTransaction>;
    // Mapping of Native Token ID to its Token Inforamation.
    tokens: map<Int, Token>;
    // From Token -> Struct {  i: Target Token -> Steps  }
    incoming_token_strategy: map<Int, FromTokenToTargetTokenToSteps>;
    // Target Chain -> Struct { i: From Token -> Struct { i: Target Token -> CrossChainStrategy } } }
    cross_chain_token_storage: map<Int, FromTokenToTargetTokenToCrossChainStrategy>;
    default_admin_role: Address;
    roles: map<Int, RoleData>;
    // A Mapping that stores all the information about the chain fees to different destination chains.
    chain_fees: map<Int, Int>;
    // State variable that represents the state of the bridge contract. ie paused or unpaused.
    paused: Bool;
    // The address of the burner contract.
    burner: Address;
    // Metadata base uri
    base_uri: String;
    // transfer fee for each transfer of TON
    transfer_fee: Int;
    // Protocol Fee
    protocol_fee: Int;
    // Validator Roles
    validators: map<Int, Address>;
    validators_count: Int;
    threshold: Int;

    /**
     * This is the constructor of the contract.
     * chain_nonce :- The nonce for this chain assigned in the bridge infrastructure.
     * native_coin :- The id of the native coin {TON}
     * burner :- Address of the burner contract that can call the JettonBurnNotification endpoint on this contract
     */
    init(chain_nonce: Int, native_coin: Int, burner: Address, base_uri: String, transfer_fee: Int, protocol_fee: Int, bootstrap_validator_key: Int, bootstrap_validator_address: Address){
        self.nonce = 0;
        self.chain_nonce = chain_nonce;
        self.paused = false;
        self.native_coin = native_coin;
        self.fees = 0;
        self.TVL = 0;
        self.burner = burner;
        self.base_uri = base_uri;
        self.transfer_fee = transfer_fee;
        self.protocol_fee = protocol_fee;
        self.default_admin_role = context().sender;
        self.validators_count = 1;
        self.threshold = 1;
        self.validators.set(bootstrap_validator_key, bootstrap_validator_address);
        self._grant_role(self.manager_role_id(), context().sender);
        self._grant_role(self.cfo_role_id(), context().sender);
        self._grant_role(self.admin_role_id(), context().sender);
        self._grant_role(self.signer_role_id(), context().sender);
        self._grant_role(self.signer_role_id(), bootstrap_validator_address);
        self._grant_role(self.admin_role_id(), bootstrap_validator_address);
    }

    /**
     * The endpoint must be called when some jetton are transferred to the contract.
     * We expect the forward payload to have the token id, target Address wrapped in a cell.
     */
    receive(msg: JettonTransferNotification){
        self.require_unpaused();
        let target_chain: Int = msg.forward_payload.loadUint(64);
        let fees: Int? = self.chain_fees.get(target_chain);
        require(fees != null, "Fees not configured for this chain");
        require(context().value >= (fees!! + self.protocol_fee), "Insufficient fee coverage.");
        self.nonce += 1;
        let from_token: Cell = msg.forward_payload.loadRef();
        let to: Cell = msg.forward_payload.loadRef();
        let to_token: Cell = msg.forward_payload.loadRef();
        let ftks: Slice = from_token.asSlice();
        let from_token_id: Int = ftks.loadUint(256);
        let from_token_info_opt: Token? = self.tokens.get(from_token_id);
        require(from_token_info_opt != null, "Invalid token sent");
        let from_token_info: Token = from_token_info_opt!!;
        require(from_token_info.token_bridge_wallet_address == context().sender, "Incorrect Token Specified in arguments");
        let otx: OutgoingTransaction = OutgoingTransaction{
            amount: msg.amount,
            to: to,
            id: self.nonce,
            target_chain_id: target_chain,
            from_token: from_token,
            to_token: to_token
        };
        let tx_hash: Int = otx.toCell().hash();
        self.outgoing.set(tx_hash, otx);
        emit(SentInstallment{tx_hash: tx_hash}.toCell());
    }

    /**
     * The endpoint gets called by the burner contract, that, is another contract which transfers some tokens * to itself and forwards this message to our bridge contract.
     * The forward payload must have token_id, target address (wrapped in a cell).
     */
    receive(msg: JettonBurnNotification){
        require(self.burner == context().sender, "Only Burner Can Call this Method");
        self.require_unpaused();
        let target_chain: Int = msg.forward_payload.loadUint(64);
        let fees: Int? = self.chain_fees.get(target_chain);
        require(fees != null, "Fees not configured for this chain");
        require(context().value >= (fees!! + self.protocol_fee), "Insufficient fee coverage.");
        self.nonce += 1;
        let token_id: Cell = msg.forward_payload.loadRef();
        let to: Cell = msg.forward_payload.loadRef();
        let to_token: Cell = msg.forward_payload.loadRef();
        let otx: OutgoingTransaction = OutgoingTransaction{
            amount: msg.amount,
            to: to,
            id: self.nonce,
            target_chain_id: target_chain,
            from_token: token_id,
            to_token: to_token
        };
        let tx_hash: Int = otx.toCell().hash();
        self.outgoing.set(tx_hash, otx);
        emit(SentInstallment{tx_hash: tx_hash}.toCell());
    }

    /**
     * This message is called by end user when the contract wants to send some native coing {TON} to
     * another address on the chain.
     */
    receive(msg: FreezeTon){
        self.require_unpaused();
        self.nonce += 1;
        let otx: OutgoingTransaction = OutgoingTransaction{
            amount: msg.amount,
            to: msg.to,
            id: self.nonce,
            target_chain_id: msg.target_chain,
            from_token: msg.from_token,
            to_token: msg.to_token
        };
        let tx_hash: Int = otx.toCell().hash();
        let fees: Int? = self.chain_fees.get(msg.target_chain);
        require(fees != null, "Fees not configured for this chain");
        require(context().value >= ((fees!! + msg.amount) + self.protocol_fee), "Insufficient fee coverage.");
        self._accept_native_coins(msg.amount);
        self.outgoing.set(tx_hash, otx);
        emit(SentInstallment{tx_hash: tx_hash}.toCell());
    }

    /**
     * This endpoint is used to add native contract mapping into the bridge.
     * Can only be called by an address who has the mapping admin role.
     */
    receive(msg: MapContract){
        self.only_role(self.manager_role_id());
        self._map_contract(msg.token_symbol, msg.contract, msg.decimals, msg.token_id,msg.swap_address, msg.fee, msg.fee_decimals, msg.token_bridge_wallet_address);
    }

    receive(msg: RemoveMappedContract){
        self.only_role(self.manager_role_id());
        self.tokens.set(msg.token_id, null);
    }

    /**
     * Withdraw Fees can only be called the an address who has the withdrawer role.
     * This withdraws all the fees to the caller of the contract.
     */
    receive("WithdrawFees"){
        self.only_role(self.cfo_role_id());
        self.withdraw_fees();
    }

    /**
     * ReceiveInstallment is the endpoint in which the contracts, transfers native coins as per the info
     * received in the message, or transfers native token in case of a native token, or mints wrapped token
     * in case of wrapped token ID recieved in the message.
     */
    receive(msg: ReceiveInstallment){
        self.only_role(self.signer_role_id());        
        self.require_unpaused();
        require(self.incoming.get(msg.tx_hash) == null, "Transaction already submitted");
        require(msg.installment.target_chain == self.chain_nonce, "Wrong chainId");
        let from_token_slice: Slice = msg.installment.from_token.asSlice();
        let tidint: Int = from_token_slice.loadUint(256);
        let to_token_slice: Slice = msg.installment.to_token.asSlice();
        let target_tidint: Int = to_token_slice.loadUint(256);
        let hash: Int = msg.installment.toCell().hash();
        self.verify_signatures(hash, msg.signatures, msg.len);

        self._select_incoming_action(msg.installment.from_chain, tidint, target_tidint, msg.installment.recepient, msg.installment.amount);
        // let tt: TokenType = self._which_token_type(tidint);
        // if (!(tt.is_native_coin) && !(tt.is_native_token) && !(tt.is_wrapped_token)) {
        //     self._deploy_wrapped_contract(tidint);
        //     tt.is_wrapped_token = true;
        // }
        // if (tt.is_native_coin) {
        //     self._transfer_native_coins(msg.installment.recepient, msg.installment.amount);
        // }
        // if (tt.is_native_token) {
        //     self._transfer_native_tokens(msg.installment.recepient, msg.installment.amount, tidint);
        // }
        // if (tt.is_wrapped_token) {
        //     self._mint_wrapped_tokens(msg.installment.recepient, msg.installment.amount, tidint);
        // }
        let itx: IncomingTransaction =  IncomingTransaction{
            id: msg.id,
            amount: msg.installment.amount,
            from_token: msg.installment.from_token,
            to_token: msg.installment.to_token,
            target_chain_id: msg.installment.target_chain,
            to: msg.installment.recepient
        };
        self.incoming.set(msg.tx_hash, itx);
        emit(ReceivedInstallment{tx_hash: msg.tx_hash}.toCell());
    }

    /**
     * This endpoint can be used to set the chain fee for a particular destionation chain.
     * Can only be called by an address which has the mapping admin role.
     */
    receive(msg: SetChainFee){
        self.only_role(self.manager_role_id());
        self.chain_fees.set(msg.chain_id, msg.fee);
    }

    /**
     * Empty callback to handle the JettonExcesses message that is sent by the Jetton Wallet Contract
     * Address sometimes.
     */
    receive(msg: JettonExcesses){}

    receive(msg: UpdateProtocolFee){
        self.only_role(self.manager_role_id());
        self.set_protocol_fee(msg.new_fee);
    }

    receive(msg: UpdateBaseUri){
        self.only_role(self.manager_role_id());
        self.base_uri = msg.new_base_uri;
    }

    receive(msg: UpdateTransferFee){
        self.only_role(self.manager_role_id());
        self._set_transfer_fee(msg.new_fee);
    }

    receive (msg: AddValidator) {
        self.only_role(self.manager_role_id());
        self.validators.set(msg.key, msg.address);
        self.validators_count += 1;
        self.threshold = (self.validators_count * 2) / 3 + 1;
    }

    receive (msg: RemoveValidator) {
        self.only_role(self.manager_role_id());
        self.validators.set(msg.key, null);
        self.validators_count -= 1;
        self.threshold = (self.validators_count * 2) / 3 + 1;
    }


    receive (msg: SetIncomingStrategy) {
        self.only_role(self.manager_role_id());
        self.set_incoming_strategy(msg.from_chain, msg.from_token, msg.target_token, msg.steps);
    }

    receive (msg: SetCrossChainStrategy) {
        self.only_role(self.manager_role_id());
        self.set_cross_chain_strategy(msg.target_chain, msg.from_token, msg.target_token, msg.local_steps, msg.foreign_steps);
    }

    receive (msg: RemoveCrossChainStrategy) {
        self.only_role(self.manager_role_id());
        self.delete_cross_chain_strategy(msg.target_chain, msg.from_token, msg.target_token);
    }

     receive (msg: RemoveInternalStrategy) {
        self.only_role(self.manager_role_id());
        self.delete_internal_strategy(msg.from_chain, msg.from_token, msg.target_token);
    }

    /**
     * Empty message handler to just receive some native currency {TON}
     */
    receive(){}

    get fun manager_role_id(): Int {
        return sha256("MANAGER_ROLE");
    }

    get fun signer_role_id(): Int {
        return sha256("SIGNER_ROLE");
    }

    get fun cfo_role_id(): Int {
        return sha256("CFO_ROLE");
    }

    inline fun require_unpaused(){
        require(!self.paused, "Contract is paused");
    }

    fun verify_signatures(hash: Int, sigs: map<Int, SignerAndSignature>, len: Int) {
        let counter: Int = 0;
        repeat(len) {
            let sig: SignerAndSignature = sigs.get(counter)!!;
            if (self.validators.get(sig.key) != null) {
            let ok: Bool = checkSignature(hash, sig.signature, sig.key);
            counter += 1;
            }
        }
        require(counter >= self.threshold, "Threshold not reached.");
    }

    receive("Pause") {
        require(!self.paused, "Pausable: Contract is already paused");
        self.only_role(self.manager_role_id());
        self.paused = true;
    }

    receive("Unpause") {
        require(!self.paused, "Pausable: Contract is already unpaused");
        self.only_role(self.manager_role_id());
        self.paused = false;
    }
}
message UpdateProtocolFee {
    new_fee: Int;
}

message AddValidator {
    key: Int;
    address: Address;
}

message RemoveValidator {
    key: Int;
}

message SetIncomingStrategy {
    from_chain: Int;
    from_token: Int;
    target_token: Int;
    steps: Steps;
}
message SetCrossChainStrategy {
    target_chain: Int;
    from_token: Int;
    target_token: Int;
    local_steps: Steps;
    foreign_steps: Steps;
}

message RemoveInternalStrategy {
    from_chain: Int;
    from_token: Int;
    target_token: Int;
}

message RemoveCrossChainStrategy {
    target_chain: Int;
    from_token: Int;
    target_token: Int;
}