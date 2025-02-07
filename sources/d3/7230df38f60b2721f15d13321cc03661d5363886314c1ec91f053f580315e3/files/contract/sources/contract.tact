import "@stdlib/deploy";

contract Lottery with Deployable {

    owner: Address;
    address: map<Address, Bool>;
    lenght: Int;

    init(owner: Address) {
        self.owner = owner;
        self.address =  emptyMap();
        self.lenght = 0;
    }

    fun saveSender() {
        let ctx: Context = context();

        self.address.set(ctx.sender, true);
        self.lenght += 1;
    }

    fun checkingTheStartOfTheLottery(): Bool {
        if (self.lenght >= 3) {
            return true;
        }
        return false;
    }

    receive(){
        self.saveSender();
        if (self.checkingTheStartOfTheLottery()) {
            self.reply("The lottery has ready run".asComment());
        }else{
            self.reply("The lottery has not yet started run".asComment());
        }
    }
}

