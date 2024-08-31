import "@stdlib/deploy";
import "@stdlib/ownable";

struct Operation {
    date: Int;
    from_token_amont: Int as coins;
    swap_rate: Int as int16;
    rate_decimals: Int as uint32;
    transId: String;
    trans_query_id: Int as uint64;
    query_id: Int as uint64;
    forward_ton_amount: Int as coins;
}
message SwapSignature {
    operation: Operation;
    signature: Slice as bytes64;
    token_index: Int as int8;
    forward_payload: Slice as remaining;
}
message WithdrawToken {
    token_index: Int as int8;
    amount: Int as coins;
    query_id: Int as uint64;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}
struct SwapData {
    from_token_amont: Int as coins;
    amount: Int as coins;
    token_index: Int as int8;
    to: Address;
    transId: String;
    query_id: Int as uint64;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}
message UpdatePublicKey {
    publicKey: Int;
}
message UpdateSalt {
    newSalt: String;
}
message UpdateOwnerAddress {
    address: Address;
}
message UpdateServiceFeeRate {
    serviceFeeRate: Int as int16;
}
message UpdateJettonWalletAddress {
    token_index: Int as int8;
    address: Address;
}
message(0xf8a7ea5) TokenTransfer {
    query_id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; 
}
message(0xd53276db) TokenExcesses {
    query_id: Int as uint64;
}
contract UXUYSwapContract with Deployable {
    owner: Address;
    const MinTonForStorage: Int = ton("0.1");
    transIds: map<Int, Bool>;
    queryIds: map<Int, SwapData>;
    publicKey: Int as uint256;
    salt: String;
    tokenIndexToJettonWalletAddress: map<Int as int8, Address>;
    serviceFeeRate: Int as int16;
    formJettonWalletTokenIndex: Int as int8;
    init(owner: Address, publicKey: Int, salt: String) {
        self.owner = owner;
        self.publicKey = publicKey;
        self.salt = salt;
        self.serviceFeeRate = 0;
        self.formJettonWalletTokenIndex = 1;
    }
    receive() {}
    receive(msg: UpdateOwnerAddress) {
        require(sender() == self.owner, "Not owner");
        self.owner = msg.address;
        self.reply("Owner updated".asComment());
    }
    receive(msg: UpdatePublicKey) {
        require(sender() == self.owner, "Not owner");
        self.publicKey = msg.publicKey;
        self.reply("Public key has update".asComment());
    }
    receive(msg: UpdateSalt) {
        require(sender() == self.owner, "Not owner");
        self.salt = msg.newSalt;
        self.reply("Salt updated".asComment());
    }
    receive(msg: UpdateServiceFeeRate) {
        require(sender() == self.owner, "Not owner");
        self.serviceFeeRate = msg.serviceFeeRate;
        self.reply("Service fee rate updated".asComment());
    }
    receive(msg: UpdateJettonWalletAddress) {
        require(sender() == self.owner, "Not owner");
        self.tokenIndexToJettonWalletAddress.set(msg.token_index, msg.address);
        self.reply("Jetton_Wallet address has update".asComment());
    }
    receive("withdrawTONSafe"){
        let withdrawValue: Int = ((myBalance() - context().value) - self.MinTonForStorage);
        require(sender() == self.owner && withdrawValue > 0, "Not owner");
        send(SendParameters{
                to: sender(),
                bounce: true,
                value: withdrawValue,
                mode: (SendRemainingValue + SendIgnoreErrors)
            }
        );
    }
    receive(msg: WithdrawToken){
        let sender: Address = sender();
        require(sender() == self.owner, "Not owner");

        require(msg.amount > 0, "amount is zero");

        let jettonWalletAddress: Address? = self.tokenIndexToJettonWalletAddress.get(msg.token_index);
        require(jettonWalletAddress != null, "No such token");

        send(SendParameters{
            to: jettonWalletAddress!!,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: TokenTransfer{
                query_id: msg.query_id,
                amount: msg.amount,
                destination: sender,
                response_destination: sender,
                custom_payload: null,
                forward_ton_amount: msg.forward_ton_amount,
                forward_payload: msg.forward_payload
            }.toCell(),
        });
    }
    receive(msg: SwapSignature){
        let sender: Address = sender();
        let op: Operation = msg.operation;

        require(op.from_token_amont > 0, "amount is zero");

        let isTrans: Bool = self._existsTransId(op.transId);
        require(isTrans == false, "Exists transId");

        let fizz: StringBuilder = beginString();
        fizz.append("ton:swap:");
        fizz.append(op.date.toCoinsString());
        fizz.append(":");
        fizz.append(op.from_token_amont.toCoinsString());
        fizz.append(":");
        fizz.append(op.swap_rate.toString());
        fizz.append(":");
        fizz.append(op.rate_decimals.toString());
        fizz.append(":");
        fizz.append(op.transId);
        fizz.append(":");
        fizz.append(msg.token_index.toString());
        fizz.append(":");
        fizz.append(self.salt);
        let fizzStr: String = fizz.toString();
        let op_hash: Int = sha256(fizzStr);
        let isOk: Bool = checkSignature(op_hash, msg.signature, self.publicKey);
        require(isOk, "Signature is invalid");
        let amount = op.from_token_amont * op.swap_rate / op.rate_decimals;
        if (self.serviceFeeRate > 0) {
            amount = amount - amount * self.serviceFeeRate / 1000;
        }
        self.queryIds.set(op.trans_query_id, SwapData{
            from_token_amont: op.from_token_amont,
            amount: amount,
            token_index: msg.token_index,
            to: sender,
            transId: op.transId,
            query_id: op.query_id,
            forward_ton_amount: op.forward_ton_amount,
            forward_payload: msg.forward_payload
        });
        self.reply("Signature successful".asComment());
    }

    receive(msg: TokenExcesses) {
        let query_id = msg.query_id;
        let swapDataUnsure: SwapData? = self.queryIds.get(query_id);
        if (swapDataUnsure == null) {
            self.reply("Receive token".asComment());
        } else {
            let swapData = self.queryIds.get(query_id)!!;
            let jettonWalletAddress: Address? = self.tokenIndexToJettonWalletAddress.get(swapData.token_index);
            require(jettonWalletAddress != null, "No such token");

            self._setTransId(swapData.transId);

            send(SendParameters{
                to: jettonWalletAddress!!,
                value: 0,
                mode: SendRemainingValue,
                bounce: true,
                body: TokenTransfer{
                    query_id: swapData.query_id,
                    amount: swapData.amount,
                    destination: swapData.to,
                    response_destination: swapData.to,
                    custom_payload: null,
                    forward_ton_amount: swapData.forward_ton_amount,
                    forward_payload: swapData.forward_payload
                }.toCell(),
            });
        }
    } 

    fun _existsTransId(transId: String): Bool {
        let shaInt: Int = sha256(transId);
        let isIn: Bool? = self.transIds.get(shaInt);
        if (isIn == true) {
            return true;
        } else {
            return false;
        }
    }
    fun _setTransId(transId: String) {
        let shaInt: Int = sha256(transId);
        self.transIds.set(shaInt, true);
    }
    get fun existsTransId (transId: String): Bool {
        return self._existsTransId(transId);
    }
    get fun getPublicKey (): Int {
        return self.publicKey;
    }
    get fun getOwnerAddress (): Address {
        return self.owner;
    }
    get fun get_swap_data(query_id: Int): SwapData? {
        return self.queryIds.get(query_id);
    }
}
