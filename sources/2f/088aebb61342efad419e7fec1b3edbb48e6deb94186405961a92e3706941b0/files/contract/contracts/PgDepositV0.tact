// this trait has to be imported
import "@stdlib/ownable";

contract PgDepositV0 with Ownable, Upgradable {
    owner: Address; // factory
    version: Int as uint32 = 0;
    merchant: Address;

    // deposit
    fees: Int as uint16;
    shareRevenue: Int as uint16;
    referral: Address;
    beneficiaries: map<Int as uint8, Address>;
    
    // extra state
    extra: map<Int as uint32, Cell>;

    init(factory: Address, merchant: Address) {
        self.owner = factory; 
        self.merchant = merchant;
        self.fees = 0;
        self.shareRevenue = 0;
        self.referral = _emptyAddress();
    }

    receive(msg: RegisterInternal) {

        self.requireOwner(); 
        nativeReserve(minTonsForStorage, ReserveExact | ReserveBounceIfActionFail);
        
        self.beneficiaries = msg.beneficiaries;
        self.fees = msg.fees;
        self.shareRevenue = msg.shareRevenue;
        self.referral = msg.referral;

        let i: Int = 0;
        foreach (k, beneficiary in msg.beneficiaries) {
            self.beneficiaries.set(i, beneficiary);
            i+=1;
        }

        if (msg.newCode != null) {
            setCode(msg.newCode!!);
        }   

        // send excess
        message(MessageParameters {
            bounce: false,
            to: self.merchant,
            value: 0,
            mode: SendRemainingBalance | SendIgnoreErrors,
        });

    }
}