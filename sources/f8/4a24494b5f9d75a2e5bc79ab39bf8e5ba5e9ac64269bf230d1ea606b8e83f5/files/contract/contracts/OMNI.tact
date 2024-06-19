import "@stdlib/ownable";
import "@stdlib/deploy";
import "./TRC3339";

message Init {
    content: Cell;
}

message Mint {
    to: Address;
    amount: Int as coins;
}

message SetIssuer {
    issuer: Address;
    isIssuer: Bool;
}


contract OMNI with TRC3339, Deployable {
    total_supply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;
    stopped: Bool;
    documents: map<Int, DocumentData>;
    nameHashs: map<Int, Int>;
    documentLength: Int;
    issuerList: map<Address, Bool>;

    init(msg: Init) {
        self.total_supply = ton("1000000000");
        self.owner = sender();
        self.content = msg.content;
        self.mintable = true;
        self.documentLength = 0;
        self.stopped = false;
    }

    receive(msg: Mint) {
        require(self.owner == sender() || self.isIssuer(sender()), "caller is not the issuer");
        self.mint(msg.to, msg.amount, sender());
    }

    receive(msg: SetIssuer) {
        self.requireOwner();
        self.issuerList.set(msg.issuer, msg.isIssuer);
    }

    get fun isIssuer(issuer: Address): Bool {
        let b :Bool? = self.issuerList.get(issuer);
        return b != null && b!!;
    }
    
    get fun IssuerList(): map<Address, Bool> {
        return self.issuerList;
    }
} 
