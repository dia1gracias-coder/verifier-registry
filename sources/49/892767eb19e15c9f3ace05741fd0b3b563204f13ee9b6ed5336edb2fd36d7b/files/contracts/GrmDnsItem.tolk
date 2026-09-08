import "@stdlib/tvm-dicts"
import "constants"
import "domain"
import "errors"
import "messages"
import "types"

// ============================================================
//  Grm DNS Domains — a single .grm domain
//
//  Implements TEP-62 (NFT item) and TEP-81 (DNS records).
//
//  The domain owns its own GRM jetton wallet. Only the very first bid arrives
//  through the collection; every later bid is paid straight into this wallet,
//  and refunds and the final burn leave from it. No other domain and no
//  administrator can reach that money.
//
//  Life cycle:
//    unclaimed -> auction (first bid) -> owned (finalize)
//              -> expires after a year of inactivity -> auction again
// ============================================================

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

// ------------------------------------------------------------
//  Talking to the collection
// ------------------------------------------------------------

/// Sends GRM out of this domain's own wallet.
fun sendJettons(grmWallet: address, queryId: uint64, amount: coins, to: address) {
    val transferMsg = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: grmWallet,
        value: 0,
        body: JettonTransfer {
            queryId,
            amount,
            destination: to,
            sendExcessesTo: to,
            customPayload: null,
            forwardTonAmount: 0,
            forwardPayload: beginCell().storeUint(0, 1).endCell().beginParse(),
        },
    });
    transferMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
}

/// Keeps the storage minimum and returns everything else to `to`.
fun returnChange(to: address, queryId: uint64) {
    reserveToncoinsOnBalance(MIN_TONS_FOR_STORAGE, RESERVE_MODE_AT_MOST);
    val changeMsg = createMessage({
        bounce: BounceMode.NoBounce,
        dest: to,
        value: 0,
        body: ReturnExcessesBack { queryId },
    });
    // SAFETY: the reserve above is taken first and always keeps
    // MIN_TONS_FOR_STORAGE on the contract, so CARRY_ALL_BALANCE can only send
    // the genuine surplus. IGNORE_ERRORS is required because that surplus may
    // be smaller than the forward fee, in which case dropping the change
    // message must not roll back the state change that precedes it.
    changeMsg.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS);
}

// ------------------------------------------------------------
//  Bids
// ------------------------------------------------------------

/// The very first bid on a name: this contract is being deployed right now.
/// The GRM is still at the collection, so we record the auction and ask for it.
fun startFirstAuction(itemIndex: uint256, collectionAddress: address, msg: RelayBid) {
    // This contract's address is derived from the domain hash, so a mismatch
    // would mean the collection was tampered with. Reject rather than throw.
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
            // the money is still in flight; competing bids wait for it
            isFunded: false,
        }.toCell(),
        lastFillUpTime: blockchain.now(),
        wallet: DomainWallet { grmWallet: msg.grmWallet }.toCell(),
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
    // Домен удерживает свой резерв на хранение прямо здесь, а всё сверх него
    // едет дальше и в итоге возвращается тому, кто ставил. Рассчитывать на
    // сдачу с обратного пути нельзя: её может не остаться.
    reserveToncoinsOnBalance(MIN_TONS_FOR_STORAGE, RESERVE_MODE_AT_MOST);
    fundsMsg.send(SEND_MODE_CARRY_ALL_BALANCE);
}

/// Tells the collection to give a relayed bid back. Used when the domain
/// already exists, in which case the bidder should have paid it directly.
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

/// A bid paid straight into this domain's own GRM wallet. The money is already
/// here, so a refund is just a transfer back out of the same wallet.
fun handleDirectBid(
    mutate storage: GrmDnsItemStorage,
    queryId: uint64,
    bidder: address,
    amount: coins,
) {
    val now = blockchain.now();

    if (storage.auction != null) {
        val auction = storage.auction!.load();

        // The first bid's money has not landed yet: we could not pay the leader
        // back, so this bid waits outside.
        if (!auction.isFunded) {
            sendJettons(storage.wallet.load().grmWallet, queryId, amount, bidder);
            return;
        }

        // --- an auction is live: this is a competing bid ---
        if (now < auction.auctionEndTime) {
            val minNextBid = max(
                mulDivFloor(auction.maxBidAmount, MIN_BID_STEP_PERCENT, 100),
                auction.maxBidAmount + 1,
            );
            if (amount < minNextBid) {
                sendJettons(storage.wallet.load().grmWallet, queryId, amount, bidder);
                return;
            }

            // A bid in the final hour pushes the deadline an hour away.
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

            // The previous leader is paid back immediately, out of this very
            // wallet, in the same transaction.
            sendJettons(
                storage.wallet.load().grmWallet,
                queryId,
                auction.maxBidAmount,
                auction.maxBidAddress,
            );
            return;
        }

        // --- the auction is over but nobody has closed it yet ---
        sendJettons(storage.wallet.load().grmWallet, queryId, amount, bidder);
        return;
    }

    // --- the domain is owned; only an expired one can be re-auctioned ---
    if (!storage.isExpired() || amount < getMinPrice(domainLength(storage.domain.beginParse()))) {
        sendJettons(storage.wallet.load().grmWallet, queryId, amount, bidder);
        return;
    }

    // Records are wiped. Carrying them over would hand the next owner a domain
    // that still resolves to the previous owner's wallet.
    storage.ownerAddress = null;
    storage.content = buildInitialContent(storage.domain);
    storage.auction = AuctionInfo {
        maxBidAddress: bidder,
        maxBidAmount: amount,
        auctionEndTime: now + AUCTION_DURATION,
        // paid directly, so the money is already on the wallet
        isFunded: true,
    }.toCell();
    storage.lastFillUpTime = now;
    storage.save();
    returnChange(bidder, queryId);
}

// ------------------------------------------------------------
//  Message handling
// ------------------------------------------------------------

fun onInternalMessage(in: InMessage) {
    var loading = GrmDnsItemStorage.startLoading();

    if (loading.isNotInitialized()) {
        assert (in.senderAddress == loading.collectionAddress) throw Errors.NotFromCollection;
        val msg = RelayBid.fromSlice(in.body);
        startFirstAuction(loading.itemIndex, loading.collectionAddress, msg);
        return;
    }

    var storage = loading.endLoading();

    // Plain TON, with no body or with a text comment, is a top-up. From the
    // owner it also renews the domain for another year, which is how
    // prolongation works. Wallets attach comments by default, so a comment
    // must renew exactly like an empty body does.
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
        // A relayed first bid on a domain that already exists: it took the
        // wrong route, so the collection gives it back.
        RelayBid => {
            assert (in.senderAddress == storage.collectionAddress) throw Errors.NotFromCollection;
            rejectRelayedBid(storage.collectionAddress, storage.itemIndex, msg);
        }

        // GRM paid straight into this domain's own wallet.
        JettonTransferNotification => {
            assert (
                in.senderAddress == storage.wallet.load().grmWallet
            ) throw Errors.WrongJettonWallet;

            // The collection delivering the first bid: the auction is already
            // recorded, this just confirms the money arrived.
            if (storage.auction != null && msg.senderAddress == storage.collectionAddress) {
                var auction = storage.auction!.load();
                if (!auction.isFunded && msg.amount == auction.maxBidAmount) {
                    auction.isFunded = true;
                    storage.auction = auction.toCell();
                    storage.save();
                    return;
                }
            }

            handleDirectBid(mutate storage, msg.queryId, msg.senderAddress, msg.amount);
        }

        // Closing a finished auction is permissionless: the winner has every
        // reason to call it, but anybody may.
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

            // The winning bid is destroyed, straight from this domain's wallet.
            val burnMsg = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: storage.wallet.load().grmWallet,
                value: GAS_SETTLE,
                body: JettonBurn {
                    queryId: msg.queryId,
                    amount: auction.maxBidAmount,
                    sendExcessesTo: null,
                    customPayload: null,
                },
            });
            burnMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);

            // The winner needs a little value of its own, otherwise the
            // receiving wallet has no gas to process the notification.
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

        // Сдача от джеттон-переводов. Ничего делать не надо, но и падать нельзя:
        // иначе TON осядут здесь мёртвым грузом.
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
            // name, description and image are derived from the domain itself
            // and must stay that way, so that every .grm domain keeps pointing
            // at the Gram CDN.
            assert (!isReservedRecord(msg.key)) throw Errors.ReservedRecord;

            var content = storage.content.beginParse();
            assert (content.loadUint(8) == 0) throw Errors.DnsBadContent;
            var records = content.loadMaybeRef();

            if (msg.value != null) {
                records.uDictSetRef(256, msg.key, msg.value!);
            } else {
                records.uDictDelete(256, msg.key);
            }

            var b = beginCell();
            b.storeUint(0, 8);
            b.storeMaybeRef(records);
            storage.content = b.endCell();
            storage.lastFillUpTime = blockchain.now();
            storage.save();
        }

        else => {
            assert (in.body.isEmpty()) throw 0xFFFF;
        }
    }
}

/// Owner-only actions additionally require a settled, unexpired domain.
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
    // Any owner action also renews the domain for another year.
    storage.lastFillUpTime = blockchain.now();
    storage.save();
}

fun onBouncedMessage(_in: InMessageBounced) {
    // A refund or settle request that failed comes back here. The collection
    // has not changed its accounting in that case, so there is nothing to undo.
}

// ============================================================
//  Get methods
// ============================================================

get fun get_nft_data(): NftDataReply {
    var loading = GrmDnsItemStorage.startLoading();
    if (loading.isNotInitialized()) {
        return {
            isInitialized: false,
            itemIndex: loading.itemIndex,
            collectionAddress: loading.collectionAddress,
        };
    }

    val storage = loading.endLoading();
    return {
        isInitialized: true,
        itemIndex: storage.itemIndex,
        collectionAddress: storage.collectionAddress,
        ownerAddress: storage.ownerAddress,
        content: storage.content,
    };
}

get fun get_editor(): address? {
    var loading = GrmDnsItemStorage.startLoading();
    return loading.endLoading().ownerAddress;
}

/// "alice" — without the ".grm" suffix, same as TON DNS.
get fun get_domain(): slice {
    var loading = GrmDnsItemStorage.startLoading();
    return loading.endLoading().domain.beginParse();
}

get fun get_auction_info(): AuctionInfoReply {
    var loading = GrmDnsItemStorage.startLoading();
    val storage = loading.endLoading();
    if (storage.auction == null) {
        return {
            maxBidAddress: null,
            maxBidAmount: 0,
            auctionEndTime: 0,
            isFunded: false,
        };
    }
    val auction = storage.auction!.load();
    return {
        maxBidAddress: auction.maxBidAddress,
        maxBidAmount: auction.maxBidAmount,
        auctionEndTime: auction.auctionEndTime,
        isFunded: auction.isFunded,
    };
}

get fun get_last_fill_up_time(): int {
    var loading = GrmDnsItemStorage.startLoading();
    return loading.endLoading().lastFillUpTime;
}

/// This domain's own GRM wallet, where its live bid is held.
get fun get_grm_wallet(): address {
    var loading = GrmDnsItemStorage.startLoading();
    return loading.endLoading().wallet.load().grmWallet;
}

get fun get_expiration_time(): int {
    var loading = GrmDnsItemStorage.startLoading();
    return loading.endLoading().lastFillUpTime + ONE_YEAR;
}

/// TEP-81. Returns the number of consumed bits and the matching record.
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

    // An unclaimed or expired domain resolves to nothing.
    if (storage.auction != null || storage.isExpired()) {
        return (0, null);
    }

    var content = storage.content.beginParse();
    assert (content.loadUint(8) == 0) throw Errors.DnsBadContent;
    val records = content.loadMaybeRef();

    // A deeper name is handed over to the next resolver, if one is set.
    var wantedCategory = category;
    if (subdomainBits > 8) {
        wantedCategory = KEY_NEXT_RESOLVER;
    }

    if (wantedCategory == 0) {
        return (8, records); // every category at once
    }
    return (8, records.uDictGetRefOrNull(256, wantedCategory));
}
