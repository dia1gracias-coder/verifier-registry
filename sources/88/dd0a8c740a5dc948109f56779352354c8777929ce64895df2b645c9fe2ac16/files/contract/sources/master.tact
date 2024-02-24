import "./wallet";
import "@stdlib/ownable";
import "@stdlib/deploy";

struct MasterData {
    total_supply: Int;
    mintable: Bool;
    owner: Address;
    jetton_content: Cell;
    jetton_wallet_code: Cell;
}

message(0x2c76b973) ProvideWalletAddress {
    query_id: Int as uint64;
    owner_address: Address;
    include_address: Bool;
}
message(0xd1735400) TakeWalletAddress {
    query_id: Int as uint64;
    wallet_address: Address;
    owner_address: Address?;
}

message ChangeContent {
    jetton_content: Cell;
}

const gasConsumption: Int = ton("1.00");

const minTons: Int = ton("0.01");

@interface("org.ton.jetton.master")
contract TokenMaster with OwnableTransferable, Deployable {
    total_supply: Int as coins = 0;
    mintable: Bool = true;
    owner: Address;
    jetton_content: Cell;

    init(owner: Address, jetton_content: Cell) {
        self.owner = owner;
        self.jetton_content = jetton_content;
    }

    receive(msg: ChangeContent) {
        self.requireOwner();
        self.jetton_content = msg.jetton_content;
    }

    receive(msg: TokenTransfer) {
        let ctx: Context = context();
        self.requireOwner();
        require(self.mintable, "Mint stopped");
        require(ctx.readForwardFee() * 2 + 2 * gasConsumption + minTons + msg.forward_ton_amount < ctx.value, "Invalid ton amount");
        self.total_supply = self.total_supply + msg.amount;
        let init: StateInit = initOf JettonDefaultWallet(msg.destination, myAddress());
        let to: Address = contractAddress(init);

        send(SendParameters {
            to: to,
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: TokenTransferInternal{
                queryId: msg.queryId,
                amount: msg.amount,
                from: self.owner,
                response_destination: msg.response_destination,
                forward_ton_amount: msg.forward_ton_amount,
                forward_payload: msg.forward_payload}.toCell(),
            data: init.data,
            code: init.code
        });
    }

    receive("Stop Mint") {
        self.requireOwner();
        self.mintable = false;
    }

    receive("Mint") {
        let ctx: Context = context();
        require(self.mintable, "mint stopped");
        require(ctx.sender == self.owner, "Cant mint");
        self.mint(ctx.sender, ton("1000000000"), self.owner); // (to, amount, response_destination)
    }

    fun mint(to: Address, amount: Int, response_destination: Address) {
        self.total_supply = self.total_supply + amount; // Update total supply

        let winit: StateInit = self.getJettonWalletInit(to); // Create message
        send(SendParameters{
            to: contractAddress(winit), 
            value: 0, 
            bounce: false,
            mode: SendRemainingValue,
            body: TokenTransferInternal{ 
                queryId: 0,
                amount: amount,
                from: myAddress(),
                response_destination: response_destination,
                forward_ton_amount: ton("0.05"),
                forward_payload: emptySlice()
            }.toCell(),
            code: winit.code,
            data: winit.data
        });
    }

    receive(msg: ProvideWalletAddress) {
        let ctx: Context = context();
        let wallet: Address = contractAddress(initOf JettonDefaultWallet(msg.owner_address, myAddress()));
        let owner_address: Address? = null;
        if (msg.include_address) {
            owner_address = msg.owner_address;
        }
        send(SendParameters {
            to: ctx.sender,
            value: 0,
            mode: SendRemainingValue,
            body: TakeWalletAddress{
                query_id: msg.query_id,
                wallet_address: wallet,
                owner_address: owner_address
            }.toCell()
        });
    }

    fun requireWallet(owner: Address) {
        let ctx: Context = context();
        let winit: StateInit = self.getJettonWalletInit(owner);
        require(contractAddress(winit) == ctx.sender, "Invalid sender");
    }

    fun getJettonWalletInit(address: Address): StateInit {
        return initOf JettonDefaultWallet(myAddress(), address);
    }

    get fun get_jetton_data(): MasterData {
        return MasterData{total_supply: self.total_supply, mintable: self.mintable, owner: self.owner, jetton_content: self.jetton_content, jetton_wallet_code: (initOf JettonDefaultWallet(self.owner, myAddress())).code};
    }

    get fun get_wallet_address(owner_address: Address): Address {
        let init: StateInit = initOf JettonDefaultWallet(owner_address, myAddress());
        return contractAddress(init);
    }
    
}