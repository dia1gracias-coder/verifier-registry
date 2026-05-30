import "types"

// The single registry contract. On a CreateOrder message it deploys a brand
// new Order contract and forwards the attached TON to it as the escrow.
//
// Note on discovery: an order's address is the hash of its initial state, so
// only someone who knows that order's initial data can recompute its address.
// The frontend recomputes its OWN orders' addresses; a global feed needs a
// read-only TON indexer that reads the Marketplace's outgoing deploy messages.
contract Marketplace {
    author: "SwiftParcel"
    version: "1.0.0"
    description: "Registry that deploys Order escrow contracts"
    storage: MarketplaceStorage
    incomingMessages: MarketplaceMessage
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy MarketplaceMessage.fromSlice(in.body);
    var st = lazy MarketplaceStorage.load();

    match (msg) {
        CreateOrder => {
            // orderCount is kept only as a running total / stat.
            st.orderCount = st.orderCount + 1;
            st.save();

            // Build the new Order's initial state from the creator's fields.
            val orderData = OrderStorage {
                sender: in.senderAddress,
                courier: null,
                description: msg.description,
                area: msg.area,
                reward: msg.reward,
                status: OrderStatus.Open,
                nonce: msg.nonce,
                createdAt: msg.createdAt,
            };

            // Deploy it by sending to its state-init, forwarding all the TON
            // that came with this message (minus gas already spent).
            val deployMsg = createMessage({
                bounce: BounceMode.NoBounce,
                value: 0 as coins,
                dest: AutoDeployAddress {
                    stateInit: ContractState {
                        code: st.orderCode,
                        data: orderData.toCell(),
                    },
                },
            });
            deployMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }
        else => {
            assert (in.body.isEmpty()) throw MarketplaceErrors.InvalidMessage;
        }
    }
}

fun onBouncedMessage(_in: InMessageBounced) {}

get fun orderCount(): uint32 {
    val st = lazy MarketplaceStorage.load();
    return st.orderCount;
}

get fun owner(): address {
    val st = lazy MarketplaceStorage.load();
    return st.owner;
}

// Recompute the address of an order from its initial data. The frontend uses
// this for orders it created itself (it knows all the fields it sent).
get fun orderAddress(
    sender: address,
    reward: coins,
    nonce: uint64,
    createdAt: uint32,
    description: cell,
    area: cell,
): address {
    val st = lazy MarketplaceStorage.load();
    val orderData = OrderStorage {
        sender,
        courier: null,
        description,
        area,
        reward,
        status: OrderStatus.Open,
        nonce,
        createdAt,
    };
    val addr = AutoDeployAddress {
        stateInit: ContractState {
            code: st.orderCode,
            data: orderData.toCell(),
        },
    }.calculateAddress();
    return addr;
}
