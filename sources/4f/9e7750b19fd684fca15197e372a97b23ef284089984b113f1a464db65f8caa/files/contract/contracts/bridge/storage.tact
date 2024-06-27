import "./bridge-messages.tact";
trait Storage {
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
    // A Mapping that stores all the information about the chain fees to different destination chains.
    chain_fees: map<Int, Int>;
    // Metadata baseurl
    base_uri: String;
    // Protocol Fee
    protocol_fee: Int;
    default_admin_role: Address;

    get fun base_uri(): String {
        return self.base_uri;
    }

    get fun protocol_fee(): Int {
        return self.protocol_fee;
    }

    inline fun set_protocol_fee(new_fee: Int) {
        self.protocol_fee = new_fee;
    }

    /**
     * Getter function to get the current tx nonce of the bridge contract.
     */

    get fun nonce(): Int {
        return self.nonce;
    }
    /**
     * Getter function to get the id of the native coin on the chain {TON}
     */

    get fun native_coin(): Int {
        return self.native_coin;
    }
    /**
     * Getter function to get total fees stored inside the contract.
     */

    get fun fees(): Int {
        return self.fees;
    }

    /**
     * Getter function to get the total value locked inside the contract.
     */

    get fun TVL(): Int {
        return self.TVL;
    }

    /**
     * Getter function to get the chain nonce of the current chain
     */

    get fun chain_nonce(): Int {
        return self.chain_nonce;
    }

    /**
     * Getter function to get all the incoming txs informations stored inside the bridge contract.
     */

    get fun incoming(): map<Int, IncomingTransaction> {
        return self.incoming;
    }

    /**
     * Getter function to get all the outgoing txs informations stored inside the bridge contract.
     */

    get fun outgoing(): map<Int, OutgoingTransaction> {
        return self.outgoing;
    }

    /**
     * Getter function to get all the native tokens inside the bridge contract
     */

    get fun tokens(): map<Int, Token> {
        return self.tokens;
    }

    /**
     * Getter function to get the chain fees mapping stored inside the contract.
     */

    get fun chain_fees(): map<Int, Int> {
        return self.chain_fees;
    }
}