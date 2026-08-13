// ============================================================================
// Helping To Rise — GiveHelpManager (v3.7)
// OPEN SOURCE — verifiable by anyone, forever.
//
// V3.7 (owner-directed hardening + economics, built on V3.6):
//   1. AIRDROP SLOT = the first extra winner slot. No special airdrop fee
//      add-on — it costs exactly the same per-slot reserve as any other slot.
//      The airdrop slot is paid to a dedicated AIRDROP WALLET (owner-settable
//      once-optional, see SetAirdropWallet), NOT the PlatformVault.
//   2. AUTO-REFUND at final settlement: everything unused returns to the
//      giver automatically — zero-participant totals, unfilled slots, and the
//      TON fee reserve. Manual WithdrawUnspent remains as a pure FALLBACK
//      (e.g. if the distribution poke is never sent by anyone).
//   3. FRACTIONAL DIVISION: per-winner shares are exact to RISE's native 8
//      decimals — the "must divide evenly" requirement is REMOVED. The
//      integer-division remainder (dust, < 1 slot) goes to a dust pot and is
//      forwarded in RISE to the airdrop wallet once it reaches an
//      admin-settable threshold (default 100 RISE ≈ $5 at 20 RISE = $1).
//   4. RESCUE OPS (owner-only, the ONLY new owner powers):
//      - RescueJettons: recover stray/trapped RISE from THIS contract's
//        jetton wallet (the 1.25 RISE mainnet pattern). Any amount up to the
//        untracked balance is allowed; giveaway accounting is untouched.
//      - ClaimFor: owner-poke that releases a user's claimable balance to
//        that user — covers the PlatformVault 0.3 RISE pattern where the
//        holder contract cannot sign ClaimReferrals itself. Funds go ONLY to
//        the recorded claimable owner, never to the owner or elsewhere.
//   5. MIN DURATION 5 minutes contract-side (the app keeps a 1h UI floor).
//   6. Auditor items (Grok V3.6 residual findings):
//      - Jetton-trap sealing: under-funded notifications that cannot fund
//        their own return are now bounced-to-self accounting: the jettons
//        are credited to the sender's CLAIMABLE balance instead of being
//        trapped in the manager's jetton wallet — always recoverable.
//      - WithdrawUnspent now runs the SAME full cleanup chain as the
//        distribution path (no participant entries exist on that path, but
//        the reserve sweep + state handling is unified).
//      - Admin min-duration: owner can raise (never lower below 5 min) the
//        minimum duration via SetMinDuration.
//      - Friend-support reserve proportionality kept from V3.6 (Fix 1).
//   7. V3.6 goods kept: BATCH_SIZE=30 batched self-continuation, codeHash
//      privacy (only hashes on-chain), commit-reveal join, payoutFee cage
//      [0.005, 5], fee semantics (deposits, not fees — unused is refunded),
//      support reserve proportionality, cleanup chain, bounce ring.
//
// Hard rules (by design, see V3-CONTRACT-DESIGN.md):
//   - NO cancel / end / edit of a Give Help. Ever. By anyone.
//   - Owner can ONLY: UpdateMinimums, SetPayoutFee (caged), SetMinDuration
//     (raise only), SetDustSweepThreshold, SetAirdropWallet, Pause/Unpause
//     (new creations only), TransferOwnership, SetJettonWallet (once),
//     RescueRequest/ExecuteRescue/CancelRescue (72-hour timelocked queue —
//     V3.7.1 Grok-audit fix), ClaimFor (pays the claimant, never the owner).
//     Owner can NEVER instantly move funds, see codes, or touch randomness.
// ============================================================================

// ── TEP-74 jetton interface messages ────────────────────────────────────────

message(0xf8a7ea5) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

message(0x7362d09c) JettonTransferNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forwardPayload: Slice as remaining;
}

message(0xd53276db) JettonExcesses {
    queryId: Int as uint64;
}

// ── Public messages ─────────────────────────────────────────────────────────

message JoinGiveHelp {
    giveawayId: Int as uint64;
    code: String;           // plain "HTR-XXXXXX" — hashed on-chain, never stored
    referrer: Address?;     // optional referrer (credited 10% of THIS winner's share)
}

message Distribute {
    giveawayId: Int as uint64;
}

// V3.7: pure fallback — normally the final settlement auto-refunds everything.
message WithdrawUnspent {
    giveawayId: Int as uint64;
}

// Self-only cleanup chain — deletes a completed giveaway's
// participants/referrer/shuffle map entries in bounded chunks.
message Cleanup {
    giveawayId: Int as uint64;
    cursor: Int as uint64;
}

message ClaimReferrals {}

// ── Owner-only messages (the ONLY owner powers) ─────────────────────────────

message UpdateMinimums {
    minTotalAmount: Int as coins;
    minPerWinner: Int as coins;
}

message SetPayoutFee {
    newFee: Int as coins;
}

// V3.7: owner can RAISE the minimum duration (never below 5 minutes).
message SetMinDuration {
    newMinMinutes: Int as uint32;
}

// V3.7: RISE dust-pot sweep threshold (in whole RISE units at 8 decimals).
message SetDustSweepThreshold {
    newThreshold: Int as coins;
}

// V3.7: the airdrop wallet that receives airdrop slots + swept RISE dust.
message SetAirdropWallet {
    wallet: Address;
}

message Pause {}
message Unpause {}

message TransferOwnership {
    newOwner: Address;
}

// One-time bootstrap: the manager's own RISE jetton wallet address depends
// on the manager address, which depends on init args — a circular dependency
// that cannot be resolved at deploy time. It is therefore set ONCE by the
// owner immediately after deploy, then locked forever.
message SetJettonWallet {
    wallet: Address;
}

// V3.7.1 rescue (Grok-audit fix): two-step timelocked rescue of stray RISE.
// Step 1: RescueRequest records {to, amount} and starts a 72-hour timer.
// Step 2: ExecuteRescue (only after the delay) executes EXACTLY what was
// queued. CancelRescue aborts a pending request before execution.
// ONE pending request at a time (single-slot queue, documented choice):
// rescue is a rare maintenance op; a single slot keeps state minimal and
// makes the pending action unambiguous for anyone watching the contract.
message RescueRequest {
    to: Address;
    amount: Int as coins;
}

message ExecuteRescue {}

message CancelRescue {}

// V3.7 owner-poke: release a user's claimable balance TO THAT USER. Covers
// holders that cannot sign ClaimReferrals themselves (e.g. PlatformVault's
// parked 0.3 RISE). Funds can only ever go to the recorded claimant.
message ClaimFor {
    user: Address;
}

// ── On-chain events ─────────────────────────────────────────────────────────

message GiveHelpCreatedEvent {
    giveawayId: Int as uint64;
    giver: Address;
    totalAmount: Int as coins;
    declaredWinners: Int as uint32;
    airdropIncluded: Bool;
    perWinner: Int as coins;
    endsAt: Int as uint64;
    codeHash: Int as uint256; // hash only — the code itself never appears on-chain
}

message JoinedEvent {
    giveawayId: Int as uint64;
    participant: Address;
    participantCount: Int as uint32;
}

message SupportedEvent {
    giveawayId: Int as uint64;
    supporter: Address;
    amount: Int as coins;
    newSlots: Int as uint32;
}

message BatchPayoutEvent {
    giveawayId: Int as uint64;
    fromIndex: Int as uint32;
    count: Int as uint32;
    totalPaid: Int as coins;
}

message DistributionCompleteEvent {
    giveawayId: Int as uint64;
    winners: Int as uint32;
    remnant: Int as coins;
    remnantToHeld: Bool;
    airdropPaid: Int as coins;
}

message WithdrawUnspentEvent {
    giveawayId: Int as uint64;
    giver: Address;
    amount: Int as coins;
}

message ClaimedEvent {
    user: Address;
    amount: Int as coins;
}

message BounceRecoveredEvent {
    queryId: Int as uint64;
    user: Address;
    amount: Int as coins;
}

// TON dust swept to the airdrop wallet.
message DustSweepEvent {
    amount: Int as coins;
}

// V3.7: RISE dust pot swept (in RISE) to the airdrop wallet.
message RiseDustSweepEvent {
    amount: Int as coins;
}

message RejectionReturnedEvent {
    sender: Address;
    amount: Int as coins;
}

// V3.7: a rejected notification that could not fund its own return was
// credited to the sender's claimable balance instead of trapping RISE.
message RejectionCreditedEvent {
    sender: Address;
    amount: Int as coins;
}

// V3.7.1: a stray-RISE rescue was REQUESTED (step 1; 72-hour timer starts).
message RescueRequestedEvent {
    to: Address;
    amount: Int as coins;
    executeAfter: Int as uint64;
}

// V3.7.1: a queued rescue was EXECUTED (step 2, after the timelock).
message RescueExecutedEvent {
    to: Address;
    amount: Int as coins;
}

// V3.7.1: a pending rescue was CANCELLED before execution.
message RescueCancelledEvent {
    to: Address;
    amount: Int as coins;
}

// ── Give Help record ────────────────────────────────────────────────────────

struct GiveHelp {
    giver: Address;
    codeHash: Int as uint256;
    totalAmount: Int;          // giver's own RISE (excl. support)
    supportedAmount: Int;      // friend-support RISE
    perWinner: Int;            // declared per-winner share (exact, 8 decimals)
    declaredWinners: Int;      // winner slots at creation (excl. airdrop slot)
    supportSlots: Int;         // extra slots added by support
    airdropIncluded: Bool;
    participantCount: Int;
    endsAt: Int;
    tonReserveLeft: Int;       // remaining TON fee reserve
    status: Int;               // 0=Active 1=Distributing 2=Completed 3=ExpiredWithdrawable
    distCursor: Int;           // next winner index to pay
    seed: Int;                 // rolling randomness seed
    createDust: Int;           // V3.7: creation remainder, potted at settlement
}

struct PendingPayout {
    to: Address;
    amount: Int as coins;
}

contract GiveHelpManagerV37 {
    owner: Address;
    platformVault: Address;
    airdropWallet: Address;   // V3.7: airdrop slots + swept RISE dust go here
    riseJettonMaster: Address;
    riseJettonWallet: Address;  // THIS contract's own RISE jetton wallet

    minTotalAmount: Int as coins;
    minPerWinner: Int as coins;
    // Safety deposit ("payout fee") per jetton send. Admin-adjustable by the
    // owner WITHIN the hard-coded absolute cage [FEE_MIN, FEE_MAX]. Deposits
    // are auto-refunded after every distribution; this is never a fee owed
    // to anyone.
    payoutFee: Int as coins;
    // V3.7: admin min duration — owner can RAISE it, never below 5 minutes.
    minDurationMin: Int;
    // V3.7: RISE dust pot sweep threshold (8-decimal RISE units).
    dustSweepRiseThreshold: Int as coins;
    paused: Bool = false;

    nextGiveawayId: Int = 1;
    accumulatedDust: Int = 0;     // TON dust pot (fee-reserve dust)
    accumulatedRiseDust: Int = 0; // V3.7: RISE dust pot (division remainders)
    payoutSeq: Int = 1;
    // V3.7.1: single-slot rescue queue (Grok-audit timelock fix).
    pendingRescueTo: Address? = null;
    pendingRescueAmount: Int as coins = 0;
    pendingRescueAfter: Int = 0;  // unix time after which ExecuteRescue works

    giveaways: map<Int, GiveHelp>;
    usedCodeHashes: map<Int, Bool>;          // code hash ever used → rejected forever
    participants: map<Int, Address>;         // key: giveawayId * PKEY + index
    joinedKeys: map<Int, Bool>;              // key: sha256(giveawayId || address)
    participantReferrer: map<Int, Address>;  // key: giveawayId * PKEY + index
    shuffleMap: map<Int, Int>;               // Fisher-Yates virtual swaps
    held: map<Address, Int>;                 // Held Token per giver
    claimable: map<Address, Int>;            // referral + recovered bounces + sealed rejects
    pendingRing: map<Int, PendingPayout>;    // bounded ring for bounce recovery

    // ── Constants ──
    const PKEY: Int = 281474976710656;       // 2^48, composite map key space
    const BATCH_SIZE: Int = 30;              // max jetton payouts per transaction
    const BASE_PAYOUT_FEE: Int = ton("0.0013"); // measured real delivery cost
    const FEE_MIN: Int = ton("0.005");          // cage floor: ~4x real cost
    const FEE_MAX: Int = ton("5");              // cage ceiling: emergency window
    const GAS_PER_BATCH: Int = ton("0.15");  // measured gas per batch transaction
    const FINALIZE_GAS: Int = ton("0.3");    // estimated gas for the final batch
    const STORAGE_MIN: Int = ton("0.1");     // always kept for storage fees
    const DUST_MIN_REFUND: Int = ton("0.2"); // below this a TON refund is dust
    const DUST_SWEEP_MIN: Int = ton("1");    // sweep TON dust above this
    const REFUND_SEND_GAS: Int = ton("0.05");
    const CLAIM_MIN_VALUE: Int = ton("0.1"); // claimer funds their own claim send
    const SUPPORT_CLOSE_SECS: Int = 600;     // support closes T-10 minutes
    const MAX_DURATION_MIN: Int = 10080;     // 7 days, in minutes
    // V3.7: 5-minute minimum duration (contract floor). The app keeps a 1h
    // UI floor; the contract only enforces this absolute minimum.
    const MIN_DURATION_FLOOR: Int = 5;
    // V3.7: default RISE dust-pot threshold = 100 RISE (≈ $5 at 20 RISE = $1).
    const DEFAULT_DUST_SWEEP_RISE: Int = 10000000000; // 100 * 10^8
    // V3.7.1: rescue timelock — 72 hours between RescueRequest and
    // ExecuteRescue (Grok-audit requirement: 48-72h).
    const RESCUE_TIMELOCK_SECS: Int = 259200; // 72 * 3600
    const RING_SIZE: Int = 4096;             // bounce-recovery ring capacity
    const CLEANUP_BATCH: Int = 25;
    const CLEANUP_GAS: Int = ton("0.1");

    // Forward-payload opcodes inside JettonTransferNotification
    const OP_CREATE: Int = 1;
    const OP_SUPPORT: Int = 2;
    const OP_TOPUP_HELD: Int = 3;

    // Status codes
    const ST_ACTIVE: Int = 0;
    const ST_DISTRIBUTING: Int = 1;
    const ST_COMPLETED: Int = 2;
    const ST_WITHDRAWABLE: Int = 3;

    init(owner: Address, platformVault: Address, airdropWallet: Address,
         riseJettonMaster: Address, minTotalAmount: Int, minPerWinner: Int) {
        self.owner = owner;
        self.platformVault = platformVault;
        self.airdropWallet = airdropWallet;
        self.riseJettonMaster = riseJettonMaster;
        self.riseJettonWallet = newAddress(0, 0); // set once via SetJettonWallet
        self.minTotalAmount = minTotalAmount;
        self.minPerWinner = minPerWinner;
        self.payoutFee = ton("0.06"); // V3.6-era deploy default semantics kept
        self.minDurationMin = self.MIN_DURATION_FLOOR;
        self.dustSweepRiseThreshold = self.DEFAULT_DUST_SWEEP_RISE;
    }

    // ── One-time wallet bootstrap (see message doc) ──
    receive(msg: SetJettonWallet) {
        require(sender() == self.owner, "Only owner");
        require(self.riseJettonWallet == newAddress(0, 0), "Already set");
        self.riseJettonWallet = msg.wallet;
    }

    // ── Required TON fee reserve: every future send is funded up-front,
    //    with a 20% safety buffer. The airdrop slot is simply one of the
    //    slots — NO special airdrop add-on (V3.7 change). ──
    fun requiredReserve(totalSlots: Int): Int {
        let batches: Int = (totalSlots + self.BATCH_SIZE - 1) / self.BATCH_SIZE;
        let base: Int = totalSlots * self.payoutFee
                      + batches * self.GAS_PER_BATCH
                      + 2 * self.payoutFee + self.FINALIZE_GAS;
        return base * 120 / 100;
    }

    // TON reserve a support transfer must attach for the slots it adds —
    // same pricing components as requiredReserve, without the one-time
    // creation constants (paid once by the giver at creation).
    fun requiredSupportReserve(newSlots: Int): Int {
        let batches: Int = (newSlots + self.BATCH_SIZE - 1) / self.BATCH_SIZE;
        return (newSlots * self.payoutFee + batches * self.GAS_PER_BATCH) * 120 / 100;
    }

    // ══════════════════════════════════════════════════════════════════════
    // RISE IN — creation / friend support / held top-up (jetton notification)
    // ══════════════════════════════════════════════════════════════════════
    receive(msg: JettonTransferNotification) {
        require(sender() == self.riseJettonWallet, "Not RISE wallet");
        require(self.riseJettonWallet != newAddress(0, 0), "Wallet not set");
        let p: Slice = msg.forwardPayload;
        // TEP-74 allows the forward payload inline or as a ref; accept both.
        if (p.bits() < 32 && p.refs() > 0) {
            p = p.loadRef().beginParse();
        }
        // V3.7 trap sealing: even a malformed/short payload must not trap
        // RISE — credit it to the sender's claimable balance.
        if (p.bits() < 32) {
            self.creditClaimable(msg.sender, msg.amount);
            emit(RejectionCreditedEvent { sender: msg.sender, amount: msg.amount }.toCell());
            return;
        }
        let op: Int = p.loadUint(32);

        if (op == self.OP_CREATE) {
            self.handleCreate(msg, p);
        } else if (op == self.OP_SUPPORT) {
            self.handleSupport(msg, p);
        } else if (op == self.OP_TOPUP_HELD) {
            require(msg.amount > 0, "Zero top-up");
            let h: Int = 0;
            let hOpt: Int? = self.held.get(msg.sender);
            if (hOpt != null) { h = hOpt!!; }
            self.held.set(msg.sender, h + msg.amount);
        } else {
            // Unknown op — RETURN the jettons to the sender (or credit their
            // claimable balance if the return cannot be funded — V3.7 seal).
            self.returnJettons(msg);
        }
    }

    fun handleCreate(msg: JettonTransferNotification, p: Slice) {
        require(!self.paused, "Platform paused");

        let totalAmount: Int = p.loadCoins();
        let winnerCount: Int = p.loadUint(32);
        let durationMinutes: Int = p.loadUint(32);
        let airdropIncluded: Bool = p.loadUint(1) == 1;
        let codeHash: Int = p.loadUint(256);

        require(winnerCount > 0, "Winners > 0");
        require(durationMinutes >= self.minDurationMin, "Below min duration");
        require(durationMinutes <= self.MAX_DURATION_MIN, "Max 7 days");
        require(codeHash != 0, "Bad code hash");
        require(self.usedCodeHashes.get(codeHash) == null, "Code already used");

        // Airdrop = the first extra winner slot, same cost as any other slot.
        let slots: Int = winnerCount;
        if (airdropIncluded) { slots = slots + 1; }

        // V3.7: fractional division to RISE's native 8 decimals. The integer
        // remainder (dust, always < slots units of 1e-8 RISE) goes to the
        // RISE dust pot instead of rejecting the creation.
        require(totalAmount >= self.minTotalAmount, "Below minimum total");
        let perWinner: Int = totalAmount / slots;
        require(perWinner >= self.minPerWinner, "Below minimum per winner");
        // The integer-division remainder (dust, < slots units of 1e-8 RISE)
        // is recorded on the giveaway and moved into the RISE dust pot AT
        // SETTLEMENT — crediting it here would double-count it, because the
        // same remainder resurfaces in the settlement remnant.

        // Held Token is used first; the transfer tops up the rest (exactly).
        let heldBal: Int = 0;
        let heldOpt: Int? = self.held.get(msg.sender);
        if (heldOpt != null) { heldBal = heldOpt!!; }
        let heldUsed: Int = heldBal;
        if (heldUsed > totalAmount) { heldUsed = totalAmount; }
        require(msg.amount + heldUsed == totalAmount, "Top-up mismatch");
        if (heldUsed > 0) { self.held.set(msg.sender, heldBal - heldUsed); }

        // Bulletproof fee reserve: airdrop slot included at the SAME per-slot
        // cost — no special add-on.
        let requiredTon: Int = self.requiredReserve(slots);
        require(context().value >= requiredTon, "Insufficient TON reserve");

        let id: Int = self.nextGiveawayId;
        self.nextGiveawayId = id + 1;
        self.usedCodeHashes.set(codeHash, true);

        self.giveaways.set(id, GiveHelp {
            giver: msg.sender,
            codeHash: codeHash,
            totalAmount: totalAmount,
            supportedAmount: 0,
            perWinner: perWinner,
            declaredWinners: winnerCount,
            supportSlots: 0,
            airdropIncluded: airdropIncluded,
            participantCount: 0,
            endsAt: now() + durationMinutes * 60,
            tonReserveLeft: context().value,
            status: self.ST_ACTIVE,
            distCursor: 0,
            seed: 0,
            createDust: totalAmount - perWinner * slots
        });

        emit(GiveHelpCreatedEvent {
            giveawayId: id,
            giver: msg.sender,
            totalAmount: totalAmount,
            declaredWinners: winnerCount,
            airdropIncluded: airdropIncluded,
            perWinner: perWinner,
            endsAt: now() + durationMinutes * 60,
            codeHash: codeHash
        }.toCell());
    }

    fun handleSupport(msg: JettonTransferNotification, p: Slice) {
        let giveawayId: Int = p.loadUint(64);
        let gOpt: GiveHelp? = self.giveaways.get(giveawayId);
        // Every rejection RETURNS the support jettons (or credits claimable
        // when the return cannot be funded — V3.7 seal, never trapped).
        if (gOpt == null) { self.returnJettons(msg); return; }
        let g: GiveHelp = gOpt!!;

        if (g.status != self.ST_ACTIVE) { self.returnJettons(msg); return; }
        if (now() >= g.endsAt - self.SUPPORT_CLOSE_SECS) { self.returnJettons(msg); return; }
        if (msg.amount <= 0) { return; }
        if (msg.amount % g.perWinner != 0) { self.returnJettons(msg); return; }

        let newSlots: Int = msg.amount / g.perWinner;

        // Support must ATTACH TON reserve proportional to the slots it adds
        // (V3.6 Fix 1, kept). Insufficient TON -> jettons RETURNED.
        if (context().value < self.requiredSupportReserve(newSlots)) {
            self.returnJettons(msg);
            return;
        }

        g.supportedAmount = g.supportedAmount + msg.amount;
        g.supportSlots = g.supportSlots + newSlots;
        g.tonReserveLeft = g.tonReserveLeft + context().value;
        self.giveaways.set(giveawayId, g);

        emit(SupportedEvent {
            giveawayId: giveawayId,
            supporter: msg.sender,
            amount: msg.amount,
            newSlots: newSlots
        }.toCell());
    }

    // ══════════════════════════════════════════════════════════════════════
    // JOIN — code proven by hash; the plain code is never stored or emitted
    // ══════════════════════════════════════════════════════════════════════
    receive(msg: JoinGiveHelp) {
        let gOpt: GiveHelp? = self.giveaways.get(msg.giveawayId);
        require(gOpt != null, "Not found");
        let g: GiveHelp = gOpt!!;

        require(g.status == self.ST_ACTIVE, "Not active");
        require(now() < g.endsAt, "Ended");
        require(sender() != g.giver, "Giver cannot join");
        require(sha256(msg.code) == g.codeHash, "Wrong code");

        // O(1) duplicate check — hash the CELL, not the slice.
        let joinKey: Int = beginCell()
            .storeUint(msg.giveawayId, 64)
            .storeAddress(sender())
            .endCell().hash();
        require(self.joinedKeys.get(joinKey) == null, "Already joined");
        self.joinedKeys.set(joinKey, true);

        let idx: Int = g.participantCount;
        let pKey: Int = msg.giveawayId * self.PKEY + idx;
        self.participants.set(pKey, sender());
        if (msg.referrer != null && msg.referrer!! != sender()) {
            self.participantReferrer.set(pKey, msg.referrer!!);
        }
        g.participantCount = idx + 1;
        self.giveaways.set(msg.giveawayId, g);

        emit(JoinedEvent {
            giveawayId: msg.giveawayId,
            participant: sender(),
            participantCount: g.participantCount
        }.toCell());
    }

    // ══════════════════════════════════════════════════════════════════════
    // DISTRIBUTE — permissionless, after endsAt, forward-only, batched,
    // self-continuing until done. Fisher-Yates partial shuffle, no duplicates.
    // V3.7: the FINAL batch auto-refunds EVERYTHING unused to the giver —
    // zero-participant totals, unfilled slots, the airdrop slot when there
    // are no participants, and the leftover TON reserve (via cleanup chain).
    // ══════════════════════════════════════════════════════════════════════
    receive(msg: Distribute) {
        let gOpt: GiveHelp? = self.giveaways.get(msg.giveawayId);
        require(gOpt != null, "Not found");
        let g: GiveHelp = gOpt!!;

        require(now() >= g.endsAt, "Not ended");
        require(g.status == self.ST_ACTIVE || g.status == self.ST_DISTRIBUTING, "Finished");

        if (g.status == self.ST_ACTIVE) {
            nativeRandomizeLt();
            g.seed = randomInt();
            g.status = self.ST_DISTRIBUTING;
        } else {
            nativeRandomize(g.seed);
        }

        let totalSlots: Int = g.declaredWinners + g.supportSlots;
        let humanWinners: Int = g.participantCount;
        if (humanWinners > totalSlots) { humanWinners = totalSlots; }

        // ── Process one batch of winners ──
        let processed: Int = 0;
        let batchPaid: Int = 0;
        let fromIndex: Int = g.distCursor;

        while (processed < self.BATCH_SIZE && g.distCursor < humanWinners) {
            let w: Int = g.distCursor;
            let n: Int = g.participantCount;

            // Fisher-Yates step on a virtual array (swaps recorded in a map).
            let j: Int = w + random(0, n - w);
            let keyJ: Int = msg.giveawayId * self.PKEY + j;
            let keyW: Int = msg.giveawayId * self.PKEY + w;
            let pi: Int = j;
            let pjOpt: Int? = self.shuffleMap.get(keyJ);
            if (pjOpt != null) { pi = pjOpt!!; }
            let cur: Int = w;
            let pwOpt: Int? = self.shuffleMap.get(keyW);
            if (pwOpt != null) { cur = pwOpt!!; }
            self.shuffleMap.set(keyJ, cur);

            let winner: Address = self.participants.get(msg.giveawayId * self.PKEY + pi)!!;

            // Referral: 10% comes out of THIS winner's own share. Never extra.
            // Rounding note (Grok MEDIUM, documented, no code change):
            // `perWinner / 10` FLOORS — the sub-unit remainder stays with the
            // winner. The referrer can never gain from rounding; at 8-decimal
            // RISE granularity the effect is < 1e-8 RISE (≈ $0.000000005).
            let pay: Int = g.perWinner;
            let refOpt: Address? = self.participantReferrer.get(msg.giveawayId * self.PKEY + pi);
            if (refOpt != null) {
                let refShare: Int = g.perWinner / 10;
                pay = g.perWinner - refShare;
                let bal: Int = 0;
                let balOpt: Int? = self.claimable.get(refOpt!!);
                if (balOpt != null) { bal = balOpt!!; }
                self.claimable.set(refOpt!!, bal + refShare);
            }

            self.sendJettons(winner, pay, g.giver);

            g.distCursor = g.distCursor + 1;
            processed = processed + 1;
            batchPaid = batchPaid + pay;
        }

        if (processed > 0) {
            emit(BatchPayoutEvent {
                giveawayId: msg.giveawayId,
                fromIndex: fromIndex,
                count: processed,
                totalPaid: batchPaid
            }.toCell());
        }

        // Fee-reserve accounting for this batch.
        g.tonReserveLeft = g.tonReserveLeft - processed * self.payoutFee - self.GAS_PER_BATCH;
        if (g.tonReserveLeft < 0) { g.tonReserveLeft = 0; }

        if (g.distCursor < humanWinners) {
            // Continue in the next transaction — funded from the reserve.
            g.seed = randomInt();
            self.giveaways.set(msg.giveawayId, g);

            let remaining: Int = humanWinners - g.distCursor;
            let nextCount: Int = remaining;
            if (nextCount > self.BATCH_SIZE) { nextCount = self.BATCH_SIZE; }
            let nextValue: Int = nextCount * self.payoutFee + self.GAS_PER_BATCH;
            let avail: Int = myBalance() - self.STORAGE_MIN - context().value;
            if (nextValue > avail) { nextValue = avail; }
            require(nextValue > self.GAS_PER_BATCH, "Reserve exhausted");

            send(SendParameters {
                to: myAddress(),
                value: nextValue,
                mode: SendPayFwdFeesSeparately,
                body: Distribute { giveawayId: msg.giveawayId }.toCell()
            });
            return;
        }

        // ── Final batch: settle EVERYTHING unused, automatically ──
        let airdropPaid: Int = 0;
        if (g.airdropIncluded && g.participantCount >= 1) {
            // V3.7: the airdrop slot is paid to the AIRDROP WALLET (only ever
            // with real participants). Same per-slot cost as any other slot.
            self.sendJettons(self.airdropWallet, g.perWinner, g.giver);
            airdropPaid = g.perWinner;
            g.tonReserveLeft = g.tonReserveLeft - self.payoutFee;
            if (g.tonReserveLeft < 0) { g.tonReserveLeft = 0; }
        }

        let pool: Int = g.totalAmount + g.supportedAmount;
        let remnant: Int = pool - humanWinners * g.perWinner - airdropPaid;
        // V3.7: the creation remainder (createDust) is carved out of the
        // remnant and moved into the RISE dust pot FIRST — it belongs to the
        // airdrop wallet, never to the giver's refund or the held lock.
        if (g.createDust > 0 && remnant >= g.createDust) {
            self.accumulatedRiseDust = self.accumulatedRiseDust + g.createDust;
            remnant = remnant - g.createDust;
        }
        let remnantToHeld: Bool = false;

        if (remnant > 0) {
            if (g.supportedAmount > 0 && g.participantCount > 0) {
                // Anti-scam lock (kept): when FRIENDS supported a round that
                // had participants, the remnant becomes Held Token so the
                // giver cannot pocket support while appearing generous.
                let h: Int = 0;
                let hOpt: Int? = self.held.get(g.giver);
                if (hOpt != null) { h = hOpt!!; }
                self.held.set(g.giver, h + remnant);
                remnantToHeld = true;
            } else {
                // V3.7 AUTO-REFUND: zero participants, or no support at all —
                // every unused RISE returns to the giver automatically at
                // final settlement (unfilled slots, zero-participant totals).
                self.sendJettons(g.giver, remnant, g.giver);
                g.tonReserveLeft = g.tonReserveLeft - self.payoutFee;
                if (g.tonReserveLeft < 0) { g.tonReserveLeft = 0; }
            }
        }

        g.status = self.ST_COMPLETED;
        self.giveaways.set(msg.giveawayId, g);

        emit(DistributionCompleteEvent {
            giveawayId: msg.giveawayId,
            winners: humanWinners,
            remnant: remnant,
            remnantToHeld: remnantToHeld,
            airdropPaid: airdropPaid
        }.toCell());

        // Clean this giveaway's maps (best-effort, chunked), then sweep the
        // reserve — and sweep the RISE dust pot if it crossed the threshold.
        self.startCleanupOrSweep(msg.giveawayId, g);
    }

    // ══════════════════════════════════════════════════════════════════════
    // CLEANUP (self-only) — chunked deletion of a completed giveaway's
    // participants / referrer / shuffle entries, funded from the giveaway's
    // own reserve. Runs strictly AFTER completion: if the reserve cannot
    // fund another chunk, cleanup stops and the remaining reserve is swept
    // to the giver as usual (bounded laziness; every winner is already paid).
    // ══════════════════════════════════════════════════════════════════════
    receive(msg: Cleanup) {
        require(sender() == myAddress(), "Self only");
        let gOpt: GiveHelp? = self.giveaways.get(msg.giveawayId);
        if (gOpt == null) { return; }
        let g: GiveHelp = gOpt!!;
        if (g.status != self.ST_COMPLETED) { return; }

        let cursor: Int = msg.cursor;
        let end: Int = cursor + self.CLEANUP_BATCH;
        if (end > g.participantCount) { end = g.participantCount; }
        let base: Int = msg.giveawayId * self.PKEY;
        while (cursor < end) {
            self.participants.set(base + cursor, null);
            self.participantReferrer.set(base + cursor, null);
            self.shuffleMap.set(base + cursor, null);
            cursor = cursor + 1;
        }

        g.tonReserveLeft = g.tonReserveLeft - self.CLEANUP_GAS;
        if (g.tonReserveLeft < 0) { g.tonReserveLeft = 0; }
        self.giveaways.set(msg.giveawayId, g);

        if (cursor < g.participantCount && g.tonReserveLeft >= self.CLEANUP_GAS) {
            let nextValue: Int = self.CLEANUP_GAS;
            let avail: Int = myBalance() - self.STORAGE_MIN - context().value;
            if (nextValue > avail) { nextValue = avail; }
            if (nextValue > self.CLEANUP_GAS / 2) {
                send(SendParameters {
                    to: myAddress(),
                    value: nextValue,
                    mode: SendPayFwdFeesSeparately,
                    body: Cleanup { giveawayId: msg.giveawayId, cursor: cursor }.toCell()
                });
                return;
            }
        }
        // Cleanup finished (or reserve too low): final sweep.
        self.refundReserveAndSweep(g.giver, g.tonReserveLeft);
    }

    // ══════════════════════════════════════════════════════════════════════
    // WITHDRAW UNSPENT — V3.7: pure FALLBACK. The final settlement already
    // auto-refunds everything; this path exists only if distribution never
    // ran (nobody ever poked Distribute). Same cleanup + sweep unified.
    // ══════════════════════════════════════════════════════════════════════
    receive(msg: WithdrawUnspent) {
        let gOpt: GiveHelp? = self.giveaways.get(msg.giveawayId);
        require(gOpt != null, "Not found");
        let g: GiveHelp = gOpt!!;

        require(sender() == g.giver, "Only giver");
        require(g.participantCount == 0, "Has participants");
        require(g.supportedAmount == 0, "Has support");
        let ok: Bool = g.status == self.ST_WITHDRAWABLE;
        if (g.status == self.ST_ACTIVE && now() >= g.endsAt) { ok = true; }
        require(ok, "Not withdrawable");

        g.status = self.ST_COMPLETED;
        self.giveaways.set(msg.giveawayId, g);

        // Refund the RISE amount minus the creation remainder — the dust
        // still goes to the airdrop pot, exactly as on the settlement path.
        let refundAmount: Int = g.totalAmount;
        if (g.createDust > 0) {
            self.accumulatedRiseDust = self.accumulatedRiseDust + g.createDust;
            refundAmount = refundAmount - g.createDust;
        }
        self.sendJettons(g.giver, refundAmount, g.giver);

        emit(WithdrawUnspentEvent {
            giveawayId: msg.giveawayId,
            giver: g.giver,
            amount: refundAmount
        }.toCell());

        // Refund remaining TON reserve (minus the payout send cost) — same
        // unified sweep as the distribution path.
        let reserve: Int = g.tonReserveLeft - self.payoutFee;
        if (reserve < 0) { reserve = 0; }
        self.refundReserveAndSweep(g.giver, reserve);
    }

    // ══════════════════════════════════════════════════════════════════════
    // CLAIM REFERRALS — pull-based; claimer funds their own network fee.
    // Bounced payouts are recovered into the same claimable balance.
    // ══════════════════════════════════════════════════════════════════════
    receive(msg: ClaimReferrals) {
        require(context().value >= self.CLAIM_MIN_VALUE, "Fee too small");
        let bal: Int = 0;
        let balOpt: Int? = self.claimable.get(sender());
        if (balOpt != null) { bal = balOpt!!; }
        require(bal > 0, "Nothing to claim");

        self.sendJettons(sender(), bal, sender());
        self.claimable.set(sender(), 0);

        emit(ClaimedEvent { user: sender(), amount: bal }.toCell());
    }

    // ── Jetton excess TON returns here — silently accepted. ──
    receive(msg: JettonExcesses) {}

    // ── Bounced jetton payout recovery (bounded ring). ──
    bounced(msg: Slice) {
        let op: Int = msg.loadUint(32);
        if (op != 0xf8a7ea5) { return; } // only jetton transfers
        let qid: Int = msg.loadUint(64);
        let amount: Int = msg.loadCoins();

        let rec: PendingPayout? = self.pendingRing.get(qid % self.RING_SIZE);
        if (rec != null && rec!!.amount == amount) {
            let to: Address = rec!!.to;
            self.creditClaimable(to, amount);
            self.pendingRing.set(qid % self.RING_SIZE, null);
            emit(BounceRecoveredEvent { queryId: qid, user: to, amount: amount }.toCell());
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    // OWNER — the ONLY owner powers (see contract header). No fund movement
    // from giveaways. No code access. No randomness influence. Ever.
    // ══════════════════════════════════════════════════════════════════════
    receive(msg: UpdateMinimums) {
        require(sender() == self.owner, "Only owner");
        require(msg.minTotalAmount > 0 && msg.minPerWinner > 0, "Minimums > 0");
        require(msg.minTotalAmount >= msg.minPerWinner, "Total >= per winner");
        self.minTotalAmount = msg.minTotalAmount;
        self.minPerWinner = msg.minPerWinner;
    }

    receive(msg: SetPayoutFee) {
        require(sender() == self.owner, "Only owner");
        require(msg.newFee >= self.FEE_MIN && msg.newFee <= self.FEE_MAX,
                "Fee outside safe band");
        self.payoutFee = msg.newFee;
    }

    // V3.7: admin min-duration — RAISE only, never below the 5-minute floor.
    receive(msg: SetMinDuration) {
        require(sender() == self.owner, "Only owner");
        require(msg.newMinMinutes >= self.MIN_DURATION_FLOOR, "Below 5-min floor");
        require(msg.newMinMinutes <= self.MAX_DURATION_MIN, "Above max");
        self.minDurationMin = msg.newMinMinutes;
    }

    // V3.7: RISE dust-pot sweep threshold (default 100 RISE ≈ $5).
    receive(msg: SetDustSweepThreshold) {
        require(sender() == self.owner, "Only owner");
        require(msg.newThreshold > 0, "Threshold > 0");
        self.dustSweepRiseThreshold = msg.newThreshold;
    }

    // V3.7: the airdrop wallet receiving airdrop slots + swept RISE dust.
    receive(msg: SetAirdropWallet) {
        require(sender() == self.owner, "Only owner");
        self.airdropWallet = msg.wallet;
    }

    receive(msg: Pause) {
        require(sender() == self.owner, "Only owner");
        self.paused = true; // blocks NEW creations only; running Give Helps finish
    }

    receive(msg: Unpause) {
        require(sender() == self.owner, "Only owner");
        self.paused = false;
    }

    receive(msg: TransferOwnership) {
        require(sender() == self.owner, "Only owner");
        self.owner = msg.newOwner;
    }

    // ══════════════════════════════════════════════════════════════════════
    // V3.7.1 RESCUE OPS (Grok-audit timelock fix) — the ONLY owner
    // fund-touching powers besides ClaimFor.
    //   - Rescue is TWO-STEP with a hard 72-hour timelock: RescueRequest
    //     queues {to, amount} and emits a public event; ExecuteRescue runs
    //     only after RESCUE_TIMELOCK_SECS and executes EXACTLY what was
    //     queued; CancelRescue aborts a pending request (also public).
    //     A compromised owner key can therefore only START a publicly
    //     visible, cancellable 72-hour countdown — it cannot drain instantly.
    //   - Single-slot queue (documented choice): one pending request at a
    //     time. Rescue is a rare maintenance op; a single slot keeps the
    //     pending action unambiguous for anyone watching the contract and
    //     keeps state minimal. A second request reverts until the first is
    //     executed or cancelled.
    //   - ClaimFor pays ONLY the recorded claimant, never the owner.
    // ══════════════════════════════════════════════════════════════════════
    receive(msg: RescueRequest) {
        require(sender() == self.owner, "Only owner");
        require(msg.amount > 0, "Amount > 0");
        require(msg.to != newAddress(0, 0), "Bad destination");
        require(self.pendingRescueTo == null, "Rescue already pending");
        // The owner attests off-chain that the amount is stray (e.g. the
        // 1.25 RISE trapped by under-funded notifications). The 72-hour
        // public window below is the protection against abuse.
        self.pendingRescueTo = msg.to;
        self.pendingRescueAmount = msg.amount;
        self.pendingRescueAfter = now() + self.RESCUE_TIMELOCK_SECS;
        emit(RescueRequestedEvent {
            to: msg.to,
            amount: msg.amount,
            executeAfter: self.pendingRescueAfter
        }.toCell());
    }

    receive(msg: ExecuteRescue) {
        require(sender() == self.owner, "Only owner");
        require(self.pendingRescueTo != null, "No pending rescue");
        require(now() >= self.pendingRescueAfter, "Timelock not expired");
        require(context().value >= self.payoutFee, "Fee too small");
        let to: Address = self.pendingRescueTo!!;
        let amount: Int = self.pendingRescueAmount;
        self.pendingRescueTo = null;
        self.pendingRescueAmount = 0;
        self.pendingRescueAfter = 0;
        self.sendJettons(to, amount, self.owner);
        emit(RescueExecutedEvent { to: to, amount: amount }.toCell());
    }

    receive(msg: CancelRescue) {
        require(sender() == self.owner, "Only owner");
        require(self.pendingRescueTo != null, "No pending rescue");
        let to: Address = self.pendingRescueTo!!;
        let amount: Int = self.pendingRescueAmount;
        self.pendingRescueTo = null;
        self.pendingRescueAmount = 0;
        self.pendingRescueAfter = 0;
        emit(RescueCancelledEvent { to: to, amount: amount }.toCell());
    }

    // V3.7: release a user's claimable balance TO THAT USER (owner-poke).
    // Covers claimants that cannot sign ClaimReferrals themselves (e.g. the
    // PlatformVault's parked 0.3 RISE). Funds can ONLY go to the claimant.
    receive(msg: ClaimFor) {
        require(sender() == self.owner, "Only owner");
        require(context().value >= self.payoutFee, "Fee too small");
        let bal: Int = 0;
        let balOpt: Int? = self.claimable.get(msg.user);
        if (balOpt != null) { bal = balOpt!!; }
        require(bal > 0, "Nothing to claim");

        self.sendJettons(msg.user, bal, msg.user);
        self.claimable.set(msg.user, 0);

        emit(ClaimedEvent { user: msg.user, amount: bal }.toCell());
    }

    // ══════════════════════════════════════════════════════════════════════
    // Internal helpers
    // ══════════════════════════════════════════════════════════════════════

    fun creditClaimable(user: Address, amount: Int) {
        let bal: Int = 0;
        let balOpt: Int? = self.claimable.get(user);
        if (balOpt != null) { bal = balOpt!!; }
        self.claimable.set(user, bal + amount);
    }

    fun sendJettons(to: Address, amount: Int, excessTo: Address) {
        let qid: Int = self.payoutSeq;
        self.payoutSeq = qid + 1;
        self.pendingRing.set(qid % self.RING_SIZE, PendingPayout { to: to, amount: amount });

        // TEP-74 JettonTransfer body built BY HAND — the explicit trailing
        // `0` flag bit makes it byte-identical to the known-good mainnet
        // layout (V3.4 fix; do NOT switch to Tact auto-serialization).
        let body: Cell = beginCell()
            .storeUint(0xf8a7ea5, 32)
            .storeUint(qid, 64)
            .storeCoins(amount)
            .storeAddress(to)
            .storeAddress(excessTo)
            .storeBit(false)      // customPayload: none
            .storeCoins(0)        // forwardTonAmount
            .storeBit(false)      // forwardPayload: absent
            .endCell();

        send(SendParameters {
            to: self.riseJettonWallet,
            value: self.payoutFee,
            mode: SendPayFwdFeesSeparately,
            body: body
        });
    }

    // Rejected incoming RISE (late support, unknown op, etc.) is sent BACK
    // to the original sender. V3.7 trap sealing: if the notification did not
    // carry enough TON to fund the return, the RISE is credited to the
    // sender's CLAIMABLE balance instead of being trapped in this contract's
    // jetton wallet (the 1.25 RISE mainnet trap) — always recoverable via
    // ClaimReferrals / ClaimFor.
    fun returnJettons(msg: JettonTransferNotification) {
        if (msg.amount > 0) {
            if (context().value >= self.payoutFee + ton("0.01")) {
                self.sendJettons(msg.sender, msg.amount, msg.sender);
                emit(RejectionReturnedEvent { sender: msg.sender, amount: msg.amount }.toCell());
            } else {
                self.creditClaimable(msg.sender, msg.amount);
                emit(RejectionCreditedEvent { sender: msg.sender, amount: msg.amount }.toCell());
            }
        }
    }

    // Kick off the chunked cleanup chain, or sweep directly when there is
    // nothing to clean / not enough reserve to fund a chunk.
    fun startCleanupOrSweep(giveawayId: Int, g: GiveHelp) {
        if (g.participantCount > 0 && g.tonReserveLeft >= self.CLEANUP_GAS) {
            send(SendParameters {
                to: myAddress(),
                value: self.CLEANUP_GAS,
                mode: SendPayFwdFeesSeparately,
                body: Cleanup { giveawayId: giveawayId, cursor: 0 }.toCell()
            });
        } else {
            self.refundReserveAndSweep(g.giver, g.tonReserveLeft);
        }
    }

    // Excess TON reserve → back to the giver, self-funded. TON dust below
    // the refund threshold accumulates; above the sweep threshold it goes to
    // the airdrop wallet. Also sweeps the RISE dust pot (division
    // remainders) in RISE to the airdrop wallet once it reaches the
    // admin-settable threshold (default 100 RISE ≈ $5).
    fun refundReserveAndSweep(giver: Address, reserve: Int) {
        if (reserve > 0) {
            if (reserve >= self.DUST_MIN_REFUND + self.REFUND_SEND_GAS) {
                let avail: Int = myBalance() - self.STORAGE_MIN;
                let value: Int = reserve - self.REFUND_SEND_GAS;
                if (value > avail) { value = avail; }
                if (value > 0) {
                    send(SendParameters {
                        to: giver,
                        value: value,
                        mode: SendPayFwdFeesSeparately,
                        body: "HTR fee reserve refund".asComment()
                    });
                } else {
                    self.accumulatedDust = self.accumulatedDust + reserve;
                }
            } else {
                self.accumulatedDust = self.accumulatedDust + reserve;
            }
        }

        if (self.accumulatedDust >= self.DUST_SWEEP_MIN) {
            let avail: Int = myBalance() - self.STORAGE_MIN;
            let value: Int = self.accumulatedDust - self.REFUND_SEND_GAS;
            if (value > 0 && value <= avail) {
                self.accumulatedDust = 0;
                send(SendParameters {
                    to: self.airdropWallet,
                    value: value,
                    mode: SendPayFwdFeesSeparately,
                    body: "HTR accumulated dust".asComment()
                });
                emit(DustSweepEvent { amount: value }.toCell());
            }
        }

        // V3.7: RISE dust pot — sent in RISE to the airdrop wallet at the
        // admin-set threshold (default 100 RISE). The pot is tracked RISE
        // already inside this contract's jetton wallet (division remainders),
        // so the sweep is a plain ring-registered jetton send.
        if (self.accumulatedRiseDust >= self.dustSweepRiseThreshold) {
            let amount: Int = self.accumulatedRiseDust;
            self.accumulatedRiseDust = 0;
            self.sendJettons(self.airdropWallet, amount, self.airdropWallet);
            emit(RiseDustSweepEvent { amount: amount }.toCell());
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    // Getters — code privacy: only hashes are ever exposed.
    // ══════════════════════════════════════════════════════════════════════

    get fun getGiveHelp(id: Int): GiveHelp? {
        return self.giveaways.get(id);
    }

    get fun getTotalGiveHelps(): Int {
        return self.nextGiveawayId - 1;
    }

    get fun isCodeHashUsed(codeHash: Int): Bool {
        return self.usedCodeHashes.get(codeHash) != null;
    }

    get fun hashCode(code: String): Int {
        return sha256(code);
    }

    get fun hasJoined(giveawayId: Int, user: Address): Bool {
        let joinKey: Int = beginCell()
            .storeUint(giveawayId, 64)
            .storeAddress(user)
            .endCell().hash();
        return self.joinedKeys.get(joinKey) != null;
    }

    get fun getParticipant(giveawayId: Int, index: Int): Address? {
        return self.participants.get(giveawayId * self.PKEY + index);
    }

    get fun getHeldBalance(user: Address): Int {
        let h: Int? = self.held.get(user);
        if (h == null) { return 0; }
        return h!!;
    }

    get fun getClaimable(user: Address): Int {
        let c: Int? = self.claimable.get(user);
        if (c == null) { return 0; }
        return c!!;
    }

    get fun getMinimums(): Int {
        return self.minTotalAmount;
    }

    get fun getMinPerWinner(): Int {
        return self.minPerWinner;
    }

    get fun getPayoutFee(): Int {
        return self.payoutFee;
    }

    get fun getPayoutFeeBounds(): Int {
        return self.FEE_MIN;
    }

    get fun getPayoutFeeMax(): Int {
        return self.FEE_MAX;
    }

    get fun getBasePayoutFee(): Int {
        return self.BASE_PAYOUT_FEE;
    }

    get fun getRequiredReserve(totalSlots: Int): Int {
        return self.requiredReserve(totalSlots);
    }

    get fun getRequiredSupportReserve(newSlots: Int): Int {
        return self.requiredSupportReserve(newSlots);
    }

    get fun getAccumulatedDust(): Int {
        return self.accumulatedDust;
    }

    // V3.7 getters
    get fun getAccumulatedRiseDust(): Int {
        return self.accumulatedRiseDust;
    }

    get fun getDustSweepRiseThreshold(): Int {
        return self.dustSweepRiseThreshold;
    }

    get fun getMinDurationMin(): Int {
        return self.minDurationMin;
    }

    get fun getAirdropWallet(): Address {
        return self.airdropWallet;
    }

    // V3.7.1: pending rescue queue state (publicly watchable).
    get fun getPendingRescue(): PendingPayout? {
        if (self.pendingRescueTo == null) { return null; }
        return PendingPayout { to: self.pendingRescueTo!!, amount: self.pendingRescueAmount };
    }

    get fun getPendingRescueAfter(): Int {
        return self.pendingRescueAfter;
    }

    get fun isPaused(): Bool {
        return self.paused;
    }

    get fun getOwner(): Address {
        return self.owner;
    }

    get fun getPlatformVault(): Address {
        return self.platformVault;
    }

    get fun getRiseJettonMaster(): Address {
        return self.riseJettonMaster;
    }

    get fun getRiseJettonWallet(): Address {
        return self.riseJettonWallet;
    }

    get fun getTonBalance(): Int {
        return myBalance();
    }

    // V3.7 version identifier: 3007 (= v3.7).
    get fun getVersion(): Int {
        return 3007;
    }
}
