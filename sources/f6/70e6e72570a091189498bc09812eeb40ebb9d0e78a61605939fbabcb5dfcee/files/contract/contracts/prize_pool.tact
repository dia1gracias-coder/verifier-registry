import "@stdlib/deploy";

// ─────────────────────────────────────────────────────────────────────────────
//  GRAM CUP — Prize Pool (hardened)
//
//  Holds the whole TON prize pool. BALL purchases send TON straight here (with a
//  payment-nonce comment), so the pool lives in the contract — nobody can withdraw
//  it arbitrarily. Funds leave only as:
//    • the 10% house fee, AUTO-SENT to the organizer wallet on Finalize (push),
//    • winner prizes, PULLED by each winner via Claim (winner pays their own fee),
//    • an emergency sweep of leftovers to the admin, allowed only long after
//      Finalize (timelock) — so unclaimed prizes can't be stranded forever.
//
//  Guarantees against a malicious admin:
//    • cannot pay out more than the pool holds (Finalize checks total ≤ balance)
//    • commission is fixed at 1/9 of the winners' total (= 10% of the payout)
//    • cannot pay a winner more than committed, nor twice (entry deleted on claim)
//    • cannot route a winner's share elsewhere (Claim pays msg.sender only)
//    • cannot pay/sweep before the respective timelocks elapse
// ─────────────────────────────────────────────────────────────────────────────

const MIN_STORAGE: Int = ton("0.05"); // always kept on the contract for storage/gas
const COMMISSION_DEN: Int = 9;        // organizer gets winnersTotal/9 == 10% of the total payout
// Timelocks are set at deploy (init): production = 259200 (72h) claim, 864000 (10d) sweep;
// testnet dry-runs use short values so the full cycle can be exercised live.

// Admin commits the final per-winner payout table (the 90% players' split). The
// 10% house fee is computed on-chain and auto-sent — not trusted from off-chain.
message Finalize {
    distribution: map<Address, Int>; // winner wallet -> TON share (nanoton)
}
message Claim {}                      // a winner pulls their own share
message Sweep {}                      // admin recovers leftovers after the sweep timelock

struct PoolInfo {
    balance: Int as coins;
    finalized: Bool;
    claimsOpenAt: Int;
    sweepOpenAt: Int;
}

contract PrizePool with Deployable {
    admin: Address;                   // operational: signs Finalize and Sweep
    organizer: Address;               // house-fee (commission) wallet
    claimTimelock: Int as uint32;     // seconds after Finalize before winners can claim
    sweepDelay: Int as uint32;        // seconds after Finalize before admin can sweep leftovers
    finalized: Bool = false;
    claimsOpenAt: Int = 0;
    sweepOpenAt: Int = 0;
    distribution: map<Address, Int>;

    init(admin: Address, organizer: Address, claimTimelock: Int, sweepDelay: Int) {
        self.admin = admin;
        self.organizer = organizer;
        self.claimTimelock = claimTimelock;
        self.sweepDelay = sweepDelay;
    }

    // Pool funding: plain TON …
    receive() {}
    // … and TON carrying a comment (BALL purchases embed a payment nonce). Just pool it.
    receive(_: String) {}

    receive(msg: Finalize) {
        require(sender() == self.admin, "only admin");
        require(!self.finalized, "already finalized");

        let winnersTotal: Int = 0;
        foreach (addr, amount in msg.distribution) {
            require(amount > 0, "zero share");
            winnersTotal = winnersTotal + amount;
        }
        // commission = 1/9 of winners == 10% of (winners + commission)
        let commission: Int = winnersTotal / COMMISSION_DEN;
        // the pool must cover winners + commission, leaving a storage/gas buffer
        require(winnersTotal + commission + MIN_STORAGE <= myBalance(), "pool too small");

        self.distribution = msg.distribution;
        self.finalized = true;
        self.claimsOpenAt = now() + self.claimTimelock;
        self.sweepOpenAt = now() + self.sweepDelay;

        // auto-send the house fee to the organizer (full amount; gas from the buffer)
        if (commission > 0) {
            send(SendParameters{
                to: self.organizer,
                value: commission,
                mode: SendPayGasSeparately,
                bounce: false,
            });
        }
    }

    receive(msg: Claim) {
        require(self.finalized, "not finalized");
        require(now() >= self.claimsOpenAt, "timelock active");
        let who: Address = sender();
        let amount: Int? = self.distribution.get(who);
        require(amount != null, "nothing to claim");
        self.distribution.del(who); // no second claim
        // mode 0: the forward fee comes out of the prize — the winner pays their own
        // claim fee, the pool buffer is never touched.
        send(SendParameters{
            to: who,
            value: amount!!,
            mode: 0,
            bounce: false,
        });
    }

    // Emergency recovery: long after Finalize, the admin can reclaim whatever is
    // left (e.g. prizes winners never claimed) so funds aren't stranded forever.
    receive(msg: Sweep) {
        require(sender() == self.admin, "only admin");
        require(self.finalized, "not finalized");
        require(now() >= self.sweepOpenAt, "sweep timelock active");
        send(SendParameters{
            to: self.admin,
            value: 0,
            mode: SendRemainingBalance | SendIgnoreErrors,
            bounce: false,
        });
    }

    get fun claimable(addr: Address): Int {
        let a: Int? = self.distribution.get(addr);
        if (a == null) { return 0; }
        return a!!;
    }

    get fun info(): PoolInfo {
        return PoolInfo{
            balance: myBalance(),
            finalized: self.finalized,
            claimsOpenAt: self.claimsOpenAt,
            sweepOpenAt: self.sweepOpenAt,
        };
    }
}
