import "@stdlib/deploy";
import "./messages/admin.tact";
import "./messages/cfo.tact";
import "./storage.tact";

trait BridgeAdmin with Deployable, Storage {

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

    receive(){
        self.TVL = myBalance();
    }

    //********************************************//
    //              Admin functions               //
    //********************************************//

    receive(msg: DeleteChain) {
        self.only_admin();
        self.delete_chain(msg.chain_id);
        emit(msg.toCell());
    }

    receive(msg: DeleteModule){
        self.only_admin();
        self.delete_module(msg.step);
        emit(msg.toCell());
    }

    receive(msg: DeleteStategies) {
        self.only_admin();
        self.delete_strategies(
            msg.chain_id,
            msg.from_token,
            msg.to_token
        );
        emit(msg.toCell());
    }

    receive(msg: DeleteToken) {
        self.only_admin();
        self.delete_token(msg.symbol);
        emit(msg.toCell());
    }

    receive(msg: DeleteValidator){
        self.only_admin();
        self.delete_validator(msg.candidate);
        self._revoke_role(self.validator_role_id(), msg.candidate);
        emit(msg.toCell());
    }

    // ============ S E T T E R S ============ //

    receive(msg: Pause){
        self.only_admin();
        self.pause();
        emit(beginCell().storeSlice("Paused".asSlice()).endCell());
    }

    receive(msg: SetAdmin) {
        self.only_admin();
        self._grant_role(self.admin_role_id(), msg.newAdmin);
        self._revoke_role(self.admin_role_id(), self.admin);
        self.admin = msg.newAdmin;
        emit(msg.toCell());
    }

    receive(msg: SetChain) {
        self.only_admin();
        self.set_chain(msg.name, msg.chain_id);
        emit(msg.toCell());
    }

    receive(msg: SetCFO) {
        self.only_admin();
        self._grant_role(self.cfo_role_id(), msg.newCFO);
        self._revoke_role(self.cfo_role_id(), self.cfo);
        self.cfo = msg.newCFO;
        emit(msg.toCell());
    }

    receive(msg: SetModule) {
        self.only_admin();
        self.set_module(msg.step, msg.module);
        emit(msg.toCell());
    }

    receive(msg: SetStrategies) {
        self.only_admin();
        self.set_strategies(
            msg.chain_id,
            msg.from_token,
            msg.to_token,
            msg.foreign,
            msg.incomming,
            msg.local
        );
        emit(msg.toCell());
    }

    receive(msg: SetToken) {
        self.only_admin();
        self.set_token(
            msg.address, 
            msg.decimals, 
            msg.emmet_lp,
            msg.symbol,
            msg.swap_pool,
            msg.swap_router,
            msg.wallet
        );
        emit(msg.toCell());
    }

    receive(msg: SetValidator) {
        self.only_admin();
        self.set_validator(msg.candidate);
        self._grant_role(self.validator_role_id(), msg.candidate);
        emit(msg.toCell());
    }

    receive(msg: Unpause){
        self.only_admin();
        self.unpause();
        emit(beginCell().storeSlice("Unpaused".asSlice()).endCell());
    }

    //********************************************//
    //               CFO functions                //
    //********************************************//

    receive(msg: UpdateChainFee) {
        self.only_cfo();
        self.set_step_fee(msg.chain_id, msg.strategy_step, msg.gas_amount);
        emit(msg.toCell());
    }

    receive(msg: UpdateConsensusFee) {
        self.only_cfo();
        self.set_consensus_fee(msg.amount);
        emit(msg.toCell());
    }

    receive(msg: UpdateMinimumTxFee) {
        self.only_cfo();
        self.set_min_tx_fee(msg.amount);
        emit(msg.toCell());
    }

    receive(msg: UpdateProtocolFee) {
        self.only_cfo();
        self.set_protocol_fee(msg.amount);
        emit(msg.toCell());
    }

    receive(msg: WithdrawGas){
        self.only_cfo();

        let amount: Int = myBalance() >= msg.amount
            ? msg.amount
            : myBalance();

        // Transfer TON
        send(SendParameters{
            to:         self.cfo,
            value:      amount,
            mode:       SendRemainingValue,
            bounce:     false
        });

        self.TVL = myBalance();

        emit(msg.toCell());
    }

}