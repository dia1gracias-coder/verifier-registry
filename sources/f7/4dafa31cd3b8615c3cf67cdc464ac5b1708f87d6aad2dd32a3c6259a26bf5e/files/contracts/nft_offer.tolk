import "@stdlib/gas-payments"
import "constant"
import "storage"
import "messages"


fun sendMoney(dest: address, amount: coins, comment: slice) {
    createMessage({
        bounce: BounceMode.NoBounce,
        dest: dest,
        value: amount,
        body: CommentMessage { comment: comment },
    }).send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun sendAllBalance(dest: address, body: cell? = null) {
    createMessage({
        bounce: BounceMode.NoBounce,
        dest: dest,
        value: 0 as coins,
        body: body,
    }).send(SEND_MODE_CARRY_ALL_BALANCE);
}

fun sendJettons(jettonWallet: address, queryId: int, dest: address, amount: int, responseDest: address) {
    if (amount <= 0) { return; }
    createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: jettonWallet,
        value: JETTON_TRANSFER_GAS,
        body: JettonTransfer {
            queryId: queryId as uint64,
            amount: amount as coins,
            destination: dest,
            responseDestination: responseDest,
        },
    }).send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun returnJettons(jettonWallet: address, queryId: int, dest: address, amount: int) {
    createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: jettonWallet,
        value: 0 as coins,
        body: JettonTransfer {
            queryId: queryId as uint64,
            amount: amount as coins,
            destination: dest,
            responseDestination: dest,
        },
    }).send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE + SEND_MODE_IGNORE_ERRORS);
}

fun returnNft(nftAddr: address, prevOwner: address, queryId: int) {
    createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: nftAddr,
        value: 0 as coins,
        body: NftTransfer {
            queryId: queryId as uint64,
            newOwner: prevOwner,
            responseAddress: prevOwner
        },
    }).send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
}

fun cancelOffer(mutate storage: Storage) {
    if (storage.isJettonOffer()) {
        val jd = lazy storage.jettonData!.load();
        if (jd.jettonWalletAddress != null) {
            createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: jd.jettonWalletAddress!,
                value: 0 as coins,
                body: JettonTransfer {
                    queryId: 0 as uint64,
                    amount: storage.fullPrice,
                    destination: storage.offerOwnerAddress,
                    responseDestination: storage.offerOwnerAddress,
                },
            }).send(SEND_MODE_CARRY_ALL_BALANCE);
        }
    } else {
        sendAllBalance(storage.offerOwnerAddress);
    }
    storage.isComplete = true;
    storage.save();
}

fun acceptOffer(mutate storage: Storage, nftOwnerAddress: address, queryId: int) {
    val fees = storage.feesData.load();
    val (royaltyAmount, marketplaceFee, profit) = fees.calcProfit(storage.fullPrice as int);

    assert (profit > 0) throw Err.ProfitTooLow;

    if (storage.isJettonOffer()) {
        val jettonWallet = storage.jettonData!.load().jettonWalletAddress!;
        sendJettons(jettonWallet, queryId, nftOwnerAddress, profit, nftOwnerAddress);
        if (marketplaceFee > 0) {
            sendJettons(jettonWallet, queryId, fees.marketplaceFeeAddress, marketplaceFee, nftOwnerAddress);
        }
        if ((royaltyAmount > 0) & (fees.royaltyAddress != null)) {
            sendJettons(jettonWallet, queryId, fees.royaltyAddress!, royaltyAmount, nftOwnerAddress);
        }
    } else {
        sendMoney(nftOwnerAddress, profit as coins, "Profit");
        if (marketplaceFee > 0) {
            sendMoney(fees.marketplaceFeeAddress, marketplaceFee as coins, "Market fee");
        }
        if ((royaltyAmount > 0) & (fees.royaltyAddress != null)) {
            sendMoney(fees.royaltyAddress!, royaltyAmount as coins, "Royalty");
        }
    }

    createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: storage.nftAddress,
        value: 0 as coins,
        body: NftTransfer {
            queryId: queryId as uint64,
            newOwner: storage.offerOwnerAddress,
            responseAddress: nftOwnerAddress,
            forwardAmount: 1
        },
    }).send(SEND_MODE_CARRY_ALL_BALANCE);

    storage.acceptedAt = blockchain.now() as uint32;
    storage.isComplete = true;
    storage.save();
}

fun onInternalMessage(in: InMessage) {
    var storage = lazy Storage.load();
    val msg = lazy OfferMessage.fromSlice(in.body);
    match (msg) {
        DeployTonOp => {
            /*
            There are two possible ways to deploy the offer SMC using TON:
            1. Set `fullPrice` directly in stateInit and use the `DeployTonOp` opcode to deploy the offer SMC.
            2. Set `fullPrice` to 0 and use op = 0, adding TON as a top-up.

            Use the second method if you want to leave a comment on offer deployment.
            */
        }

        DeployJettonOp => {
            assert ((in.senderAddress == storage.marketplaceAddress) | (in.senderAddress == storage.offerOwnerAddress)) throw Err.Forbidden;
            assert (storage.isJettonOffer()) throw Err.NotJettonOffer;
            val jd = lazy storage.jettonData!.load();
            assert (jd.jettonWalletAddress == null) throw Err.JettonWalletAlreadySet;

            val hash = msg.payload.hash();
            assert (isSignatureValid(hash, msg.signature as slice, jd.publicKey)) throw Err.InvalidSignature;

            var payloadSlice = msg.payload.beginParse();
            val jettonWalletAddress = payloadSlice.loadAddress()!;
            val marketplaceAddress = payloadSlice.loadAddress()!;

            val newJd: JettonData = {
                jettonMasterAddress: jd.jettonMasterAddress,
                jettonWalletAddress: jettonWalletAddress,
                publicKey: jd.publicKey,
            };
            storage.jettonData = newJd.toCell();
            storage.marketplaceAddress = marketplaceAddress;
            storage.save();
        }

        OwnershipAssigned => {
            val minValue = storage.isJettonOffer() ? MIN_MSG_VALUE_JETTON : MIN_MSG_VALUE_TON;
            if ((in.senderAddress == storage.nftAddress) & (!storage.isComplete) & (in.valueCoins >= minValue) & (storage.validUntil > blockchain.now() as uint32)) {
                try {
                    acceptOffer(mutate storage, msg.prevOwner, msg.queryId as int);
                } catch (e) {
                    returnNft(in.senderAddress, msg.prevOwner, msg.queryId as int);
                }
                return;
            }
            returnNft(in.senderAddress, msg.prevOwner, msg.queryId as int);
        }

        // Top-up the offer with jettons
        JettonTransferNotification => {
            if (!storage.isJettonOffer() | storage.isComplete) {
                returnJettons(in.senderAddress, msg.queryId as int, msg.sender, msg.amount as int);
                return;
            }
            val jd = storage.jettonData!.load();
            if ((jd.jettonWalletAddress == null) | (in.senderAddress != jd.jettonWalletAddress!) | (msg.sender != storage.offerOwnerAddress)) {
                returnJettons(in.senderAddress, msg.queryId as int, msg.sender, msg.amount as int);
                return;
            }
            storage.fullPrice = (storage.fullPrice as int + msg.amount as int) as coins;
            storage.save();
        }

        CancelOfferOp => {
            assert (!storage.isComplete) throw Err.OfferCompleted;
            assert ((in.senderAddress == storage.offerOwnerAddress) | (in.senderAddress == storage.marketplaceAddress)) throw Err.Forbidden;

            if (in.senderAddress == storage.marketplaceAddress) {
                sendMoney(storage.marketplaceAddress, in.valueCoins, "Offer cancel by marketplace");
            }
            cancelOffer(mutate storage);
        }

        CommentMessage => {
            if (msg.comment.bitsEqual("cancel")) {
                assert (!storage.isComplete) throw Err.OfferCompleted;
                assert (in.senderAddress == storage.offerOwnerAddress) throw Err.Forbidden;
                cancelOffer(mutate storage);
                return;
            }

            // Top-up the offer with TON
            assert (!storage.isComplete) throw Err.OfferCompleted;
            assert (in.senderAddress == storage.offerOwnerAddress) throw Err.Forbidden;
            assert (!storage.isJettonOffer()) throw Err.NotJettonOffer;
            storage.fullPrice = (storage.fullPrice as int + in.valueCoins as int) as coins;
            storage.save();
        }

        EmergencyMessage => {
            assert (storage.isComplete & (in.senderAddress == storage.marketplaceAddress)) throw Err.Forbidden;

            var refSlice = msg.payload.beginParse();
            val mode = refSlice.loadUint(8);

            if (storage.acceptedAt != 0) {
                val tenMin = 10 * 60;
                val swapAtInt = storage.acceptedAt as int;
                assert (!((blockchain.now() > swapAtInt - tenMin) & (blockchain.now() < swapAtInt + tenMin))) throw Err.TooCloseToSwap;
            }

            assert (!(mode & 32)) throw Err.DestroyModeNotAllowed;
            sendRawMessage(refSlice.loadRef(), mode);
        }

        else => {
            throw 0xffff;
        }
    }
}

fun onExternalMessage(inMsg: slice) {
    var storage = lazy Storage.load();
    assert (!storage.isComplete) throw Err.OfferCompleted;

    if (blockchain.now() > storage.validUntil as int) {
        acceptExternalMessage();
        cancelOffer(mutate storage);
        return;
    }

    throw 0xffff;
}

struct JettonOfferDataResult {
    isComplete: bool
    createdAt: uint32
    validUntil: uint32
    acceptedAt: uint32
    marketplaceAddress: address
    nftAddress: address
    offerOwnerAddress: address
    fullPrice: coins
    marketplaceFeeAddress: address
    marketplacePercent: uint17
    royaltyAddress: address?
    royaltyPercent: uint17
    profitPrice: int
    jettonMasterAddress: address?
    jettonWalletAddress: address?
}

get fun getJettonOfferData(): JettonOfferDataResult {
    val storage = lazy Storage.load();

    val fees = lazy storage.feesData.load();
    val (_, _, profitPrice) = fees.calcProfit(storage.fullPrice as int);
    assert (profitPrice > 0) throw Err.ProfitTooLow;

    var jettonMasterAddress: address? = null;
    var jettonWalletAddress: address? = null;
    if (storage.jettonData != null) {
        val jd = lazy storage.jettonData!.load();
        jettonMasterAddress = jd.jettonMasterAddress;
        jettonWalletAddress = jd.jettonWalletAddress;
    }

    return {
        isComplete: storage.isComplete,
        createdAt: storage.createdAt,
        validUntil: storage.validUntil,
        acceptedAt: storage.acceptedAt,
        marketplaceAddress: storage.marketplaceAddress,
        nftAddress: storage.nftAddress,
        offerOwnerAddress: storage.offerOwnerAddress,
        fullPrice: storage.fullPrice,
        marketplaceFeeAddress: fees.marketplaceFeeAddress,
        marketplacePercent: fees.marketplacePercent,
        royaltyAddress: fees.royaltyAddress,
        royaltyPercent: fees.royaltyPercent,
        profitPrice,
        jettonMasterAddress,
        jettonWalletAddress,
    }
}
