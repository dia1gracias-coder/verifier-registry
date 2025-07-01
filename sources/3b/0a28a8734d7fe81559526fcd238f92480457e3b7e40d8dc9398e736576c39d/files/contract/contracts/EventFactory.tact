import "./Event";

struct EventsResponse {
  nextId: Int;
  eventsCount: Int;
}

message CreateEvent {
  deadline: Int;
  description: String;
}

contract EventFactory {
  admin: Address;
  feeReceiver: Address = address("UQDBFoW7wPlwdqnbIJ0SQMR3HdxYEyrXvACmApKmijTDa4kj"); // ← твой кошелёк
  feeAmount: Int = ton("0.1");

  events: map<Int, Address>;
  nextId: Int = 0;

  init(_admin: Address) {
    self.admin = _admin;
    self.events = emptyMap();
  }

  receive() {
    // пусто
  }

  receive(msg: CreateEvent) {
    require(context().sender == self.admin, "Only admin");

    let sent: Int = context().value;
    require(sent >= ton("0.6"), "Min value = fee + deploy amount");

    let deadline: Int = msg.deadline;
    let desc: String = msg.description;

    // 💸 Перевод комиссии
    send(SendParameters{
      to: self.feeReceiver,
      value: self.feeAmount,
      bounce: false,
      mode: SendIgnoreErrors
    });

    // 🏗 Создаём Event
    let deployAmount = sent - self.feeAmount;

    let eventInit: StateInit = initOf Event(self.admin, deadline, desc);
    let newEventAddr: Address = contractAddress(eventInit);

    send(SendParameters{
      to: newEventAddr,
      value: deployAmount,
      mode: SendIgnoreErrors,
      bounce: false,
      data: eventInit.data,
      code: eventInit.code
    });

    self.events.set(self.nextId, newEventAddr);
    self.nextId = self.nextId + 1;
  }

  get fun get_events(): EventsResponse {
    return EventsResponse{
      nextId: self.nextId,
      eventsCount: self.nextId
    };
  }

  get fun get_event_address(id: Int): Address? {
    return self.events.get(id);
  }
}
