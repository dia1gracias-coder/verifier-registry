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

contract TokenMaster with Ownable, Deployable {
    total_supply: Int as coins = 0;
    mintable: Bool = true;
    owner: Address;
    minter: Address;
    jetton_content: Cell;
    is_initial_supply: Bool = false;
    supply_amount: Int = 1000000 * 1000000000;
    mint_amount: Int = 10000 * 1000000000; 
    day: Int = 5 * 60; // 24 * 60 * 60
    last_claim_day: Int = 0;
    

    init(owner: Address, minter: Address, jetton_content: Cell) {
        self.owner = owner;
        self.minter = minter;
        self.jetton_content = jetton_content;
    }

    receive("Initial"){
        let ctx: Context = context();
        require(sender() == self.minter, "Invalid minter");
        require(self.is_initial_supply == false, "Initial Supply has been minted");
        require(ctx.readForwardFee() * 2 + 2 * gasConsumption + minTons < ctx.value, "Invalid ton amount");
        require(self.mintable, "Mint stopped");
        self.total_supply = self.total_supply + self.supply_amount;
        let init: StateInit = initOf TokenWallet(self.minter, myAddress());
        let to: Address = contractAddress(init);

        send(SendParameters {
            to: to,
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: InternalTransfer{
                query_id: now(),
                amount: self.supply_amount,
                from: self.minter,
                response_destination: self.minter,
                forward_ton_amount: 0,
                forward_payload: emptySlice()
            }.toCell(),
            data: init.data,
            code: init.code
        });

        self.is_initial_supply = true;
    }

    receive(msg: ChangeContent) {
        self.requireOwner();
        self.jetton_content = msg.jetton_content;
    }

    receive(msg: ChangeMinter) {
        self.requireOwner();
        self.minter = msg.minter;
    }

    fun today(): Int {
        return now() / self.day;
    }

    receive(msg: Mint) {
        let ctx: Context = context();
        require(sender() == self.minter, "Invalid minter");
        require(self.last_claim_day < self.today(), "Claimed today");
        require(self.mintable, "Mint stopped");
        require(ctx.readForwardFee() * 2 + 2 * gasConsumption + minTons < ctx.value, "Invalid ton amount");
        self.total_supply = self.total_supply + self.mint_amount;
        let init: StateInit = initOf TokenWallet(self.minter, myAddress());
        let to: Address = contractAddress(init);
        self.last_claim_day = self.today();

        send(SendParameters {
            to: to,
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: InternalTransfer{
                query_id: now(),
                amount: self.mint_amount,
                from: self.minter,
                response_destination: self.minter,
                forward_ton_amount: 0,
                forward_payload: emptySlice()
            }.toCell(),
            data: init.data,
            code: init.code
        });
    }

    receive("Change Mint Status") {
        self.requireOwner();
        self.mintable = !self.mintable;
    }

    get fun get_jetton_data(): MasterData {
        return MasterData{total_supply: self.total_supply, mintable: self.mintable, owner: self.owner, jetton_content: self.jetton_content, jetton_wallet_code: (initOf TokenWallet(self.owner, myAddress())).code};
    }

    get fun get_wallet_address(owner_address: Address): Address {
        let init: StateInit = initOf TokenWallet(owner_address, myAddress());
        return contractAddress(init);
    }

    get fun get_minter_address(): Address {
        return self.minter;
    }

    get fun get_owner_address(): Address {
        return self.owner;
    }

    get fun get_last_claim_day(): Int {
        return self.last_claim_day;
    }

    get fun get_today(): Int {
        return self.today();
    }
}