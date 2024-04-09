/*
  Wallet
  author: @a3_ton
*/
message(0x999) NewOwner {
    owner: Address;
}

contract Wallet {
    owner: Address;
    seqno: Int as uint64;
    init(owner: Address, seqno: Int){
        self.owner = owner;
        self.seqno = seqno;
    }

    receive("get"){
        require(sender() == self.owner, "Insufficient privelegies");
        send(SendParameters{to: self.owner, value: 0, mode: SendRemainingBalance, body: "OK".asComment()});
    }

    receive(){
        throw(0);
    }

    receive(msg: NewOwner){
        require(sender() == self.owner, "Insufficient privelegies");
        self.owner = msg.owner;
    }
}