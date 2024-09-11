struct JettonData {
    total_supply: Int as coins; // the total number of issues jettons
    mintable: Bool;             // flag which indicates whether number of jettons can increase admin_address
    admin_address: Address;     // address of smart-contrac which control Jetton
    jetton_content: Cell;       // data in accordance to Token Data Standard #64
    jetton_wallet_code: Cell;   // code of wallet for that jetton
}

struct UserAmount {
    user: Address;
    amount: Int as coins;
}

struct Country {
    country: String;
    address: Address;
    buyable: Bool;
    sellable: Bool;
}