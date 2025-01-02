import "@stdlib/deploy";
import "./jetton/JettonMaster";
import "./jetton/JettonWallet";

message Mint {
    amount: Int;
    receiver: Address;
}

contract SPAJettonWallet with JettonWallet {
    balance: Int as coins = 0;
    owner: Address;
    jetton_master: Address;

    init(owner: Address, jetton_master: Address){
        self.owner = owner;
        self.jetton_master = jetton_master;
    }

    override inline fun calculate_jetton_wallet_init(owner_address: Address): StateInit {
        return initOf SPAJettonWallet(owner_address, self.jetton_master);
    }
}

contract SPAJettonMaster with Deployable, JettonMaster {
    total_supply: Int as coins = 0;
    mintable: Bool = false;
    owner: Address;
    jetton_content: Cell;

    // inited fixed mint amount
    init(owner: Address, jetton_content: Cell){
        self.owner = owner;
        self.jetton_content = jetton_content;
        
        let ctx: Context = context();
        let _msg: JettonMint = JettonMint{
            origin: ctx.sender,
            receiver: ctx.sender,
            amount: 1000000000_000000000,
            custom_payload: emptyCell(),
            forward_ton_amount: 0,
            forward_payload: emptySlice()
        };
        self._mint(ctx, _msg);
    }
    
    override inline fun _mint_validate(ctx: Context, msg: JettonMint) {
        require(ctx.sender == self.owner, "JettonMaster: Sender is not a Jetton owner");
        require(self.mintable, "JettonMaster: Jetton is not mintable");
    }

    override inline fun calculate_jetton_wallet_init(owner_address: Address): StateInit {
        return initOf SPAJettonWallet(owner_address, myAddress());
    }
}