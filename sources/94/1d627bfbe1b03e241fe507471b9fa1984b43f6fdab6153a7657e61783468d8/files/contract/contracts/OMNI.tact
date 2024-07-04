import "@stdlib/ownable";
import "@stdlib/deploy";
import "./TRC3339";

message Init {
    content: Cell;
    transferFee: Int as coins; // fee rate (e.g. 200 = 2%, 150 = 1.50%)
    OMNIDigital: Address;
    Tokenise: Address;
    InvessHK: Address;
}

message SetAddr {
    OMNIDigital: Address;
    Tokenise: Address;
    InvessHK: Address;
}

message Mint {
    to: Address?;
    amount: Int as coins;
    allToDistributed: Bool;
    enableDistributed: Bool;
    forward_ton_amount: Int as coins;
}

message SetIssuer {
    issuer: Address;
    isIssuer: Bool;
}

message ClaimFee {
    amount: Int as coins;
    forward_ton_amount: Int as coins;
}


contract OMNI with TRC3339, Deployable {
    total_supply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;
    stopped: Bool;
    documents: map<Int, DocumentData>;
    nameHashs: map<Int, Int>;
    documentLength: Int as coins;
    transferFee: Int as coins; // fee rate (e.g. 200 = 2%, 150 = 1.50%)
    issuerList: map<Address, Bool>;
    OMNIDigital: Address;
    Tokenise: Address;
    InvessHK: Address;

    init(msg: Init) {
        self.total_supply = 0;
        self.owner = sender();
        self.content = msg.content;
        self.mintable = true;
        self.documentLength = 0;
        self.stopped = false;
        self.transferFee = msg.transferFee;
        self.OMNIDigital = msg.OMNIDigital;
        self.Tokenise = msg.Tokenise;
        self.InvessHK = msg.InvessHK;
    }

    receive(msg: Mint) {
        require(self.mintable, "Can't Mint Anymore");
        require(self.owner == sender() || self.isIssuer(sender()), "caller is not the issuer");
        let distributedAmount: Int = 0;
        if(!msg.allToDistributed && msg.enableDistributed) {
            distributedAmount = msg.amount * 750 / 10000;
        }
        else if(msg.allToDistributed) {
            distributedAmount = msg.amount;
        }
        if(distributedAmount > 0) {
            self.total_supply = self.total_supply + distributedAmount; // Update total supply
            let OMNIDigitalAmount: Int = distributedAmount * 2000 / 10000;
            let TokeniseAmount: Int = distributedAmount * 1600 / 10000;
            let InvessHKAmount: Int = distributedAmount - OMNIDigitalAmount - TokeniseAmount;
            self.issue(self.OMNIDigital, OMNIDigitalAmount, msg.forward_ton_amount);
            self.issue(self.Tokenise, TokeniseAmount, msg.forward_ton_amount);
            self.issue(self.InvessHK, InvessHKAmount, msg.forward_ton_amount);
        }
        if(msg.to != null && !msg.allToDistributed) {
            self.issue(msg.to!!, msg.amount, msg.forward_ton_amount);
        }
    }

    receive(msg: SetIssuer) {
        self.requireOwner();
        self.issuerList.set(msg.issuer, msg.isIssuer);
    }

    receive(msg: ClaimFee) {
        self.requireOwner();
        let distributedAmount: Int = msg.amount;
        if(distributedAmount > 0) {
            //Once you have programmed the fees, 20% of it goes to OMNI Digital, 16% goes to Tokenise and 64% goes to Invess HK.
            let OMNIDigitalAmount: Int = distributedAmount * 2000 / 10000;
            let TokeniseAmount: Int = distributedAmount * 1600 / 10000;
            let InvessHKAmount: Int = distributedAmount - OMNIDigitalAmount - TokeniseAmount;
            self.claimFee(self.OMNIDigital, OMNIDigitalAmount, msg.forward_ton_amount);
            self.claimFee(self.Tokenise, TokeniseAmount, msg.forward_ton_amount);
            self.claimFee(self.InvessHK, InvessHKAmount, msg.forward_ton_amount);
        }
    }

    receive(msg: SetAddr) {
        self.requireOwner();
        self.OMNIDigital = msg.OMNIDigital;
        self.Tokenise = msg.Tokenise;
        self.InvessHK = msg.InvessHK;
    }

    fun issue(to: Address, amount: Int, forward_ton_amount: Int) {
        self.total_supply = self.total_supply + amount; // Update total supply
        let winit: StateInit = self.getJettonWalletInit(to);
        send(SendParameters{
                    to: contractAddress(winit), 
                    value: forward_ton_amount,
                    mode: SendPayGasSeparately,
                    body: TokenTransferInternal {
                            query_id: 0,
                            amount: amount,
                            from: myAddress(),
                            response_destination: null,
                            forward_ton_amount: 0,
                            forward_payload: beginCell().asCell().asSlice()
                    }.toCell(),
                    code: winit.code,
                    data: winit.data
            });
    }

    fun claimFee(to: Address, amount: Int, forward_ton_amount: Int) {
        let winit: StateInit = self.getJettonWalletInit(myAddress());
        send(SendParameters{
                to: contractAddress(winit),
                value: forward_ton_amount,
                mode: SendPayGasSeparately,
                body: TokenTransfer {
                        query_id: 0,
                        amount: amount,
                        destination: to,
                        response_destination: null,
                        custom_payload: null,
                        forward_ton_amount: 0,
                        forward_payload: beginCell().asCell().asSlice()
                }.toCell()
        });
    }

    get fun isIssuer(issuer: Address): Bool {
        let b :Bool? = self.issuerList.get(issuer);
        return b != null && b!!;
    }
    
    get fun IssuerList(): map<Address, Bool> {
        return self.issuerList;
    }
    
    get fun FeAddr(): SetAddr {
        return SetAddr{
            OMNIDigital: self.OMNIDigital,
            Tokenise: self.Tokenise,
            InvessHK: self.InvessHK
        };
    }
} 
