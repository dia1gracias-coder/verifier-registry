import "@stdlib/deploy";
import "@stdlib/ownable";

message PaymentEvent {
    amount: Int as coins;
    sender: Address;
	typeitem: Int as uint8;
	iditem: Int as uint8;
}

message MakePayment {
	typeItem: Int as uint8;
	idItem: Int as uint8;
    sponsorAddress: Address;
}

message ActivateReferralLink {
    sponsorAddress: Address;
}

message ActivateReferralLinkByOwner {
    referralAddress: Address;
    sponsorAddress: Address;
}

message ChangeReferralLinkByOwner {
    referralAddress: Address;
    sponsorAddress: Address;    
}

message SetMinimalAmount {
    minAmount: Int as coins;
}

contract GtwContract with Deployable, Ownable {
    const ForStorage: Int = ton("0.25");

    owner: Address;
    recipient: Address;

    referralTree: map<Address, Address>;

    tonsTotalAmount: Int as coins = 0;
    minAmount: Int as coins;

    init(recipient: Address) {
        self.owner = sender();
        self.recipient = recipient;

        self.minAmount = 1000000000;

        self.referralTree.set(recipient, sender());

    }

    fun onlyOwner(){
        require(sender() == self.owner, "only owner can use this method");
    }

    fun notSender(address: Address) {
        require(sender() != address, "address same as yours");
    }

    fun minimalAmount() {
        require(context().value >= self.minAmount, "minimal amount is 1 ton");
    }

    fun referralPayment(sponsor: Address, amount: Int) {
        let bonusOne: Int = (amount*7)/100;
        self.sendPayment(sponsor, bonusOne);
        let levelTwo: Address? = self.referralTree.get(sponsor);
        if(levelTwo != null) {
            let bonusTwo: Int = (amount*5)/100;
            self.sendPayment(levelTwo!!, bonusTwo);
            let levelThree: Address? = self.referralTree.get(levelTwo!!);
            if(levelThree != null) {
                let bonusThree: Int = (amount*3)/100;
                self.sendPayment(levelThree!!, bonusThree);
            }
        }
    }

    fun sendPayment(address: Address, value: Int) {
        send(SendParameters{
            to: address,
            bounce: true,
            value: value,
            mode: SendIgnoreErrors,
			body: "referral income".asComment(),
        });   
    }

    receive(msg: MakePayment) {
        self.minimalAmount();
        self.notSender(msg.sponsorAddress);
        if(self.referralTree.get(sender()) == null) {
            self.referralTree.set(sender(), msg.sponsorAddress);
        }
		
		emit(PaymentEvent{amount: context().value, sender: sender(), typeitem: msg.typeItem, iditem: msg.idItem}.toCell());
		
        self.referralPayment(msg.sponsorAddress, context().value);
    }

    receive(msg: String) {
        
    }

    receive(msg: Slice) {
        
    }

    receive(msg: ActivateReferralLink) {
        self.notSender(msg.sponsorAddress);
        if (self.referralTree.get(msg.sponsorAddress) != null) {
            if(self.referralTree.get(sender()) == null) {
                self.referralTree.set(sender(), msg.sponsorAddress);
            }
        }
    }

    receive(msg: ActivateReferralLinkByOwner) {
        self.onlyOwner();
        if (self.referralTree.get(msg.sponsorAddress) != null) {
            if(self.referralTree.get(msg.referralAddress) == null) {
                self.referralTree.set(msg.referralAddress, msg.sponsorAddress);
            }
        }
    }

    receive(msg: ChangeReferralLinkByOwner) {
        self.onlyOwner();
        self.referralTree.set(msg.referralAddress, msg.sponsorAddress);
    }

    receive(msg: SetMinimalAmount) {
        self.onlyOwner();
        self.minAmount = msg.minAmount;
    }

    receive("withdraw all"){
        self.onlyOwner();
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors
        });
    }

    receive("withdraw tons"){
        self.onlyOwner();
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: myBalance() - context().value - self.ForStorage,
            mode: SendIgnoreErrors + SendRemainingValue
        });
    }

    get fun get_sponsor(referral: Address): Address? {
        return self.referralTree.get(referral);
    }

    get fun referral_tree(): map<Address, Address> {
        return self.referralTree;
    }

    get fun get_total_tons(): Int {
        return self.tonsTotalAmount;
    }

    get fun balance(): String {
        return myBalance().toCoinsString();
    }

    get fun min_amount(): Int {
        return self.minAmount;
    }
}
