message AcceptPubKey {
  pubKey: Int;
}

message RevokePubKey {
  pubKey: Int;
}

struct DataWithDomain {
  data: Cell;
  domain: String;
}

trait SignatureValidation {
  abstract const domain: String;

  owner: Address;
  pubKeys: map<Int, Bool>;

  receive(msg: AcceptPubKey) {
    require(sender() == self.owner, "PubKeysControl: caller is not an owner");
    self.pubKeys.set(msg.pubKey, true);

    self.reply("Public key accepted".asComment())
  }

  receive(msg: RevokePubKey) {
    require(sender() == self.owner, "PubKeysControl: caller is not an owner");
    self.pubKeys.del(msg.pubKey);

    self.reply("Public key revoked".asComment())
  }

  fun validateSignature(data: Cell, pubKey: Int, signature: Slice): Bool {
    let hash = self.hashWithDomain(data);
    let check: Bool = checkSignature(hash, signature, pubKey);
    return check;
  }

  fun requireAcceptedPubKey(pubKey: Int) {
    require(self.checkPubKey(pubKey), "PubKeysControl: public key is not accepted");
  }

  get fun checkPubKey(pubKey: Int): Bool {
    let pkStatus = self.pubKeys.get(pubKey);
    if (pkStatus != null) {
      return pkStatus!!;
    }
    return false;
  }

  get fun hashWithDomain(data: Cell): Int {
    return beginCell()
    .storeRef(data)
    .storeSlice(self.domain.asSlice())
    .endCell()
    .hash();
  }
}