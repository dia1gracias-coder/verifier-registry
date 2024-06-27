import "@stdlib/deploy";
import "./jetton-wallet";
import "./jetton-dynasty";

contract WrappedJettonWallet with JettonWallet {
    balance: Int as coins = 0;
    owner: Address;
    jetton_master: Address;
    init(owner: Address, jetton_master: Address){
        self.owner = owner;
        self.jetton_master = jetton_master;
    }

    override inline fun calculate_jetton_wallet_init(owner_address: Address): StateInit {
        return initOf WrappedJettonWallet(owner_address, self.jetton_master);
    }
}

contract WrappedJetton with JettonMaster, Deployable {
    total_supply: Int as coins = 0;
    mintable: Bool = true;
    owner: Address;
    admin: Address;
    jetton_content: Cell;
    init(admin: Address, owner: Address, jetton_content: Cell){
        self.admin = admin;
        self.owner = owner;
        self.jetton_content = jetton_content;
    }

    override inline fun _mint_validate(ctx: Context, msg: JettonMint) {
        require(self.mintable, "JettonMaster: Jetton is not mintable");
        require(context().sender == self.owner, "JettonMaster: Mint can only be performed by owner");
    }

    override inline fun calculate_jetton_wallet_init(owner_address: Address): StateInit {
        return initOf WrappedJettonWallet(owner_address, myAddress());
    }

    receive (msg: UpdateAdmin) {
        require(context().sender == self.admin, "JettonMaster: Only Admin can set new admin.");
        self.admin = msg.new_admin;
    }

    receive (msg: UpdateOwner) {
        require(context().sender == self.admin, "JettonMaster: Only Admin can set new owner.");
        self.owner = msg.new_owner;
    }

    get fun owner(): Address {
        return self.owner;
    }

    get fun admin(): Address {
        return self.admin;
    }
}
message UpdateAdmin {
    new_admin: Address;
}
message UpdateOwner {
    new_owner: Address;
}