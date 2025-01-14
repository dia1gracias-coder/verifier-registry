message BetPlaced {
  roundId: Int as uint32;
  betId: Int as uint32;
  betKey: String;
  symbol: String;
  address: Address;
  tonAmount: Int as coins;  
  jettonAmount: Int as coins;
}

message RoundPayoutCompleted {
  address: Address;
  tonAmount: Int as coins;
  jettonAmount: map<Address, Int as coins>;
}

message RoundEnded {
  roundId: Int as uint32;
  winner: Address;
  tonAmount: Int as coins;
  jettonAmount: map<Address, Int as coins>;
}