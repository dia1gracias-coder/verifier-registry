// Genesis Collection (TEP-62 style) — storage schema, opcodes, message layouts,
// and getter stubs only. Mint/admin business logic is NOT implemented yet: see
// the handle*() stubs called from onInternalMessage below, filled in a later step.

const MAX_SUPPLY: int = 10000;

// The treasury is where all mint proceeds must ultimately go. It is a compile-time
// constant, NOT a Storage field, and no function in this contract ever writes to it.
// This is deliberate: the payout destination must be permanently immutable and
// impossible to redirect post-deployment — there is no admin function, upgrade path,
// or proxy anywhere in this contract that could ever touch it.
// PLACEHOLDER: replace with the real treasury multisig address before deployment.
const TREASURY_ADDRESS: address = address("0QBBtpl3o5WYGFvGRR9g-4UXeSaL7K2VfBGHqglnJ0qfqcXk");

// ---- Opcodes ----
// Note: Tolk identifiers can't contain `::`, so these use OP_* naming instead of
// the `op::name` convention from FunC. Values must stay in sync with the opcode
// literal in each message struct's header below — confirmed by compiler test that
// `struct (OP_MINT) MintMessage` is rejected ("expected opcode `0x...` or `0b...`,
// got `OP_MINT`"): that header position is grammar-level restricted to a literal,
// a named constant can never be used there, so the values must be kept in sync
// by hand.
const OP_MINT: int = 0x4d494e54;             // sender: anyone — submit signed quote + payment
const OP_PAUSE: int = 0x50415553;            // sender: admin only — halt new mints
const OP_UNPAUSE: int = 0x554e5053;          // sender: admin only — resume minting
const OP_ROTATE_SIGNER: int = 0x524f5453;    // sender: admin only — update signerPubKey
const OP_UPDATE_CONTENT: int = 0x55504354;   // sender: admin only — swap baseContent (delayed reveal)
const OP_INITIALIZE: int = 0x494e4954;       // sender: this collection only — sent collection -> item, first message only

// Placeholder — covers the item's StateInit rent + gas; we'll revisit the exact
// figure once full payment/treasury logic exists in a later step.
const ITEM_DEPLOY_VALUE: coins = ton("0.03");

// Operating reserve this contract always keeps for its own storage rent and to
// fund future item-deploy sends (which pay their forward fee out of this
// contract's own balance, not out of the incoming message's value — see the
// reserve comment in handleMint's treasury forward for why this exists).
const MIN_COLLECTION_BALANCE: coins = ton("0.05");

// ---- Error codes ----
const ERROR_NOT_ADMIN: int = 401;
const ERROR_PAUSED: int = 402;
const ERROR_QUOTE_EXPIRED: int = 403;
const ERROR_BAD_SIGNATURE: int = 404;
const ERROR_NONCE_USED: int = 405;
const ERROR_SERIAL_MINTED: int = 406;
const ERROR_SUPPLY_EXCEEDED: int = 407;
const ERROR_INSUFFICIENT_PAYMENT: int = 408;
const ERROR_UNKNOWN_OP: int = 409;
const ERROR_SENDER_MISMATCH: int = 410;

// ---- Storage ----
struct Storage {
    signerPubKey: uint256    // quote-signing key, rotatable by admin
    adminAddress: address    // multisig wallet address; controls pause/rotate/reveal
    itemCode: cell           // compiled GenesisItemTesting code, used for StateInit at mint time
    totalMinted: uint16      // running counter, checked against MAX_SUPPLY
    mintedSerials: map<uint16, bool>     // uint16 serial -> bool, double-mint guard
    usedNonces: map<uint64, bool>        // uint64 nonce -> bool, replay guard
    paused: bool
    baseContent: cell        // TEP-64 base content; swappable by admin for delayed reveal
}

fun Storage.load(): Storage {
    return Storage.fromCell(contract.getData());
}

fun Storage.save(self) {
    contract.setData(self.toCell());
}

// ---- Item address computation (for get_nft_address_by_index) ----
//
// Must mirror genesis_item_testing.tolk's `StorageInit` shape EXACTLY (same
// field order, same widths, no refs), so the StateInit hash computed here
// matches what the item contract will actually be deployed with once mint logic
// is implemented. Deliberately duplicated rather than imported: that file
// defines its own onInternalMessage, and importing it here would collide with
// this contract's onInternalMessage (Tolk has one global function namespace per
// compiled binary — see also genesis_item_testing.tolk's comment on the same
// address-before-storage constraint). Verified via a sandbox test that the
// address this produces matches @ton/core's own contractAddress() computed from
// the same (code, data) pair.
struct ItemStorageInit {
    index: uint16
    collectionAddress: address
}

// Single source of truth for an item's initial data cell. Both address
// computation (calcItemAddress, below) and the actual deploy (handleMint's item
// deployment loop) call this same function, so they can never construct
// different data shapes and diverge.
fun buildItemInitData(index: int): cell {
    val initData: ItemStorageInit = {
        index: index as uint16,
        collectionAddress: contract.getAddress(),
    };
    return initData.toCell();
}

fun calcItemAddress(index: int, itemCode: cell): address {
    val deployed: AutoDeployAddress = {
        stateInit: {
            code: itemCode,
            data: buildItemInitData(index),
        },
    };
    return deployed.calculateAddress();
}

// ---- Message layouts ----

struct MintQuote {
    wallet: address
    quantity: uint16
    serials: cell        // packed list of uint16, length == quantity
    usdTotal: uint64
    gramAmount: coins
    expiry: uint32
    nonce: uint64
}

struct (0x4d494e54) MintMessage {
    queryId: uint64
    quote: Cell<MintQuote>   // ^MintQuote, referenced cell, NOT inlined
    signature: bits512
}

struct (0x50415553) PauseMessage {
    queryId: uint64
}

struct (0x554e5053) UnpauseMessage {
    queryId: uint64
}

struct (0x524f5453) RotateSignerMessage {
    queryId: uint64
    newPubKey: uint256
}

struct (0x55504354) UpdateContentMessage {
    queryId: uint64
    newContent: cell
}

// Sent collection -> item, first message only (deploy + init in one shot, sent
// together with the item's StateInit). Necessarily duplicated in
// genesis_item_testing.tolk rather than shared/imported — same single-namespace
// reason as ItemStorageInit/StorageInit above.
struct (0x494e4954) InitializeMessage {
    queryId: uint64
    ownerAddress: address
    individualContent: cell
}

type AllowedMessage =
    | MintMessage
    | PauseMessage
    | UnpauseMessage
    | RotateSignerMessage
    | UpdateContentMessage;

// ---- Handler stubs (business logic added in a later step) ----

// `senderAddress` is passed in explicitly rather than the whole `InMessage`:
// `in` (InMessage) is a compiler-magic object whose fields map to specific TVM
// instructions, and it's rejected outright if you try to pass it as an object
// to another function ("using `in` as an object is prohibited") — confirmed by
// compiler error when this was first attempted for the admin handlers.
fun handleMint(mutate storage: Storage, msg: MintMessage, senderAddress: address, msgValue: coins): void {
    assert (!storage.paused) throw ERROR_PAUSED;

    // msg.quote is `Cell<MintQuote>` — a referenced cell, not inlined. `.load()`
    // parses it into a typed MintQuote; `.hash()` (available on Cell<T> the same
    // as on a plain cell) gives the 32-byte representation hash that was signed.
    val quote = msg.quote.load();

    // Sender must be the wallet the quote was issued for. Checked right after
    // loading the quote and before the (relatively expensive) signature check,
    // so a mismatched sender is rejected cheaply — checking after signature
    // verification would be equally correct (the quote is only trustworthy once
    // signed either way), this is just cheaper for the common-case reject.
    assert (senderAddress == quote.wallet) throw ERROR_SENDER_MISMATCH;

    // `signature` is `bits512` (a fixed-width slice); isSignatureValid wants a
    // plain `slice`, so an explicit `as slice` cast is required here — bits512
    // doesn't implicitly widen to slice the way uintN widens to int.
    val quoteHash = msg.quote.hash();
    assert (isSignatureValid(quoteHash, msg.signature as slice, storage.signerPubKey)) throw ERROR_BAD_SIGNATURE;

    assert (quote.expiry >= blockchain.now()) throw ERROR_QUOTE_EXPIRED;

    // addIfNotExists does the "already used?" check and the "mark used" write in
    // one map operation; it returns false if the key was already present.
    val nonceWasUnused = storage.usedNonces.addIfNotExists(quote.nonce, true);
    assert (nonceWasUnused) throw ERROR_NONCE_USED;

    // Supply check before touching mintedSerials at all. Strictly, any throw
    // anywhere in this function is already atomic per-transaction — nothing is
    // persisted until onInternalMessage's single storage.save() after this
    // function returns, so a throw here vs. mid-loop would leave identical
    // on-chain state either way. Checking supply first just avoids doing
    // mintedSerials writes for a mint that's going to be rejected regardless.
    assert (storage.totalMinted + quote.quantity <= MAX_SUPPLY) throw ERROR_SUPPLY_EXCEEDED;

    // Attached value must cover both the quoted price (forwarded to the
    // treasury below) and this mint's item-deploy costs. Still a pre-flight
    // guard — checked before the serial-minting loop, same position as before —
    // not something dependent on the loop's results.
    assert (msgValue >= quote.gramAmount + (quote.quantity * ITEM_DEPLOY_VALUE)) throw ERROR_INSUFFICIENT_PAYMENT;

    // quote.serials packs `quantity` uint16 serial numbers back-to-back in a
    // single cell — no length prefix, msg's own `quantity` field is the count.
    var serialsSlice = quote.serials.beginParse();
    repeat (quote.quantity) {
        val serial = serialsSlice.loadUint(16) as uint16;
        val serialWasUnminted = storage.mintedSerials.addIfNotExists(serial, true);
        assert (serialWasUnminted) throw ERROR_SERIAL_MINTED;

        // individualContent is always empty at mint time — metadata resolves
        // off-chain purely from baseContent + index, nothing per-item needed.
        // `dest` is the item's not-yet-deployed StateInit (via buildItemInitData,
        // the same function calcItemAddress uses), so the compiler derives the
        // destination address automatically and attaches the StateInit to
        // actually deploy it — the item doesn't need to exist beforehand.
        val deployDest: AutoDeployAddress = {
            stateInit: {
                code: storage.itemCode,
                data: buildItemInitData(serial),
            },
        };
        val deployMsg = createMessage({
            bounce: BounceMode.Only256BitsOfBody,
            dest: deployDest,
            value: ITEM_DEPLOY_VALUE,
            body: InitializeMessage {
                queryId: msg.queryId,
                ownerAddress: quote.wallet,
                individualContent: beginCell().endCell(),
            },
        });
        deployMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
    }

    storage.totalMinted += quote.quantity;

    // Forward whatever's left to the treasury. Rather than computing an exact
    // leftover amount by hand (fragile: would need to account for this
    // transaction's own gas, which isn't known precisely in advance), reserve
    // this contract's own operating balance and sweep the rest — Tolk/TVM's
    // idiom for "carry remaining value" without hand-computed arithmetic.
    //
    // Note this uses reserveGramsOnBalance(...) + SEND_MODE_CARRY_ALL_BALANCE
    // (mode 128, "remaining balance of the contract"), NOT bare
    // SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE (mode 64, "remaining value of
    // the inbound message") on its own. Verified empirically (sandbox test,
    // repeated mints against the same contract instance) that mode 64 alone
    // sweeps the contract down to near-zero balance on every call — not just
    // this message's incremental value — which then starves the very next
    // mint's item-deploy send (that send's forward fee is paid from this
    // contract's own balance, separately from the incoming message value, so a
    // near-zero balance makes it fail with "not enough Toncoin"). Reserving
    // MIN_COLLECTION_BALANCE first and sweeping with mode 128 is the standard,
    // correctly-composing pattern for "forward the remainder, keep a reserve"
    // and was verified stable across 5 consecutive mints in the same test.
    //
    // This is intentional, not a rounding bug: the treasury receives whatever
    // is actually left after item-deploy costs, this transaction's own gas, and
    // the reserve, which may be slightly more or less than quote.gramAmount
    // exactly — the ERROR_INSUFFICIENT_PAYMENT check above only guarantees a
    // *floor* on msgValue, not an exact accounting of it.
    reserveGramsOnBalance(MIN_COLLECTION_BALANCE, RESERVE_MODE_EXACT_AMOUNT);
    val treasuryMsg = createMessage({
        bounce: BounceMode.NoBounce,
        dest: TREASURY_ADDRESS,
        value: 0,
    });
    treasuryMsg.send(SEND_MODE_CARRY_ALL_BALANCE);
}

fun handlePause(mutate storage: Storage, msg: PauseMessage): void {
    storage.paused = true;
}

fun handleUnpause(mutate storage: Storage, msg: UnpauseMessage): void {
    storage.paused = false;
}

fun handleRotateSigner(mutate storage: Storage, msg: RotateSignerMessage): void {
    storage.signerPubKey = msg.newPubKey;
}

fun handleUpdateContent(mutate storage: Storage, msg: UpdateContentMessage): void {
    storage.baseContent = msg.newContent;
}

fun onInternalMessage(in: InMessage) {
    // No bounced-message guard needed here: Tolk's compiler-generated entrypoint
    // routes bounced messages to a separate onBouncedMessage(in: InMessageBounced)
    // handler (or silently drops them, since this contract defines none) before
    // onInternalMessage is ever invoked. Verified empirically — sending an
    // already-bounced message to a contract whose onInternalMessage
    // unconditionally throws produced exitCode 0 with negligible gas, i.e. the
    // body never ran. InMessage also exposes no bounced field/method to check.
    var storage = lazy Storage.load();
    val msg = lazy AllowedMessage.fromSlice(in.body);

    match (msg) {
        MintMessage => {
            handleMint(mutate storage, msg, in.senderAddress, in.valueCoins);
        }
        PauseMessage => {
            assert (in.senderAddress == storage.adminAddress) throw ERROR_NOT_ADMIN;
            handlePause(mutate storage, msg);
        }
        UnpauseMessage => {
            assert (in.senderAddress == storage.adminAddress) throw ERROR_NOT_ADMIN;
            handleUnpause(mutate storage, msg);
        }
        RotateSignerMessage => {
            assert (in.senderAddress == storage.adminAddress) throw ERROR_NOT_ADMIN;
            handleRotateSigner(mutate storage, msg);
        }
        UpdateContentMessage => {
            assert (in.senderAddress == storage.adminAddress) throw ERROR_NOT_ADMIN;
            handleUpdateContent(mutate storage, msg);
        }
        else => {
            // ignore empty messages, "wrong opcode" for others
            assert (in.body.isEmpty()) throw ERROR_UNKNOWN_OP;
        }
    }

    // Single persistence point: every branch above (including the stub handlers)
    // mutates `storage` in place if at all, and we save exactly once here.
    storage.save();
}

// ---- Getters ----

get fun getMintStatus(): (bool, int, int) {
    val storage = lazy Storage.load();
    return (storage.paused, storage.totalMinted, MAX_SUPPLY);
}

get fun getSignerPubKey(): int {
    val storage = lazy Storage.load();
    return storage.signerPubKey;
}

// TEP-62 standard get_collection_data: (nextItemIndex, collectionContent,
// ownerAddress). Named exactly `get_collection_data` (snake_case, not
// camelCase) since external tools resolve get-methods by literal name.
get fun get_collection_data(): (int, cell, address) {
    val storage = lazy Storage.load();
    return (storage.totalMinted, storage.baseContent, storage.adminAddress);
}

// TEP-62 standard get_nft_address_by_index. Named exactly
// `get_nft_address_by_index` for the same standards-compliance reason.
get fun get_nft_address_by_index(index: int): address {
    val storage = lazy Storage.load();
    return calcItemAddress(index, storage.itemCode);
}
