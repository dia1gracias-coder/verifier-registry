import "@stdlib/deploy";

message SetFee {
   fee: Int;
}

message SendTon {
   address: map<Int, Address>;
   amount: map<Int, Int>;
   comment: map<Int, Cell>;
   length: Int;
}

message SendJetton {
   contractAddress: Address; 
   body: map<Int, Cell>;
   length: Int;
   amount: Int;
}

message ChangeContractOwner{
    newOwner: Address; 
}

 
contract BatchSender with Deployable {

const MinTonForStorage: Int = ton("0.01"); // enough for 1 KB of storage for 2.5 years
    deployer: Address;
    fee: Int;

    init() {
        self.deployer = sender();
        self.fee = ton("0.05");
     }

    receive(msg:  SendTon ) { 
        self.sendTonBatch(msg);
    }

    receive(msg: SetFee ) { 
        self.fee = msg.fee;
    }

    receive(msg:  SendJetton ) { 
        self.SendJettonBatch(msg);
    }
  
    receive(msg:  ChangeContractOwner ) { 
        self.deployer= (msg.newOwner);
    }

    fun SendJettonBatch(data: SendJetton ) {
 
        let totalFee: Int = self.fee * data.length;

        require(context().value >= (totalFee+(data.amount)),"401");
            
        send(SendParameters{
            to: self.deployer,  
            value: totalFee,
            mode: SendIgnoreErrors,
            bounce: true,
            body: "Fee from Ton Sprayer".asComment()
        });

        let i: Int = data.length;
            while ( i > 0) {
            let body: Cell = data.body.get(i)!!;            
            send(SendParameters{
                to: data.contractAddress,
                value: ton("0.05"),
                mode: SendIgnoreErrors,
                bounce: true,
                body: body
            });
            i-=1;
        }
    }

    fun sendTonBatch(data: SendTon ) { 
 
        let totalFee: Int = self.fee * data.length;
        let amountPerWallet: Int? =data.amount.get(1);
        if(amountPerWallet == null) {
            return;
        }

        require(context().value >= (totalFee+(amountPerWallet!!*data.length)),"400");
            
        send(SendParameters{
            to: self.deployer,  
            value: totalFee,
            mode: SendIgnoreErrors,
            bounce: true,
            body: "Fee from Ton Sprayer".asComment()
        });

        let i: Int = data.length;
            while ( i > 0) {
          
            let to: Address = data.address.get(i)!!;
            let amount: Int = data.amount.get(i)!!;
            let comment: Cell = data.comment.get(i)!!;
             
            send(SendParameters{
                to: to,  
                value: amount,
                mode: SendIgnoreErrors,
                bounce: true,
                body: comment
            });
            i-=1;
        }     
    }

    get fun balance(): Int {
        return myBalance();
    }

    get fun fee(): Int {
        return self.fee;
    }

    receive("withdraw safe") {
        require(sender() == self.deployer, "Only deployer is allowed to withdraw");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: myBalance() - context().value - self.MinTonForStorage,
            mode: SendRemainingValue + SendIgnoreErrors
        });
    } 
 
}
