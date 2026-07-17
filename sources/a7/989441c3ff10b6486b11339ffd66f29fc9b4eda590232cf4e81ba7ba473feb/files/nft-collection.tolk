// TEP-62 NFT collection contract.
//
// This is the "factory" contract: it deploys and keeps track of
// individual NFT item contracts (see nft-item.tolk). Only its admin can
// mint new NFTs; anyone can read collection/item data.

import "errors";
import "storage";
import "messages";

// Deploys (= creates on-chain) one NFT item contract at its predictable
// address, and hands it its initial owner/content/royalty data in the
// same message (see nft-item.tolk's "not initialized" branch).
fun deployNftItem(
    itemIndex: uint64,
    nftItemCode: cell,
    attachGrams: coins,
    initParams: Cell<NftItemInitAtDeployment>,
) {
    val deployMsg = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: calcDeployedNftItem(
            itemIndex,
            contract.getAddress(),
            nftItemCode,
        ),
        value: attachGrams,
        body: initParams,
    });
    deployMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

type AllowedMessageToNftCollection =
    | DeployNft
    | BatchDeployNfts
    | ChangeCollectionAdmin;

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessageToNftCollection.fromSlice(in.body);

    match (msg) {
        // MINT one new NFT (admin-only).
        DeployNft => {
            var storage = lazy NftCollectionStorage.load();
            assert (in.senderAddress == storage.adminAddress)
                throw ERROR_NOT_FROM_ADMIN;
            assert (msg.itemIndex <= storage.nextItemIndex)
                throw ERROR_INVALID_ITEM_INDEX;

            val isLast = msg.itemIndex == storage.nextItemIndex;
            deployNftItem(
                msg.itemIndex,
                storage.nftItemCode,
                msg.attachGrams,
                msg.initParams,
            );
            if (isLast) {
                storage.nextItemIndex += 1;
                storage.save();
            }
        }

        // MINT many NFTs in one message (admin-only).
        BatchDeployNfts => {
            var storage = lazy NftCollectionStorage.load();
            assert (in.senderAddress == storage.adminAddress)
                throw ERROR_NOT_FROM_ADMIN;

            var counter = 0;
            var r = msg.deployList.findFirst();
            while (r.isFound) {
                counter += 1;
                // due to limits of action list size
                assert (counter < 250) throw ERROR_BATCH_LIMIT_EXCEEDED;

                val itemIndex = r.getKey();
                assert (itemIndex <= storage.nextItemIndex)
                    throw ERROR_NOT_FROM_ADMIN + counter;

                val dictItem = r.loadValue();
                deployNftItem(
                    itemIndex,
                    storage.nftItemCode,
                    dictItem.attachGrams,
                    dictItem.initParams,
                );

                if (itemIndex == storage.nextItemIndex) {
                    storage.nextItemIndex += 1;
                }
                r = msg.deployList.iterateNext(r);
            }
            storage.save();
        }

        // Transfer admin rights (mint permission) to a new address.
        ChangeCollectionAdmin => {
            var storage = lazy NftCollectionStorage.load();
            assert (in.senderAddress == storage.adminAddress)
                throw ERROR_NOT_FROM_ADMIN;
            storage.adminAddress = msg.newAdminAddress;
            storage.save();
        }

        else => {
            // ignore empty messages, "wrong opcode" for others
            assert (in.body.isEmpty()) throw 0xFFFF;
        }
    }
}

struct CollectionDataReply {
    nextItemIndex: int
    collectionMetadata: cell
    adminAddress: address
}

// TEP-64 offchain metadata format wrapper used by TEP-62.
struct (0x01) OffchainMetadataReply {
    string: SnakeString
}

get fun get_collection_data(): CollectionDataReply {
    val storage = lazy NftCollectionStorage.load();
    val content = lazy storage.content.load();

    return {
        nextItemIndex: storage.nextItemIndex,
        collectionMetadata: content.collectionMetadata,
        adminAddress: storage.adminAddress,
    }
}

get fun get_nft_address_by_index(itemIndex: int): address {
    val storage = lazy NftCollectionStorage.load();
    val nftDeployed = calcDeployedNftItem(
        itemIndex as uint64,
        contract.getAddress(),
        storage.nftItemCode,
    );
    return nftDeployed.calculateAddress();
}

get fun get_nft_content(
    itemIndex: int,
    individualNftContent: Cell<SnakeString>,
): Cell<OffchainMetadataReply> {
    val storage = lazy NftCollectionStorage.load();
    val content = lazy storage.content.load();

    return OffchainMetadataReply {
        string: beginCell()
            // assume it's short (no refs)
            .storeSlice(content.commonContent.load())
            // so, it's the first ref (snake encoding)
            .storeRef(individualNftContent)
            .endCell()
            .beginParse(),
    }.toCell();
}
