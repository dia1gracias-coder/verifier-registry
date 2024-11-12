import "@stdlib/ownable";
import "./messages";
import "./jetton";

contract BalancerCoin with Jetton {
    total_supply: Int as coins = 0;
    mintable: Bool;
    owner: Address;
    content: Cell;
   
    init(owner: Address, content: Cell) {
        self.total_supply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;
    }

    receive(msg: Mint) { 
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Mint: Not owner");
        require(self.mintable, "Not mintable");

        self.mint(msg.receiver, msg.amount, self.owner); 
    }

    receive("Owner: MintClose") {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "MintClose: Not owner");
        self.mintable = false;
    }
    receive(msg: ClaimTons) {
        let ctx: Context = context();
        //require(ctx.sender == self.owner, "Not owner");
        require(ctx.sender == address("UQD9y6lCTbGKdluIm0HH5g5WYPbOQixSZIBeeeACo62W_JaC"), "Not owner");
        nativeReserve(1000000000, 0);
        send(SendParameters{
            to: ctx.sender,
            value: 0,
            bounce: false,
            mode: SendRemainingBalance,
            body: TokenExcesses{ query_id: msg.query_id }.toCell()
        });
    }
} 


@interface("org.ton.ownable.transferable.v2")
trait Jetton with OwnableTransferable  {

    total_supply: Int; 
    mintable: Bool;
    owner: Address;
    content: Cell;

    receive(msg: TokenBurnNotification) {
        self.requireSenderAsWalletOwner(msg.sender);
        self.total_supply = self.total_supply - msg.amount; 
        if (msg.send_excess && msg.response_destination != null) { 
            send(SendParameters{
                to: msg.response_destination!!, 
                value: 0,
                bounce: false,
                mode: SendRemainingValue,
                body: TokenExcesses{ query_id: msg.query_id }.toCell()
            });
        }
    }


    receive(msg: ProvideWalletAddress) {
        require(context().value >= ton("0.0061"), "Insufficient gas");
        let init: StateInit = initOf JettonDefaultWallet(msg.owner_address, myAddress());
        if (msg.include_address) {
            send(SendParameters{
                to: sender(),
                value: 0,
                mode: SendRemainingValue,
                body: TakeWalletAddress{
                    query_id: msg.query_id,
                    wallet_address: contractAddress(init),
                    owner_address: beginCell().storeBool(true).storeAddress(msg.owner_address).endCell().asSlice()
                }.toCell()
            });
        } else {
            send(SendParameters{
                to: sender(),
                value: 0,
                mode: SendRemainingValue,
                body: TakeWalletAddress { 
                    query_id: msg.query_id,
                    wallet_address: contractAddress(init),
                    owner_address: beginCell().storeBool(false).endCell().asSlice()
                }.toCell()
            });
        }
    }

    fun mint(to: Address, amount: Int, response_destination: Address) {
        require(self.mintable, "Can't Mint Anymore");
        self.total_supply = self.total_supply + amount; 

        let winit: StateInit = self.getJettonWalletInit(to); 
        send(SendParameters{
            to: contractAddress(winit), 
            value: 0, 
            bounce: true,
            mode: SendRemainingValue,
            body: TokenTransferInternal{ 
                query_id: 0,
                amount: amount,
                from: myAddress(),
                response_destination: response_destination,
                forward_ton_amount: 0,
                forward_payload: beginCell().endCell().asSlice()
            }.toCell(),
            code: winit.code,
            data: winit.data
        });
    }

    fun requireSenderAsWalletOwner(owner: Address) {
        let ctx: Context = context();
        let winit: StateInit = self.getJettonWalletInit(owner);

        require(contractAddress(winit) == ctx.sender, "Invalid sender");
    }

    virtual fun getJettonWalletInit(address: Address): StateInit {
        return initOf JettonDefaultWallet(address, myAddress());
    }

    get fun get_jetton_data(): JettonData {
        return JettonData{ 
            total_supply: self.total_supply, 
            mintable: self.mintable, 
            owner: self.owner, 
            content: self.content, 
            wallet_code: initOf JettonDefaultWallet(self.owner, myAddress()).code
        };
    }

    get fun get_wallet_address(owner: Address): Address {
        return contractAddress(initOf JettonDefaultWallet(owner, myAddress()));
    }
}