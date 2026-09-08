import "jetton-wallet-address"
import "@stdlib/tvm-dicts"
import "constants"
import "domain"
import "errors"
import "messages"
import "types"

// ============================================================
//  Grm DNS Domains — collection and .grm resolver
//
//  Implements TEP-62 (NFT collection), TEP-66 (royalties), TEP-81 (DNS
//  resolver) and receives GRM through TEP-74.
//
//  The collection handles the FIRST bid on a name and nothing else. It checks
//  the name and the price, deploys the domain contract, and hands the GRM over
//  to the domain's own jetton wallet. From then on the domain is autonomous:
//  every later bid is paid straight into it, and refunds and the final burn
//  leave from its own wallet.
//
//  So the collection never holds anyone's money, keeps no accounting counter,
//  and has no operation that can move GRM. Handing ownership to the zero
//  address therefore strands nothing.
//
//  Nothing needs configuring after deployment either: the GRM wallet address of
//  the collection and of every domain is derived from the master address and
//  the wallet code, both fixed at deploy time.
// ============================================================

contract GrmDnsCollection {
    author: "Grm DNS"
    version: "2.0.0"
    description: "Grm DNS collection and .grm resolver. TEP-62, TEP-66 and TEP-81 compliant"
    storage: GrmDnsCollectionStorage
    incomingMessages: AllowedMessageToCollection
}

type AllowedMessageToCollection =
    | JettonTransferNotification
    | RequestFunds
    | RejectBid
    | RequestRoyaltyParams
    | RescueJettons
    | WithdrawTon
    | ChangeOwner
    | ChangeContent
    | ChangeRoyalty

// ------------------------------------------------------------
//  Helpers
// ------------------------------------------------------------

/// The GRM wallet of any owner, derived rather than stored. Uses the classic
/// TEP-74 wallet layout, which is what the GRM jetton uses.
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
            // an empty Either: a single zero bit meaning "inline, nothing"
            forwardPayload: beginCell().storeUint(0, 1).endCell().beginParse(),
        },
    });
    transferMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
}

/// Unwraps a jetton `forward_payload`: one zero bit means the payload follows
/// inline, one set bit means it sits in a reference.
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

/// Pulls a domain name out of a plain text comment: 32 zero bits, then the
/// name, possibly snaked across cells. Returns `(domain, ok)` and never throws.
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

/// Only the domain contract whose address is derived from `itemIndex` may ask
/// the collection to move GRM on its behalf.
fun assertFromDomain(storage: GrmDnsCollectionStorage, itemIndex: uint256, senderAddress: address) {
    val expected = calcDeployedDomain(itemIndex, contract.getAddress(), storage.itemCode);
    assert (senderAddress == expected.calculateAddress()) throw Errors.NotFromItem;
}

fun assertFromOwner(storage: GrmDnsCollectionStorage, senderAddress: address) {
    assert (storage.ownerAddress != null) throw Errors.NotFromOwner;
    assert (senderAddress == storage.ownerAddress!) throw Errors.NotFromOwner;
}

// ------------------------------------------------------------
//  The first bid on a name
// ------------------------------------------------------------

fun handleFirstBid(
    storage: GrmDnsCollectionStorage,
    senderAddress: address,
    valueCoins: coins,
    msg: JettonTransferNotification,
) {
    val jetton = storage.jetton.load();
    val ourWallet = grmWalletOf(jetton, contract.getAddress());

    // Only our own GRM wallet may tell us about jettons.
    assert (senderAddress == ourWallet) throw Errors.WrongJettonWallet;

    // From here on nothing throws. A transfer notification is not bounceable,
    // so an exception would leave the sender's GRM stuck inside this contract.
    // Every rejected bid is refunded instead.
    var reject = false;

    val (domain, parsed) = parseBidComment(msg.forwardPayload);
    if (!parsed) {
        reject = true;
    } else if (valueCoins < MIN_BID_TON) {
        reject = true;
    } else if (msg.amount < getMinPrice(domainLength(domain))) {
        // Below the starting price no bid can ever be accepted, whatever state
        // the domain is in, so we can reject here and save a round trip.
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

    // Deploy the domain and let it decide. It answers with RequestFunds if it
    // accepted the bid, or RejectBid if it already exists — in which case the
    // bidder should have paid it directly.
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

// ------------------------------------------------------------
//  Message handling
// ------------------------------------------------------------

fun onInternalMessage(in: InMessage) {
    // Empty body or a text comment: a plain TON top-up, nothing to do.
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

        // The domain accepted the first bid: send it the money. The forward
        // amount is what makes the domain's wallet notify it, which is how the
        // domain learns the funds landed and starts accepting competing bids.
        RequestFunds => {
            assertFromDomain(storage, msg.itemIndex, in.senderAddress);

            // A domain only asks for funds right after it was deployed; an
            // existing one answers RejectBid instead. So this counts domains
            // that were actually created, with no double counting.
            var updated = storage;
            updated.domainIndex.uDictSet(
                64,
                updated.mintedCount,
                beginCell().storeUint(msg.itemIndex, 256).endCell().beginParse(),
            );
            updated.mintedCount += 1;
            updated.save();

            val jetton = storage.jetton.load();
            sendJettons(
                grmWalletOf(jetton, contract.getAddress()),
                msg.queryId,
                msg.amount,
                in.senderAddress,
                // change goes back to whoever paid, not to the domain
                msg.bidder,
                GAS_FUNDING_NOTIFY,
            );
        }

        // The domain already exists, so this bid took the wrong route.
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

        RequestRoyaltyParams => {
            val respondMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: in.senderAddress,
                value: 0,
                body: ResponseRoyaltyParams {
                    queryId: msg.queryId,
                    royaltyParams: storage.jetton.load().royalty.load(),
                },
            });
            respondMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        // ---------- everything below is owner only ----------
        // Once the owner is null nothing here can ever run again: no sender can
        // present addr_none as its source address.
        RescueJettons => {
            assertFromOwner(storage, in.senderAddress);
            val jetton = storage.jetton.load();
            // The collection's own GRM wallet is off limits. It is empty
            // between transactions, but a bid still in flight must never be
            // spendable by the owner.
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
            // SAFETY: owner only, and the reserve above keeps a working balance
            // on the contract. This cannot touch GRM: jettons live on separate
            // wallet contracts and this collection holds none between messages.
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

        ChangeRoyalty => {
            assertFromOwner(storage, in.senderAddress);
            var updated = storage;
            var jetton = updated.jetton.load();
            jetton.royalty = msg.newRoyalty;
            updated.jetton = jetton.toCell();
            updated.save();
        }

        else => {
            assert (in.body.isEmpty()) throw 0xFFFF;
        }
    }
}

fun onBouncedMessage(_in: InMessageBounced) {
    // A failed outgoing jetton transfer returns its TON here. The jettons never
    // left our wallet, so there is nothing to undo.
}

// ============================================================
//  Get methods
// ============================================================

get fun get_collection_data(): CollectionDataReply {
    val storage = lazy GrmDnsCollectionStorage.load();
    return {
        nextItemIndex: storage.mintedCount,
        collectionContent: storage.content,
        ownerAddress: addressOrNone(storage.ownerAddress),
    };
}

/// Number of domains created. Same value as `next_item_index`, exposed
/// separately for convenience.
get fun get_domains_count(): int {
    val storage = lazy GrmDnsCollectionStorage.load();
    return storage.mintedCount;
}

/// TEP-62: a sequential index from 0 to `next_item_index - 1`, not a name
/// hash. To look a domain up by name use `get_domain_address`.
get fun get_nft_address_by_index(itemIndex: int): address {
    val storage = lazy GrmDnsCollectionStorage.load();
    val (entry, found) = storage.domainIndex.uDictGet(64, itemIndex);
    assert (found) throw Errors.NotFound;
    var nameHash = entry!;
    return calcDeployedDomain(
        nameHash.loadUint(256) as uint256,
        contract.getAddress(),
        storage.itemCode,
    ).calculateAddress();
}

/// Domain metadata lives entirely on the domain contract.
get fun get_nft_content(_itemIndex: int, individualNftContent: cell): cell {
    return individualNftContent;
}

get fun royalty_params(): RoyaltyParams {
    val storage = lazy GrmDnsCollectionStorage.load();
    return storage.jetton.load().royalty.load();
}

get fun get_grm_config(): GrmConfigReply {
    val storage = lazy GrmDnsCollectionStorage.load();
    val jetton = storage.jetton.load();
    return { grmMaster: jetton.grmMaster, grmWallet: grmWalletOf(jetton, contract.getAddress()) };
}

/// The GRM wallet this contract believes any owner has.
///
/// Run this against the real GRM master's `get_wallet_address` before going
/// live. If the two disagree, the stored wallet code is wrong and no bid would
/// ever be recognised.
get fun get_grm_wallet_of(ownerAddress: address): address {
    val storage = lazy GrmDnsCollectionStorage.load();
    return grmWalletOf(storage.jetton.load(), ownerAddress);
}

/// Starting price of a domain of `charCount` characters, in nanoGRM.
get fun get_domain_price(charCount: int): int {
    return getMinPriceGrm(charCount) * GRM_UNIT;
}

/// Address of the domain contract for a plain name such as "vadvek".
get fun get_domain_address(domain: slice): address {
    val storage = lazy GrmDnsCollectionStorage.load();
    return calcDeployedDomain(
        domain.hash(),
        contract.getAddress(),
        storage.itemCode,
    ).calculateAddress();
}

/// TEP-81. Hands resolution over to the domain contract.
get fun dnsresolve(subdomain: slice, _category: int): (int, cell?) {
    val subdomainBits = subdomain.remainingBitsCount();
    assert (subdomainBits % 8 == 0) throw Errors.DnsBadSubdomain;
    if (subdomainBits == 0) {
        return (0, null);
    }

    var s = subdomain;
    val startsWithZeroByte = s.preloadUint(8) == 0;

    // "." — resolved, but the collection itself carries no records
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
