import "errors"
import "storage"
import "messages"

fun deployPostItem(
    itemIndex: uint64,
    ownerAddress: address,
    attachTonAmount: coins,
    postData: Cell<PostData>,
    itemCode: cell,
) {
    val deployMsg = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: calcDeployedTheOpenChannelItem(
            itemIndex,
            contract.getAddress(),
            itemCode,
        ),
        value: attachTonAmount,
        body: ItemInitAtDeployment {
            ownerAddress,
            postData,
        },
    });
    deployMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

type AllowedMessageToTheOpenChannel =
    | MintPost
    | ChangeAdmin

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessageToTheOpenChannel.fromSlice(in.body);

    match (msg) {
        MintPost => {
            assert (msg.attachTonAmount >= MIN_ITEM_DEPLOY_VALUE)
                throw ERROR_NOT_ENOUGH_TON;
            assert (in.valueCoins >= msg.attachTonAmount + MIN_COLLECTION_MESSAGE_VALUE)
                throw ERROR_NOT_ENOUGH_TON;
            validatePostDataCell(msg.postData);

            var storage = lazy TheOpenChannelStorage.load();
            val currentIndex = storage.nextItemIndex;
            deployPostItem(
                currentIndex,
                in.senderAddress,
                msg.attachTonAmount,
                msg.postData,
                storage.itemCode,
            );
            storage.nextItemIndex += 1;
            storage.save();
        }

        ChangeAdmin => {
            var storage = lazy TheOpenChannelStorage.load();
            assert (in.senderAddress == storage.adminAddress)
                throw ERROR_NOT_FROM_ADMIN;
            storage.adminAddress = msg.newAdminAddress;
            storage.save();
        }

        else => {
            assert (in.body.isEmpty()) throw 0xFFFF
        }
    }
}

struct CollectionDataReply {
    nextItemIndex: int
    metadata: cell
    adminAddress: address
}

get fun get_collection_data(): CollectionDataReply {
    val storage = lazy TheOpenChannelStorage.load();
    return {
        nextItemIndex: storage.nextItemIndex,
        metadata: storage.metadata,
        adminAddress: storage.adminAddress,
    }
}

get fun get_nft_address_by_index(itemIndex: int): address {
    val storage = lazy TheOpenChannelStorage.load();
    val deployed = calcDeployedTheOpenChannelItem(
        itemIndex as uint64,
        contract.getAddress(),
        storage.itemCode,
    );
    return deployed.calculateAddress();
}

get fun get_collection_metadata(): cell {
    val storage = lazy TheOpenChannelStorage.load();
    return storage.metadata;
}

get fun get_nft_content(itemIndex: int, individualContent: cell): cell {
    return individualContent;
}
