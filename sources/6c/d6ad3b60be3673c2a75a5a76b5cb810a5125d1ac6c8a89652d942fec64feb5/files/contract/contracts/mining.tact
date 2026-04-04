import "./imports/messages";
import "./jetton";
import "@stdlib/deploy";


contract Mining with Deployable {

    owner: Address;
    signerPubKey: Int as uint256;
    jettonWallet: Address;

    paused: Bool;
    maxClaimAmount: Int as uint64;

    lastUserNonce: map<Address, Int as uint64>;

    init(
        owner: Address,
        signerPubKey: Int as uint256,
        jettonMaster: Address,
        maxClaimAmount: Int as uint64
    ) {
        self.owner = owner;
        self.signerPubKey = signerPubKey;
        self.paused = false;
        self.maxClaimAmount = maxClaimAmount;

        let winit: StateInit = initOf JettonDefaultWallet(jettonMaster, myAddress());
        self.jettonWallet = contractAddress(winit);
    }

    receive(msg: SetJettonWallet) {
        require(sender() == self.owner, "Not owner");
        self.jettonWallet = msg.jettonWallet;
    }

    receive(msg: TokenExcesses) {
    // ignore
    }   

    receive(msg: Claim) {

        require(!self.paused, "Paused");

        let amount: Int = msg.amount;
        let nonce: Int = msg.nonce;
        let deadline: Int = msg.deadline;
        let signature: Slice = msg.signature;
        let user = sender();
        let opt = self.lastUserNonce.get(user);
        let lastNonce: Int = opt != null ? opt!! : 0;
        require(msg.rewardId != null, "Invalid rewardId");
        require(msg.nonce == lastNonce + 1, "Invalid nonce order");

        require(amount > 0, "Zero amount");
        require(amount <= self.maxClaimAmount, "Exceed max");
        require(now() <= deadline, "Expired");

        let payload = beginCell()
            .storeAddress(sender())
            .storeUint(amount, 64)
            .storeUint(nonce, 64)
            .storeUint(deadline, 64)
        .endCell();

        require(
            checkSignature(payload.hash(), signature, self.signerPubKey),
            "Invalid sig"
        );
        self.lastUserNonce.set(sender(), msg.nonce);
        self._transferJetton(sender(), amount, msg.nonce, msg.rewardId!!);
    }

    fun _transferJetton(to: Address, amount: Int, nonce: Int?, rewardId: String) {

        let body = beginCell()
            .storeUint(0xf8a7ea5, 32)
            .storeUint(nonce == null ? 0 : nonce!!, 64)
            .storeCoins(amount)
            .storeAddress(to)
            .storeAddress(myAddress())
            .storeBit(false) 
            .storeCoins(ton("0.01"))
            .storeBit(false)  
            .storeUint(0, 32) 
            .storeSlice(rewardId.asSlice())
            .endCell();

        message(MessageParameters{
            to: self.jettonWallet,
            bounce: true,
            value: 0,
            mode: SendRemainingValue,
            body: body
        });
    }

    receive(msg: Excesses) {} 

    receive(msg: AdminWithdraw) {
        require(sender() == self.owner, "Not owner");
        self._transferJetton(self.owner, msg.amount, null, "1");
    }

    receive(msg: Withdraw) {
        require(sender() == self.owner, "Not owner");

        message(MessageParameters{
            to: self.owner,
            value: msg.amount,
            bounce: false
        });
    }

    receive(msg: Pause) {
        require(sender() == self.owner, "Not owner");
        self.paused = true;
    }

    receive(msg: Unpause) {
        require(sender() == self.owner, "Not owner");
        self.paused = false;
    }

    receive(msg: SetMaxClaim) {
        require(sender() == self.owner, "Not owner");
        self.maxClaimAmount = msg.newMax;
    }

    receive(msg: RotateSigner) {
        require(sender() == self.owner, "Not owner");
        self.signerPubKey = msg.newKey;
    }

    get fun next_nonce(user: Address): Int {
        let nonce = self.lastUserNonce.get(user) ;
        return (nonce == null ? 0 : nonce!!) + 1;
    }

    get fun status(): ContractStatus {
        return ContractStatus{
            owner: self.owner,
            jettonWallet: self.jettonWallet,
            paused: self.paused,
            maxClaimAmount: self.maxClaimAmount
        };
    }
}