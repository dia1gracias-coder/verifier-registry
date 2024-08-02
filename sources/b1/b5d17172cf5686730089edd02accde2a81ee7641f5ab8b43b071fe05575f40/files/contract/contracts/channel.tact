import "@stdlib/deploy";
import "@stdlib/ownable";
import "./bridge_call.tact";

message OutboundMessage {
    nonce: Int as uint64;
    message: SoraEncodedCall;
    source: Address;
}

message SendOutboundMessage {
    message: SoraEncodedCall;
    sender: Address;
}

message SendInboundMessage {
    target: Address;
    message: Cell;
}

message RegisterApp {
    app: Address;
}

message Reset {}

contract Channel with Deployable, OwnableTransferable {
    override const storageReserve: Int = ton("0.01");
    owner: Address;
    outboundNonce: Int as uint64 = 0;
    apps: map<Address, Bool>;

    init(owner: Address){
        require(sender() == owner, "Only owner can initialize this contract");
        self.owner = owner;
    }
    
    get fun isApp(app: Address): Bool {
        return self.apps.get(app) == true;
    }
    
    get fun apps(): map<Address, Bool> {
        return self.apps;
    }

    get fun outboundNonce(): Int {
        return self.outboundNonce;
    }
    
    fun requireApp() {
        require(self.apps.get(sender()) == true, "Only apps can send messages");
    }
    
    receive(msg: SendOutboundMessage) {
        self.requireApp();
        self.outboundNonce += 1;
        emit(OutboundMessage {
            nonce: self.outboundNonce,
            message: msg.message,
            source: sender(),
        }.toCell());
        self.forward(msg.sender, null, false, null);
    }
    
    receive(msg: RegisterApp) {
        self.requireOwner();
        self.apps.set(msg.app, true);
        self.notify(null);
    }
    
    receive(msg: Reset) {
        self.requireOwner();
        self.outboundNonce = 0;
        self.notify(null);
    }
    
    receive(msg: SendInboundMessage) {
        self.requireOwner();
        require(self.apps.get(msg.target) == true, "Can only send messages to apps");
        self.forward(msg.target, msg.message, true, null);
    }
}