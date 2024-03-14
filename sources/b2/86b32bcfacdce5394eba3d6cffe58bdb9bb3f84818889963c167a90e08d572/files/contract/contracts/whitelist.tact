import "@stdlib/deploy";
import "@stdlib/ownable";

message AcceptFee {
    cashback: Address;
}

message WhitelistMetadata {
    owner: Address;
    enrollFee: Int;
}

contract Whitelist with Deployable, Ownable {
    owner: Address;
    id: Int as uint32;
    enrollFee: Int as coins;

    const childStorageValue: Int = ton("0.02");

    init(id: Int, enrollFee: Int) {
        self.id = id;
        self.owner = sender();
        self.enrollFee = enrollFee;
    }

    receive() {}

    receive(msg: AcceptFee) {
        send(SendParameters{
            to: msg.cashback,
            bounce: true,
            value: context().value - self.enrollFee - self.childStorageValue,
            mode: 0
        });
    }

    receive("enroll") {
        require(context().value >= self.enrollFee + self.childStorageValue + ton("0.01"), "Not enough money to enroll");
        let init: StateInit = initOf WhitelistChildEntry(myAddress(), sender());
        send(SendParameters{
            to: contractAddress(init),
            value: self.childStorageValue,
            body: "accept".asComment(),
            mode: SendIgnoreErrors,
            code: init.code,
            data: init.data
        });
        send(SendParameters{
            to: myAddress(),
            body: AcceptFee{cashback: sender()}.toCell(),
            value: 0,
            mode: SendRemainingValue
        });
    }

    get fun id(): Int {
        return self.id;
    }

    get fun metadata(): WhitelistMetadata {
        return WhitelistMetadata{
            owner: self.owner,
            enrollFee: self.enrollFee
        };
    }

    get fun entryAddress(addr: Address): Address {
        return contractAddress(initOf WhitelistChildEntry(myAddress(), addr));
    }
}

///////////////////////////////////////
// Child contract - internal interface that users shouldn't access directly
// Refer to: https://tact-by-example.org/06-parent-child

message WhitelistEntryDetails {
    addr: Address;
    accepted: Bool;
}

contract WhitelistChildEntry {
    parent: Address;
    addr: Address;
    accepted: Bool = false;

    init(parent: Address, addr: Address) {
        require(sender() == parent, "Access denied");
        self.parent = parent;
        self.addr = addr;
    }

    receive("accept") {
        require(sender() == self.parent, "Access denied");
        self.accepted = true;
    }

    get fun details(): WhitelistEntryDetails {
        return WhitelistEntryDetails{
            addr: self.addr,
            accepted: self.accepted
        };
    }
}