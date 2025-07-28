import "@stdlib/deploy";


message Ack {
    queryId: Int as uint64;
}

message Add {
    queryId: Int as uint64;
    amount: Int as int32;
}

contract TactCounter with Deployable {
    id: Int as uint32;
    counter: Int as uint32;

    init(id: Int) {
        self.id = id;
        self.counter = 0;
    }

    // receive(msg: Add) {
        
    //     self.counter += msg.amount;
    // }
        receive("time changes everything") {
        message(MessageParameters {
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            body: "Doing things changes things. Not doing things leaves things exactly as they were".asComment(),
        });
    }

    receive(str: String) {
        message(MessageParameters {
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            body: "Do I get bonus points if I act like I care?".asComment(),
        });
    }
    receive(msg: Add) {
        let sender = context().sender;
        require(msg.queryId != 0, "queryId must not be zero");
        // require(msg.queryId != 0); // валидируем
        self.counter += msg.amount;

        // ответ (например, при bidirectional взаимодействии)
        // send(sender, Ack { queryId: msg.queryId });
        // let msg1 = Ack { queryId: msg.queryId };
        // send(SendParameters {
        //     to: context().sender,
        //     body: msg1.toCell(),
        //     value: 0,
        //     mode: SendRemainingValue
        // });
    }

    get fun counter(): Int {
        return self.counter;
    }

    get fun id(): Int {
        return self.id;
    }
}
