import "@stdlib/deploy";
import "@stdlib/ownable";
message Withdraw {
    amount: Int as coins;
}

contract DonateList with Deployable, Ownable {
    const minTonForStorage: Int = ton("0.03"); // 1kb for 2,5 year
    const gasConsumption: Int = ton("0.03");
    const minTonForBuyNft: Int = ton("0.5");
    owner: Address;
    contracts: Address;
    next_item_index: Int as uint32 = 0;
    arr: map<Int, Address>;
    arrAddr: map<Address, Int>;

    init(){
        self.owner = sender();
        self.contracts = myAddress();
    }

    receive(){
        require(context().value > ((self.minTonForBuyNft + self.minTonForStorage) + self.gasConsumption),
            "Not enough ton"
        );
        self.mint(sender());
    }

    receive("withdraw safe"){
        self.requireOwner();
        send(SendParameters{
                to: sender(),
                bounce: true,
                value: ((myBalance() - context().value) - self.minTonForStorage),
                mode: (SendIgnoreErrors + SendRemainingValue)
            }
        );
    }

    receive(msg: Withdraw){
        self.requireOwner();
        let amount: Int = min(msg.amount, ((myBalance() - context().value) - self.minTonForStorage));
        require(amount > 0, "Insufficient balance");
        send(SendParameters{to: sender(), value: amount, mode: (SendIgnoreErrors + SendRemainingValue), bounce: true});
    }

    fun mint(receiver: Address) {
        require(self.next_item_index >= 0, "non-sequential NFTs");
        self.arr.set(self.next_item_index, receiver);
        self.arrAddr.set(receiver, self.next_item_index);
        self.next_item_index = (self.next_item_index + 1);
    }

    get fun balance(): Int {
        return myBalance();
    }

    get fun nextItemIndex(): Int {
        return self.next_item_index;
    }

    get fun getListCollectionData(): map<Int, Address> {
        return self.arr;
    }

    get fun getAddress(key: Int): Address? {
        return self.arr.get(key);
    }

    get fun checkAddress(key: Address): Int? {
        return self.arrAddr.get(key);
    }
}