import "@stdlib/ownable";
import "@stdlib/deploy";

message(0x2c76b973) ProvideWalletAddress {
    query_id: Int as uint64;
    owner_address: Address;
    include_address: Bool;
}
message(0xd1735400) TakeWalletAddress {
    query_id: Int as uint64;
    wallet_address: Address;
    owner_address: Cell?;
}

message(0x0f8a7ea5) Transfer {
    query_id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

struct Data {
    owner: Address;
    jetton_wallet: Address;
    master: Address;
}

contract TokenMaster with OwnableTransferable, Deployable {
    owner: Address;
    master: Address;
    jetton_wallet: Address;
    active: Bool;

    init(master: Address, owner: Address) {
        self.owner = owner;
        self.master = master;
        self.jetton_wallet = newAddress(0, 0);
        self.active = true;
    
        send(SendParameters{
            to: self.master,
            value: 0,
            mode: SendRemainingValue,
            body: ProvideWalletAddress{query_id: now(), owner_address: myAddress(), include_address: true}.toCell()
        });
    }

    receive(msg: TakeWalletAddress) {
        let ctx: Context = context();
        require(ctx.sender == self.master, "Invalid sender");
        self.jetton_wallet = msg.wallet_address;
    }

    receive() {
        let ctx: Context = context();
        require(self.active == true, "Off");
        require(myBalance() > ton("0.21"), "Balance");
        require(ctx.value >= ton("1"), "Small amount");
        let value: Int = ctx.value * 5;
        let sendvalue: Int = value / 100000;
        self.send_jetton(self.jetton_wallet, ton("0.20"), 0, now(), sendvalue, sender(), myAddress(), emptyCell());
    }

    receive("Stop") {
        require(sender() == self.owner, "Not owner");
        if (self.active == true) {
            self.active = false;
        }
    }

    receive("Resume") {
        require(sender() == self.owner, "Not owner");
        if (self.active == false) {
            self.active = true;
        }
    }

    receive("W") {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");
        let value: Int = myBalance();
        send(SendParameters{
                to: self.owner,
                value: value, 
                mode: SendRemainingBalance, 
                bounce: true
            });
    }

    fun send_jetton(to: Address, value: Int, mode: Int, query_id: Int, amount: Int, destination: Address, response_destination: Address, custom_payload: Cell) {
        if (amount > 0) {
            send(SendParameters{
                to: to,
                value: value,
                mode: mode,
                bounce: false,
                body: Transfer {
                    query_id: query_id,
                    amount: amount,
                    destination: destination, 
                    response_destination: response_destination, 
                    custom_payload: custom_payload, 
                    forward_ton_amount: 0,
                    forward_payload: beginCell().storeUint(0, 1).endCell().beginParse()}.toCell()
            });
        }
    }

    get fun data(): Data {
        return Data{owner: self.owner, jetton_wallet: self.jetton_wallet, master: self.master};
    }
}