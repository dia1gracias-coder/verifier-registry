import "@stdlib/deploy";

message Boost {
    queryId: Int as uint64;
    tierId: Int as uint16;
}

message SetTierPrice {
    queryId: Int as uint64;
    tierId: Int as uint16;
    price: Int as uint64;
}

message SetBeneficiary {
    queryId: Int as uint64;
    beneficiary: Address;
}

message Boosted {
    queryId: Int as uint64;
    tierId: Int as uint16;
    purchaseId: Int as uint64;
    player: Address;
}

struct Purchase {
    tierId: Int as uint16;
    player: Address;
    timestamp: Int as uint32;
}

contract GDTapBooster with Deployable {

    balance_to_keep: Int = ton("0.03");

    next_item_index: Int as uint32 = 1;

    purchases: map<Int as uint64, Purchase>;

    latestPurchase: map<Address, Int as uint64>;

    tierPrices: map<Int as uint32, Int as uint64>;

    owner: Address;
    beneficiary: Address;

    init(owner: Address, beneficiary: Address) {
        self.owner = owner;
        self.beneficiary = beneficiary;

        self.tierPrices.set(1, 0);
        self.tierPrices.set(2, ton("0.05"));
        self.tierPrices.set(3, ton("0.1"));
        self.tierPrices.set(4, ton("0.25"));
    }

    receive(msg: Boost) {
        let ctx: Context = context();
        require(ctx.value >= self.tierPrices.get(msg.tierId)!!, "Not enough monies" );

        let purchase: Purchase = Purchase { tierId: msg.tierId, player: ctx.sender, timestamp: now() };

        self.purchases.set(self.next_item_index, purchase);
        self.latestPurchase.set(ctx.sender, self.next_item_index);

        let boostedMessage: Boosted = Boosted {
            queryId: msg.queryId,
            tierId: msg.tierId,
            purchaseId: self.next_item_index,
            player: ctx.sender
        };


        self.next_item_index = self.next_item_index + 1;

        send(SendParameters{
            to: self.beneficiary,
            value: 0,
            bounce: false,
            mode: SendRemainingBalance
        });

        self.reply(boostedMessage.toCell());

    }

    receive(msg: SetTierPrice) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Hecker protection");

        self.tierPrices.set(msg.tierId, msg.price);

        send(SendParameters{
            to: self.owner,
            bounce: false,
            value: 0,
            mode: SendRemainingValue
        });
    }

    receive(msg: SetBeneficiary) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Unauthorized: Only owner can set beneficiary");

        self.beneficiary = msg.beneficiary;

        send(SendParameters{
            to: self.owner,
            bounce: false,
            value: 0,
            mode: SendRemainingValue
        });
    }



    get fun tier_price(tierId: Int): Int {
        return self.tierPrices.get(tierId)!!;
    }


    get fun purchase(purchaseId: Int): Purchase? {
        return self.purchases.get(purchaseId);
    }

    get fun next_purchase_id(): Int {
        return self.next_item_index;
    }

    get fun beneficiary(): Address {
        return self.beneficiary;
    }

    get fun latestPurchase(player: Address): Int {
        return self.latestPurchase.get(player)!!;
    }

}
