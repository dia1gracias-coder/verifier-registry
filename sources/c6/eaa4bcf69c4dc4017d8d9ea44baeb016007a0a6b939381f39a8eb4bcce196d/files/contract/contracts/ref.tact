import "@stdlib/deploy";

contract Ref with Deployable {
  const presaleAddr: Address = address("EQAXtW28nSlb8z_-dhQPPsxRDx8mgJc4KJwEN6OWcUYeEDIe");
  tgId: Int as int64;
  user: Address;

  init(tgId: Int, user: Address) {
    self.tgId = tgId;
    self.user = user;
  }

  fun send(to: Address, amt: Int, comment: String) {
    send(SendParameters{
      to: to,
      value: amt,
      mode: 0,
      body: comment.asComment(),
    });
  }

  receive() {
    let eachAmt: Int = context().value / 2;
    self.send(self.presaleAddr, eachAmt, sender().toString());
    self.send(self.user, eachAmt, "bomj.me ref reward");
  }
}
