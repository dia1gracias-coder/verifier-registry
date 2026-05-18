import "errors"
import "messages"
import "tokenomics-messages"
import "tokenomics-storage"

contract MerkleRewardVault {
    author: "100wan"
    version: "0.1.0"
    description: "HI Merkle reward vault for ecosystem, lottery, and red packets"
    storage: MerkleRewardStorage
    incomingMessages: AllowedMerkleRewardMessage
}

type AllowedMerkleRewardMessage = CreateRewardBatch | ClaimReward | SetRewardJettonWallet

type MerkleRewardBounceMessage = AskToTransfer

const MERKLE_POOL_ECOSYSTEM = 1
const MERKLE_POOL_UNIVERSAL_LOTTERY = 2
const MERKLE_POOL_RED_PACKET = 3

const ECOSYSTEM_POOL_CAP_HI = 2500000000 * 1000000000
const UNIVERSAL_LOTTERY_POOL_CAP_HI = 80000000 * 1000000000
const RED_PACKET_POOL_CAP_HI = 20000000 * 1000000000

fun onBouncedMessage(in: InMessageBounced) {
    in.bouncedBody.skipBouncedPrefix();
    val msg = lazy MerkleRewardBounceMessage.fromSlice(in.bouncedBody);

    var storage = lazy MerkleRewardStorage.load();
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
                poolType: batch.poolType,
            },
        );
    storage.claimed.delete(rewardClaimKey(pending.batchId, pending.claimant));
    storage.pendingTransfers.delete(msg.queryId);
    storage.save();
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMerkleRewardMessage.fromSlice(in.body);

    match (msg) {
        CreateRewardBatch => {
            var storage = lazy MerkleRewardStorage.load();
            val config = storage.config.load();
            assert (in.senderAddress == config.admin) throw Errors.NotAdmin;
            assert (!storage.batches.exists(msg.batchId)) throw Errors.BatchExists;
            assert (validMerkleRewardPoolType(msg.poolType)) throw Errors.InvalidPoolType;
            reserveMerkleRewardPool(mutate storage, msg.poolType, msg.totalHi);
            storage
                .batches
                .set(
                    msg.batchId,
                    {
                        root: msg.root,
                        totalHi: msg.totalHi,
                        claimedHi: 0,
                        metadataHash: msg.metadataHash,
                        poolType: msg.poolType,
                    },
                );
            storage.save();
        }

        SetRewardJettonWallet => {
            var storage = lazy MerkleRewardStorage.load();
            val config = storage.config.load();
            assert (in.senderAddress == config.admin) throw Errors.NotAdmin;
            storage.rewardJettonWallet = msg.rewardJettonWallet;
            storage.save();
        }

        ClaimReward => {
            var storage = lazy MerkleRewardStorage.load();
            assert (in.valueCoins >= ton("0.25")) throw Errors.InsufficientAttachedTon;
            val batch = storage.batches.mustGet(msg.batchId, Errors.BatchMissing);
            val key = rewardClaimKey(msg.batchId, in.senderAddress);
            assert (!storage.claimed.exists(key)) throw Errors.AlreadyClaimed;
            assert (
                rewardMerkleRoot(msg.batchId, in.senderAddress, msg.amount, msg.proof) == batch.root
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
                        poolType: batch.poolType,
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
    mutate storage: MerkleRewardStorage,
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

fun validMerkleRewardPoolType(poolType: uint8): bool {
    return poolType == MERKLE_POOL_ECOSYSTEM || poolType == MERKLE_POOL_UNIVERSAL_LOTTERY ||
    poolType == MERKLE_POOL_RED_PACKET;
}

fun reserveMerkleRewardPool(mutate storage: MerkleRewardStorage, poolType: uint8, amount: coins) {
    if (poolType == MERKLE_POOL_ECOSYSTEM) {
        assert (
            storage.ecosystemTotalHi + amount <= ECOSYSTEM_POOL_CAP_HI
        ) throw Errors.InsufficientInventory;
        storage.ecosystemTotalHi += amount;
        return;
    }
    if (poolType == MERKLE_POOL_UNIVERSAL_LOTTERY) {
        assert (
            storage.universalTotalHi + amount <= UNIVERSAL_LOTTERY_POOL_CAP_HI
        ) throw Errors.InsufficientInventory;
        storage.universalTotalHi += amount;
        return;
    }
    assert (
        storage.redPacketTotalHi + amount <= RED_PACKET_POOL_CAP_HI
    ) throw Errors.InsufficientInventory;
    storage.redPacketTotalHi += amount;
}

fun rewardClaimKey(batchId: uint64, claimant: address): uint256 {
    return beginCell().storeUint(batchId, 64).storeAddress(claimant).hash();
}

fun rewardLeaf(batchId: uint64, claimant: address, amount: coins): uint256 {
    return beginCell().storeUint(batchId, 64).storeAddress(claimant).storeCoins(amount).hash();
}

fun rewardMerkleRoot(batchId: uint64, claimant: address, amount: coins, proof: cell): uint256 {
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

get fun batch_state(batchId: uint64): (uint256, coins, coins, uint256, uint8) {
    val storage = lazy MerkleRewardStorage.load();
    val batch = storage.batches.mustGet(batchId, Errors.BatchMissing);
    return (batch.root, batch.totalHi, batch.claimedHi, batch.metadataHash, batch.poolType);
}

get fun has_claimed(batchId: uint64, claimant: address): bool {
    val storage = lazy MerkleRewardStorage.load();
    return storage.claimed.exists(rewardClaimKey(batchId, claimant));
}

get fun pool_state(): (coins, coins, coins) {
    val storage = lazy MerkleRewardStorage.load();
    return (storage.ecosystemTotalHi, storage.universalTotalHi, storage.redPacketTotalHi);
}
