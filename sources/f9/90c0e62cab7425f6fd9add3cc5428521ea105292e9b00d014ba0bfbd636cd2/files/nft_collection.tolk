import "@stdlib/strings"
import "errors"
import "fees"
import "messages"
import "types"

contract NftCollection {
    author: "Pirate Station"
    version: "1.0"
    description: "Pirate Station NFT Collection with public mint. TEP-62 and TEP-64 compatible"
    storage: NftCollectionStorage
    incomingMessages: AllowedMessageToNftCollection
}

type AllowedMessageToNftCollection =
    | Mint
    | AdminMint
    | RequestRoyaltyParams
    | ChangeCollectionAdmin
    | ChangeCollectionContent
    | ChangeMintPrice
    | WithdrawFunds

// Deploy the next NFT item to `recipient`. All items share the same (empty)
// individual content, so every NFT resolves to the same off-chain metadata.
fun deployNftItem(itemIndex: uint64, nftItemCode: cell, recipient: address) {
    val deployMsg = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: calcDeployedNftItem(itemIndex, contract.getAddress(), nftItemCode),
        value: NFT_DEPLOY_AMOUNT,
        body: NftItemInitAtDeployment { ownerAddress: recipient, content: "" },
    });
    deployMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessageToNftCollection.fromSlice(in.body);

    match (msg) {
        Mint => {
            var storage = lazy NftCollectionStorage.load();
            assert (storage.nextItemIndex < storage.maxSupply) throw Errors.SoldOut;
            assert (in.valueCoins >= storage.mintPrice) throw Errors.InsufficientPayment;

            deployNftItem(storage.nextItemIndex, storage.nftItemCode, in.senderAddress);
            storage.nextItemIndex += 1;
            storage.save();
        }

        AdminMint => {
            var storage = lazy NftCollectionStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw Errors.NotFromAdmin;
            assert (storage.nextItemIndex < storage.maxSupply) throw Errors.SoldOut;

            deployNftItem(storage.nextItemIndex, storage.nftItemCode, msg.recipient);
            storage.nextItemIndex += 1;
            storage.save();
        }

        RequestRoyaltyParams => {
            val storage = lazy NftCollectionStorage.load();
            val respondMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: in.senderAddress,
                value: 0,
                body: ResponseRoyaltyParams {
                    queryId: msg.queryId,
                    royaltyParams: storage.royaltyParams.load(),
                },
            });
            respondMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        ChangeCollectionAdmin => {
            var storage = lazy NftCollectionStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw Errors.NotFromAdmin;
            storage.adminAddress = msg.newAdminAddress;
            storage.save();
        }

        ChangeCollectionContent => {
            var storage = lazy NftCollectionStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw Errors.NotFromAdmin;
            storage.content = msg.newContent;
            storage.save();
        }

        ChangeMintPrice => {
            var storage = lazy NftCollectionStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw Errors.NotFromAdmin;
            storage.mintPrice = msg.newMintPrice;
            storage.save();
        }

        WithdrawFunds => {
            val storage = lazy NftCollectionStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw Errors.NotFromAdmin;

            val amount = contract.getOriginalBalance() - MIN_TONS_FOR_STORAGE;
            assert (amount > 0) throw Errors.TooSmallRestAmount;

            val withdrawMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: storage.adminAddress,
                value: amount,
                body: ReturnExcessesBack { queryId: msg.queryId },
            });
            withdrawMsg.send(SEND_MODE_REGULAR);
        }

        else => {
            // ignore empty messages (balance top-ups), reject unknown opcodes
            assert (in.body.isEmpty()) throw 0xFFFF;
        }
    }
}

fun onBouncedMessage(_in: InMessageBounced) {
    // receive funds back from a possibly bounced item deployment
}

get fun get_collection_data(): CollectionDataReply {
    val storage = lazy NftCollectionStorage.load();
    val content = lazy storage.content.load();
    return {
        nextItemIndex: storage.nextItemIndex,
        collectionMetadata: content.collectionMetadata,
        adminAddress: storage.adminAddress,
    };
}

get fun get_nft_address_by_index(itemIndex: int): address {
    val storage = lazy NftCollectionStorage.load();
    val nftDeployed = calcDeployedNftItem(itemIndex, contract.getAddress(), storage.nftItemCode);
    return nftDeployed.calculateAddress();
}

get fun royalty_params(): RoyaltyParams {
    val storage = lazy NftCollectionStorage.load();
    return storage.royaltyParams.load();
}

get fun get_nft_content(
    _itemIndex: int,
    individualNftContent: string,
): Cell<OffchainMetadataReply> {
    val storage = lazy NftCollectionStorage.load();
    val content = lazy storage.content.load();

    // full metadata URL = commonContent + individualNftContent;
    // for identical items individualNftContent is empty, so all resolve to commonContent
    var b = StringBuilder.create();
    b.append(content.commonContent);
    b.append(individualNftContent);
    return OffchainMetadataReply { string: b.build() }.toCell();
}

get fun get_mint_data(): MintDataReply {
    val storage = lazy NftCollectionStorage.load();
    return {
        nextItemIndex: storage.nextItemIndex,
        maxSupply: storage.maxSupply,
        mintPrice: storage.mintPrice,
        adminAddress: storage.adminAddress,
    };
}
