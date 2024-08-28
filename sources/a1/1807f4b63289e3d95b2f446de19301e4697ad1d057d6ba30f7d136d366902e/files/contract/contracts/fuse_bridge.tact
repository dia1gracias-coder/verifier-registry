import "@stdlib/deploy";
import "@stdlib/ownable";
message Release {
    amount: Int as coins;
    user: Address;
    requestId: Int;
}
message SwapAndRelease {
    amount: Int as coins;
    user: Address;
    requestId: Int;
    vault: Address;
    pool: Address;
    tradeFee: Int as coins;
}
message Prevent {
    user: Address;
    requestId: Int;
}
message WithdrawJetton {
    amount: Int as coins;
    user: Address;
    jettonWallet: Address;
}
message ExecutorStatus {
    account: Address;
    canExecute: Bool;
}
message Bridge {
    amount: Int as coins;
    destinationAddress: String;
}
message BridgeInitiated {
    sourceAddress: Address;
    destinationAddress: String;
    amount: Int as coins;
}
message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}
message SetFeeBps {
    newFeeBps: Int;
}

message SetFeeBpsOk {
    newFeeBps: Int;
}

message SetMinBridgeAmount {
    newMinBridgeAmount: Int;
}

message SetMinBridgeAmountOk {
    newMinBridgeAmount: Int;
}

struct DedustPayload {
    sourceAddress: Address;
    destinationAddress: String;
    amount: Int as coins;
}
message(0x474f86cf) DedustPayout {
    queryId: Int as uint64;
    payload: Cell?;
}
struct DedustSwapStepParams {
    kind: Bool = false;
    limit: Int as coins = 0;
    next: Cell? = null;
}
struct DedustSwapParams {
    deadline: Int as uint32 = 0;
    recipient_addr: Address? = null;
    referral_addr: Address? = null;
    fulfill_payload: Cell? = null;
    reject_payload: Cell? = null;
}
message(0xea06185d) DedustSwap {
    queryId: Int as uint64;
    amount: Int as coins;
    pool_addr: Address;
    params: DedustSwapStepParams;
    swap_params: Cell;
}

message Withdraw {
    amount: Int as coins;
    receiver: Address;
}

contract RequestStatus with Deployable {
    override const storageReserve: Int = ton("0.001");
    bridge: Address;
    user: Address;
    requestId: Int;
    released: Bool;
    prevented: Bool;

    init(user: Address, requestId: Int){
        self.bridge = sender();
        self.user = user;
        self.requestId = requestId;
        self.released = false;
        self.prevented = false;
    }

    bounced(rawMsg: Slice) {
        self.released = false;
        self.forward(self.bridge, "Refunding for fail swap".asComment(), false, null);
    }

    receive(msg: Release){
        require(!self.released, "Request released");
        require(!self.prevented, "Request prevented");
        require(self.bridge == sender(), "Bridge only");
        require(self.requestId == msg.requestId, "Invalid request id");
        require(self.user == msg.user, "Invalid user address");
        require(context().value >= msg.amount, "Insufficient value");
        self.released = true;
        send(SendParameters{to: msg.user, bounce: true, value: msg.amount});
        self.reply("Refunding gas for release".asComment());
    }

    receive(msg: SwapAndRelease){
        require(!self.released, "Request released");
        require(!self.prevented, "Request prevented");
        require(self.bridge == sender(), "Bridge only");
        require(self.requestId == msg.requestId, "Invalid request id");
        require(self.user == msg.user, "Invalid user address");
        require(msg.amount > msg.tradeFee, "Invalid trade fee");
        require(context().value >= msg.amount, "Insufficient value");
        self.released = true;
        send(SendParameters{
            to: msg.vault, 
            bounce: true, 
            value: msg.amount,
            body: DedustSwap{
                queryId: msg.requestId,
                amount: msg.amount - msg.tradeFee,
                pool_addr: msg.pool,
                params: DedustSwapStepParams{},
                swap_params: DedustSwapParams{
                    recipient_addr: msg.user,
                }.toCell(),
            }.toCell(),
        });
        self.reply("Refunding gas for release".asComment());
    }

    receive(msg: Prevent){
        require(!self.released, "Request released");
        require(!self.prevented, "Request prevented");
        require(self.bridge == sender(), "Bridge only");
        require(self.requestId == msg.requestId, "Invalid request id");
        require(self.user == msg.user, "Invalid user address");
        self.prevented = true;
        self.reply("Refunding gas for prevent".asComment());
    }
}

contract FuseBridge with Deployable, OwnableTransferable {
    const MinTonForStorage: Int = ton("0.01");
    const MaxFeeBps: Int = 500;
    const gasConsumption: Int = ton("0.01");
    executors: map<Address, Bool>;
    owner: Address;
    feeBps: Int;
    minBridgeAmount: Int = ton("0");
    
    init(feeBps: Int){
        require(self.MaxFeeBps >= feeBps, "Invalid fee bps");
        self.owner = sender();
        self.executors = emptyMap();
        self.feeBps = feeBps;
    }

    receive(){
        dump("funds received");
    }

    receive(msg: ExecutorStatus){
        self.requireOwner();
        if (self.executors.get(msg.account) != msg.canExecute) {
            self.executors.set(msg.account, msg.canExecute);
        }
    }

    receive(msg: Release){
        require(self.executors.get(sender()) == true, "Only executors can release funds");        
        let statusInit: StateInit = initOf RequestStatus(msg.user, msg.requestId);
        let statusAddress: Address = contractAddress(statusInit);
        send(SendParameters{
            to: statusAddress,
            bounce: true, 
            value: msg.amount + self.gasConsumption,
            mode: SendIgnoreErrors | SendPayGasSeparately,
            code: statusInit.code,
            data: statusInit.data,
            body: msg.toCell(),
        });
        self.reply("Refunding gas for release".asComment());
    }

    receive(msg: SwapAndRelease){
        require(self.executors.get(sender()) == true, "Only executors can release funds");        
        let statusInit: StateInit = initOf RequestStatus(msg.user, msg.requestId);
        let statusAddress: Address = contractAddress(statusInit);
        send(SendParameters{
            to: statusAddress,
            bounce: true, 
            value: msg.amount + self.gasConsumption,
            mode: SendIgnoreErrors | SendPayGasSeparately,
            code: statusInit.code,
            data: statusInit.data,
            body: msg.toCell(),
        });
        self.reply("Refunding gas for release".asComment());
    }

    receive(msg: Prevent){
        require(self.executors.get(sender()) == true, "Only executors can prevent request from releasing");        
        let statusInit: StateInit = initOf RequestStatus(msg.user, msg.requestId);
        let statusAddress: Address = contractAddress(statusInit);
        send(SendParameters{
            to: statusAddress,
            value: self.gasConsumption,
            mode: SendIgnoreErrors | SendPayGasSeparately,
            code: statusInit.code,
            data: statusInit.data,
            body: msg.toCell(),
        });
        self.reply("Refunding gas for prevent".asComment());
    }

    receive(msg: WithdrawJetton){
      self.requireOwner();
        send(SendParameters{
                to: msg.jettonWallet,
                bounce: true,
                value: 0,
                mode: SendRemainingValue,
                body: TokenTransfer{
                    queryId: 0,
                    amount: msg.amount,
                    destination: msg.user,
                    response_destination: myAddress(),
                    forward_ton_amount: 0,
                    forward_payload: "Bridged by Fuse".asSlice(),
                    custom_payload: null
                }.toCell()
            }
        );
        self.reply("Admin withdraw jetton".asComment());
    }

    receive(msg: Bridge){
        require(context().value > msg.amount, "Insufficient value");
        require(msg.amount >= self.minBridgeAmount, "Amount is less than min bridge amount");
        let feeAmount = self.getFeeAmount(msg.amount);
        emit(BridgeInitiated{
                sourceAddress: sender(),
                destinationAddress: msg.destinationAddress,
                amount: msg.amount - feeAmount
            }.toCell()
        );
        send(SendParameters{to: sender(), bounce: true, value: (context().value - msg.amount)});
    }
    
    receive(msg: DedustPayout) {
        require(msg.payload != null, "Payout payload empty");
        let data = DedustPayload.fromCell(msg.payload!!);
        require(context().value > data.amount, "Insufficient value");
        require(data.amount >= self.minBridgeAmount, "Amount is less than min bridge amount");
        let feeAmount = self.getFeeAmount(data.amount);
        emit(BridgeInitiated{
                sourceAddress: data.sourceAddress,
                destinationAddress: data.destinationAddress,
                amount: data.amount - feeAmount
            }.toCell()
        );
        send(SendParameters{to: data.sourceAddress, bounce: true, value: (context().value - data.amount)});
    }

    receive(msg: SetFeeBps){
        self.requireOwner();
        require(self.MaxFeeBps >= msg.newFeeBps, "Invalid fee bps");
        self.feeBps = msg.newFeeBps;
        self.reply(SetFeeBpsOk{ newFeeBps: msg.newFeeBps }.toCell());
    }

    receive(msg: SetMinBridgeAmount){
        self.requireOwner();
        self.minBridgeAmount = msg.newMinBridgeAmount;
        self.reply(SetMinBridgeAmountOk{ newMinBridgeAmount: msg.newMinBridgeAmount }.toCell());
    }

    receive(msg: Withdraw){
        self.requireOwner();
        send(SendParameters{to: msg.receiver, bounce: true, value: msg.amount});
        self.reply("Admin withdraw".asComment());
    }

    fun getFeeAmount(amount: Int): Int {
        return (amount * self.feeBps) / 10000;
    }

    get fun admin(): Address {
        return self.owner;
    }

    get fun feeBps(): Int {
        return self.feeBps;
    }

    get fun minBridgeAmount(): Int {
        return self.minBridgeAmount;
    }

    get fun statusAddress(user: Address, requestId: Int): Address {
        let statusInit: StateInit = initOf RequestStatus(user, requestId);
        return contractAddress(statusInit);
    }

    get fun executorStatus(account: Address): Bool {
        let canExecute: Bool? = self.executors.get(account);
        if (canExecute == null) {
            return false;
        }
        return canExecute!!;
    }
}