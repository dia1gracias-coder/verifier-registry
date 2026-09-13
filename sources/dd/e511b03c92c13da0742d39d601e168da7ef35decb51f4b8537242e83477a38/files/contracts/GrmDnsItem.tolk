import "@stdlib/tvm-dicts"
import "constants"
import "domain"
import "errors"
import "messages"
import "types"


contract GrmDnsItem {
    author: "Grm DNS"
    version: "1.0.0"
    description: "Grm DNS domain. TEP-62, TEP-64 and TEP-81 compliant"
    storage: GrmDnsItemStorage
    storageAtDeployment: GrmDnsItemStorageNotInitialized
    incomingMessages: AllowedMessageToDomain
}

type AllowedMessageToDomain =
    | ReturnExcessesBack
    | RelayBid
    | JettonTransferNotification
    | FinalizeAuction
    | RequestStaticData
    | AskToChangeOwnership
    | ChangeDnsRecord


fun sendJettons(
    grmWallet: address,
    queryId: uint64,
    amount: coins,
    to: address,
    changeTo: address? = null,
) {
    val transferMsg = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: grmWallet,
        value: 0,
        body: JettonTransfer {
            queryId,
            amount,
            destination: to,
            sendExcessesTo: changeTo == null ? to : changeTo!,
            customPayload: null,
            forwardTonAmount: 0,
            forwardPayload: beginCell().storeUint(0, 1).endCell().beginParse(),
        },
    });
    transferMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
}

fun returnChange(to: address, queryId: uint64) {
    reserveToncoinsOnBalance(MIN_TONS_FOR_STORAGE, RESERVE_MODE_AT_MOST);
    val changeMsg = createMessage({
        bounce: BounceMode.NoBounce,
        dest: to,
        value: 0,
        body: ReturnExcessesBack { queryId },
    });
    // SAFETY: reserve above keeps MIN_TONS_FOR_STORAGE.
    changeMsg.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS);
}


fun startFirstAuction(itemIndex: uint256, collectionAddress: address, msg: RelayBid) {
    if (msg.domain.beginParse().hash() != itemIndex) {
        rejectRelayedBid(collectionAddress, itemIndex, msg);
        return;
    }

    val storage: GrmDnsItemStorage = {
        itemIndex,
        collectionAddress,
        ownerAddress: null,
        content: buildInitialContent(msg.domain),
        domain: msg.domain,
        auction: AuctionInfo {
            maxBidAddress: msg.bidder,
            maxBidAmount: msg.amount,
            auctionEndTime: blockchain.now() + AUCTION_DURATION,
            isFunded: false,
        }.toCell(),
        lastFillUpTime: blockchain.now(),
        wallet: DomainData { grmWallet: msg.grmWallet, records: null }.toCell(),
    };
    storage.save();

    val fundsMsg = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: collectionAddress,
        value: 0,
        body: RequestFunds {
            queryId: msg.queryId,
            itemIndex,
            amount: msg.amount,
            bidder: msg.bidder,
        },
    });
    reserveToncoinsOnBalance(MIN_TONS_FOR_STORAGE, RESERVE_MODE_AT_MOST);
    // SAFETY: reserve above keeps MIN_TONS_FOR_STORAGE.
    fundsMsg.send(SEND_MODE_CARRY_ALL_BALANCE);
}

fun rejectRelayedBid(collectionAddress: address, itemIndex: uint256, msg: RelayBid) {
    val rejectMsg = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: collectionAddress,
        value: 0,
        body: RejectBid {
            queryId: msg.queryId,
            itemIndex,
            amount: msg.amount,
            bidder: msg.bidder,
        },
    });
    rejectMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
}

fun handleDirectBid(
    mutate storage: GrmDnsItemStorage,
    queryId: uint64,
    bidder: address,
    amount: coins,
) {
    val now = blockchain.now();

    if (storage.auction != null) {
        val auction = storage.auction!.load();

        if (!auction.isFunded) {
            if (
                now <= auction.auctionEndTime ||
                amount < getMinPrice(domainLength(storage.domain.beginParse()))
            ) {
                sendJettons(storage.wallet.load().grmWallet, queryId, amount, bidder);
                return;
            }

            storage.ownerAddress = null;
            storage.content = buildInitialContent(storage.domain);
            storage.wallet = DomainData {
                grmWallet: storage.wallet.load().grmWallet,
                records: null,
            }.toCell();
            storage.auction = AuctionInfo {
                maxBidAddress: bidder,
                maxBidAmount: amount,
                auctionEndTime: now + AUCTION_DURATION,
                isFunded: true,
            }.toCell();
            storage.lastFillUpTime = now;
            storage.save();
            returnChange(bidder, queryId);
            return;
        }

        if (now < auction.auctionEndTime) {
            val minNextBid = max(
                mulDivFloor(auction.maxBidAmount, MIN_BID_STEP_PERCENT, 100),
                auction.maxBidAmount + 1,
            );
            if (amount < minNextBid) {
                sendJettons(storage.wallet.load().grmWallet, queryId, amount, bidder);
                return;
            }

            var newEndTime = auction.auctionEndTime;
            if (auction.auctionEndTime - now < AUCTION_PROLONGATION) {
                newEndTime = now + AUCTION_PROLONGATION;
            }

            storage.auction = AuctionInfo {
                maxBidAddress: bidder,
                maxBidAmount: amount,
                auctionEndTime: newEndTime,
                isFunded: true,
            }.toCell();
            storage.lastFillUpTime = now;
            storage.save();

            sendJettons(
                storage.wallet.load().grmWallet,
                queryId,
                auction.maxBidAmount,
                auction.maxBidAddress,
                bidder,
            );
            return;
        }

        sendJettons(storage.wallet.load().grmWallet, queryId, amount, bidder);
        return;
    }

    if (!storage.isExpired() || amount < getMinPrice(domainLength(storage.domain.beginParse()))) {
        sendJettons(storage.wallet.load().grmWallet, queryId, amount, bidder);
        return;
    }

    storage.ownerAddress = null;
    storage.content = buildInitialContent(storage.domain);
    storage.wallet = DomainData {
        grmWallet: storage.wallet.load().grmWallet,
        records: null,
    }.toCell();
    storage.auction = AuctionInfo {
        maxBidAddress: bidder,
        maxBidAmount: amount,
        auctionEndTime: now + AUCTION_DURATION,
        isFunded: true,
    }.toCell();
    storage.lastFillUpTime = now;
    storage.save();
    returnChange(bidder, queryId);
}


fun onInternalMessage(in: InMessage) {
    var loading = GrmDnsItemStorage.startLoading();

    if (loading.isNotInitialized()) {
        assert (in.senderAddress == loading.collectionAddress) throw Errors.NotFromCollection;
        val msg = RelayBid.fromSlice(in.body);
        startFirstAuction(loading.itemIndex, loading.collectionAddress, msg);
        return;
    }

    var storage = loading.endLoading();

    val bodyBits = in.body.remainingBitsCount();
    val isPlainTransfer = bodyBits == 0 || (bodyBits >= 32 && in.body.preloadUint(32) == 0);
    if (isPlainTransfer) {
        if (
            storage.auction == null && storage.ownerAddress != null &&
            in.senderAddress == storage.ownerAddress!
        ) {
            storage.lastFillUpTime = blockchain.now();
            storage.save();
        }
        return;
    }

    val msg = lazy AllowedMessageToDomain.fromSlice(in.body);

    match (msg) {
        RelayBid => {
            assert (in.senderAddress == storage.collectionAddress) throw Errors.NotFromCollection;
            rejectRelayedBid(storage.collectionAddress, storage.itemIndex, msg);
        }

        JettonTransferNotification => {
            assert (
                in.senderAddress == storage.wallet.load().grmWallet
            ) throw Errors.WrongJettonWallet;

            if (storage.auction != null && msg.senderAddress == storage.collectionAddress) {
                var auction = storage.auction!.load();
                if (!auction.isFunded && msg.amount == auction.maxBidAmount) {
                    auction.isFunded = true;
                    storage.auction = auction.toCell();
                    storage.save();
                    return;
                }
            }

            if (in.valueCoins < MIN_DIRECT_BID_TON) {
                sendJettons(storage.wallet.load().grmWallet, msg.queryId, msg.amount, msg.senderAddress);
                return;
            }

            handleDirectBid(mutate storage, msg.queryId, msg.senderAddress, msg.amount);
        }

        FinalizeAuction => {
            assert (storage.auction != null) throw Errors.AuctionNotStarted;
            assert (in.valueCoins >= MIN_FINALIZE_TON) throw Errors.TooSmallRestAmount;

            val auction = storage.auction!.load();
            assert (blockchain.now() > auction.auctionEndTime) throw Errors.AuctionNotFinished;

            assert (auction.isFunded) throw Errors.AuctionNotFinished;

            storage.ownerAddress = auction.maxBidAddress;
            storage.auction = null;
            storage.lastFillUpTime = blockchain.now();
            storage.save();

            val burnMsg = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: storage.wallet.load().grmWallet,
                value: GAS_SETTLE,
                body: JettonBurn {
                    queryId: msg.queryId,
                    amount: auction.maxBidAmount,
                    sendExcessesTo: in.senderAddress,
                    customPayload: null,
                },
            });
            burnMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);

            val wonMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: auction.maxBidAddress,
                value: GAS_NOTIFY,
                body: NotificationForNewOwner {
                    queryId: msg.queryId,
                    oldOwnerAddress: null,
                    forwardPayload: createEmptySlice(),
                },
            });
            wonMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);

            returnChange(in.senderAddress, msg.queryId);
        }

        ReturnExcessesBack => {}

        RequestStaticData => {
            val respondMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: in.senderAddress,
                value: 0,
                body: UnsafeBodyNoRef {
                    forceInline: ResponseStaticData {
                        queryId: msg.queryId,
                        itemIndex: storage.itemIndex,
                        collectionAddress: storage.collectionAddress,
                    },
                },
            });
            respondMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        AskToChangeOwnership => {
            assertOwnerCanAct(storage, in.senderAddress);
            transferOwnership(mutate storage, in.originalForwardFee, msg);
        }

        ChangeDnsRecord => {
            assertOwnerCanAct(storage, in.senderAddress);
            assert (!isReservedRecord(msg.key)) throw Errors.ReservedRecord;

            val data = storage.wallet.load();
            var records = data.records;

            if (msg.value != null) {
                records.uDictSetRef(256, msg.key, msg.value!);
            } else {
                records.uDictDelete(256, msg.key);
            }

            storage.wallet = DomainData { grmWallet: data.grmWallet, records }.toCell();
            storage.lastFillUpTime = blockchain.now();
            storage.save();
        }

        else => {
            assert (in.body.isEmpty()) throw 0xFFFF;
        }
    }
}

fun assertOwnerCanAct(storage: GrmDnsItemStorage, senderAddress: address) {
    assert (storage.auction == null) throw Errors.AuctionInProgress;
    assert (storage.ownerAddress != null) throw Errors.NotFromOwner;
    assert (senderAddress == storage.ownerAddress!) throw Errors.NotFromOwner;
    assert (!storage.isExpired()) throw Errors.DomainExpired;
}

fun transferOwnership(
    mutate storage: GrmDnsItemStorage,
    fwdFee: coins,
    msg: AskToChangeOwnership,
) {
    val (fwdBits, fwdRefs) = msg.forwardPayload.remainingBitsAndRefsCount();
    assert (fwdBits != 0) throw Errors.TooSmallRestAmount;
    if (msg.forwardPayload.preloadUint(1) != 0) {
        assert (fwdBits == 1 && fwdRefs == 1) throw Errors.TooSmallRestAmount;
    }
    assert (msg.newOwnerAddress.getWorkchain() == BASECHAIN) throw Errors.InvalidWorkchain;

    var restAmount = contract.getOriginalBalance() - MIN_TONS_FOR_STORAGE;
    if (msg.forwardTonAmount != 0) {
        restAmount -= (msg.forwardTonAmount + fwdFee);
    }
    if (msg.sendExcessesTo != null) {
        assert (msg.sendExcessesTo!.getWorkchain() == BASECHAIN) throw Errors.InvalidWorkchain;
        restAmount -= fwdFee;
    }
    assert (restAmount >= 0) throw Errors.TooSmallRestAmount;

    if (msg.forwardTonAmount != 0) {
        val ownershipMsg = createMessage({
            bounce: BounceMode.NoBounce,
            dest: msg.newOwnerAddress,
            value: msg.forwardTonAmount,
            body: NotificationForNewOwner {
                queryId: msg.queryId,
                oldOwnerAddress: storage.ownerAddress,
                forwardPayload: msg.forwardPayload,
            },
        });
        ownershipMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
    }
    if (msg.sendExcessesTo != null) {
        val excessesMsg = createMessage({
            bounce: BounceMode.NoBounce,
            dest: msg.sendExcessesTo!,
            value: restAmount,
            body: ReturnExcessesBack { queryId: msg.queryId },
        });
        excessesMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
    }

    storage.ownerAddress = msg.newOwnerAddress;
    storage.lastFillUpTime = blockchain.now();
    storage.save();
}

fun onBouncedMessage(_in: InMessageBounced) {
}


get fun get_nft_data(): NftDataReply {
    var loading = GrmDnsItemStorage.startLoading();
    if (loading.isNotInitialized()) {
        return {
            isInitialized: 0,
            itemIndex: loading.itemIndex,
            collectionAddress: loading.collectionAddress,
            ownerAddress: createAddressNone(),
            content: createEmptyCell(),
        };
    }

    val storage = loading.endLoading();
    return {
        isInitialized: -1,
        itemIndex: storage.itemIndex,
        collectionAddress: storage.collectionAddress,
        ownerAddress: addressOrNone(storage.ownerAddress),
        content: storage.content,
    };
}

get fun get_editor(): any_address {
    var loading = GrmDnsItemStorage.startLoading();
    return addressOrNone(loading.endLoading().ownerAddress);
}

get fun get_domain(): slice {
    var loading = GrmDnsItemStorage.startLoading();
    return loading.endLoading().domain.beginParse();
}

get fun get_auction_info(): AuctionInfoReply {
    var loading = GrmDnsItemStorage.startLoading();
    val storage = loading.endLoading();
    if (storage.auction == null) {
        return {
            maxBidAddress: createAddressNone(),
            maxBidAmount: 0,
            auctionEndTime: 0,
            isFunded: false,
        };
    }
    val auction = storage.auction!.load();
    return {
        maxBidAddress: auction.maxBidAddress as any_address,
        maxBidAmount: auction.maxBidAmount,
        auctionEndTime: auction.auctionEndTime,
        isFunded: auction.isFunded,
    };
}

get fun get_last_fill_up_time(): int {
    var loading = GrmDnsItemStorage.startLoading();
    return loading.endLoading().lastFillUpTime;
}

get fun get_grm_wallet(): address {
    var loading = GrmDnsItemStorage.startLoading();
    return loading.endLoading().wallet.load().grmWallet;
}

get fun get_expiration_time(): int {
    var loading = GrmDnsItemStorage.startLoading();
    return loading.endLoading().lastFillUpTime + ONE_YEAR;
}

get fun dnsresolve(subdomain: slice, category: int): (int, cell?) {
    val subdomainBits = subdomain.remainingBitsCount();
    assert (subdomainBits % 8 == 0) throw Errors.DnsBadSubdomain;
    if (subdomainBits == 0) {
        return (0, null);
    }

    var loading = GrmDnsItemStorage.startLoading();
    assert (!loading.isNotInitialized()) throw Errors.NotInitialized;
    val storage = loading.endLoading();

    assert (subdomain.preloadUint(8) == 0) throw Errors.DnsNoZeroByte;

    if (storage.auction != null || storage.isExpired()) {
        return (0, null);
    }

    val records = storage.wallet.load().records;

    var wantedCategory = category;
    if (subdomainBits > 8) {
        wantedCategory = KEY_NEXT_RESOLVER;
    }

    if (wantedCategory == 0) {
        return (8, records);
    }
    return (8, records.uDictGetRefOrNull(256, wantedCategory));
}
