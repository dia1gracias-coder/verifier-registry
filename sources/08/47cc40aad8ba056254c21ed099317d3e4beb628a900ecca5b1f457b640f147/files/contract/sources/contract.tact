import "@stdlib/deploy";

contract TicketSeller with Deployable {
    owner: Address;

    total: Int as uint32 = 0;

    init(owner: Address) {
        self.owner = owner;
    }

    receive(str: String) {
        
        self.total = self.total + 1;

        send(SendParameters {
            to: self.owner,
            value : 0,
            mode : SendRemainingValue,
            body: self.total.toString().asComment()
        });
    }

    get fun value(): Int {
        return self.total;
    }

}