struct Balance {
  ton: Int as coins = 0;
  usdt: Int as coins = 0;
}

extends fun add(self: Balance, other: Balance): Balance {
  return Balance {
    ton: self.ton + other.ton,
    usdt: self.usdt + other.usdt,
  };
}