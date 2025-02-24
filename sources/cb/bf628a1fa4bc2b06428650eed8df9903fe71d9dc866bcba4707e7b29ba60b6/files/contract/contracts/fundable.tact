message Fund {}

message ReturnRemainingBalance {
    target: Address;
}

trait Fundable {
    deployer: Address;

    receive(msg: Fund) {}

    receive(msg: ReturnRemainingBalance) {
        require(sender() == self.deployer, "Unauthorized caller");
        send(
            SendParameters{
                to: msg.target,
                value: 0,
                mode: SendRemainingBalance,
            }
        );
    }
}
