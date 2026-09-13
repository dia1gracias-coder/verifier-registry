import "@stdlib/strings"
import "../common/consts"
import "../common/errors"
import "../common/tep-nft"
import "desk-messages"
import "desk-types"

contract DeskCollection {
    author: "GRAMDESKS"
    version: "0.1.0"
    description: "Desk collection. TEP-62/64/66. Deploys DeskItems on behalf of the Minter and registers them in the Pot."
    storage: CollectionStorage
    incomingMessages: AllowedMessageToCollection
}

type AllowedMessageToCollection =
    | DeployDesk
    | RequestRoyaltyParams
    | ChangeCollectionAdmin
    | SetCollectionMinter

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessageToCollection.fromSlice(in.body);

    match (msg) {
        DeployDesk => {
            var storage = lazy CollectionStorage.load();
            assert (in.senderAddress == storage.minter) throw Errors.NotFromMinter;
            assert (msg.serial <= storage.nextSerial) throw Errors.InvalidSerial;
            assert (msg.owner.getWorkchain() == BASECHAIN) throw Errors.InvalidWorkchain;
            val isNew = msg.serial == storage.nextSerial;
            if (isNew) {
                assert (storage.nextSerial < storage.cap) throw Errors.CapReached;
            }
            val required = DESK_DEPLOY_VALUE + (isNew ? REGISTER_DESK_VALUE : (0 as coins)) + ton("0.01");
            assert (in.valueCoins >= required) throw Errors.InsufficientValue;

            val itemInit = calcDeployedDesk(msg.serial, contract.getAddress(), storage.deskItemCode);
            val ev = createExternalLogMessage({
                dest: ExtOutLogBucket { topic: EVENT_TOPIC_DESK_DEPLOYED as uint248 },
                body: DeskDeployedEvent { serial: msg.serial, owner: msg.owner, item: itemInit.calculateAddress(), isNew },
            });
            ev.send(SEND_MODE_REGULAR);

            val deployMsg = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: itemInit,
                value: DESK_DEPLOY_VALUE,
                body: DeskItemInit { owner: msg.owner, pot: storage.pot },
            });
            deployMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);

            if (isNew) {
                val registerMsg = createMessage({
                    bounce: BounceMode.Only256BitsOfBody,
                    dest: storage.pot,
                    value: REGISTER_DESK_VALUE,
                    body: RegisterDesk { queryId: msg.queryId, serial: msg.serial },
                });
                registerMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
                storage.nextSerial += 1;
                storage.save();
            }

            // Acknowledge to the minter with whatever value is left from the incoming message.
            val okMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: in.senderAddress,
                value: 0,
                body: DeployDeskOk { queryId: msg.queryId, serial: msg.serial },
            });
            okMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS);
        }

        RequestRoyaltyParams => {
            val storage = lazy CollectionStorage.load();
            val respondMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: in.senderAddress,
                value: 0,
                body: ResponseRoyaltyParams {
                    queryId: msg.queryId,
                    royaltyParams: storage.royalty.load(),
                },
            });
            respondMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        ChangeCollectionAdmin => {
            var storage = lazy CollectionStorage.load();
            assert (in.senderAddress == storage.admin) throw Errors.NotFromAdmin;
            storage.admin = msg.newAdmin;
            storage.save();
        }

        SetCollectionMinter => {
            var storage = lazy CollectionStorage.load();
            assert (in.senderAddress == storage.admin) throw Errors.NotFromAdmin;
            storage.minter = msg.minter;
            storage.save();
        }

        else => {
            // accept plain TON (empty body or text comment), reject unknown opcodes
            assert (in.body.isEmpty() || in.body.preloadUint(32) == 0) throw 0xFFFF;
        }
    }
}

fun onBouncedMessage(_in: InMessageBounced) {
    // Bounced DeskItem deploy / RegisterDesk: keep the TON, the Minter can RetryDeploy.
}

get fun get_collection_data(): CollectionDataReply {
    val storage = lazy CollectionStorage.load();
    val content = lazy storage.content.load();
    return {
        nextItemIndex: storage.nextSerial,
        collectionMetadata: content.collectionMetadata,
        adminAddress: storage.admin,
    };
}

get fun get_nft_address_by_index(itemIndex: int): address {
    val storage = lazy CollectionStorage.load();
    return calcDeployedDesk(itemIndex, contract.getAddress(), storage.deskItemCode).calculateAddress();
}

get fun royalty_params(): RoyaltyParams {
    val storage = lazy CollectionStorage.load();
    return storage.royalty.load();
}

/// Off-chain metadata: `<commonContent><serial>.json`; the individual item content is ignored.
get fun get_nft_content(itemIndex: int, _individualNftContent: string): Cell<OffchainMetadataReply> {
    val storage = lazy CollectionStorage.load();
    val content = lazy storage.content.load();
    var b = StringBuilder.create();
    b.append(content.commonContent);
    b.appendInt(itemIndex);
    b.append(".json");
    return OffchainMetadataReply { string: b.build() }.toCell();
}

get fun get_desk_config(): (address, address, int, int) {
    val storage = lazy CollectionStorage.load();
    return (storage.minter, storage.pot, storage.nextSerial, storage.cap);
}
