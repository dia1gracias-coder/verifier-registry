import "./storage.tact";
import "./emmet-token-strategy";
import "../token/wrapped.tact";
struct TokenType {
    is_native_coin: Bool;
    is_native_token: Bool;
    is_wrapped_token: Bool;
}
trait BridgeUtils with Storage, EmmetTokenStrategy {
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
    // Mapping of Token ID to its Token Inforamation.
    tokens: map<Int, Token>;
    // From Token -> Struct {  i: Target Token -> Steps  }
    incoming_token_strategy: map<Int, FromTokenToTargetTokenToSteps>;
    // Target Chain -> Struct { i: From Token -> Struct { i: Target Token -> CrossChainStrategy } } }
    cross_chain_token_storage: map<Int, FromTokenToTargetTokenToCrossChainStrategy>;
    // A Mapping that stores all the information about the chain fees to different destination chains.
    chain_fees: map<Int, Int>;
    // Metadata baseurl
    base_uri: String;
    // transfer fees
    transfer_fee: Int;
    // Protocol Fee
    protocol_fee: Int;
    // Default Admin Role
    default_admin_role: Address;

    /**
    * Internal function to generate a cross chain tx id which is basically a sha256({chain_nonce}-{to_chain_id}-{nonce}). It should unique for each
    * transaction
    */
    inline fun _generate_cross_chain_tx_id(to_chain_id: Int): Int {
        require(to_chain_id != self.chain_nonce && to_chain_id != 0, "Target chainId cannot equal native or zero");
        let builder: StringBuilder = beginString();
        builder.append(self.chain_nonce.toString());
        builder.append("-");
        builder.append(to_chain_id.toString());
        builder.append("-");
        builder.append(self.nonce.toString());
        return sha256(builder.toString());
    }

    inline fun _set_transfer_fee(new_fee: Int) {
        self.transfer_fee = new_fee;
    }

    /**
    * Checks whether the tx_id is unique or not. else reverts with the error.
    */
    inline fun _is_unsubmitted(tx_id: Int) {
        require(self.incoming.get(tx_id) == null, "Previously Processed Transaction.");
    }

    /**
    * Internal function to check the token type of the token id passed as the argument to this chain.
    */
    inline fun _select_incoming_action(from_chain_id: Int, from_token: Int, target_token: Int, recepient: Address, amount: Int) {
        let path: Steps = self.get_incoming_strategy(from_chain_id, from_token, target_token);
        let counter: Int = 0;

        repeat(path.size) {
            let step: Int = path.steps.get(counter)!!;
            if (step == UNLOCK) {
                if (target_token == self.native_coin()) {
                    self._transfer_native_coins(recepient, amount);
                } else {
                    self._transfer_native_tokens(recepient, amount, target_token);
                }
            } else if (step == MINT) {
                self._mint_wrapped_tokens(recepient, amount, target_token);
            } else {
                counter +=1;
            }
        }
    }

    /**
    * Internal function to accept native coins inside the bridge contract. Increments the TVL and fees with the amount passed.
    */
    inline fun _accept_native_coins(amount: Int) {
        // If sent less tokens than is asking to transfer
        require(context().value >= amount, "Insufficient funds Provided");
        // Update the TVL
        self.TVL += amount;
        // Update the fees
        self.fees = self.fees + amount;
    }

    /**
    * Transfers the native coins to `to` Address with amount. Decrements the TVL.
    */
    inline fun _transfer_native_coins(to: Address, amount: Int) {
        require(myBalance() - context().value > amount, "Insufficient Funds");
        self.TVL -= amount;
        send(SendParameters{value: amount, to: to, body: "From Emmet.Finance Bridge".asComment(),  bounce: true, mode: SendPayGasSeparately});
    }

    /**
    * Internal function to deploy a wrapped contract for a token id that is provided in the arguments.
    */
    inline fun _deploy_wrapped_contract(token_id: Int) {
        let off_chain_uri: StringBuilder = beginString();
        off_chain_uri.append(self.base_uri);
        off_chain_uri.append(token_id.toString());

        let init: StateInit = initOf WrappedJetton(self.default_admin_role ,myAddress(), beginCell().storeInt(0x01, 8).storeRef(off_chain_uri.toCell()).endCell());
        let address: Address = contractAddress(init);
        self.tokens.set(token_id, Token{address: address, decimals: 9, symbol: "em.", swap_address: address("0QAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACkT"), fee: 0, fee_decimals: 0, token_bridge_wallet_address: contractAddress(initOf WrappedJettonWallet(myAddress(), address)) });
        send(SendParameters{
                to: address,
                value: ton("0.05"), // pay for message, the deployment and give some TON for storage
                code: init.code, // attaching the state init will cause the message to deploy
                data: init.data,
                // body: "identify".asComment(), // we must piggyback the deployment on another message
                bounce: true,
                mode: SendBounceIfActionFail
            }
        );
    }

    /**
    * Internal function to add a new contract to the native contracts mapping.
    */
    inline fun _map_contract(symbol: String, contract: Address, decimals: Int, token_id: Int, swap_address: Address, fee: Int, fee_decimals: Int, token_bridge_wallet_address: Address) {
      self.tokens.set(token_id, Token {address: contract, decimals: decimals, swap_address: swap_address, fee: fee, fee_decimals: fee_decimals, symbol: symbol, token_bridge_wallet_address: token_bridge_wallet_address });
    }
    /**
    * Internal function to transfer native tokens with the {token_id} to the {to} address with an amt {amount}
    */
    inline fun _transfer_native_tokens(to: Address, amount: Int, token_id: Int) {
        let opt_token: Token? = self.tokens.get(token_id);
        require(opt_token != null, "Invalid native token id provided");
        // Force non null assertion because we have already checked for null case
        let token: Token = opt_token!!;

        send(SendParameters {
            to: token.token_bridge_wallet_address,
            body: TokenTransfer {
                amount: amount,
                sender: to,
                response_destination: to,
                custom_payload: null,
                forward_ton_amount: 0,
                forward_payload: beginCell().storeSlice("Unlocked from Emmet.finance Bridge".asSlice()).asSlice(),
                query_id: 0
            }.toCell(),
            value: self.transfer_fee,
            bounce: true
        });
    }
        /**
        Internal function to mint wrapped tokens {to} address with amt {amount} and token_id being {token_id}.
        */
        inline fun _mint_wrapped_tokens(to: Address, amount: Int, token_id: Int) {
        let opt_token: Token? = self.tokens.get(token_id);
        require(opt_token != null, "Invalid wrapped token id provided");
        // Force non null assertion because we have already checked for null case
        let token: Token = opt_token!!;
        send(SendParameters {
            to: token.address,
            body: JettonMint {
                origin: myAddress(),
                receiver: to,
                amount: amount,
                custom_payload: null,
                forward_ton_amount: 0,
                forward_payload: beginCell().asSlice()
            }.toCell(),
            value: ton("0.08"),
            bounce: true
        });
    }

    /**
    * Internal function to withdraw the amount of fees. The fees must not be zero.
    */
    inline fun withdraw_fees() {
      require(self.fees > 0, "No fees to withdraw");
      send(SendParameters{
        to: context().sender,
        value: 0,
        mode: SendRemainingBalance,
        bounce: true
      });
      self.fees = 0;
    }
}

message(0xf8a7ea5) TokenTransfer {
    query_id: Int as uint64;
    amount: Int as coins;
    sender: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; 
}
