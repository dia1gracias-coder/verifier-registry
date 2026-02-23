import "@stdlib/deploy";
import "./jetton_wallet.tact";

message Mint {
    amount: Int as coins;
    receiver: Address;
}

contract JettonMinter with Deployable {
    owner: Address;
    totalSupply: Int as coins;
    name: String;
    symbol: String;
    decimals: Int as uint8;

    init(owner: Address) {
        self.owner = owner;
        self.totalSupply = 0;
        self.name = "MyToken";
        self.symbol = "MTK";
        self.decimals = 9;
    }

    receive(msg: Mint) {
        require(sender() == self.owner, "Only owner can mint");
        require(msg.amount > 0, "Amount must be positive");
        self.totalSupply = self.totalSupply + msg.amount;

        let init: StateInit = initOf JettonWallet(msg.receiver, myAddress());
        send(SendParameters{
            to: contractAddress(init),
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            code: init.code,
            data: init.data,
            body: JettonTransferInternal{
                queryId: 0,
                amount: msg.amount,
                from: myAddress(),
                responseDestination: self.owner,
                forwardAmount: 0,
            }.toCell()
        });
    }

    get fun totalSupply(): Int {
        return self.totalSupply;
    }

    get fun owner(): Address {
        return self.owner;
    }

    get fun name(): String {
        return self.name;
    }

    get fun symbol(): String {
        return self.symbol;
    }

    get fun decimals(): Int {
        return self.decimals;
    }
}
