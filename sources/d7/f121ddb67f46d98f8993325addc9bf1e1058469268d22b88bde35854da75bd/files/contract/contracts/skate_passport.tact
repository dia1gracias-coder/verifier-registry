import "@stdlib/deploy";
import "@stdlib/ownable";

// GOVERNANCE ACTIONs
message(0x44807e69) WithdrawTON {}

message(0xa9eba477) Subscribe {
    tier: Int as uint8;
}

message(0xe9674492) SubscribeOk {
    tier: Int as uint8;
    address: Address;
    id: Int as uint64;
}

message(0xba455cd8) SetSubscriptionTiers {
    tiers_map: map<Int as uint8, Int>;
}

message ChangeFundReceiver {
    new_receiver: Address;
}

const INVALID_SUBSCCRIPTION_TIER: Int = 4000;
const INVALID_SUBSCCRIPTION_AMOUNT: Int = 4051;

//////////////////////////////////////////////////////
contract SkatePassport with Deployable, OwnableTransferable {
    owner: Address;
    fund_receiver: Address;
    get fun fund_receiver(): Address {
        return self.fund_receiver;
    }
    init(owner: Address, fund_receiver: Address) {
        self.owner = owner;
        self.fund_receiver = fund_receiver;
    }

    subscription_id: Int as uint64 = 0; // Subscriber id, monotonic counter
    get fun subscription_id(): Int {
        return self.subscription_id;
    }

    // Map tier (number [u8]) -> to amount (TON [coins])
    subscription_tiers: map<Int as uint8, Int> = emptyMap();
    get fun subscription_tiers(): map<Int as uint8, Int> {
        return self.subscription_tiers;
    }

    /////////// Governance actions ////////////
    receive(msg: WithdrawTON) {
        send(SendParameters{
            to: self.owner,
            value: 0,
            mode: SendRemainingBalance,
        })
    }

    receive(msg: SetSubscriptionTiers) {
        self.requireOwner();
        self.subscription_tiers = msg.tiers_map;
    }

    receive(msg: ChangeFundReceiver) {
        nativeThrowUnless(132, sender() == self.fund_receiver);
        self.fund_receiver = msg.new_receiver;
    }
    //////////// User interactions ////////////
    receive(msg: Subscribe) {
        let required_amount: Int? = self.subscription_tiers.get(msg.tier);
        if (required_amount == null) {
            self.reply("Invalid subscription tier".asComment());
            nativeThrow(INVALID_SUBSCCRIPTION_TIER);
        }

        let ctx: Context = context();
        if (ctx.value != required_amount) {
            nativeThrow(INVALID_SUBSCCRIPTION_AMOUNT);
        }

        self.subscription_id += 1;
        emit(SubscribeOk{tier: msg.tier, address: ctx.sender, id: self.subscription_id}.toCell());
        self.forward(self.fund_receiver, emptyCell(), false, null);
    }
}

