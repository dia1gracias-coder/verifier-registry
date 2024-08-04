
import "./administration";

trait DataStorage with Administration {

// access control --------------------------------------------------------------------
    owner : Address;
    accessList : AddrArray;
    hasAccess: map<Address, Bool>;

// administration --------------------------------------------------------------------
    isActive: Bool;
    jettonList : AddrArray;
    hasJetton : map<Address, Bool>;


// data storage --------------------------------------------------------------------
    
    txExists: map<Int, Bool>;
    userDepositList: map<Address, Array>;
    
    userIdToAddr: map<Int, Address>;
    userReferral: map<Address, Address>;
    userJettonBanned: map<Int, Bool>;

    refPlan: Uint16Array;
    contPlans: map<Address, ContPlanArray>;

    // deposit
    userJettonDeposits: map<Int, PaymentArray>;

    // claim
    userJettonClaims: map<Int, PaymentArray>;
    userJettonTotalClaimed: map<Int, Int>;
    userJettonMaxClaimFraction: map<Int, Int>;
    userJettonClaimableTemp: map<Int, Int>;


// deposit ----------------------------------------------------------------------------------
    fun setUserAddr(userId: Int, userAddr: Address) {
        if(self.userIdToAddr.get(userId) == null){
            self.userIdToAddr.set(userId, userAddr);
        }
    }

    fun setReferral(userId: Int, userAddr: Address, refAddr: Address?) {
        if(
            self.userIdToAddr.get(userId) == null
        ) {
            require(refAddr != null, "referral does not exist");
            self.userReferral.set(userAddr, refAddr!!);
        }
    }


    fun _setDepositData(userJetton: Int, jetton: Address, amount: Int) {
        let _timestamp = now();

        // get latest deposit list
        let _latestDepositList = emptyPaymentArray();
        if(self.userJettonDeposits.get(userJetton) != null){
            _latestDepositList = self.userJettonDeposits.get(userJetton)!!;
        } 

        // initial latest
        let _latestDeposit = Payment{amount: 0, profit: 0, timestamp: 0};

        // check if there is any deposit before
        if(_latestDepositList.length != 0) {
            // get latest deposit
            _latestDeposit = _latestDepositList.paymentArrayLast();
        }

        // total amount
        let _totalAmount = _latestDeposit.amount + amount;

        // get profit
        let contPlan = self._getProfit(_totalAmount, jetton);
        let _profit = contPlan.profit * _totalAmount / 10000;

        //set limitation
        self.userJettonMaxClaimFraction.set(userJetton, contPlan.limit);

        // update latest deposit
        _latestDeposit = Payment{amount: _totalAmount, profit: _profit, timestamp: _timestamp};


        // append to the deposit list temp
        _latestDepositList.paymentArrayAppend(_latestDeposit);

        // set the new deposit list  
        self.userJettonDeposits.set(userJetton, _latestDepositList);
    }


    fun _payUpline(userAddr: Address, amount: Int) {
        let list = self.refPlan.list;
        foreach (key, value in list) { // or just k, v
            if(
                self.userReferral.get(userAddr) != null 
            ) {
                let refAmount = amount * value / 10000;
                // _refEarn[refAddr][i] += refAmount;
                // payable(refAddr).transfer(refAmount);
            }
            userAddr = self.userReferral.get(userAddr)!!;
        }
    }

    fun _stakeValue(amount: Int) {
        // an array of addresses and percentages
        // pay to every address the percent
    }


    fun _getProfit(amount: Int, jetton: Address) : ContPlan {
        let contPlans = self.contPlans.get(jetton)!!;
        foreach (key, value in contPlans.minValue) {
            if(amount >= value) {
                return contPlans.contPlanGetIdx(key);
            }
        }
        return ContPlan {minValue: 0, profit: 0, limit: 0};
    }


// claim ----------------------------------------------------------------------------------

    
    fun _claimable(userJetton: Int) : Int {
        let _timestamp = now();

        // get latest deposit list
        let _latestDepositList = emptyPaymentArray();
        if(
            self.userJettonDeposits.get(userJetton) != null 
            && self.userJettonBanned.get(userJetton) != true
        ){
            _latestDepositList = self.userJettonDeposits.get(userJetton)!!;

            // initial latest
            let _latestDeposit = Payment{amount: 0, profit: 0, timestamp: 0};
    
            // check if there is any deposit before
            if(_latestDepositList.length != 0) {
                // get latest deposit
                _latestDeposit = _latestDepositList.paymentArrayLast();
            }

            require(_latestDeposit.timestamp > 0, "there is no deposit");

            // get the days after latest deposit
            let days = (_timestamp - _latestDeposit.timestamp) / 10*24*60*60;

            // get the latest profit 
            let latestProfit = days * _latestDeposit.profit;

            if(self.userJettonClaimableTemp.get(userJetton) != null) {
                latestProfit = self.userJettonClaimableTemp.get(userJetton)!! + latestProfit;
            }

            // get maximum claimable
            let maxClaim = _latestDeposit.amount * (self.userJettonMaxClaimFraction.get(userJetton)!!) / 10000;

            let totalClaimed = 0;
            if(self.userJettonTotalClaimed.get(userJetton) != null) {
                totalClaimed = self.userJettonTotalClaimed.get(userJetton)!!;
            }

            let totalClaimable = totalClaimed + latestProfit;
            if (totalClaimable < maxClaim) {
                return latestProfit;
            } else {
                if (totalClaimed < maxClaim) {
                    return maxClaim - totalClaimed;
                } else {
                    return 0;
                }
            }

        } else {
            return 0;
        }
    }


    fun _setClaimData(userJetton: Int, amount: Int) {

        // append the claim
        let claimArray_ = emptyPaymentArray();
        if(self.userJettonClaims.get(userJetton) != null) {
            claimArray_ = self.userJettonClaims.get(userJetton)!!;
        }
        claimArray_.paymentArrayAppend(Payment{amount: amount, profit: 0, timestamp: now()});
        self.userJettonClaims.set(userJetton, claimArray_);

        // set latest amount claimed
        let latestClaimed = 0;
        if(self.userJettonTotalClaimed.get(userJetton) != null) {
            latestClaimed = self.userJettonTotalClaimed.get(userJetton)!!;
        }
        self.userJettonTotalClaimed.set(userJetton, latestClaimed + amount);

    }




// transfer jetton ----------------------------------------------------------------------------------

    fun _transferJetton(jetton: Address, receiver: Address, amount: Int) {

    }

}



struct UserAndJetton {
    userAddr: Address;
    jetton: Address;
}
fun userJettonHash(userAddr: Address, jetton: Address): Int {
    let a = sha256(UserAndJetton{userAddr: userAddr, jetton: jetton}.toCell().asSlice());
    return a;
}



// struct UserStruct {
//     userAddr: Address;
//     refAddr: Address;
// }