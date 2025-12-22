import "@stdlib/ownable";

contract MapContract with Ownable {
    owner: Address;

    init() {
        self.owner = sender();
    }

    receive() {
        let str: StringBuilder = beginString().concat("Simple deposit received. Balance: ").concat(myBalance().toString());
        dump(str.toString());
    }

    receive("inc") {
        let str: StringBuilder = beginString().concat("INC: Deposit action. New balance: ").concat(myBalance().toString());
        dump(str.toString());
    }

    receive("dec") { // Авто-парсит body == "dec"
        self.requireOwner();
        require(myBalance() >= 10000000, "Insufficient balance for 0.01 TON");

        send(SendParameters {
            value: ton("0.5"),
            mode: SendPayGasSeparately,
            bounce: true,
            to: self.owner,
        });

        let str: StringBuilder = beginString().concat("DEC: Withdraw sent. Remaining balance: ").concat(myBalance().toString());
        dump(str.toString());
    }

    get fun balance(): Int {
        return myBalance();
    }

    get fun owner2(): Address {
        return self.owner;
    }
}
