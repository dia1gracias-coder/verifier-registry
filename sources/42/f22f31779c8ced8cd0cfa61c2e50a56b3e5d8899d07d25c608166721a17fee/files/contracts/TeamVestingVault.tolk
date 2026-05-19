import "errors"
import "messages"
import "tokenomics-messages"
import "tokenomics-storage"

contract TeamVestingVault {
    author: "100wan"
    version: "0.2.0"
    description: "HI team price vesting vault"
    storage: TeamVestingStorage
    incomingMessages: AllowedTeamVestingMessage
}

type AllowedTeamVestingMessage =
    | SyncTeamPriceLevel
    | ClaimTeam
    | SetTeamJettonWallet
    | SetTeamMigrationTargetAllowed
    | SetTeamMigrationTarget
    | TransferTeamUncommittedHiToContract

type TeamBounceMessage = AskToTransfer

fun onBouncedMessage(in: InMessageBounced) {
    in.bouncedBody.skipBouncedPrefix();
    val msg = lazy TeamBounceMessage.fromSlice(in.bouncedBody);

    var storage = lazy TeamVestingStorage.load();
    var counters = storage.counters.load();
    var maps = storage.maps.load();
    val pending = maps.pendingTransfers.mustGet(msg.queryId, Errors.InvalidMessage);
    if (pending.kind == 1) {
        counters.claimedHi -= pending.amount;
    } else {
        counters.migratedHi -= pending.amount;
    }
    maps.pendingTransfers.delete(msg.queryId);
    storage.counters = counters.toCell();
    storage.maps = maps.toCell();
    storage.save();
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedTeamVestingMessage.fromSlice(in.body);

    match (msg) {
        SyncTeamPriceLevel => {
            var storage = lazy TeamVestingStorage.load();
            assert (in.senderAddress == storage.oracle) throw Errors.NotAdmin;
            assert (msg.teamConfirmedLevel >= 1) throw Errors.InvalidLevel;
            assert (msg.teamConfirmedLevel <= 4) throw Errors.InvalidLevel;
            if (msg.teamConfirmedLevel > storage.teamConfirmedLevel) {
                storage.teamConfirmedLevel = msg.teamConfirmedLevel;
                storage.save();
            }
        }

        SetTeamJettonWallet => {
            var storage = lazy TeamVestingStorage.load();
            val config = storage.config.load();
            assert (in.senderAddress == config.admin) throw Errors.NotAdmin;
            storage.teamJettonWallet = msg.teamJettonWallet;
            storage.save();
        }

        SetTeamMigrationTarget => {
            var storage = lazy TeamVestingStorage.load();
            assert (isMigrationCaller(storage, in.senderAddress)) throw Errors.NotAdmin;
            assert (
                isMigrationTargetAllowed(storage, msg.targetContract)
            ) throw Errors.MigrationTargetNotAllowed;
            storage.migrationTarget = msg.targetContract;
            storage.save();
        }

        SetTeamMigrationTargetAllowed => {
            var storage = lazy TeamVestingStorage.load();
            val config = storage.config.load();
            assert (in.senderAddress == config.admin) throw Errors.NotAdmin;
            setMigrationTargetAllowed(mutate storage, msg.targetContract, msg.allowed);
            storage.save();
        }

        TransferTeamUncommittedHiToContract => {
            var storage = lazy TeamVestingStorage.load();
            assert (isMigrationCaller(storage, in.senderAddress)) throw Errors.NotAdmin;
            assert (in.valueCoins >= ton("0.25")) throw Errors.InsufficientAttachedTon;
            val target = storage.migrationTarget;
            assert (target != null) throw Errors.InvalidMessage;
            var counters = storage.counters.load();
            val amount = msg.amount;
            assert (amount > 0) throw Errors.NoClaimableAmount;
            assert (amount <= uncommitted(storage)) throw Errors.InsufficientInventory;
            counters.migratedHi += amount;
            storage.counters = counters.toCell();
            sendTeamJettonsTo(mutate storage, target!, amount, 2, in.valueCoins);
            storage.save();
        }

        ClaimTeam => {
            var storage = lazy TeamVestingStorage.load();
            val config = storage.config.load();
            assert (in.senderAddress == config.admin) throw Errors.NotAdmin;
            assert (in.valueCoins >= ton("0.25")) throw Errors.InsufficientAttachedTon;
            var counters = storage.counters.load();
            val amount = vested(storage) - counters.claimedHi;
            assert (amount > 0) throw Errors.NoClaimableAmount;
            counters.claimedHi += amount;
            storage.counters = counters.toCell();
            sendTeamJettons(mutate storage, amount, in.valueCoins);
            storage.save();
        }

        else => {
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
        }
    }
}

fun sendTeamJettons(mutate storage: TeamVestingStorage, amount: coins, value: coins) {
    val config = storage.config.load();
    sendTeamJettonsTo(mutate storage, config.teamWallet, amount, 1, value);
}

fun sendTeamJettonsTo(
    mutate storage: TeamVestingStorage,
    recipient: address,
    amount: coins,
    kind: uint8,
    value: coins,
) {
    val config = storage.config.load();
    val teamJettonWallet = storage.teamJettonWallet;
    assert (teamJettonWallet != null) throw Errors.JettonWalletNotConfigured;
    val queryId = storage.nextQueryId;
    storage.nextQueryId += 1;
    var maps = storage.maps.load();
    maps.pendingTransfers.set(queryId, { kind, amount });
    storage.maps = maps.toCell();
    val transferMessage = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: teamJettonWallet!,
        value,
        body: AskToTransfer {
            queryId,
            jettonAmount: amount,
            transferRecipient: recipient,
            sendExcessesTo: config.admin,
            customPayload: null,
            forwardTonAmount: 0,
            forwardPayload: beginCell().storeUint(0, 1).endCell().beginParse(),
        },
    });
    transferMessage.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
}

fun isMigrationCaller(storage: TeamVestingStorage, caller: address): bool {
    val config = storage.config.load();
    val migration = config.migration.load();
    return caller == migration.migrationWallet1 || caller == migration.migrationWallet2;
}

fun isMigrationTargetAllowed(storage: TeamVestingStorage, target: address): bool {
    val maps = storage.maps.load();
    return maps.migrationAllowlist.exists(target);
}

fun setMigrationTargetAllowed(
    mutate storage: TeamVestingStorage,
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

fun vested(storage: TeamVestingStorage): coins {
    val counters = storage.counters.load();
    return counters.totalHi * storage.teamConfirmedLevel / 4;
}

fun uncommitted(storage: TeamVestingStorage): coins {
    val counters = storage.counters.load();
    return counters.totalHi - vested(storage) - counters.migratedHi;
}

get fun vesting_state(): (uint8, coins, coins) {
    val storage = lazy TeamVestingStorage.load();
    val counters = storage.counters.load();
    return (storage.teamConfirmedLevel, counters.claimedHi, vested(storage));
}
