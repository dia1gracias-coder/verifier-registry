import "types"

// The single registry contract. On a CreateOrder message it deploys a brand
// new Order contract and forwards the attached TON to it as the escrow.
//
// Note on discovery: an order's address is the hash of its initial state, so
// only someone who knows that order's initial data can recompute its address.
// The frontend recomputes its OWN orders' addresses; a global feed needs a
// read-only TON indexer that reads the Marketplace's outgoing deploy messages.
// The sender must attach at least the stated reward plus this buffer. The UI
// sends reward + 0.1 (the create-time service fee, see src/contracts/orders.js);
// we require a little less so the wallet's first-hop forward fee never trips an
// honest order, while a grossly under-funded order is rejected. This check is
// what guarantees the new Order's escrow truly holds the reward: without it a
// sender could advertise a reward the contract does not hold, and a courier
// would deliver for nothing.
const CREATE_MIN_BUFFER = ton("0.05")

// Lowest reward an order may advertise. A reward of 0 (or dust) creates an order
// no courier has any reason to accept: it just sits Open, clutters the Feed, and
// strands the sender's 0.1 TON create fee. Requiring a real minimum cuts that
// spam at the source while staying low enough to allow any genuine small job.
// It is a fixed TON value, so in USD it drifts with the TON price (~$3-5 today);
// the UI types the reward in USD and locks it in TON at create time. See M-5 in
// the security audit.
const MIN_REWARD = ton("1")

contract Marketplace {
    author: "SwiftDelivery"
    version: "1.15.0"
    description: "Registry that deploys Order escrow contracts"
    storage: MarketplaceStorage
    incomingMessages: MarketplaceMessage
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy MarketplaceMessage.fromSlice(in.body);
    var st = lazy MarketplaceStorage.load();

    match (msg) {
        CreateOrder => {
            // Reject zero/dust-reward spam: an order no courier would take only
            // clutters the Feed and strands the sender's create fee (M-5).
            assert (msg.reward >= MIN_REWARD) throw MarketplaceErrors.RewardTooLow;
            // Refuse to deploy an order the sender did not actually fund. The
            // reward is forwarded to the child as its escrow, so the attached
            // value must cover it (plus a small gas/fee buffer).
            assert (
                in.valueCoins >= msg.reward + CREATE_MIN_BUFFER
            ) throw MarketplaceErrors.InsufficientValue;

            // orderCount is kept only as a running total / stat.
            st.orderCount = st.orderCount + 1;
            st.save();

            // Build the new Order's initial state from the creator's fields.
            val orderData = OrderStorage {
                sender: in.senderAddress,
                courier: null,
                description: msg.description,
                area: msg.area,
                origin: msg.origin,
                reward: msg.reward,
                status: OrderStatus.Open,
                nonce: msg.nonce,
                createdAt: msg.createdAt,
                acceptedAt: 0, // set by Order when a courier accepts
                extra: (OrderExtra {
                    owner: st.owner,
                    senderContact: msg.senderContact,
                    courierContact: createEmptyCell(),
                    secretHash: msg.secretHash,
                    referral: msg.referral,
                }).toCell(),
            };

            // Deploy it by sending to its state-init, forwarding all the TON
            // that came with this message (minus gas already spent).
            val orderStateInit = ContractState {
                code: st.orderCode,
                data: orderData.toCell(),
            };
            val deployMsg = createMessage({
                bounce: BounceMode.NoBounce,
                value: 0 as coins,
                dest: AutoDeployAddress { stateInit: orderStateInit },
            });
            deployMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);

            // Log the new order. Emitted AFTER the mode-64 deploy send, so the
            // emit's forward fee comes out of the Marketplace's OWN balance
            // (~0.0005 TON per order) and never touches the escrow being
            // forwarded. That balance drains slowly with every create; top it
            // up now and then with a plain empty-body transfer. If it ever
            // runs dry the emit is skipped (IGNORE_ERRORS in emitEvent) — the
            // order itself still deploys fine.
            emitEvent(OrderCreated {
                orderAddress: AutoDeployAddress { stateInit: orderStateInit }.calculateAddress(),
                sender: in.senderAddress,
                reward: msg.reward,
                area: msg.area,
            });
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

// The platform owner (fee recipient). Set at deploy time and can never
// change — no message touches it, same as the Order code.
get fun owner(): address {
    val st = lazy MarketplaceStorage.load();
    return st.owner;
}

// Hash of the Order code the Marketplace deploys. The code is set at deploy
// time and can never change — no message touches it — so this getter lets
// ops / the frontend verify the frozen Order code hash against the
// published build.
get fun orderCodeHash(): uint256 {
    val st = lazy MarketplaceStorage.load();
    return st.orderCode.hash();
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
    origin: cell,
    senderContact: cell,
    secretHash: uint256,
    referral: address?,
): address {
    val st = lazy MarketplaceStorage.load();
    val orderData = OrderStorage {
        sender,
        courier: null,
        description,
        area,
        origin,
        reward,
        status: OrderStatus.Open,
        nonce,
        createdAt,
        acceptedAt: 0,
        extra: (OrderExtra {
            owner: st.owner,
            senderContact,
            courierContact: createEmptyCell(),
            secretHash,
            referral,
        }).toCell(),
    };
    val addr = AutoDeployAddress {
        stateInit: ContractState {
            code: st.orderCode,
            data: orderData.toCell(),
        },
    }.calculateAddress();
    return addr;
}
