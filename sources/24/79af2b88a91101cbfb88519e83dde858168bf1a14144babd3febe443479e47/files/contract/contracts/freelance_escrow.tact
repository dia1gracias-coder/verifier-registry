import "@stdlib/deploy";
import "./messages";

// ─────────────────────────────────────────────────────────────────
//  FreelanceEscrow
//
//  Participants:
//    contractor — receives periodic payments, proposes check-ins
//    client     — funds the contract, confirms check-ins, can pause/withdraw
//
//  Flow:
//    1. Deploy (contractor deploys, sets all params)
//    2. Client funds → status becomes ACTIVE
//    3. Every `period` seconds contractor claims `rate` TON
//    4. Every `checkin_interval` seconds both parties confirm a check-in
//    5. Either party can pause; client can withdraw after grace_period
//    6. Mutual close splits the current period proportionally
// ─────────────────────────────────────────────────────────────────

contract FreelanceEscrow {

    // ── Immutable params (set at deploy) ──────────────────────────
    contractor:       Address;
    client:           Address;
    clientPubkey:     Int as uint256;
    rate:             Int as coins;    // nanoTON per period
    period:           Int as uint32;   // seconds
    checkinInterval: Int as uint32;   // max seconds between check-ins
    gracePeriod:     Int as uint32;   // seconds client must wait after pause

    // ── Mutable state ─────────────────────────────────────────────
    status:           Int as uint8;    // 0=ACTIVE 1=PAUSED 2=CLOSED
    balance:          Int as coins;
    lastPayment:     Int as uint32;   // unix ts of last successful claim
    lastCheckin:     Int as uint32;   // unix ts of last confirmed check-in
    pausedAt:        Int as uint32;   // unix ts when paused (0 if not paused)

    // ── Pending check-in ──────────────────────────────────────────
    pendingHash:     Int as uint256;  // 0 = no pending check-in
    pendingProposer: Address;         // who proposed the pending check-in

    // ── Deploy ────────────────────────────────────────────────────
    init(
        contractor:       Address,
        client:           Address,
        clientPubkey:     Int,
        rate:             Int,
        period:           Int,
        checkinInterval: Int,
        gracePeriod:     Int,
    ) {
        self.contractor       = contractor;
        self.client           = client;
        self.clientPubkey     = clientPubkey;
        self.rate             = rate;
        self.period           = period;
        self.checkinInterval = checkinInterval;
        self.gracePeriod     = gracePeriod;

        self.status           = STATUS_PAUSED; // starts PAUSED until first fund
        self.balance          = 0;
        self.lastPayment     = 0;
        self.lastCheckin     = now();         // clock starts at deploy
        self.pausedAt        = now();
        self.pendingHash     = 0;
        self.pendingProposer = contractor;    // placeholder
    }

    // ── op::fund ──────────────────────────────────────────────────
    // Client sends TON (body = Fund{} or empty). Resumes if PAUSED.
    receive(msg: Fund) {
        self._onlyClient();
        require(self.status != STATUS_CLOSED, "contract is closed");
        require(context().value > 0, "send some TON");

        self.balance += context().value;

        if (self.status == STATUS_PAUSED) {
            self.status    = STATUS_ACTIVE;
            self.pausedAt = 0;
            // if this is the very first fund, anchor last_payment to now
            if (self.lastPayment == 0) {
                self.lastPayment = now();
            }
        }
    }

    // receive(msg: Deploy) {
    //     self.notify(msg.toCell())
    // }

    // Also accept plain TON transfers from client (no body)
    receive() {
        if (sender() == self.client && self.status != STATUS_CLOSED) {
            self.balance += context().value;
            if (self.status == STATUS_PAUSED) {
                self.status    = STATUS_ACTIVE;
                self.pausedAt = 0;
                if (self.lastPayment == 0) {
                    self.lastPayment = now();
                }
            }
        }
    }

    // ── op::claim ─────────────────────────────────────────────────
    // Contractor pulls one period's payment.
    receive(msg: Claim) {
        self._onlyContractor();
        require(self.status == STATUS_ACTIVE, "not active");
        require(now() >= self.lastPayment + self.period, "period not elapsed");
        require(
            now() <= self.lastCheckin + self.checkinInterval,
            "check-in overdue: client protection active"
        );
        require(self.balance >= self.rate, "insufficient balance");

        self.balance      -= self.rate;
        self.lastPayment = now();

        message(MessageParameters{
            to:    self.contractor,
            value: self.rate,
            mode:  SendIgnoreErrors,
            body:  emptyCell(),
        });
    }

    // ── op::propose_checkin ───────────────────────────────────────
    receive(msg: ProposeCheckin) {
        self._onlyParticipant();
        require(self.status == STATUS_ACTIVE, "not active");
        require(self.pendingHash == 0, "check-in already pending");
        require(msg.reportHash != 0, "hash cannot be zero");

        self.pendingHash     = msg.reportHash;
        self.pendingProposer = sender();
    }

    // ── op::confirm_checkin ───────────────────────────────────────
    receive(msg: ConfirmCheckin) {
        self._onlyParticipant();
        require(self.status == STATUS_ACTIVE, "not active");
        require(self.pendingHash != 0, "no pending check-in");
        require(sender() != self.pendingProposer, "cannot confirm own proposal");

        self.lastCheckin     = now();
        self.pendingHash     = 0;
        self.pendingProposer = self.contractor; // reset placeholder
    }

    // ── op::pause ─────────────────────────────────────────────────
    receive(msg: Pause) {
        self._onlyParticipant();
        require(self.status == STATUS_ACTIVE, "not active");

        self.status    = STATUS_PAUSED;
        self.pausedAt = now();
        // cancel any pending check-in
        self.pendingHash = 0;
    }

    // ── op::withdraw_client ───────────────────────────────────────
    // Client reclaims remaining balance after grace period expires.
    receive(msg: WithdrawClient) {
        self._onlyClient();
        require(self.status == STATUS_PAUSED, "not paused");
        require(self.pausedAt > 0, "pausedAt not set");
        require(
            now() >= self.pausedAt + self.gracePeriod,
            "grace period not elapsed"
        );

        let amount: Int = self.balance;
        self.balance    = 0;
        self.status     = STATUS_CLOSED;

        message(MessageParameters{
            to:    self.client,
            value: amount,
            mode:  SendIgnoreErrors,
            body:  emptyCell(),
        });
    }

    // ── op::close (mutual) ────────────────────────────────────────
    // Contractor sends this with client's ed25519 signature.
    // Client signs: sha256(contract_address ++ timestamp) off-chain.
    // Proportional split for the current incomplete period.
    receive(msg: Close) {
        self._onlyContractor();
        require(self.status != STATUS_CLOSED, "already closed");

        // Build the payload cell that client was supposed to sign
        let payload: Cell = beginCell()
            .storeAddress(myAddress())
            .storeUint(now(), 32)
            .endCell();

        // Verify client's ed25519 signature
        let clientPubkey: Int = self._getClientPubkey();
        require(
            checkSignature(payload.hash(), msg.clientSignature, clientPubkey),
            "invalid client signature"
        );

        // Proportional payout for elapsed time in current period
        let elapsed: Int  = now() - self.lastPayment;
        let capped: Int   = min(elapsed, self.period);
        let owed: Int     = self.rate * capped / self.period;
        let owedSafe: Int = min(owed, self.balance);
        let refund: Int   = self.balance - owedSafe;

        self.balance = 0;
        self.status  = STATUS_CLOSED;

        if (owedSafe > 0) {
            message(MessageParameters{
                to:    self.contractor,
                value: owedSafe,
                mode:  SendIgnoreErrors,
                body:  emptyCell(),
            });
        }

        if (refund > 0) {
            message(MessageParameters{
                to:    self.client,
                value: refund,
                mode:  SendIgnoreErrors,
                body:  emptyCell(),
            });
        }
    }

    // ── Get methods ───────────────────────────────────────────────

    get fun getStatus(): Int {
        return self.status;
    }

    get fun getBalance(): Int {
        return self.balance;
    }

    // Timestamp when contractor can next claim (0 if not applicable)
    get fun getNextClaimAt(): Int {
        if (self.lastPayment == 0) { return 0; }
        return self.lastPayment + self.period;
    }

    // Deadline by which a check-in must be confirmed
    get fun getCheckinDeadline(): Int {
        return self.lastCheckin + self.checkinInterval;
    }

    // Timestamp when client can withdraw after pause (0 if not paused)
    get fun getWithdrawAvailableAt(): Int {
        if (self.status != STATUS_PAUSED || self.pausedAt == 0) { return 0; }
        return self.pausedAt + self.gracePeriod;
    }

    // Pending check-in hash (0 = none)
    get fun getPendingCheckin(): Int {
        return self.pendingHash;
    }

    // Full state snapshot for frontends
    get fun getState(): ContractState {
        return ContractState{
            status:              self.status,
            balance:             self.balance,
            lastPayment:        self.lastPayment,
            lastCheckin:        self.lastCheckin,
            pausedAt:           self.pausedAt,
            pendingHash:        self.pendingHash,
            nextClaimAt:       self.getNextClaimAt(),
            checkinDeadline:    self.getCheckinDeadline(),
            withdrawAvailable:  self.getWithdrawAvailableAt(),
        };
    }

    // ── Internal helpers ──────────────────────────────────────────

    inline fun _onlyContractor() {
        require(sender() == self.contractor, "contractor only");
    }

    inline fun _onlyClient() {
        require(sender() == self.client, "client only");
    }

    inline fun _onlyParticipant() {
        require(
            sender() == self.contractor || sender() == self.client,
            "participants only"
        );
    }

    inline fun _getClientPubkey(): Int {
        return self.clientPubkey;
    }
}

// ── State snapshot struct ─────────────────────────────────────────
struct ContractState {
    status:             Int as uint8;
    balance:            Int as coins;
    lastPayment:       Int as uint32;
    lastCheckin:       Int as uint32;
    pausedAt:          Int as uint32;
    pendingHash:       Int as uint256;
    nextClaimAt:      Int as uint32;
    checkinDeadline:   Int as uint32;
    withdrawAvailable: Int as uint32;
}
