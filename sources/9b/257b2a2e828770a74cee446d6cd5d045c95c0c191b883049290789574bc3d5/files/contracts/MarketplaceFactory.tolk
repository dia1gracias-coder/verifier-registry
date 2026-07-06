import "types"

contract MarketplaceFactory {
    author: "Grapes Marketplace"
    version: "0.1.0"
    description: "Factory for deterministic per-listing Telegram Gift NFT sale contracts"
    storage: FactoryStorage
    incomingMessages: FactoryMessage
}

fun minCreateValue(): coins {
    return ton("0.05");
}

fun minListWithNftValue(): coins {
    return ton("0.18");
}

fun saleDeployValue(): coins {
    return ton("0.16");
}

fun factoryNftTransferValue(): coins {
    return ton("0.09");
}

fun factoryNftForwardValue(): coins {
    return ton("0.05");
}

fun saleFactoryDepositReadyValue(): coins {
    return ton("0.1");
}

fun factoryReserve(): coins {
    return ton("0.2");
}

fun minFactoryActionValue(): coins {
    return ton("0.1");
}

fun minFactoryRefundValue(): coins {
    return ton("0.01");
}

fun factoryListRefundBudget(listValue: coins): coins {
    val reserved = saleDeployValue() + factoryNftTransferValue();
    val returned = saleFactoryDepositReadyValue();
    if (listValue + returned <= reserved) {
        return 0;
    }

    return listValue + returned - reserved;
}

fun sendFactoryListExcessRefund(recipient: address, reservedOutgoing: coins, maxRefund: coins) {
    if (maxRefund < minFactoryRefundValue()) {
        return;
    }

    val originalBalance = contract.getOriginalBalance();
    if (originalBalance <= reservedOutgoing + factoryReserve() + minFactoryRefundValue()) {
        return;
    }

    var refundAmount = originalBalance - reservedOutgoing - factoryReserve();
    if (refundAmount > maxRefund) {
        refundAmount = maxRefund;
    }

    if (refundAmount < minFactoryRefundValue()) {
        return;
    }

    val refund = createMessage({
        bounce: BounceMode.NoBounce,
        value: refundAmount,
        dest: recipient,
    });
    refund.send(SEND_MODE_REGULAR);
}

fun loadFactoryListWithNftMarker(
    payload: MarketTlbEither<cell, Cell<cell>>,
): FactoryListWithNftMarker {
    return match (payload) {
        MarketTlbEitherLeft => FactoryListWithNftMarker.fromCell(payload.value),
        MarketTlbEitherRight => FactoryListWithNftMarker.fromCell(payload.value),
    };
}

fun saleDepositMarkerPayload(queryId: uint64, marketplaceIntentHash: uint256, seller: address): cell {
    return beginCell()
        .storeUint(0x47534450, 32)
        .storeUint(queryId, 64)
        .storeUint(marketplaceIntentHash, 256)
        .storeAddress(seller)
        .endCell();
}

fun buildSaleStorage(factoryAddress: address, parties: SaleParties, terms: SaleTerms): SaleStorage {
    return SaleStorage {
        factory: factoryAddress,
        saleId: 0,
        state: SaleState.Created,
        parties: parties.toCell(),
        terms: terms.toCell(),
        settlement: SaleSettlement {
            buyer: null,
            refundRecipient: null,
            refundBudget: 0,
            nftTransferQueryId: 0,
            payoutDone: false,
        }.toCell(),
    };
}

fun assertSameTerms(actual: SaleTerms, expected: SaleTerms) {
    assert (actual.price == expected.price) throw Errors.WrongPendingDeposit;
    assert (actual.feeWallet == expected.feeWallet) throw Errors.WrongPendingDeposit;
    assert (actual.feeBps == expected.feeBps) throw Errors.WrongPendingDeposit;
    assert (actual.expiresAt == expected.expiresAt) throw Errors.WrongPendingDeposit;
    assert (
        actual.marketplaceIntentHash == expected.marketplaceIntentHash
    ) throw Errors.WrongPendingDeposit;
}

fun calculateSaleAddressFrom(
    factoryAddress: address,
    saleCode: cell,
    parties: SaleParties,
    terms: SaleTerms,
): address {
    val saleStorage = buildSaleStorage(factoryAddress, parties, terms);
    val saleState = ContractState {
        code: saleCode,
        data: saleStorage.toCell(),
    };
    return AutoDeployAddress { stateInit: saleState }.calculateAddress();
}

type FactoryMessage =
    | FactoryCreateSale
    | FactorySetCreatePaused
    | FactorySetFeeConfig
    | FactoryDepositNft
    | FactoryDepositCompleted
    | FactoryRecoverPendingNft
    | NftOwnershipAssigned
    | NftExcesses

fun onInternalMessage(in: InMessage) {
    val msg = lazy FactoryMessage.fromSlice(in.body);

    match (msg) {
        FactoryCreateSale => {
            var storage = lazy FactoryStorage.load();
            val parties = msg.parties.load();
            val terms = msg.terms.load();

            assert (!storage.createPaused) throw Errors.FactoryCreatePaused;
            assert (in.senderAddress == parties.seller) throw Errors.NotSeller;
            assert (terms.price > 0) throw Errors.InvalidPrice;
            assert (terms.feeBps <= 10000) throw Errors.InvalidFeeBps;
            assert (terms.feeWallet == storage.feeWallet) throw Errors.InvalidFeeConfig;
            assert (terms.feeBps == storage.feeBps) throw Errors.InvalidFeeConfig;
            assert (terms.expiresAt > blockchain.now()) throw Errors.InvalidExpiry;
            assert (terms.expiresAt <= blockchain.now() + storage.defaultLifetimeSeconds) throw Errors.InvalidExpiry;
            assert (terms.marketplaceIntentHash != 0) throw Errors.InvalidIntentHash;
            assert (in.valueCoins >= minCreateValue()) throw Errors.InsufficientValue;

            val saleStorage = buildSaleStorage(contract.getAddress(), parties, terms);
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
            var storage = lazy FactoryStorage.load();
            val marker = loadFactoryListWithNftMarker(msg.forwardPayload);
            val markerTerms = marker.terms.load();

            assert (!storage.createPaused) throw Errors.FactoryCreatePaused;
            assert (in.valueCoins >= minListWithNftValue()) throw Errors.InsufficientValue;
            assert (msg.prevOwner == marker.sellerAddress) throw Errors.WrongNftMarker;
            assert (markerTerms.price > 0) throw Errors.InvalidPrice;
            assert (markerTerms.feeBps <= 10000) throw Errors.InvalidFeeBps;
            assert (markerTerms.feeWallet == storage.feeWallet) throw Errors.InvalidFeeConfig;
            assert (markerTerms.feeBps == storage.feeBps) throw Errors.InvalidFeeConfig;
            assert (markerTerms.expiresAt > blockchain.now()) throw Errors.InvalidExpiry;
            assert (markerTerms.expiresAt <= blockchain.now() + storage.defaultLifetimeSeconds) throw Errors.InvalidExpiry;
            assert (markerTerms.marketplaceIntentHash != 0) throw Errors.InvalidIntentHash;

            val parties = SaleParties {
                seller: marker.sellerAddress,
                nftItem: in.senderAddress,
            };
            val terms = SaleTerms {
                price: markerTerms.price,
                feeWallet: markerTerms.feeWallet,
                feeBps: markerTerms.feeBps,
                expiresAt: markerTerms.expiresAt,
                marketplaceIntentHash: markerTerms.marketplaceIntentHash,
            };
            val saleStorage = buildSaleStorage(contract.getAddress(), parties, terms);
            val saleState = ContractState {
                code: storage.saleCode,
                data: saleStorage.toCell(),
            };
            val expectedSale = AutoDeployAddress { stateInit: saleState }.calculateAddress();

            val pendingAdded = storage.pendingDeposits.addIfNotExists(
                parties.nftItem,
                FactoryPendingDeposit {
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
                value: saleDeployValue(),
                dest: { stateInit: saleState },
                body: SaleRequestDeposit {
                    queryId: marker.queryId,
                    marketplaceIntentHash: markerTerms.marketplaceIntentHash,
                    factoryRefundBudget: factoryListRefundBudget(in.valueCoins),
                },
            });
            deploySale.send(SEND_MODE_REGULAR);
        }
        FactoryDepositNft => {
            var storage = lazy FactoryStorage.load();
            val parties = msg.parties.load();
            val terms = msg.terms.load();
            val expectedSale = calculateSaleAddressFrom(
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
            assertSameTerms(terms, pendingTerms);
            assert (contract.getOriginalBalance() >= factoryNftTransferValue()) throw Errors.InsufficientReserve;

            pending.transferQueryId = msg.queryId;
            pending.stage = FactoryPendingStage.TransferringToSale;
            storage.pendingDeposits.set(parties.nftItem, pending.toCell());
            storage.save();

            val transferNft = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                value: factoryNftTransferValue(),
                dest: parties.nftItem,
                body: NftTransfer {
                    queryId: msg.queryId,
                    newOwner: in.senderAddress,
                    responseDestination: contract.getAddress(),
                    customPayload: MarketTlbMaybe<Cell<cell>>.none(),
                    forwardAmount: factoryNftForwardValue(),
                    forwardPayload: MarketTlbEither<cell, Cell<cell>>.left(
                        saleDepositMarkerPayload(msg.queryId, terms.marketplaceIntentHash, parties.seller),
                    ),
                },
            });
            transferNft.send(SEND_MODE_REGULAR);

            sendFactoryListExcessRefund(parties.seller, factoryNftTransferValue(), msg.factoryRefundBudget);
        }
        FactoryDepositCompleted => {
            var storage = lazy FactoryStorage.load();
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
            var storage = lazy FactoryStorage.load();
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
            assert (in.valueCoins >= minFactoryActionValue()) throw Errors.InsufficientValue;
            assert (contract.getOriginalBalance() >= factoryNftTransferValue() + factoryReserve()) throw Errors.InsufficientReserve;

            pending.recoveryQueryId = msg.queryId;
            pending.stage = FactoryPendingStage.RecoveringToSeller;
            storage.pendingDeposits.set(msg.nftItem, pending.toCell());
            storage.save();

            val transferNft = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                value: factoryNftTransferValue(),
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
            var storage = lazy FactoryStorage.load();
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
            var storage = lazy FactoryStorage.load();
            assert (in.senderAddress == storage.owner) throw Errors.NotFactoryOwner;
            storage.createPaused = msg.paused;
            storage.save();
        }
        FactorySetFeeConfig => {
            var storage = lazy FactoryStorage.load();
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
    var storage = lazy FactoryStorage.load();
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
    val storage = lazy FactoryStorage.load();
    return storage.owner;
}

get fun feeWallet(): address {
    val storage = lazy FactoryStorage.load();
    return storage.feeWallet;
}

get fun feeBps(): uint16 {
    val storage = lazy FactoryStorage.load();
    return storage.feeBps;
}

get fun defaultLifetimeSeconds(): uint32 {
    val storage = lazy FactoryStorage.load();
    return storage.defaultLifetimeSeconds;
}

get fun createPaused(): bool {
    val storage = lazy FactoryStorage.load();
    return storage.createPaused;
}

get fun nextSaleId(): uint64 {
    val storage = lazy FactoryStorage.load();
    return storage.nextSaleId;
}

get fun pendingDepositStage(nftItem: address): uint8 {
    val storage = lazy FactoryStorage.load();
    val lookup = storage.pendingDeposits.get(nftItem);
    if (!lookup.isFound) {
        return 0;
    }

    return lookup.loadValue().load().stage as uint8;
}

get fun pendingDepositSeller(nftItem: address): address? {
    val storage = lazy FactoryStorage.load();
    val lookup = storage.pendingDeposits.get(nftItem);
    if (!lookup.isFound) {
        return null;
    }

    return lookup.loadValue().load().seller;
}

get fun calculateSaleAddress(
    seller: address,
    nftItem: address,
    price: coins,
    feeWallet: address,
    feeBps: uint16,
    expiresAt: uint64,
    marketplaceIntentHash: uint256,
): address {
    val storage = lazy FactoryStorage.load();
    val parties = SaleParties {
        seller,
        nftItem,
    };
    val terms = SaleTerms {
        price,
        feeWallet,
        feeBps,
        expiresAt,
        marketplaceIntentHash,
    };
    return calculateSaleAddressFrom(contract.getAddress(), storage.saleCode, parties, terms);
}
