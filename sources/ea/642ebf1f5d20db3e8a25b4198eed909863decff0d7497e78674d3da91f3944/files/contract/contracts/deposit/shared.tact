
message NotifyDeposit {
  user: Address;
  amount: Int;
}

message NotifyDepositEvent {
  user: Address;
  before: Int as coins;
  after: Int as coins;
  counter: Int as uint32;
}


message Deposit {}

message TakeFund {
  amount: Int? as coins;
}

message(0xd53276db) Excesses {
  query_id: Int as uint64 = 0;
}

