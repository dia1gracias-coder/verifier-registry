import "errors"
import "messages"
import "tokenomics-messages"
import "tokenomics-storage"

contract CampaignWinnerVault {
    author: "100wan"
    version: "0.2.0"
    description: "HI campaign winner growth-level reward vault"
    storage: CampaignWinnerStorage
    incomingMessages: AllowedCampaignWinnerMessage
}

type AllowedCampaignWinnerMessage =
    | RegisterCampaignWinner
    | ClaimCampaignWinner
    | SetCampaignWinnerJettonWallet
    | SetGrowthConfirmedLevel
    | SetCampaignMigrationTargetAllowed
    | SetCampaignMigrationTarget
    | TransferCampaignUncommittedHiToContract

type CampaignWinnerBounceMessage = AskToTransfer

const CAMPAIGN_WINNER_ALLOCATION_HI = 5000000 * 1000000000
const CAMPAIGN_WINNER_MAX_COUNT = 80
const CAMPAIGN_WINNER_POOL_HI = 400000000 * 1000000000

fun onBouncedMessage(in: InMessageBounced) {
    in.bouncedBody.skipBouncedPrefix();
    val msg = lazy CampaignWinnerBounceMessage.fromSlice(in.bouncedBody);

    var storage = lazy CampaignWinnerStorage.load();
    var counters = storage.counters.load();
    var maps = storage.maps.load();
    val pending = maps.pendingTransfers.mustGet(msg.queryId, Errors.InvalidMessage);
    if (pending.kind == 1) {
        val pos = maps.winners.mustGet(pending.winner, Errors.WinnerMissing);
        maps
            .winners
            .set(
                pending.winner,
                { entryLevel: pos.entryLevel, claimedHi: pos.claimedHi - pending.amount },
            );
        counters.totalClaimedHi -= pending.amount;
    } else {
        counters.migratedHi -= pending.amount;
    }
    maps.pendingTransfers.delete(msg.queryId);
    storage.counters = counters.toCell();
    storage.maps = maps.toCell();
    storage.save();
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedCampaignWinnerMessage.fromSlice(in.body);

    match (msg) {
        RegisterCampaignWinner => {
            var storage = lazy CampaignWinnerStorage.load();
            val config = storage.config.load();
            var counters = storage.counters.load();
            var maps = storage.maps.load();
            assert (in.senderAddress == config.admin) throw Errors.NotAdmin;
            assert (!maps.winners.exists(msg.winner)) throw Errors.WinnerExists;
            assert (
                counters.winnerCount < CAMPAIGN_WINNER_MAX_COUNT
            ) throw Errors.WinnerLimitExceeded;
            assert (
                campaignCommitted(storage) + CAMPAIGN_WINNER_ALLOCATION_HI + counters.migratedHi <=
                CAMPAIGN_WINNER_POOL_HI
            ) throw Errors.InsufficientInventory;
            maps
                .winners
                .set(
                    msg.winner,
                    { entryLevel: storage.growthConfirmedLevel, claimedHi: 0 },
                );
            counters.winnerCount += 1;
            storage.counters = counters.toCell();
            storage.maps = maps.toCell();
            storage.save();
        }

        SetGrowthConfirmedLevel => {
            var storage = lazy CampaignWinnerStorage.load();
            assert (in.senderAddress == storage.oracle) throw Errors.NotAdmin;
            assert (
                msg.growthConfirmedLevel > storage.growthConfirmedLevel
            ) throw Errors.InvalidLevel;
            assert (msg.growthConfirmedLevel <= 10) throw Errors.InvalidLevel;
            storage.growthConfirmedLevel = msg.growthConfirmedLevel;
            storage.save();
        }

        SetCampaignWinnerJettonWallet => {
            var storage = lazy CampaignWinnerStorage.load();
            val config = storage.config.load();
            assert (in.senderAddress == config.admin) throw Errors.NotAdmin;
            storage.winnerJettonWallet = msg.winnerJettonWallet;
            storage.save();
        }

        SetCampaignMigrationTarget => {
            var storage = lazy CampaignWinnerStorage.load();
            assert (isMigrationCaller(storage, in.senderAddress)) throw Errors.NotAdmin;
            assert (
                isMigrationTargetAllowed(storage, msg.targetContract)
            ) throw Errors.MigrationTargetNotAllowed;
            storage.migrationTarget = msg.targetContract;
            storage.save();
        }

        SetCampaignMigrationTargetAllowed => {
            var storage = lazy CampaignWinnerStorage.load();
            val config = storage.config.load();
            assert (in.senderAddress == config.admin) throw Errors.NotAdmin;
            setMigrationTargetAllowed(mutate storage, msg.targetContract, msg.allowed);
            storage.save();
        }

        TransferCampaignUncommittedHiToContract => {
            var storage = lazy CampaignWinnerStorage.load();
            assert (isMigrationCaller(storage, in.senderAddress)) throw Errors.NotAdmin;
            assert (in.valueCoins >= ton("0.25")) throw Errors.InsufficientAttachedTon;
            val target = storage.migrationTarget;
            assert (target != null) throw Errors.InvalidMessage;
            assert (
                isMigrationTargetAllowed(storage, target!)
            ) throw Errors.MigrationTargetNotAllowed;
            var counters = storage.counters.load();
            assert (msg.amount > 0) throw Errors.NoClaimableAmount;
            assert (msg.amount <= campaignUncommitted(storage)) throw Errors.InsufficientInventory;
            counters.migratedHi += msg.amount;
            storage.counters = counters.toCell();
            sendWinnerJettons(mutate storage, target!, msg.amount, 2, in.valueCoins);
            storage.save();
        }

        ClaimCampaignWinner => {
            var storage = lazy CampaignWinnerStorage.load();
            var counters = storage.counters.load();
            var maps = storage.maps.load();
            assert (in.valueCoins >= ton("0.25")) throw Errors.InsufficientAttachedTon;
            val pos = maps.winners.mustGet(in.senderAddress, Errors.WinnerMissing);
            val amount = winnerClaimable(storage.growthConfirmedLevel, pos);
            assert (amount > 0) throw Errors.NoClaimableAmount;
            maps
                .winners
                .set(
                    in.senderAddress,
                    { entryLevel: pos.entryLevel, claimedHi: pos.claimedHi + amount },
                );
            counters.totalClaimedHi += amount;
            storage.counters = counters.toCell();
            storage.maps = maps.toCell();
            sendWinnerJettons(mutate storage, in.senderAddress, amount, 1, in.valueCoins);
            storage.save();
        }

        else => {
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
        }
    }
}

fun sendWinnerJettons(
    mutate storage: CampaignWinnerStorage,
    recipient: address,
    amount: coins,
    kind: uint8,
    value: coins,
) {
    val config = storage.config.load();
    val winnerJettonWallet = storage.winnerJettonWallet;
    assert (winnerJettonWallet != null) throw Errors.JettonWalletNotConfigured;
    val queryId = storage.nextQueryId;
    storage.nextQueryId += 1;
    var maps = storage.maps.load();
    maps
        .pendingTransfers
        .set(
            queryId,
            {
                kind,
                winner: recipient,
                amount,
            },
        );
    storage.maps = maps.toCell();
    val transferMessage = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: winnerJettonWallet!,
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

fun isMigrationCaller(storage: CampaignWinnerStorage, caller: address): bool {
    val config = storage.config.load();
    val migration = config.migration.load();
    return caller == migration.migrationWallet1 || caller == migration.migrationWallet2;
}

fun isMigrationTargetAllowed(storage: CampaignWinnerStorage, target: address): bool {
    val maps = storage.maps.load();
    return maps.migrationAllowlist.exists(target);
}

fun setMigrationTargetAllowed(
    mutate storage: CampaignWinnerStorage,
    target: address,
    allowed: bool,
) {
    var maps = storage.maps.load();
    if (allowed) {
        maps.migrationAllowlist.set(target, true);
    } else {
        maps.migrationAllowlist.delete(target);
        if (storage.migrationTarget != null && storage.migrationTarget! == target) {
            storage.migrationTarget = null;
        }
    }
    storage.maps = maps.toCell();
}

fun campaignCommitted(storage: CampaignWinnerStorage): coins {
    val counters = storage.counters.load();
    return (counters.winnerCount as int) * CAMPAIGN_WINNER_ALLOCATION_HI;
}

fun campaignUncommitted(storage: CampaignWinnerStorage): coins {
    val counters = storage.counters.load();
    return CAMPAIGN_WINNER_POOL_HI - campaignCommitted(storage) - counters.migratedHi;
}

fun winnerClaimable(growthConfirmedLevel: uint8, pos: CampaignWinnerPosition): coins {
    val unlockedBps = winnerTotalUnlockedBps(growthConfirmedLevel) -
    winnerMissedUnlockedBps(pos.entryLevel);
    val unlocked = CAMPAIGN_WINNER_ALLOCATION_HI * unlockedBps / 100;
    return unlocked - pos.claimedHi;
}

fun winnerTotalUnlockedBps(level: uint8): uint8 {
    if (level == 0) {
        return 5;
    }
    if (level >= 10) {
        return 100;
    }
    return 5 + level * 10;
}

fun winnerMissedUnlockedBps(level: uint8): uint8 {
    return level == 0 ? 0 : winnerTotalUnlockedBps(level);
}

get fun winner_state(winner: address): (bool, uint8, coins, coins) {
    val storage = lazy CampaignWinnerStorage.load();
    val maps = storage.maps.load();
    val found = maps.winners.get(winner);
    if (!found.isFound) {
        return (false, storage.growthConfirmedLevel, 0, 0);
    }
    val pos = found.loadValue();
    return (
        true,
        pos.entryLevel,
        pos.claimedHi,
        winnerClaimable(storage.growthConfirmedLevel, pos),
    );
}

get fun vault_state(): (uint8, uint16, coins, coins) {
    val storage = lazy CampaignWinnerStorage.load();
    val counters = storage.counters.load();
    return (
        storage.growthConfirmedLevel,
        counters.winnerCount,
        counters.totalClaimedHi,
        counters.migratedHi,
    );
}

get fun claimable(winner: address): coins {
    val storage = lazy CampaignWinnerStorage.load();
    val maps = storage.maps.load();
    val pos = maps.winners.mustGet(winner, Errors.WinnerMissing);
    return winnerClaimable(storage.growthConfirmedLevel, pos);
}

get fun growth_confirmed_level(): uint8 {
    val storage = lazy CampaignWinnerStorage.load();
    return storage.growthConfirmedLevel;
}
