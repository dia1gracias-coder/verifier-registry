import "@stdlib/deploy";

// TokenNotification message structure
message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining;  // Slice containing additional data (e.g., comment text)
}

message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}

message(0x178d4519) TokenTransferInternal {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    response_destination: Address;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}

message SetAllowedAddress {
    allowedAdress: Address;  
}


message(0xd53276db) TokenExcesses {
    queryId: Int as uint64;
}


struct JettonWalletData {
    balance: Int as coins;
    ownerAddress: Address;
    jettonMasterAddress: Address;
    jettonWalletCode: Cell;
}

fun calculateJettonWalletAddress(ownerAddress: Address, jettonMasterAddress: Address, jettonWalletCode: Cell): Address {
    let initData: JettonWalletData = JettonWalletData{  // Initialize the struct
        balance: 0,
        ownerAddress: myAddress(),
        jettonMasterAddress: jettonMasterAddress,
        jettonWalletCode: jettonWalletCode
    };
    
    // Convert struct to a Cell and return the contract address
    return contractAddress(StateInit{code: jettonWalletCode, data: initData.toCell()});
    
}

trait JettonValidator {
    jettonWalletCode: Cell;

    // Function to calculate this contract's Jetton wallet address
    fun calculateMyJettonAddress(jettonMasterAddress: Address): Address {
        return calculateJettonWalletAddress(myAddress(), jettonMasterAddress, self.jettonWalletCode);
    }

    // Function to assert that the Jetton wallet address is correct
    fun assertJettonIsValid(jettonAddress: Address, jettonMasterAddress: Address) {
        let calculatedAddress: Address = self.calculateMyJettonAddress(jettonMasterAddress);
        nativeThrowUnless(999, jettonAddress == calculatedAddress);
    }
}


// Main contract: JettonDex
contract JettonTester with JettonValidator, Deployable {
    jettonABalance: Int as coins;  // Ensure consistent type for jetton A balance
    jettonBalance: Int as coins;
    fails: Int as uint32;
    allowedAddress: Address;   
    ConAdr: Address;
    jettonWalletAddress: Address;   // Jetton wallet address
    jettonWalletCode: Cell;         // Jetton wallet code
    jettonMasterAddress: Address;
    ownerAddress: Address;
 
    // Initialize contract with owner's address and initial jetton balances
    init(jettonWalletCode: Cell, jettonMasterAddress: Address) {
        self.jettonABalance = 0;
        self.jettonBalance = 0;
        self.fails = 0;
        self.allowedAddress = myAddress();
        self.ConAdr = myAddress();
        self.jettonWalletCode = jettonWalletCode;
        self.jettonMasterAddress = address("kQCtj2MsejKfN7A0Pr4XWc3kQD02eqopy45DT5F6QxXn5LXB");
        self.jettonWalletAddress = calculateJettonWalletAddress(myAddress(), self.jettonMasterAddress, self.jettonWalletCode);
        self.ownerAddress = myAddress();
        
    }

    // Handle receiving jettons via TokenNotification message
    receive(msg: TokenNotification) {

         
        let ctx: Context = context();
        let queryId: Int = msg.queryId;
        let value: Int = 15;
        let address: Address = msg.from;
        let amount: Int = msg.amount;
        let myJettonWalletAddress: Address = calculateJettonWalletAddress(myAddress(), self.jettonMasterAddress, self.jettonWalletCode);
 
        self.addJetton(amount);
     
    }

   receive(msg: SetAllowedAddress) {
        self.allowedAddress = msg.allowedAdress;  // Set the new allowed address
    }

    receive("something2") {
     
        let ctx: Context = context();
        
        send(SendParameters{
        to: self.allowedAddress,   
        value: 0,       
        bounce: false,  
        mode: SendRemainingValue, 
        body: TokenTransfer{ 
            queryId: 0,
            amount: 50000000000,
            destination: address("kQAR3PTNr0mWvqIYkwQlQUS-Yh6wQOY2ZIPfDK0lWkoUyc8J"),
            response_destination: self.allowedAddress,
            custom_payload: emptyCell(),
            forward_ton_amount: 50000000,
            forward_payload: emptySlice()
        }.toCell()  // Convert the struct to a cell to sen
    });
    }

    receive("something") {    
        let ctx: Context = context();
        
        send(SendParameters{
        to: self.allowedAddress,   
        value: 0,       
        bounce: false,  
        mode: SendRemainingValue, 
        body: TokenTransfer{ 
            queryId: 0,
            amount: 50000000000,
            destination: sender(),
            response_destination:  sender(),
            custom_payload: emptyCell(),
            forward_ton_amount: 50000000,
            forward_payload: beginCell().storeUint(0, 1).endCell().beginParse(),
        }.toCell()  // Convert the struct to a cell to sen
    });
    }




    // Function to add jettons to balance
    fun addJetton(amount: Int) {
        self.jettonABalance += amount;  // Update balance with the received amount
    }

    // Getter for Jetton A balance
    get fun getJettonABalance(): Int {
        return self.jettonABalance;
    }

    // Getter for the total jetton balance
    get fun getJettonBalance(): Int {
        return self.jettonBalance;
    }

    // Getter for the total fails
    get fun getFails(): Int {
        return self.fails;
    }

    get fun getAddr(): Address {
        return self.allowedAddress;
    }

    get fun myAdr(): Address {
        return myAddress();
    }

    get fun getJettonWalletAddress(): Address {
    return self.jettonWalletAddress;
}
}
