import "errors"
import "messages"
import "tokenomics-messages"
import "tokenomics-storage"

contract EcosystemRewardVault {
    author: "100wan"
    version: "0.1.0"
    description: "HI V1 ecosystem Merkle reward vault"
    storage: EcosystemRewardStorage
    incomingMessages: AllowedRewardMessage
}

type AllowedRewardMessage = CreateRewardBatch | ClaimReward | SetRewardJettonWallet

type RewardBounceMessage = AskToTransfer

fun onBouncedMessage(in: InMessageBounced) {
    in.bouncedBody.skipBouncedPrefix();
    val msg = lazy RewardBounceMessage.fromSlice(in.bouncedBody);

    var storage = lazy EcosystemRewardStorage.load();
    val pending = storage.pendingTransfers.mustGet(msg.queryId, Errors.InvalidMessage);
    val batch = storage.batches.mustGet(pending.batchId, Errors.BatchMissing);
    storage
        .batches
        .set(
            pending.batchId,
            {
                root: batch.root,
                totalHi: batch.totalHi,
                claimedHi: batch.claimedHi - pending.amount,
                metadataHash: batch.metadataHash,
            },
        );
    storage.claimed.delete(claimKey(pending.batchId, pending.claimant));
    storage.pendingTransfers.delete(msg.queryId);
    storage.save();
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedRewardMessage.fromSlice(in.body);

    match (msg) {
        CreateRewardBatch => {
            var storage = lazy EcosystemRewardStorage.load();
            val config = storage.config.load();
            assert (in.senderAddress == config.admin) throw Errors.NotAdmin;
            assert (!storage.batches.exists(msg.batchId)) throw Errors.BatchExists;
            storage
                .batches
                .set(
                    msg.batchId,
                    {
                        root: msg.root,
                        totalHi: msg.totalHi,
                        claimedHi: 0,
                        metadataHash: msg.metadataHash,
                    },
                );
            storage.save();
        }

        SetRewardJettonWallet => {
            var storage = lazy EcosystemRewardStorage.load();
            val config = storage.config.load();
            assert (in.senderAddress == config.admin) throw Errors.NotAdmin;
            storage.rewardJettonWallet = msg.rewardJettonWallet;
            storage.save();
        }

        ClaimReward => {
            var storage = lazy EcosystemRewardStorage.load();
            assert (in.valueCoins >= ton("0.25")) throw Errors.InsufficientAttachedTon;
            val batch = storage.batches.mustGet(msg.batchId, Errors.BatchMissing);
            val key = claimKey(msg.batchId, in.senderAddress);
            assert (!storage.claimed.exists(key)) throw Errors.AlreadyClaimed;
            assert (
                merkleRoot(msg.batchId, in.senderAddress, msg.amount, msg.proof) == batch.root
            ) throw Errors.InvalidProof;
            assert (
                batch.claimedHi + msg.amount <= batch.totalHi
            ) throw Errors.InsufficientInventory;

            storage.claimed.set(key, true);
            storage
                .batches
                .set(
                    msg.batchId,
                    {
                        root: batch.root,
                        totalHi: batch.totalHi,
                        claimedHi: batch.claimedHi + msg.amount,
                        metadataHash: batch.metadataHash,
                    },
                );
            sendRewardJettons(
                mutate storage,
                msg.batchId,
                in.senderAddress,
                msg.amount,
                in.valueCoins,
            );
            storage.save();
        }

        else => {
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
        }
    }
}

fun sendRewardJettons(
    mutate storage: EcosystemRewardStorage,
    batchId: uint64,
    claimant: address,
    amount: coins,
    value: coins,
) {
    val config = storage.config.load();
    val rewardJettonWallet = storage.rewardJettonWallet;
    assert (rewardJettonWallet != null) throw Errors.JettonWalletNotConfigured;
    val queryId = storage.nextQueryId;
    storage.nextQueryId += 1;
    storage
        .pendingTransfers
        .set(
            queryId,
            {
                batchId,
                claimant,
                amount,
            },
        );
    val transferMessage = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: rewardJettonWallet!,
        value,
        body: AskToTransfer {
            queryId,
            jettonAmount: amount,
            transferRecipient: claimant,
            sendExcessesTo: config.admin,
            customPayload: null,
            forwardTonAmount: 0,
            forwardPayload: beginCell().storeUint(0, 1).endCell().beginParse(),
        },
    });
    transferMessage.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
}

fun claimKey(batchId: uint64, claimant: address): uint256 {
    return beginCell().storeUint(batchId, 64).storeAddress(claimant).hash();
}

fun rewardLeaf(batchId: uint64, claimant: address, amount: coins): uint256 {
    return beginCell().storeUint(batchId, 64).storeAddress(claimant).storeCoins(amount).hash();
}

fun merkleRoot(batchId: uint64, claimant: address, amount: coins, proof: cell): uint256 {
    var root = rewardLeaf(batchId, claimant, amount);
    var proofSlice = proof.beginParse();
    val proofLen = proofSlice.loadUint(8);
    var i = 0;
    while (i < proofLen) {
        val sibling = proofSlice.loadUint(256);
        val siblingOnLeft = proofSlice.loadBool();
        if (siblingOnLeft) {
            root = beginCell().storeUint(sibling, 256).storeUint(root, 256).hash();
        } else {
            root = beginCell().storeUint(root, 256).storeUint(sibling, 256).hash();
        }
        i += 1;
    }
    proofSlice.assertEnd();
    return root;
}

get fun batch_state(batchId: uint64): (uint256, coins, coins, uint256) {
    val storage = lazy EcosystemRewardStorage.load();
    val batch = storage.batches.mustGet(batchId, Errors.BatchMissing);
    return (batch.root, batch.totalHi, batch.claimedHi, batch.metadataHash);
}

get fun has_claimed(batchId: uint64, claimant: address): bool {
    val storage = lazy EcosystemRewardStorage.load();
    return storage.claimed.exists(claimKey(batchId, claimant));
}
