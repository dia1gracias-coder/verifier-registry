import "@stdlib/deploy";
import "../traits/jetton/JettonMaster.tact";
import "../traits/jetton/JettonWallet.tact";
import "../traits/jetton/extensions/Approveable.tact";

contract Tonbear with JettonMaster, Deployable {
    total_supply: Int as coins = 0;
    owner: Address = address("UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJKZ");
    jetton_content: Cell;
    mintable: Bool = true;
    init(owner: Address, content: Cell){
        self.jetton_content = content;
        self.owner = owner;
    }

    override inline fun calculate_jetton_wallet_init(owner_address: Address): StateInit {
        return initOf TonbearWallet(owner_address, myAddress());
    }

    get fun total_supply(): Int {
        return self.total_supply;
    }

    receive ("Revoke Admin") {
        let ctx: Context = context();
        require(sender() == self.owner, "JettonMaster: Sender is not a Jetton owner");
        self.owner = newAddress(0, 0);
        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors,
            body: "Revoke Admin Success".asComment()})
    }

    receive("Mint:Close"){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "JettonMaster: Sender is not a Jetton owner");
        self.mintable = false;
    }
}

contract TonbearWallet with JettonWallet, Deployable, ApproveableWallet {
    balance: Int as coins = 0;
    owner: Address;
    jetton_master: Address;
    allowances: map<Address,Int>;
    init(owner: Address, jetton_master: Address){
        self.owner = owner;
        self.jetton_master = jetton_master;
    }

    override inline fun calculate_jetton_wallet_init(owner_address: Address): StateInit {
        return initOf TonbearWallet(owner_address, self.jetton_master);
    }



    // TODO : fix me
    receive(msg: TokenSpend){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "JettonWallet: Only owner can spend tokens");
        let init: StateInit = initOf TonbearWallet(msg.destination, self.jetton_master);
        send(SendParameters{
                to: myAddress(),
                value: 0,
                bounce: true,
                body: JettonTransfer{
                        query_id: msg.query_id,
                        amount: msg.amount,
                        destination: msg.destination,
                        response_destination: msg.response_destination,
                        custom_payload: msg.custom_payload,
                        forward_ton_amount: msg.forward_ton_amount,
                        forward_payload: msg.forward_payload
                    }.toCell()
            }
        )
    }

    receive(msg: TokenApprove){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "JettonWallet: Only owner can approve tokens");
        self.approve(msg.spender, msg.amount);
    }
}