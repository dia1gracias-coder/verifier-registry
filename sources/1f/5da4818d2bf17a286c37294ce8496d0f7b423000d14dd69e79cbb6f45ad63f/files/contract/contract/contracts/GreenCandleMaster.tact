// GreenCandleMaster.tact
// Jetton master: non-mintable, 9 decimals, 10% tax on every wallet->transfer.
// Упрощенная версия для UI деплоя - walletCode вычисляется автоматически

import "./messages";
import "./GreenCandleWallet";
import "@stdlib/deploy";

contract GreenCandleMaster with Deployable {
    admin: Address;
    totalSupply: Int as coins;
    content: Cell;
    taxRecipient: Address;
    mintable: Bool;

    init(
        admin: Address,
        initialSupplyUnits: Int,
        taxRecipient: Address
    ) {
        require(initialSupplyUnits > 0, "supply=0");
        self.admin = admin;
        self.taxRecipient = taxRecipient;
        self.mintable = false;

        // 10^9 для 9 decimals
        self.totalSupply = initialSupplyUnits * 1000000000;

        // Инициализация content напрямую
        let b: StringBuilder = beginString();
        b.append("GreenCandle");
        b.append(";");
        b.append("GC");
        self.content = b.toCell();

        // Вычисляем адрес кошелька напрямую
        let init: StateInit = initOf GreenCandleWallet(admin, myAddress());
        let ownerWallet: Address = contractAddress(init);
        
        send(SendParameters{
            to: ownerWallet,
            value: ton("0.15"),
            mode: SendPayGasSeparately,
            bounce: false,
            body: InternalMint{to: admin, amount: self.totalSupply}.toCell()
        });
        send(SendParameters{
            to: ownerWallet,
            value: ton("0.1"),
            mode: SendPayGasSeparately,
            bounce: false,
            body: InitTax{addr: self.taxRecipient}.toCell()
        });
    }

    get fun get_wallet_address(owner: Address): Address {
        let init: StateInit = initOf GreenCandleWallet(owner, myAddress());
        return contractAddress(init);
    }

    get fun get_wallet_code(): Cell {
        let init: StateInit = initOf GreenCandleWallet(self.admin, myAddress());
        return init.code;
    }

    get fun get_jetton_data(): JettonData {
        let walletCode: Cell = self.get_wallet_code();
        return JettonData{
            totalSupply: self.totalSupply,
            mintable: self.mintable,
            owner: self.admin,
            content: self.content,
            walletCode: walletCode
        };
    }
}

// Структура для get-метода
struct JettonData {
    totalSupply: Int as coins;
    mintable: Bool;
    owner: Address;
    content: Cell;
    walletCode: Cell;
}
