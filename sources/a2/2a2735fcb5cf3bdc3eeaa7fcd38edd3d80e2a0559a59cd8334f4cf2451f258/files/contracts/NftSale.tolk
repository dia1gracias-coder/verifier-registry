import "types"

contract NftSale {
    author: "Grapes Marketplace"
    version: "0.1.0"
    description: "Per-listing Telegram Gift NFT sale contract"
    storage: SaleStorage
    incomingMessages: SaleMessage
}

type SaleMessage =
    | SaleRequestDeposit
    | SaleBuy
    | SaleCancel
    | SaleRetryTransfer
    | SaleRefundBuy
    | NftOwnershipAssigned
    | NftExcesses

fun minBuyGasValue(): coins {
    return ton("0.06");
}

fun storageReserve(): coins {
    return ton("0.05");
}

fun terminalReserve(): coins {
    return ton("0.08");
}

fun minTerminalRefundValue(): coins {
    return ton("0.01");
}

fun nftTransferValue(): coins {
    return ton("0.05");
}

fun minActionGasValue(): coins {
    return ton("0.1");
}

fun factoryDepositReadyValue(): coins {
    return ton("0.1");
}

fun factoryDepositCompletedValue(): coins {
    return ton("0.01");
}

fun loadDepositMarker(
    payload: MarketTlbEither<cell, Cell<cell>>,
): SaleDepositMarker {
    return match (payload) {
        MarketTlbEitherLeft => SaleDepositMarker.fromCell(payload.value),
        MarketTlbEitherRight => SaleDepositMarker.fromCell(payload.value),
    };
}

fun sendNftTransfer(nftItem: address, queryId: uint64, newOwner: address) {
    val transferNft = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        value: nftTransferValue(),
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

fun sendTerminalExcessRefund(recipient: address, reservedOutgoing: coins, maxRefund: coins) {
    if (maxRefund < minTerminalRefundValue()) {
        return;
    }

    val originalBalance = contract.getOriginalBalance();
    if (originalBalance <= reservedOutgoing + terminalReserve() + minTerminalRefundValue()) {
        return;
    }

    var refundAmount = originalBalance - reservedOutgoing - terminalReserve();
    if (refundAmount > maxRefund) {
        refundAmount = maxRefund;
    }

    if (refundAmount < minTerminalRefundValue()) {
        return;
    }

    val refund = createMessage({
        bounce: BounceMode.NoBounce,
        value: refundAmount,
        dest: recipient,
    });
    refund.send(SEND_MODE_REGULAR);
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy SaleMessage.fromSlice(in.body);

    match (msg) {
        SaleRequestDeposit => {
            val storage = lazy SaleStorage.load();
            val terms = storage.terms.load();

            assert (in.senderAddress == storage.factory) throw Errors.NotSeller;
            assert (storage.state == 0) throw Errors.SaleNotActive;
            assert (
                msg.marketplaceIntentHash == terms.marketplaceIntentHash
            ) throw Errors.WrongNftMarker;
            assert (
                contract.getOriginalBalance() >= storageReserve() + factoryDepositReadyValue()
            ) throw Errors.InsufficientReserve;

            val ready = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                value: factoryDepositReadyValue(),
                dest: storage.factory,
                body: FactoryDepositNft {
                    queryId: msg.queryId,
                    parties: storage.parties,
                    terms: storage.terms,
                    factoryRefundBudget: msg.factoryRefundBudget,
                },
            });
            ready.send(SEND_MODE_REGULAR);
        }
        SaleBuy => {
            var storage = lazy SaleStorage.load();
            val terms = storage.terms.load();

            assert (storage.state == 1) throw Errors.SaleNotActive;
            assert (blockchain.now() < terms.expiresAt) throw Errors.SaleExpired;
            assert (in.senderAddress == msg.buyerAddress) throw Errors.BuyerMismatch;
            assert (msg.expectedPriceNano == terms.price) throw Errors.PriceMismatch;
            assert (
                msg.marketplaceIntentHash == terms.marketplaceIntentHash
            ) throw Errors.WrongNftMarker;
            assert (in.valueCoins >= terms.price + minBuyGasValue()) throw Errors.InsufficientValue;
            assert (
                contract.getOriginalBalance() >= terms.price + storageReserve() + nftTransferValue()
            ) throw Errors.InsufficientReserve;

            storage.state = SaleState.SettlingBuy;
            storage.settlement = SaleSettlement {
                buyer: msg.buyerAddress,
                refundRecipient: msg.buyerAddress,
                refundBudget: in.valueCoins - terms.price,
                nftTransferQueryId: msg.queryId,
                payoutDone: false,
            }.toCell();
            storage.save();

            val parties = storage.parties.load();
            sendNftTransfer(parties.nftItem, msg.queryId, msg.buyerAddress);
        }
        SaleCancel => {
            var storage = lazy SaleStorage.load();
            val parties = storage.parties.load();
            val terms = storage.terms.load();
            val canCancel = in.senderAddress == parties.seller ||
            blockchain.now() >= terms.expiresAt;

            assert (
                msg.marketplaceIntentHash == terms.marketplaceIntentHash
            ) throw Errors.WrongNftMarker;
            assert (storage.state == 0 || storage.state == 1) throw Errors.SaleNotActive;
            assert (canCancel) throw Errors.SaleNotExpired;
            assert (in.valueCoins >= minActionGasValue()) throw Errors.InsufficientValue;

            if (storage.state == 0) {
                storage.state = SaleState.Cancelled;
                storage.settlement = SaleSettlement {
                    buyer: null,
                    refundRecipient: in.senderAddress,
                    refundBudget: in.valueCoins,
                    nftTransferQueryId: msg.queryId,
                    payoutDone: true,
                }.toCell();
                storage.save();
                sendTerminalExcessRefund(in.senderAddress, ton("0"), in.valueCoins);
                return;
            }

            assert (
                contract.getOriginalBalance() >= storageReserve() + nftTransferValue()
            ) throw Errors.InsufficientReserve;

            storage.state = SaleState.SettlingCancel;
            storage.settlement = SaleSettlement {
                buyer: null,
                refundRecipient: in.senderAddress,
                refundBudget: in.valueCoins,
                nftTransferQueryId: msg.queryId,
                payoutDone: false,
            }.toCell();
            storage.save();

            sendNftTransfer(parties.nftItem, msg.queryId, parties.seller);
        }
        SaleRetryTransfer => {
            var storage = lazy SaleStorage.load();
            val parties = storage.parties.load();
            val terms = storage.terms.load();
            val settlement = storage.settlement.load();

            assert (
                msg.marketplaceIntentHash == terms.marketplaceIntentHash
            ) throw Errors.WrongNftMarker;
            assert (storage.state == 6 || storage.state == 7) throw Errors.SaleNotActive;
            assert (in.valueCoins >= minActionGasValue()) throw Errors.InsufficientValue;
            assert (
                contract.getOriginalBalance() >= storageReserve() + nftTransferValue()
            ) throw Errors.InsufficientReserve;

            if (storage.state == 6) {
                assert (settlement.buyer != null) throw Errors.WrongNftResponse;

                storage.state = SaleState.SettlingBuy;
                storage.settlement = SaleSettlement {
                    buyer: settlement.buyer,
                    refundRecipient: settlement.refundRecipient,
                    refundBudget: settlement.refundBudget,
                    nftTransferQueryId: msg.queryId,
                    payoutDone: false,
                }.toCell();
                storage.save();

                sendNftTransfer(parties.nftItem, msg.queryId, settlement.buyer!);
                return;
            }

            storage.state = SaleState.SettlingCancel;
            storage.settlement = SaleSettlement {
                buyer: null,
                refundRecipient: settlement.refundRecipient,
                refundBudget: settlement.refundBudget,
                nftTransferQueryId: msg.queryId,
                payoutDone: false,
            }.toCell();
            storage.save();

            sendNftTransfer(parties.nftItem, msg.queryId, parties.seller);
        }
        SaleRefundBuy => {
            var storage = lazy SaleStorage.load();
            val terms = storage.terms.load();
            val settlement = storage.settlement.load();

            assert (
                msg.marketplaceIntentHash == terms.marketplaceIntentHash
            ) throw Errors.WrongNftMarker;
            assert (storage.state == 6) throw Errors.SaleNotActive;
            assert (settlement.buyer != null) throw Errors.WrongNftResponse;
            assert (in.senderAddress == settlement.buyer!) throw Errors.NotBuyer;
            assert (in.valueCoins >= minActionGasValue()) throw Errors.InsufficientValue;
            assert (
                contract.getOriginalBalance() >= terms.price + storageReserve()
            ) throw Errors.InsufficientReserve;

            storage.state = SaleState.Active;
            storage.settlement = SaleSettlement {
                buyer: null,
                refundRecipient: null,
                refundBudget: 0,
                nftTransferQueryId: msg.queryId,
                payoutDone: false,
            }.toCell();
            storage.save();

            val refund = createMessage({
                bounce: BounceMode.NoBounce,
                value: terms.price,
                dest: in.senderAddress,
            });
            refund.send(SEND_MODE_PAY_FEES_SEPARATELY);
        }
        NftOwnershipAssigned => {
            var storage = lazy SaleStorage.load();
            val parties = storage.parties.load();
            val terms = storage.terms.load();
            val marker = loadDepositMarker(msg.forwardPayload);

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
            storage.settlement = SaleSettlement {
                buyer: null,
                refundRecipient: null,
                refundBudget: 0,
                nftTransferQueryId: msg.queryId,
                payoutDone: false,
            }.toCell();
            storage.save();

            if (msg.prevOwner == storage.factory) {
                val completed = createMessage({
                    bounce: BounceMode.NoBounce,
                    value: factoryDepositCompletedValue(),
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
            var storage = lazy SaleStorage.load();
            val parties = storage.parties.load();
            val terms = storage.terms.load();
            val settlement = storage.settlement.load();

            assert (in.senderAddress == parties.nftItem) throw Errors.WrongNftResponse;
            assert (storage.state == 2 || storage.state == 3) throw Errors.SaleNotActive;
            assert (settlement.nftTransferQueryId == msg.queryId) throw Errors.WrongNftResponse;
            assert (!settlement.payoutDone) throw Errors.AlreadySettled;

            if (storage.state == 3) {
                assert (settlement.refundRecipient != null) throw Errors.WrongNftResponse;
                storage.state = SaleState.Cancelled;
                storage.settlement = SaleSettlement {
                    buyer: null,
                    refundRecipient: null,
                    refundBudget: 0,
                    nftTransferQueryId: settlement.nftTransferQueryId,
                    payoutDone: true,
                }.toCell();
                storage.save();
                sendTerminalExcessRefund(settlement.refundRecipient!, ton("0"), settlement.refundBudget);
                return;
            }

            assert (settlement.buyer != null) throw Errors.WrongNftResponse;
            assert (settlement.refundRecipient != null) throw Errors.WrongNftResponse;
            val fee = terms.price * terms.feeBps / 10000;
            val sellerAmount = terms.price - fee;
            assert (
                contract.getOriginalBalance() >= terms.price + storageReserve()
            ) throw Errors.InsufficientReserve;

            storage.state = SaleState.Sold;
            storage.settlement = SaleSettlement {
                buyer: settlement.buyer,
                refundRecipient: settlement.refundRecipient,
                refundBudget: settlement.refundBudget,
                nftTransferQueryId: settlement.nftTransferQueryId,
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
                dest: terms.feeWallet,
            });
            payFee.send(SEND_MODE_PAY_FEES_SEPARATELY);

            sendTerminalExcessRefund(settlement.refundRecipient!, terms.price, settlement.refundBudget);
        }
        else => {
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
        }
    }
}

fun onBouncedMessage(in: InMessageBounced) {
    var storage = lazy SaleStorage.load();
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
    val storage = lazy SaleStorage.load();
    return storage.factory;
}

get fun saleId(): uint64 {
    val storage = lazy SaleStorage.load();
    return storage.saleId;
}

get fun seller(): address {
    val storage = lazy SaleStorage.load();
    return storage.parties.load().seller;
}

get fun nftItem(): address {
    val storage = lazy SaleStorage.load();
    return storage.parties.load().nftItem;
}

get fun price(): coins {
    val storage = lazy SaleStorage.load();
    return storage.terms.load().price;
}

get fun feeWallet(): address {
    val storage = lazy SaleStorage.load();
    return storage.terms.load().feeWallet;
}

get fun feeBps(): uint16 {
    val storage = lazy SaleStorage.load();
    return storage.terms.load().feeBps;
}

get fun expiresAt(): uint64 {
    val storage = lazy SaleStorage.load();
    return storage.terms.load().expiresAt;
}

get fun marketplaceIntentHash(): uint256 {
    val storage = lazy SaleStorage.load();
    return storage.terms.load().marketplaceIntentHash;
}

get fun state(): uint8 {
    val storage = lazy SaleStorage.load();
    return storage.state;
}

get fun buyer(): address? {
    val storage = lazy SaleStorage.load();
    return storage.settlement.load().buyer;
}

get fun nftTransferQueryId(): uint64 {
    val storage = lazy SaleStorage.load();
    return storage.settlement.load().nftTransferQueryId;
}

get fun payoutDone(): bool {
    val storage = lazy SaleStorage.load();
    return storage.settlement.load().payoutDone;
}
