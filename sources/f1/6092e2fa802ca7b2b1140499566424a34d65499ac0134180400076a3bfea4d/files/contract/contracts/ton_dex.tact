import "@stdlib/deploy";
import "./traits/tokens/jetton/JettonMaster.tact";
import "./traits/tokens/jetton/JettonWallet.tact";

contract TonDex with JettonMaster, Deployable {
    total_supply: Int as coins = 0;
    owner: Address = address("UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJKZ");
    jetton_content: Cell;
    mintable: Bool = true;
    
    init(owner: Address, content: Cell) {
        self.jetton_content = content;
        self.mintable = false;
        let ctx: Context = context();
        let msg: JettonMint = JettonMint{
            origin: ctx.sender,
            receiver: ctx.sender,
            amount: ton("1000000000"),
            custom_payload: emptyCell(),
            forward_ton_amount: 0,
            forward_payload: emptySlice()
        };
        self._mint(ctx, msg);
    }

    override inline fun calculate_jetton_wallet_init(owner_address: Address): StateInit {
        return initOf TonDexWallet(owner_address, myAddress());
    }
}

contract TonDexWallet with JettonWallet, Deployable {
    balance: Int as coins = 0;
    owner: Address;
    jetton_master: Address;

    init(owner: Address, jetton_master: Address) {
        self.owner = owner;
        self.jetton_master = jetton_master;
    }

    override inline fun calculate_jetton_wallet_init(owner_address: Address): StateInit {
        return initOf TonDexWallet(owner_address, self.jetton_master);
    }
}