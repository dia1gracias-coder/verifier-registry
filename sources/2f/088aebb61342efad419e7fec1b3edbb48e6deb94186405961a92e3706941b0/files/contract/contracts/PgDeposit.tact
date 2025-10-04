// this trait has to be imported
import "@stdlib/ownable";
import "./Includes";

contract PgDeposit with Ownable, Upgradable {
    owner: Address; // factory
    version: Int as uint32 = 0;
    merchant: Address;

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

    receive(msg: DepFundoutInternal) {

        self.requireOwner();

        nativeReserve(minTonsForStorage, ReserveExact | ReserveBounceIfActionFail);
        
        let numBeneficiaries: Int = 0;
        foreach (_, _ in msg.beneficiaryIdxes) {
            numBeneficiaries+=1;
        }
       
        let amount = msg.amount;
        
        let fees: Int = amount * self.fees / 10000;
        let shareRevenue: Int = (fees * self.shareRevenue) / 10000;
        let afterFees: Int = amount - fees;
        let share: Int = afterFees / numBeneficiaries;
        //let remainder: Int = afterFees - (share * numBeneficiaries); //ignore remainder
        if (msg.wkCompany == self.referral) {
            _transferFromContract(msg.depositJWallet, msg.queryId, fees, msg.wkCompany, self.merchant, gasNanoForTransfer);
        } else {
            _transferFromContract(msg.depositJWallet, msg.queryId, fees - shareRevenue, msg.wkCompany, self.merchant, gasNanoForTransfer);
            _transferFromContract(msg.depositJWallet, msg.queryId, shareRevenue, self.referral, self.merchant, gasNanoForTransfer);    
        }
        
        foreach (_, beneficiaryIdx in msg.beneficiaryIdxes) {
            _transferFromContract(msg.depositJWallet, msg.queryId, share, self.beneficiaries.get(beneficiaryIdx)!!, self.merchant, gasNanoForTransfer);
        }
        
        //send excess
        message(MessageParameters {
            mode: SendRemainingBalance | SendIgnoreErrors,
            body: null,
            value: 0,
            to: self.merchant,
            bounce: false,
        });
    }

    receive(msg: DepFundoutTonInternal) {

        self.requireOwner(); 
        nativeReserve(minTonsForStorage, ReserveExact | ReserveBounceIfActionFail);

        let ctx: Context = context();
        let msgValue: Int = ctx.value;
        let checkAmount = myBalance() - msgValue;

        require(msg.amount<=checkAmount, "insufficient amount");
      
        let amount = msg.amount;

        let numBeneficiaries: Int = 0;
        foreach (_, _ in msg.beneficiaryIdxes) {
            numBeneficiaries+=1;
        }

        let fees: Int = amount * self.fees / 10000;
        let shareRevenue: Int = (fees * self.shareRevenue) / 10000;
        let afterFees: Int = amount - fees;
        let share: Int = afterFees / numBeneficiaries;
        let remainder: Int = afterFees - (share * numBeneficiaries); //ignore remainder
        
        if (msg.wkCompany == self.referral) {
            _transferTonFromContract(msg.wkCompany, msg.queryId, fees);
        } else {
            _transferTonFromContract(msg.wkCompany, msg.queryId, fees - shareRevenue);
            _transferTonFromContract(self.referral, msg.queryId, shareRevenue);    
        }
        
        foreach (_, beneficiaryIdx in msg.beneficiaryIdxes) {
            _transferTonFromContract(self.beneficiaries.get(beneficiaryIdx)!!, msg.queryId, share + remainder);
            //dump(remainder);
            remainder = 0; // ady given to 1st beneficiary
        }

        //send excess
        message(MessageParameters {
            mode: SendRemainingBalance | SendIgnoreErrors,
            body: null,
            value: 0,
            to: self.merchant,
            bounce: false,
        });
    }
    
    get fun data(): DepositData {
        return DepositData{
            owner: self.owner,
            version: self.version,
            merchant: self.merchant,
            fees: self.fees,
            shareRevenue: self.shareRevenue,
            referral: self.referral,
            beneficiaries: self.beneficiaries
        };
    } 

    get fun jettonWalletAddress(dataLayoutId: Int, code: Cell, minter: Address, owner: Address): Address {
        return _jettonWalletAddress(dataLayoutId, code, minter, owner);
    }   
}
