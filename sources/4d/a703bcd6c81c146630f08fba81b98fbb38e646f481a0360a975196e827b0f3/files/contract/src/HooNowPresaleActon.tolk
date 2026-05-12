import "HooNowPresaleMessages"
import "HooNowPresaleTypes"

contract HooNowPresaleActon {
    author: "HooNow"
    version: "1.1.0"
    description: "HOO first-wave TON presale contract (TON + USDT, batch flush)"
    storage: PresaleStorage
    incomingMessages: AllowedPresaleMessage
}

type AllowedPresaleMessage =
    | TransferNotificationForRecipient
    | ReturnExcessesBack
    | SetPaused
    | SetJettonWallets
    | WithdrawUnsold
    | WithdrawUsdt
    | TopUpTons
    | BuyWithTon
    | SetTonPrice
    | FlushToTreasury
    | WithdrawTon

fun onBouncedMessage(in: InMessageBounced) {
    var storage = lazy PresaleStorage.load();
    val jettons = storage.jettonWallets();
    if (in.senderAddress != jettons.hooWallet) {
        return;
    }

    var bounced = in.bouncedBody;
    bounced.skipBouncedPrefix();
    val opcode = bounced.loadUint(32);
    if (opcode != 0x0f8a7ea5) {
        return;
    }

    val queryId = bounced.loadUint(64) as uint64;
    var pending = storage.pendingPurchases;
    val purchaseLookup = pending.get(queryId);
    if (!purchaseLookup.isFound) {
        return;
    }

    val purchase = purchaseLookup.loadValue();
    pending.delete(queryId);
    storage.pendingPurchases = pending;
    storage.issuedHoo -= purchase.hooAmount;

    if (purchase.tonAmount > 0) {
        // TON purchase: rollback raisedUsdt equivalent, unwind accumulatedTon, refund TON
        val usdtEquiv = tonToUsdtEquiv(purchase.tonAmount, storage.tonPriceUsdtMicro);
        storage.raisedUsdt -= usdtEquiv;
        storage.accumulatedTon -= purchase.tonAmount;
        storage.save();
        refundTon(purchase.buyer, purchase.tonAmount);
    } else {
        // USDT purchase: rollback raisedUsdt, refund USDT to buyer
        storage.raisedUsdt -= purchase.usdtAmount;
        storage.save();
        refundUsdt(storage, queryId, purchase.buyer, purchase.usdtAmount);
    }
}

fun assertOwner(senderAddress: address, ownerAddress: address) {
    assert (senderAddress == ownerAddress) throw Errors.OnlyOwner;
}

fun assertSaleOpen(storage: PresaleStorage) {
    assert (!storage.paused) throw Errors.SalePaused;
    assert (storage.jettonWalletsConfigured) throw Errors.JettonWalletsNotSet;
}

fun hooFromUsdt(amountUsdtMicro: coins): coins {
    return (amountUsdtMicro * HOO_UNIT_NANO) / PRESALE_PRICE_USDT_MICRO;
}

fun tonToUsdtEquiv(tonNano: coins, tonPriceUsdtMicro: coins): coins {
    return (tonNano * tonPriceUsdtMicro) / 1_000_000_000;
}

fun assertCapacity(storage: PresaleStorage, paidUsdtMicro: coins, hooAmount: coins) {
    assert (hooAmount > 0) throw Errors.ZeroHoo;
    assert (storage.issuedHoo + hooAmount <= SALE_ALLOCATION_HOO_NANO) throw Errors.SoldOut;
    assert (storage.raisedUsdt + paidUsdtMicro <= HARD_CAP_USDT_MICRO) throw Errors.HardCapReached;
}

fun issueHoo(storage: PresaleStorage, queryId: uint64, buyer: address, hooAmount: coins) {
    val jettons = storage.jettonWallets();
    val transfer = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: jettons.hooWallet,
        value: HOO_TRANSFER_TON_VALUE,
        body: AskToTransfer {
            queryId,
            jettonAmount: hooAmount,
            transferRecipient: buyer,
            sendExcessesTo: contract.getAddress(),
            customPayload: null,
            forwardTonAmount: 1,
            forwardPayload: emptyForwardPayload(),
        },
    });
    transfer.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
}

fun forwardUsdtToTreasury(storage: PresaleStorage, queryId: uint64, amount: coins) {
    val admin = storage.adminAddresses();
    val jettons = storage.jettonWallets();
    val transfer = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: jettons.usdtWallet,
        value: USDT_FORWARD_TON_VALUE,
        body: AskToTransfer {
            queryId,
            jettonAmount: amount,
            transferRecipient: admin.treasury,
            sendExcessesTo: contract.getAddress(),
            customPayload: null,
            forwardTonAmount: 1,
            forwardPayload: emptyForwardPayload(),
        },
    });
    transfer.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
}

fun refundUsdt(storage: PresaleStorage, queryId: uint64, buyer: address, amount: coins) {
    val jettons = storage.jettonWallets();
    val transfer = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: jettons.usdtWallet,
        value: USDT_FORWARD_TON_VALUE,
        body: AskToTransfer {
            queryId,
            jettonAmount: amount,
            transferRecipient: buyer,
            sendExcessesTo: contract.getAddress(),
            customPayload: null,
            forwardTonAmount: 1,
            forwardPayload: emptyForwardPayload(),
        },
    });
    transfer.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
}

fun refundTon(buyer: address, netTonAmount: coins) {
    val refund = createMessage({
        bounce: BounceMode.NoBounce,
        dest: buyer,
        value: netTonAmount,
        body: beginCell().endCell().beginParse(),
    });
    refund.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedPresaleMessage.fromSlice(in.body);

    match (msg) {
        TransferNotificationForRecipient => {
            var storage = lazy PresaleStorage.load();
            val jettons = storage.jettonWallets();
            assertSaleOpen(storage);
            assert (in.senderAddress == jettons.usdtWallet) throw Errors.InvalidUsdtWallet;
            assert (msg.transferInitiator != null) throw Errors.MissingBuyer;
            assert (msg.jettonAmount >= MIN_PURCHASE_USDT_MICRO) throw Errors.BelowMinPurchase;

            val buyer = msg.transferInitiator!;
            val hooAmount = hooFromUsdt(msg.jettonAmount);
            assertCapacity(storage, msg.jettonAmount, hooAmount);
            var pending = storage.pendingPurchases;
            assert (pending.addIfNotExists(msg.queryId, PendingPurchase {
                buyer,
                usdtAmount: msg.jettonAmount,
                hooAmount,
                tonAmount: 0,
            })) throw Errors.DuplicateQuery;

            storage.raisedUsdt += msg.jettonAmount;
            storage.issuedHoo += hooAmount;
            storage.pendingPurchases = pending;
            storage.save();

            issueHoo(storage, msg.queryId, buyer, hooAmount);
        }

        BuyWithTon => {
            var storage = lazy PresaleStorage.load();
            assertSaleOpen(storage);
            assert (storage.tonPriceUsdtMicro > 0) throw Errors.TonPriceNotSet;

            // Deduct fixed gas cost from incoming TON to get net payment amount
            val netTon = in.valueCoins - TON_PURCHASE_GAS_COST;
            val usdtEquiv = tonToUsdtEquiv(netTon, storage.tonPriceUsdtMicro);
            assert (usdtEquiv >= MIN_PURCHASE_USDT_MICRO) throw Errors.BelowMinPurchase;

            val hooAmount = hooFromUsdt(usdtEquiv);
            assertCapacity(storage, usdtEquiv, hooAmount);
            var pending = storage.pendingPurchases;
            assert (pending.addIfNotExists(msg.queryId, PendingPurchase {
                buyer: in.senderAddress,
                usdtAmount: 0,
                hooAmount,
                tonAmount: netTon,
            })) throw Errors.DuplicateQuery;

            storage.raisedUsdt += usdtEquiv;
            storage.issuedHoo += hooAmount;
            storage.accumulatedTon += netTon;
            storage.pendingPurchases = pending;
            storage.save();

            issueHoo(storage, msg.queryId, in.senderAddress, hooAmount);
        }

        ReturnExcessesBack => {
            var storage = lazy PresaleStorage.load();
            val jettons = storage.jettonWallets();
            if (in.senderAddress != jettons.hooWallet) {
                return;
            }

            var pending = storage.pendingPurchases;
            val purchaseLookup = pending.get(msg.queryId);
            if (!purchaseLookup.isFound) {
                return;
            }

            val purchase = purchaseLookup.loadValue();
            pending.delete(msg.queryId);
            storage.pendingPurchases = pending;

            if (purchase.usdtAmount > 0) {
                // USDT purchase confirmed: accumulate, do NOT forward to treasury yet
                storage.accumulatedUsdt += purchase.usdtAmount;
            }
            // TON purchase: TON already in contract and accumulatedTon already set on entry

            storage.save();
        }

        SetPaused => {
            var storage = lazy PresaleStorage.load();
            val admin = storage.adminAddresses();
            assertOwner(in.senderAddress, admin.owner);
            storage.paused = msg.paused;
            storage.save();
        }

        SetJettonWallets => {
            var storage = lazy PresaleStorage.load();
            val admin = storage.adminAddresses();
            assertOwner(in.senderAddress, admin.owner);
            storage.jettons = PresaleJettonWallets {
                usdtWallet: msg.usdtWallet,
                hooWallet: msg.hooWallet,
            }.toCell();
            storage.jettonWalletsConfigured = true;
            storage.save();
        }

        SetTonPrice => {
            var storage = lazy PresaleStorage.load();
            val admin = storage.adminAddresses();
            assertOwner(in.senderAddress, admin.owner);
            storage.tonPriceUsdtMicro = msg.priceUsdtMicro;
            storage.save();
        }

        FlushToTreasury => {
            var storage = lazy PresaleStorage.load();
            val admin = storage.adminAddresses();
            assertOwner(in.senderAddress, admin.owner);
            assert (storage.jettonWalletsConfigured) throw Errors.JettonWalletsNotSet;

            val hasUsdt = storage.accumulatedUsdt >= FLUSH_USDT_THRESHOLD;
            // available TON above gas reserve (approximation; actual balance includes in.value)
            val availableTon = contract.getOriginalBalance() - GAS_RESERVE_TON;
            val hasTon = (storage.accumulatedTon >= FLUSH_TON_THRESHOLD) & (availableTon > 0);
            assert (hasUsdt | hasTon) throw Errors.BelowFlushThreshold;

            if (hasUsdt) {
                val amount = storage.accumulatedUsdt;
                storage.accumulatedUsdt = 0;
                forwardUsdtToTreasury(storage, msg.queryId, amount);
            }
            if (hasTon) {
                val tonToSend = min(storage.accumulatedTon, availableTon);
                storage.accumulatedTon -= tonToSend;
                val flushMsg = createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: admin.treasury,
                    value: tonToSend,
                    body: beginCell().endCell().beginParse(),
                });
                flushMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
            }
            storage.save();
        }

        WithdrawUnsold => {
            val storage = lazy PresaleStorage.load();
            val admin = storage.adminAddresses();
            assertOwner(in.senderAddress, admin.owner);
            assert (storage.jettonWalletsConfigured) throw Errors.JettonWalletsNotSet;
            assert (storage.issuedHoo + msg.amount <= SALE_ALLOCATION_HOO_NANO) throw Errors.OnlyUnsold;

            issueHoo(storage, 0, msg.destination, msg.amount);
        }

        WithdrawUsdt => {
            val storage = lazy PresaleStorage.load();
            val admin = storage.adminAddresses();
            assertOwner(in.senderAddress, admin.owner);
            assert (storage.jettonWalletsConfigured) throw Errors.JettonWalletsNotSet;
            assert (msg.amount > 0) throw Errors.ZeroUsdt;
            forwardUsdtToTreasury(storage, msg.queryId, msg.amount);
        }

        WithdrawTon => {
            val storage = lazy PresaleStorage.load();
            val admin = storage.adminAddresses();
            assertOwner(in.senderAddress, admin.owner);
            assert (msg.amount > 0) throw Errors.InsufficientTon;
            val available = contract.getOriginalBalance() - GAS_RESERVE_TON;
            assert (available >= msg.amount) throw Errors.InsufficientTon;
            val sendMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: admin.treasury,
                value: msg.amount,
                body: beginCell().endCell().beginParse(),
            });
            sendMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
        }

        TopUpTons => {
            // Accept maintenance TON for outgoing transfer fees.
        }

        else => {
            assert (in.body.isEmpty()) throw 0xFFFF;
        }
    }
}

get fun saleData(): SaleData {
    val storage = lazy PresaleStorage.load();
    val admin = storage.adminAddresses();
    val jettons = storage.jettonWallets();

    return {
        hooMaster: HOO_MASTER,
        usdtMaster: USDT_TON_MASTER,
        treasury: admin.treasury,
        priceUsdtMicro: PRESALE_PRICE_USDT_MICRO,
        targetPriceUsdtMicro: TARGET_PRICE_USDT_MICRO,
        usdtWallet: jettons.usdtWallet,
        hooWallet: jettons.hooWallet,
        jettonWalletsConfigured: storage.jettonWalletsConfigured,
        allocationHooNano: SALE_ALLOCATION_HOO_NANO,
        hardCapUsdtMicro: HARD_CAP_USDT_MICRO,
        minPurchaseUsdtMicro: MIN_PURCHASE_USDT_MICRO,
        raisedUsdt: storage.raisedUsdt,
        issuedHoo: storage.issuedHoo,
        paused: storage.paused,
        accumulatedUsdt: storage.accumulatedUsdt,
        accumulatedTon: storage.accumulatedTon,
        tonPriceUsdtMicro: storage.tonPriceUsdtMicro,
    };
}
