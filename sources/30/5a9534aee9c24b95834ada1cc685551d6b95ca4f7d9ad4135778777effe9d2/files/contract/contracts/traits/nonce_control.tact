message ResetNonce {}

trait NonceControl {
  owner: Address;
  nonce: Int;

  receive(msg: ResetNonce) {
    require(sender() == self.owner, "NonceControl: caller is not an owner");
    self.nonce = 0;

    self.reply("Nonce reset".asComment())
  }

  fun incrementNonce() {
    self.nonce += 1;
  }

  fun setNonce(newNonce: Int) {
    self.nonce + newNonce;
  }

  fun requireValidNonce(nonce: Int) {
    require(self.nonce < nonce, "NonceControl: nonce collision");
  }

  get fun nonce(): Int {
    return self.nonce;
  }
}