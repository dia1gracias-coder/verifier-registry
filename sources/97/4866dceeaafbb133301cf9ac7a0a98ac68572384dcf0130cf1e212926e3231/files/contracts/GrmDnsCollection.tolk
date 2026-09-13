import "jetton-wallet-address"
import "constants"
import "domain"
import "errors"
import "messages"
import "types"


contract GrmDnsCollection {
    author: "Grm DNS"
    version: "2.0.0"
    description: "Grm DNS collection and .grm resolver. TEP-62 and TEP-81 compliant"
    storage: GrmDnsCollectionStorage
    incomingMessages: AllowedMessageToCollection
}

type AllowedMessageToCollection =
    | JettonTransferNotification
    | RequestFunds
    | RejectBid
    | RescueJettons
    | WithdrawTon
    | ChangeOwner
    | ChangeContent


fun grmWalletOf(jetton: JettonConfig, ownerAddress: address): address {
    return calcAddressOfJettonWallet(ownerAddress, jetton.grmMaster, jetton.grmWalletCode);
}

fun sendJettons(
    grmWallet: address,
    queryId: uint64,
    amount: coins,
    to: address,
    sendExcessesTo: address,
    forwardTonAmount: coins,
) {
    val transferMsg = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: grmWallet,
        value: 0,
        body: JettonTransfer {
            queryId,
            amount,
            destination: to,
            sendExcessesTo,
            customPayload: null,
            forwardTonAmount,
            forwardPayload: beginCell().storeUint(0, 1).endCell().beginParse(),
        },
    });
    transferMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
}

fun unwrapForwardPayload(payload: slice): (slice, bool) {
    var s = payload;
    val (bits, refs) = s.remainingBitsAndRefsCount();
    if (bits == 0) {
        return (createEmptySlice(), false);
    }
    if (s.loadUint(1) == 0) {
        return (s, true);
    }
    if (refs < 1) {
        return (createEmptySlice(), false);
    }
    return (s.loadRef().beginParse(), true);
}

fun parseBidComment(payload: slice): (slice, bool) {
    val (unwrapped, unwrapOk) = unwrapForwardPayload(payload);
    if (!unwrapOk) {
        return (createEmptySlice(), false);
    }

    var s = unwrapped;
    if (s.remainingBitsCount() < 32) {
        return (createEmptySlice(), false);
    }
    if (s.loadUint(32) != 0) {
        return (createEmptySlice(), false);
    }

    val (text, textOk) = readText(s);
    if (!textOk) {
        return (createEmptySlice(), false);
    }

    val domain = stripTld(text);
    if (!isValidDomain(domain)) {
        return (createEmptySlice(), false);
    }
    return (domain, true);
}

fun assertFromDomain(storage: GrmDnsCollectionStorage, itemIndex: uint256, senderAddress: address) {
    val expected = calcDeployedDomain(itemIndex, contract.getAddress(), storage.itemCode);
    assert (senderAddress == expected.calculateAddress()) throw Errors.NotFromItem;
}

fun assertFromOwner(storage: GrmDnsCollectionStorage, senderAddress: address) {
    assert (storage.ownerAddress != null) throw Errors.NotFromOwner;
    assert (senderAddress == storage.ownerAddress!) throw Errors.NotFromOwner;
}


fun handleFirstBid(
    storage: GrmDnsCollectionStorage,
    senderAddress: address,
    valueCoins: coins,
    msg: JettonTransferNotification,
) {
    val jetton = storage.jetton.load();
    val ourWallet = grmWalletOf(jetton, contract.getAddress());

    assert (senderAddress == ourWallet) throw Errors.WrongJettonWallet;

    var reject = false;

    val (domain, parsed) = parseBidComment(msg.forwardPayload);
    if (!parsed) {
        reject = true;
    } else if (valueCoins < MIN_BID_TON) {
        reject = true;
    } else if (msg.amount < getMinPrice(domainLength(domain))) {
        reject = true;
    }

    if (reject) {
        sendJettons(
            ourWallet,
            msg.queryId,
            msg.amount,
            msg.senderAddress,
            msg.senderAddress,
            0,
        );
        return;
    }

    val itemIndex = domain.hash();
    val domainDeploy = calcDeployedDomain(itemIndex, contract.getAddress(), storage.itemCode);

    val bidMsg = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: domainDeploy,
        value: 0,
        body: RelayBid {
            queryId: msg.queryId,
            bidder: msg.senderAddress,
            amount: msg.amount,
            domain: beginCell().storeSlice(domain).endCell(),
            grmWallet: grmWalletOf(jetton, domainDeploy.calculateAddress()),
        },
    });
    bidMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
}


fun onInternalMessage(in: InMessage) {
    val bodyBits = in.body.remainingBitsCount();
    if (bodyBits == 0 || (bodyBits >= 32 && in.body.preloadUint(32) == 0)) {
        return;
    }

    val storage = lazy GrmDnsCollectionStorage.load();
    val msg = lazy AllowedMessageToCollection.fromSlice(in.body);

    match (msg) {
        JettonTransferNotification => {
            handleFirstBid(storage, in.senderAddress, in.valueCoins, msg);
        }

        RequestFunds => {
            assertFromDomain(storage, msg.itemIndex, in.senderAddress);

            var updated = storage;
            updated.domainIndex.set(updated.mintedCount, msg.itemIndex);
            updated.mintedCount += 1;
            updated.save();

            val jetton = storage.jetton.load();
            sendJettons(
                grmWalletOf(jetton, contract.getAddress()),
                msg.queryId,
                msg.amount,
                in.senderAddress,
                msg.bidder,
                GAS_FUNDING_NOTIFY,
            );
        }

        RejectBid => {
            assertFromDomain(storage, msg.itemIndex, in.senderAddress);
            val jetton = storage.jetton.load();
            sendJettons(
                grmWalletOf(jetton, contract.getAddress()),
                msg.queryId,
                msg.amount,
                msg.bidder,
                msg.bidder,
                0,
            );
        }

        RescueJettons => {
            assertFromOwner(storage, in.senderAddress);
            val jetton = storage.jetton.load();
            assert (
                msg.walletAddress != grmWalletOf(jetton, contract.getAddress())
            ) throw Errors.GrmWalletLocked;
            sendJettons(
                msg.walletAddress,
                msg.queryId,
                msg.amount,
                msg.to,
                in.senderAddress,
                0,
            );
        }

        WithdrawTon => {
            assertFromOwner(storage, in.senderAddress);
            reserveToncoinsOnBalance(MIN_TONS_FOR_COLLECTION, RESERVE_MODE_AT_MOST);
            val withdrawMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: in.senderAddress,
                value: 0,
                body: ReturnExcessesBack { queryId: msg.queryId },
            });
            // SAFETY: reserve above keeps MIN_TONS_FOR_COLLECTION.
            withdrawMsg.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS);
        }

        ChangeOwner => {
            assertFromOwner(storage, in.senderAddress);
            if (msg.newOwnerAddress != null) {
                assert (
                    msg.newOwnerAddress!.getWorkchain() == BASECHAIN
                ) throw Errors.InvalidWorkchain;
            }
            var updated = storage;
            updated.ownerAddress = msg.newOwnerAddress;
            updated.save();
        }

        ChangeContent => {
            assertFromOwner(storage, in.senderAddress);
            var updated = storage;
            updated.content = msg.newContent;
            updated.save();
        }

        else => {
            assert (in.body.isEmpty()) throw 0xFFFF;
        }
    }
}

fun onBouncedMessage(_in: InMessageBounced) {
}


get fun get_collection_data(): CollectionDataReply {
    val storage = lazy GrmDnsCollectionStorage.load();
    return {
        nextItemIndex: storage.mintedCount,
        collectionContent: storage.content,
        ownerAddress: addressOrNone(storage.ownerAddress),
    };
}

get fun get_domains_count(): int {
    val storage = lazy GrmDnsCollectionStorage.load();
    return storage.mintedCount;
}

get fun get_nft_address_by_index(itemIndex: int): address {
    val storage = lazy GrmDnsCollectionStorage.load();
    val found = storage.domainIndex.get(itemIndex as uint64);
    assert (found.isFound) throw Errors.NotFound;
    return calcDeployedDomain(
        found.loadValue(),
        contract.getAddress(),
        storage.itemCode,
    ).calculateAddress();
}

get fun get_nft_content(_itemIndex: int, individualNftContent: cell): cell {
    return individualNftContent;
}

get fun get_grm_config(): GrmConfigReply {
    val storage = lazy GrmDnsCollectionStorage.load();
    val jetton = storage.jetton.load();
    return { grmMaster: jetton.grmMaster, grmWallet: grmWalletOf(jetton, contract.getAddress()) };
}

get fun get_grm_wallet_of(ownerAddress: address): address {
    val storage = lazy GrmDnsCollectionStorage.load();
    return grmWalletOf(storage.jetton.load(), ownerAddress);
}

get fun get_domain_price(charCount: int): int {
    return getMinPriceGrm(charCount) * GRM_UNIT;
}

get fun get_domain_address(domain: slice): address {
    val storage = lazy GrmDnsCollectionStorage.load();
    return calcDeployedDomain(
        domain.hash(),
        contract.getAddress(),
        storage.itemCode,
    ).calculateAddress();
}

get fun dnsresolve(subdomain: slice, _category: int): (int, cell?) {
    val subdomainBits = subdomain.remainingBitsCount();
    assert (subdomainBits % 8 == 0) throw Errors.DnsBadSubdomain;
    if (subdomainBits == 0) {
        return (0, null);
    }

    var s = subdomain;
    val startsWithZeroByte = s.preloadUint(8) == 0;

    if (startsWithZeroByte && subdomainBits == 8) {
        return (8, null);
    }
    if (startsWithZeroByte) {
        s.skipBits(8);
    }

    val topBits = getTopDomainBits(s);
    val topDomain = s.getFirstBits(topBits);

    val storage = lazy GrmDnsCollectionStorage.load();
    val domainAddress = calcDeployedDomain(
        topDomain.hash(),
        contract.getAddress(),
        storage.itemCode,
    ).calculateAddress();

    var b = beginCell();
    b.storeUint(DNS_NEXT_RESOLVER_PREFIX, 16);
    b.storeAddress(domainAddress);

    return (topBits + (startsWithZeroByte ? 8 : 0), b.endCell());
}
