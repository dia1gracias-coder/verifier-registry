import "@stdlib/ownable";
import "../messages";
import "@stdlib/deploy";

contract FeeContract with Deployable, OwnableTransferable {
    owner: Address;
    numerator: Int as uint64 = 0;
    denominator: Int as uint64 = 1;

    const minTonsForStorage: Int = ton("0.02");

    init(owner: Address) {
        self.owner = owner;
    }

    receive(msg: TokenTransfer) {
        let ctx: Context = context();
        
        let balance_befor: Int = myBalance() - ctx.value;
        if (balance_befor < self.minTonsForStorage) {
            ctx.value -= max(self.minTonsForStorage - balance_befor, ton("0.01"));
        }

        send(SendParameters{
            to: sender(),
            value: ctx.value,
            mode: 0,
            bounce: false,
            body: TokenTransferWithFee{
                    query_id: msg.query_id,
                    amount: msg.amount,
                    destination: msg.destination,
                    numerator: self.numerator,
                    denominator: self.denominator,
                    response_destination: msg.response_destination,
                    custom_payload: msg.custom_payload,
                    forward_ton_amount: msg.forward_ton_amount,
                    forward_payload: msg.forward_payload
                }.toCell()
        });
    }

    receive(msg: ChangeFee) {
        self.requireOwner(); //Exit code - 132
        require(msg.denominator!=0, "Devision by zero");
        require(100*msg.numerator/msg.denominator<=10, "Too big commission"); // 10% - max //Exit code - 51252
        self.numerator = msg.numerator;
        self.denominator = msg.denominator;
    }


    get fun get_fee_data(): FeeData {
        return FeeData{
            owner: self.owner,
            numerator: self.numerator,
            denominator: self.denominator
        };
    }
}