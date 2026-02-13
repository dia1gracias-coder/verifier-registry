import "error"
import "helper"
import "message"
import "storage"

// Check if sender is the contract owner or an authorized admin
fun isAdminOrOwner(senderAddress: address, collectionStorage: NftCollectionStorage): bool {
    if (collectionStorage.ownerAddress == senderAddress) {
        return true;
    }
    val result = collectionStorage.authorizedAdmins.get(senderAddress);
    return result.isFound;
}

fun handleMintNft(
    mutate NftCollectionStorage: NftCollectionStorage,
    senderAddress: address,
    nftItemMsg: MessageMintNft,
) {
    // step 1: check if the whole system is paused by calling master contract
    // TODO: need to implement the function, currently default bypass
    // step 2: permission check
    // only owner or authorized admin can mint
    assert (isAdminOrOwner(senderAddress, NftCollectionStorage)) throw ERROR_NOT_AUTHORIZED;

    // step 3: check if the item owner address is valid
    requireValidAddress(nftItemMsg.itemOwnerAddress);

    // step 4: check the item content is not empty
    assert (!nftItemMsg.itemContent.beginParse().isEmpty()) throw ERROR_INVALID_CONTENT;

    val nextItemIndex = NftCollectionStorage.nextItemIndex;

    // calculate the item deploy address
    val itemDeployAddress = calculateItemAddress(
        nextItemIndex,
        NftCollectionStorage.itemCode,
        contract.getAddress()
    );

    val messageBody = beginCell().storeAddress(nftItemMsg.itemOwnerAddress).storeRef(nftItemMsg
        .itemContent)
        .endCell();

    // create the message to send
    var message = createMessage({
        // the destination address for this message to reach/send to, which is the nft item contract address
        dest: itemDeployAddress,
        // how much ton to send to the nft item contract to prevent the contract freeze or deleted if amount is 0
        value: ton("0.1"),
        // the body of the message to send and receive by the nft item contract
        body: messageBody,
        // whether to bounce the message if it fails to reach the destination or receive by the nft item contract
        // set bounc to true if the destination address is already existed and deployed
        // for mint new nft item, set bounce to false since the destination address is not deployed yet
        bounce: false,
    });

    message.send(SEND_MODE_PAY_FEES_SEPARATELY);

    NftCollectionStorage.nextItemIndex = nextItemIndex + 1;
    NftCollectionStorage.totalNfts = NftCollectionStorage.totalNfts + 1;

    val extraData = NftCollectionStorage.extraData.load();
    NftCollectionStorage.extraData = NftCollectionExtraData {
        isPaused: extraData.isPaused,
        lastPausedBy: extraData.lastPausedBy,
        lastPausedAt: extraData.lastPausedAt,
        lastUnpausedBy: extraData.lastUnpausedBy,
        lastUnpausedAt: extraData.lastUnpausedAt,
        createdAt: extraData.createdAt,
        updatedAt: getCurrentTimestamp(),
    }.toCell();

    NftCollectionStorage.save();
}

// Batch mint function - mints multiple NFTs in one transaction
fun handleBatchMintNft(
    mutate NftCollectionStorage: NftCollectionStorage,
    senderAddress: address,
    batchMsg: MessageBatchMintNft,
) {
    // Permission check - only owner or authorized admin can batch mint
    assert (isAdminOrOwner(senderAddress, NftCollectionStorage)) throw ERROR_NOT_AUTHORIZED;

    // Validate batch size
    assert (batchMsg.batchSize > 0) throw ERROR_INVALID_BATCH_SIZE;
    assert (
        batchMsg.batchSize <= 250
    ) throw ERROR_BATCH_TOO_LARGE; // Max 250 per batch for gas safety

    var itemsSlice = batchMsg.items;
    var currentIndex = NftCollectionStorage.nextItemIndex;
    var mintedCount: uint32 = 0;

    // Process each item in the batch
    while (mintedCount < batchMsg.batchSize) {
        // Check if current slice is empty, follow ref to next cell
        if (itemsSlice.remainingBitsCount() == 0 && itemsSlice.remainingRefsCount() > 0) {
            itemsSlice = itemsSlice.loadRef().beginParse();
        }

        // Parse owner address and content for this item
        val itemOwnerAddress = itemsSlice.loadAddress();
        val itemContent = itemsSlice.loadRef();

        // Validate item owner address
        requireValidAddress(itemOwnerAddress);

        // Validate content is not empty
        assert (!itemContent.beginParse().isEmpty()) throw ERROR_INVALID_CONTENT;

        // Calculate item deploy address
        val itemDeployAddress = calculateItemAddress(
            currentIndex,
            NftCollectionStorage.itemCode,
            contract.getAddress()
        );

        // Create message body for NFT item initialization
        val messageBody = beginCell().storeAddress(itemOwnerAddress).storeRef(itemContent).endCell();

        // Send deployment message to NFT item
        var message = createMessage({
            dest: itemDeployAddress,
            value: ton("0.1"), // 0.1 TON per item
            body: messageBody,
            bounce: false, // No bounce for new deployments
        });

        message.send(SEND_MODE_PAY_FEES_SEPARATELY);

        currentIndex = currentIndex + 1;
        mintedCount = mintedCount + 1;
    }

    // Update collection storage
    NftCollectionStorage.nextItemIndex = currentIndex;
    NftCollectionStorage.totalNfts = NftCollectionStorage.totalNfts + (batchMsg.batchSize as uint64);

    val extraData = NftCollectionStorage.extraData.load();
    NftCollectionStorage.extraData = NftCollectionExtraData {
        isPaused: extraData.isPaused,
        lastPausedBy: extraData.lastPausedBy,
        lastPausedAt: extraData.lastPausedAt,
        lastUnpausedBy: extraData.lastUnpausedBy,
        lastUnpausedAt: extraData.lastUnpausedAt,
        createdAt: extraData.createdAt,
        updatedAt: getCurrentTimestamp(),
    }.toCell();

    NftCollectionStorage.save();
}

// Batch pause NFT items - pauses multiple NFTs in one transaction
fun handleBatchPauseNft(
    mutate NftCollectionStorage: NftCollectionStorage,
    senderAddress: address,
    batchMsg: MessageBatchPauseNft,
) {
    // Permission check - only owner or authorized admin can batch pause
    assert (isAdminOrOwner(senderAddress, NftCollectionStorage)) throw ERROR_NOT_AUTHORIZED;

    var indicesSlice = batchMsg.itemIndices;

    // Process each item index
    while (!indicesSlice.isEmpty()) {
        val itemIndex = indicesSlice.loadUint(64);

        // Calculate NFT item address
        val itemAddress = getCalculatedItemAddress(
            itemIndex,
            NftCollectionStorage.itemCode,
            contract.getAddress()
        );

        // Create pause message for NFT item
        val pauseBody = beginCell().storeUint(0x00050004, 32) // MessagePauseNft opcode
            .storeUint(batchMsg.queryId, 64)
            .endCell();

        // Send pause message to NFT item
        var message = createMessage({
            dest: itemAddress,
            value: ton("0.05"), // 0.05 TON per item
            body: pauseBody,
            bounce: true, // Bounce if item doesn't exist
        });

        message.send(SEND_MODE_PAY_FEES_SEPARATELY);
    }

    // Update collection timestamp
    val extraData = NftCollectionStorage.extraData.load();
    NftCollectionStorage.extraData = NftCollectionExtraData {
        isPaused: extraData.isPaused,
        lastPausedBy: extraData.lastPausedBy,
        lastPausedAt: extraData.lastPausedAt,
        lastUnpausedBy: extraData.lastUnpausedBy,
        lastUnpausedAt: extraData.lastUnpausedAt,
        createdAt: extraData.createdAt,
        updatedAt: getCurrentTimestamp(),
    }.toCell();

    NftCollectionStorage.save();
}

// Batch unpause NFT items - unpauses multiple NFTs in one transaction
fun handleBatchUnpauseNft(
    mutate NftCollectionStorage: NftCollectionStorage,
    senderAddress: address,
    batchMsg: MessageBatchUnpauseNft,
) {
    // Permission check - only owner or authorized admin can batch unpause
    assert (isAdminOrOwner(senderAddress, NftCollectionStorage)) throw ERROR_NOT_AUTHORIZED;

    var indicesSlice = batchMsg.itemIndices;

    // Process each item index
    while (!indicesSlice.isEmpty()) {
        val itemIndex = indicesSlice.loadUint(64);

        // Calculate NFT item address
        val itemAddress = getCalculatedItemAddress(
            itemIndex,
            NftCollectionStorage.itemCode,
            contract.getAddress()
        );

        // Create unpause message for NFT item
        val unpauseBody = beginCell().storeUint(0x00050005, 32) // MessageUnpauseNft opcode
            .storeUint(batchMsg.queryId, 64)
            .endCell();

        // Send unpause message to NFT item
        var message = createMessage({
            dest: itemAddress,
            value: ton("0.05"), // 0.05 TON per item
            body: unpauseBody,
            bounce: true, // Bounce if item doesn't exist
        });

        message.send(SEND_MODE_PAY_FEES_SEPARATELY);
    }

    // Update collection timestamp
    val extraData = NftCollectionStorage.extraData.load();
    NftCollectionStorage.extraData = NftCollectionExtraData {
        isPaused: extraData.isPaused,
        lastPausedBy: extraData.lastPausedBy,
        lastPausedAt: extraData.lastPausedAt,
        lastUnpausedBy: extraData.lastUnpausedBy,
        lastUnpausedAt: extraData.lastUnpausedAt,
        createdAt: extraData.createdAt,
        updatedAt: getCurrentTimestamp(),
    }.toCell();

    NftCollectionStorage.save();
}

// Add to nft_collection_contract.tolk
fun handleWithdrawCollection(
    mutate NftCollectionStorage: NftCollectionStorage,
    senderAddress: address,
    msg: MessageWithdrawCollection,
) {
    // Only owner or authorized admin can withdraw
    assert (isAdminOrOwner(senderAddress, NftCollectionStorage)) throw ERROR_NOT_AUTHORIZED;

    val currentBalance = contract.getOriginalBalance();
    val minBalance = ton("0.1"); // Keep minimum for storage

    assert (currentBalance > minBalance) throw ERROR_INSUFFICIENT_BALANCE;

    val withdrawAmount = msg.amount == 0 ? currentBalance - minBalance : msg.amount; // Withdraw all except minimum

    assert (withdrawAmount <= (currentBalance - minBalance)) throw ERROR_INSUFFICIENT_BALANCE;

    // Send to owner
    var withdrawMsg = createMessage({
        dest: NftCollectionStorage.ownerAddress,
        value: withdrawAmount,
        bounce: false,
        body: beginCell().endCell(),
    });

    withdrawMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

// Forward a revoke message to an NFT item (owner or authorized admin can call)
fun handleForwardRevoke(
    mutate NftCollectionStorage: NftCollectionStorage,
    senderAddress: address,
    msg: MessageForwardRevoke,
) {
    assert (isAdminOrOwner(senderAddress, NftCollectionStorage)) throw ERROR_NOT_AUTHORIZED;

    val itemAddress = getCalculatedItemAddress(
        msg.itemIndex,
        NftCollectionStorage.itemCode,
        contract.getAddress()
    );

    // Build MessageRevokeNft body: opcode(32) + queryId(64) + newOwner(address)
    val revokeBody = beginCell()
        .storeUint(0x00050006, 32)
        .storeUint(msg.queryId, 64)
        .storeAddress(msg.newOwner)
        .endCell();

    var message = createMessage({
        dest: itemAddress,
        value: ton("0.05"),
        body: revokeBody,
        bounce: true,
    });

    message.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

// Forward a collection transfer message to an NFT item (owner or authorized admin can call)
fun handleForwardCollectionTransfer(
    mutate NftCollectionStorage: NftCollectionStorage,
    senderAddress: address,
    msg: MessageForwardCollectionTransfer,
) {
    assert (isAdminOrOwner(senderAddress, NftCollectionStorage)) throw ERROR_NOT_AUTHORIZED;

    val itemAddress = getCalculatedItemAddress(
        msg.itemIndex,
        NftCollectionStorage.itemCode,
        contract.getAddress()
    );

    // Build MessageCollectionTransfer body: opcode(32) + queryId(64) + newOwner(address)
    val transferBody = beginCell()
        .storeUint(0x00050007, 32)
        .storeUint(msg.queryId, 64)
        .storeAddress(msg.newOwner)
        .endCell();

    var message = createMessage({
        dest: itemAddress,
        value: ton("0.05"),
        body: transferBody,
        bounce: true,
    });

    message.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

// Add an authorized admin (only contract owner can add, not other admins)
fun handleAddAuthorizedAdmin(
    mutate NftCollectionStorage: NftCollectionStorage,
    senderAddress: address,
    msg: MessageAddAuthorizedAdmin,
) {
    // Only the contract owner can add admins (not other admins)
    assert (NftCollectionStorage.ownerAddress == senderAddress) throw ERROR_NOT_AUTHORIZED;

    // Validate admin address
    requireValidAddress(msg.adminAddress);

    // Add to authorized admins dict
    NftCollectionStorage.authorizedAdmins.set(msg.adminAddress, true);

    NftCollectionStorage.save();
}

// Remove an authorized admin (only contract owner can remove)
fun handleRemoveAuthorizedAdmin(
    mutate NftCollectionStorage: NftCollectionStorage,
    senderAddress: address,
    msg: MessageRemoveAuthorizedAdmin,
) {
    // Only the contract owner can remove admins
    assert (NftCollectionStorage.ownerAddress == senderAddress) throw ERROR_NOT_AUTHORIZED;

    // Remove from authorized admins dict
    NftCollectionStorage.authorizedAdmins.delete(msg.adminAddress);

    NftCollectionStorage.save();
}

fun onInternalMessage(in: InMessage) {
    var NftCollectionStorage = lazy NftCollectionStorage.load();

    val nftCollectionMsg = lazy AllowedCollectionMessages.fromSlice(in.body);
    match (nftCollectionMsg) {
        MessageMintNft => {
            handleMintNft(mutate NftCollectionStorage, in.senderAddress, nftCollectionMsg);
        }
        MessageBatchMintNft => {
            handleBatchMintNft(mutate NftCollectionStorage, in.senderAddress, nftCollectionMsg);
        }
        MessageBatchPauseNft => {
            handleBatchPauseNft(mutate NftCollectionStorage, in.senderAddress, nftCollectionMsg);
        }
        MessageBatchUnpauseNft => {
            handleBatchUnpauseNft(mutate NftCollectionStorage, in.senderAddress, nftCollectionMsg);
        }
        MessageWithdrawCollection => {
            handleWithdrawCollection(
                mutate NftCollectionStorage,
                in.senderAddress,
                nftCollectionMsg
            );
        }
        MessageForwardRevoke => {
            handleForwardRevoke(mutate NftCollectionStorage, in.senderAddress, nftCollectionMsg);
        }
        MessageForwardCollectionTransfer => {
            handleForwardCollectionTransfer(mutate NftCollectionStorage, in.senderAddress, nftCollectionMsg);
        }
        MessageAddAuthorizedAdmin => {
            handleAddAuthorizedAdmin(mutate NftCollectionStorage, in.senderAddress, nftCollectionMsg);
        }
        MessageRemoveAuthorizedAdmin => {
            handleRemoveAuthorizedAdmin(mutate NftCollectionStorage, in.senderAddress, nftCollectionMsg);
        }
        else => {
            assert (in.body.isEmpty()) throw 0xFFFF;
        }
    }
}

struct CollectionDataResponse {
    nextItemIndex: uint64
    collectionContent: cell
    ownerAddress: address
}

struct CollectionStatsResponse {
    nextItemIndex: uint64
    totalNfts: uint64
    updatedAt: uint64
    isPaused: bool
    lastPausedBy: address?
    lastPausedAt: uint64
    lastUnpausedBy: address?
    lastUnpausedAt: uint64
}

get fun getCollectionStats(): CollectionStatsResponse {
    val collectionStorage = lazy NftCollectionStorage.load();
    // Manually deserialize extraData from cell reference
    val extraData = lazy NftCollectionExtraData.fromCell(collectionStorage.extraData);

    return CollectionStatsResponse {
        nextItemIndex: collectionStorage.nextItemIndex,
        totalNfts: collectionStorage.totalNfts,
        updatedAt: extraData.updatedAt,
        isPaused: extraData.isPaused,
        lastPausedBy: extraData.lastPausedBy,
        lastPausedAt: extraData.lastPausedAt,
        lastUnpausedBy: extraData.lastUnpausedBy,
        lastUnpausedAt: extraData.lastUnpausedAt,
    };
}

get fun getTotalNfts(): uint64 {
    val collectionStorage = lazy NftCollectionStorage.load();

    return collectionStorage.totalNfts;
}

// Check if an address is an authorized admin
get fun isAuthorizedAdmin(adminAddress: address): bool {
    val collectionStorage = lazy NftCollectionStorage.load();
    val result = collectionStorage.authorizedAdmins.get(adminAddress);
    return result.isFound;
}

// must have function for collection contract
// must return next item index, admin address, collection metadata
get fun get_collection_data(): CollectionDataResponse {
    val collectionStorage = lazy NftCollectionStorage.load();

    return CollectionDataResponse {
        nextItemIndex: collectionStorage.nextItemIndex,
        collectionContent: collectionStorage.content,
        ownerAddress: collectionStorage.ownerAddress,
    };
}

// ================================================
// PRIVATE HELPER FUNCTION (Collection-specific)
// ================================================
fun calculateItemAddress(itemIndex: uint64, itemCode: cell, collectionAddress: address): AutoDeployAddress {
    val itemData = beginCell().storeUint(itemIndex, 64).storeAddress(collectionAddress).endCell();

    val stateInit = ContractState { code: itemCode, data: itemData };
    val calculatedItemAddress = AutoDeployAddress { workchain: 0, stateInit };

    return calculatedItemAddress;
}

fun getCalculatedItemAddress(itemIndex: uint64, itemCode: cell, collectionAddress: address): address {
    val calculatedItemAddress = calculateItemAddress(itemIndex, itemCode, collectionAddress);

    return calculatedItemAddress.calculateAddress();
}

// based on the nft item index, return it nft item address
get fun get_nft_address_by_index(item_index: uint64): address {
    val collectionStorage = lazy NftCollectionStorage.load();

    // get the itemcode
    val itemCode = collectionStorage.itemCode;

    return getCalculatedItemAddress(item_index, itemCode, contract.getAddress());
}

get fun get_nft_content(item_index: uint64, individual_content: cell): cell {
    val collectionStorage = lazy NftCollectionStorage.load();

    val nftContent = beginCell().storeRef(collectionStorage.content).storeRef(individual_content)
        .endCell();

    return nftContent;
}
