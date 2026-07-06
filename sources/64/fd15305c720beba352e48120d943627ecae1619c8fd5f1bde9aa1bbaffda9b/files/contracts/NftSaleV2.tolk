import "types"

contract NftSaleV2 {
    author: "Grapes Marketplace"
    version: "0.2.0"
    description: "Per-listing Telegram Gift NFT sale contract with fixed-native and live-USD quote pricing"
    storage: SaleV2Storage
    incomingMessages: SaleV2Message
}

fun minBuyGasValueV2(): coins {
    return ton("0.06");
}

fun storageReserveV2(): coins {
    return ton("0.05");
}

fun terminalReserveV2(): coins {
    return ton("0.08");
}

fun minTerminalRefundValueV2(): coins {
    return ton("0.01");
}

fun nftTransferValueV2(): coins {
    return ton("0.05");
}

fun minActionGasValueV2(): coins {
    return ton("0.1");
}

fun factoryDepositCompletedValueV2(): coins {
    return ton("0.01");
}

fun factoryDepositReadyValueV2(): coins {
    return ton("0.1");
}

fun liveRateNanoUnitV2(): coins {
    return ton("0.01");
}

fun ceilDivV2(value: int, divisor: int): int {
    assert (value >= 0) throw Errors.InvalidQuote;
    assert (divisor > 0) throw Errors.InvalidQuote;
    if (value == 0) {
        return 0;
    }

    return (value + divisor - 1) / divisor;
}

fun computeLivePriceNanoV2(usdPriceMicro: uint64, rateUsdPerGramMicro: uint64): coins {
    assert (usdPriceMicro > 0) throw Errors.InvalidQuote;
    assert (rateUsdPerGramMicro > 0) throw Errors.InvalidQuote;

    val centiGram = ceilDivV2((usdPriceMicro as int) * 100, rateUsdPerGramMicro as int);
    return centiGram * liveRateNanoUnitV2();
}

fun loadDepositMarkerV2(
    payload: MarketTlbEither<cell, Cell<cell>>,
): SaleDepositMarker {
    return match (payload) {
        MarketTlbEitherLeft => SaleDepositMarker.fromCell(payload.value),
        MarketTlbEitherRight => SaleDepositMarker.fromCell(payload.value),
    };
}

fun sendNftTransferV2(nftItem: address, queryId: uint64, newOwner: address) {
    val transferNft = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        value: nftTransferValueV2(),
        dest: nftItem,
        body: NftTransfer {
            queryId,
            newOwner,
            responseDestination: contract.getAddress(),
            customPayload: MarketTlbMaybe<Cell<cell>>.none(),
            forwardAmount: ton("0"),
            forwardPayload: MarketTlbEither<cell, Cell<cell>>.left(createEmptyCell()),
        },
    });
    transferNft.send(SEND_MODE_REGULAR);
}

fun sendTerminalExcessRefundV2(recipient: address, reservedOutgoing: coins, maxRefund: coins) {
    if (maxRefund < minTerminalRefundValueV2()) {
        return;
    }

    val originalBalance = contract.getOriginalBalance();
    if (originalBalance <= reservedOutgoing + terminalReserveV2() + minTerminalRefundValueV2()) {
        return;
    }

    var refundAmount = originalBalance - reservedOutgoing - terminalReserveV2();
    if (refundAmount > maxRefund) {
        refundAmount = maxRefund;
    }

    if (refundAmount < minTerminalRefundValueV2()) {
        return;
    }

    val refund = createMessage({
        bounce: BounceMode.NoBounce,
        value: refundAmount,
        dest: recipient,
    });
    refund.send(SEND_MODE_REGULAR);
}

fun validateLiveQuoteV2(
    storage: SaleV2Storage,
    parties: SaleParties,
    terms: SaleV2Terms,
    senderAddress: address,
    quoteCell: Cell<SaleV2LiveQuote>,
    signature: bits512,
): coins {
    val policy = terms.pricing.load();
    assert (policy.pricingMode == SalePricingMode.LiveUsdQuote as uint8) throw Errors.InvalidPricingMode;
    assert (policy.usdPriceMicro > 0) throw Errors.InvalidPrice;
    assert (policy.rateScale == 1000000) throw Errors.InvalidQuote;
    assert (policy.oraclePublicKey != 0) throw Errors.InvalidQuote;

    val quote = quoteCell.load();
    val scope = quote.scope.load();
    val listing = quote.listing.load();
    val pricing = quote.pricing.load();
    val now = blockchain.now();

    assert (scope.networkId == policy.networkId) throw Errors.InvalidQuote;
    assert (scope.factory == storage.factory) throw Errors.InvalidQuote;
    assert (scope.sale == contract.getAddress()) throw Errors.InvalidQuote;
    assert (scope.buyer == senderAddress) throw Errors.BuyerMismatch;
    assert (listing.seller == parties.seller) throw Errors.InvalidQuote;
    assert (listing.nftItem == parties.nftItem) throw Errors.InvalidQuote;
    assert (listing.marketplaceIntentHash == terms.marketplaceIntentHash) throw Errors.WrongNftMarker;
    assert (listing.usdPriceMicro == policy.usdPriceMicro) throw Errors.InvalidQuote;
    assert (pricing.issuedAt <= now + 60) throw Errors.QuoteNotActive;
    assert (pricing.expiresAt >= now) throw Errors.QuoteExpired;
    assert (pricing.expiresAt <= terms.expiresAt) throw Errors.QuoteExpired;
    assert (pricing.quoteId != 0) throw Errors.InvalidQuote;

    val expectedPrice = computeLivePriceNanoV2(
        policy.usdPriceMicro,
        pricing.rateUsdPerGramMicro,
    );
    assert (pricing.priceNano == expectedPrice) throw Errors.QuotePriceMismatch;
    assert (pricing.priceNano >= policy.minPriceNano) throw Errors.QuotePriceMismatch;
    assert (pricing.priceNano <= policy.maxPriceNano) throw Errors.QuotePriceMismatch;
    assert (
        isSignatureValid(quoteCell.hash(), signature as slice, policy.oraclePublicKey)
    ) throw Errors.InvalidSignature;

    return pricing.priceNano;
}

type SaleV2Message =
    | SaleRequestDeposit
    | SaleV2BuyFixed
    | SaleV2BuyLive
    | SaleCancel
    | SaleRetryTransfer
    | SaleRefundBuy
    | NftOwnershipAssigned
    | NftExcesses

fun onInternalMessage(in: InMessage) {
    val msg = lazy SaleV2Message.fromSlice(in.body);

    match (msg) {
        SaleRequestDeposit => {
            val storage = lazy SaleV2Storage.load();
            val terms = storage.terms.load();

            assert (in.senderAddress == storage.factory) throw Errors.NotSeller;
            assert (storage.state == 0) throw Errors.SaleNotActive;
            assert (
                msg.marketplaceIntentHash == terms.marketplaceIntentHash
            ) throw Errors.WrongNftMarker;
            assert (
                contract.getOriginalBalance() >= storageReserveV2() + factoryDepositReadyValueV2()
            ) throw Errors.InsufficientReserve;

            val ready = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                value: factoryDepositReadyValueV2(),
                dest: storage.factory,
                body: FactoryV2DepositNft {
                    queryId: msg.queryId,
                    parties: storage.parties,
                    terms: storage.terms,
                    factoryRefundBudget: msg.factoryRefundBudget,
                },
            });
            ready.send(SEND_MODE_REGULAR);
        }
        SaleV2BuyFixed => {
            var storage = lazy SaleV2Storage.load();
            val parties = storage.parties.load();
            val terms = storage.terms.load();
            val policy = terms.pricing.load();

            assert (policy.pricingMode == SalePricingMode.FixedNative as uint8) throw Errors.InvalidPricingMode;
            assert (storage.state == 1) throw Errors.SaleNotActive;
            assert (blockchain.now() < terms.expiresAt) throw Errors.SaleExpired;
            assert (in.senderAddress == msg.buyerAddress) throw Errors.BuyerMismatch;
            assert (msg.expectedPriceNano == policy.fixedPrice) throw Errors.PriceMismatch;
            assert (
                msg.marketplaceIntentHash == terms.marketplaceIntentHash
            ) throw Errors.WrongNftMarker;
            assert (in.valueCoins >= policy.fixedPrice + minBuyGasValueV2()) throw Errors.InsufficientValue;
            assert (
                contract.getOriginalBalance() >= policy.fixedPrice + storageReserveV2() + nftTransferValueV2()
            ) throw Errors.InsufficientReserve;

            storage.state = SaleState.SettlingBuy;
            storage.settlement = SaleV2Settlement {
                buyer: msg.buyerAddress,
                refundRecipient: msg.buyerAddress,
                refundBudget: in.valueCoins - policy.fixedPrice,
                nftTransferQueryId: msg.queryId,
                settlementPrice: policy.fixedPrice,
                payoutDone: false,
            }.toCell();
            storage.save();

            sendNftTransferV2(parties.nftItem, msg.queryId, msg.buyerAddress);
        }
        SaleV2BuyLive => {
            var storage = lazy SaleV2Storage.load();
            val parties = storage.parties.load();
            val terms = storage.terms.load();

            assert (storage.state == 1) throw Errors.SaleNotActive;
            assert (blockchain.now() < terms.expiresAt) throw Errors.SaleExpired;
            val price = validateLiveQuoteV2(storage, parties, terms, in.senderAddress, msg.quote, msg.signature);
            assert (in.valueCoins >= price + minBuyGasValueV2()) throw Errors.InsufficientValue;
            assert (
                contract.getOriginalBalance() >= price + storageReserveV2() + nftTransferValueV2()
            ) throw Errors.InsufficientReserve;

            val quote = msg.quote.load();
            val scope = quote.scope.load();
            storage.state = SaleState.SettlingBuy;
            storage.settlement = SaleV2Settlement {
                buyer: scope.buyer,
                refundRecipient: scope.buyer,
                refundBudget: in.valueCoins - price,
                nftTransferQueryId: msg.queryId,
                settlementPrice: price,
                payoutDone: false,
            }.toCell();
            storage.save();

            sendNftTransferV2(parties.nftItem, msg.queryId, scope.buyer);
        }
        SaleCancel => {
            var storage = lazy SaleV2Storage.load();
            val parties = storage.parties.load();
            val terms = storage.terms.load();
            val canCancel = in.senderAddress == parties.seller ||
            blockchain.now() >= terms.expiresAt;

            assert (
                msg.marketplaceIntentHash == terms.marketplaceIntentHash
            ) throw Errors.WrongNftMarker;
            assert (storage.state == 0 || storage.state == 1) throw Errors.SaleNotActive;
            assert (canCancel) throw Errors.SaleNotExpired;
            assert (in.valueCoins >= minActionGasValueV2()) throw Errors.InsufficientValue;

            if (storage.state == 0) {
                storage.state = SaleState.Cancelled;
                storage.settlement = SaleV2Settlement {
                    buyer: null,
                    refundRecipient: in.senderAddress,
                    refundBudget: in.valueCoins,
                    nftTransferQueryId: msg.queryId,
                    settlementPrice: 0,
                    payoutDone: true,
                }.toCell();
                storage.save();
                sendTerminalExcessRefundV2(in.senderAddress, ton("0"), in.valueCoins);
                return;
            }

            assert (
                contract.getOriginalBalance() >= storageReserveV2() + nftTransferValueV2()
            ) throw Errors.InsufficientReserve;

            storage.state = SaleState.SettlingCancel;
            storage.settlement = SaleV2Settlement {
                buyer: null,
                refundRecipient: in.senderAddress,
                refundBudget: in.valueCoins,
                nftTransferQueryId: msg.queryId,
                settlementPrice: 0,
                payoutDone: false,
            }.toCell();
            storage.save();

            sendNftTransferV2(parties.nftItem, msg.queryId, parties.seller);
        }
        SaleRetryTransfer => {
            var storage = lazy SaleV2Storage.load();
            val parties = storage.parties.load();
            val terms = storage.terms.load();
            val settlement = storage.settlement.load();

            assert (
                msg.marketplaceIntentHash == terms.marketplaceIntentHash
            ) throw Errors.WrongNftMarker;
            assert (storage.state == 6 || storage.state == 7) throw Errors.SaleNotActive;
            assert (in.valueCoins >= minActionGasValueV2()) throw Errors.InsufficientValue;
            assert (
                contract.getOriginalBalance() >= storageReserveV2() + nftTransferValueV2()
            ) throw Errors.InsufficientReserve;

            if (storage.state == 6) {
                assert (settlement.buyer != null) throw Errors.WrongNftResponse;

                storage.state = SaleState.SettlingBuy;
                storage.settlement = SaleV2Settlement {
                    buyer: settlement.buyer,
                    refundRecipient: settlement.refundRecipient,
                    refundBudget: settlement.refundBudget,
                    nftTransferQueryId: msg.queryId,
                    settlementPrice: settlement.settlementPrice,
                    payoutDone: false,
                }.toCell();
                storage.save();

                sendNftTransferV2(parties.nftItem, msg.queryId, settlement.buyer!);
                return;
            }

            storage.state = SaleState.SettlingCancel;
            storage.settlement = SaleV2Settlement {
                buyer: null,
                refundRecipient: settlement.refundRecipient,
                refundBudget: settlement.refundBudget,
                nftTransferQueryId: msg.queryId,
                settlementPrice: 0,
                payoutDone: false,
            }.toCell();
            storage.save();

            sendNftTransferV2(parties.nftItem, msg.queryId, parties.seller);
        }
        SaleRefundBuy => {
            var storage = lazy SaleV2Storage.load();
            val terms = storage.terms.load();
            val settlement = storage.settlement.load();

            assert (
                msg.marketplaceIntentHash == terms.marketplaceIntentHash
            ) throw Errors.WrongNftMarker;
            assert (storage.state == 6) throw Errors.SaleNotActive;
            assert (settlement.buyer != null) throw Errors.WrongNftResponse;
            assert (settlement.settlementPrice > 0) throw Errors.WrongNftResponse;
            assert (in.senderAddress == settlement.buyer!) throw Errors.NotBuyer;
            assert (in.valueCoins >= minActionGasValueV2()) throw Errors.InsufficientValue;
            assert (
                contract.getOriginalBalance() >= settlement.settlementPrice + storageReserveV2()
            ) throw Errors.InsufficientReserve;

            storage.state = SaleState.Active;
            storage.settlement = SaleV2Settlement {
                buyer: null,
                refundRecipient: null,
                refundBudget: 0,
                nftTransferQueryId: msg.queryId,
                settlementPrice: 0,
                payoutDone: false,
            }.toCell();
            storage.save();

            val refund = createMessage({
                bounce: BounceMode.NoBounce,
                value: settlement.settlementPrice,
                dest: in.senderAddress,
            });
            refund.send(SEND_MODE_PAY_FEES_SEPARATELY);
        }
        NftOwnershipAssigned => {
            var storage = lazy SaleV2Storage.load();
            val parties = storage.parties.load();
            val terms = storage.terms.load();
            val marker = loadDepositMarkerV2(msg.forwardPayload);

            assert (in.senderAddress == parties.nftItem) throw Errors.WrongNftSender;
            assert (storage.state == 0) throw Errors.SaleNotActive;
            assert (
                msg.prevOwner == parties.seller || msg.prevOwner == storage.factory
            ) throw Errors.WrongNftMarker;
            assert (
                marker.marketplaceIntentHash == terms.marketplaceIntentHash
            ) throw Errors.WrongNftMarker;
            assert (marker.sellerAddress == parties.seller) throw Errors.WrongNftMarker;

            storage.state = SaleState.Active;
            storage.settlement = SaleV2Settlement {
                buyer: null,
                refundRecipient: null,
                refundBudget: 0,
                nftTransferQueryId: msg.queryId,
                settlementPrice: 0,
                payoutDone: false,
            }.toCell();
            storage.save();

            if (msg.prevOwner == storage.factory) {
                val completed = createMessage({
                    bounce: BounceMode.NoBounce,
                    value: factoryDepositCompletedValueV2(),
                    dest: storage.factory,
                    body: FactoryDepositCompleted {
                        queryId: msg.queryId,
                        nftItem: parties.nftItem,
                        marketplaceIntentHash: terms.marketplaceIntentHash,
                    },
                });
                completed.send(SEND_MODE_REGULAR);
            }
        }
        NftExcesses => {
            var storage = lazy SaleV2Storage.load();
            val parties = storage.parties.load();
            val settlement = storage.settlement.load();

            assert (in.senderAddress == parties.nftItem) throw Errors.WrongNftResponse;
            assert (storage.state == 2 || storage.state == 3) throw Errors.SaleNotActive;
            assert (settlement.nftTransferQueryId == msg.queryId) throw Errors.WrongNftResponse;
            assert (!settlement.payoutDone) throw Errors.AlreadySettled;

            if (storage.state == 3) {
                assert (settlement.refundRecipient != null) throw Errors.WrongNftResponse;
                storage.state = SaleState.Cancelled;
                storage.settlement = SaleV2Settlement {
                    buyer: null,
                    refundRecipient: null,
                    refundBudget: 0,
                    nftTransferQueryId: settlement.nftTransferQueryId,
                    settlementPrice: 0,
                    payoutDone: true,
                }.toCell();
                storage.save();
                sendTerminalExcessRefundV2(settlement.refundRecipient!, ton("0"), settlement.refundBudget);
                return;
            }

            assert (settlement.buyer != null) throw Errors.WrongNftResponse;
            assert (settlement.refundRecipient != null) throw Errors.WrongNftResponse;
            assert (settlement.settlementPrice > 0) throw Errors.WrongNftResponse;
            val fee = settlement.settlementPrice * storage.terms.load().feeBps / 10000;
            val sellerAmount = settlement.settlementPrice - fee;
            assert (
                contract.getOriginalBalance() >= settlement.settlementPrice + storageReserveV2()
            ) throw Errors.InsufficientReserve;

            storage.state = SaleState.Sold;
            storage.settlement = SaleV2Settlement {
                buyer: settlement.buyer,
                refundRecipient: settlement.refundRecipient,
                refundBudget: settlement.refundBudget,
                nftTransferQueryId: settlement.nftTransferQueryId,
                settlementPrice: settlement.settlementPrice,
                payoutDone: true,
            }.toCell();
            storage.save();

            val paySeller = createMessage({
                bounce: BounceMode.NoBounce,
                value: sellerAmount,
                dest: parties.seller,
            });
            paySeller.send(SEND_MODE_PAY_FEES_SEPARATELY);

            val payFee = createMessage({
                bounce: BounceMode.NoBounce,
                value: fee,
                dest: storage.terms.load().feeWallet,
            });
            payFee.send(SEND_MODE_PAY_FEES_SEPARATELY);

            sendTerminalExcessRefundV2(
                settlement.refundRecipient!,
                settlement.settlementPrice,
                settlement.refundBudget,
            );
        }
        else => {
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
        }
    }
}

fun onBouncedMessage(in: InMessageBounced) {
    var storage = lazy SaleV2Storage.load();
    val parties = storage.parties.load();
    val settlement = storage.settlement.load();
    var body = in.bouncedBody;

    assert (in.senderAddress == parties.nftItem) throw Errors.WrongNftResponse;
    body.skipBouncedPrefix();
    val op = body.loadUint(32);
    assert (op == 0x5fcc3d14) throw Errors.WrongNftResponse;
    val queryId = body.loadUint(64);
    assert (settlement.nftTransferQueryId == queryId) throw Errors.WrongNftResponse;
    assert (storage.state == 2 || storage.state == 3) throw Errors.SaleNotActive;
    assert (!settlement.payoutDone) throw Errors.AlreadySettled;

    if (storage.state == 2) {
        storage.state = SaleState.TransferFailedBuy;
    } else {
        storage.state = SaleState.TransferFailedCancel;
    }
    storage.save();
}

get fun factory(): address {
    val storage = lazy SaleV2Storage.load();
    return storage.factory;
}

get fun saleId(): uint64 {
    val storage = lazy SaleV2Storage.load();
    return storage.saleId;
}

get fun seller(): address {
    val storage = lazy SaleV2Storage.load();
    return storage.parties.load().seller;
}

get fun nftItem(): address {
    val storage = lazy SaleV2Storage.load();
    return storage.parties.load().nftItem;
}

get fun pricingMode(): uint8 {
    val storage = lazy SaleV2Storage.load();
    return storage.terms.load().pricing.load().pricingMode;
}

get fun networkId(): uint32 {
    val storage = lazy SaleV2Storage.load();
    return storage.terms.load().pricing.load().networkId;
}

get fun fixedPrice(): coins {
    val storage = lazy SaleV2Storage.load();
    return storage.terms.load().pricing.load().fixedPrice;
}

get fun usdPriceMicro(): uint64 {
    val storage = lazy SaleV2Storage.load();
    return storage.terms.load().pricing.load().usdPriceMicro;
}

get fun oraclePublicKey(): uint256 {
    val storage = lazy SaleV2Storage.load();
    return storage.terms.load().pricing.load().oraclePublicKey;
}

get fun rateScale(): uint32 {
    val storage = lazy SaleV2Storage.load();
    return storage.terms.load().pricing.load().rateScale;
}

get fun minPriceNano(): coins {
    val storage = lazy SaleV2Storage.load();
    return storage.terms.load().pricing.load().minPriceNano;
}

get fun maxPriceNano(): coins {
    val storage = lazy SaleV2Storage.load();
    return storage.terms.load().pricing.load().maxPriceNano;
}

get fun feeWallet(): address {
    val storage = lazy SaleV2Storage.load();
    return storage.terms.load().feeWallet;
}

get fun feeBps(): uint16 {
    val storage = lazy SaleV2Storage.load();
    return storage.terms.load().feeBps;
}

get fun expiresAt(): uint64 {
    val storage = lazy SaleV2Storage.load();
    return storage.terms.load().expiresAt;
}

get fun marketplaceIntentHash(): uint256 {
    val storage = lazy SaleV2Storage.load();
    return storage.terms.load().marketplaceIntentHash;
}

get fun state(): uint8 {
    val storage = lazy SaleV2Storage.load();
    return storage.state;
}

get fun buyer(): address? {
    val storage = lazy SaleV2Storage.load();
    return storage.settlement.load().buyer;
}

get fun nftTransferQueryId(): uint64 {
    val storage = lazy SaleV2Storage.load();
    return storage.settlement.load().nftTransferQueryId;
}

get fun settlementPrice(): coins {
    val storage = lazy SaleV2Storage.load();
    return storage.settlement.load().settlementPrice;
}

get fun payoutDone(): bool {
    val storage = lazy SaleV2Storage.load();
    return storage.settlement.load().payoutDone;
}
