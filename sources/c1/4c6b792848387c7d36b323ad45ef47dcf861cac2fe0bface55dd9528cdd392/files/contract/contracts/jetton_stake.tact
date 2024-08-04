import "@stdlib/deploy";
import "@stdlib/ownable";
import "./stake/messages";
import "./jetton_sample";
import "./stake/data_storage";


contract JettonStake with Deployable, DataStorage {

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


    init(refPlan: Uint16Array, contPlan: ContPlanArray, initialJetton: Address) {
        self.owner = sender();
        self.accessList = emptyAddrArray();
        self.jettonList = emptyAddrArray();
        self.refPlan = emptyUint16Array();
        self.isActive = true;
        self.refPlan = refPlan;
        self.contPlans.set(initialJetton, contPlan);
    }

    get fun get_jetton_list() : AddrArray? {
        return self.jettonList;
    }

    get fun get_profit_plan(jetton: Address) : ContPlanArray? {
        return self.contPlans.get(jetton);
    }

    get fun get_referral_plan() : Uint16Array? {
        return self.refPlan;
    }

    get fun get_user_address(userId: Int) : Address? {
        return self.userIdToAddr.get(userId);
    }

    get fun get_user_deposits(userId: Int, jetton: Address) : PaymentArray? {
        let userAddr = self.userIdToAddr.get(userId)!!;
        let userJetton = userJettonHash(userAddr, jetton);
        return self.userJettonDeposits.get(userJetton);
    }

    get fun get_user_withdraws(userId: Int, jetton: Address) : PaymentArray? {
        let userAddr = self.userIdToAddr.get(userId)!!;
        let userJetton = userJettonHash(userAddr, jetton);
        return self.userJettonClaims.get(userJetton);
    }

    get fun get_user_withdrawable(userId: Int, jetton: Address) : Int? {
        let userAddr = self.userIdToAddr.get(userId)!!;
        let userJetton = userJettonHash(userAddr, jetton);
        return self._claimable(userJetton);
    }


    receive(msg: TokenNotification){
        // require(context().value >= ton("0.1"), "not enough value");
        // let _userArray = emptyArray();
        // if(self.userDepositList.get(msg.from) != null){
        //     _userArray = self.userDepositList.get(msg.from)!!;
        // } 
        // _userArray.append(msg.amount);
        // self.userDepositList.set(msg.from, _userArray);
        // self.userIdDepositList.set(msg.forward_payload.toInt(), _userArray);
        // self.theSliceInt = msg.forward_payload.toInt();
    }


    receive(msg: Deposit){
        self.requireAccess();
        require(self.hasJetton.get(msg.jetton) == true, "jetton does not exist");
        require(self.txExists.get(msg.txId) != true, "this tx has been set before.");
        let userJettonInt = userJettonHash(msg.userAddr, msg.jetton);

        if(msg.refId != 0){
            self.setReferral(msg.userId, msg.userAddr, self.userIdToAddr.get(msg.refId));
        }
        self.txExists.set(msg.txId, true);
        self._setDepositData(userJettonInt, msg.jetton, msg.amount);
        self._payUpline(msg.userAddr, msg.amount);
        self._stakeValue(msg.amount);
        self.setUserAddr(msg.userId, msg.userAddr);
    }



    receive(msg: Withdraw){
        self.requireAccess();
        require(self.isActive, "contract is not active");
        require(self.hasJetton.get(msg.jetton) == true, "jetton does not exist");
        require(self.userIdToAddr.get(msg.userId) != null, "user does not exist");

        let userAddr = self.userIdToAddr.get(msg.userId)!!;
        let userJettonInt = userJettonHash(userAddr, msg.jetton);


        let _amountClaimable = self._claimable(userJettonInt);


        // get minimum claim for this token
        let _minClaimable = 0; //# should be edited
        // get claim fee for this token
        let _claimFee = 0; //# should be edited
        require(
            _amountClaimable >= _minClaimable &&
            _amountClaimable > _claimFee,
            "insufficient amount to claim"
        );

        self._setClaimData(userJettonInt, _amountClaimable);
        self._transferJetton(msg.jetton, userAddr, _amountClaimable - _claimFee);
    }


}
