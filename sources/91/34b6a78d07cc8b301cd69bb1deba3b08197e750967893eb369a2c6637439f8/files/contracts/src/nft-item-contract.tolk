import "errors"
import "item-storage"
import "messages"

const ITEM_MIN_STORAGE_RESERVE = ton("0.05")

contract NftItem {
    author: "Hoppr"
    version: "1.0.0"
    description: "Hoppr Genesis TEP-62 NFT item"
    incomingMessages: AllowedMessageToNftItem
    storage: NftItemStorage
    storageAtDeployment: NftItemStorageNotInitialized
}

type AllowedMessageToNftItem = AskToChangeOwnership | RequestStaticData

fun onInternalMessage(in: InMessage) {
    var loading = NftItemStorage.startLoading();
    if (loading.isNotInitialized()) {
        assert (
            in.senderAddress == loading.collectionAddress
        ) throw HopprErrors.ItemNotFromCollection;
        val init = NftItemInitAtDeployment.fromSlice(in.body);
        NftItemStorage {
            itemIndex: loading.itemIndex,
            collectionAddress: loading.collectionAddress,
            ownerAddress: init.ownerAddress,
            content: init.content,
        }.save();
        return;
    }

    var storage = loading.endLoading();
    val msg = lazy AllowedMessageToNftItem.fromSlice(in.body);
    match (msg) {
        AskToChangeOwnership => {
            assert (in.senderAddress == storage.ownerAddress) throw HopprErrors.ItemNotOwner;
            assert (
                msg.newOwnerAddress.getWorkchain() == BASECHAIN
            ) throw HopprErrors.ItemInvalidWorkchain;

            val (payloadBits, payloadRefs) = msg.forwardPayload.remainingBitsAndRefsCount();
            assert (payloadBits != 0) throw HopprErrors.ItemInvalidPayload;
            if (msg.forwardPayload.preloadUint(1) != 0) {
                assert (payloadBits == 1 && payloadRefs == 1) throw HopprErrors.ItemInvalidPayload;
            }

            val fwdFee = in.originalForwardFee;
            var rest = contract.getOriginalBalance() - ITEM_MIN_STORAGE_RESERVE;
            if (msg.forwardTonAmount != 0) {
                rest -= msg.forwardTonAmount + fwdFee;
            }
            if (msg.sendExcessesTo != null) {
                assert (
                    msg.sendExcessesTo.getWorkchain() == BASECHAIN
                ) throw HopprErrors.ItemInvalidWorkchain;
                rest -= fwdFee;
            }
            assert (rest >= 0) throw HopprErrors.ItemInsufficientValue;

            val previousOwner = storage.ownerAddress;
            storage.ownerAddress = msg.newOwnerAddress;
            storage.save();

            if (msg.forwardTonAmount != 0) {
                val ownershipNotification = createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: msg.newOwnerAddress,
                    value: msg.forwardTonAmount,
                    body: NotificationForNewOwner {
                        queryId: msg.queryId,
                        oldOwnerAddress: previousOwner,
                        payload: msg.forwardPayload,
                    },
                });
                ownershipNotification.send(SEND_MODE_PAY_FEES_SEPARATELY);
            }
            if (msg.sendExcessesTo != null) {
                val excessesMessage = createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: msg.sendExcessesTo,
                    value: rest,
                    body: ReturnExcessesBack { queryId: msg.queryId },
                });
                excessesMessage.send(SEND_MODE_PAY_FEES_SEPARATELY);
            }
        }
        RequestStaticData => {
            val staticDataResponse = createMessage({
                bounce: BounceMode.NoBounce,
                dest: in.senderAddress,
                value: 0,
                body: UnsafeBodyNoRef {
                    forceInline: ResponseStaticData {
                        queryId: msg.queryId,
                        itemIndex: storage.itemIndex as uint256,
                        collectionAddress: storage.collectionAddress,
                    },
                },
            });
            staticDataResponse.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }
        else => {
            assert (in.body.isEmpty()) throw HopprErrors.InvalidMessage;
        }
    }
}

fun onBouncedMessage(_in: InMessageBounced) {}

get fun get_nft_data(): (bool, int, address, address?, cell?) {
    var loading = NftItemStorage.startLoading();
    if (loading.isNotInitialized()) {
        return (false, loading.itemIndex, loading.collectionAddress, null, null);
    }
    val storage = loading.endLoading();
    return (
        true,
        storage.itemIndex,
        storage.collectionAddress,
        storage.ownerAddress,
        storage.content as unknown as cell,
    );
}
