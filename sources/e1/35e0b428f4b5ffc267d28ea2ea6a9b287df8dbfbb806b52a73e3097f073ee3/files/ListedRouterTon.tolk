// ListedRouterTon — fork fedele 1:1 del Listed Router EVM (contracts/ListedRouter.sol)
// sul modello full-custody di TON (docs/47, criteri congelati 2026-08-09).
//
// PARITÀ (le 12 garanzie di docs/43 §0 → docs/47 §2):
//  #1  fee recipient PINNATO nel codice (FEE_WALLET, mai parametro)
//  #2  fee bounds [0,100] bps nel codice, default 50, mai del caller; setFee owner-only nei bound
//  #3  fee UNA volta sul lato SOLIDO (TON = solido per CODICE; jetton solidi = registro);
//      meme→meme single-leg RIFIUTATO ⇒ two-leg obbligatoria
//  #4  two-leg col mid solido (TON o jetton registrato): fee sul mid RICEVUTO, leg2 sul netto
//  #5  whitelist venue: propose → timelock 24h → execute (guardia anti-token via TEP-89) · remove istantaneo
//  #6  registro solidi, stessa governance timelocked
//  #7  pull solo-da-firmatario: i fondi arrivano SOLO con messaggi firmati dall'utente;
//      il router non può prelevare nulla da nessuno
//  #8  misura ESATTA (importi delle notification / valore del messaggio = il "delta" EVM),
//      refund integrale su ogni fallimento, fee-on-transfer safe by physics
//  #9  pause SEMPRE viva (anche post-renounce) · renounce() congela target+solidi+fee per sempre
//  #10 sweep chiamabile da chiunque, fondi SOLO al fee wallet, MAI fondi di ordini pendenti
//  #11 ownership two-step, poteri solo di governance
//  #12 ops: KAT build riproducibile · suite avversariale emulatore · rehearsal testnet con
//      fallimenti forzati · regina · battesimo (docs/47 §5-§6)
//
// TRADUZIONE DI FISICA (unica, dichiarata e decisa dall'owner): l'atomicità in-tx
// dell'EVM diventa "OUT CONSEGNATO oppure REFUND COMPLETO — fee SOLO a successo":
// il contratto custodisce i fondi dell'ordine durante gli hop e la fee viaggia verso
// il fee wallet esclusivamente nello stesso passo della consegna all'utente.
//
// ANTI-SPOOF (docs/47 §4-bis decisione 1): l'identità wallet↔master non si assume mai —
// si verifica on-chain via TEP-89 (provide/take_wallet_address, query_id = order id,
// risposta accettata solo dal master interrogato) e si cachea. Una notification da un
// wallet non riconducibile al master dichiarato è un NO-OP (refund/ignore) per costruzione.
tolk 1.4

// ---------------- economics, pinned in code (.sol #1 #2) ----------------
const FEE_WALLET = address("UQDv3gHsDZPlCXToMSeKJfE5g4JN1aY7uxbqu0OtW-At_xNx");
const MIN_FEE_BPS = 0;
const MAX_FEE_BPS = 100;      // 1% ceiling, hard-coded
const DEFAULT_FEE_BPS = 50;   // 0.5% at deploy (init data must match — asserted in suite)
const TIMELOCK = 86400;       // 24h propose→execute (D20)
const ORDER_TTL = 3600;       // reclaim window for orders whose funds are still held here
const VENUE_DEADLINE = 600;   // deadline field handed to venues

// gas policy (tuned in F2 rehearsal — declared in docs/47 §7).
// I floor coprono il WORST CASE interno: discovery TEP-89 (fino a 2 single / 3 two-leg
// × 0.03) + hop wallet della gamba (0.05) + riserva settle (0.03) + margine venue —
// un floor più basso produrrebbe forwardTonAmount negativi a metà ordine.
const GAS_FLOOR_SINGLE = 250000000;  // 0.25 TON min budget attached to a single-leg order
const GAS_FLOOR_TWOLEG = 400000000;  // 0.40 TON min budget for a two-leg order
const GAS_DISCOVERY   = 30000000;    // 0.03 TON per TEP-89 provide roundtrip
const GAS_FWD_SETTLE  = 30000000;    // reserve kept for the settle/delivery step
const GAS_JET_HOP     = 50000000;    // 0.05 TON kept by a jetton-transfer wallet hop
const GAS_LEG2_RESERVE = 100000000;  // 0.10 TON kept aside for leg2 of a two-leg order
const SEND_FEE_PAD    = 10000000;    // 0.01 TON margin covering fwd fees of exact-value sends
const STORAGE_RESERVE = 250000000;   // 0.25 TON storage float — sweep never goes below

// ---------------- op codes ----------------
// TEP-74 / TEP-89 (standard; 0x7362d09c/0x0f8a7ea5/0xd53276db provati su mainnet in F0)
const OP_JETTON_TRANSFER = 0x0f8a7ea5;
const OP_JETTON_NOTIFY   = 0x7362d09c;
const OP_EXCESSES        = 0xd53276db;
const OP_PROVIDE_WALLET  = 0x2c76b973;
const OP_TAKE_WALLET     = 0xd1735400;
// venue (Ston.fi v2 0x6664de2a PINNATO da specimen mainnet B1; pTON 0x01f3835d visto in trace;
// DeDust: layout pubblico, verifica byte in F2 — isolati QUI per design)
const OP_STON_SWAP        = 0x6664de2a;
const OP_PTON_TRANSFER    = 0x01f3835d;
const OP_DEDUST_NATIVE    = 0xea06185d;
const OP_DEDUST_JETTON    = 0xe3a0d482;
// marker nostri dentro i payload venue (fulfill/reject → tornano nelle notification/settle)
const OP_SETTLE_MARK = 0x4c53c001;
const OP_REFUND_MARK = 0x4c53c002;
// ordini/governance nostri (prefisso 0x4c53 = "LS")
const OP_ORDER_TON = 0x4c531001;
const OP_ORDER_JET = 0x4c531002;
const OP_REFUSE_NOTE = 0x4c53ee01;
const OP_GOV_ACK     = 0x4c53ee00;

// venue kinds (come si parla con la venue di una gamba)
const VK_STON_JETTON   = 1;  // TEP-74 transfer al router Ston.fi con ston_swap forward
const VK_STON_PTON     = 2;  // TON al pTON-wallet del router Ston.fi (lato TON in ingresso)
const VK_DEDUST_NATIVE = 3;  // TON al native vault DeDust
const VK_DEDUST_JETTON = 4;  // TEP-74 transfer al jetton vault DeDust

// order states
const ST_AWAIT = 1;       // fondi qui, wallet-discovery in corso (reclaimabile dopo TTL)
const ST_SENT1 = 2;       // leg1 inoltrata alla venue
const ST_SENT2 = 3;       // leg2 inoltrata (two-leg)
const ST_DELIVERING = 4;  // out jetton in consegna (chiuso dall'excesses di conferma)

// purposes dentro query_id: qid = (orderId << 3) | purpose
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

// ---------------- error codes (specchio dei require del .sol) ----------------
const ERR_PAUSED = 601;            // "paused"
const ERR_TARGET = 602;            // "target" non whitelistato
const ERR_AMOUNT = 603;            // "amount"
const ERR_SAME_TOKEN = 604;        // "same token"
const ERR_MIN_OUT = 605;           // "minOut" == 0
const ERR_TARGET_TOKEN = 606;      // "target token" (venue coincide con un token della rotta)
const ERR_FEE_SIDE = 607;          // "fee side not solid"
const ERR_NOT_OWNER = 608;         // "not owner"
const ERR_RENOUNCED = 609;         // "renounced"
const ERR_TIMELOCK = 610;          // "timelock"
const ERR_BAD_TARGET = 611;        // "bad target" (propose) / leg malformata (refuse)
const ERR_FEE_RANGE = 612;         // "fee range"
const ERR_ZERO_OWNER = 613;        // "zero owner" (n/a: address è sempre valido — parità numerica)
const ERR_NOT_PENDING_OWNER = 614; // "not pending owner"
const ERR_BAD_SOLID = 615;         // "bad solid"
const ERR_INTERMEDIATE = 616;      // "intermediate" non solido
const ERR_GAS = 617;               // budget gas sotto il pavimento
const ERR_ORDER_STATE = 618;
const ERR_TTL = 619;               // reclaim prima del TTL
const ERR_SWEEP_PENDING = 620;     // sweep toccherebbe fondi pendenti
const ERR_MID_MIN = 621;           // two-leg: midMin==0 (R-2 backstop — mai un floor mid degenere)
const ERR_ORDER_UNKNOWN = 622;
const ERR_NOTHING_TO_SWEEP = 623;

// ---------------- storage ----------------
struct GovMaps {
    allowed: map<address, bool>          // venue destinations whitelist (.sol allowed)
    pendingEta: map<address, uint32>     // venue proposal → earliest execute ts
    solids: map<address, bool>           // jetton master solidi (.sol isSolid; TON = codice)
    pendingSolidEta: map<address, uint32>
}

// NB: NESSUNA mappa inversa wallet→master, di proposito: sarebbe avvelenabile
// (un master ostile può "dichiarare" come suo un wallet altrui nella risposta
// TEP-89). Ogni verifica va IN AVANTI — walletOf[master ATTESO dall'ordine]
// == sender — che un estraneo non può avvelenare per costruzione.
struct RunMaps {
    walletOf: map<address, address>        // master → NOSTRO jetton-wallet (verificato TEP-89)
    orders: map<uint64, Cell<Order>>       // ordini vivi
    pendingJet: map<address, coins>        // master → atomi jetton A RIPOSO per ordini pendenti
}

struct Storage {
    owner: address
    pendingOwner: address?
    feeBps: uint16
    paused: bool
    renounced: bool
    seqno: uint64          // id ordine progressivo (0 riservato alla governance)
    pendingTon: coins      // TON totali (importi + float gas) tenuti per ordini pendenti
    gov: Cell<GovMaps>
    run: Cell<RunMaps>
}

fun Storage.load() {
    return Storage.fromCell(contract.getData());
}

fun Storage.save(self) {
    contract.setData(self.toCell());
}

// ---------------- ordini ----------------
struct LegSpec {
    kind: uint8            // VK_*
    venue: address         // destinazione whitelistata della gamba (router ston / pton wallet / vault)
    aux: address?          // ston: token_wallet1 · dedust: pool — hint di routing, MAI di sicurezza
}

struct OrderTokens {
    inMaster: address?     // null = TON in ingresso
    outMaster: address?    // null = TON in uscita
    midMaster: address?    // two-leg: jetton solido intermedio (null = mid TON)
}

struct OrderFunds {
    amountIn: coins
    minOut: coins          // minimo NETTO all'utente (il contratto deriva il venueMinOut)
    midMin: coins          // two-leg: hint client sul minimo della leg1 (mai indebolisce minOut)
    heldJet: coins         // atomi jetton a riposo per l'ordine (in-fase o consegna rimbalzata)
    feeHeld: coins         // fee già skimmata e TRATTENUTA (viaggia solo alla consegna)
    heldMaster: address?   // master degli atomi trattenuti (null = lato TON)
}

struct Order {
    user: address
    claimedWallet: address?   // wallet che ha notificato l'ingresso jetton (da verificare TEP-89)
    state: uint8
    twoLeg: bool
    feeOnInput: bool
    tonIn: bool
    tonOut: bool
    midIsTon: bool
    deliveryBounced: bool     // la consegna è rimbalzata: redelivery ammessa via reclaim post-TTL
    needMask: uint8           // discovery in sospeso: 1=in 2=out 4=mid
    createdAt: uint32
    feeBpsSnap: uint16        // L-1: fee CONGELATA alla creazione (la quota è quella quotata all'utente)
    nonce: uint64             // H-1/M-1: segreto per-ordine — settle/refund/excesses devono portarlo
    heldTon: coins            // TON fisicamente riservati all'ordine (importo se TON-in + gas)
    sentJet: coins            // atomi dell'ultima transfer jetton in volo (per i bounce)
    funds: Cell<OrderFunds>
    tokens: Cell<OrderTokens>
    leg1: Cell<LegSpec>
    leg2: Cell<LegSpec>?
}

// ---------------- messaggi in ingresso (protocollo nostro + standard) ----------------
struct (0x4c531001) TonOrder {
    queryId: uint64
    amountIn: coins
    feeOnInput: bool          // true = fee sul TON in ingresso (buy); false = out solido (sell)
    outMaster: address
    minOut: coins
    leg1: Cell<LegSpec>
}

struct (0x7362d09c) JettonNotify {
    queryId: uint64
    amount: coins
    sender: address                       // il proprietario del wallet (l'utente)
    forwardPayload: RemainingBitsAndRefs  // Either Cell ^Cell — parse manuale
}

// corpo del forward_payload di un ordine jetton (dopo l'op a 32 bit)
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
    nonce: uint64        // H-1: lega il settle all'ordine oltre l'orderId pubblico
}

struct (0x4c53c002) RefundMark {
    orderId: uint64
    nonce: uint64
}

// governance (specchio 1:1 delle funzioni del .sol)
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

// ---------------- messaggi in uscita ----------------
struct (0x0f8a7ea5) JettonTransferMsg {
    queryId: uint64
    amount: coins
    destination: address
    responseDestination: address
    customPayload: cell?
    forwardTonAmount: coins
    forwardPayload: cell?     // Either inline-vuoto (bit 0) / ref (bit 1) — identico a Maybe ^Cell
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

// Ston.fi v2 swap (layout PINNATO da specimen mainnet, probe-ton-fork2 B1-3).
// Il wire-format della venue è INLINE per contratto loro: il worst-case 1023 del
// compilatore presuppone addr_var/extern che nel NOSTRO build non esistono
// (receiver/refund = router addr_std 267 bit, refAddress = none 2 bit, coins reali
// ≤124): totale reale ~660 bit — la suite lo prova sul payload golden.
@overflow1023_policy("suppress")
struct StonSwapInner {
    minOut: coins
    receiver: address
    fwdGas: coins
    customPayload: cell?      // fulfill → torna nella notification di settle
    refundFwdGas: coins
    refundPayload: cell?      // reject → torna nella notification di refund
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

// DeDust (layout pubblico; byte-compat = gate F2)
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
    return mulDivFloor(amount, bps, 10000);   // floor division = parità .sol
}

// sell: il minimo LORDO G tale che G − fee(G) ≥ minOut (il client non può indebolirlo)
@pure
fun grossFloorFor(minOut: coins, bps: int): coins {
    return mulDivCeil(minOut, 10000, 10000 - bps);
}

@pure
fun qidOf(orderId: uint64, purpose: int): uint64 {
    return ((orderId << 3) | purpose) as uint64;
}

// query_id della CONSEGNA jetton: lega l'excesses di chiusura all'ordine.
// purpose (3 bit) | orderId (32 bit) | nonce (29 bit). Bound orderId ≤ 2^32
// (4.3 mld ordini — mai raggiungibile; oltre = re-deploy). L'excesses standard
// porta SOLO il query_id (nessun payload), quindi il nonce vive qui.
@pure
fun qidDeliver(orderId: uint64, nonce: uint64): uint64 {
    return ((((nonce & 0x1FFFFFFF) << 35) | ((orderId & 0xFFFFFFFF) << 3) | T_DELIVER)) as uint64;
}

// nonce per-ordine: hash(orderId · logicalTime · user) troncato a 64 bit. Non
// indovinabile senza osservare il payload venue on-chain (che su TON è arduo da
// anticipare prima del settle reale); accoppiato al pavimento per-ordine rende
// il settle-polvere forgiato impraticabile (H-1).
fun makeNonce(orderId: uint64, user: address): uint64 {
    return (beginCell().storeUint(orderId, 64).storeUint(blockchain.logicalTime(), 64)
        .storeAddress(user).endCell().hash() & 0xFFFFFFFFFFFFFFFF) as uint64;
}

fun markCell(op: uint32, orderId: uint64, nonce: uint64): cell {
    return beginCell().storeUint(op, 32).storeUint(orderId, 64).storeUint(nonce, 64).endCell();
}

// nota di rifiuto per un ordine TON-in: tutto il valore torna al mittente (mode 64)
fun refuseTon(dest: address, queryId: uint64, code: uint16) {
    createMessage({
        bounce: BounceMode.NoBounce,
        value: 0,
        dest: dest,
        body: RefuseNote { queryId: queryId, code: code }
    }).send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
}

// refund di jetton attraverso il condotto da cui sono arrivati (wallet mittente della notify):
// se il wallet era finto non muove nulla di reale — no-op simmetrico per costruzione
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

// invio TON esatto (mode 1: le fee di forward le paga il balance, coperte dal pad dell'ordine)
fun sendTonExact(dest: address, amount: coins) {
    createMessage({
        bounce: BounceMode.NoBounce,
        value: amount,
        dest: dest
    }).send(SEND_MODE_PAY_FEES_SEPARATELY);
}

// TEP-89: chiedi al master l'indirizzo del NOSTRO wallet (query_id = ordine+lato)
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

// payload ston_swap costruito DAL CONTRATTO (docs/47 §0: mai byte ciechi del client)
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

// inoltro di una gamba: il contratto COSTRUISCE il payload venue dall'ordine tipato.
// net = importo che parte · ride = TON attaccati al messaggio · legIdx: T_LEG1/T_LEG2
fun forwardLeg(leg: LegSpec, net: coins, ride: coins, venueMinOut: coins,
               orderId: uint64, nonce: uint64, legIdx: int, viaWallet: address?, user: address) {
    if (leg.kind == VK_STON_PTON) {
        // lato TON → pTON wallet del router Ston con ston_swap nel forward
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
    // gambe jetton: transfer TEP-74 dal NOSTRO wallet verso la venue whitelistata
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

// validazione forma/sicurezza di una gamba (guardie F1 + kind coerente col lato)
fun legRefuseCode(gov: GovMaps, leg: LegSpec, sideIsTon: bool,
                  tIn: address?, tOut: address?, tMid: address?): int {
    val isTonKind = (leg.kind == VK_STON_PTON) | (leg.kind == VK_DEDUST_NATIVE);
    val isJetKind = (leg.kind == VK_STON_JETTON) | (leg.kind == VK_DEDUST_JETTON);
    if (!isTonKind && !isJetKind) { return ERR_BAD_TARGET; }
    if (sideIsTon && !isTonKind)  { return ERR_BAD_TARGET; }
    if (!sideIsTon && !isJetKind) { return ERR_BAD_TARGET; }
    if (leg.aux == null) { return ERR_BAD_TARGET; }
    if (!gov.allowed.exists(leg.venue)) { return ERR_TARGET; }
    // F1: la venue non è mai uno dei token della rotta
    if (tIn != null && leg.venue == tIn)   { return ERR_TARGET_TOKEN; }
    if (tOut != null && leg.venue == tOut) { return ERR_TARGET_TOKEN; }
    if (tMid != null && leg.venue == tMid) { return ERR_TARGET_TOKEN; }
    return 0;
}

// ---------------- macchina a stati: creazione ordini ----------------

fun acceptOrForward(mutate st: Storage, mutate run: RunMaps, ord: Order, orderId: uint64) {
    // se tutte le identità wallet servite sono note → inoltra leg1, altrimenti attesa discovery
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
    // H-2: fee d'ingresso SOLO su single-leg (il two-leg prende la fee sul MID, mai sull'input)
    val inFee = (ord.feeOnInput && !ord.twoLeg) ? feeOf(f.amountIn, ord.feeBpsSnap) : (0 as coins);
    val net = f.amountIn - inFee;
    // venueMinOut derivato dal minOut utente (decisione 2): mai dal client
    var vMin: coins = 0;
    if (ord.twoLeg) {
        vMin = f.midMin;      // hint di routing della leg1 (la protezione vera è la leg2)
    } else if (ord.feeOnInput) {
        vMin = f.minOut;      // fee già presa in ingresso: l'out arriva integrale all'utente
    } else {
        vMin = grossFloorFor(f.minOut, ord.feeBpsSnap);
    }
    if (ord.tonIn) {
        // parte il netto + tutto il float gas tranne la riserva di settle
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
        // il netto lascia la custodia; l'eventuale fee d'ingresso resta a riposo
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

// ---------------- refund/consegna ----------------

// refund integrale di un ordine i cui fondi sono ANCORA qui (AWAIT / bounce discovery)
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

// consegna dell'out jetton + viaggio della fee NELLO STESSO PASSO (decisione 3)
fun deliverJetOut(mutate st: Storage, mutate run: RunMaps, mutate ord: Order,
                  orderId: uint64, outWallet: address, gross: coins) {
    val f = ord.funds.load();
    val tokens = ord.tokens.load();
    var userOut = gross;
    var outFee: coins = 0;
    if (!ord.twoLeg && !ord.feeOnInput) {
        outFee = feeOf(gross, ord.feeBpsSnap);   // L-1: fee CONGELATA alla creazione dell'ordine
        userOut = gross - outFee;
    }
    // 1) consegna all'utente — cavalca il valore della notification di settle (mode 64)
    createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        value: 0,
        dest: outWallet,
        body: JettonTransferMsg {
            queryId: qidDeliver(orderId, ord.nonce),
            amount: userOut,
            destination: ord.user,
            responseDestination: contract.getAddress(),   // l'excesses di ritorno chiude l'ordine
            customPayload: null,
            forwardTonAmount: 0,
            forwardPayload: null
        }
    }).send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
    // 2) fee: parte SOLO ora, mai prima
    if (outFee > 0) {
        // fee sull'out solido: seconda transfer dallo stesso wallet
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
            // fee TON trattenuta (TON-in buy / mid TON): viaggia esatta
            sendTonExact(FEE_WALLET, f.feeHeld);
            val spend = f.feeHeld + SEND_FEE_PAD;
            st.pendingTon -= spend > ord.heldTon ? ord.heldTon : spend;
            ord.heldTon = spend > ord.heldTon ? 0 : ord.heldTon - spend;
        } else {
            // fee jetton trattenuta (in solido / mid jetton): transfer dal wallet del master
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
    // stato: consegna in volo, chiusa dall'excesses (o TTL-cleanup / bounce→redelivery)
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

// consegna TON all'utente (out TON solido) + fee esatta al fee wallet.
// Se la fee era TRATTENUTA in jetton (in solido, es. USDT→TON con fee input),
// viaggia ORA via il wallet del master — mai fondi fee lasciati in custodia.
fun deliverTonOut(mutate st: Storage, mutate run: RunMaps, ord: Order,
                  orderId: uint64, gross: coins) {
    val f = ord.funds.load();
    var userOut = gross;
    var outFee: coins = 0;
    if (!ord.feeOnInput) {
        outFee = feeOf(gross, ord.feeBpsSnap);   // L-1: fee CONGELATA alla creazione dell'ordine
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
            extra = 0;   // il float residuo paga il viaggio della fee
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
        return;   // top-up semplice
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
            // guardia anti-vandalismo (decisione 6): il probe TEP-89 parte ORA;
            // se il target risponde take_wallet_address è un jetton master → auto-cancel
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
            // parità .sol: la pause NON è congelata dal renounce (safety over immutability)
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
            // chiunque; fondi SOLO al fee wallet; MAI sotto riserva storage + pendenze ordini
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
            // chiunque; vietata se il master ha fondi di ordini pendenti (decisione 5)
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

// ---------------- ordini: TON in ingresso ----------------

fun handleTonOrder(msg: TonOrder, sender: address, msgValue: coins) {
    var st = Storage.load();
    if (st.paused) { refuseTon(sender, msg.queryId, ERR_PAUSED); return; }
    if (msg.amountIn == 0) { refuseTon(sender, msg.queryId, ERR_AMOUNT); return; }
    if (msg.minOut == 0) { refuseTon(sender, msg.queryId, ERR_MIN_OUT); return; }
    if (msgValue < msg.amountIn + GAS_FLOOR_SINGLE) { refuseTon(sender, msg.queryId, ERR_GAS); return; }
    // lato fee solido: TON è solido per CODICE; se la fee va sull'out, l'out dev'essere solido
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

// ---------------- ordini/settle/refund: notification jetton ----------------

fun handleNotify(msg: JettonNotify, senderWallet: address, msgValue: coins) {
    // parse del forward payload (Either Cell ^Cell)
    var p: slice = msg.forwardPayload;
    if (p.isEmpty()) { return; }   // transfer semplice senza payload: donazione → surplus
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
    // op sconosciuto: jetton arrivati senza ordine → surplus (sweepabile), mai throw:
    // un throw qui perderebbe solo la notification, i jetton sono già accreditati
}

fun handleJetOrder(msg: JettonNotify, senderWallet: address, msgValue: coins, mutate p: slice) {
    var st = Storage.load();
    // parse TOLLERANTE: bit di coda dopo i campi non buttano MAI via un ordine con fondi
    val body = JetOrderBody.fromSlice(p, { assertEndAfterReading: false });
    val tokens = body.tokens.load();
    val user = msg.sender;

    // identità del condotto: se il master dichiarato ha già un wallet verificato DIVERSO
    // dal mittente, la notification è CONTRAFFATTA → no-op (nessun fondo reale esiste)
    var run = st.run.load();
    if (tokens.inMaster == null) { refundJetViaPipe(senderWallet, msg.amount, user, 0); return; }
    val inMaster = tokens.inMaster!;
    val cachedW = run.walletOf.get(inMaster);
    val verified = cachedW.isFound && cachedW.loadValue() == senderWallet;
    if (cachedW.isFound && !verified) { return; }

    // guardie (specchio .sol — ogni violazione = refund attraverso il condotto d'arrivo)
    if (st.paused) { refundJetViaPipe(senderWallet, msg.amount, user, 0); return; }
    if (msg.amount == 0) { refundJetViaPipe(senderWallet, msg.amount, user, 0); return; }
    if (body.minOut == 0) { refundJetViaPipe(senderWallet, msg.amount, user, 0); return; }
    val floor = body.twoLeg ? GAS_FLOOR_TWOLEG : GAS_FLOOR_SINGLE;
    if (msgValue < floor) { refundJetViaPipe(senderWallet, msg.amount, user, 0); return; }

    val gov = st.gov.load();
    var refuse = 0;
    if (body.twoLeg) {
        // two-leg: out jetton, mid TON o jetton SOLIDO registrato (parità #4).
        // H-2: la fee del two-leg è SEMPRE sul mid ricevuto → feeOnInput è contraddittorio, rifiutato.
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
        // R-2 backstop (audit round-2): il floor anti-forge del mid = midMin; midMin==0 lo
        // annulla → rifiuto del caso degenere. Il floor STRETTO resta responsabilità dell'F5.
        if (refuse == 0 && body.midMin == 0) { refuse = ERR_MID_MIN; }
    } else {
        // single-leg: lato fee solido obbligatorio (meme→meme single RIFIUTATO → two-leg)
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

    // accettazione: fondi in custodia, discovery per ogni identità mancante
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

// settle jetton: l'out (o il mid) è arrivato a un NOSTRO wallet. La verifica è
// IN AVANTI: il sender deve essere ESATTAMENTE walletOf[master atteso in questa
// fase dell'ordine] — mai lookup inverso (avvelenabile da un master ostile).
fun handleJetSettle(orderId: uint64, nonce: uint64, senderWallet: address, gross: coins, msgValue: coins) {
    var st = Storage.load();
    var run = st.run.load();
    val oc = run.orders.get(orderId);
    if (!oc.isFound) { return; }       // ordine chiuso/ignoto (doppio settle) → surplus
    var ord = oc.loadValue().load();
    if (ord.nonce != nonce) { return; }   // H-1: il marker DEVE portare il nonce dell'ordine
    val tokens = ord.tokens.load();
    val f = ord.funds.load();

    if (ord.state == ST_SENT1 && ord.twoLeg && !ord.midIsTon && tokens.midMaster != null) {
        val expect = run.walletOf.get(tokens.midMaster!);
        if (!expect.isFound || expect.loadValue() != senderWallet) { return; }
        if (gross < f.midMin) { return; }   // H-1: pavimento del mid (mai un mid-polvere)
        // mid solido arrivato: fee sul RICEVUTO, leg2 sul netto (parità #4)
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
    // H-1: pavimento per-ordine sull'OUT — un settle sotto il minimo garantito è forgiato/anomalo.
    // Un settle legittimo porta SEMPRE gross ≥ venueMinOut (la venue whitelistata l'ha onorato).
    val outFloor = (ord.feeOnInput || ord.twoLeg) ? f.minOut : grossFloorFor(f.minOut, ord.feeBpsSnap);
    if (gross < outFloor) { return; }
    deliverJetOut(mutate st, mutate run, mutate ord, orderId, senderWallet, gross);
    st.run = run.toCell();
    st.save();
}

// fee sul mid ricevuto + inoltro leg2 col netto (mid jetton o TON)
fun settleMidAndLeg2(mutate st: Storage, mutate run: RunMaps, mutate ord: Order,
                     orderId: uint64, midGross: coins, midTon: bool) {
    val f = ord.funds.load();
    val tokens = ord.tokens.load();
    val midFee = feeOf(midGross, ord.feeBpsSnap);   // L-1: fee CONGELATA
    val midNet = midGross - midFee;
    val leg2 = ord.leg2!.load();
    if (midTon) {
        // il valore del settle è già sul balance: il netto riparte + il float oltre la riserva
        val ride = midNet + (ord.heldTon - GAS_FWD_SETTLE);
        forwardLeg(leg2, midNet, ride, f.minOut, orderId, ord.nonce, T_LEG2, null, ord.user);
        st.pendingTon += midGross;             // il gross è entrato in custodia...
        st.pendingTon -= ride;                 // ...e il netto+gas riparte subito
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

// refund jetton dalla venue (leg1 respinta: tornano i jetton d'ingresso ·
// leg2 respinta: torna il mid netto — si restituisce NETTO+FEE, decisione 3)
fun handleJetRefund(orderId: uint64, nonce: uint64, senderWallet: address, amount: coins) {
    var st = Storage.load();
    var run = st.run.load();
    val oc = run.orders.get(orderId);
    if (!oc.isFound) { return; }
    val ord = oc.loadValue().load();
    if (ord.nonce != nonce) { return; }   // H-1: refund forgiato senza il nonce dell'ordine → ignorato
    val f = ord.funds.load();
    val tokens = ord.tokens.load();

    // verifica IN AVANTI del condotto (mai lookup inverso)
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
        // leg1 fallita: refund INPUT INTEGRALE (netto rimborsato + eventuale fee d'ingresso)
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
        // leg2 fallita: refund del mid NETTO + FEE trattenuta
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

// ---------------- settle/refund TON (payout nativo dalla venue whitelistata) ----------------

fun handleTonSettle(orderId: uint64, nonce: uint64, sender: address, value: coins) {
    var st = Storage.load();
    val gov = st.gov.load();
    if (!gov.allowed.exists(sender)) { return; }   // TON-settle SOLO da infrastruttura whitelistata
    var run = st.run.load();
    val oc = run.orders.get(orderId);
    if (!oc.isFound) { return; }
    var ord = oc.loadValue().load();
    if (ord.nonce != nonce) { return; }   // H-1: nonce dell'ordine obbligatorio
    val f = ord.funds.load();
    if (ord.state == ST_SENT1 && ord.twoLeg && ord.midIsTon) {
        if (value < f.midMin) { return; }   // H-1: pavimento del mid
        settleMidAndLeg2(mutate st, mutate run, mutate ord, orderId, value, true);
        st.run = run.toCell();
        st.save();
        return;
    }
    val isOut = ((ord.state == ST_SENT1 && !ord.twoLeg) || ord.state == ST_SENT2) && ord.tonOut;
    if (!isOut) { return; }
    val outFloor = ord.feeOnInput ? f.minOut : grossFloorFor(f.minOut, ord.feeBpsSnap);
    if (value < outFloor) { return; }   // H-1: pavimento per-ordine sull'OUT TON
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
    if (ord.nonce != nonce) { return; }   // H-1: nonce dell'ordine obbligatorio
    val f = ord.funds.load();
    if (ord.state == ST_SENT1 && ord.tonIn) {
        // leg1 TON fallita: torna il valore + il float residuo (fee trattenuta inclusa)
        val back = value + ord.heldTon;
        sendTonExact(ord.user, back > SEND_FEE_PAD ? back - SEND_FEE_PAD : 0);
        st.pendingTon -= ord.heldTon;
        run.orders.delete(orderId);
        st.run = run.toCell();
        st.save();
        return;
    }
    if (ord.state == ST_SENT2 && ord.midIsTon) {
        // leg2 fallita con mid TON: refund mid netto (tornato) + fee TON trattenuta
        val back = value + ord.heldTon;
        sendTonExact(ord.user, back > SEND_FEE_PAD ? back - SEND_FEE_PAD : 0);
        st.pendingTon -= ord.heldTon;
        run.orders.delete(orderId);
        st.run = run.toCell();
        st.save();
        return;
    }
}

// ---------------- TEP-89: risposta del master ----------------

fun handleTakeWallet(msg: TakeWalletAddress, sender: address) {
    val purpose = (msg.queryId & 7) as int;
    val orderId = (msg.queryId >> 3) as uint64;
    var st = Storage.load();
    if (purpose == Q_GOV) {
        // il target proposto ha risposto da JETTON MASTER → auto-cancel (decisione 6)
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
    // la risposta vale SOLO se arriva dal master che abbiamo interrogato per quel lato
    var expected: address? = null;
    if (purpose == Q_IN)  { expected = tokens.inMaster; }
    if (purpose == Q_OUT) { expected = tokens.outMaster; }
    if (purpose == Q_MID) { expected = tokens.midMaster; }
    if (expected == null) { return; }
    if (sender != expected!) { return; }

    if (purpose == Q_IN && ord.claimedWallet != null && msg.walletAddress != ord.claimedWallet!) {
        // SPOOF provato: il wallet vero del master dichiarato NON è chi ha notificato.
        // Nessun fondo reale esiste per quest'ordine → drop (l'attach resta surplus).
        val f = ord.funds.load();
        subPendingJet(mutate run, tokens.inMaster!, f.heldJet);
        st.pendingTon -= ord.heldTon;
        run.orders.delete(orderId);
        st.run = run.toCell();
        st.save();
        return;
    }
    run.walletOf.set(sender, msg.walletAddress);          // cache SOLO in avanti: master → wallet
    val bit = purpose == Q_IN ? 1 : (purpose == Q_OUT ? 2 : 4);
    ord.needMask = (ord.needMask & (~bit)) as uint8;
    if (ord.needMask == 0) {
        forwardLeg1(mutate st, mutate run, mutate ord, orderId);
    }
    run.orders.set(orderId, ord.toCell());
    st.run = run.toCell();
    st.save();
}

// ---------------- excesses: conferma di consegna ----------------

fun handleExcesses(msg: Excesses) {
    val purpose = (msg.queryId & 7) as int;
    if (purpose != T_DELIVER) { return; }   // ogni altro excesses → surplus
    val orderId = ((msg.queryId >> 3) & 0xFFFFFFFF) as uint64;
    val nonce29 = ((msg.queryId >> 35) & 0x1FFFFFFF) as int;
    var st = Storage.load();
    var run = st.run.load();
    val oc = run.orders.get(orderId);
    if (!oc.isFound) { return; }
    val ord = oc.loadValue().load();
    // M-1 (audit): l'excesses della consegna è emesso dal wallet del DESTINATARIO (l'utente),
    // NON dal nostro out-wallet — un check sul sender rifiuterebbe la conferma LEGITTIMA (il
    // bug della "fix" §11.1). La SOLA autenticazione corretta è il NONCE: l'utente riecheggia
    // il query_id (= qidDeliver, con 29 bit di nonce) della NOSTRA transfer di consegna. Un
    // excesses forgiato con nonce sbagliato non chiude. Finestra residua (osservatore che
    // corre il nonce on-chain prima del settle reale + bounce) dichiarata in docs/48 §12 e
    // limitata: un excesses legittimo = consegna riuscita = nessun bounce in arrivo.
    if (((ord.nonce & 0x1FFFFFFF) as int) != nonce29) { return; }
    if (ord.state != ST_DELIVERING) { return; }
    if (ord.deliveryBounced) { return; }   // riconsegna PENDENTE: non chiudere
    // consegna confermata: chiudi e restituisci l'eventuale float residuo all'utente
    if (ord.heldTon > SEND_FEE_PAD) { sendTonExact(ord.user, ord.heldTon - SEND_FEE_PAD); }
    st.pendingTon -= ord.heldTon;
    run.orders.delete(orderId);
    st.run = run.toCell();
    st.save();
}

// ---------------- reclaim TTL (decisione 4) ----------------

fun handleReclaim(orderId: uint64, msgValue: coins) {
    var st = Storage.load();
    var run = st.run.load();
    val oc = run.orders.get(orderId);
    assert (oc.isFound) throw ERR_ORDER_UNKNOWN;
    var ord = oc.loadValue().load();
    assert (blockchain.now() >= ord.createdAt + ORDER_TTL) throw ERR_TTL;
    if (ord.state == ST_AWAIT) {
        // fondi ancora QUI (discovery appesa): refund integrale, SOLO all'utente dell'ordine
        refundHeld(mutate st, mutate run, ord, orderId);
        st.run = run.toCell();
        st.save();
        return;
    }
    if (ord.state == ST_DELIVERING) {
        val tokens = ord.tokens.load();
        if (ord.deliveryBounced && ord.sentJet > 0 && tokens.outMaster != null) {
            // la consegna era rimbalzata: i jetton sono ANCORA nel nostro wallet → riconsegna
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
            // L-2 (audit): consegna NON (ancora) rimbalzata. NON cancellare — un bounce tardivo
            // potrebbe ancora arrivare e la riconsegna andrebbe persa. Restituiamo SOLO il float
            // residuo (una volta, azzerando heldTon) e LASCIAMO l'ordine in DELIVERING: se poi
            // rimbalza → deliveryBounced → un reclaim successivo riconsegna; se arriva l'excesses
            // → chiude (heldTon=0). Costo: uno slot che resta finché non si risolve (float liberato,
            // nessun fondo utente bloccato). Reclaim ripetuti sono idempotenti (heldTon già 0).
            if (ord.heldTon > SEND_FEE_PAD) { sendTonExact(ord.user, ord.heldTon - SEND_FEE_PAD); }
            st.pendingTon -= ord.heldTon;
            ord.heldTon = 0;
            run.orders.set(orderId, ord.toCell());
        }
        st.run = run.toCell();
        st.save();
        return;
    }
    // SENT1/SENT2: fondi alla venue whitelistata — chiude la fisica della venue (mai doppio pagamento)
    throw ERR_ORDER_STATE;
}

// ---------------- bounce dei nostri messaggi ----------------

fun onBouncedMessage(in: InMessageBounced) {
    var b = in.bouncedBody;
    b.skipBouncedPrefix();
    if (b.remainingBitsCount() < 96) { return; }
    val op = b.loadUint(32);
    val qid = b.loadUint(64) as uint64;
    val purpose = (qid & 7) as int;
    val orderId = (qid >> 3) as uint64;

    if (op == OP_PROVIDE_WALLET) {
        if (purpose == Q_GOV) { return; }   // probe anti-token rimbalzato: il target NON è un token
        // il master interrogato non è un contratto vivo: ordine invalido → refund integrale
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
        // gamba TON rimbalzata: il valore è tornato sul balance → refund all'utente
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
            val back = in.valueCoins + ord.heldTon;   // heldTon include la fee mid trattenuta
            sendTonExact(ord.user, back > SEND_FEE_PAD ? back - SEND_FEE_PAD : 0);
            st.pendingTon -= ord.heldTon;
            run.orders.delete(orderId);
            st.run = run.toCell();
            st.save();
        }
        return;
    }
    if (op == OP_JETTON_TRANSFER) {
        // la consegna usa qidDeliver (orderId 32 bit + nonce nei bit alti): decodifica mirata
        val oid = (purpose == T_DELIVER) ? (((qid >> 3) & 0xFFFFFFFF) as uint64) : orderId;
        var st = Storage.load();
        var run = st.run.load();
        val oc = run.orders.get(oid);
        if (!oc.isFound) { return; }
        var ord = oc.loadValue().load();
        val f = ord.funds.load();
        val tokens = ord.tokens.load();
        if (purpose == T_LEG1 && ord.state == ST_SENT1 && !ord.tonIn) {
            // il NOSTRO wallet ha respinto la leg1: i jetton non sono mai partiti → refund
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
            // consegna rimbalzata: i jetton sono rientrati nel wallet → redelivery via reclaim
            ord.deliveryBounced = true;
            if (tokens.outMaster != null) { addPendingJet(mutate run, tokens.outMaster!, ord.sentJet); }
            run.orders.set(oid, ord.toCell());
        }
        // T_FEE / T_REFUND / T_SWEEP rimbalzate: i fondi restano qui → surplus (dichiarato)
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
    // (state, needMask, heldTon, sentJet, createdAt) — 0 tutto se l'ordine non esiste
    val r = Storage.load().run.load().orders.get(orderId);
    if (!r.isFound) { return (0, 0, 0, 0, 0); }
    val o = r.loadValue().load();
    return (o.state, o.needMask, o.heldTon, o.sentJet, o.createdAt);
}

get fun parityVersion(): int {
    return 1;   // ListedRouterTon v1 — fork fedele del ListedRouter EVM (docs/47)
}
