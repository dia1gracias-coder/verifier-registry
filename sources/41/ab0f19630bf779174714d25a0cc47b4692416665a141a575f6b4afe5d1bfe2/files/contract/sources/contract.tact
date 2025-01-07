import "@stdlib/ownable";
import "@stdlib/deploy";
import "./util.fc";
import "./message";

const sale_processing_value: Int = ton("0.2");
const jetton_transfer_value: Int = ton("0.06");

const service_numerator: Int = 11;
const service_denominator: Int = 1000;

const hundred_percent: Int = 100000000000;

@name(service_address)
native serviceAddress(): Address;

@name(muldiv)
native mulDiv(a: Int, b: Int, c: Int): Int;

struct PriceInfo {
    jetton_amount: Int;
    full_price: Int;
    service_fee: Int;
    service_address: Address;
}

struct SaleInfo {
    sale_ended: Bool;
    owner: Address;
    jetton_master: Address;
    jetton_wallet: Address?;
    jetton_amount: Int;
    price_info: PriceInfo;
}

contract JettonSale with Ownable {
    owner: Address;
    jetton_master: Address;
    jetton_wallet: Address? = null;
    sale_ended: Bool = false;
    jetton_amount: Int as uint16;
    price_per_ton: Int as coins;

    init(owner: Address, jetton_master: Address, jetton_amount: Int, price_per_ton: Int) {
        self.owner = owner;
        self.jetton_master = jetton_master;
        self.jetton_amount = jetton_amount;
        self.price_per_ton = price_per_ton;

        send(SendParameters{
            to: self.jetton_master,
            value: 0,
            mode: SendRemainingValue,
            body: ProvideWalletAddress{query_id: now(), owner_address: myAddress(), include_address: true}.toCell()
        });
    }

    receive(msg: TakeWalletAddress) {
        let ctx: Context = context();
        require(ctx.sender == self.jetton_master, "Invalid sender");
        self.jetton_wallet = msg.wallet_address;
    }

    receive(msg: TransferNotification) {
        let ctx: Context = context();
        let total_price: Int = mulDiv(msg.amount, self.price_per_ton, hundred_percent);
        let service_fee: Int = mulDiv(total_price, service_numerator, service_denominator);
        let full_price: Int = total_price + service_fee;

        require(ctx.value >= sale_processing_value, "Insufficient TON provided");
        require(msg.amount <= self.jetton_amount, "Not enough jettons available for sale");
        require(!self.sale_ended, "Sale has ended");

        if (msg.amount > full_price) {
            send(SendParameters{
                to: ctx.sender,
                value: ctx.value - full_price,
                mode: SendRemainingValue,
                body: "Excess TON refunded".asComment()
            });
        }

        self.jetton_amount -= msg.amount;

        send(SendParameters{
            to: self.jetton_wallet!!,
            value: jetton_transfer_value,
            mode: 0,
            body: Transfer{
                query_id: msg.query_id,
                amount: msg.amount,
                destination: msg.sender,
                response_destination: msg.sender,
                custom_payload: "Jetton purchase".asComment(),
                forward_ton_amount: 0,
                forward_payload: emptySlice()
            }.toCell()
        });

        send(SendParameters{
            to: serviceAddress(),
            value: service_fee,
            mode: 0,
            body: "Service fee payment".asComment()
        });

        send(SendParameters{
            to: self.owner,
            value: full_price - service_fee,
            mode: 0,
            body: "TON payment for jetton sale".asComment()
        });
    }

    receive("Cancel") {
        self.requireOwner();
        self.sale_ended = true;
    }

    receive(msg: Deploy) {
        self.requireOwner();
        self.sale_ended = false;
    }

    get fun get_price_info(): PriceInfo {
        let total_price: Int = mulDiv(self.jetton_amount, self.price_per_ton, hundred_percent);
        let service_fee: Int = mulDiv(total_price, service_numerator, service_denominator);
        let full_price: Int = total_price + service_fee;

        return PriceInfo{
            jetton_amount: self.jetton_amount,
            full_price: full_price,
            service_fee: service_fee,
            service_address: serviceAddress()
        };
    }

    get fun get_sale_info(): SaleInfo {
        let price_info: PriceInfo = self.get_price_info();

        return SaleInfo {
            sale_ended: self.sale_ended,
            owner: self.owner,
            jetton_master: self.jetton_master,
            jetton_wallet: self.jetton_wallet,
            jetton_amount: self.jetton_amount,
            price_info: price_info
        };
    }
}