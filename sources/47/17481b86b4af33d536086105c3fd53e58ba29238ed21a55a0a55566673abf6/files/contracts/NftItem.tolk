import "errors"
import "fees-management"
import "messages"
import "name-utils"
import "types"

contract NftItem {
    author: "@Games Names"
    version: "1.5.0"
    description: "Permanent transferable @games name with one included deterministic pattern"
    incomingMessages: AllowedMessageToNftItem
    storage: NftItemStorage
    storageAtDeployment: NftItemStorageNotInitialized
}

type AllowedMessageToNftItem = AskToChangeOwnership | RequestStaticData | RequestMintAcknowledgement

fun onInternalMessage(in: InMessage) {
    var loadingStorage = NftItemStorage.startLoading();
    if (loadingStorage.isNotInitialized()) {
        assert (
            in.senderAddress == loadingStorage.collectionAddress
        ) throw Errors.NotFromCollection;

        val msg = InitializeNameNft.fromSlice(in.body);
        validateCanonicalName(msg.name);
        val computedHash = canonicalNameHash(msg.name);
        assert (msg.nameHash == computedHash) throw Errors.NameHashMismatch;
        assert (
            in.valueCoins >= MIN_TONS_FOR_STORAGE + ITEM_ACK_VALUE
        ) throw Errors.TooSmallRestAmount;

        val details: NftNameDetails = {
            name: msg.name,
            nameHash: computedHash,
            content: msg.content,
            category: msg.category,
            mintPrice: msg.mintPrice,
            mintedAt: msg.mintedAt,
        };
        val storage: NftItemStorage = {
            itemIndex: loadingStorage.itemIndex,
            collectionAddress: loadingStorage.collectionAddress,
            ownerAddress: msg.ownerAddress,
            details: details.toCell(),
        };
        storage.save();

        val ack = createMessage({
            bounce: BounceMode.NoBounce,
            dest: loadingStorage.collectionAddress,
            value: ITEM_ACK_VALUE,
            body: MintAcknowledged {
                queryId: msg.queryId,
                nameHash: computedHash,
            },
        });
        ack.send(SEND_MODE_PAY_FEES_SEPARATELY);
        return;
    }

    var storage = loadingStorage.endLoading();
    val msg = lazy AllowedMessageToNftItem.fromSlice(in.body);

    match (msg) {
        AskToChangeOwnership => {
            assert (in.senderAddress == storage.ownerAddress) throw Errors.NotFromOwner;

            val (fwdBits, fwdRefs) = msg.forwardPayload.remainingBitsAndRefsCount();
            assert (fwdBits != 0) throw Errors.IncorrectForwardPayload;
            if (msg.forwardPayload.preloadUint(1) != 0) {
                assert (fwdBits == 1 && fwdRefs == 1) throw Errors.IncorrectForwardPayload;
            }
            assert (msg.newOwnerAddress.getWorkchain() == BASECHAIN) throw Errors.InvalidRecipient;

            val fwdFee = in.originalForwardFee;
            var restAmount = contract.getOriginalBalance() - MIN_TONS_FOR_STORAGE;
            if (msg.forwardTonAmount != 0) {
                restAmount -= (msg.forwardTonAmount + fwdFee);
            }
            if (msg.sendExcessesTo != null) {
                assert (
                    msg.sendExcessesTo.getWorkchain() == BASECHAIN
                ) throw Errors.InvalidRecipient;
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
                        payload: msg.forwardPayload,
                    },
                });
                ownershipMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
            }

            if (msg.sendExcessesTo != null) {
                val excessesMsg = createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: msg.sendExcessesTo,
                    value: restAmount,
                    body: ReturnExcessesBack { queryId: msg.queryId },
                });
                excessesMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
            }

            storage.ownerAddress = msg.newOwnerAddress;
            storage.save();
        }

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

        RequestMintAcknowledgement => {
            assert (in.senderAddress == storage.collectionAddress) throw Errors.NotFromCollection;
            val details = storage.details.load();
            assert (msg.nameHash == details.nameHash) throw Errors.NameHashMismatch;
            val ack = createMessage({
                bounce: BounceMode.NoBounce,
                dest: storage.collectionAddress,
                value: ITEM_ACK_VALUE,
                body: MintAcknowledged {
                    queryId: msg.queryId,
                    nameHash: details.nameHash,
                },
            });
            ack.send(SEND_MODE_PAY_FEES_SEPARATELY);
        }

        else => {
            assert (in.body.isEmpty()) throw 0xFFFF;
        }
    }
}

get fun get_nft_data(): NftDataReply {
    var loadingStorage = NftItemStorage.startLoading();
    if (loadingStorage.isNotInitialized()) {
        return {
            isInitialized: false,
            itemIndex: loadingStorage.itemIndex,
            collectionAddress: loadingStorage.collectionAddress,
        };
    }

    val storage = loadingStorage.endLoading();
    val details = storage.details.load();
    return {
        isInitialized: true,
        itemIndex: storage.itemIndex,
        collectionAddress: storage.collectionAddress,
        ownerAddress: storage.ownerAddress,
        content: details.content,
    };
}

get fun get_name_data(): NameDataReply {
    var loadingStorage = NftItemStorage.startLoading();
    assert (!loadingStorage.isNotInitialized()) throw Errors.PendingMintNotFound;
    val storage = loadingStorage.endLoading();
    val details = storage.details.load();
    val length = validateCanonicalName(details.name);

    return {
        name: details.name,
        nameHash: details.nameHash,
        length: length as uint8,
        category: details.category,
        mintPrice: details.mintPrice,
        mintedAt: details.mintedAt,
    };
}
