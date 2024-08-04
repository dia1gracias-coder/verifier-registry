import "./access_control";

trait Administration with AccessControl {
    owner: Address;
    accessList : AddrArray;
    hasAccess : map<Address, Bool>;

    isActive: Bool;
    jettonList : AddrArray;
    hasJetton : map<Address, Bool>;

    refPlan: Uint16Array;
    contPlans: map<Address, ContPlanArray>;

    // activation ------------------------------------------------------------------------

    get fun get_is_active(): Bool {
        return self.isActive;
    }

    receive("activate") {
        self.isActive = self.isActive ? false : true;
    }


    // jetton list ------------------------------------------------------------------------

    get fun get_has_jetton(jettonAddr: Address): Bool? {
        return self.hasJetton.get(jettonAddr);
    }

    get fun get_jetton_exists(jettonAddr: Address): Bool? {
        return self.jettonList.addrIsInList(jettonAddr);
    }

    receive(msg: AddToJettonList) {
        self.requireOwner();
        require(!self.jettonList.addrIsInList(msg.jettonAddr), "already exists");
        self.jettonList.addrArrayAppend(msg.jettonAddr);
        self.hasJetton.set(msg.jettonAddr, true);
    }

    receive(msg: RemoveFromJettonList) {
        self.requireOwner();
        let index = 0;
        let exist = false;
        let list = self.jettonList.list;
        foreach (key, value in list) { // or just k, v
            if(value == msg.jettonAddr) {
                exist = true;
                index = key;
            }
        }
        require(exist, "does not exist");
        self.jettonList.addrArrayDeleteIdx(index);
        self.hasJetton.set(msg.jettonAddr, false);
    }


    // plans ------------------------------------------------------------------------
    receive(msg: SetContPlan) {
        self.requireOwner();
        self.contPlans.set(msg.jettonAddr, msg.contPlans);
    }

    receive(msg: SetRefPlan) {
        self.requireOwner();
        self.refPlan = msg.refPlan;
    }
}

message AddToJettonList {
    jettonAddr: Address;
}

message RemoveFromJettonList {
    jettonAddr: Address;
}

message SetContPlan {
    jettonAddr: Address;
    contPlans: ContPlanArray;
}

message SetRefPlan {
    refPlan: Uint16Array;
}