tolk 1.4

// ---------------- economics, pinned in code ----------------
const FEE_WALLET = address("UQDv3gHsDZPlCXToMSeKJfE5g4JN1aY7uxbqu0OtW-At_xNx");
const MIN_FEE_BPS = 0;
const MAX_FEE_BPS = 100;      // 1% ceiling, hard-coded
const DEFAULT_FEE_BPS = 50;   // 0.5% at deploy (init data must match — asserted in suite)
const TIMELOCK = 86400;       // 24h propose→execute
const ORDER_TTL = 3600;       // reclaim window for orders whose funds are still held here
const VENUE_DEADLINE = 600;   // deadline field handed to venues

// gas policy.
// The floors cover the internal WORST CASE: TEP-89 discovery (up to 2 single / 3 two-leg
// × 0.03) + the leg's wallet hop (0.05) + settle reserve (0.03) + venue margin —
// a lower floor would produce negative forwardTonAmount mid-order.
const GAS_FLOOR_SINGLE = 250000000;  // 0.25 TON min budget attached to a single-leg order
const GAS_FLOOR_TWOLEG = 400000000;  // 0.40 TON min budget for a two-leg order
const GAS_DISCOVERY   = 30000000;    // 0.03 TON per TEP-89 provide roundtrip
const GAS_FWD_SETTLE  = 30000000;    // reserve kept for the settle/delivery step
const GAS_JET_HOP     = 50000000;    // 0.05 TON kept by a jetton-transfer wallet hop
const GAS_LEG2_RESERVE = 100000000;  // 0.10 TON kept aside for leg2 of a two-leg order
const SEND_FEE_PAD    = 10000000;    // 0.01 TON margin covering fwd fees of exact-value sends
const STORAGE_RESERVE = 250000000;   // 0.25 TON storage float — sweep never goes below

// ---------------- op codes ----------------
// TEP-74 / TEP-89 (standard; 0x7362d09c/0x0f8a7ea5/0xd53276db)
const OP_JETTON_TRANSFER = 0x0f8a7ea5;
const OP_JETTON_NOTIFY   = 0x7362d09c;
const OP_EXCESSES        = 0xd53276db;
const OP_PROVIDE_WALLET  = 0x2c76b973;
const OP_TAKE_WALLET     = 0xd1735400;
// venue (Ston.fi v2 0x6664de2a; pTON 0x01f3835d;
// DeDust: public layout — isolated HERE by design)
const OP_STON_SWAP        = 0x6664de2a;
const OP_PTON_TRANSFER    = 0x01f3835d;
const OP_DEDUST_NATIVE    = 0xea06185d;
const OP_DEDUST_JETTON    = 0xe3a0d482;
// our markers inside the venue payloads (fulfill/reject → come back in the notification/settle)
const OP_SETTLE_MARK = 0x4c53c001;
const OP_REFUND_MARK = 0x4c53c002;
// our orders/governance (prefix 0x4c53 = "LS")
const OP_ORDER_TON = 0x4c531001;
const OP_ORDER_JET = 0x4c531002;
const OP_REFUSE_NOTE = 0x4c53ee01;
const OP_GOV_ACK     = 0x4c53ee00;

// venue kinds (how we talk to a leg's venue)
const VK_STON_JETTON   = 1;  // TEP-74 transfer to the Ston.fi router with ston_swap forward
const VK_STON_PTON     = 2;  // TON to the Ston.fi router's pTON wallet (TON side inbound)
const VK_DEDUST_NATIVE = 3;  // TON to the DeDust native vault
const VK_DEDUST_JETTON = 4;  // TEP-74 transfer to the DeDust jetton vault

// order states
const ST_AWAIT = 1;       // funds here, wallet-discovery in progress (reclaimable after TTL)
const ST_SENT1 = 2;       // leg1 forwarded to the venue
const ST_SENT2 = 3;       // leg2 forwarded (two-leg)
const ST_DELIVERING = 4;  // out jetton being delivered (closed by the confirmation excesses)

// purposes inside query_id: qid = (orderId << 3) | purpose
// provide_wallet:  0=in 1=out 2=mid 7=gov anti-token probe
// jetton_transfer: 0=leg1 1=leg2 2=delivery 3=fee 4=refund 5=sweep
const Q_IN  = 0;
const Q_OUT = 1;
const Q_MID = 2;
const Q_GOV = 7;
const T_LEG1 = 0;
const T_LEG2 = 1;
const T_DELIVER = 2;
const T_FEE = 3;
const T_REFUND = 4;
const T_SWEEP = 5;

// ---------------- error codes ----------------
const ERR_PAUSED = 601;            // "paused"
const ERR_TARGET = 602;            // "target" not whitelisted
const ERR_AMOUNT = 603;            // "amount"
const ERR_SAME_TOKEN = 604;        // "same token"
const ERR_MIN_OUT = 605;           // "minOut" == 0
const ERR_TARGET_TOKEN = 606;      // "target token" (venue coincides with a token on the route)
const ERR_FEE_SIDE = 607;          // "fee side not solid"
const ERR_NOT_OWNER = 608;         // "not owner"
const ERR_RENOUNCED = 609;         // "renounced"
const ERR_TIMELOCK = 610;          // "timelock"
const ERR_BAD_TARGET = 611;        // "bad target" (propose) / malformed leg (refuse)
const ERR_FEE_RANGE = 612;         // "fee range"
const ERR_ZERO_OWNER = 613;        // "zero owner" (n/a: address is always valid)
const ERR_NOT_PENDING_OWNER = 614; // "not pending owner"
const ERR_BAD_SOLID = 615;         // "bad solid"
const ERR_INTERMEDIATE = 616;      // "intermediate" not solid
const ERR_GAS = 617;               // gas budget below the floor
const ERR_ORDER_STATE = 618;
const ERR_TTL = 619;               // reclaim before the TTL
const ERR_SWEEP_PENDING = 620;     // sweep would touch pending funds
const ERR_MID_MIN = 621;           // two-leg: midMin==0 (never a degenerate mid floor)
const ERR_ORDER_UNKNOWN = 622;
const ERR_NOTHING_TO_SWEEP = 623;

// ---------------- storage ----------------
struct GovMaps {
    allowed: map<address, bool>          // venue destinations whitelist
    pendingEta: map<address, uint32>     // venue proposal → earliest execute ts
    solids: map<address, bool>           // solid jetton masters (TON is solid by code)
    pendingSolidEta: map<address, uint32>
}

// NB: NO inverse wallet→master map, on purpose: it would be poisonable
// (a hostile master could "declare" someone else's wallet as its own in the
// TEP-89 reply). Every check goes FORWARD — walletOf[master EXPECTED by the order]
// == sender — which an outsider cannot poison by construction.
struct RunMaps {
    walletOf: map<address, address>        // master → OUR jetton-wallet (verified TEP-89)
    orders: map<uint64, Cell<Order>>       // live orders
    pendingJet: map<address, coins>        // master → jetton atoms AT REST for pending orders
}

struct Storage {
    owner: address
    pendingOwner: address?
    feeBps: uint16
    paused: bool
    renounced: bool
    seqno: uint64          // progressive order id (0 reserved for governance)
    pendingTon: coins      // total TON (amounts + gas float) held for pending orders
    gov: Cell<GovMaps>
    run: Cell<RunMaps>
}

fun Storage.load() {
    return Storage.fromCell(contract.getData());
}

fun Storage.save(self) {
    contract.setData(self.toCell());
}

// ---------------- orders ----------------
struct LegSpec {
    kind: uint8            // VK_*
    venue: address         // whitelisted destination of the leg (ston router / pton wallet / vault)
    aux: address?          // ston: token_wallet1 · dedust: pool — routing hint, NEVER security
}

struct OrderTokens {
    inMaster: address?     // null = TON inbound
    outMaster: address?    // null = TON outbound
    midMaster: address?    // two-leg: intermediate solid jetton (null = mid TON)
}

struct OrderFunds {
    amountIn: coins
    minOut: coins          // NET minimum to the user (the contract derives the venueMinOut)
    midMin: coins          // two-leg: client hint on leg1's minimum (never weakens minOut)
    heldJet: coins         // jetton atoms at rest for the order (mid-phase or bounced delivery)
    feeHeld: coins         // fee already skimmed and HELD (travels only at delivery)
    heldMaster: address?   // master of the held atoms (null = TON side)
}

struct Order {
    user: address
    claimedWallet: address?   // wallet that notified the jetton inbound (to be verified via TEP-89)
    state: uint8
    twoLeg: bool
    feeOnInput: bool
    tonIn: bool
    tonOut: bool
    midIsTon: bool
    deliveryBounced: bool     // the delivery bounced: redelivery allowed via reclaim post-TTL
    needMask: uint8           // pending discovery: 1=in 2=out 4=mid
    createdAt: uint32
    feeBpsSnap: uint16        // fee FROZEN at creation (the rate is the one quoted to the user)
    nonce: uint64             // per-order secret — settle/refund/excesses must carry it
    heldTon: coins            // TON physically reserved for the order (amount if TON-in + gas)
    sentJet: coins            // atoms of the last jetton transfer in flight (for bounces)
    funds: Cell<OrderFunds>
    tokens: Cell<OrderTokens>
    leg1: Cell<LegSpec>
    leg2: Cell<LegSpec>?
}

// ---------------- inbound messages (our protocol + standard) ----------------
struct (0x4c531001) TonOrder {
    queryId: uint64
    amountIn: coins
    feeOnInput: bool          // true = fee on the inbound TON (buy); false = solid out (sell)
    outMaster: address
    minOut: coins
    leg1: Cell<LegSpec>
}

struct (0x7362d09c) JettonNotify {
    queryId: uint64
    amount: coins
    sender: address                       // the wallet's owner (the user)
    forwardPayload: RemainingBitsAndRefs  // Either Cell ^Cell — manual parse
}

// body of a jetton order's forward_payload (after the 32-bit op)
struct JetOrderBody {
    feeOnInput: bool
    tonOut: bool
    twoLeg: bool
    midIsTon: bool
    minOut: coins
    midMin: coins
    tokens: Cell<OrderTokens>
    leg1: Cell<LegSpec>
    leg2: Cell<LegSpec>?
}

struct (0xd1735400) TakeWalletAddress {
    queryId: uint64
    walletAddress: address
    ownerAddress: cell?
}

struct (0xd53276db) Excesses {
    queryId: uint64
}

struct (0x4c53c001) SettleMark {
    orderId: uint64
    nonce: uint64        // binds the settle to the order beyond the public orderId
}

struct (0x4c53c002) RefundMark {
    orderId: uint64
    nonce: uint64
}

// governance
struct (0x4c530010) GovPropose      { queryId: uint64, target: address }
struct (0x4c530011) GovExecute      { queryId: uint64, target: address }
struct (0x4c530012) GovRemove       { queryId: uint64, target: address }
struct (0x4c530013) GovProposeSolid { queryId: uint64, token: address }
struct (0x4c530014) GovExecuteSolid { queryId: uint64, token: address }
struct (0x4c530015) GovRemoveSolid  { queryId: uint64, token: address }
struct (0x4c530016) GovSetFee       { queryId: uint64, bps: uint16 }
struct (0x4c530017) GovPause        { queryId: uint64 }
struct (0x4c530018) GovUnpause      { queryId: uint64 }
struct (0x4c530019) GovTransferOwnership { queryId: uint64, newOwner: address }
struct (0x4c53001a) GovAcceptOwnership   { queryId: uint64 }
struct (0x4c53001b) GovRenounce     { queryId: uint64 }
struct (0x4c53001c) SweepTon        { queryId: uint64 }
struct (0x4c53001d) SweepJetton     { queryId: uint64, master: address, amount: coins }
struct (0x4c53001e) Reclaim         { queryId: uint64, orderId: uint64 }

type InMsg = TonOrder | JettonNotify | TakeWalletAddress | Excesses | SettleMark | RefundMark
    | GovPropose | GovExecute | GovRemove | GovProposeSolid | GovExecuteSolid | GovRemoveSolid
    | GovSetFee | GovPause | GovUnpause | GovTransferOwnership | GovAcceptOwnership | GovRenounce
    | SweepTon | SweepJetton | Reclaim;

// ---------------- outbound messages ----------------
struct (0x0f8a7ea5) JettonTransferMsg {
    queryId: uint64
    amount: coins
    destination: address
    responseDestination: address
    customPayload: cell?
    forwardTonAmount: coins
    forwardPayload: cell?     // Either inline-empty (bit 0) / ref (bit 1) — identical to Maybe ^Cell
}

struct (0x2c76b973) ProvideWalletAddress {
    queryId: uint64
    ownerAddress: address
    includeAddress: bool
}

struct (0x01f3835d) PtonTransfer {
    queryId: uint64
    tonAmount: coins
    refundAddress: address
    forwardPayload: cell?
}

// Ston.fi v2 swap.
// The venue's wire format is INLINE by their contract: the compiler's 1023 worst-case
// assumes addr_var/extern that in OUR build do not exist
// (receiver/refund = router addr_std 267 bit, refAddress = none 2 bit, real coins
// ≤124): real total ~660 bit — the suite proves it on the golden payload.
@overflow1023_policy("suppress")
struct StonSwapInner {
    minOut: coins
    receiver: address
    fwdGas: coins
    customPayload: cell?      // fulfill → comes back in the settle notification
    refundFwdGas: coins
    refundPayload: cell?      // reject → comes back in the refund notification
    refFee: uint16
    refAddress: any_address
}

struct (0x6664de2a) StonSwap {
    tokenWallet1: address
    refundAddress: address
    excessesAddress: address
    deadline: uint64
    inner: Cell<StonSwapInner>
}

// DeDust (public layout)
struct DedustParams {
    deadline: uint32
    recipient: address
    referral: any_address
    fulfillPayload: cell?
    rejectPayload: cell?
}

struct (0xea06185d) DedustNativeSwap {
    queryId: uint64
    amount: coins
    pool: address
    kindOut: bool
    limit: coins
    next: cell?
    params: Cell<DedustParams>
}

struct (0xe3a0d482) DedustJettonSwapPayload {
    pool: address
    kindOut: bool
    limit: coins
    next: cell?
    params: Cell<DedustParams>
}

struct (0x4c53ee01) RefuseNote {
    queryId: uint64
    code: uint16
}

struct (0x4c53ee00) GovAck {
    queryId: uint64
}

// ---------------- helpers ----------------
@pure
fun feeOf(amount: coins, bps: int): coins {
    return mulDivFloor(amount, bps, 10000);   // floor division
}

// sell: the GROSS minimum G such that G − fee(G) ≥ minOut (the client cannot weaken it)
@pure
fun grossFloorFor(minOut: coins, bps: int): coins {
    return mulDivCeil(minOut, 10000, 10000 - bps);
}

@pure
fun qidOf(orderId: uint64, purpose: int): uint64 {
    return ((orderId << 3) | purpose) as uint64;
}

// query_id of the jetton DELIVERY: binds the closing excesses to the order.
// purpose (3 bit) | orderId (32 bit) | nonce (29 bit). Bound orderId ≤ 2^32
// (4.3 bln orders — never reachable; beyond = re-deploy). The standard excesses
// carries ONLY the query_id (no payload), so the nonce lives here.
@pure
fun qidDeliver(orderId: uint64, nonce: uint64): uint64 {
    return ((((nonce & 0x1FFFFFFF) << 35) | ((orderId & 0xFFFFFFFF) << 3) | T_DELIVER)) as uint64;
}

// per-order nonce: hash(orderId · logicalTime · user) truncated to 64 bit. Not
// guessable without observing the venue payload on-chain (which on TON is hard to
// anticipate before the real settle); coupled with the per-order floor it makes
// the forged dust-settle impractical.
fun makeNonce(orderId: uint64, user: address): uint64 {
    return (beginCell().storeUint(orderId, 64).storeUint(blockchain.logicalTime(), 64)
        .storeAddress(user).endCell().hash() & 0xFFFFFFFFFFFFFFFF) as uint64;
}

fun markCell(op: uint32, orderId: uint64, nonce: uint64): cell {
    return beginCell().storeUint(op, 32).storeUint(orderId, 64).storeUint(nonce, 64).endCell();
}

// refusal note for a TON-in order: all the value returns to the sender (mode 64)
fun refuseTon(dest: address, queryId: uint64, code: uint16) {
    createMessage({
        bounce: BounceMode.NoBounce,
        value: 0,
        dest: dest,
        body: RefuseNote { queryId: queryId, code: code }
    }).send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
}

// refund jetton through the pipe they arrived from (the notify's sender wallet):
// if the wallet was fake it moves nothing real — a symmetric no-op by construction
fun refundJetViaPipe(pipeWallet: address, amount: coins, toUser: address, orderId: uint64) {
    createMessage({
        bounce: BounceMode.NoBounce,
        value: 0,
        dest: pipeWallet,
        body: JettonTransferMsg {
            queryId: qidOf(orderId, T_REFUND),
            amount: amount,
            destination: toUser,
            responseDestination: toUser,
            customPayload: null,
            forwardTonAmount: 0,
            forwardPayload: null
        }
    }).send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
}

// exact TON send (mode 1: forward fees are paid by the balance, covered by the order's pad)
fun sendTonExact(dest: address, amount: coins) {
    createMessage({
        bounce: BounceMode.NoBounce,
        value: amount,
        dest: dest
    }).send(SEND_MODE_PAY_FEES_SEPARATELY);
}

// TEP-89: ask the master for the address of OUR wallet (query_id = order+side)
fun sendDiscovery(master: address, orderId: uint64, side: int) {
    createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        value: GAS_DISCOVERY,
        dest: master,
        body: ProvideWalletAddress {
            queryId: qidOf(orderId, side),
            ownerAddress: contract.getAddress(),
            includeAddress: false
        }
    }).send(SEND_MODE_REGULAR);
}

// ston_swap payload built BY THE CONTRACT (never blind bytes from the client)
fun buildStonSwap(tokenWallet1: address, venueMinOut: coins, orderId: uint64, nonce: uint64): cell {
    val me = contract.getAddress();
    val inner = StonSwapInner {
        minOut: venueMinOut,
        receiver: me,
        fwdGas: GAS_FWD_SETTLE,
        customPayload: markCell(OP_SETTLE_MARK, orderId, nonce),
        refundFwdGas: GAS_FWD_SETTLE,
        refundPayload: markCell(OP_REFUND_MARK, orderId, nonce),
        refFee: 0,
        refAddress: createAddressNone()
    };
    val body = StonSwap {
        tokenWallet1: tokenWallet1,
        refundAddress: me,
        excessesAddress: me,
        deadline: (blockchain.now() + VENUE_DEADLINE) as uint64,
        inner: inner.toCell()
    };
    return beginCell().storeAny(body).endCell();
}

fun buildDedustParams(orderId: uint64, nonce: uint64): Cell<DedustParams> {
    val p = DedustParams {
        deadline: (blockchain.now() + VENUE_DEADLINE) as uint32,
        recipient: contract.getAddress(),
        referral: createAddressNone(),
        fulfillPayload: markCell(OP_SETTLE_MARK, orderId, nonce),
        rejectPayload: markCell(OP_REFUND_MARK, orderId, nonce)
    };
    return p.toCell();
}

// forwarding a leg: the contract BUILDS the venue payload from the typed order.
// net = amount that leaves · ride = TON attached to the message · legIdx: T_LEG1/T_LEG2
fun forwardLeg(leg: LegSpec, net: coins, ride: coins, venueMinOut: coins,
               orderId: uint64, nonce: uint64, legIdx: int, viaWallet: address?, user: address) {
    if (leg.kind == VK_STON_PTON) {
        // TON side → Ston router's pTON wallet with ston_swap in the forward
        createMessage({
            bounce: BounceMode.Only256BitsOfBody,
            value: ride,
            dest: leg.venue,
            body: PtonTransfer {
                queryId: qidOf(orderId, legIdx),
                tonAmount: net,
                refundAddress: contract.getAddress(),
                forwardPayload: buildStonSwap(leg.aux!, venueMinOut, orderId, nonce)
            }
        }).send(SEND_MODE_REGULAR);
        return;
    }
    if (leg.kind == VK_DEDUST_NATIVE) {
        createMessage({
            bounce: BounceMode.Only256BitsOfBody,
            value: ride,
            dest: leg.venue,
            body: DedustNativeSwap {
                queryId: qidOf(orderId, legIdx),
                amount: net,
                pool: leg.aux!,
                kindOut: false,
                limit: venueMinOut,
                next: null,
                params: buildDedustParams(orderId, nonce)
            }
        }).send(SEND_MODE_REGULAR);
        return;
    }
    // jetton legs: TEP-74 transfer from OUR wallet to the whitelisted venue
    var fwdPayload: cell? = null;
    if (leg.kind == VK_STON_JETTON) {
        fwdPayload = buildStonSwap(leg.aux!, venueMinOut, orderId, nonce);
    } else {
        // VK_DEDUST_JETTON
        fwdPayload = beginCell().storeAny(DedustJettonSwapPayload {
            pool: leg.aux!,
            kindOut: false,
            limit: venueMinOut,
            next: null,
            params: buildDedustParams(orderId, nonce)
        }).endCell();
    }
    createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        value: ride,
        dest: viaWallet!,
        body: JettonTransferMsg {
            queryId: qidOf(orderId, legIdx),
            amount: net,
            destination: leg.venue,
            responseDestination: user,
            customPayload: null,
            forwardTonAmount: ride > GAS_JET_HOP ? ride - GAS_JET_HOP : 0,
            forwardPayload: fwdPayload
        }
    }).send(SEND_MODE_REGULAR);
}

// form/security validation of a leg (kind consistent with the side)
fun legRefuseCode(gov: GovMaps, leg: LegSpec, sideIsTon: bool,
                  tIn: address?, tOut: address?, tMid: address?): int {
    val isTonKind = (leg.kind == VK_STON_PTON) | (leg.kind == VK_DEDUST_NATIVE);
    val isJetKind = (leg.kind == VK_STON_JETTON) | (leg.kind == VK_DEDUST_JETTON);
    if (!isTonKind && !isJetKind) { return ERR_BAD_TARGET; }
    if (sideIsTon && !isTonKind)  { return ERR_BAD_TARGET; }
    if (!sideIsTon && !isJetKind) { return ERR_BAD_TARGET; }
    if (leg.aux == null) { return ERR_BAD_TARGET; }
    if (!gov.allowed.exists(leg.venue)) { return ERR_TARGET; }
    // the venue is never one of the route's tokens
    if (tIn != null && leg.venue == tIn)   { return ERR_TARGET_TOKEN; }
    if (tOut != null && leg.venue == tOut) { return ERR_TARGET_TOKEN; }
    if (tMid != null && leg.venue == tMid) { return ERR_TARGET_TOKEN; }
    return 0;
}

// ---------------- state machine: order creation ----------------

fun acceptOrForward(mutate st: Storage, mutate run: RunMaps, ord: Order, orderId: uint64) {
    // if all the needed wallet identities are known → forward leg1, otherwise await discovery
    if (ord.needMask == 0) {
        var o = ord;
        forwardLeg1(mutate st, mutate run, mutate o, orderId);
        run.orders.set(orderId, o.toCell());
    } else {
        val tokens = ord.tokens.load();
        if ((ord.needMask & 1) != 0) { sendDiscovery(tokens.inMaster!, orderId, Q_IN); }
        if ((ord.needMask & 2) != 0) { sendDiscovery(tokens.outMaster!, orderId, Q_OUT); }
        if ((ord.needMask & 4) != 0) { sendDiscovery(tokens.midMaster!, orderId, Q_MID); }
        var o = ord;
        val nDisc = ((ord.needMask & 1) != 0 ? 1 : 0) + ((ord.needMask & 2) != 0 ? 1 : 0)
                  + ((ord.needMask & 4) != 0 ? 1 : 0);
        o.heldTon -= (GAS_DISCOVERY * nDisc) as coins;
        st.pendingTon -= (GAS_DISCOVERY * nDisc) as coins;
        run.orders.set(orderId, o.toCell());
    }
}

fun forwardLeg1(mutate st: Storage, mutate run: RunMaps, mutate ord: Order, orderId: uint64) {
    val f = ord.funds.load();
    val tokens = ord.tokens.load();
    val leg = ord.leg1.load();
    // inbound fee ONLY on single-leg (two-leg takes the fee on the MID, never on the input)
    val inFee = (ord.feeOnInput && !ord.twoLeg) ? feeOf(f.amountIn, ord.feeBpsSnap) : (0 as coins);
    val net = f.amountIn - inFee;
    // venueMinOut derived from the user's minOut: never from the client
    var vMin: coins = 0;
    if (ord.twoLeg) {
        vMin = f.midMin;      // leg1's routing hint (the real protection is leg2)
    } else if (ord.feeOnInput) {
        vMin = f.minOut;      // fee already taken inbound: the out reaches the user in full
    } else {
        vMin = grossFloorFor(f.minOut, ord.feeBpsSnap);
    }
    if (ord.tonIn) {
        // the net leaves + all the gas float except the settle reserve
        val ride = ord.heldTon - inFee - GAS_FWD_SETTLE;
        forwardLeg(leg, net, ride, vMin, orderId, ord.nonce, T_LEG1, null, ord.user);
        st.pendingTon -= ride;
        ord.heldTon = inFee + GAS_FWD_SETTLE;
    } else {
        val reserve = ord.twoLeg ? GAS_LEG2_RESERVE : GAS_FWD_SETTLE;
        val ride = ord.heldTon - reserve;
        forwardLeg(leg, net, ride, vMin, orderId, ord.nonce, T_LEG1,
                   run.walletOf.get(tokens.inMaster!).loadValue(), ord.user);
        st.pendingTon -= ride;
        ord.heldTon = reserve;
        // the net leaves custody; any inbound fee stays at rest
        subPendingJet(mutate run, tokens.inMaster!, net);
        var nf = f;
        nf.heldJet = inFee;
        nf.feeHeld = inFee;
        nf.heldMaster = ord.feeOnInput ? tokens.inMaster : null;
        ord.funds = nf.toCell();
        ord.sentJet = net;
    }
    ord.state = ST_SENT1;
}

fun addPendingJet(mutate run: RunMaps, master: address, amount: coins) {
    val cur = run.pendingJet.get(master);
    val base: coins = cur.isFound ? cur.loadValue() : 0;
    run.pendingJet.set(master, base + amount);
}

fun subPendingJet(mutate run: RunMaps, master: address, amount: coins) {
    val cur = run.pendingJet.get(master);
    if (!cur.isFound) { return; }
    val base: coins = cur.loadValue();
    val next = base > amount ? base - amount : (0 as coins);
    if (next == 0) {
        run.pendingJet.delete(master);
    } else {
        run.pendingJet.set(master, next);
    }
}

// ---------------- refund/delivery ----------------

// full refund of an order whose funds are STILL here (AWAIT / discovery bounce)
fun refundHeld(mutate st: Storage, mutate run: RunMaps, ord: Order, orderId: uint64) {
    val f = ord.funds.load();
    if (!ord.tonIn && f.heldJet > 0 && ord.claimedWallet != null) {
        refundJetViaPipe(ord.claimedWallet!, f.heldJet, ord.user, orderId);
        val tokens = ord.tokens.load();
        subPendingJet(mutate run, tokens.inMaster!, f.heldJet);
    }
    if (ord.heldTon > SEND_FEE_PAD) {
        sendTonExact(ord.user, ord.heldTon - SEND_FEE_PAD);
    }
    st.pendingTon -= ord.heldTon;
    run.orders.delete(orderId);
}

// delivery of the out jetton + travel of the fee IN THE SAME STEP
fun deliverJetOut(mutate st: Storage, mutate run: RunMaps, mutate ord: Order,
                  orderId: uint64, outWallet: address, gross: coins) {
    val f = ord.funds.load();
    val tokens = ord.tokens.load();
    var userOut = gross;
    var outFee: coins = 0;
    if (!ord.twoLeg && !ord.feeOnInput) {
        outFee = feeOf(gross, ord.feeBpsSnap);   // fee FROZEN at order creation
        userOut = gross - outFee;
    }
    // 1) delivery to the user — rides the value of the settle notification (mode 64)
    createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        value: 0,
        dest: outWallet,
        body: JettonTransferMsg {
            queryId: qidDeliver(orderId, ord.nonce),
            amount: userOut,
            destination: ord.user,
            responseDestination: contract.getAddress(),   // the returning excesses closes the order
            customPayload: null,
            forwardTonAmount: 0,
            forwardPayload: null
        }
    }).send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
    // 2) fee: leaves ONLY now, never before
    if (outFee > 0) {
        // fee on the solid out: second transfer from the same wallet
        createMessage({
            bounce: BounceMode.Only256BitsOfBody,
            value: ord.heldTon,
            dest: outWallet,
            body: JettonTransferMsg {
                queryId: qidOf(orderId, T_FEE),
                amount: outFee,
                destination: FEE_WALLET,
                responseDestination: ord.user,
                customPayload: null,
                forwardTonAmount: 0,
                forwardPayload: null
            }
        }).send(SEND_MODE_REGULAR);
        st.pendingTon -= ord.heldTon;
        ord.heldTon = 0;
    } else if (f.feeHeld > 0) {
        if (f.heldMaster == null) {
            // held TON fee (TON-in buy / mid TON): travels exact
            sendTonExact(FEE_WALLET, f.feeHeld);
            val spend = f.feeHeld + SEND_FEE_PAD;
            st.pendingTon -= spend > ord.heldTon ? ord.heldTon : spend;
            ord.heldTon = spend > ord.heldTon ? 0 : ord.heldTon - spend;
        } else {
            // held jetton fee (solid in / mid jetton): transfer from the master's wallet
            createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                value: ord.heldTon,
                dest: run.walletOf.get(f.heldMaster!).loadValue(),
                body: JettonTransferMsg {
                    queryId: qidOf(orderId, T_FEE),
                    amount: f.feeHeld,
                    destination: FEE_WALLET,
                    responseDestination: ord.user,
                    customPayload: null,
                    forwardTonAmount: 0,
                    forwardPayload: null
                }
            }).send(SEND_MODE_REGULAR);
            st.pendingTon -= ord.heldTon;
            ord.heldTon = 0;
            subPendingJet(mutate run, f.heldMaster!, f.feeHeld);
        }
    }
    // state: delivery in flight, closed by the excesses (or TTL-cleanup / bounce→redelivery)
    ord.state = ST_DELIVERING;
    ord.deliveryBounced = false;
    ord.sentJet = userOut;
    var nf = f;
    nf.heldJet = userOut;
    nf.heldMaster = tokens.outMaster;
    nf.feeHeld = 0;
    ord.funds = nf.toCell();
    run.orders.set(orderId, ord.toCell());
}

// TON delivery to the user (solid TON out) + exact fee to the fee wallet.
// If the fee was HELD in jetton (solid in, e.g. USDT→TON with input fee),
// it travels NOW via the master's wallet — never fee funds left in custody.
fun deliverTonOut(mutate st: Storage, mutate run: RunMaps, ord: Order,
                  orderId: uint64, gross: coins) {
    val f = ord.funds.load();
    var userOut = gross;
    var outFee: coins = 0;
    if (!ord.feeOnInput) {
        outFee = feeOf(gross, ord.feeBpsSnap);   // fee FROZEN at order creation
        userOut = gross - outFee;
    }
    var extra = ord.heldTon > SEND_FEE_PAD ? ord.heldTon - SEND_FEE_PAD : (0 as coins);
    if (outFee == 0 && f.feeHeld > 0 && f.heldMaster != null) {
        val w = run.walletOf.get(f.heldMaster!);
        if (w.isFound) {
            createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                value: extra,
                dest: w.loadValue(),
                body: JettonTransferMsg {
                    queryId: qidOf(orderId, T_FEE),
                    amount: f.feeHeld,
                    destination: FEE_WALLET,
                    responseDestination: ord.user,
                    customPayload: null,
                    forwardTonAmount: 0,
                    forwardPayload: null
                }
            }).send(SEND_MODE_REGULAR);
            subPendingJet(mutate run, f.heldMaster!, f.feeHeld);
            extra = 0;   // the residual float pays for the fee's travel
        }
    }
    sendTonExact(ord.user, userOut + extra);
    if (outFee > 0) { sendTonExact(FEE_WALLET, outFee); }
    st.pendingTon -= ord.heldTon;
    run.orders.delete(orderId);
}

// ---------------- entrypoint ----------------

fun onInternalMessage(in: InMessage) {
    if (in.body.isEmpty()) {
        return;   // simple top-up
    }
    val msg = lazy InMsg.fromSlice(in.body);
    match (msg) {
        TonOrder => { handleTonOrder(msg, in.senderAddress, in.valueCoins); }
        JettonNotify => { handleNotify(msg, in.senderAddress, in.valueCoins); }
        TakeWalletAddress => { handleTakeWallet(msg, in.senderAddress); }
        Excesses => { handleExcesses(msg); }
        SettleMark => { handleTonSettle(msg.orderId, msg.nonce, in.senderAddress, in.valueCoins); }
        RefundMark => { handleTonRefund(msg.orderId, msg.nonce, in.senderAddress, in.valueCoins); }

        GovPropose => {
            var st = Storage.load();
            assert (in.senderAddress == st.owner) throw ERR_NOT_OWNER;
            assert (!st.renounced) throw ERR_RENOUNCED;
            assert (in.valueCoins >= GAS_DISCOVERY + SEND_FEE_PAD) throw ERR_GAS;
            var gov = st.gov.load();
            assert (!gov.allowed.exists(msg.target)) throw ERR_BAD_TARGET;
            gov.pendingEta.set(msg.target, (blockchain.now() + TIMELOCK) as uint32);
            st.gov = gov.toCell();
            st.save();
            // anti-vandalism guard: the TEP-89 probe leaves NOW;
            // if the target replies take_wallet_address it is a jetton master → auto-cancel
            sendDiscovery(msg.target, 0, Q_GOV);
            ackGov(in.senderAddress, msg.queryId);
        }
        GovExecute => {
            var st = Storage.load();
            assert (in.senderAddress == st.owner) throw ERR_NOT_OWNER;
            assert (!st.renounced) throw ERR_RENOUNCED;
            var gov = st.gov.load();
            val eta = gov.pendingEta.get(msg.target);
            assert (eta.isFound) throw ERR_TIMELOCK;
            assert (blockchain.now() >= eta.loadValue()) throw ERR_TIMELOCK;
            gov.pendingEta.delete(msg.target);
            gov.allowed.set(msg.target, true);
            st.gov = gov.toCell();
            st.save();
            ackGov(in.senderAddress, msg.queryId);
        }
        GovRemove => {
            var st = Storage.load();
            assert (in.senderAddress == st.owner) throw ERR_NOT_OWNER;
            assert (!st.renounced) throw ERR_RENOUNCED;
            var gov = st.gov.load();
            gov.pendingEta.delete(msg.target);
            gov.allowed.delete(msg.target);
            st.gov = gov.toCell();
            st.save();
            ackGov(in.senderAddress, msg.queryId);
        }
        GovProposeSolid => {
            var st = Storage.load();
            assert (in.senderAddress == st.owner) throw ERR_NOT_OWNER;
            assert (!st.renounced) throw ERR_RENOUNCED;
            var gov = st.gov.load();
            assert (!gov.solids.exists(msg.token)) throw ERR_BAD_SOLID;
            gov.pendingSolidEta.set(msg.token, (blockchain.now() + TIMELOCK) as uint32);
            st.gov = gov.toCell();
            st.save();
            ackGov(in.senderAddress, msg.queryId);
        }
        GovExecuteSolid => {
            var st = Storage.load();
            assert (in.senderAddress == st.owner) throw ERR_NOT_OWNER;
            assert (!st.renounced) throw ERR_RENOUNCED;
            var gov = st.gov.load();
            val eta = gov.pendingSolidEta.get(msg.token);
            assert (eta.isFound) throw ERR_TIMELOCK;
            assert (blockchain.now() >= eta.loadValue()) throw ERR_TIMELOCK;
            gov.pendingSolidEta.delete(msg.token);
            gov.solids.set(msg.token, true);
            st.gov = gov.toCell();
            st.save();
            ackGov(in.senderAddress, msg.queryId);
        }
        GovRemoveSolid => {
            var st = Storage.load();
            assert (in.senderAddress == st.owner) throw ERR_NOT_OWNER;
            assert (!st.renounced) throw ERR_RENOUNCED;
            var gov = st.gov.load();
            gov.pendingSolidEta.delete(msg.token);
            gov.solids.delete(msg.token);
            st.gov = gov.toCell();
            st.save();
            ackGov(in.senderAddress, msg.queryId);
        }
        GovSetFee => {
            var st = Storage.load();
            assert (in.senderAddress == st.owner) throw ERR_NOT_OWNER;
            assert (!st.renounced) throw ERR_RENOUNCED;
            assert (msg.bps >= MIN_FEE_BPS && msg.bps <= MAX_FEE_BPS) throw ERR_FEE_RANGE;
            st.feeBps = msg.bps;
            st.save();
            ackGov(in.senderAddress, msg.queryId);
        }
        GovPause => {
            // pause is NOT frozen by renounce (safety over immutability)
            var st = Storage.load();
            assert (in.senderAddress == st.owner) throw ERR_NOT_OWNER;
            st.paused = true;
            st.save();
            ackGov(in.senderAddress, msg.queryId);
        }
        GovUnpause => {
            var st = Storage.load();
            assert (in.senderAddress == st.owner) throw ERR_NOT_OWNER;
            st.paused = false;
            st.save();
            ackGov(in.senderAddress, msg.queryId);
        }
        GovTransferOwnership => {
            var st = Storage.load();
            assert (in.senderAddress == st.owner) throw ERR_NOT_OWNER;
            assert (!st.renounced) throw ERR_RENOUNCED;
            st.pendingOwner = msg.newOwner;
            st.save();
            ackGov(in.senderAddress, msg.queryId);
        }
        GovAcceptOwnership => {
            var st = Storage.load();
            assert (!st.renounced) throw ERR_RENOUNCED;
            assert (st.pendingOwner != null) throw ERR_NOT_PENDING_OWNER;
            assert (in.senderAddress == st.pendingOwner!) throw ERR_NOT_PENDING_OWNER;
            st.owner = st.pendingOwner!;
            st.pendingOwner = null;
            st.save();
            ackGov(in.senderAddress, msg.queryId);
        }
        GovRenounce => {
            var st = Storage.load();
            assert (in.senderAddress == st.owner) throw ERR_NOT_OWNER;
            st.renounced = true;
            st.save();
            ackGov(in.senderAddress, msg.queryId);
        }
        SweepTon => {
            // anyone; funds ONLY to the fee wallet; NEVER below storage reserve + order pendings
            val st = Storage.load();
            val balance = contract.getOriginalBalance();
            val floor = STORAGE_RESERVE + st.pendingTon + in.valueCoins;
            assert (balance > floor) throw ERR_NOTHING_TO_SWEEP;
            createMessage({
                bounce: BounceMode.NoBounce,
                value: balance - floor,
                dest: FEE_WALLET
            }).send(SEND_MODE_REGULAR);
            ackGov(in.senderAddress, msg.queryId);
        }
        SweepJetton => {
            // anyone; forbidden if the master has pending-order funds
            val st = Storage.load();
            val run = st.run.load();
            val pend = run.pendingJet.get(msg.master);
            assert (!pend.isFound) throw ERR_SWEEP_PENDING;
            val w = run.walletOf.get(msg.master);
            assert (w.isFound) throw ERR_BAD_TARGET;
            assert (in.valueCoins >= GAS_JET_HOP) throw ERR_GAS;
            createMessage({
                bounce: BounceMode.NoBounce,
                value: 0,
                dest: w.loadValue(),
                body: JettonTransferMsg {
                    queryId: qidOf(0, T_SWEEP),
                    amount: msg.amount,
                    destination: FEE_WALLET,
                    responseDestination: FEE_WALLET,
                    customPayload: null,
                    forwardTonAmount: 0,
                    forwardPayload: null
                }
            }).send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }
        Reclaim => { handleReclaim(msg.orderId, in.valueCoins); }
        else => { throw 0xffff; }
    }
}

fun ackGov(dest: address, queryId: uint64) {
    createMessage({
        bounce: BounceMode.NoBounce,
        value: 0,
        dest: dest,
        body: GovAck { queryId: queryId }
    }).send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
}

// ---------------- orders: TON inbound ----------------

fun handleTonOrder(msg: TonOrder, sender: address, msgValue: coins) {
    var st = Storage.load();
    if (st.paused) { refuseTon(sender, msg.queryId, ERR_PAUSED); return; }
    if (msg.amountIn == 0) { refuseTon(sender, msg.queryId, ERR_AMOUNT); return; }
    if (msg.minOut == 0) { refuseTon(sender, msg.queryId, ERR_MIN_OUT); return; }
    if (msgValue < msg.amountIn + GAS_FLOOR_SINGLE) { refuseTon(sender, msg.queryId, ERR_GAS); return; }
    // solid fee side: TON is solid by CODE; if the fee goes on the out, the out must be solid
    val gov = st.gov.load();
    if (!msg.feeOnInput && !gov.solids.exists(msg.outMaster)) {
        refuseTon(sender, msg.queryId, ERR_FEE_SIDE);
        return;
    }
    val leg = msg.leg1.load();
    val code = legRefuseCode(gov, leg, true, null, msg.outMaster, null);
    if (code != 0) { refuseTon(sender, msg.queryId, code as uint16); return; }

    var run = st.run.load();
    st.seqno += 1;
    val orderId = st.seqno;
    val known = run.walletOf.get(msg.outMaster);
    var ord = Order {
        user: sender,
        claimedWallet: null,
        state: ST_AWAIT,
        twoLeg: false,
        feeOnInput: msg.feeOnInput,
        tonIn: true,
        tonOut: false,
        midIsTon: false,
        deliveryBounced: false,
        needMask: known.isFound ? 0 : 2,
        createdAt: blockchain.now() as uint32,
        feeBpsSnap: st.feeBps,
        nonce: makeNonce(orderId, sender),
        heldTon: msgValue,
        sentJet: 0,
        funds: OrderFunds {
            amountIn: msg.amountIn, minOut: msg.minOut, midMin: 0,
            heldJet: 0, feeHeld: msg.feeOnInput ? feeOf(msg.amountIn, st.feeBps) : 0,
            heldMaster: null
        }.toCell(),
        tokens: OrderTokens { inMaster: null, outMaster: msg.outMaster, midMaster: null }.toCell(),
        leg1: msg.leg1,
        leg2: null
    };
    st.pendingTon += msgValue;
    acceptOrForward(mutate st, mutate run, ord, orderId);
    st.run = run.toCell();
    st.save();
}

// ---------------- orders/settle/refund: jetton notification ----------------

fun handleNotify(msg: JettonNotify, senderWallet: address, msgValue: coins) {
    // parse of the forward payload (Either Cell ^Cell)
    var p: slice = msg.forwardPayload;
    if (p.isEmpty()) { return; }   // simple transfer without payload: donation → surplus
    val isRef = p.loadBool();
    if (isRef) {
        if (p.remainingRefsCount() == 0) { return; }
        p = p.loadRef().beginParse();
    }
    if (p.remainingBitsCount() < 32) { return; }
    val op = p.loadUint(32);
    if (op == OP_ORDER_JET) {
        handleJetOrder(msg, senderWallet, msgValue, mutate p);
    } else if (op == OP_SETTLE_MARK) {
        if (p.remainingBitsCount() < 128) { return; }   // orderId(64) + nonce(64)
        val oid = p.loadUint(64) as uint64;
        val non = p.loadUint(64) as uint64;
        handleJetSettle(oid, non, senderWallet, msg.amount, msgValue);
    } else if (op == OP_REFUND_MARK) {
        if (p.remainingBitsCount() < 128) { return; }
        val oid = p.loadUint(64) as uint64;
        val non = p.loadUint(64) as uint64;
        handleJetRefund(oid, non, senderWallet, msg.amount);
    }
    // unknown op: jetton arrived without an order → surplus (sweepable), never throw:
    // a throw here would only lose the notification, the jetton are already credited
}

fun handleJetOrder(msg: JettonNotify, senderWallet: address, msgValue: coins, mutate p: slice) {
    var st = Storage.load();
    // TOLERANT parse: trailing bits after the fields NEVER throw away an order with funds
    val body = JetOrderBody.fromSlice(p, { assertEndAfterReading: false });
    val tokens = body.tokens.load();
    val user = msg.sender;

    // pipe identity: if the declared master already has a verified wallet DIFFERENT
    // from the sender, the notification is COUNTERFEIT → no-op (no real funds exist)
    var run = st.run.load();
    if (tokens.inMaster == null) { refundJetViaPipe(senderWallet, msg.amount, user, 0); return; }
    val inMaster = tokens.inMaster!;
    val cachedW = run.walletOf.get(inMaster);
    val verified = cachedW.isFound && cachedW.loadValue() == senderWallet;
    if (cachedW.isFound && !verified) { return; }

    // guards (every violation = refund through the arrival pipe)
    if (st.paused) { refundJetViaPipe(senderWallet, msg.amount, user, 0); return; }
    if (msg.amount == 0) { refundJetViaPipe(senderWallet, msg.amount, user, 0); return; }
    if (body.minOut == 0) { refundJetViaPipe(senderWallet, msg.amount, user, 0); return; }
    val floor = body.twoLeg ? GAS_FLOOR_TWOLEG : GAS_FLOOR_SINGLE;
    if (msgValue < floor) { refundJetViaPipe(senderWallet, msg.amount, user, 0); return; }

    val gov = st.gov.load();
    var refuse = 0;
    if (body.twoLeg) {
        // two-leg: out jetton, mid TON or registered SOLID jetton.
        // the two-leg fee is ALWAYS on the received mid → feeOnInput is contradictory, rejected.
        if (body.feeOnInput) { refuse = ERR_FEE_SIDE; }
        else if (body.tonOut || tokens.outMaster == null) { refuse = ERR_BAD_TARGET; }
        else if (body.midIsTon) {
            if (tokens.midMaster != null) { refuse = ERR_BAD_TARGET; }
        } else if (tokens.midMaster == null || !gov.solids.exists(tokens.midMaster!)) {
            refuse = ERR_INTERMEDIATE;
        }
        if (refuse == 0 && tokens.outMaster != null && inMaster == tokens.outMaster!) { refuse = ERR_SAME_TOKEN; }
        if (refuse == 0 && tokens.midMaster != null
            && (inMaster == tokens.midMaster! || tokens.outMaster! == tokens.midMaster!)) {
            refuse = ERR_SAME_TOKEN;
        }
        if (refuse == 0 && body.leg2 == null) { refuse = ERR_BAD_TARGET; }
        // the mid's anti-forge floor = midMin; midMin==0
        // nullifies it → rejection of the degenerate case. The TIGHT floor is the client's responsibility.
        if (refuse == 0 && body.midMin == 0) { refuse = ERR_MID_MIN; }
    } else {
        // single-leg: solid fee side mandatory (meme→meme single REJECTED → two-leg)
        if (body.tonOut) {
            if (tokens.outMaster != null) { refuse = ERR_BAD_TARGET; }
            else if (body.feeOnInput && !gov.solids.exists(inMaster)) { refuse = ERR_FEE_SIDE; }
        } else {
            if (tokens.outMaster == null) { refuse = ERR_BAD_TARGET; }
            else if (inMaster == tokens.outMaster!) { refuse = ERR_SAME_TOKEN; }
            else if (body.feeOnInput) {
                if (!gov.solids.exists(inMaster)) { refuse = ERR_FEE_SIDE; }
            } else if (!gov.solids.exists(tokens.outMaster!)) {
                refuse = ERR_FEE_SIDE;
            }
        }
    }
    if (refuse == 0) {
        val leg1 = body.leg1.load();
        refuse = legRefuseCode(gov, leg1, false, tokens.inMaster, tokens.outMaster, tokens.midMaster);
    }
    if (refuse == 0 && body.twoLeg) {
        val leg2 = body.leg2!.load();
        refuse = legRefuseCode(gov, leg2, body.midIsTon, tokens.inMaster, tokens.outMaster, tokens.midMaster);
    }
    if (refuse != 0) { refundJetViaPipe(senderWallet, msg.amount, user, 0); return; }

    // acceptance: funds in custody, discovery for each missing identity
    st.seqno += 1;
    val orderId = st.seqno;
    var need = verified ? 0 : 1;
    if (!body.tonOut && !run.walletOf.get(tokens.outMaster!).isFound) { need |= 2; }
    if (body.twoLeg && !body.midIsTon && !run.walletOf.get(tokens.midMaster!).isFound) { need |= 4; }
    val inFee = body.feeOnInput && !body.twoLeg ? feeOf(msg.amount, st.feeBps) : (0 as coins);
    var ord = Order {
        user: user,
        claimedWallet: senderWallet,
        state: ST_AWAIT,
        twoLeg: body.twoLeg,
        feeOnInput: body.feeOnInput,
        tonIn: false,
        tonOut: body.tonOut,
        midIsTon: body.midIsTon,
        deliveryBounced: false,
        needMask: need as uint8,
        createdAt: blockchain.now() as uint32,
        feeBpsSnap: st.feeBps,
        nonce: makeNonce(orderId, user),
        heldTon: msgValue,
        sentJet: 0,
        funds: OrderFunds {
            amountIn: msg.amount, minOut: body.minOut, midMin: body.midMin,
            heldJet: msg.amount, feeHeld: inFee, heldMaster: tokens.inMaster
        }.toCell(),
        tokens: body.tokens,
        leg1: body.leg1,
        leg2: body.leg2
    };
    st.pendingTon += msgValue;
    addPendingJet(mutate run, inMaster, msg.amount);
    acceptOrForward(mutate st, mutate run, ord, orderId);
    st.run = run.toCell();
    st.save();
}

// jetton settle: the out (or the mid) arrived at OUR wallet. The check is
// FORWARD: the sender must be EXACTLY walletOf[master expected in this
// phase of the order] — never a reverse lookup (poisonable by a hostile master).
fun handleJetSettle(orderId: uint64, nonce: uint64, senderWallet: address, gross: coins, msgValue: coins) {
    var st = Storage.load();
    var run = st.run.load();
    val oc = run.orders.get(orderId);
    if (!oc.isFound) { return; }       // closed/unknown order (double settle) → surplus
    var ord = oc.loadValue().load();
    if (ord.nonce != nonce) { return; }   // the marker MUST carry the order's nonce
    val tokens = ord.tokens.load();
    val f = ord.funds.load();

    if (ord.state == ST_SENT1 && ord.twoLeg && !ord.midIsTon && tokens.midMaster != null) {
        val expect = run.walletOf.get(tokens.midMaster!);
        if (!expect.isFound || expect.loadValue() != senderWallet) { return; }
        if (gross < f.midMin) { return; }   // mid floor (never a dust-mid)
        // solid mid arrived: fee on the RECEIVED, leg2 on the net
        settleMidAndLeg2(mutate st, mutate run, mutate ord, orderId, gross, false);
        st.run = run.toCell();
        st.save();
        return;
    }
    val isOutPhase =
        ((ord.state == ST_SENT1 && !ord.twoLeg) || ord.state == ST_SENT2)
        && !ord.tonOut && tokens.outMaster != null;
    if (!isOutPhase) { return; }
    val expect = run.walletOf.get(tokens.outMaster!);
    if (!expect.isFound || expect.loadValue() != senderWallet) { return; }
    // per-order floor on the OUT — a settle below the guaranteed minimum is forged/anomalous.
    // A legitimate settle ALWAYS carries gross ≥ venueMinOut (the whitelisted venue honored it).
    val outFloor = (ord.feeOnInput || ord.twoLeg) ? f.minOut : grossFloorFor(f.minOut, ord.feeBpsSnap);
    if (gross < outFloor) { return; }
    deliverJetOut(mutate st, mutate run, mutate ord, orderId, senderWallet, gross);
    st.run = run.toCell();
    st.save();
}

// fee on the received mid + leg2 forwarding with the net (mid jetton or TON)
fun settleMidAndLeg2(mutate st: Storage, mutate run: RunMaps, mutate ord: Order,
                     orderId: uint64, midGross: coins, midTon: bool) {
    val f = ord.funds.load();
    val tokens = ord.tokens.load();
    val midFee = feeOf(midGross, ord.feeBpsSnap);   // fee FROZEN
    val midNet = midGross - midFee;
    val leg2 = ord.leg2!.load();
    if (midTon) {
        // the settle value is already on the balance: the net leaves again + the float beyond the reserve
        val ride = midNet + (ord.heldTon - GAS_FWD_SETTLE);
        forwardLeg(leg2, midNet, ride, f.minOut, orderId, ord.nonce, T_LEG2, null, ord.user);
        st.pendingTon += midGross;             // the gross entered custody...
        st.pendingTon -= ride;                 // ...and the net+gas leaves again immediately
        ord.heldTon = ord.heldTon + midGross - ride;
        var nf = f;
        nf.feeHeld = midFee;
        nf.heldMaster = null;
        nf.heldJet = 0;
        ord.funds = nf.toCell();
    } else {
        addPendingJet(mutate run, tokens.midMaster!, midGross);
        val ride = ord.heldTon - GAS_FWD_SETTLE;
        forwardLeg(leg2, midNet, ride, f.minOut, orderId, ord.nonce, T_LEG2,
                   run.walletOf.get(tokens.midMaster!).loadValue(), ord.user);
        st.pendingTon -= ride;
        ord.heldTon = GAS_FWD_SETTLE;
        subPendingJet(mutate run, tokens.midMaster!, midNet);
        var nf = f;
        nf.feeHeld = midFee;
        nf.heldMaster = tokens.midMaster;
        nf.heldJet = midFee;
        ord.funds = nf.toCell();
        ord.sentJet = midNet;
    }
    ord.state = ST_SENT2;
    run.orders.set(orderId, ord.toCell());
}

// refund jetton from the venue (leg1 rejected: the inbound jetton come back ·
// leg2 rejected: the net mid comes back — NET+FEE is returned)
fun handleJetRefund(orderId: uint64, nonce: uint64, senderWallet: address, amount: coins) {
    var st = Storage.load();
    var run = st.run.load();
    val oc = run.orders.get(orderId);
    if (!oc.isFound) { return; }
    val ord = oc.loadValue().load();
    if (ord.nonce != nonce) { return; }   // refund forged without the order's nonce → ignored
    val f = ord.funds.load();
    val tokens = ord.tokens.load();

    // FORWARD check of the pipe (never a reverse lookup)
    var fromIn = false;
    if (tokens.inMaster != null) {
        val w = run.walletOf.get(tokens.inMaster!);
        fromIn = w.isFound && w.loadValue() == senderWallet;
    }
    var fromMid = false;
    if (tokens.midMaster != null) {
        val w = run.walletOf.get(tokens.midMaster!);
        fromMid = w.isFound && w.loadValue() == senderWallet;
    }

    if (ord.state == ST_SENT1 && !ord.tonIn && tokens.inMaster != null && fromIn) {
        // leg1 failed: FULL INPUT refund (net refunded + any inbound fee)
        val total = amount + f.feeHeld;
        refundJetViaPipe(senderWallet, total, ord.user, orderId);
        if (f.feeHeld > 0) { subPendingJet(mutate run, tokens.inMaster!, f.feeHeld); }
        if (ord.heldTon > SEND_FEE_PAD) { sendTonExact(ord.user, ord.heldTon - SEND_FEE_PAD); }
        st.pendingTon -= ord.heldTon;
        run.orders.delete(orderId);
        st.run = run.toCell();
        st.save();
        return;
    }
    if (ord.state == ST_SENT2 && !ord.midIsTon && tokens.midMaster != null && fromMid) {
        // leg2 failed: refund of the NET mid + HELD fee
        val total = amount + f.feeHeld;
        refundJetViaPipe(senderWallet, total, ord.user, orderId);
        subPendingJet(mutate run, tokens.midMaster!, f.feeHeld);
        if (ord.heldTon > SEND_FEE_PAD) { sendTonExact(ord.user, ord.heldTon - SEND_FEE_PAD); }
        st.pendingTon -= ord.heldTon;
        run.orders.delete(orderId);
        st.run = run.toCell();
        st.save();
        return;
    }
}

// ---------------- settle/refund TON (native payout from the whitelisted venue) ----------------

fun handleTonSettle(orderId: uint64, nonce: uint64, sender: address, value: coins) {
    var st = Storage.load();
    val gov = st.gov.load();
    if (!gov.allowed.exists(sender)) { return; }   // TON-settle ONLY from whitelisted infrastructure
    var run = st.run.load();
    val oc = run.orders.get(orderId);
    if (!oc.isFound) { return; }
    var ord = oc.loadValue().load();
    if (ord.nonce != nonce) { return; }   // order's nonce mandatory
    val f = ord.funds.load();
    if (ord.state == ST_SENT1 && ord.twoLeg && ord.midIsTon) {
        if (value < f.midMin) { return; }   // mid floor
        settleMidAndLeg2(mutate st, mutate run, mutate ord, orderId, value, true);
        st.run = run.toCell();
        st.save();
        return;
    }
    val isOut = ((ord.state == ST_SENT1 && !ord.twoLeg) || ord.state == ST_SENT2) && ord.tonOut;
    if (!isOut) { return; }
    val outFloor = ord.feeOnInput ? f.minOut : grossFloorFor(f.minOut, ord.feeBpsSnap);
    if (value < outFloor) { return; }   // per-order floor on the OUT TON
    deliverTonOut(mutate st, mutate run, ord, orderId, value);
    st.run = run.toCell();
    st.save();
}

fun handleTonRefund(orderId: uint64, nonce: uint64, sender: address, value: coins) {
    var st = Storage.load();
    val gov = st.gov.load();
    if (!gov.allowed.exists(sender)) { return; }
    var run = st.run.load();
    val oc = run.orders.get(orderId);
    if (!oc.isFound) { return; }
    val ord = oc.loadValue().load();
    if (ord.nonce != nonce) { return; }   // order's nonce mandatory
    val f = ord.funds.load();
    if (ord.state == ST_SENT1 && ord.tonIn) {
        // leg1 TON failed: the value comes back + the residual float (held fee included)
        val back = value + ord.heldTon;
        sendTonExact(ord.user, back > SEND_FEE_PAD ? back - SEND_FEE_PAD : 0);
        st.pendingTon -= ord.heldTon;
        run.orders.delete(orderId);
        st.run = run.toCell();
        st.save();
        return;
    }
    if (ord.state == ST_SENT2 && ord.midIsTon) {
        // leg2 failed with mid TON: refund of the net mid (returned) + held TON fee
        val back = value + ord.heldTon;
        sendTonExact(ord.user, back > SEND_FEE_PAD ? back - SEND_FEE_PAD : 0);
        st.pendingTon -= ord.heldTon;
        run.orders.delete(orderId);
        st.run = run.toCell();
        st.save();
        return;
    }
}

// ---------------- TEP-89: master's reply ----------------

fun handleTakeWallet(msg: TakeWalletAddress, sender: address) {
    val purpose = (msg.queryId & 7) as int;
    val orderId = (msg.queryId >> 3) as uint64;
    var st = Storage.load();
    if (purpose == Q_GOV) {
        // the proposed target replied as a JETTON MASTER → auto-cancel
        var gov = st.gov.load();
        if (gov.pendingEta.exists(sender)) {
            gov.pendingEta.delete(sender);
            st.gov = gov.toCell();
            st.save();
        }
        return;
    }
    var run = st.run.load();
    val oc = run.orders.get(orderId);
    if (!oc.isFound) { return; }
    var ord = oc.loadValue().load();
    if (ord.state != ST_AWAIT) { return; }
    val tokens = ord.tokens.load();
    // the reply counts ONLY if it comes from the master we queried for that side
    var expected: address? = null;
    if (purpose == Q_IN)  { expected = tokens.inMaster; }
    if (purpose == Q_OUT) { expected = tokens.outMaster; }
    if (purpose == Q_MID) { expected = tokens.midMaster; }
    if (expected == null) { return; }
    if (sender != expected!) { return; }

    if (purpose == Q_IN && ord.claimedWallet != null && msg.walletAddress != ord.claimedWallet!) {
        // SPOOF proven: the declared master's real wallet is NOT the one that notified.
        // No real funds exist for this order → drop (the attach stays surplus).
        val f = ord.funds.load();
        subPendingJet(mutate run, tokens.inMaster!, f.heldJet);
        st.pendingTon -= ord.heldTon;
        run.orders.delete(orderId);
        st.run = run.toCell();
        st.save();
        return;
    }
    run.walletOf.set(sender, msg.walletAddress);          // cache FORWARD only: master → wallet
    val bit = purpose == Q_IN ? 1 : (purpose == Q_OUT ? 2 : 4);
    ord.needMask = (ord.needMask & (~bit)) as uint8;
    if (ord.needMask == 0) {
        forwardLeg1(mutate st, mutate run, mutate ord, orderId);
    }
    run.orders.set(orderId, ord.toCell());
    st.run = run.toCell();
    st.save();
}

// ---------------- excesses: delivery confirmation ----------------

fun handleExcesses(msg: Excesses) {
    val purpose = (msg.queryId & 7) as int;
    if (purpose != T_DELIVER) { return; }   // any other excesses → surplus
    val orderId = ((msg.queryId >> 3) & 0xFFFFFFFF) as uint64;
    val nonce29 = ((msg.queryId >> 35) & 0x1FFFFFFF) as int;
    var st = Storage.load();
    var run = st.run.load();
    val oc = run.orders.get(orderId);
    if (!oc.isFound) { return; }
    val ord = oc.loadValue().load();
    // the delivery excesses is emitted by the RECIPIENT's wallet (the user),
    // NOT by our out-wallet — a check on the sender would reject the LEGITIMATE confirmation (the
    // bug of the "fix"). The ONLY correct authentication is the NONCE: the user echoes
    // the query_id (= qidDeliver, with 29 bit of nonce) of OUR delivery transfer. A
    // forged excesses with the wrong nonce does not close. Residual window (an observer that
    // races the nonce on-chain before the real settle + bounce) is
    // limited: a legitimate excesses = successful delivery = no bounce incoming.
    if (((ord.nonce & 0x1FFFFFFF) as int) != nonce29) { return; }
    if (ord.state != ST_DELIVERING) { return; }
    if (ord.deliveryBounced) { return; }   // redelivery PENDING: do not close
    // delivery confirmed: close and return any residual float to the user
    if (ord.heldTon > SEND_FEE_PAD) { sendTonExact(ord.user, ord.heldTon - SEND_FEE_PAD); }
    st.pendingTon -= ord.heldTon;
    run.orders.delete(orderId);
    st.run = run.toCell();
    st.save();
}

// ---------------- reclaim TTL ----------------

fun handleReclaim(orderId: uint64, msgValue: coins) {
    var st = Storage.load();
    var run = st.run.load();
    val oc = run.orders.get(orderId);
    assert (oc.isFound) throw ERR_ORDER_UNKNOWN;
    var ord = oc.loadValue().load();
    assert (blockchain.now() >= ord.createdAt + ORDER_TTL) throw ERR_TTL;
    if (ord.state == ST_AWAIT) {
        // funds still HERE (discovery hung): full refund, ONLY to the order's user
        refundHeld(mutate st, mutate run, ord, orderId);
        st.run = run.toCell();
        st.save();
        return;
    }
    if (ord.state == ST_DELIVERING) {
        val tokens = ord.tokens.load();
        if (ord.deliveryBounced && ord.sentJet > 0 && tokens.outMaster != null) {
            // the delivery had bounced: the jetton are STILL in our wallet → redelivery
            assert (msgValue >= GAS_JET_HOP) throw ERR_GAS;
            createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                value: 0,
                dest: run.walletOf.get(tokens.outMaster!).loadValue(),
                body: JettonTransferMsg {
                    queryId: qidDeliver(orderId, ord.nonce),
                    amount: ord.sentJet,
                    destination: ord.user,
                    responseDestination: contract.getAddress(),
                    customPayload: null,
                    forwardTonAmount: 0,
                    forwardPayload: null
                }
            }).send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
            ord.deliveryBounced = false;
            subPendingJet(mutate run, tokens.outMaster!, ord.sentJet);
            run.orders.set(orderId, ord.toCell());
        } else {
            // delivery NOT (yet) bounced. Do NOT cancel — a late bounce
            // could still arrive and the redelivery would be lost. We return ONLY the residual
            // float (once, zeroing heldTon) and LEAVE the order in DELIVERING: if it then
            // bounces → deliveryBounced → a later reclaim redelivers; if the excesses arrives
            // → it closes (heldTon=0). Cost: a slot that stays until it resolves (float freed,
            // no user funds locked). Repeated reclaims are idempotent (heldTon already 0).
            if (ord.heldTon > SEND_FEE_PAD) { sendTonExact(ord.user, ord.heldTon - SEND_FEE_PAD); }
            st.pendingTon -= ord.heldTon;
            ord.heldTon = 0;
            run.orders.set(orderId, ord.toCell());
        }
        st.run = run.toCell();
        st.save();
        return;
    }
    // SENT1/SENT2: funds at the whitelisted venue — the venue's physics closes it (never a double payment)
    throw ERR_ORDER_STATE;
}

// ---------------- bounce of our messages ----------------

fun onBouncedMessage(in: InMessageBounced) {
    var b = in.bouncedBody;
    b.skipBouncedPrefix();
    if (b.remainingBitsCount() < 96) { return; }
    val op = b.loadUint(32);
    val qid = b.loadUint(64) as uint64;
    val purpose = (qid & 7) as int;
    val orderId = (qid >> 3) as uint64;

    if (op == OP_PROVIDE_WALLET) {
        if (purpose == Q_GOV) { return; }   // anti-token probe bounced: the target is NOT a token
        // the queried master is not a live contract: invalid order → full refund
        var st = Storage.load();
        var run = st.run.load();
        val oc = run.orders.get(orderId);
        if (!oc.isFound) { return; }
        val ord = oc.loadValue().load();
        if (ord.state != ST_AWAIT) { return; }
        refundHeld(mutate st, mutate run, ord, orderId);
        st.run = run.toCell();
        st.save();
        return;
    }
    if (op == OP_PTON_TRANSFER || op == OP_DEDUST_NATIVE) {
        // TON leg bounced: the value returned to the balance → refund to the user
        var st = Storage.load();
        var run = st.run.load();
        val oc = run.orders.get(orderId);
        if (!oc.isFound) { return; }
        val ord = oc.loadValue().load();
        if (purpose == T_LEG1 && ord.state == ST_SENT1 && ord.tonIn) {
            val back = in.valueCoins + ord.heldTon;
            sendTonExact(ord.user, back > SEND_FEE_PAD ? back - SEND_FEE_PAD : 0);
            st.pendingTon -= ord.heldTon;
            run.orders.delete(orderId);
            st.run = run.toCell();
            st.save();
        } else if (purpose == T_LEG2 && ord.state == ST_SENT2 && ord.midIsTon) {
            val back = in.valueCoins + ord.heldTon;   // heldTon includes the held mid fee
            sendTonExact(ord.user, back > SEND_FEE_PAD ? back - SEND_FEE_PAD : 0);
            st.pendingTon -= ord.heldTon;
            run.orders.delete(orderId);
            st.run = run.toCell();
            st.save();
        }
        return;
    }
    if (op == OP_JETTON_TRANSFER) {
        // the delivery uses qidDeliver (orderId 32 bit + nonce in the high bits): targeted decode
        val oid = (purpose == T_DELIVER) ? (((qid >> 3) & 0xFFFFFFFF) as uint64) : orderId;
        var st = Storage.load();
        var run = st.run.load();
        val oc = run.orders.get(oid);
        if (!oc.isFound) { return; }
        var ord = oc.loadValue().load();
        val f = ord.funds.load();
        val tokens = ord.tokens.load();
        if (purpose == T_LEG1 && ord.state == ST_SENT1 && !ord.tonIn) {
            // OUR wallet rejected leg1: the jetton never left → refund
            val total = ord.sentJet + f.feeHeld;
            refundJetViaPipe(ord.claimedWallet!, total, ord.user, oid);
            if (f.feeHeld > 0) { subPendingJet(mutate run, tokens.inMaster!, f.feeHeld); }
            if (ord.heldTon > SEND_FEE_PAD) { sendTonExact(ord.user, ord.heldTon - SEND_FEE_PAD); }
            st.pendingTon -= ord.heldTon;
            run.orders.delete(oid);
        } else if (purpose == T_LEG2 && ord.state == ST_SENT2 && !ord.midIsTon) {
            val total = ord.sentJet + f.feeHeld;
            val w = run.walletOf.get(tokens.midMaster!);
            if (w.isFound) { refundJetViaPipe(w.loadValue(), total, ord.user, oid); }
            subPendingJet(mutate run, tokens.midMaster!, f.feeHeld);
            if (ord.heldTon > SEND_FEE_PAD) { sendTonExact(ord.user, ord.heldTon - SEND_FEE_PAD); }
            st.pendingTon -= ord.heldTon;
            run.orders.delete(oid);
        } else if (purpose == T_DELIVER && ord.state == ST_DELIVERING) {
            // delivery bounced: the jetton returned to the wallet → redelivery via reclaim
            ord.deliveryBounced = true;
            if (tokens.outMaster != null) { addPendingJet(mutate run, tokens.outMaster!, ord.sentJet); }
            run.orders.set(oid, ord.toCell());
        }
        // T_FEE / T_REFUND / T_SWEEP bounced: the funds stay here → surplus (declared)
        st.run = run.toCell();
        st.save();
        return;
    }
}

// ---------------- get methods ----------------

get fun ownerAddress(): address {
    return Storage.load().owner;
}

get fun pendingOwnerAddress(): address? {
    return Storage.load().pendingOwner;
}

get fun feeBps(): int {
    return Storage.load().feeBps;
}

get fun isPaused(): bool {
    return Storage.load().paused;
}

get fun isRenounced(): bool {
    return Storage.load().renounced;
}

get fun feeWallet(): address {
    return FEE_WALLET;
}

get fun feeBounds(): (int, int, int) {
    return (MIN_FEE_BPS, MAX_FEE_BPS, DEFAULT_FEE_BPS);
}

get fun timelockSeconds(): int {
    return TIMELOCK;
}

get fun orderTtlSeconds(): int {
    return ORDER_TTL;
}

get fun isAllowed(target: address): bool {
    return Storage.load().gov.load().allowed.exists(target);
}

get fun pendingEtaOf(target: address): int {
    val r = Storage.load().gov.load().pendingEta.get(target);
    return r.isFound ? r.loadValue() : 0;
}

get fun isSolidToken(token: address): bool {
    return Storage.load().gov.load().solids.exists(token);
}

get fun pendingSolidEtaOf(token: address): int {
    val r = Storage.load().gov.load().pendingSolidEta.get(token);
    return r.isFound ? r.loadValue() : 0;
}

get fun pendingTonTotal(): coins {
    return Storage.load().pendingTon;
}

get fun pendingJetOf(master: address): coins {
    val r = Storage.load().run.load().pendingJet.get(master);
    return r.isFound ? r.loadValue() : 0;
}

get fun walletOfMaster(master: address): address? {
    val r = Storage.load().run.load().walletOf.get(master);
    return r.isFound ? r.loadValue() : null;
}

get fun orderSeqno(): int {
    return Storage.load().seqno;
}

get fun orderBrief(orderId: uint64): (int, int, int, int, int) {
    // (state, needMask, heldTon, sentJet, createdAt) — 0 for everything if the order does not exist
    val r = Storage.load().run.load().orders.get(orderId);
    if (!r.isFound) { return (0, 0, 0, 0, 0); }
    val o = r.loadValue().load();
    return (o.state, o.needMask, o.heldTon, o.sentJet, o.createdAt);
}

get fun parityVersion(): int {
    return 2;   // ListedRouterTon v2 — English build; logic identical to v1, only this version number differs
}
