import "@stdlib/deploy";

message SendTON {
  length: Int;
  ton_user_list: map<Int, Address>;
  ton_sending_value: map<Int, Int>;
  memo: String;
}

message TokenTransfer {
  query_id: Int as uint64;
  amount: Int as coins;
  destination: Address;
  response_destination: Address;
  custom_payload: Cell?;
  forward_ton_amount: Int as coins;
  forward_payload: Slice as remaining;
  memo: String;
}

contract Multisender with Deployable {
  // Empty init() function is present by default in all Tact contracts
  // since v1.3.0, so the following may be omitted:
  //
  const min_tons_for_storage: Int = ton("0.03");
  const gas_consumption: Int = ton("0.03");

  init() {}

  receive(msg: SendTON) {
    let ctx: Context = context();
    let msgValue: Int = self.msgValue(ctx.value);
    let value_default: Int = 0;
    let sendingValue: Int = 0;

    do {
      let receiver: Address? = msg.ton_user_list.get(value_default);
      let value_send: Int? = msg.ton_sending_value.get(value_default);
      sendingValue = value_send!! + sendingValue;
      send(SendParameters{
        to: receiver!!,
        value: value_send!!, 
        mode: SendIgnoreErrors,
        bounce: false,
        body: TokenTransfer {
          query_id: value_default,
          amount: msg.ton_sending_value.get(value_default)!!,
          destination: receiver!!,
          response_destination: myAddress(),
          custom_payload: null,
          forward_ton_amount: ton("0.005"),
          forward_payload: emptySlice(),
          memo: msg.memo
        }.toCell()
      });
      value_default =  value_default + 1;
    } until (value_default > msg.length);
  }

  receive(){
    let ctx: Context = context();
    send(SendParameters{
      to: ctx.sender,
      value: ton("0.01"), 
      mode: SendIgnoreErrors + SendRemainingBalance,
      bounce: false
    });
  }

  fun completed(to_address: Address, value: Int) {
    send(SendParameters{
      to: to_address,
      value: value, // msgValue - sendingValue, 
      mode: SendIgnoreErrors, 
      bounce: false,
    });
  }

  fun msgValue(msgValue: Int): Int {
    let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
    let storageFee: Int = self.min_tons_for_storage - min(tonBalanceBeforeMsg, self.min_tons_for_storage);
    msgValue = msgValue - (storageFee + self.gas_consumption);
    return msgValue;
  }
}
