import "@stdlib/ownable";
import "@stdlib/deploy";
import "./structs.tact";

contract AttestParent with OwnableTransferable, Deployable {
    const MIN_TONS_FOR_STORAGE: Int = ton("0.01");
    const GAS_CONSUMPTION: Int = ton("0.01");

    owner: Address;
    initOwner: Address;
    publicKey: Int as uint256;
    initPublicKey: Int as uint256;
    attestFee: Int = ton("0.2");

    init(owner: Address, publicKey: Int) {
        self.owner = owner;
        self.initOwner = owner;
        self.initPublicKey = publicKey;
        self.publicKey = publicKey;
    }

    receive(msg: ChangePublicKey) {
        self.requireOwner();
        self.publicKey = msg.publicKey;
        self.reply(ChangePublicKeyOk {
        queryId: msg.queryId}.toCell())
    }

    receive("fund") {}

    receive(msg: AttestRequest) {
        require(msg.media >= 0, "Invalid media");
        self.checkSign(msg);
        self.checkTon(false);
        self.attest(msg.queryId, msg.media, msg.response_destination, msg.update);
    }

    receive(msg: ChangeAttestFee) {
        self.requireOwner();
        require(msg.attestFee >= 0, "Invalid attest fee");
        self.attestFee = msg.attestFee;
        self.reply(ChangeAttestFeeOk{
        queryId: msg.queryId
        }.toCell());
    }

    receive(msg: Withdraw) {
        self.requireOwner();
        require(myBalance() - msg.amount - context().value > self.MIN_TONS_FOR_STORAGE, "Invalid amount");
        send(
        SendParameters{
        to: sender(),
        bounce: true,
        value: msg.amount
        }
        )
    }

    fun checkTon(update: Bool) {
        let minGasToUse = self.getMinGasToUseFromMain(update);
        require(context().value > minGasToUse + self.attestFee, "Invalid value");
    }

    fun getMinGasToUseFromMain(update: Bool): Int {
        let ctx: Context = context();
        let fwdFee = ctx.readForwardFee() * 2;
        let storageFee = update ? 0 : self.MIN_TONS_FOR_STORAGE;
        let finalFee = 2 * self.GAS_CONSUMPTION + storageFee + fwdFee;
        return min(finalFee, ton("0.1"));
    }

    fun doCheckSign(msg: AttestRequest): Bool {
        let data = beginCell()
        .storeUint(msg.media, 8)
        .storeUint(msg.seed, 64)
        .endCell()
        .asSlice();
        return checkDataSignature(data, msg.sign, self.publicKey);
    }

    fun checkSign(msg: AttestRequest) {
        require(self.doCheckSign(msg), "Invalid sign");
    }

    get fun signResult(msg: AttestRequest): Bool {
        return self.doCheckSign(msg);
    }

    fun attest(queryId: Int, media: Int, response_destination: Address?, update: Bool) {
        let ctx: Context = context();
        let sinit: StateInit = initOf AttestChild(myAddress(), ctx.sender);
        let toAddress: Address = contractAddress(sinit);

        send(SendParameters{
        to: toAddress,
        value: ton("0.1"),
        bounce: false,
        mode: SendIgnoreErrors,
        body: AttestInternal {
        queryId: queryId,
        media: media,
        address: ctx.sender,
        update: update,
        response_destination: response_destination
        }.toCell(),
        code: sinit.code,
        data: sinit.data
        });
    }

    fun getChildAddress(owner: Address): Address {
        let ctx: Context = context();
        let sinit: StateInit = initOf AttestChild(myAddress(), owner);
        return contractAddress(sinit);
    }

    get fun attest_parent_data(withCode: Bool): AttestParentData {
        let code: Cell? = withCode ? initOf AttestParent(self.owner, self.publicKey).code : null;
        return AttestParentData{
        owner: self.owner,
        initOwner: self.initOwner,
        publicKey: self.publicKey,
        initPublicKey: self.initPublicKey,
        attestFee: self.attestFee,
        code: code
        }
    }

    get fun attest_child(owner: Address): Address {
        return self.getChildAddress(owner);
    }

    get fun public_key(): Int {
        return self.publicKey;
    }

    get fun init_public_key(): Int {
        return self.initPublicKey;
    }

    get fun init_owner(): Address {
        return self.initOwner;
    }

    get fun balance(): String {
        return myBalance().toCoinsString();
    }

}

contract AttestChild with Ownable {

    const MIN_TONS_FOR_STORAGE: Int = ton("0.01");
    const GAS_CONSUMPTION: Int = ton("0.01");

    owner: Address;
    master: Address;
    media: Int;
    attestTime: Int as uint32;

    init(master: Address, owner: Address) {
        self.master = master;
        self.owner = owner;
        self.media = 0;
        self.attestTime = 0;
    }

    receive("fund") {}

    fun msgValue(value: Int): Int {
        let msgValue: Int = value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = self.MIN_TONS_FOR_STORAGE - min(tonBalanceBeforeMsg, self.MIN_TONS_FOR_STORAGE);
        let finalMsgValue = msgValue - (storageFee + self.GAS_CONSUMPTION);
        return finalMsgValue;
    }

    receive(msg: AttestInternal) {
        require(sender() == self.master, "Only master");
        self.media = msg.media;
        self.attestTime = now();
        let ctx = context();
        let fwdFee = ctx.readForwardFee();
        let msgValue = self.msgValue(ctx.value);
        let excessMsgValue = msgValue - fwdFee;
        if(msg.response_destination != null) {
            send(SendParameters{
            to: msg.response_destination!!,
            value: excessMsgValue,
            mode: SendIgnoreErrors,
            bounce: false,
            body: TokenExcesses {
            queryId: msg.queryId
            }.toCell(),
            });
        }
    }

    get fun attest_child_data(withCode: Bool): AttestChildData {
        return AttestChildData{
        owner: self.owner,
        master: self.master,
        media: self.media,
        attestTime: self.attestTime,
        code: withCode? (initOf AttestChild(self.master, self.owner)).code: null
        }
    }
}