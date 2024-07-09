import "@stdlib/deploy";

message Invoice {
    id: Int as uint64;
    value: Int as uint64;
}

const minTonsForStorage: Int = ton("0.2");

contract GleamInvoices with Deployable {
    deployer: Address;
    invoices: map<Int as uint64, Int as uint64>;

    init() {
        self.deployer = sender();
    }

    get fun invoice(id: Int): Int {
        let amount: Int? = self.invoices.get(id);
        return amount != null ? amount!! : 0;
    }

    get fun allInvoices(): map<Int as uint64, Int as uint64> {
        return self.invoices;
    }

    receive(msg: Invoice) {
        let ctx: Context = context();

        require(ctx.value >= msg.value, "Sent TON amount should cover passed value");

        self.invoices.set(msg.id, self.invoice(msg.id) + msg.value);

        let refundTon: Int = ctx.value - msg.value;

        if (refundTon > 0) {
            send(SendParameters{
                to: sender(),
                value: refundTon,
                mode: SendIgnoreErrors
            });
        }
    }

    receive("deposit") {}

    receive("withdraw all") {
        require(sender() == self.deployer, "Only deployer is allowed to withdraw");

        send(SendParameters{
            to: sender(),
            bounce: true,
            value: myBalance() - context().value - minTonsForStorage,
            mode: SendRemainingBalance + SendIgnoreErrors
        });
    }
}
