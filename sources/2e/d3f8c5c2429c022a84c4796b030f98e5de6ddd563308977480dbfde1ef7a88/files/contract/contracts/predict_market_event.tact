
message Init {
    name: String;
    time: Int as uint32;
    oracle: Address;
}

struct EventData {
    item_index: Int;
    name: String;
    time: Int;
    predict_master: Address;
    count_no:  Int;
    count_yes: Int;
}


message Bet {
    query_id: Int;
    bets: Slice as remaining;
}

contract PredictMarketEvent {

    item_index: Int;
    predict_master: Address;

    oracle: Address;

    is_init: Bool = false;

    name: String;
    time: Int as uint32;

    count_no:  Int = 0;
    count_yes: Int = 0;

    init(_predict_master: Address, _item_index: Int) {
        self.predict_master = _predict_master;
        self.item_index = _item_index;

        self.name = "";
        self.time = 0;  

        self.oracle = newAddress(0, 0);

    }

    //*********************************//
    //             Messages            //
    //*********************************//

    receive(msg: Init) {
        self._init(msg);
    }

    receive(msg: Bet) {
        self._bet(msg);
    }

    //*********************************//
    //       Internal functions        //
    //*********************************//

    inline fun _bet(msg: Bet) {
        self.count_no+= msg.bets.loadUint(32);
        self.count_yes+= msg.bets.loadUint(32);
    }

    inline fun _init(msg: Init) {
        require(self.is_init == false, "Contract init");
        require(sender() == self.predict_master, "Only predict master");

        self.is_init = true;

        self.name = msg.name;
        self.time = msg.time;
        self.oracle = msg.oracle;
    }



    //*********************************//
    //             Getters             //
    //*********************************//


    get fun get_event_data(): EventData {
        return EventData{
            item_index: self.item_index,
            name: self.name,
            time: self.time,
            predict_master: self.predict_master,
            count_no: self.count_no,
            count_yes: self.count_yes,
        };
    }
}
