import "@stdlib/ownable";
import "@stdlib/deploy";
import "./HeroTokenMessages.tact";
import "./HeroTokenWallet.tact";

struct JettonData {
    owner: Address;
    content: Cell;
    mintable: Bool;
    totalSupply: Int;
    walletCode: Cell;
}

contract HeroToken with Jetton {
    owner: Address;
    content: Cell;
    mintable: Bool;
    totalSupply: Int as coins;
    maxSupply: Int as coins; 

    init(owner: Address, content: Cell, maxSupply: Int) {
        self.owner = owner;
        self.content = content;
        self.mintable = true;
        self.totalSupply = 0;
        self.maxSupply = maxSupply;
    }

    receive(msg: Mint) {
        self.requireOwner();
        require(self.mintable, "Token mint: Minting forbidden");
        self.mint(msg.to, msg.amount, self.owner);
    }
} 

@interface("org.ton.jetton.master")
trait Jetton with Deployable, OwnableTransferable {
    owner: Address;
    content: Cell;
    mintable: Bool;
    totalSupply: Int;
    maxSupply: Int;

    receive(msg: UpdateContent) {
        self.requireOwner();
        self.content = msg.content;
    }

    receive(msg: BurnNotification) {
        self.requireWallet(msg.owner);
        self.totalSupply = self.totalSupply - msg.amount;

        if (msg.response_destination != null) {
            send(SendParameters{
                to: msg.response_destination!!, 
                value: 0,
                bounce: false,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: Excesses{ query_id: msg.query_id }.toCell()
            });
        }
    }

   fun mint(to: Address, amount: Int, responseDestination: Address) {
        require(self.totalSupply + amount <= self.maxSupply, "Token mint: Max supply exceeded");
        self.totalSupply = self.totalSupply + amount;
        if (self.totalSupply >= self.maxSupply) {
            self.mintable = false;
        }

        let stateInit: StateInit = self.getJettonWalletInit(to);
        send(SendParameters{
            to: contractAddress(stateInit), 
            value: 0, 
            bounce: false,
            mode: SendRemainingValue,
            body: InternalTransfer{ 
                query_id: 0,
                amount: amount,
                from: myAddress(),
                response_destination: responseDestination,
                forward_ton_amount: 0,
                forward_payload: emptySlice()
            }.toCell(),
            code: stateInit.code,
            data: stateInit.data
        });
    }

    fun requireWallet(owner: Address) {
        let stateInit: StateInit = self.getJettonWalletInit(owner);
        require(contractAddress(stateInit) == sender(), "Token burn notification: Invalid sender");
    }

    virtual fun getJettonWalletInit(address: Address): StateInit {
        return initOf HeroTokenWallet(myAddress(), address);
    }

    get fun get_jetton_data(): JettonData {
        let stateInit: StateInit = self.getJettonWalletInit(myAddress());
        return JettonData{ 
            owner: self.owner, 
            content: self.content, 
            totalSupply: self.totalSupply, 
            mintable: self.mintable, 
            walletCode: stateInit.code
        };
    }

    get fun get_wallet_address(owner: Address): Address {
        let stateInit: StateInit = self.getJettonWalletInit(owner);
        return contractAddress(stateInit);
    }
}