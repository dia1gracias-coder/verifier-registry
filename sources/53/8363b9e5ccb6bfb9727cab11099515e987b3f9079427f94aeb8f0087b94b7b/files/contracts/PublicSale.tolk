import "errors"
import "messages"
import "tokenomics-messages"
import "tokenomics-storage"

contract PublicSale {
    author: "100wan"
    version: "0.1.0"
    description: "HI V1 public sale"
    storage: PublicSaleStorage
    incomingMessages: AllowedPublicSaleMessage
}

type AllowedPublicSaleMessage =
    | BuyInstant
    | BuyLocked
    | ClaimLocked
    | SetPoolEnabled
    | SetConfirmedLevel
    | CloseSale
    | SweepProjectFund
    | WithdrawSaleTons
    | SetSaleJettonWallet

type SaleBounceMessage = AskToTransfer

fun onBouncedMessage(in: InMessageBounced) {
    in.bouncedBody.skipBouncedPrefix();
    val msg = lazy SaleBounceMessage.fromSlice(in.bouncedBody);

    var storage = lazy PublicSaleStorage.load();
    var counters = storage.counters.load();
    var maps = storage.maps.load();
    val pending = maps.pendingTransfers.mustGet(msg.queryId, Errors.InvalidMessage);

    if (pending.kind == 1) {
        counters.instantSoldHi -= pending.hiAmount;
        maps.purchasedTon.set(pending.owner, purchasedTon(maps, pending.owner) - pending.tonAmount);
    } else {
        if (pending.kind == 3) {
            val pos = position(maps, pending.owner, storage.confirmedLevel);
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
            counters.lockedClaimedHi -= pending.hiAmount;
        }
    }

    storage.counters = counters.toCell();
    maps.pendingTransfers.delete(msg.queryId);
    storage.maps = maps.toCell();
    storage.save();
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedPublicSaleMessage.fromSlice(in.body);

    match (msg) {
        BuyInstant => {
            buy(in.senderAddress, msg.tonAmount, in.valueCoins, true);
        }
        BuyLocked => {
            buy(in.senderAddress, msg.tonAmount, in.valueCoins, false);
        }
        ClaimLocked => {
            claimLocked(in.senderAddress, in.valueCoins);
        }
        SetPoolEnabled => {
            var storage = lazy PublicSaleStorage.load();
            val config = storage.config.load();
            assert (in.senderAddress == config.admin) throw Errors.NotAdmin;
            assert (!storage.permanentlyClosed) throw Errors.SaleClosed;
            if (msg.instantPool) {
                storage.instantSaleEnabled = msg.enabled;
            } else {
                storage.lockedSaleEnabled = msg.enabled;
            }
            storage.save();
        }
        SetConfirmedLevel => {
            var storage = lazy PublicSaleStorage.load();
            assert (in.senderAddress == storage.oracle) throw Errors.NotAdmin;
            assert (msg.confirmedLevel >= storage.confirmedLevel) throw Errors.InvalidLevel;
            assert (msg.confirmedLevel <= 10) throw Errors.InvalidLevel;
            storage.confirmedLevel = msg.confirmedLevel;
            storage.save();
        }
        SetSaleJettonWallet => {
            var storage = lazy PublicSaleStorage.load();
            val config = storage.config.load();
            assert (in.senderAddress == config.admin) throw Errors.NotAdmin;
            storage.saleJettonWallet = msg.saleJettonWallet;
            storage.save();
        }
        CloseSale => {
            var storage = lazy PublicSaleStorage.load();
            val config = storage.config.load();
            assert (in.senderAddress == config.admin) throw Errors.NotAdmin;
            storage.instantSaleEnabled = false;
            storage.lockedSaleEnabled = false;
            storage.permanentlyClosed = true;
            storage.save();
        }
        SweepProjectFund => {
            var storage = lazy PublicSaleStorage.load();
            val config = storage.config.load();
            assert (in.senderAddress == config.admin) throw Errors.NotAdmin;
            assert (storage.permanentlyClosed) throw Errors.SaleClosed;
            var counters = storage.counters.load();
            val amount = instantUnsold(counters) + lockedUnsold(counters) + counters.lockedMissedHi;
            assert (amount > 0) throw Errors.NoClaimableAmount;
            counters.instantPoolTotalHi = counters.instantSoldHi;
            counters.lockedPoolTotalHi = counters.lockedSoldHi;
            counters.lockedMissedHi = 0;
            storage.counters = counters.toCell();
            sendJettons(
                mutate storage,
                config.projectFundWallet,
                amount,
                2,
                ton("0"),
                ton("0.25"),
            );
            storage.save();
        }
        WithdrawSaleTons => {
            val storage = lazy PublicSaleStorage.load();
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

fun buy(buyer: address, tonAmount: coins, attached: coins, instantPool: bool) {
    assert (attached >= tonAmount + ton("0.25")) throw Errors.InsufficientAttachedTon;

    var storage = lazy PublicSaleStorage.load();
    var counters = storage.counters.load();
    var maps = storage.maps.load();
    assert (!storage.permanentlyClosed) throw Errors.SaleClosed;
    assert (tonAmount >= minPurchaseTon()) throw Errors.BelowMinimum;

    val previous = purchasedTon(maps, buyer);
    val newTotal = previous + tonAmount;
    assert (newTotal <= maxPurchaseTon()) throw Errors.WalletCapExceeded;

    if (instantPool) {
        assert (storage.instantSaleEnabled) throw Errors.PoolPaused;
        val hiAmount = tonAmount * instantHiPerTon();
        assert (
            counters.instantSoldHi + hiAmount <= counters.instantPoolTotalHi
        ) throw Errors.InsufficientInventory;
        counters.instantSoldHi += hiAmount;
        maps.purchasedTon.set(buyer, newTotal);
        storage.counters = counters.toCell();
        storage.maps = maps.toCell();
        sendJettons(
            mutate storage,
            buyer,
            hiAmount,
            1,
            tonAmount,
            attached - tonAmount,
        );
    } else {
        assert (storage.lockedSaleEnabled) throw Errors.PoolPaused;
        val hiAmount = tonAmount * lockedHiPerTon();
        assert (
            counters.lockedSoldHi + hiAmount <= counters.lockedPoolTotalHi
        ) throw Errors.InsufficientInventory;
        val missedHi = hiAmount * storage.confirmedLevel / 10;
        val pos = position(maps, buyer, storage.confirmedLevel);
        maps
            .positions
            .set(
                buyer,
                {
                    totalLockedHi: pos.totalLockedHi + hiAmount,
                    claimedHi: pos.claimedHi,
                    entryLevel: storage.confirmedLevel,
                    missedHi: pos.missedHi + missedHi,
                },
            );
        counters.lockedSoldHi += hiAmount;
        counters.lockedMissedHi += missedHi;
        maps.purchasedTon.set(buyer, newTotal);
        storage.counters = counters.toCell();
        storage.maps = maps.toCell();
    }

    storage.save();
}

fun claimLocked(owner: address, attached: coins) {
    assert (attached >= ton("0.25")) throw Errors.InsufficientAttachedTon;
    var storage = lazy PublicSaleStorage.load();
    var counters = storage.counters.load();
    var maps = storage.maps.load();
    val pos = position(maps, owner, storage.confirmedLevel);
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
    counters.lockedClaimedHi += amount;
    storage.counters = counters.toCell();
    storage.maps = maps.toCell();
    sendJettons(
        mutate storage,
        owner,
        amount,
        3,
        ton("0"),
        attached,
    );
    storage.save();
}

fun sendJettons(
    mutate storage: PublicSaleStorage,
    recipient: address,
    amount: coins,
    kind: uint8,
    tonAmount: coins,
    value: coins,
) {
    val config = storage.config.load();
    val saleJettonWallet = storage.saleJettonWallet;
    assert (saleJettonWallet != null) throw Errors.JettonWalletNotConfigured;
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
            },
        );
    storage.maps = maps.toCell();
    val transferMessage = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: saleJettonWallet!,
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

fun purchasedTon(maps: PublicSaleMaps, buyer: address): coins {
    val found = maps.purchasedTon.get(buyer);
    return found.isFound ? found.loadValue() : 0;
}

fun position(maps: PublicSaleMaps, owner: address, confirmedLevel: uint8): PurchasePosition {
    val found = maps.positions.get(owner);
    if (found.isFound) {
        return found.loadValue();
    }
    return {
        totalLockedHi: 0,
        claimedHi: 0,
        entryLevel: confirmedLevel,
        missedHi: 0,
    };
}

fun claimable(storage: PublicSaleStorage, pos: PurchasePosition): coins {
    if (storage.confirmedLevel <= pos.entryLevel) {
        return 0;
    }
    val eligibleLevels = storage.confirmedLevel - pos.entryLevel;
    return pos.totalLockedHi * eligibleLevels / 10 - pos.claimedHi;
}

fun instantUnsold(counters: PublicSaleCounters): coins {
    return counters.instantPoolTotalHi - counters.instantSoldHi;
}

fun lockedUnsold(counters: PublicSaleCounters): coins {
    return counters.lockedPoolTotalHi - counters.lockedSoldHi;
}

get fun buyer_state(owner: address): (coins, coins, uint8, coins, coins) {
    val storage = lazy PublicSaleStorage.load();
    val maps = storage.maps.load();
    val pos = position(maps, owner, storage.confirmedLevel);
    return (
        purchasedTon(maps, owner),
        pos.totalLockedHi,
        pos.entryLevel,
        pos.claimedHi,
        claimable(storage, pos),
    );
}

get fun sale_state(): (
    uint8,
    coins,
    coins,
    coins,
    coins,
    coins,
) {
    val storage = lazy PublicSaleStorage.load();
    val counters = storage.counters.load();
    return (
        storage.confirmedLevel,
        counters.instantSoldHi,
        counters.lockedSoldHi,
        counters.lockedClaimedHi,
        counters.lockedMissedHi,
        instantUnsold(counters) + lockedUnsold(counters),
    );
}

fun minPurchaseTon(): coins {
    return ton("0.1");
}

fun maxPurchaseTon(): coins {
    return ton("5000");
}

fun instantHiPerTon(): int {
    return 3000;
}

fun lockedHiPerTon(): int {
    return 15000;
}
