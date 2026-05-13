const OWNER_KEY_VALUE: uint8 = 1
const APPROVAL_KEY_VALUE: uint8 = 1
const DEFAULT_EXPIRY_SECONDS: uint32 = 86400
const DEFAULT_FEE_RESERVE: coins = ton("0.10")

enum Errors {
    NotOwner = 128
    InvalidMessage = 129
    InvalidOwnerCount = 130
    DuplicateOwner = 131
    InvalidThreshold = 132
    InvalidRecipient = 133
    InvalidAmount = 134
    InvalidExpiry = 135
    ProposalNotFound = 136
    ProposalNotPending = 137
    ProposalExpired = 138
    AlreadyApproved = 139
    ThresholdNotReached = 140
    AlreadyExecutable = 141
    InsufficientBalance = 142
    NotCreator = 143
}

enum ProposalStatus: uint8 {
    Pending = 0
    Executed = 1
    Cancelled = 2
}

enum ProposalViewStatus: uint8 {
    Pending = 0
    Executable = 1
    Executed = 2
    Cancelled = 3
    Expired = 4
}

struct PayoutProposal {
    id: uint64
    creator: address
    recipient: address
    amount: coins
    createdAt: uint32
    expiresAt: uint32
    status: ProposalStatus
    approvalCount: uint8
}

struct ProposalView {
    id: uint64
    creator: address
    recipient: address
    amount: coins
    createdAt: uint32
    expiresAt: uint32
    status: ProposalViewStatus
    approvalCount: uint8
}

struct Storage {
    ownerCount: uint8
    threshold: uint8
    proposalSeqno: uint64
    feeReserve: coins
    owners: map<address, uint8>
    proposals: map<uint64, Cell<PayoutProposal>>
    approvals: map<uint256, uint8>
}

fun Storage.load(): Storage {
    return Storage.fromCell(contract.getData());
}

fun Storage.save(self) {
    contract.setData(self.toCell());
}

fun Storage.assertValidConfig(self) {
    assert (self.ownerCount > 0) throw Errors.InvalidOwnerCount;
    assert (self.ownerMapCount() == self.ownerCount) throw Errors.DuplicateOwner;
    assert (self.threshold > 0) throw Errors.InvalidThreshold;
    assert (self.threshold <= self.ownerCount) throw Errors.InvalidThreshold;
}

fun Storage.ownerMapCount(self): int {
    var count = 0;
    var entry = self.owners.findFirst();
    while (entry.isFound) {
        count += 1;
        entry = self.owners.iterateNext(entry);
    }
    return count;
}

fun Storage.isOwner(self, owner: address): bool {
    return self.owners.exists(owner);
}

fun Storage.assertOwner(self, owner: address) {
    assert (self.isOwner(owner)) throw Errors.NotOwner;
}

fun approvalKey(proposalId: uint64, owner: address): uint256 {
    return beginCell().storeUint(proposalId, 64).storeAddress(owner).endCell().hash();
}

fun Storage.mustGetProposal(self, proposalId: uint64): PayoutProposal {
    val proposalCell = self.proposals.mustGet(proposalId, Errors.ProposalNotFound);
    return proposalCell.load();
}

fun PayoutProposal.isExpired(self): bool {
    return blockchain.now() >= self.expiresAt;
}

fun PayoutProposal.viewStatus(self, threshold: uint8): ProposalViewStatus {
    if (self.status == ProposalStatus.Executed) {
        return ProposalViewStatus.Executed;
    }
    if (self.status == ProposalStatus.Cancelled) {
        return ProposalViewStatus.Cancelled;
    }
    if (self.isExpired()) {
        return ProposalViewStatus.Expired;
    }
    if (self.approvalCount >= threshold) {
        return ProposalViewStatus.Executable;
    }
    return ProposalViewStatus.Pending;
}

fun PayoutProposal.toView(self, threshold: uint8): ProposalView {
    return ProposalView {
        id: self.id,
        creator: self.creator,
        recipient: self.recipient,
        amount: self.amount,
        createdAt: self.createdAt,
        expiresAt: self.expiresAt,
        status: self.viewStatus(threshold),
        approvalCount: self.approvalCount,
    };
}

struct (0x54524601) CreatePayoutProposal {
    recipient: address
    amount: coins
    expiresAt: uint32
}

struct (0x54524602) ApproveProposal {
    proposalId: uint64
}

struct (0x54524603) ExecuteProposal {
    proposalId: uint64
}

struct (0x54524604) CancelProposal {
    proposalId: uint64
}

type TreasuryMessage = CreatePayoutProposal | ApproveProposal | ExecuteProposal | CancelProposal
