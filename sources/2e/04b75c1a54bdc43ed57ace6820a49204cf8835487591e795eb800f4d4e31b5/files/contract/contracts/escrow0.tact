import "@stdlib/deploy";
import "@stdlib/ownable";

// ─── Constants ───
const FEE_BPS: Int = 100;           // 1% fee
const BPS_DENOMINATOR: Int = 10000;
const ADMIN_APPROVAL_TIMEOUT: Int = 1209600; // 14 days in seconds
const GAS_JETTON_TRANSFER: Int = ton("0.05");

// ─── Status codes ───
const STATUS_NONE: Int           = 0;
const STATUS_CREATED: Int        = 1;
const STATUS_FUNDED: Int         = 2;
const STATUS_RELEASED: Int       = 3;
const STATUS_REFUNDED: Int       = 4;
const STATUS_RESOLVED: Int       = 5;
const STATUS_CANCELLED: Int      = 6;
const STATUS_ADMIN_CLAIMED: Int  = 7;

// ─── Token type ───
const TOKEN_NATIVE: Int = 0;  // native TON
const TOKEN_JETTON: Int = 1;  // Jetton (TEP-74)

// ─── Escrow data struct ───
struct EscrowData {
    buyer: Address;
    seller: Address;
    tokenType: Int as uint8;           // 0=native TON, 1=Jetton
    jettonWallet: Address?;            // contract's Jetton Wallet address (for Jetton escrows)
    jettonMaster: Address?;            // Jetton Master address (for reference)
    amount: Int as coins;
    fundedAmount: Int as coins;
    feeAmount: Int as coins;
    sellerAmount: Int as coins;
    createdAt: Int as uint64;
    fundedAt: Int as uint64;
    deadline: Int as uint64;
    adminApprovedAt: Int as uint64;
    status: Int as uint8;
    adminApprovedRelease: Bool;
    buyerApprovedRelease: Bool;
    externalReference: String;
}

// ─── Messages ───

message CreateEscrow {
    seller: Address;
    amount: Int as coins;
    deadline: Int as uint64;
    externalReference: String;
}

message CreateJettonEscrow {
    seller: Address;
    amount: Int as coins;
    deadline: Int as uint64;
    jettonWallet: Address;
    jettonMaster: Address;
    externalReference: String;
}

message FundEscrow {
    escrowId: Int as uint64;
}

message ApproveReleaseByAdmin {
    escrowId: Int as uint64;
}

message ApproveReleaseByBuyer {
    escrowId: Int as uint64;
}

message ClaimToAdminAfterTimeout {
    escrowId: Int as uint64;
}

message RefundBuyer {
    escrowId: Int as uint64;
    amount: Int as coins;
}

message ResolveDisputeSplit {
    escrowId: Int as uint64;
    buyerAmount: Int as coins;
    sellerAmount: Int as coins;
    feeAmount: Int as coins;
}

message CancelUnfunded {
    escrowId: Int as uint64;
}

message SetFeeRecipient {
    newFeeRecipient: Address;
}

// ─── Jetton TEP-74 standard messages ───

// Opcode 0x7362d09c — notification sent by Jetton Wallet to destination
message(0x7362d09c) JettonTransferNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;               // original sender (buyer)
    forwardPayload: Slice as remaining;
}

// Opcode 0xf8a7ea5 — send Jettons from this contract's Jetton Wallet
message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

// ─── Response messages ───
message EscrowCreatedEvent {
    escrowId: Int as uint64;
    buyer: Address;
    seller: Address;
    amount: Int as coins;
    tokenType: Int as uint8;
}

// ─── Internal: forward payload for Jetton funding ───
message FundJettonPayload {
    escrowId: Int as uint64;
}

// ─── Main Contract ───

contract Escrow0 with Deployable, Ownable {
    owner: Address;
    feeRecipient: Address;
    nextEscrowId: Int as uint64;
    escrows: map<Int, EscrowData>;

    init(owner: Address, feeRecipient: Address) {
        self.owner = owner;
        self.feeRecipient = feeRecipient;
        self.nextEscrowId = 1;
    }

    // ═══════════════════════════════════════════════
    //  CREATE — native TON escrow
    // ═══════════════════════════════════════════════
    receive(msg: CreateEscrow) {
        let buyer: Address = sender();
        require(msg.seller != buyer, "Buyer cannot be seller");
        require(msg.amount > 0, "Amount must be > 0");

        let escrowId: Int = self.nextEscrowId;
        self.nextEscrowId = self.nextEscrowId + 1;

        let feeAmount: Int = (msg.amount * FEE_BPS) / BPS_DENOMINATOR;
        let sellerAmount: Int = msg.amount - feeAmount;

        let escrow: EscrowData = EscrowData{
            buyer: buyer,
            seller: msg.seller,
            tokenType: TOKEN_NATIVE,
            jettonWallet: null,
            jettonMaster: null,
            amount: msg.amount,
            fundedAmount: 0,
            feeAmount: feeAmount,
            sellerAmount: sellerAmount,
            createdAt: now(),
            fundedAt: 0,
            deadline: msg.deadline,
            adminApprovedAt: 0,
            status: STATUS_CREATED,
            adminApprovedRelease: false,
            buyerApprovedRelease: false,
            externalReference: msg.externalReference
        };

        self.escrows.set(escrowId, escrow);

        self.reply(EscrowCreatedEvent{
            escrowId: escrowId,
            buyer: buyer,
            seller: msg.seller,
            amount: msg.amount,
            tokenType: TOKEN_NATIVE
        }.toCell());
    }

    // ═══════════════════════════════════════════════
    //  CREATE — Jetton token escrow
    // ═══════════════════════════════════════════════
    receive(msg: CreateJettonEscrow) {
        let buyer: Address = sender();
        require(msg.seller != buyer, "Buyer cannot be seller");
        require(msg.amount > 0, "Amount must be > 0");

        let escrowId: Int = self.nextEscrowId;
        self.nextEscrowId = self.nextEscrowId + 1;

        let feeAmount: Int = (msg.amount * FEE_BPS) / BPS_DENOMINATOR;
        let sellerAmount: Int = msg.amount - feeAmount;

        let escrow: EscrowData = EscrowData{
            buyer: buyer,
            seller: msg.seller,
            tokenType: TOKEN_JETTON,
            jettonWallet: msg.jettonWallet,
            jettonMaster: msg.jettonMaster,
            amount: msg.amount,
            fundedAmount: 0,
            feeAmount: feeAmount,
            sellerAmount: sellerAmount,
            createdAt: now(),
            fundedAt: 0,
            deadline: msg.deadline,
            adminApprovedAt: 0,
            status: STATUS_CREATED,
            adminApprovedRelease: false,
            buyerApprovedRelease: false,
            externalReference: msg.externalReference
        };

        self.escrows.set(escrowId, escrow);

        self.reply(EscrowCreatedEvent{
            escrowId: escrowId,
            buyer: buyer,
            seller: msg.seller,
            amount: msg.amount,
            tokenType: TOKEN_JETTON
        }.toCell());
    }

    // ═══════════════════════════════════════════════
    //  FUND — native TON (send TON with this message)
    // ═══════════════════════════════════════════════
    receive(msg: FundEscrow) {
        let escrow: EscrowData = self._getEscrow(msg.escrowId);
        require(sender() == escrow.buyer, "Only buyer can fund");
        require(escrow.status == STATUS_CREATED, "Invalid status");
        require(escrow.tokenType == TOKEN_NATIVE, "Use Jetton transfer for token escrows");

        let ctx: Context = context();
        let receivedTon: Int = ctx.value;
        require(receivedTon >= escrow.amount, "Insufficient TON sent");

        escrow.fundedAmount = escrow.amount;
        escrow.fundedAt = now();
        escrow.status = STATUS_FUNDED;
        self.escrows.set(msg.escrowId, escrow);
    }

    // ═══════════════════════════════════════════════
    //  FUND — Jetton (receive via transfer_notification)
    //  Buyer sends Jettons to this contract's Jetton Wallet
    //  with forward_payload containing escrowId
    // ═══════════════════════════════════════════════
    receive(msg: JettonTransferNotification) {
        let ctx: Context = context();

        // Parse escrowId from forward payload
        let payloadSlice: Slice = msg.forwardPayload;
        let escrowId: Int = payloadSlice.loadUint(64);

        let escrow: EscrowData = self._getEscrow(escrowId);
        require(escrow.status == STATUS_CREATED, "Invalid status");
        require(escrow.tokenType == TOKEN_JETTON, "Not a Jetton escrow");
        require(msg.sender == escrow.buyer, "Only buyer can fund");

        // Validate that notification comes from the registered Jetton Wallet
        require(ctx.sender == escrow.jettonWallet!!, "Invalid Jetton wallet");

        require(msg.amount >= escrow.amount, "Insufficient Jetton amount");

        escrow.fundedAmount = escrow.amount;
        escrow.fundedAt = now();
        escrow.status = STATUS_FUNDED;
        self.escrows.set(escrowId, escrow);
    }

    // ═══════════════════════════════════════════════
    //  ADMIN APPROVE RELEASE
    // ═══════════════════════════════════════════════
    receive(msg: ApproveReleaseByAdmin) {
        self.requireOwner();
        let escrow: EscrowData = self._getEscrow(msg.escrowId);
        require(escrow.status == STATUS_FUNDED, "Invalid status");
        require(!escrow.adminApprovedRelease, "Already approved by admin");

        escrow.adminApprovedRelease = true;
        escrow.adminApprovedAt = now();
        self.escrows.set(msg.escrowId, escrow);
    }

    // ═══════════════════════════════════════════════
    //  BUYER APPROVE RELEASE → triggers payout
    // ═══════════════════════════════════════════════
    receive(msg: ApproveReleaseByBuyer) {
        let escrow: EscrowData = self._getEscrow(msg.escrowId);
        require(sender() == escrow.buyer, "Only buyer");
        require(escrow.status == STATUS_FUNDED, "Invalid status");
        require(escrow.adminApprovedRelease, "Admin must approve first");
        require(!escrow.buyerApprovedRelease, "Already approved by buyer");

        escrow.buyerApprovedRelease = true;
        escrow.status = STATUS_RELEASED;
        self.escrows.set(msg.escrowId, escrow);

        if (escrow.tokenType == TOKEN_NATIVE) {
            // Native TON release
            send(SendParameters{
                to: escrow.seller,
                value: escrow.sellerAmount,
                mode: SendPayGasSeparately,
                bounce: true,
                body: "Escrow released".asComment()
            });
            if (escrow.feeAmount > 0) {
                send(SendParameters{
                    to: self.feeRecipient,
                    value: escrow.feeAmount,
                    mode: SendPayGasSeparately,
                    bounce: true,
                    body: "Escrow fee".asComment()
                });
            }
        } else {
            // Jetton release — send tokens via Jetton Wallet
            self._sendJetton(escrow.jettonWallet!!, escrow.seller, escrow.sellerAmount);
            if (escrow.feeAmount > 0) {
                self._sendJetton(escrow.jettonWallet!!, self.feeRecipient, escrow.feeAmount);
            }
        }
    }

    // ═══════════════════════════════════════════════
    //  ADMIN CLAIM AFTER 14-DAY TIMEOUT
    // ═══════════════════════════════════════════════
    receive(msg: ClaimToAdminAfterTimeout) {
        self.requireOwner();
        let escrow: EscrowData = self._getEscrow(msg.escrowId);
        require(escrow.status == STATUS_FUNDED, "Invalid status");
        require(escrow.adminApprovedRelease, "No admin approval yet");
        require(!escrow.buyerApprovedRelease, "Buyer already approved");
        require(now() >= escrow.adminApprovedAt + ADMIN_APPROVAL_TIMEOUT, "Timeout not reached");

        escrow.status = STATUS_ADMIN_CLAIMED;
        self.escrows.set(msg.escrowId, escrow);

        if (escrow.tokenType == TOKEN_NATIVE) {
            send(SendParameters{
                to: self.feeRecipient,
                value: escrow.fundedAmount,
                mode: SendPayGasSeparately,
                bounce: true,
                body: "Admin claimed after timeout".asComment()
            });
        } else {
            self._sendJetton(escrow.jettonWallet!!, self.feeRecipient, escrow.fundedAmount);
        }
    }

    // ═══════════════════════════════════════════════
    //  REFUND BUYER
    // ═══════════════════════════════════════════════
    receive(msg: RefundBuyer) {
        self.requireOwner();
        let escrow: EscrowData = self._getEscrow(msg.escrowId);
        require(escrow.status == STATUS_FUNDED, "Invalid status");
        require(msg.amount > 0 && msg.amount <= escrow.fundedAmount, "Invalid amount");

        escrow.status = STATUS_REFUNDED;
        self.escrows.set(msg.escrowId, escrow);

        if (escrow.tokenType == TOKEN_NATIVE) {
            send(SendParameters{
                to: escrow.buyer,
                value: msg.amount,
                mode: SendPayGasSeparately,
                bounce: true,
                body: "Escrow refunded".asComment()
            });
        } else {
            self._sendJetton(escrow.jettonWallet!!, escrow.buyer, msg.amount);
        }
    }

    // ═══════════════════════════════════════════════
    //  RESOLVE DISPUTE WITH 3-WAY SPLIT
    // ═══════════════════════════════════════════════
    receive(msg: ResolveDisputeSplit) {
        self.requireOwner();
        let escrow: EscrowData = self._getEscrow(msg.escrowId);
        require(escrow.status == STATUS_FUNDED, "Invalid status");
        require(
            msg.buyerAmount + msg.sellerAmount + msg.feeAmount == escrow.fundedAmount,
            "Invalid split"
        );

        escrow.status = STATUS_RESOLVED;
        self.escrows.set(msg.escrowId, escrow);

        if (escrow.tokenType == TOKEN_NATIVE) {
            if (msg.buyerAmount > 0) {
                send(SendParameters{
                    to: escrow.buyer, value: msg.buyerAmount,
                    mode: SendPayGasSeparately, bounce: true,
                    body: "Dispute: buyer share".asComment()
                });
            }
            if (msg.sellerAmount > 0) {
                send(SendParameters{
                    to: escrow.seller, value: msg.sellerAmount,
                    mode: SendPayGasSeparately, bounce: true,
                    body: "Dispute: seller share".asComment()
                });
            }
            if (msg.feeAmount > 0) {
                send(SendParameters{
                    to: self.feeRecipient, value: msg.feeAmount,
                    mode: SendPayGasSeparately, bounce: true,
                    body: "Dispute: fee".asComment()
                });
            }
        } else {
            if (msg.buyerAmount > 0) {
                self._sendJetton(escrow.jettonWallet!!, escrow.buyer, msg.buyerAmount);
            }
            if (msg.sellerAmount > 0) {
                self._sendJetton(escrow.jettonWallet!!, escrow.seller, msg.sellerAmount);
            }
            if (msg.feeAmount > 0) {
                self._sendJetton(escrow.jettonWallet!!, self.feeRecipient, msg.feeAmount);
            }
        }
    }

    // ═══════════════════════════════════════════════
    //  CANCEL UNFUNDED (buyer only)
    // ═══════════════════════════════════════════════
    receive(msg: CancelUnfunded) {
        let escrow: EscrowData = self._getEscrow(msg.escrowId);
        require(sender() == escrow.buyer, "Only buyer");
        require(escrow.status == STATUS_CREATED, "Invalid status");

        escrow.status = STATUS_CANCELLED;
        self.escrows.set(msg.escrowId, escrow);
    }

    // ═══════════════════════════════════════════════
    //  SET FEE RECIPIENT
    // ═══════════════════════════════════════════════
    receive(msg: SetFeeRecipient) {
        self.requireOwner();
        self.feeRecipient = msg.newFeeRecipient;
    }

    // ═══════════════════════════════════════════════
    //  GETTERS
    // ═══════════════════════════════════════════════

    get fun getEscrow(escrowId: Int): EscrowData? {
        return self.escrows.get(escrowId);
    }

    get fun nextId(): Int {
        return self.nextEscrowId;
    }

    get fun getFeeRecipient(): Address {
        return self.feeRecipient;
    }

    get fun contractBalance(): Int {
        return myBalance();
    }

    // ═══════════════════════════════════════════════
    //  INTERNAL HELPERS
    // ═══════════════════════════════════════════════

    fun _getEscrow(escrowId: Int): EscrowData {
        let escrow: EscrowData? = self.escrows.get(escrowId);
        require(escrow != null, "Escrow not found");
        return escrow!!;
    }

    // Send Jettons via TEP-74 TokenTransfer to the contract's Jetton Wallet
    fun _sendJetton(jettonWallet: Address, to: Address, amount: Int) {
        send(SendParameters{
            to: jettonWallet,
            value: GAS_JETTON_TRANSFER,
            mode: SendPayGasSeparately,
            body: TokenTransfer{
                queryId: 0,
                amount: amount,
                destination: to,
                responseDestination: myAddress(),
                customPayload: null,
                forwardTonAmount: 1,
                forwardPayload: beginCell().endCell().beginParse()
            }.toCell()
        });
    }
}
