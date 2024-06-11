import "@stdlib/deploy";

message Buy {
    userId: Int;
}

contract AquaPointsStore with Deployable {
    deployer: Address;
    buyers: map<Int, Int as int8>;

    init() {
        self.deployer = sender();
    }

    get fun isBuyer(userId: Int): Int? {
        return self.buyers.get(userId);
    }

    receive(msg: Buy) {
        require(context().value >= ton("0.1"), "Must send minimum 0.1 TON");
        require(self.isBuyer(msg.userId) == null, "Points can be bought only once");
        self.buyers.set(msg.userId, context().value >= ton("1") ? 2 : 1);
    }

    receive("withdraw all") {
        require(sender() == self.deployer, "Only deployer is allowed to withdraw");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors
        });
    }
}
