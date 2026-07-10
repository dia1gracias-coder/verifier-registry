import "@stdlib/ownable";
import "@stdlib/deploy";
import "./imports/staking.message";

// ============================================================
// StakingVault — $1 jetton staking, "thin vault" model.
// ------------------------------------------------------------
// On-chain state is intentionally small: custody of $1 (principal pool + reward treasury), a
//   per-user replay nonce, the backend signer key, and a few config/counters. In-flight payout
//   records (pendingPayouts) exist only for bounce rollback; the owner prunes settled ones
//   (PrunePayout) — they don't clear automatically (no forge-proof on-chain "success" signal).
//
// Everything data-heavy (positions, plan snapshot at stake time, lock/maturity,
// 24h early-unstake, forfeit, accrual, auto-compound) is OFF-CHAIN in the backend,
// which is the source of truth and signs each payout. The immutable on-chain tx
// history (indexed by the backend crawler) is the audit log.
//
// Trust model: the backend + its signer key are trusted to enforce staking rules
// and to eventually sign valid withdrawals. Funds are only ever movable to the
// exact `user` a signature names, and each nonce is single-use.
// ============================================================

const MIN_GAS: Int = ton("0.08");        // gas to attach to a withdraw
const SIG_BITS: Int = 512;               // Ed25519 signature length
const TON_RESERVE: Int = ton("0.1");     // keep for storage rent

contract StakingVault with Deployable, Ownable {
    owner: Address;
    jettonWallet: Address?;               // the vault's own $1 jetton wallet (set post-deploy)
    rewardSignerPublicKey: Int as uint256 = 0; // backend Ed25519 pubkey for payouts; 0 = withdrawals blocked
    stakeSignerPublicKey: Int as uint256 = 0;  // backend Ed25519 pubkey for stake vouchers; 0 = stakes blocked
    minStake: Int as coins = 10000000;    // 0.01 $1 (9 decimals) — flat, all plans
    paused: Bool = false;

    // Obligation counters (aggregate, fixed-size)
    totalStakedPrincipal: Int as coins = 0; // sum of active principal held for users
    rewardTreasury: Int as coins = 0;       // reward pool the owner funded (kept separate)

    // Defense-in-depth: max principal+reward a single withdraw may release (0 = unlimited). (C6)
    maxWithdrawPerTx: Int as coins = 0;

    // Replay protection: per-user strictly-increasing nonce (one small int per user). (C8)
    lastNonce: map<Address, Int>;

    // Global, unique payout id — used as the TokenTransfer queryId AND the pendingPayouts key,
    // so two users sharing the same per-user nonce can't collide. (C1)
    payoutSeq: Int as uint64 = 0;

    // In-flight payouts, keyed by the global payoutSeq, for bounce rollback.
    pendingPayouts: map<Int, PayoutRecord>;

    // Un-stakeable deposits (below min / bad voucher / paused) credited to the sender to PULL back
    // via ClaimStray — pull instead of push, so a deposit can never strand and a bounced refund can
    // never collide with a payout's queryId. (E1 + E2)
    strayCredit: map<Address, Int as coins>;

    init() {
        self.owner = sender();
    }

    // A standards-compliant EMPTY jetton forward_payload: single Either bit (0 = inline, empty).
    // Governed $1/USDT wallets strictly parse forward_payload:(Either Cell ^Cell); a malformed
    // prefix would underflow (exit 9), so we always send this exact shape.
    fun emptyForwardPayload(): Slice {
        return beginCell().storeUint(0, 1).endCell().asSlice();
    }

    fun sendJetton(to: Address, amount: Int, queryId: Int) {
        message(MessageParameters{
            to: self.jettonWallet!!,
            value: ton("0.05"),
            mode: SendPayGasSeparately,
            body: TokenTransfer{
                queryId: queryId,
                amount: amount,
                destination: to,
                response_destination: myAddress(), // excess TON returns to the vault, not the payee (F2)
                custom_payload: null,
                forward_ton_amount: ton("0.01"),
                forward_payload: self.emptyForwardPayload()
            }.toCell()
        });
    }

    // Credit an un-stakeable deposit to the sender for later ClaimStray (pull, never push). (E1+E2)
    fun creditStray(addr: Address, amount: Int) {
        let cur: Int? = self.strayCredit.get(addr);
        self.strayCredit.set(addr, (cur == null ? 0 : cur!!) + amount);
    }

    // Refund path: carry the REMAINING inbound TON (SendRemainingValue) instead of spending the
    // vault's own balance, so dust-stake spam can't drain the vault's gas. (C3)
    fun refundJetton(to: Address, amount: Int, queryId: Int) {
        message(MessageParameters{
            to: self.jettonWallet!!,
            value: 0,
            mode: SendRemainingValue,
            body: TokenTransfer{
                queryId: queryId,
                amount: amount,
                destination: to,
                response_destination: to,
                custom_payload: null,
                forward_ton_amount: 0,
                forward_payload: self.emptyForwardPayload()
            }.toCell()
        });
    }

    // ================= ADMIN ================= //

    // NOTE: do not rotate the jetton wallet while payouts are in flight — a bounce from the OLD
    // wallet would fail the sender check in bounced() and its rollback would be lost.
    receive(msg: SetStakingJettonWallet) { self.requireOwner(); self.jettonWallet = msg.jettonWallet; }
    receive(msg: SetRewardSigner)        { self.requireOwner(); self.rewardSignerPublicKey = msg.publicKey; }
    receive(msg: SetStakeSigner)         { self.requireOwner(); self.stakeSignerPublicKey = msg.publicKey; }
    receive(msg: SetMinStake)            { self.requireOwner(); require(msg.amount > 0, "min > 0"); self.minStake = msg.amount; }
    receive(msg: SetMaxWithdrawPerTx)    { self.requireOwner(); require(msg.amount >= 0, "cap >= 0"); self.maxWithdrawPerTx = msg.amount; }
    receive(msg: StakingPause)           { self.requireOwner(); self.paused = true; }
    receive(msg: StakingUnpause)         { self.requireOwner(); self.paused = false; }

    // Owner reclaims UNUSED reward treasury only (e.g. over-funded rewards). Capped by rewardTreasury
    // and decrements it, so this can NEVER touch staked principal — user principal is not withdrawable
    // by the owner through any path. (C5: closes the owner rug-pull vector on principal.)
    receive(msg: DefundTreasury) {
        self.requireOwner();
        require(self.jettonWallet != null, "Wallet not set");
        require(msg.amount > 0, "Amount must be > 0");
        require(msg.amount <= self.rewardTreasury, "Exceeds reward treasury");
        self.rewardTreasury -= msg.amount;
        self.sendJetton(msg.to, msg.amount, 0);
    }

    // Emergency: recover stuck TON, keeping a storage reserve.
    receive(msg: WithdrawStakingTon) {
        self.requireOwner();
        let available: Int = myBalance() - TON_RESERVE;
        require(available > 0, "No TON available");
        require(msg.amount <= available, "Exceeds available");
        message(MessageParameters{
            to: self.owner,
            value: msg.amount,
            mode: SendPayGasSeparately,
            body: "Staking TON withdraw".asComment()
        });
    }

    // ================= RECEIVE $1 (stake / fund) ================= //
    // op=1 stake — carries a BACKEND-SIGNED "voucher" {planId, apyBps, lockDays, deadline} verified
    //   on-chain, so the exact plan terms are recorded IMMUTABLY in this tx and can NEVER be forged
    //   by the user nor lost (re-indexable from chain even if the DB is wiped). (Level-2 voucher)
    // op=2 fund treasury (owner only).
    receive(msg: StakeNotification) {
        require(self.jettonWallet != null && sender() == self.jettonWallet!!, "Unknown jetton wallet");

        // Parse forward_payload: Either bit, then op(32). Guard every read.
        let op: Int = 0;
        let payload: Slice = msg.forward_payload;
        if (payload.bits() >= 1) {
            let isRef: Int = payload.loadUint(1);
            if (isRef == 1 && payload.refs() >= 1) {
                payload = payload.loadRef().beginParse();
            }
            if (payload.bits() >= 32) {
                op = payload.loadUint(32);
            }
        }

        if (op == 2) {
            // Treasury funding — only the owner may add to the reward pool. A non-owner op=2 deposit is
            // CREDITED for pull-back (ClaimStray), never reverted: the jetton is already credited and this
            // notification is non-bounceable, so a revert would strand the funds with no recovery. (F3)
            if (msg.from != self.owner) {
                self.creditStray(msg.from, msg.amount);
                return;
            }
            self.rewardTreasury += msg.amount;
            return;
        }

        // ---- Stake: verify the backend voucher, else refund (never count a bad/forged stake). ----
        // Voucher layout after op: planId(32) apyBps(16) lockDays(32) deadline(64) + ref -> sig(512).
        // Any structural problem, missing signer, expiry, bad signature, pause, or below-min → refund.
        if (op != 1
            || self.stakeSignerPublicKey == 0
            || self.paused
            || msg.amount < self.minStake
            || payload.bits() < 144
            || payload.refs() < 1) {
            self.creditStray(msg.from, msg.amount);
            return;
        }
        let planId: Int = payload.loadUint(32);
        let apyBps: Int = payload.loadUint(16);
        let lockDays: Int = payload.loadUint(32);
        let voucherDeadline: Int = payload.loadUint(64);
        let sig: Slice = payload.loadRef().beginParse();

        // voucher hash = (vault | planId | apyBps | lockDays | deadline); NOT bound to user (a plan
        // voucher is reusable by anyone until its deadline). Bound to this vault to block cross-use.
        let voucherHash: Int = beginCell()
            .storeAddress(myAddress())
            .storeUint(planId, 32)
            .storeUint(apyBps, 16)
            .storeUint(lockDays, 32)
            .storeUint(voucherDeadline, 64)
            .endCell()
            .hash();
        if (sig.bits() != SIG_BITS
            || now() > voucherDeadline
            || !checkSignature(voucherHash, sig, self.stakeSignerPublicKey)) {
            self.creditStray(msg.from, msg.amount);
            return;
        }

        // Accepted: terms are authentic + recorded on-chain in this tx (planId/apyBps/lockDays/deadline).
        self.totalStakedPrincipal += msg.amount;
        // (backend indexes this tx to build the Position; on-chain data is the durable source of truth)
    }

    // ================= BACKEND-SIGNED PAYOUT ================= //
    receive(msg: StakingWithdraw) {
        let ctx: Context = context();
        require(ctx.value >= MIN_GAS, "Attach at least 0.08 TON for gas");
        require(!self.paused, "Paused");
        require(self.jettonWallet != null, "Wallet not set");
        require(self.rewardSignerPublicKey != 0, "Signer not set");
        let sig: Slice = msg.signature.beginParse();
        require(sig.bits() == SIG_BITS, "Invalid signature length");
        require(now() <= msg.deadline, "Signature expired");
        require(msg.principal >= 0 && msg.reward >= 0, "Negative amount");
        require(msg.principal + msg.reward > 0, "Nothing to withdraw");

        // Per-user strictly-increasing nonce (replay guard). Using ">" (not "== prev+1") lets the
        // backend pick any higher nonce — gaps and bounce-reissues don't strand a signature.
        // Concurrent withdrawals for the SAME user must still be serialized backend-side. (C8)
        let prev: Int? = self.lastNonce.get(msg.user);
        let prevNonce: Int = (prev == null) ? 0 : prev!!;
        require(msg.nonce > prevNonce, "Nonce must increase");

        // Defense-in-depth cap on a single payout (0 = unlimited). (C6)
        if (self.maxWithdrawPerTx > 0) {
            require(msg.principal + msg.reward <= self.maxWithdrawPerTx, "Exceeds max per tx");
        }

        // Solvency guards against the aggregate counters.
        require(self.totalStakedPrincipal >= msg.principal, "Principal exceeds staked");
        require(self.rewardTreasury >= msg.reward, "Insufficient reward treasury");

        // Verify the backend signature over (vault | user | principal | reward | nonce | deadline).
        let payloadHash: Int = beginCell()
            .storeAddress(myAddress())
            .storeAddress(msg.user)
            .storeCoins(msg.principal)
            .storeCoins(msg.reward)
            .storeUint(msg.nonce, 64)
            .storeUint(msg.deadline, 64)
            .endCell()
            .hash();
        require(checkSignature(payloadHash, sig, self.rewardSignerPublicKey), "Invalid signature");

        // Effects before interaction (CEI).
        self.lastNonce.set(msg.user, msg.nonce);
        self.totalStakedPrincipal -= msg.principal;
        self.rewardTreasury -= msg.reward;

        // Use a GLOBAL unique id as queryId + pendingPayouts key so per-user nonces can't collide. (C1)
        self.payoutSeq += 1;
        let pid: Int = self.payoutSeq;
        self.pendingPayouts.set(pid, PayoutRecord{
            user: msg.user,
            principal: msg.principal,
            reward: msg.reward
        });

        // Pay principal + reward in a single jetton transfer; queryId = pid for bounce/excess matching.
        self.sendJetton(msg.user, msg.principal + msg.reward, pid);
    }

    // Roll the counters back if the payout transfer bounced. A genuine bounce can only originate from
    // our own jetton wallet (the payout's counterparty); requiring that is the sole authenticated way
    // a pending record is reversed. (F1/F2 — was previously also clearable via a forgeable excess.)
    bounced(src: bounced<TokenTransfer>) {
        if (self.jettonWallet == null || sender() != self.jettonWallet!!) { return; }
        let rec: PayoutRecord? = self.pendingPayouts.get(src.queryId);
        if (rec != null) {
            self.totalStakedPrincipal += rec!!.principal;
            self.rewardTreasury += rec!!.reward;
            self.pendingPayouts.set(src.queryId, null);
        }
    }

    // Absorb the excess TON returned after a successful payout (kept for storage rent). It does NOT
    // clear pendingPayouts: a real payout's excess comes from the PAYEE's wallet, and anyone can make
    // the vault's own wallet emit an excess with a chosen queryId, so clearing here is forgeable and
    // could suppress a bounce rollback. Settled records are cleared by the owner via PrunePayout. (F2)
    receive(msg: TokenExcesses) {}

    // Owner escape hatch to clear a stale pending record if neither excess nor bounce arrived. (C9)
    receive(msg: PrunePayout) {
        self.requireOwner();
        self.pendingPayouts.set(msg.id, null);
    }

    // User pulls back a credited (un-stakeable) deposit — the sender pays gas, so the refund can
    // never strand the vault's TON and never collides with a payout queryId. (E1+E2)
    receive(msg: ClaimStray) {
        require(context().value >= ton("0.05"), "Attach at least 0.05 TON for gas");
        require(self.jettonWallet != null, "Wallet not set");
        let amt: Int? = self.strayCredit.get(sender());
        require(amt != null && amt!! > 0, "No stray credit");
        self.strayCredit.set(sender(), 0);              // effect before interaction (CEI)
        self.refundJetton(sender(), amt!!, 0);          // queryId 0 = reserved, never a payoutSeq
    }

    // ================= GETTERS ================= //

    // One-shot snapshot for the admin dashboard / monitor (avoids many RPC calls).
    get fun get_vault_state(): VaultState {
        return VaultState{
            owner: self.owner,
            jettonWallet: self.jettonWallet,
            rewardSigner: self.rewardSignerPublicKey,
            stakeSigner: self.stakeSignerPublicKey,
            paused: self.paused,
            minStake: self.minStake,
            totalStakedPrincipal: self.totalStakedPrincipal,
            rewardTreasury: self.rewardTreasury,
            tonBalance: myBalance()
        };
    }

    // TON left in the contract — alert before it can't afford gas to send payouts.
    get fun get_ton_balance(): Int { return myBalance(); }

    // Ready to accept stakes / process withdrawals?
    get fun is_operational(): Bool {
        return self.jettonWallet != null
            && self.rewardSignerPublicKey != 0
            && self.stakeSignerPublicKey != 0
            && !self.paused;
    }

    // Inspect an in-flight payout (present = still unresolved / possibly bounced) for reconciliation.
    get fun get_pending_payout(nonce: Int): PayoutRecord? { return self.pendingPayouts.get(nonce); }

    // Credited un-stakeable deposit the user can pull via ClaimStray.
    get fun get_stray_credit(user: Address): Int {
        let c: Int? = self.strayCredit.get(user);
        return c == null ? 0 : c!!;
    }

    get fun get_owner(): Address { return self.owner; }

    get fun getJettonWallet(): Address? { return self.jettonWallet; }
    get fun get_min_stake(): Int { return self.minStake; }
    get fun is_paused(): Bool { return self.paused; }
    get fun get_reward_signer(): Int { return self.rewardSignerPublicKey; }
    get fun get_stake_signer(): Int { return self.stakeSignerPublicKey; }

    // Next nonce the backend must sign for a given user.
    get fun next_nonce(user: Address): Int {
        let n: Int? = self.lastNonce.get(user);
        return ((n == null) ? 0 : n!!) + 1;
    }

    get fun get_treasury_stats(): Cell {
        return beginCell()
            .storeCoins(self.totalStakedPrincipal)
            .storeCoins(self.rewardTreasury)
            .endCell();
    }

    get fun total_staked_principal(): Int { return self.totalStakedPrincipal; }
    get fun reward_treasury(): Int { return self.rewardTreasury; }
    get fun get_max_withdraw_per_tx(): Int { return self.maxWithdrawPerTx; }
    get fun get_payout_seq(): Int { return self.payoutSeq; }
}
