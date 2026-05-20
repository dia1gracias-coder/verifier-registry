import "errors"
import "fees-management"
import "messages"
import "types"

contract NftItem {
    author: "Acton User"
    version: "1.0.0"
    description: "Standard NFT Item. TEP-62 and TEP-64 compliant"
    storage: NftItemStorage
    storageAtDeployment: NftItemStorageNotInitialized
    incomingMessages: AllowedMessageToNftItem
}

type AllowedMessageToNftItem =
    | AskToChangeOwnership
    | RequestStaticData

fun onInternalMessage(in: InMessage) {
    var loadingStorage = NftItemStorage.startLoading();
    if (loadingStorage.isNotInitialized()) {
        assert (
            in.senderAddress == loadingStorage.collectionAddress
        ) throw Errors.NotFromCollection;

        // using a message from collection, convert "uninitialized" to "initialized" state
        val initParams = NftItemInitAtDeployment.fromSlice(in.body);
        val storage: NftItemStorage = {
            itemIndex: loadingStorage.itemIndex,
            collectionAddress: loadingStorage.collectionAddress,
            ownerAddress: initParams.ownerAddress,
            content: initParams.content,
        };
        storage.save();
        return;
    }

    var storage = loadingStorage.endLoading();

    val msg = lazy AllowedMessageToNftItem.fromSlice(in.body);

    match (msg) {
        AskToChangeOwnership => {
            assert (in.senderAddress == storage.ownerAddress) throw Errors.NotFromOwner;
            throw Errors.SoulboundTransferDisabled;
        }

        RequestStaticData => {
            val respondMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: in.senderAddress,
                value: 0,
                // why ever, in FunC implementation, item index was encoded as 256-bit (not 64-bit),
                // do the same here to pass FunC tests;
                // but since a response becomes too long (64 + 256 + address), the compiler will create a ref;
                // force the compiler not to create a ref, because it's guaranteed that with
                // value (coins) = 0 it will nevertheless fit into a message cell directly
                body: UnsafeBodyNoRef {
                    forceInline: ResponseStaticData {
                        queryId: msg.queryId,
                        itemIndex: storage.itemIndex as uint256,
                        collectionAddress: storage.collectionAddress,
                    },
                },
            });
            respondMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        else => {
            // ignore empty messages, "wrong opcode" for others
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
    return {
        isInitialized: true,
        itemIndex: storage.itemIndex,
        collectionAddress: storage.collectionAddress,
        ownerAddress: storage.ownerAddress,
        content: storage.content,
    };
}
