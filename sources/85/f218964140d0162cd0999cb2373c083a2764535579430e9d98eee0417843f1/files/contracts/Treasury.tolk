import "types"

contract Treasury {
    author: "TreasuryFlow TON"
    version: "0.1.0"
    description: "Track A Treasury-first TON payout approval prototype"
    storage: Storage
    incomingMessages: TreasuryMessage
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy TreasuryMessage.fromSlice(in.body);

    match (msg) {
        CreatePayoutProposal => {
            var storage = lazy Storage.load();
            storage.assertValidConfig();
            storage.assertOwner(in.senderAddress);
            assert (msg.amount > 0) throw Errors.InvalidAmount;
            assert (msg.expiresAt > blockchain.now()) throw Errors.InvalidExpiry;

            val proposalId = storage.proposalSeqno;
            val proposal = PayoutProposal {
                id: proposalId,
                creator: in.senderAddress,
                recipient: msg.recipient,
                amount: msg.amount,
                createdAt: blockchain.now() as uint32,
                expiresAt: msg.expiresAt,
                status: ProposalStatus.Pending,
                approvalCount: 1,
            };

            storage.proposals.set(proposalId, proposal.toCell());
            storage
                .approvals
                .set(
                    approvalKey(proposalId, in.senderAddress),
                    APPROVAL_KEY_VALUE,
                );
            storage.proposalSeqno = proposalId + 1;
            storage.save();
        }
        ApproveProposal => {
            var storage = lazy Storage.load();
            storage.assertValidConfig();
            storage.assertOwner(in.senderAddress);

            var proposal = storage.mustGetProposal(msg.proposalId);
            assert (proposal.status == ProposalStatus.Pending) throw Errors.ProposalNotPending;
            assert (!proposal.isExpired()) throw Errors.ProposalExpired;

            val key = approvalKey(msg.proposalId, in.senderAddress);
            assert (!storage.approvals.exists(key)) throw Errors.AlreadyApproved;

            storage.approvals.set(key, APPROVAL_KEY_VALUE);
            proposal.approvalCount = proposal.approvalCount + 1;
            storage.proposals.set(msg.proposalId, proposal.toCell());
            storage.save();
        }
        ExecuteProposal => {
            var storage = lazy Storage.load();
            storage.assertValidConfig();
            storage.assertOwner(in.senderAddress);

            var proposal = storage.mustGetProposal(msg.proposalId);
            assert (proposal.status == ProposalStatus.Pending) throw Errors.ProposalNotPending;
            assert (!proposal.isExpired()) throw Errors.ProposalExpired;
            assert (proposal.approvalCount >= storage.threshold) throw Errors.ThresholdNotReached;
            val availableBalance = contract.getOriginalBalance() - in.valueCoins;
            assert (
                availableBalance >= proposal.amount + storage.feeReserve
            ) throw Errors.InsufficientBalance;

            proposal.status = ProposalStatus.Executed;
            storage.proposals.set(msg.proposalId, proposal.toCell());
            storage.save();

            sendTonPayout(proposal.recipient, proposal.amount);
        }
        CancelProposal => {
            var storage = lazy Storage.load();
            storage.assertValidConfig();
            storage.assertOwner(in.senderAddress);

            var proposal = storage.mustGetProposal(msg.proposalId);
            assert (proposal.status == ProposalStatus.Pending) throw Errors.ProposalNotPending;
            assert (!proposal.isExpired()) throw Errors.ProposalExpired;
            assert (proposal.creator == in.senderAddress) throw Errors.NotCreator;
            assert (proposal.approvalCount < storage.threshold) throw Errors.AlreadyExecutable;

            proposal.status = ProposalStatus.Cancelled;
            storage.proposals.set(msg.proposalId, proposal.toCell());
            storage.save();
        }
        else => {
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
            val storage = lazy Storage.load();
            storage.assertValidConfig();
        }
    }
}

fun onBouncedMessage(_in: InMessageBounced) {}

fun sendTonPayout(recipient: address, amount: coins) {
    val payout = createMessage({
        bounce: false,
        dest: recipient,
        value: amount,
    });
    payout.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

get fun owner_count(): uint8 {
    val storage = lazy Storage.load();
    return storage.ownerCount;
}

get fun threshold(): uint8 {
    val storage = lazy Storage.load();
    return storage.threshold;
}

get fun proposal_seqno(): uint64 {
    val storage = lazy Storage.load();
    return storage.proposalSeqno;
}

get fun fee_reserve(): coins {
    val storage = lazy Storage.load();
    return storage.feeReserve;
}

get fun is_owner(owner: address): bool {
    val storage = lazy Storage.load();
    return storage.isOwner(owner);
}

get fun proposal(proposalId: uint64): ProposalView {
    val storage = lazy Storage.load();
    val proposal = storage.mustGetProposal(proposalId);
    return proposal.toView(storage.threshold);
}

get fun has_approval(proposalId: uint64, owner: address): bool {
    val storage = lazy Storage.load();
    return storage.approvals.exists(approvalKey(proposalId, owner));
}
