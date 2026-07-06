import "types"

contract MarketplaceFactoryV2 {
    author: "Grapes Marketplace"
    version: "0.2.0"
    description: "Factory for deterministic v2 NFT sale contracts with fixed-native and live-USD quote pricing"
    storage: FactoryV2Storage
    incomingMessages: FactoryV2Message
}

fun minCreateValueV2Factory(): coins {
    return ton("0.05");
}

fun minListWithNftValueV2Factory(): coins {
    return ton("0.18");
}

fun saleDeployValueV2Factory(): coins {
    return ton("0.16");
}

fun factoryNftTransferValueV2Factory(): coins {
    return ton("0.09");
}

fun factoryNftForwardValueV2Factory(): coins {
    return ton("0.05");
}

fun saleFactoryDepositReadyValueV2Factory(): coins {
    return ton("0.1");
}

fun factoryReserveV2Factory(): coins {
    return ton("0.2");
}

fun minFactoryActionValueV2Factory(): coins {
    return ton("0.1");
}

fun minFactoryRefundValueV2Factory(): coins {
    return ton("0.01");
}

fun factoryListRefundBudgetV2Factory(listValue: coins): coins {
    val reserved = saleDeployValueV2Factory() + factoryNftTransferValueV2Factory();
    val returned = saleFactoryDepositReadyValueV2Factory();
    if (listValue + returned <= reserved) {
        return 0;
    }

    return listValue + returned - reserved;
}

fun sendFactoryListExcessRefundV2Factory(recipient: address, reservedOutgoing: coins, maxRefund: coins) {
    if (maxRefund < minFactoryRefundValueV2Factory()) {
        return;
    }

    val originalBalance = contract.getOriginalBalance();
    if (originalBalance <= reservedOutgoing + factoryReserveV2Factory() + minFactoryRefundValueV2Factory()) {
        return;
    }

    var refundAmount = originalBalance - reservedOutgoing - factoryReserveV2Factory();
    if (refundAmount > maxRefund) {
        refundAmount = maxRefund;
    }

    if (refundAmount < minFactoryRefundValueV2Factory()) {
        return;
    }

    val refund = createMessage({
        bounce: BounceMode.NoBounce,
        value: refundAmount,
        dest: recipient,
    });
    refund.send(SEND_MODE_REGULAR);
}

fun loadFactoryV2ListWithNftMarker(
    payload: MarketTlbEither<cell, Cell<cell>>,
): FactoryV2ListWithNftMarker {
    return match (payload) {
        MarketTlbEitherLeft => FactoryV2ListWithNftMarker.fromCell(payload.value),
        MarketTlbEitherRight => FactoryV2ListWithNftMarker.fromCell(payload.value),
    };
}

fun saleDepositMarkerPayloadV2Factory(queryId: uint64, marketplaceIntentHash: uint256, seller: address): cell {
    return beginCell()
        .storeUint(0x47534450, 32)
        .storeUint(queryId, 64)
        .storeUint(marketplaceIntentHash, 256)
        .storeAddress(seller)
        .endCell();
}

fun buildSaleV2Storage(factoryAddress: address, parties: SaleParties, terms: SaleV2Terms): SaleV2Storage {
    return SaleV2Storage {
        factory: factoryAddress,
        saleId: 0,
        state: SaleState.Created,
        parties: parties.toCell(),
        terms: terms.toCell(),
        settlement: SaleV2Settlement {
            buyer: null,
            refundRecipient: null,
            refundBudget: 0,
            nftTransferQueryId: 0,
            settlementPrice: 0,
            payoutDone: false,
        }.toCell(),
    };
}

fun assertValidFactoryV2Terms(storage: FactoryV2Storage, terms: SaleV2Terms) {
    val policy = terms.pricing.load();

    assert (terms.feeBps <= 10000) throw Errors.InvalidFeeBps;
    assert (terms.feeWallet == storage.feeWallet) throw Errors.InvalidFeeConfig;
    assert (terms.feeBps == storage.feeBps) throw Errors.InvalidFeeConfig;
    assert (terms.expiresAt > blockchain.now()) throw Errors.InvalidExpiry;
    assert (terms.expiresAt <= blockchain.now() + storage.defaultLifetimeSeconds) throw Errors.InvalidExpiry;
    assert (terms.marketplaceIntentHash != 0) throw Errors.InvalidIntentHash;
    assert (policy.networkId == storage.networkId) throw Errors.InvalidQuote;

    if (policy.pricingMode == SalePricingMode.FixedNative as uint8) {
        assert (policy.fixedPrice > 0) throw Errors.InvalidPrice;
        assert (policy.usdPriceMicro == 0) throw Errors.InvalidPrice;
        assert (policy.oraclePublicKey == 0) throw Errors.InvalidQuote;
        assert (policy.minPriceNano == 0) throw Errors.InvalidQuote;
        assert (policy.maxPriceNano == 0) throw Errors.InvalidQuote;
        return;
    }

    assert (policy.pricingMode == SalePricingMode.LiveUsdQuote as uint8) throw Errors.InvalidPricingMode;
    assert (policy.fixedPrice == 0) throw Errors.InvalidPrice;
    assert (policy.usdPriceMicro > 0) throw Errors.InvalidPrice;
    assert (policy.rateScale == 1000000) throw Errors.InvalidQuote;
    assert (policy.oraclePublicKey != 0) throw Errors.InvalidQuote;
    assert (policy.minPriceNano > 0) throw Errors.InvalidQuote;
    assert (policy.maxPriceNano >= policy.minPriceNano) throw Errors.InvalidQuote;
}

fun assertSameTermsV2Factory(actual: SaleV2Terms, expected: SaleV2Terms) {
    val actualPolicy = actual.pricing.load();
    val expectedPolicy = expected.pricing.load();

    assert (actualPolicy.pricingMode == expectedPolicy.pricingMode) throw Errors.WrongPendingDeposit;
    assert (actualPolicy.networkId == expectedPolicy.networkId) throw Errors.WrongPendingDeposit;
    assert (actualPolicy.fixedPrice == expectedPolicy.fixedPrice) throw Errors.WrongPendingDeposit;
    assert (actualPolicy.usdPriceMicro == expectedPolicy.usdPriceMicro) throw Errors.WrongPendingDeposit;
    assert (actualPolicy.rateScale == expectedPolicy.rateScale) throw Errors.WrongPendingDeposit;
    assert (actualPolicy.oraclePublicKey == expectedPolicy.oraclePublicKey) throw Errors.WrongPendingDeposit;
    assert (actualPolicy.minPriceNano == expectedPolicy.minPriceNano) throw Errors.WrongPendingDeposit;
    assert (actualPolicy.maxPriceNano == expectedPolicy.maxPriceNano) throw Errors.WrongPendingDeposit;
    assert (actual.feeWallet == expected.feeWallet) throw Errors.WrongPendingDeposit;
    assert (actual.feeBps == expected.feeBps) throw Errors.WrongPendingDeposit;
    assert (actual.expiresAt == expected.expiresAt) throw Errors.WrongPendingDeposit;
    assert (
        actual.marketplaceIntentHash == expected.marketplaceIntentHash
    ) throw Errors.WrongPendingDeposit;
}

fun calculateSaleV2AddressFrom(
    factoryAddress: address,
    saleCode: cell,
    parties: SaleParties,
    terms: SaleV2Terms,
): address {
    val saleStorage = buildSaleV2Storage(factoryAddress, parties, terms);
    val saleState = ContractState {
        code: saleCode,
        data: saleStorage.toCell(),
    };
    return AutoDeployAddress { stateInit: saleState }.calculateAddress();
}

type FactoryV2Message =
    | FactoryV2CreateSale
    | FactorySetCreatePaused
    | FactorySetFeeConfig
    | FactoryV2DepositNft
    | FactoryDepositCompleted
    | FactoryRecoverPendingNft
    | NftOwnershipAssigned
    | NftExcesses

fun onInternalMessage(in: InMessage) {
    val msg = lazy FactoryV2Message.fromSlice(in.body);

    match (msg) {
        FactoryV2CreateSale => {
            var storage = lazy FactoryV2Storage.load();
            val parties = msg.parties.load();
            val terms = msg.terms.load();

            assert (!storage.createPaused) throw Errors.FactoryCreatePaused;
            assert (in.senderAddress == parties.seller) throw Errors.NotSeller;
            assertValidFactoryV2Terms(storage, terms);
            assert (in.valueCoins >= minCreateValueV2Factory()) throw Errors.InsufficientValue;

            val saleStorage = buildSaleV2Storage(contract.getAddress(), parties, terms);
            val saleState = ContractState {
                code: storage.saleCode,
                data: saleStorage.toCell(),
            };
            storage.nextSaleId += 1;
            storage.save();

            val deploySale = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                value: ton("0"),
                dest: { stateInit: saleState },
            });
            deploySale.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }
        NftOwnershipAssigned => {
            var storage = lazy FactoryV2Storage.load();
            val marker = loadFactoryV2ListWithNftMarker(msg.forwardPayload);
            val terms = marker.terms.load();

            assert (!storage.createPaused) throw Errors.FactoryCreatePaused;
            assert (in.valueCoins >= minListWithNftValueV2Factory()) throw Errors.InsufficientValue;
            assert (msg.prevOwner == marker.sellerAddress) throw Errors.WrongNftMarker;
            assertValidFactoryV2Terms(storage, terms);

            val parties = SaleParties {
                seller: marker.sellerAddress,
                nftItem: in.senderAddress,
            };
            val saleStorage = buildSaleV2Storage(contract.getAddress(), parties, terms);
            val saleState = ContractState {
                code: storage.saleCode,
                data: saleStorage.toCell(),
            };
            val expectedSale = AutoDeployAddress { stateInit: saleState }.calculateAddress();

            val pendingAdded = storage.pendingDeposits.addIfNotExists(
                parties.nftItem,
                FactoryV2PendingDeposit {
                    seller: parties.seller,
                    expectedSale,
                    terms: terms.toCell(),
                    transferQueryId: 0,
                    recoveryQueryId: 0,
                    stage: FactoryPendingStage.WaitingSaleReady,
                    createdAt: blockchain.now(),
                }.toCell(),
            );
            assert (pendingAdded) throw Errors.PendingDepositExists;

            storage.nextSaleId += 1;
            storage.save();

            val deploySale = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                value: saleDeployValueV2Factory(),
                dest: { stateInit: saleState },
                body: SaleRequestDeposit {
                    queryId: marker.queryId,
                    marketplaceIntentHash: terms.marketplaceIntentHash,
                    factoryRefundBudget: factoryListRefundBudgetV2Factory(in.valueCoins),
                },
            });
            deploySale.send(SEND_MODE_REGULAR);
        }
        FactoryV2DepositNft => {
            var storage = lazy FactoryV2Storage.load();
            val parties = msg.parties.load();
            val terms = msg.terms.load();
            val expectedSale = calculateSaleV2AddressFrom(
                contract.getAddress(),
                storage.saleCode,
                parties,
                terms,
            );
            val lookup = storage.pendingDeposits.get(parties.nftItem);
            assert (lookup.isFound) throw Errors.PendingDepositMissing;
            var pending = lookup.loadValue().load();
            val pendingTerms = pending.terms.load();

            assert (in.senderAddress == expectedSale) throw Errors.WrongFactoryDeposit;
            assert (pending.expectedSale == expectedSale) throw Errors.WrongPendingDeposit;
            assert (pending.seller == parties.seller) throw Errors.WrongPendingDeposit;
            assert (pending.stage == FactoryPendingStage.WaitingSaleReady) throw Errors.WrongPendingDeposit;
            assertSameTermsV2Factory(terms, pendingTerms);
            assert (contract.getOriginalBalance() >= factoryNftTransferValueV2Factory()) throw Errors.InsufficientReserve;

            pending.transferQueryId = msg.queryId;
            pending.stage = FactoryPendingStage.TransferringToSale;
            storage.pendingDeposits.set(parties.nftItem, pending.toCell());
            storage.save();

            val transferNft = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                value: factoryNftTransferValueV2Factory(),
                dest: parties.nftItem,
                body: NftTransfer {
                    queryId: msg.queryId,
                    newOwner: in.senderAddress,
                    responseDestination: contract.getAddress(),
                    customPayload: MarketTlbMaybe<Cell<cell>>.none(),
                    forwardAmount: factoryNftForwardValueV2Factory(),
                    forwardPayload: MarketTlbEither<cell, Cell<cell>>.left(
                        saleDepositMarkerPayloadV2Factory(msg.queryId, terms.marketplaceIntentHash, parties.seller),
                    ),
                },
            });
            transferNft.send(SEND_MODE_REGULAR);

            sendFactoryListExcessRefundV2Factory(parties.seller, factoryNftTransferValueV2Factory(), msg.factoryRefundBudget);
        }
        FactoryDepositCompleted => {
            var storage = lazy FactoryV2Storage.load();
            val lookup = storage.pendingDeposits.get(msg.nftItem);
            assert (lookup.isFound) throw Errors.PendingDepositMissing;
            val pending = lookup.loadValue().load();
            val terms = pending.terms.load();

            assert (in.senderAddress == pending.expectedSale) throw Errors.WrongPendingDeposit;
            assert (pending.stage == FactoryPendingStage.TransferringToSale) throw Errors.WrongPendingDeposit;
            assert (pending.transferQueryId == msg.queryId) throw Errors.WrongPendingDeposit;
            assert (
                terms.marketplaceIntentHash == msg.marketplaceIntentHash
            ) throw Errors.WrongPendingDeposit;

            storage.pendingDeposits.delete(msg.nftItem);
            storage.save();
        }
        FactoryRecoverPendingNft => {
            var storage = lazy FactoryV2Storage.load();
            val lookup = storage.pendingDeposits.get(msg.nftItem);
            assert (lookup.isFound) throw Errors.PendingDepositMissing;
            var pending = lookup.loadValue().load();
            val terms = pending.terms.load();
            val canRecover = in.senderAddress == pending.seller ||
                blockchain.now() >= terms.expiresAt;
            val recoverableStage = pending.stage == FactoryPendingStage.WaitingSaleReady ||
                pending.stage == FactoryPendingStage.TransferFailedToSale ||
                pending.stage == FactoryPendingStage.RecoveryFailedToSeller ||
                (
                    pending.stage == FactoryPendingStage.TransferringToSale &&
                    blockchain.now() >= terms.expiresAt
                );

            assert (msg.marketplaceIntentHash == terms.marketplaceIntentHash) throw Errors.WrongPendingDeposit;
            assert (canRecover) throw Errors.RecoveryNotAllowed;
            assert (recoverableStage) throw Errors.RecoveryNotAllowed;
            assert (in.valueCoins >= minFactoryActionValueV2Factory()) throw Errors.InsufficientValue;
            assert (
                contract.getOriginalBalance() >= factoryNftTransferValueV2Factory() + factoryReserveV2Factory()
            ) throw Errors.InsufficientReserve;

            pending.recoveryQueryId = msg.queryId;
            pending.stage = FactoryPendingStage.RecoveringToSeller;
            storage.pendingDeposits.set(msg.nftItem, pending.toCell());
            storage.save();

            val transferNft = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                value: factoryNftTransferValueV2Factory(),
                dest: msg.nftItem,
                body: NftTransfer {
                    queryId: msg.queryId,
                    newOwner: pending.seller,
                    responseDestination: contract.getAddress(),
                    customPayload: MarketTlbMaybe<Cell<cell>>.none(),
                    forwardAmount: ton("0"),
                    forwardPayload: MarketTlbEither<cell, Cell<cell>>.left(createEmptyCell()),
                },
            });
            transferNft.send(SEND_MODE_REGULAR);
        }
        NftExcesses => {
            var storage = lazy FactoryV2Storage.load();
            val lookup = storage.pendingDeposits.get(in.senderAddress);
            if (!lookup.isFound) {
                return;
            }

            val pending = lookup.loadValue().load();
            if (
                pending.stage == FactoryPendingStage.RecoveringToSeller &&
                pending.recoveryQueryId == msg.queryId
            ) {
                storage.pendingDeposits.delete(in.senderAddress);
                storage.save();
            }
        }
        FactorySetCreatePaused => {
            var storage = lazy FactoryV2Storage.load();
            assert (in.senderAddress == storage.owner) throw Errors.NotFactoryOwner;
            storage.createPaused = msg.paused;
            storage.save();
        }
        FactorySetFeeConfig => {
            var storage = lazy FactoryV2Storage.load();
            assert (in.senderAddress == storage.owner) throw Errors.NotFactoryOwner;
            assert (msg.feeBps <= 10000) throw Errors.InvalidFeeBps;
            storage.feeWallet = msg.feeWallet;
            storage.feeBps = msg.feeBps;
            storage.save();
        }
        else => {
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
        }
    }
}

fun onBouncedMessage(in: InMessageBounced) {
    var storage = lazy FactoryV2Storage.load();
    val lookup = storage.pendingDeposits.get(in.senderAddress);
    assert (lookup.isFound) throw Errors.PendingDepositMissing;
    var pending = lookup.loadValue().load();
    var body = in.bouncedBody;

    body.skipBouncedPrefix();
    val op = body.loadUint(32);
    assert (op == 0x5fcc3d14) throw Errors.WrongPendingDeposit;
    val queryId = body.loadUint(64);

    if (
        pending.stage == FactoryPendingStage.TransferringToSale &&
        pending.transferQueryId == queryId
    ) {
        pending.stage = FactoryPendingStage.TransferFailedToSale;
        storage.pendingDeposits.set(in.senderAddress, pending.toCell());
        storage.save();
        return;
    }

    if (
        pending.stage == FactoryPendingStage.RecoveringToSeller &&
        pending.recoveryQueryId == queryId
    ) {
        pending.stage = FactoryPendingStage.RecoveryFailedToSeller;
        storage.pendingDeposits.set(in.senderAddress, pending.toCell());
        storage.save();
        return;
    }

    throw Errors.WrongPendingDeposit;
}

get fun owner(): address {
    val storage = lazy FactoryV2Storage.load();
    return storage.owner;
}

get fun feeWallet(): address {
    val storage = lazy FactoryV2Storage.load();
    return storage.feeWallet;
}

get fun feeBps(): uint16 {
    val storage = lazy FactoryV2Storage.load();
    return storage.feeBps;
}

get fun defaultLifetimeSeconds(): uint32 {
    val storage = lazy FactoryV2Storage.load();
    return storage.defaultLifetimeSeconds;
}

get fun networkId(): uint32 {
    val storage = lazy FactoryV2Storage.load();
    return storage.networkId;
}

get fun createPaused(): bool {
    val storage = lazy FactoryV2Storage.load();
    return storage.createPaused;
}

get fun nextSaleId(): uint64 {
    val storage = lazy FactoryV2Storage.load();
    return storage.nextSaleId;
}

get fun pendingDepositStage(nftItem: address): uint8 {
    val storage = lazy FactoryV2Storage.load();
    val lookup = storage.pendingDeposits.get(nftItem);
    if (!lookup.isFound) {
        return 0;
    }

    return lookup.loadValue().load().stage as uint8;
}

get fun pendingDepositSeller(nftItem: address): address? {
    val storage = lazy FactoryV2Storage.load();
    val lookup = storage.pendingDeposits.get(nftItem);
    if (!lookup.isFound) {
        return null;
    }

    return lookup.loadValue().load().seller;
}

get fun calculateFixedNativeSaleAddress(
    seller: address,
    nftItem: address,
    fixedPrice: coins,
    feeWallet: address,
    feeBps: uint16,
    expiresAt: uint64,
    marketplaceIntentHash: uint256,
): address {
    val storage = lazy FactoryV2Storage.load();
    val parties = SaleParties {
        seller,
        nftItem,
    };
    val terms = SaleV2Terms {
        pricing: SaleV2PricingPolicy {
            pricingMode: SalePricingMode.FixedNative as uint8,
            networkId: storage.networkId,
            fixedPrice,
            usdPriceMicro: 0,
            rateScale: 1000000,
            oraclePublicKey: 0,
            minPriceNano: 0,
            maxPriceNano: 0,
        }.toCell(),
        feeWallet,
        feeBps,
        expiresAt,
        marketplaceIntentHash,
    };
    return calculateSaleV2AddressFrom(contract.getAddress(), storage.saleCode, parties, terms);
}

get fun calculateLiveUsdQuoteSaleAddress(
    seller: address,
    nftItem: address,
    usdPriceMicro: uint64,
    oraclePublicKey: uint256,
    minPriceNano: coins,
    maxPriceNano: coins,
    feeWallet: address,
    feeBps: uint16,
    expiresAt: uint64,
    marketplaceIntentHash: uint256,
): address {
    val storage = lazy FactoryV2Storage.load();
    val parties = SaleParties {
        seller,
        nftItem,
    };
    val terms = SaleV2Terms {
        pricing: SaleV2PricingPolicy {
            pricingMode: SalePricingMode.LiveUsdQuote as uint8,
            networkId: storage.networkId,
            fixedPrice: 0,
            usdPriceMicro,
            rateScale: 1000000,
            oraclePublicKey,
            minPriceNano,
            maxPriceNano,
        }.toCell(),
        feeWallet,
        feeBps,
        expiresAt,
        marketplaceIntentHash,
    };
    return calculateSaleV2AddressFrom(contract.getAddress(), storage.saleCode, parties, terms);
}
