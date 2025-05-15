
message(0xe3f0fd90) RemoveToWhitelist {
    address: Address;
    query_id: Int as uint64;
}

message(0xc7aaf20e) AddToWhitelist {
    address: Address;
    query_id: Int as uint64;
}

struct List {
    _map: map<Address, Bool>;
}


extends mutates fun del(self: List, key: Address) {
    self._map.set(key, null);
}


trait Whitelist {
    list: List;

    //*********************************//
    //             Messages            //
    //*********************************//

    receive(msg: RemoveToWhitelist) {
        self._removeList(msg);
    }
    
    receive(msg: AddToWhitelist) {
        self._addList(msg);
    }

    //*********************************//
    //       Internal functions        //
    //*********************************//

    virtual inline fun _isInList(address: Address): Bool {
        let isValid:Bool? = self.list._map.get(address);
        return isValid == true;
    }

    virtual inline fun _isNotInList(address: Address): Bool {
        let isValid:Bool? = self.list._map.get(address);
        return isValid == false;
    }

    virtual inline fun _addList(msg: AddToWhitelist) {
        self._canEditList();
        self.list._map.set(msg.address, true);
    }

    virtual inline fun _removeList(msg: RemoveToWhitelist) {
        self._canEditList();

        self.list._map.del(msg.address);
    }

    virtual inline fun _canEditList() {}

    //*********************************//
    //             Getters             //
    //*********************************//

    get fun get_list(): List {
        return self.list;
    }

}