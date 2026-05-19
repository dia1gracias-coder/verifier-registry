// TONado privacy pool for native TON.
//
// Deposit-time protocol fee routes to a treasury address. The fee is
// uniform per pool (no per-user fingerprint). The withdraw handler does
// not depend on the fee config: SNARK boundary, nullifier write, payout,
// and refund logic are unchanged regardless of fee level. See
// TOKENOMICS.md for the design rationale.
//
// Storage carries a `revenue: Cell<RevenueConfig>` sub-ref with
// (treasuryAddress, protocolFeeBps). Initial state at deploy: treasury
// is BURN_ADDRESS and fee is 0; governance enables via
// AdminSetRevenueConfig.
//
// One pool per denomination per network. Accepts fixed-size deposits, emits
// commitments into an on-chain merkle tree (Poseidon over BLS12-381), and
// pays out via withdraw + Groth16 proof. See docs/architecture.md.

import "@stdlib/tvm-dicts"
import "verifier"
import "verifier_merkle_update"
import "lib/errors"

const FIELD_SIZE: int = 0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001

// Merkle config (matches packages/core/src/constants.ts MERKLE_TREE_HEIGHT=20).
// The off-chain merkle tree + the Groth16 circuits operate at the full 2^20
// capacity. The on-chain pool does NOT compute Poseidon hashes on-chain (too
// expensive) and does NOT trust depositor-supplied roots blindly. Instead,
// every deposit carries a Groth16 proof (`mergeProof`) that the claimed
// `newRoot` is the result of inserting `commitment` at leaf index
// `nextIndex` into the tree with root `currentRoot`.
//
// MAX_LEAVES is capped well below 2^20 because the pool accumulates three
// growing dictionaries (`roots`, `nullifiers`, `commitments`). TON caps
// account state at ~65,536 cells; each HashmapE entry consumes multiple
// cells; three dicts in lockstep cap real usable capacity FAR below the
// off-chain ceiling.
//
// Measured empirically by `tests/pool.capacity.test.ts`:
//   per-deposit  ≈ 3.8 cells  (commitments dict + roots dict)
//   per-withdraw ≈ 1.7 cells  (nullifiers dict)
//   full lifecycle (deposit + withdraw) ≈ 5.5 cells
//
// At 8192 deposits + 8192 withdraws → ~45K cells (~70% of TON's
// 65,536-cell account state cap). Past MAX_LEAVES, deposits revert with
// ERR_TREE_FULL — clean failure so already-paid withdrawers don't get
// stranded by storage pressure they didn't cause. The capacity test
// asserts the projection is consistent with this cap; bump both
// together when changing.
const MAX_LEAVES: int = 8192 // 2^13, ~30% headroom under TON state-cell cap

// Gas budgets. Deposit verifies one Groth16 proof (~150K gas pairing + dict
// ops) — 0.15 TON gives ~2x headroom. Withdraw also verifies one Groth16
// proof plus two outgoing sends + a log emit — measured ~0.015 TON real
// cost; 0.05 TON gives ~3x headroom over real cost and ~5x over
// REFUND_RESERVE.
//
// These are FLOOR checks: tx fails fast if attached value is below them.
// They do NOT determine how much the pool retains. The pool's per-tx
// retention is REFUND_RESERVE below; on deposit the depositor supplies
// denomination + gas (refund = attached − denomination − reserve); on
// withdraw the relayer supplies only gas (refund = attached − reserve).
// The denomination outflow to recipient is funded from the pool's
// accumulated balance, NOT from the relayer's attached value.
const MIN_DEPOSIT_GAS: int = 150_000_000 // 0.15 TON
const MIN_WITHDRAW_GAS: int = 50_000_000 // 0.05 TON

// Per-tx retention. Any handler that accepts an internal message refunds
// `attached - committed - REFUND_RESERVE` back to the sender; the pool
// keeps REFUND_RESERVE to cover its own ongoing storage rent (~3.8 cells
// added per deposit, ~1.7 per withdraw). Net pool growth per tx ≈
// REFUND_RESERVE minus the refund's own compute + forward fees, i.e.
// roughly half of REFUND_RESERVE accrues. 0.01 TON gives ~0.005 TON real
// growth per tx — enough to outpace storage rent at any realistic
// activity level.
const REFUND_RESERVE: int = 10_000_000 // 0.01 TON

// ZERO_VALUE = keccak256("tornado") mod r. The zero leaf of the merkle tree.
// Lives in packages/core/src/constants.ts on the prover side and is also
// embedded as a constant in circuits/merkleUpdate.circom. Used here only to
// initialize an empty pool's `currentRoot` to the empty-tree root (the
// merkle_update circuit assumes `prevRoot` corresponds to an empty leaf at
// the insertion position; for the first deposit, prevRoot must equal the
// empty-tree root, which is the Poseidon chain of ZERO_VALUE up to height 20).
const ZERO_VALUE: int = 0x2fe54c60d3acabf3343a35b6eba15db4821b340f76e741e2249685ed4899af6c

// Canonical Poseidon-chain of ZERO_VALUE at MERKLE_TREE_HEIGHT = 20.
// Computed off-chain via @tonado/core's `buildMerkleTree({}).root`
// (matches the bundled circomlib Poseidon over BLS12-381 — Poseidon
// parity is enforced by `check-poseidon-parity.ts`).
//
// On the FIRST deposit (`nextIndex == 0`), the deposit handler verifies
// `currentRoot == EMPTY_TREE_ROOT_HEIGHT_20`. A malicious or buggy
// deploy that seeds the pool with a non-empty initial tree (attacker-
// controlled leaves) is rejected at the first legitimate deposit,
// forcing redeploy. After the first deposit, `currentRoot` evolves via
// merge-proof-validated transitions, so this check is only meaningful
// at genesis.
const EMPTY_TREE_ROOT_HEIGHT_20: int = 0x3918ce7f8e3edbdf5afb899edd2749176d6879c93bf3d8ac3149b904f5bc1742

// ============================================================================
// Contract declaration + storage layout
// ============================================================================

contract PoolNative {
    storage: PoolStorage
    incomingMessages: AllowedMessage
}

// Hard ceiling on protocolFeeBps. AdminSetRevenueConfig rejects anything
// above this. Commits the contract to "protocol fee never exceeds 2% of
// denomination, regardless of governance whims." Trust-minimization
// surface for users.
const MAX_FEE_BPS: int = 200

// Revenue config sub-ref. Sub-ref'd to keep the root cell under TLB's
// 1023-bit budget — same pattern pool_jetton uses for JettonConfig.
struct RevenueConfig {
    treasury: address // BURN_ADDRESS until AdminSetRevenueConfig fires
    protocolFeeBps: uint16
}

struct PoolStorage {
    paused: bool
    owner: address
    denomination: coins
    nextIndex: uint32
    // Number of withdraws settled (= size of nullifiers dict). Tracked
    // explicitly so admin-recover can compute outstanding liability
    // (outstanding = nextIndex - nullifiersCount) without iterating the dict.
    nullifiersCount: uint32
    // Canonical merkle root after all deposits so far. Initialised at
    // deploy time to EMPTY_TREE_ROOT_HEIGHT_20. Every deposit's
    // mergeProof must reference `currentRoot` as its `prevRoot`, so
    // each deposit extends a single canonical chain — a depositor
    // cannot claim a multi-leaf root from a paid single-leaf insertion.
    currentRoot: uint256
    roots: cell?       // dict<uint256, slice1> — historical canonical roots
    nullifiers: cell?  // dict<uint256, slice1>
    commitments: cell? // dict<uint256, slice1>
    revenue: Cell<RevenueConfig>
}

fun isBurnAddress(a: address): bool {
    val (wc, hash) = a.getWorkchainAndHash();
    return wc == 0 && hash == 0;
}

fun PoolStorage.load(): PoolStorage {
    return PoolStorage.fromCell(contract.getData());
}

fun PoolStorage.save(self): void {
    contract.setData(self.toCell());
}

// ============================================================================
// Messages
// ============================================================================

/// Groth16 proof points for the merkle-update SNARK.
/// Same layout as `WithdrawProof` because both use BLS12-381 compressed
/// G1/G2 points, just with different verification keys.
struct MergeProof {
    piA: cell
    piB: cell
    piC: cell
}

/// Deposit native TON into the pool.
///
/// The depositor proves on-chain that `newRoot` is the result of inserting
/// `commitment` at `leafIndex` into the tree with root `prevRoot`. The
/// pool checks `prevRoot == storage.currentRoot` and
/// `leafIndex == storage.nextIndex`, so the only path through the deposit
/// handler is "extend the canonical tree by exactly one paid commitment."
/// A single paid deposit cannot register a multi-leaf attacker tree.
struct (0xded05701) DepositNative {
    queryId: uint64
    commitment: uint256
    prevRoot: uint256
    newRoot: uint256
    leafIndex: uint32
    mergeProof: Cell<MergeProof> // 3 refs (piA, piB, piC), refs out to fit
}

struct WithdrawCoreFields {
    recipient: address
    relayer: address
    fee: coins
    refund: coins
}

struct WithdrawProof {
    piA: cell
    piB: cell
    piC: cell
}

struct (0xded05702) Withdraw {
    queryId: uint64
    root: uint256
    nullifierHash: uint256
    coreFields: Cell<WithdrawCoreFields> // refs out: addresses + amounts won't fit inline
    proof: Cell<WithdrawProof>           // refs out: 3 G1/G2 cell refs
}

struct (0xded057f1) AdminPause {
    queryId: uint64
}

struct (0xded057f2) AdminUnpause {
    queryId: uint64
}

struct (0xded057f3) AdminRecoverStuck {
    queryId: uint64
    to: address
    amount: coins
}

/// V2 only — set the treasury address + protocol fee bps. Owner-gated.
/// `protocolFeeBps` is capped at MAX_FEE_BPS (200 = 2%) for trust
/// minimization; users know up-front that governance cannot punitively
/// raise the fee without redeploying the pool.
struct (0xded057f4) AdminSetRevenueConfig {
    queryId: uint64
    treasury: address
    protocolFeeBps: uint16
}

// External-out log body emitted on every successful deposit. Off-chain
// indexers (packages/core/src/indexer.ts) decode `txOutMessages` of the pool,
// filtering by the 0xded057a1 op-code, to reconstruct the merkle tree leaves
// for withdraw-proof generation. MUST stay in lockstep with the parser in
// indexer.ts :: decodeLogOutMessage.
struct (0xded057a1) DepositLog {
    commitment: uint256
    leafIndex: uint32
    timestamp: uint64
}

// External-out log body emitted on every successful withdraw. Off-chain
// indexers (apps/relayer/src/libs/Indexer.ts) decode this to populate the
// withdrawals table for /note/check, history, and dedupe.
//
// `recipientField` / `relayerField` are the address-as-field-element values
// that were bound into the SNARK public inputs (not the raw addresses);
// keeping them in the same encoding the proof saw means the indexer can
// match a withdraw log to a `WithdrawalArgs` blob without re-encoding.
//
// MUST stay in lockstep with the parser in apps/relayer/src/libs/Indexer.ts.
struct (0xded057a2) WithdrawLog {
    nullifierHash: uint256
    recipientField: uint256
    relayerField: uint256
    fee: coins
    timestamp: uint64
}

type AllowedMessage =
    | DepositNative
    | Withdraw
    | AdminPause
    | AdminUnpause
    | AdminRecoverStuck
    | AdminSetRevenueConfig

// ============================================================================
// Dict helpers (raw HashmapE — type `dict = cell?`)
// ============================================================================

const ONE_BIT_VALUE: int = 1

fun dictMarkSeen256(mutate d: cell?, key: int): void {
    d.uDictSet(256, key, beginCell().storeUint(ONE_BIT_VALUE, 1).endCell().beginParse());
}

fun dictIsSet256(d: cell?, key: int): bool {
    val (_, found) = d.uDictGet(256, key);
    return found;
}

// ============================================================================
// Address-to-field encoding (must match packages/core/src/tonClient.ts
// :: addressToFieldElement exactly).
//   bits [247..240]: workchain & 0xff
//   bits [239..0]:   high 240 bits of the 256-bit account hash
// ============================================================================

fun addressToField(addr: address): int {
    val (wc, hash) = addr.getWorkchainAndHash();
    return ((wc & 0xff) * (1 << 240)) | (hash >> 16);
}

// ============================================================================
// Build the Groth16 public-input payload for verifier.tolk's
// groth16VerifyPayload. Layout: uint8 N_PUBLIC + N int257 values, chained
// through cell refs once one cell fills up. For N=6 with int257 each:
//   Cell 1: 8 (header) + 3*257 = 779 bits + 1 ref
//   Cell 2: 3*257 = 771 bits
// See verifier.tolk :: loadNextPubInput for the reader.
// ============================================================================

// Builds the 6-input public-signal payload for the withdraw verifier's
// `groth16VerifyPayload`. 6 × 257 = 1542 bits, packed 771 + 771 across two
// cells. NO 8-bit length prefix (that's only consumed by the message-based
// `verifyProof` entry point, which we don't call from the pool).
fun buildWithdrawVerifierPayload(
    sig0: int,
    sig1: int,
    sig2: int,
    sig3: int,
    sig4: int,
    sig5: int,
): slice {
    val cell2 = beginCell().storeInt(sig3, 257).storeInt(sig4, 257).storeInt(sig5, 257).endCell();
    val cell1 = beginCell()
        .storeInt(sig0, 257)
        .storeInt(sig1, 257)
        .storeInt(sig2, 257)
        .storeRef(cell2)
        .endCell();
    return cell1.beginParse();
}

// Builds the 4-input public-signal payload for the merkle-update verifier's
// `mugroth16VerifyPayload`. Layout: 3 × 257-bit ints (771 bits) + 1 ref to a
// cell holding the final 257-bit int. Matches the reader in
// verifier_merkle_update.tolk :: muloadNextPubInput, which moves to the next
// cell only when the current one has exactly 0 bits remaining.
//
// Order MUST match circuits/merkleUpdate.circom :: main public-signals
// declaration: [prevRoot, newRoot, commitment, leafIndex].
fun buildMergeVerifierPayload(
    prevRoot: int,
    newRoot: int,
    commitment: int,
    leafIndex: int,
): slice {
    val cell2 = beginCell().storeInt(leafIndex, 257).endCell();
    val cell1 = beginCell()
        .storeInt(prevRoot, 257)
        .storeInt(newRoot, 257)
        .storeInt(commitment, 257)
        .storeRef(cell2)
        .endCell();
    return cell1.beginParse();
}

// ============================================================================
// Entry point
// ============================================================================

fun onInternalMessage(in: InMessage) {
    // Empty bodies (0 bits, 0 refs) are handled by a state-fresh heuristic:
    //
    //   - On a FRESH pool (nextIndex == 0 && nullifiersCount == 0), retain
    //     the attached value silently. This is the deploy state-init
    //     message — TVM has already installed code+data before compute
    //     runs, and the attached value (typically 0.5 TON) is the pool's
    //     initial storage reserve.
    //
    //   - After any deposit has landed, treat empty-body messages as
    //     accidental sends and refund attached − REFUND_RESERVE back to
    //     the sender. This closes the bounce: false accidental-loss
    //     footgun under burn-key mainnet, where admin-recover-stuck is
    //     permanently unavailable (no party can sign a tx with
    //     senderAddress == BURN_ADDRESS).
    //
    // Pre-first-deposit operational note: the mainnet deploy ceremony
    // performs an immediate operator seed deposit (the note is burned)
    // immediately after deploy, so the fresh-state window is closed
    // within the same deploy transaction batch. See [shell/mainnet.sh]
    // and [scripts/seed-pool.ts].
    var storage = PoolStorage.load();
    if (in.body.remainingBitsCount() == 0 && in.body.remainingRefsCount() == 0) {
        if (storage.nextIndex == 0 && storage.nullifiersCount == 0) {
            // Fresh state → deploy message → retain attached value.
            return;
        }
        // Post-fresh: refund attached − REFUND_RESERVE to sender, NoBounce
        // so the refund lands on uninitialised destinations and the
        // sender's own wallet alike.
        val refundExcess = in.valueCoins - REFUND_RESERVE;
        if (refundExcess > 0) {
            val refundMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: in.senderAddress,
                value: refundExcess,
            });
            refundMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
        }
        return;
    }
    val msg = AllowedMessage.fromSlice(in.body);

    match (msg) {
        DepositNative => {
            assert (!storage.paused) throw ERR_PAUSED;
            // v2: compute the protocol fee now so the depositor's
            // attached-value floor includes it. Fee is uniform per pool
            // (denomination * protocolFeeBps / 10000), so every depositor
            // attaches the same amount — no per-user fingerprint.
            val revCfg = storage.revenue.load();
            val protocolFee = (storage.denomination * revCfg.protocolFeeBps) / 10000;
            assert (
                in.valueCoins >= storage.denomination + protocolFee + MIN_DEPOSIT_GAS
            ) throw ERR_WRONG_DENOMINATION;

            // Enforce that the deposit extends the SINGLE canonical chain.
            // prevRoot must equal storage.currentRoot — no parallel-tree
            // forking. leafIndex must equal storage.nextIndex — append-only,
            // no skipping positions, no inserting at past positions.
            assert (msg.prevRoot == storage.currentRoot) throw ERR_PROOF_INVALID;
            assert (msg.leafIndex == storage.nextIndex) throw ERR_PROOF_INVALID;
            assert (storage.nextIndex < MAX_LEAVES) throw ERR_TREE_FULL;

            // On the FIRST deposit, verify the operator's initial
            // `currentRoot` matches the canonical empty-tree root. Without
            // this, a malicious/buggy deploy could seed the pool with
            // attacker-controlled leaves; a precomputed merge-proof against
            // that "non-empty empty tree" would let a fake withdraw succeed
            // against fabricated commitments. After the first legitimate
            // deposit lands, currentRoot evolves via merge-proof-validated
            // transitions, so this check is only meaningful at genesis.
            if (storage.nextIndex == 0) {
                assert (
                    storage.currentRoot == EMPTY_TREE_ROOT_HEIGHT_20
                ) throw ERR_BAD_GENESIS_ROOT;
            }

            // Field-range checks on every Groth16 public signal.
            // Reachability matrix (defense-in-depth analysis):
            //   commitment  — REACHABLE: attacker chooses, must be canonical
            //   prevRoot    — unreachable in practice: the `==` check above
            //                 already requires equality with storage.currentRoot
            //                 which is always written via the newRoot range
            //                 check below. Kept as defense-in-depth against
            //                 a future bug in the equality check.
            //   newRoot     — REACHABLE: attacker chooses, must be canonical
            //                 so the `roots` dict slot is unique.
            assert (msg.commitment < FIELD_SIZE) throw ERR_COMMITMENT_OUT_OF_FIELD;
            assert (msg.prevRoot < FIELD_SIZE) throw ERR_ROOT_OUT_OF_FIELD;
            assert (msg.newRoot < FIELD_SIZE) throw ERR_ROOT_OUT_OF_FIELD;

            assert (
                !dictIsSet256(storage.commitments, msg.commitment)
            ) throw ERR_DUPLICATE_COMMITMENT;

            // Verify the merkle-update Groth16 proof. Without this the
            // contract has no proof that `newRoot = insert(prevRoot,
            // commitment, leafIndex)` — a depositor could otherwise claim
            // a multi-leaf attacker tree off a single paid insertion.
            val merge = msg.mergeProof.load();
            var mergePayload = buildMergeVerifierPayload(
                msg.prevRoot,
                msg.newRoot,
                msg.commitment,
                msg.leafIndex,
            );
            assert (
                mugroth16VerifyPayload(
                    merge.piA.beginParse(),
                    merge.piB.beginParse(),
                    merge.piC.beginParse(),
                    mutate mergePayload,
                )
            ) throw ERR_PROOF_INVALID;

            // All checks passed — commit the state transition.
            val leafIndexBefore = storage.nextIndex;
            dictMarkSeen256(mutate storage.commitments, msg.commitment);
            dictMarkSeen256(mutate storage.roots, msg.newRoot);
            storage.currentRoot = msg.newRoot;
            storage.nextIndex = storage.nextIndex + 1;
            storage.save();

            // Emit the deposit log so off-chain indexers can replay the leaves
            // and rebuild the merkle tree for withdraw-proof generation.
            val logMsg = createExternalLogMessage({
                dest: createAddressNone(),
                body: DepositLog {
                    commitment: msg.commitment,
                    leafIndex: leafIndexBefore,
                    timestamp: blockchain.now() as uint64,
                },
            });
            logMsg.send(SEND_MODE_REGULAR);

            // v2: route protocol fee to treasury. Fee is uniform per
            // pool so this send doesn't fingerprint individual users.
            // NoBounce — if the treasury address rejects, we don't
            // want to brick legitimate deposits. Treasury MUST be a
            // contract that accepts arbitrary TON for accumulation
            // (see TreasuryRouter).
            if (protocolFee > 0 && !isBurnAddress(revCfg.treasury)) {
                val feeMsg = createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: revCfg.treasury,
                    value: protocolFee,
                });
                feeMsg.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
            }

            // Refund excess attached value back to the sender. The pool
            // requires `valueCoins >= denomination + protocolFee + MIN_DEPOSIT_GAS`
            // (the floor — guarantees enough budget for compute + log-emit +
            // fee-send + refund send), but only retains REFUND_RESERVE for
            // ongoing storage rent. Everything above (denomination + fee +
            // RESERVE) is refunded.
            val refundExcess = in.valueCoins - storage.denomination - protocolFee - REFUND_RESERVE;
            if (refundExcess > 0) {
                val refundMsg = createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: in.senderAddress,
                    value: refundExcess,
                });
                refundMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
            }
        }

        Withdraw => {
            assert (!storage.paused) throw ERR_PAUSED;
            assert (in.valueCoins >= MIN_WITHDRAW_GAS) throw ERR_INSUFFICIENT_GAS;

            // Load the ref-stored fields once.
            val core = msg.coreFields.load();
            val proof = msg.proof.load();

            // Range-check every public signal that flows into proof
            // verification or a dict lookup. Out-of-canonical-range values
            // would let `s · G == (s + k·p) · G` produce dict-key collisions
            // — distinct slots referring to the same scalar.
            //
            // Reachability matrix:
            //   root          — REACHABLE: attacker chooses, must be canonical
            //                   for the `roots` dict lookup to find the slot.
            //   nullifierHash — REACHABLE: same, for the `nullifiers` dict.
            //   fee, refund   — unreachable: typed as `coins` (TLB
            //                   VarUInteger 16, ≤120 bits, well below
            //                   FIELD_SIZE ≈ 2^254.9). Kept as defense-in-
            //                   depth against a future struct-layout change.
            assert (msg.root < FIELD_SIZE) throw ERR_ROOT_OUT_OF_FIELD;
            assert (msg.nullifierHash < FIELD_SIZE) throw ERR_NULLIFIER_OUT_OF_FIELD;
            assert (core.fee < FIELD_SIZE) throw ERR_FEE_OUT_OF_FIELD;
            assert (core.refund < FIELD_SIZE) throw ERR_REFUND_OUT_OF_FIELD;

            assert (core.fee <= storage.denomination) throw ERR_FEE_EXCEEDS_DENOM;
            assert (core.refund == 0) throw ERR_REFUND_NOT_ZERO_NATIVE;
            assert (dictIsSet256(storage.roots, msg.root)) throw ERR_UNKNOWN_ROOT;
            assert (!dictIsSet256(storage.nullifiers, msg.nullifierHash)) throw ERR_ALREADY_SPENT;

            // `core.recipient` and `core.relayer` are typed `address`
            // (internal-only). Tolk's typed deserializer rejects addr_none /
            // addr_extern before this handler runs; no explicit isNone()
            // check is needed at the boundary.
            val recipientField = addressToField(core.recipient);
            val relayerField = addressToField(core.relayer);
            // Both fields are derived by `addressToField` from typed
            // `address` inputs and bounded to 2^248 - 1, which is strictly
            // below FIELD_SIZE (≈ 2^254.9). Asserts kept as defense in
            // depth against a future change to `addressToField` that could
            // widen the output range.
            assert (recipientField < FIELD_SIZE) throw ERR_RECIPIENT_FIELD_OUT_OF_RANGE;
            assert (relayerField < FIELD_SIZE) throw ERR_RELAYER_FIELD_OUT_OF_RANGE;

            // Verify Groth16 proof. Public signals must match the circuit's
            // declared order (see circuits/withdraw.circom :: main).
            var payload = buildWithdrawVerifierPayload(
                msg.root,
                msg.nullifierHash,
                recipientField,
                relayerField,
                core.fee,
                core.refund,
            );
            assert (
                groth16VerifyPayload(
                    proof.piA.beginParse(),
                    proof.piB.beginParse(),
                    proof.piC.beginParse(),
                    mutate payload,
                )
            ) throw ERR_PROOF_INVALID;

            // Mark nullifier + persist BEFORE sending. The +16
            // SEND_MODE_BOUNCE_ON_ACTION_FAIL flag on the sends below
            // ensures any action-phase failure rolls back the compute
            // phase atomically (storage write reverted with the send).
            dictMarkSeen256(mutate storage.nullifiers, msg.nullifierHash);
            storage.nullifiersCount = storage.nullifiersCount + 1;
            storage.save();

            // Emit the withdraw log so off-chain indexers can populate
            // their withdrawals table for /note/check, history queries, and
            // dedupe. Stays in the same compute phase as the storage write
            // above and the value sends below — an action-phase abort rolls
            // back all three together via SEND_MODE_BOUNCE_ON_ACTION_FAIL on
            // the value sends.
            val withdrawLogMsg = createExternalLogMessage({
                dest: createAddressNone(),
                body: WithdrawLog {
                    nullifierHash: msg.nullifierHash,
                    recipientField: recipientField as uint256,
                    relayerField: relayerField as uint256,
                    fee: core.fee,
                    timestamp: blockchain.now() as uint64,
                },
            });
            withdrawLogMsg.send(SEND_MODE_REGULAR);

            val toRecipient = storage.denomination - core.fee;
            // Privacy-first payout: NoBounce + empty body so the payout lands
            // on ANY destination, including fresh uninitialized addresses —
            // which is the canonical Tornado privacy use case (withdraw to a
            // never-seen-before recipient). Trade-off: if the recipient is a
            // contract that rejects the payment, the funds are lost with no
            // on-chain record. Acceptable: the recipient address is bound
            // into the SNARK public inputs, so the user CHOSE this target.
            val recipMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: core.recipient,
                value: toRecipient,
            });
            recipMsg.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);

            if (core.fee > 0) {
                val relayerMsg = createMessage({
                    bounce: BounceMode.Only256BitsOfBody,
                    dest: core.relayer,
                    value: core.fee,
                });
                relayerMsg.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
            }

            // Refund excess attached value to the sender (relayer or
            // self-relayed user).
            //
            // At withdraw time the relayer's attached value covers ONLY the
            // sender's gas + REFUND_RESERVE. The denomination outflow to the
            // recipient (and the fee outflow to the relayer) is funded out
            // of the pool's existing balance — that liability was credited
            // by a prior deposit's denomination retention. The refund
            // formula must NOT subtract the denomination: doing so would
            // leave exactly `denomination` per cycle stranded in the pool
            // as admin-recoverable excess.
            //
            // Pool retains REFUND_RESERVE for storage rent.
            val refundExcess = in.valueCoins - REFUND_RESERVE;
            if (refundExcess > 0) {
                val refundMsg = createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: in.senderAddress,
                    value: refundExcess,
                });
                refundMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
            }
        }

        AdminPause => {
            assert (in.senderAddress == storage.owner) throw ERR_NOT_OWNER;
            storage.paused = true;
            storage.save();
            val refundExcess = in.valueCoins - REFUND_RESERVE;
            if (refundExcess > 0) {
                val refundMsg = createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: in.senderAddress,
                    value: refundExcess,
                });
                refundMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
            }
        }

        AdminUnpause => {
            assert (in.senderAddress == storage.owner) throw ERR_NOT_OWNER;
            storage.paused = false;
            storage.save();
            val refundExcess = in.valueCoins - REFUND_RESERVE;
            if (refundExcess > 0) {
                val refundMsg = createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: in.senderAddress,
                    value: refundExcess,
                });
                refundMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
            }
        }

        AdminRecoverStuck => {
            assert (in.senderAddress == storage.owner) throw ERR_NOT_OWNER;
            // Zero-amount recovery is meaningless and would emit a
            // 0-value send that may fail in the action phase under
            // PAY_FEES_SEPARATELY. Reject explicitly.
            assert (msg.amount > 0) throw ERR_RECOVER_EXCEEDS_EXCESS;
            // `msg.to` is typed `address` (internal-only). Tolk's typed
            // deserializer rejects addr_none / addr_extern before this
            // handler runs, so no explicit isNone() check is needed.
            //
            // Admin can only recover EXCESS — the balance NOT earmarked
            // for unwithdrawn deposits:
            //   outstanding = unspent deposits
            //   liability   = outstanding * denomination
            //   excess      = balance - liability - attached_gas
            val outstanding = storage.nextIndex - storage.nullifiersCount;
            val liability = outstanding * storage.denomination;
            val balance = contract.getOriginalBalance();
            val attached = in.valueCoins;
            assert (balance >= liability + attached) throw ERR_RECOVER_EXCEEDS_EXCESS;
            val excess = balance - liability - attached;
            assert (msg.amount <= excess) throw ERR_RECOVER_EXCEEDS_EXCESS;
            val rmsg = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: msg.to,
                value: msg.amount,
            });
            rmsg.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);

            // Refund excess attached value to the admin sender. The
            // recovered `msg.amount` comes from the pool's excess (above
            // liability), not from attached value, so don't subtract it.
            val refundExcess = in.valueCoins - REFUND_RESERVE;
            if (refundExcess > 0) {
                val refundMsg = createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: in.senderAddress,
                    value: refundExcess,
                });
                refundMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
            }
        }

        AdminSetRevenueConfig => {
            assert (in.senderAddress == storage.owner) throw ERR_NOT_OWNER;
            // Hard ceiling — even governance cannot punitively raise the
            // fee. Commits "fee will never exceed MAX_FEE_BPS" to users.
            assert (msg.protocolFeeBps <= MAX_FEE_BPS) throw ERR_FEE_EXCEEDS_DENOM;
            // Reject the (BURN_ADDRESS, non-zero fee) combo. The deposit
            // handler skips the fee send when treasury is BURN_ADDRESS
            // but still subtracts the fee from the refund, so accepting
            // this config silently traps the fee in the pool. If
            // governance wants to disable fee routing, set fee = 0
            // explicitly.
            assert (
                !isBurnAddress(msg.treasury) || msg.protocolFeeBps == 0
            ) throw ERR_FEE_EXCEEDS_DENOM;
            val newCfg = RevenueConfig {
                treasury: msg.treasury,
                protocolFeeBps: msg.protocolFeeBps,
            };
            storage.revenue = newCfg.toCell();
            storage.save();

            val refundExcess = in.valueCoins - REFUND_RESERVE;
            if (refundExcess > 0) {
                val refundMsg = createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: in.senderAddress,
                    value: refundExcess,
                });
                refundMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
            }
        }
    }
}

// ============================================================================
// Get methods
// ============================================================================

get fun isSpent(nh: int): bool {
    val storage = PoolStorage.load();
    return dictIsSet256(storage.nullifiers, nh);
}

get fun getDenomination(): coins {
    return PoolStorage.load().denomination;
}

get fun getNextIndex(): int {
    return PoolStorage.load().nextIndex;
}

get fun isPaused(): bool {
    return PoolStorage.load().paused;
}

get fun isKnownRoot(root: int): bool {
    return dictIsSet256(PoolStorage.load().roots, root);
}

get fun getTreasury(): address {
    return PoolStorage.load().revenue.load().treasury;
}

get fun getProtocolFeeBps(): int {
    return PoolStorage.load().revenue.load().protocolFeeBps;
}

get fun getMaxFeeBps(): int {
    return MAX_FEE_BPS;
}
