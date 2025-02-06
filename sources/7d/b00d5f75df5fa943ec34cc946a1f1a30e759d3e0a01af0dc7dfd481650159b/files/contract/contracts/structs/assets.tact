struct Assets {
  ton: Int as coins = 0;
  usdt: Int as coins = 0;
}

extends fun add(self: Assets, other: Assets): Assets {
  return Assets {
    ton: self.ton + other.ton,
    usdt: self.usdt + other.usdt,
  };
}