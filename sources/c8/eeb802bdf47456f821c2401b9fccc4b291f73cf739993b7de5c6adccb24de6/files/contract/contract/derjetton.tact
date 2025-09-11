import "@stdlib/deploy";

struct WalletData {
    balance: Int as coins;
    owner: Address;
    master: Address;
}

struct JettonData {
    totalSupply: Int as coins;
    mintable: Bool;
    owner: Address;
    content: Cell;
    walletCode: Cell;
}

contract DERJettonWallet with Deployable {
    master: Address;
    owner: Address;
    balance: Int as coins;

    init(master: Address, owner: Address) {
        self.master = master;
        self.owner = owner;
        self.balance = 0;
    }

    get fun get_wallet_data(): WalletData {
        return WalletData{
            balance: self.balance,
            owner: self.owner,
            master: self.master
        };
    }
}

contract DERJetton with Deployable {
    const name: String = "Islamic Economic Republic";
    const symbol: String = "DER";
    const decimals: Int = 9;

    owner: Address;
    total_supply: Int as coins;
    content: Cell;
    wallet_code: Cell;

    init(owner: Address) {
        self.owner = owner;
        self.total_supply = 100_250_000 * 1_000_000_000; // 100,250,000 DER with 9 decimals
        self.content = beginCell().endCell();
        self.wallet_code = codeOf DERJettonWallet;
    }

    get fun get_jetton_data(): JettonData {
        return JettonData{
            totalSupply: self.total_supply,
            mintable: false,
            owner: self.owner,
            content: self.content,
            walletCode: self.wallet_code
        };
    }

    get fun get_wallet_address(owner: Address): Address {
        return contractAddress(initOf DERJettonWallet(myAddress(), owner));
    }
}
