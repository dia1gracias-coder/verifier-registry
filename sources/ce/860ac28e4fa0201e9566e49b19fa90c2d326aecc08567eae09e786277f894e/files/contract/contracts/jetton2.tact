import "@stdlib/deploy";
import "@stdlib/ownable";
import "./JettonWallet.tact"; // Import wallet properly

// Messages
message Mint {
    amount: Int as coins;
    receiver: Address;
}

message MintDisable {}

// Master Contract
contract Jetton2 with Deployable, Ownable {
    owner: Address;
    content: Cell;
    totalSupply: Int;
    maxSupply: Int;
    mintable: Bool;

    init(owner: Address, content: Cell, maxSupply: Int) {
        self.owner = owner;
        self.content = content;
        self.totalSupply = 0;
        self.maxSupply = maxSupply;
        self.mintable = true;
    }

    receive(msg: Mint) {
        self.requireOwner();
        require(self.mintable, "Minting disabled");
        require(self.totalSupply + msg.amount <= self.maxSupply, "Exceeds max supply");

        self.totalSupply = self.totalSupply + msg.amount;

        let walletInit = self.buildWalletInit(msg.receiver);
        send(SendParameters {
            to: contractAddress(walletInit),
            value: 0,
            bounce: false,
            mode: SendRemainingValue,
            code: walletInit.code,
            data: walletInit.data,
            body: TokenTransferInternal {
                queryId: 0,
                amount: msg.amount,
                from: myAddress(),
                response_destination: self.owner,
                forward_ton_amount: 0,
                forward_payload: emptySlice(),
            }.toCell(),
        });
    }

    receive(msg: MintDisable) {
        self.requireOwner();
        self.mintable = false;
    }

    fun buildWalletInit(owner: Address): StateInit {
        return initOf JeddonWallet(myAddress(), owner);
    }

    get fun get_total_supply(): Int {
        return self.totalSupply;
    }

    get fun get_max_supply(): Int {
        return self.maxSupply;
    }

    get fun is_mintable(): Bool {
        return self.mintable;
    }

    get fun get_content(): Cell {
        return self.content;
    }

    get fun get_wallet_address(owner: Address): Address {
        return contractAddress(self.buildWalletInit(owner));
    }
}
