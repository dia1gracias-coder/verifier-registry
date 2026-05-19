import "errors"
import "messages"
import "tokenomics-messages"
import "tokenomics-storage"

contract GrowthEngine {
    author: "100wan"
    version: "0.2.0"
    description: "HI Growth Engine"
    storage: GrowthEngineStorage
    incomingMessages: AllowedGrowthEngineMessage
}

type AllowedGrowthEngineMessage =
    | BuyGrowth
    | ClaimGrowth
    | SetGrowthEnabled
    | SetGrowthConfirmedLevel
    | CloseGrowthEngine
    | SweepGrowthProjectFund
    | WithdrawGrowthTons
    | SetGrowthJettonWallet
    | SetGrowthMigrationTarget
    | TransferGrowthUncommittedHiToContract

type GrowthBounceMessage = AskToTransfer

fun onBouncedMessage(in: InMessageBounced) {
    in.bouncedBody.skipBouncedPrefix();
    val msg = lazy GrowthBounceMessage.fromSlice(in.bouncedBody);

    var storage = lazy GrowthEngineStorage.load();
    var counters = storage.counters.load();
    var maps = storage.maps.load();
    val pending = maps.pendingTransfers.mustGet(msg.queryId, Errors.InvalidMessage);

    if (pending.kind == 2) {
        counters.growthPoolTotalHi += pending.hiAmount - pending.missedHi;
        counters.growthMissedHi += pending.missedHi;
    } else {
        if (pending.kind == 3) {
            val pos = position(maps, pending.owner, storage.growthConfirmedLevel);
            maps
                .positions
                .set(
                    pending.owner,
                    {
                        totalLockedHi: pos.totalLockedHi,
                        claimedHi: pos.claimedHi - pending.hiAmount,
                        entryLevel: pos.entryLevel,
                        missedHi: pos.missedHi,
                    },
                );
            counters.growthClaimedHi -= pending.hiAmount;
        } else {
            if (pending.kind == 4) {
                val pos = position(maps, pending.owner, storage.growthConfirmedLevel);
                maps
                    .positions
                    .set(
                        pending.owner,
                        {
                            totalLockedHi: pos.totalLockedHi - pending.lockedPurchaseHi,
                            claimedHi: pos.claimedHi - pending.hiAmount,
                            entryLevel: pos.entryLevel,
                            missedHi: pos.missedHi - pending.missedHi,
                        },
                    );
                counters.growthSoldHi -= pending.lockedPurchaseHi;
                counters.growthClaimedHi -= pending.hiAmount;
                counters.growthMissedHi -= pending.missedHi;
                maps
                    .purchasedTon
                    .set(pending.owner, purchasedTon(maps, pending.owner) - pending.tonAmount);
            } else {
                if (pending.kind == 5) {
                    counters.growthMigratedHi -= pending.hiAmount;
                }
            }
        }
    }

    storage.counters = counters.toCell();
    maps.pendingTransfers.delete(msg.queryId);
    storage.maps = maps.toCell();
    storage.save();
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedGrowthEngineMessage.fromSlice(in.body);

    match (msg) {
        BuyGrowth => {
            buyGrowth(in.senderAddress, msg.tonAmount, in.valueCoins);
        }
        ClaimGrowth => {
            claimGrowth(in.senderAddress, in.valueCoins);
        }
        SetGrowthEnabled => {
            var storage = lazy GrowthEngineStorage.load();
            val config = storage.config.load();
            assert (in.senderAddress == config.admin) throw Errors.NotAdmin;
            assert (!storage.permanentlyClosed) throw Errors.SaleClosed;
            storage.growthEnabled = msg.enabled;
            storage.save();
        }
        SetGrowthConfirmedLevel => {
            var storage = lazy GrowthEngineStorage.load();
            assert (in.senderAddress == storage.oracle) throw Errors.NotAdmin;
            assert (
                msg.growthConfirmedLevel >= storage.growthConfirmedLevel
            ) throw Errors.InvalidLevel;
            assert (msg.growthConfirmedLevel <= 10) throw Errors.InvalidLevel;
            storage.growthConfirmedLevel = msg.growthConfirmedLevel;
            storage.save();
        }
        SetGrowthJettonWallet => {
            var storage = lazy GrowthEngineStorage.load();
            val config = storage.config.load();
            assert (in.senderAddress == config.admin) throw Errors.NotAdmin;
            storage.growthJettonWallet = msg.growthJettonWallet;
            storage.save();
        }
        SetGrowthMigrationTarget => {
            var storage = lazy GrowthEngineStorage.load();
            assert (isMigrationCaller(storage, in.senderAddress)) throw Errors.NotAdmin;
            storage.migrationTarget = msg.targetContract;
            storage.save();
        }
        TransferGrowthUncommittedHiToContract => {
            var storage = lazy GrowthEngineStorage.load();
            assert (isMigrationCaller(storage, in.senderAddress)) throw Errors.NotAdmin;
            assert (in.valueCoins >= ton("0.25")) throw Errors.InsufficientAttachedTon;
            val target = storage.migrationTarget;
            assert (target != null) throw Errors.InvalidMessage;
            var counters = storage.counters.load();
            assert (msg.amount > 0) throw Errors.NoClaimableAmount;
            assert (msg.amount <= growthUncommitted(counters)) throw Errors.InsufficientInventory;
            counters.growthMigratedHi += msg.amount;
            storage.counters = counters.toCell();
            sendJettons(
                mutate storage,
                target!,
                msg.amount,
                5,
                ton("0"),
                in.valueCoins,
                ton("0"),
                ton("0"),
            );
            storage.save();
        }
        CloseGrowthEngine => {
            var storage = lazy GrowthEngineStorage.load();
            val config = storage.config.load();
            assert (in.senderAddress == config.admin) throw Errors.NotAdmin;
            storage.growthEnabled = false;
            storage.permanentlyClosed = true;
            storage.save();
        }
        SweepGrowthProjectFund => {
            var storage = lazy GrowthEngineStorage.load();
            val config = storage.config.load();
            assert (in.senderAddress == config.admin) throw Errors.NotAdmin;
            assert (storage.permanentlyClosed) throw Errors.SaleClosed;
            var counters = storage.counters.load();
            val missedHi = counters.growthMissedHi;
            val amount = growthUncommitted(counters) + missedHi;
            assert (amount > 0) throw Errors.NoClaimableAmount;
            counters.growthPoolTotalHi = counters.growthSoldHi + counters.growthMigratedHi;
            counters.growthMissedHi = 0;
            storage.counters = counters.toCell();
            sendJettons(
                mutate storage,
                config.projectFundWallet,
                amount,
                2,
                ton("0"),
                ton("0.25"),
                ton("0"),
                missedHi,
            );
            storage.save();
        }
        WithdrawGrowthTons => {
            val storage = lazy GrowthEngineStorage.load();
            val config = storage.config.load();
            assert (in.senderAddress == config.admin) throw Errors.NotAdmin;
            val msgOut = createMessage({
                bounce: BounceMode.NoBounce,
                dest: config.admin,
                value: msg.amount,
                body: TopUpTons {},
            });
            msgOut.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_IGNORE_ERRORS);
        }
        else => {
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
        }
    }
}

fun buyGrowth(buyer: address, tonAmount: coins, attached: coins) {
    assert (attached >= tonAmount + ton("0.25")) throw Errors.InsufficientAttachedTon;

    var storage = lazy GrowthEngineStorage.load();
    var counters = storage.counters.load();
    var maps = storage.maps.load();
    assert (!storage.permanentlyClosed) throw Errors.SaleClosed;
    assert (storage.growthEnabled) throw Errors.PoolPaused;
    assert (tonAmount >= minPurchaseTon()) throw Errors.BelowMinimum;

    val previous = purchasedTon(maps, buyer);
    val newTotal = previous + tonAmount;
    assert (newTotal <= maxPurchaseTon()) throw Errors.WalletCapExceeded;

    val hiAmount = tonAmount * growthHiPerTon();
    assert (
        counters.growthSoldHi + hiAmount <= growthAvailableForSale(counters)
    ) throw Errors.InsufficientInventory;
    val immediateHi = hiAmount * 5 / 100;
    val missedHi = hiAmount * historicalUnlockedBps(storage.growthConfirmedLevel) / 100;
    val pos = position(maps, buyer, storage.growthConfirmedLevel);
    maps
        .positions
        .set(
            buyer,
            {
                totalLockedHi: pos.totalLockedHi + hiAmount,
                claimedHi: pos.claimedHi + immediateHi,
                entryLevel: storage.growthConfirmedLevel,
                missedHi: pos.missedHi + missedHi,
            },
        );
    counters.growthSoldHi += hiAmount;
    counters.growthClaimedHi += immediateHi;
    counters.growthMissedHi += missedHi;
    maps.purchasedTon.set(buyer, newTotal);
    storage.counters = counters.toCell();
    storage.maps = maps.toCell();
    sendJettons(
        mutate storage,
        buyer,
        immediateHi,
        4,
        tonAmount,
        attached - tonAmount,
        hiAmount,
        missedHi,
    );
    storage.save();
}

fun claimGrowth(owner: address, attached: coins) {
    assert (attached >= ton("0.25")) throw Errors.InsufficientAttachedTon;
    var storage = lazy GrowthEngineStorage.load();
    var counters = storage.counters.load();
    var maps = storage.maps.load();
    val pos = position(maps, owner, storage.growthConfirmedLevel);
    val amount = claimable(storage, pos);
    assert (amount > 0) throw Errors.NoClaimableAmount;

    maps
        .positions
        .set(
            owner,
            {
                totalLockedHi: pos.totalLockedHi,
                claimedHi: pos.claimedHi + amount,
                entryLevel: pos.entryLevel,
                missedHi: pos.missedHi,
            },
        );
    counters.growthClaimedHi += amount;
    storage.counters = counters.toCell();
    storage.maps = maps.toCell();
    sendJettons(
        mutate storage,
        owner,
        amount,
        3,
        ton("0"),
        attached,
        ton("0"),
        ton("0"),
    );
    storage.save();
}

fun sendJettons(
    mutate storage: GrowthEngineStorage,
    recipient: address,
    amount: coins,
    kind: uint8,
    tonAmount: coins,
    value: coins,
    lockedPurchaseHi: coins,
    missedHi: coins,
) {
    val config = storage.config.load();
    val growthJettonWallet = storage.growthJettonWallet;
    assert (growthJettonWallet != null) throw Errors.JettonWalletNotConfigured;
    var maps = storage.maps.load();
    val queryId = storage.nextQueryId;
    storage.nextQueryId += 1;
    maps
        .pendingTransfers
        .set(
            queryId,
            {
                kind,
                owner: recipient,
                hiAmount: amount,
                tonAmount,
                lockedPurchaseHi,
                missedHi,
            },
        );
    storage.maps = maps.toCell();
    val transferMessage = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: growthJettonWallet!,
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

fun isMigrationCaller(storage: GrowthEngineStorage, caller: address): bool {
    val config = storage.config.load();
    val migration = config.migration.load();
    return caller == migration.migrationWallet1 || caller == migration.migrationWallet2;
}

fun purchasedTon(maps: GrowthEngineMaps, buyer: address): coins {
    val found = maps.purchasedTon.get(buyer);
    return found.isFound ? found.loadValue() : 0;
}

fun position(
    maps: GrowthEngineMaps,
    owner: address,
    growthConfirmedLevel: uint8,
): PurchasePosition {
    val found = maps.positions.get(owner);
    if (found.isFound) {
        return found.loadValue();
    }
    return {
        totalLockedHi: 0,
        claimedHi: 0,
        entryLevel: growthConfirmedLevel,
        missedHi: 0,
    };
}

fun claimable(storage: GrowthEngineStorage, pos: PurchasePosition): coins {
    val confirmedBps = historicalUnlockedBps(storage.growthConfirmedLevel);
    if (confirmedBps == 0) {
        return 0;
    }
    val unlocked = pos.totalLockedHi * (5 + confirmedBps) / 100;
    return unlocked - pos.missedHi - pos.claimedHi;
}

fun historicalUnlockedBps(level: uint8): int {
    if (level == 0) {
        return 0;
    }
    if (level < 10) {
        return level * 10;
    }
    return 95;
}

fun growthAvailableForSale(counters: GrowthEngineCounters): coins {
    return counters.growthPoolTotalHi - counters.growthMigratedHi;
}

fun growthUncommitted(counters: GrowthEngineCounters): coins {
    return growthAvailableForSale(counters) - counters.growthSoldHi;
}

get fun buyer_state(owner: address): (coins, coins, uint8, coins, coins) {
    val storage = lazy GrowthEngineStorage.load();
    val maps = storage.maps.load();
    val pos = position(maps, owner, storage.growthConfirmedLevel);
    return (
        purchasedTon(maps, owner),
        pos.totalLockedHi,
        pos.entryLevel,
        pos.claimedHi,
        claimable(storage, pos),
    );
}

get fun growth_state(): (
    uint8,
    coins,
    coins,
    coins,
    coins,
    coins,
) {
    val storage = lazy GrowthEngineStorage.load();
    val counters = storage.counters.load();
    return (
        storage.growthConfirmedLevel,
        counters.growthSoldHi,
        counters.growthClaimedHi,
        counters.growthMissedHi,
        counters.growthMigratedHi,
        growthUncommitted(counters),
    );
}

fun minPurchaseTon(): coins {
    return ton("0.1");
}

fun maxPurchaseTon(): coins {
    return ton("5000");
}

fun growthHiPerTon(): int {
    return 10100;
}
