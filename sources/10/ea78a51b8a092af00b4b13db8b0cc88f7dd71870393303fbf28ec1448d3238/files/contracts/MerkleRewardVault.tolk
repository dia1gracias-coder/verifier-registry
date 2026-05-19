import "errors"
import "messages"
import "tokenomics-messages"
import "tokenomics-storage"

contract MerkleRewardVault {
    author: "100wan"
    version: "0.2.0"
    description: "HI Merkle reward vault with growth-level gates"
    storage: MerkleRewardStorage
    incomingMessages: AllowedMerkleRewardMessage
}

type AllowedMerkleRewardMessage =
    | CreateRewardBatch
    | ClaimReward
    | SetRewardJettonWallet
    | SetRewardGrowthLevel
    | SetRewardMigrationTargetAllowed
    | SetRewardMigrationTarget
    | TransferRewardUncommittedHiToContract

type MerkleRewardBounceMessage = AskToTransfer

const MERKLE_POOL_ECOSYSTEM = 1
const MERKLE_POOL_UNIVERSAL_LOTTERY = 2
const MERKLE_POOL_RED_PACKET = 3

const ECOSYSTEM_POOL_CAP_HI = 1600000000 * 1000000000
const UNIVERSAL_LOTTERY_POOL_CAP_HI = 80000000 * 1000000000
const RED_PACKET_POOL_CAP_HI = 20000000 * 1000000000

fun onBouncedMessage(in: InMessageBounced) {
    in.bouncedBody.skipBouncedPrefix();
    val msg = lazy MerkleRewardBounceMessage.fromSlice(in.bouncedBody);

    var storage = lazy MerkleRewardStorage.load();
    var counters = storage.counters.load();
    var maps = storage.maps.load();
    val pending = maps.pendingTransfers.mustGet(msg.queryId, Errors.InvalidMessage);
    if (pending.kind == 1) {
        val batch = maps.batches.mustGet(pending.batchId, Errors.BatchMissing);
        maps
            .batches
            .set(
                pending.batchId,
                {
                    root: batch.root,
                    totalHi: batch.totalHi,
                    claimedHi: batch.claimedHi - pending.amount,
                    metadataHash: batch.metadataHash,
                    poolType: batch.poolType,
                    requiredGrowthLevel: batch.requiredGrowthLevel,
                },
            );
        maps.claimed.delete(rewardClaimKey(pending.batchId, pending.claimant));
    } else {
        counters.migratedHi -= pending.amount;
    }
    maps.pendingTransfers.delete(msg.queryId);
    storage.counters = counters.toCell();
    storage.maps = maps.toCell();
    storage.save();
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMerkleRewardMessage.fromSlice(in.body);

    match (msg) {
        CreateRewardBatch => {
            var storage = lazy MerkleRewardStorage.load();
            val config = storage.config.load();
            var maps = storage.maps.load();
            assert (in.senderAddress == config.admin) throw Errors.NotAdmin;
            assert (!maps.batches.exists(msg.batchId)) throw Errors.BatchExists;
            assert (validMerkleRewardPoolType(msg.poolType)) throw Errors.InvalidPoolType;
            assert (msg.requiredGrowthLevel <= 10) throw Errors.InvalidLevel;
            reserveMerkleRewardPool(mutate storage, msg.poolType, msg.totalHi);
            maps
                .batches
                .set(
                    msg.batchId,
                    {
                        root: msg.root,
                        totalHi: msg.totalHi,
                        claimedHi: 0,
                        metadataHash: msg.metadataHash,
                        poolType: msg.poolType,
                        requiredGrowthLevel: msg.requiredGrowthLevel,
                    },
                );
            storage.maps = maps.toCell();
            storage.save();
        }

        SetRewardJettonWallet => {
            var storage = lazy MerkleRewardStorage.load();
            val config = storage.config.load();
            assert (in.senderAddress == config.admin) throw Errors.NotAdmin;
            storage.rewardJettonWallet = msg.rewardJettonWallet;
            storage.save();
        }

        SetRewardGrowthLevel => {
            var storage = lazy MerkleRewardStorage.load();
            assert (in.senderAddress == storage.oracle) throw Errors.NotAdmin;
            assert (
                msg.growthConfirmedLevel >= storage.growthConfirmedLevel
            ) throw Errors.InvalidLevel;
            assert (msg.growthConfirmedLevel <= 10) throw Errors.InvalidLevel;
            storage.growthConfirmedLevel = msg.growthConfirmedLevel;
            storage.save();
        }

        SetRewardMigrationTarget => {
            var storage = lazy MerkleRewardStorage.load();
            assert (isMigrationCaller(storage, in.senderAddress)) throw Errors.NotAdmin;
            assert (
                isMigrationTargetAllowed(storage, msg.targetContract)
            ) throw Errors.MigrationTargetNotAllowed;
            storage.migrationTarget = msg.targetContract;
            storage.save();
        }

        SetRewardMigrationTargetAllowed => {
            var storage = lazy MerkleRewardStorage.load();
            val config = storage.config.load();
            assert (in.senderAddress == config.admin) throw Errors.NotAdmin;
            setMigrationTargetAllowed(mutate storage, msg.targetContract, msg.allowed);
            storage.save();
        }

        TransferRewardUncommittedHiToContract => {
            var storage = lazy MerkleRewardStorage.load();
            assert (isMigrationCaller(storage, in.senderAddress)) throw Errors.NotAdmin;
            assert (in.valueCoins >= ton("0.25")) throw Errors.InsufficientAttachedTon;
            val target = storage.migrationTarget;
            assert (target != null) throw Errors.InvalidMessage;
            assert (msg.amount > 0) throw Errors.NoClaimableAmount;
            assert (msg.amount <= rewardUncommitted(storage)) throw Errors.InsufficientInventory;
            var counters = storage.counters.load();
            counters.migratedHi += msg.amount;
            storage.counters = counters.toCell();
            sendRewardJettons(
                mutate storage,
                0,
                target!,
                msg.amount,
                2,
                in.valueCoins,
            );
            storage.save();
        }

        ClaimReward => {
            var storage = lazy MerkleRewardStorage.load();
            var maps = storage.maps.load();
            assert (in.valueCoins >= ton("0.25")) throw Errors.InsufficientAttachedTon;
            val batch = maps.batches.mustGet(msg.batchId, Errors.BatchMissing);
            assert (
                storage.growthConfirmedLevel >= batch.requiredGrowthLevel
            ) throw Errors.InvalidLevel;
            val key = rewardClaimKey(msg.batchId, in.senderAddress);
            assert (!maps.claimed.exists(key)) throw Errors.AlreadyClaimed;
            assert (
                rewardMerkleRoot(msg.batchId, in.senderAddress, msg.amount, msg.proof) == batch.root
            ) throw Errors.InvalidProof;
            assert (
                batch.claimedHi + msg.amount <= batch.totalHi
            ) throw Errors.InsufficientInventory;

            maps.claimed.set(key, true);
            maps
                .batches
                .set(
                    msg.batchId,
                    {
                        root: batch.root,
                        totalHi: batch.totalHi,
                        claimedHi: batch.claimedHi + msg.amount,
                        metadataHash: batch.metadataHash,
                        poolType: batch.poolType,
                        requiredGrowthLevel: batch.requiredGrowthLevel,
                    },
                );
            storage.maps = maps.toCell();
            sendRewardJettons(
                mutate storage,
                msg.batchId,
                in.senderAddress,
                msg.amount,
                1,
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
    kind: uint8,
    value: coins,
) {
    val config = storage.config.load();
    val rewardJettonWallet = storage.rewardJettonWallet;
    assert (rewardJettonWallet != null) throw Errors.JettonWalletNotConfigured;
    val queryId = storage.nextQueryId;
    storage.nextQueryId += 1;
    var maps = storage.maps.load();
    maps
        .pendingTransfers
        .set(
            queryId,
            {
                kind,
                batchId,
                claimant,
                amount,
            },
        );
    storage.maps = maps.toCell();
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

fun isMigrationCaller(storage: MerkleRewardStorage, caller: address): bool {
    val config = storage.config.load();
    val migration = config.migration.load();
    return caller == migration.migrationWallet1 || caller == migration.migrationWallet2;
}

fun isMigrationTargetAllowed(storage: MerkleRewardStorage, target: address): bool {
    val maps = storage.maps.load();
    return maps.migrationAllowlist.exists(target);
}

fun setMigrationTargetAllowed(
    mutate storage: MerkleRewardStorage,
    target: address,
    allowed: bool,
) {
    var maps = storage.maps.load();
    if (allowed) {
        maps.migrationAllowlist.set(target, true);
    } else {
        maps.migrationAllowlist.delete(target);
    }
    storage.maps = maps.toCell();
}

fun validMerkleRewardPoolType(poolType: uint8): bool {
    return poolType == MERKLE_POOL_ECOSYSTEM || poolType == MERKLE_POOL_UNIVERSAL_LOTTERY ||
    poolType == MERKLE_POOL_RED_PACKET;
}

fun reserveMerkleRewardPool(mutate storage: MerkleRewardStorage, poolType: uint8, amount: coins) {
    var counters = storage.counters.load();
    assert (
        counters.ecosystemTotalHi + counters.universalTotalHi + counters.redPacketTotalHi +
        amount <=
        ECOSYSTEM_POOL_CAP_HI
    ) throw Errors.InsufficientInventory;
    if (poolType == MERKLE_POOL_ECOSYSTEM) {
        counters.ecosystemTotalHi += amount;
        storage.counters = counters.toCell();
        return;
    }
    if (poolType == MERKLE_POOL_UNIVERSAL_LOTTERY) {
        assert (
            counters.universalTotalHi + amount <= UNIVERSAL_LOTTERY_POOL_CAP_HI
        ) throw Errors.InsufficientInventory;
        counters.universalTotalHi += amount;
        storage.counters = counters.toCell();
        return;
    }
    assert (
        counters.redPacketTotalHi + amount <= RED_PACKET_POOL_CAP_HI
    ) throw Errors.InsufficientInventory;
    counters.redPacketTotalHi += amount;
    storage.counters = counters.toCell();
}

fun rewardCommitted(storage: MerkleRewardStorage): coins {
    val counters = storage.counters.load();
    return counters.ecosystemTotalHi + counters.universalTotalHi + counters.redPacketTotalHi;
}

fun rewardUncommitted(storage: MerkleRewardStorage): coins {
    val counters = storage.counters.load();
    return ECOSYSTEM_POOL_CAP_HI - rewardCommitted(storage) - counters.migratedHi;
}

fun rewardClaimKey(batchId: uint64, claimant: address): uint256 {
    return beginCell().storeUint(batchId, 64).storeAddress(claimant).hash();
}

fun rewardLeaf(batchId: uint64, claimant: address, amount: coins): uint256 {
    return beginCell().storeUint(batchId, 64).storeAddress(claimant).storeCoins(amount).hash();
}

fun rewardMerkleRoot(batchId: uint64, claimant: address, amount: coins, proof: cell): uint256 {
    var root = rewardLeaf(batchId, claimant, amount);
    root = rewardMerkleRootFromSlice(root, proof.beginParse());
    return root;
}

fun rewardMerkleRootFromSlice(root: uint256, proofSlice: RemainingBitsAndRefs): uint256 {
    var currentRoot = root;
    val hasSibling = proofSlice.loadBool();
    if (hasSibling) {
        val sibling = proofSlice.loadUint(256);
        val siblingOnLeft = proofSlice.loadBool();
        if (siblingOnLeft) {
            currentRoot = beginCell().storeUint(sibling, 256).storeUint(currentRoot, 256).hash();
        } else {
            currentRoot = beginCell().storeUint(currentRoot, 256).storeUint(sibling, 256).hash();
        }
    }
    val hasNext = proofSlice.loadBool();
    if (hasNext) {
        currentRoot = rewardMerkleRootFromSlice(currentRoot, proofSlice.loadRef().beginParse());
    }
    proofSlice.assertEnd();
    return currentRoot;
}

get fun batch_state(batchId: uint64): (
    uint256,
    coins,
    coins,
    uint256,
    uint8,
    uint8,
) {
    val storage = lazy MerkleRewardStorage.load();
    val maps = storage.maps.load();
    val batch = maps.batches.mustGet(batchId, Errors.BatchMissing);
    return (
        batch.root,
        batch.totalHi,
        batch.claimedHi,
        batch.metadataHash,
        batch.poolType,
        batch.requiredGrowthLevel,
    );
}

get fun has_claimed(batchId: uint64, claimant: address): bool {
    val storage = lazy MerkleRewardStorage.load();
    val maps = storage.maps.load();
    return maps.claimed.exists(rewardClaimKey(batchId, claimant));
}

get fun pool_state(): (coins, coins, coins, coins, uint8) {
    val storage = lazy MerkleRewardStorage.load();
    val counters = storage.counters.load();
    return (
        counters.ecosystemTotalHi,
        counters.universalTotalHi,
        counters.redPacketTotalHi,
        counters.migratedHi,
        storage.growthConfirmedLevel,
    );
}
