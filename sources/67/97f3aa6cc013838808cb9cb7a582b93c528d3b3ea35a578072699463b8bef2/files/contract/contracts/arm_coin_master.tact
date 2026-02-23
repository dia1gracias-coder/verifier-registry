import "@stdlib/deploy";
import "./arm_coin_wallet"; 

// --- Missing Struct Definition ---
struct JettonData {
    totalSupply: Int;
    mintable: Bool;
    adminAddress: Address;
    content: Cell;
    walletCode: Cell;
}

message Mint {
    amount: Int;
    receiver: Address;
}

// Rename this to avoid collision with the standard Burn message in the Wallet
message MasterBurn {
    amount: Int;
}


contract ArmCoinMaster with Deployable {
    total_supply: Int = 0;
    owner: Address;
    jetton_content: Cell;
    nonce: Int as uint64; 
    
    // 1 Billion Hard Cap as per the Business Plan [cite: 90, 94]
    const HARD_CAP: Int = 1000000000000000000; 

    init(owner: Address, content: Cell, nonce: Int) {
        self.owner = owner;
        self.jetton_content = content;
        self.nonce = nonce; 
    }

    receive(msg: Mint) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Only admin can mint");
        require(self.total_supply + msg.amount <= self.HARD_CAP, "Hard Cap exceeded");
        
        self.total_supply = self.total_supply + msg.amount;
        
        let winit: StateInit = self.getJettonWalletInit(msg.receiver);
        send(SendParameters{
            to: contractAddress(winit),
            value: 0,
            bounce: true,
            mode: SendRemainingValue,
            body: InternalTransfer{
                query_id: 0,
                amount: msg.amount,
                from: self.owner,
                response_destination: self.owner,
                forward_ton_amount: 0,
                forward_payload: emptySlice()
            }.toCell(),
            code: winit.code,
            data: winit.data
        });
    }

    // Updated receive block for the 20% deflationary protocol [cite: 184, 185]
    receive(msg: MasterBurn) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Only admin can trigger master burn");
        
        // This reduces total_supply on-chain to match off-chain deflation
        self.total_supply = self.total_supply - msg.amount;
    }


    get fun getJettonWalletInit(address: Address): StateInit {
        // Pass myAddress() (the Master contract) instead of self.owner
        return initOf ArmCoinWallet(myAddress(), address); 
    }

    get fun get_jetton_data(): JettonData {
        return JettonData{
            totalSupply: self.total_supply,
            mintable: true,
            adminAddress: self.owner,
            content: self.jetton_content,
            walletCode: (initOf ArmCoinWallet(myAddress(), myAddress())).code
        };
    }

}