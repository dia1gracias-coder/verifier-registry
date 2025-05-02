import "./predict_market_event.tact";

message CreateEvent {
    oracle: Address;
    data: Slice as remaining;
}


contract PredictMarketMaster {

    owner: Address;

    next_item_index: Int as uint32 = 0;

    init(_owner: Address) {
        self.owner = _owner;
    }

    //*********************************//
    //             Messages            //
    //*********************************//

    // This is when you don't want to send excesses back
    receive() {}

    receive(msg: CreateEvent) {
        self._create_event(msg);
    }

    //*********************************//
    //       Internal functions        //
    //*********************************//

    inline fun _create_event(msg: CreateEvent) {
        self._only_owner();

        let ctx: Context = context();

        let name: String = msg.data.asString();
        let time: Int = msg.data.loadUint(32);

        let state: StateInit = self._get_market_event_state(self.next_item_index);

        send(SendParameters{
            to: contractAddress(state),
            value: 0,
            mode: SendIgnoreErrors + SendRemainingValue,
            body: Init{
                name: name,
                time: time,
                oracle: msg.oracle
            }.toCell(),
            data: state.data,
            code: state.code,
        });

        self.next_item_index = self.next_item_index + 1;

    }

    inline fun _only_owner() {
        nativeThrowUnless(132, sender() == self.owner);
    }

    inline fun _get_market_event_state(item_index: Int): StateInit {
        return initOf PredictMarketEvent(myAddress(), item_index);
    }

    inline fun _get_market_event_address(item_index: Int): Address {
        return contractAddress(self._get_market_event_state(item_index));
    }

    //*********************************//
    //             Getters             //
    //*********************************//

    get fun get_owner(): Address {
        return self.owner;
    }

    get fun get_current_index(): Int {
        return self.next_item_index;
    }

    get fun get_market_event_address(item_index: Int): Address {
        return self._get_market_event_address(item_index);
    }

    get fun get_market_event_state(item_index: Int): StateInit {
        return self._get_market_event_state(item_index);
    }
}
