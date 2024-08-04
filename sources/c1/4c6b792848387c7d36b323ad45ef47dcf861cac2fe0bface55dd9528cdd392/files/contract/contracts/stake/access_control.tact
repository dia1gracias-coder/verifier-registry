import "@stdlib/ownable";
import "./utils/arrays";

trait AccessControl with Ownable {

    owner: Address;
    accessList : AddrArray;
    hasAccess : map<Address, Bool>;

    fun requireAccess() {
        nativeThrowUnless(132, self.hasAccess.get(sender()) == true);
    }

    get fun get_access_list(): AddrArray {
        return self.accessList;
    }

    get fun get_has_access(userAddr: Address): Bool? {
        return self.hasAccess.get(userAddr);
    }

    get fun get_admin_exists(userAddr: Address): Bool? {
        return self.accessList.addrIsInList(userAddr);
    }

    receive(msg: AddToAccessList) {
        self.requireOwner();
        require(!self.accessList.addrIsInList(msg.userAddr), "already exists");
        self.accessList.addrArrayAppend(msg.userAddr);
        self.hasAccess.set(msg.userAddr, true);
    }

    receive(msg: RemoveFromAccessList) {
        self.requireOwner();
        let index = 0;
        let exist = false;
        let list = self.accessList.list;
        foreach (key, value in list) { // or just k, v
            if(value == msg.userAddr) {
                exist = true;
                index = key;
            }
        }
        require(exist, "does not exist");
        self.accessList.addrArrayDeleteIdx(index);
        self.hasAccess.set(msg.userAddr, false);
    }
}

message AddToAccessList {
    userAddr: Address;
}

message RemoveFromAccessList {
    userAddr: Address;
}