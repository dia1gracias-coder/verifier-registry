import "@stdlib/strings"
import "collection-storage"
import "constants"
import "errors"
import "messages"
import "metadata"
import "nft-utils"
import "payment-native"
import "quote-types"
import "signature-verification"

contract NftCollection {
    author: "Hoppr"
    version: "1.0.0"
    description: "Hoppr Genesis fixed-supply signed-quote NFT collection"
    incomingMessages: AllowedMessageToCollection
    storage: NftCollectionStorage
}

type AllowedMessageToCollection =
    | MintWithQuote
    | PauseMinting
    | UnpauseMinting
    | RotateSigner
    | RevealMetadata
    | FreezeMetadata
    | PremintGiveaways
    | TransferAdmin
    | PremintTreasury
    | SetMerkleRoot
    | ClaimWhitelist

fun requireAdmin(sender: address, admin: address) {
    assert (sender == admin) throw HopprErrors.NotAdmin;
}

fun whitelistLeaf(wallet: address, snapshotBalance: uint256): uint256 {
    return beginCell().storeAddress(wallet).storeUint(snapshotBalance, 256).endCell().hash();
}

fun sortedMerklePair(left: uint256, right: uint256): uint256 {
    return left < right
        ? beginCell().storeUint(left, 256).storeUint(right, 256).endCell().hash()
        : beginCell().storeUint(right, 256).storeUint(left, 256).endCell().hash();
}

fun verifyWhitelistProof(
    wallet: address,
    snapshotBalance: uint256,
    proof: cell,
    expectedRoot: uint256,
): bool {
    var current = whitelistLeaf(wallet, snapshotBalance);
    var cursor = proof.beginParse();
    var depth = 0;
    while (!cursor.isEmpty()) {
        assert (depth < MAX_MERKLE_PROOF_DEPTH) throw HopprErrors.MerkleProofTooDeep;
        assert (cursor.remainingBitsCount() == 256) throw HopprErrors.InvalidMerkleProof;
        val sibling = cursor.loadUint(256) as uint256;
        current = sortedMerklePair(current, sibling);
        val refs = cursor.remainingRefsCount();
        assert (refs <= 1) throw HopprErrors.InvalidMerkleProof;
        if (refs == 0) {
            cursor.assertEnd();
            return current == expectedRoot;
        }
        cursor = cursor.loadRef().beginParse();
        depth += 1;
    }
    return current == expectedRoot;
}

fun deployNft(index: uint32, owner: address, content: string, code: cell, value: coins) {
    val deploymentMessage = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: calcDeployedNftItem(index, contract.getAddress(), code),
        value,
        body: NftItemInitAtDeployment {
            ownerAddress: owner,
            content,
        },
    });
    deploymentMessage.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
}

fun validateQuote(
    sender: address,
    incomingValue: coins,
    quote: HopprQuote,
    storage: NftCollectionStorage,
    config: CollectionConfig,
) {
    val tail: HopprQuoteTail = quote.tail.load();
    assert (!storage.paused) throw HopprErrors.MintPaused;
    assert (quote.version == QUOTE_VERSION) throw HopprErrors.UnsupportedQuoteVersion;
    assert (quote.networkId == config.networkId) throw HopprErrors.WrongNetwork;
    assert (quote.mintContractAddress == contract.getAddress()) throw HopprErrors.WrongCollection;
    assert (quote.buyerWallet == sender) throw HopprErrors.WrongBuyer;
    assert (
        tail.crypto.load().signerEpoch == storage.signerEpoch
    ) throw HopprErrors.WrongSignerEpoch;
    assert (
        tail.paymentAssetKind == PAYMENT_ASSET_NATIVE && tail.paymentAssetId == NATIVE_ASSET_ID
    ) throw HopprErrors.WrongPaymentAsset;
    assert (blockchain.now() >= tail.validFrom) throw HopprErrors.QuoteNotYetValid;
    assert (blockchain.now() <= tail.validUntil) throw HopprErrors.QuoteExpired;
    assert (
        tail.validUntil >= tail.validFrom && tail.validUntil - tail.validFrom <= MAX_QUOTE_LIFETIME
    ) throw HopprErrors.QuoteLifetimeInvalid;
    assert (quote.quantity > 0) throw HopprErrors.QuantityZero;
    assert (quote.quantity <= config.maximumSupply) throw HopprErrors.SupplyExceeded;
    assert (
        quote.lastSerial == quote.firstSerial + quote.quantity - 1
    ) throw HopprErrors.InvalidSerialRange;
    assert (
        quote.firstSerial >= FIRST_NFT_INDEX && quote.firstSerial <= config.maximumSupply &&
        quote.lastSerial <= config.maximumSupply &&
        storage.mintedCount <= config.maximumSupply - quote.quantity
    ) throw HopprErrors.SupplyExceeded;
    val publicFirstSerial = FIRST_NFT_INDEX + config.giveawaySupply + config.treasuryNftSupply +
    config.whitelistMaxClaims;
    assert (quote.firstSerial >= publicFirstSerial) throw HopprErrors.PublicAllocationExceeded;
    val whitelist = storage.assets.load().whitelist.load();
    val publicMintsUsed = storage.mintedCount - storage.giveawayPremintedCount -
    storage.treasuryPremintedCount -
    whitelist.claimsUsed;
    val publicMax = config.maximumSupply - config.giveawaySupply - config.treasuryNftSupply -
    config.whitelistMaxClaims;
    assert (
        publicMintsUsed <= publicMax - quote.quantity
    ) throw HopprErrors.PublicAllocationExceeded;
    validateNativePayment(incomingValue, quote, config);
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessageToCollection.fromSlice(in.body);
    match (msg) {
        MintWithQuote => {
            var storage = lazy NftCollectionStorage.load();
            val config = storage.config.load();
            val quote = msg.quote.load();
            val quoteTail = quote.tail.load();
            val quoteHash: uint256 = msg.quote.hash();
            var assets = storage.assets.load();
            var maps = assets.maps.load();
            assert (
                !maps.usedQuoteHashes.get(quoteHash).isFound
            ) throw HopprErrors.QuoteAlreadyUsed;
            validateQuote(in.senderAddress, in.valueCoins, quote, storage, config);
            verifyQuoteSignature(msg.quote, msg.signature, storage.quotePublicKey);

            var i = 0;
            while (i < quote.quantity) {
                val serial = quote.firstSerial + i;
                assert (
                    !maps.mintedSerialGuards.get(serial).isFound
                ) throw HopprErrors.SerialAlreadyMinted;
                i += 1;
            }

            maps.usedQuoteHashes.set(quoteHash, true);
            i = 0;
            while (i < quote.quantity) {
                val serial = quote.firstSerial + i;
                maps.mintedSerialGuards.set(serial, true);
                deployNft(
                    serial,
                    quote.buyerWallet,
                    serialContent(serial),
                    assets.nftItemCode,
                    config.itemDeploymentValue,
                );
                i += 1;
            }
            storage.mintedCount += quote.quantity;
            while (
                storage.nextItemIndex <= config.maximumSupply &&
                maps.mintedSerialGuards.get(storage.nextItemIndex).isFound
            ) {
                storage.nextItemIndex += 1;
            }
            assets.maps = maps.toCell();
            storage.assets = assets.toCell();
            storage.save();

            val treasuryPayment = createMessage({
                // A treasury may be an uninitialized wallet address. Send a
                // plain non-bounce transfer so dust test prices are credited
                // without attempting to execute an event body with no gas.
                bounce: BounceMode.NoBounce,
                dest: config.immutableTreasuryAddress,
                value: quoteTail.paymentAmountBaseUnits,
            });
            treasuryPayment.send(
                SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL,
            );
        }
        PremintGiveaways => {
            var storage = lazy NftCollectionStorage.load();
            val config = storage.config.load();
            requireAdmin(in.senderAddress, storage.adminAddress);
            assert (
                storage.giveawayPremintedCount < config.giveawaySupply &&
                storage.mintedCount == storage.giveawayPremintedCount &&
                storage.nextItemIndex == storage.mintedCount + FIRST_NFT_INDEX
            ) throw HopprErrors.GiveawayPremintAlreadyCompleted;
            assert (msg.quantity > 0) throw HopprErrors.QuantityZero;
            assert (
                msg.quantity <= config.giveawaySupply - storage.giveawayPremintedCount
            ) throw HopprErrors.SupplyExceeded;

            val requiredValue = msg.quantity * config.itemDeploymentValue +
            config.collectionExecutionReserve +
            config.outboundMessageReserve;
            assert (in.valueCoins >= requiredValue) throw HopprErrors.Underpayment;

            var assets = storage.assets.load();
            var maps = assets.maps.load();
            var serial = storage.nextItemIndex;
            val endSerial = serial + msg.quantity;
            while (serial < endSerial) {
                maps.mintedSerialGuards.set(serial, true);
                deployNft(
                    serial,
                    storage.adminAddress,
                    serialContent(serial),
                    assets.nftItemCode,
                    config.itemDeploymentValue,
                );
                serial += 1;
            }
            storage.mintedCount += msg.quantity;
            storage.giveawayPremintedCount += msg.quantity;
            storage.nextItemIndex += msg.quantity;
            if (
                storage.giveawayPremintedCount == config.giveawaySupply &&
                config.treasuryNftSupply == 0 &&
                (config.whitelistMaxClaims == 0 || assets.whitelist.load().merkleRoot != 0)
            ) {
                storage.paused = false;
            }
            assets.maps = maps.toCell();
            storage.assets = assets.toCell();
            storage.save();
        }
        PremintTreasury => {
            var storage = lazy NftCollectionStorage.load();
            val config = storage.config.load();
            requireAdmin(in.senderAddress, storage.adminAddress);
            assert (
                storage.giveawayPremintedCount == config.giveawaySupply
            ) throw HopprErrors.GiveawayPremintIncomplete;
            assert (
                storage.treasuryPremintedCount < config.treasuryNftSupply &&
                storage.mintedCount ==
                storage.giveawayPremintedCount + storage.treasuryPremintedCount &&
                storage.nextItemIndex == storage.mintedCount + FIRST_NFT_INDEX
            ) throw HopprErrors.TreasuryPremintAlreadyCompleted;
            assert (msg.quantity > 0) throw HopprErrors.QuantityZero;
            assert (
                msg.quantity <= config.treasuryNftSupply - storage.treasuryPremintedCount
            ) throw HopprErrors.SupplyExceeded;

            val requiredValue = msg.quantity * config.itemDeploymentValue +
            config.collectionExecutionReserve +
            config.outboundMessageReserve;
            assert (in.valueCoins >= requiredValue) throw HopprErrors.Underpayment;

            var assets = storage.assets.load();
            var maps = assets.maps.load();
            var serial = storage.nextItemIndex;
            val endSerial = serial + msg.quantity;
            while (serial < endSerial) {
                maps.mintedSerialGuards.set(serial, true);
                deployNft(
                    serial,
                    config.immutableTreasuryAddress,
                    serialContent(serial),
                    assets.nftItemCode,
                    config.itemDeploymentValue,
                );
                serial += 1;
            }
            storage.mintedCount += msg.quantity;
            storage.treasuryPremintedCount += msg.quantity;
            storage.nextItemIndex += msg.quantity;
            if (
                storage.treasuryPremintedCount == config.treasuryNftSupply &&
                (config.whitelistMaxClaims == 0 || assets.whitelist.load().merkleRoot != 0)
            ) {
                storage.paused = false;
            }
            assets.maps = maps.toCell();
            storage.assets = assets.toCell();
            storage.save();
        }
        SetMerkleRoot => {
            var storage = lazy NftCollectionStorage.load();
            requireAdmin(in.senderAddress, storage.adminAddress);
            var assets = storage.assets.load();
            var whitelist = assets.whitelist.load();
            assert (!whitelist.locked) throw HopprErrors.WhitelistRootLocked;
            assert (msg.newRoot != 0) throw HopprErrors.WhitelistRootUnset;
            whitelist.merkleRoot = msg.newRoot;
            assets.whitelist = whitelist.toCell();
            storage.assets = assets.toCell();
            storage.save();
        }
        ClaimWhitelist => {
            var storage = lazy NftCollectionStorage.load();
            val config = storage.config.load();
            assert (!storage.paused) throw HopprErrors.MintPaused;
            var assets = storage.assets.load();
            var whitelist = assets.whitelist.load();
            assert (whitelist.merkleRoot != 0) throw HopprErrors.WhitelistRootUnset;
            assert (
                whitelist.claimsUsed < config.whitelistMaxClaims
            ) throw HopprErrors.WhitelistAllocationExhausted;
            val walletKey = beginCell().storeAddress(in.senderAddress).endCell().hash();
            var maps = assets.maps.load();
            assert (
                !maps.whitelistClaimedWallets.get(walletKey).isFound
            ) throw HopprErrors.WhitelistAlreadyClaimed;
            assert (
                verifyWhitelistProof(
                    in.senderAddress,
                    msg.snapshotBalance,
                    msg.proof,
                    whitelist.merkleRoot,
                )
            ) throw HopprErrors.InvalidMerkleProof;
            assert (storage.mintedCount < config.maximumSupply) throw HopprErrors.SupplyExceeded;
            val requiredValue = config.itemDeploymentValue + config.collectionExecutionReserve +
            config.outboundMessageReserve;
            assert (in.valueCoins >= requiredValue) throw HopprErrors.Underpayment;

            val serial = FIRST_NFT_INDEX + config.giveawaySupply + config.treasuryNftSupply +
            whitelist.claimsUsed;
            assert (
                !maps.mintedSerialGuards.get(serial).isFound
            ) throw HopprErrors.SerialAlreadyMinted;
            maps.mintedSerialGuards.set(serial, true);
            maps.whitelistClaimedWallets.set(walletKey, true);
            deployNft(
                serial,
                in.senderAddress,
                serialContent(serial),
                assets.nftItemCode,
                config.itemDeploymentValue,
            );
            storage.mintedCount += 1;
            whitelist.claimsUsed += 1;
            whitelist.locked = true;
            while (
                storage.nextItemIndex <= config.maximumSupply &&
                maps.mintedSerialGuards.get(storage.nextItemIndex).isFound
            ) {
                storage.nextItemIndex += 1;
            }
            assets.maps = maps.toCell();
            assets.whitelist = whitelist.toCell();
            storage.assets = assets.toCell();
            storage.save();
        }
        PauseMinting => {
            var storage = lazy NftCollectionStorage.load();
            requireAdmin(in.senderAddress, storage.adminAddress);
            storage.paused = true;
            storage.save();
        }
        UnpauseMinting => {
            var storage = lazy NftCollectionStorage.load();
            requireAdmin(in.senderAddress, storage.adminAddress);
            assert (
                storage.giveawayPremintedCount == storage.config.load().giveawaySupply
            ) throw HopprErrors.GiveawayPremintIncomplete;
            assert (
                storage.treasuryPremintedCount == storage.config.load().treasuryNftSupply
            ) throw HopprErrors.TreasuryPremintIncomplete;
            assert (
                storage.config.load().whitelistMaxClaims == 0 ||
                storage.assets.load().whitelist.load().merkleRoot != 0
            ) throw HopprErrors.WhitelistRootUnset;
            storage.paused = false;
            storage.save();
        }
        RotateSigner => {
            var storage = lazy NftCollectionStorage.load();
            requireAdmin(in.senderAddress, storage.adminAddress);
            assert (msg.newPublicKey != 0) throw HopprErrors.InvalidPublicKey;
            storage.quotePublicKey = msg.newPublicKey;
            storage.signerEpoch += 1;
            storage.save();
        }
        RevealMetadata => {
            var storage = lazy NftCollectionStorage.load();
            requireAdmin(in.senderAddress, storage.adminAddress);
            var reveal = storage.reveal.load();
            assert (reveal.delayedRevealEnabled) throw HopprErrors.RevealDisabled;
            assert (!reveal.metadataFrozen) throw HopprErrors.MetadataFrozen;
            assert (!reveal.metadataRevealed) throw HopprErrors.AlreadyRevealed;
            assert (
                msg.finalBaseUri.hash() == reveal.metadataCommitment
            ) throw HopprErrors.InvalidReveal;
            var content = storage.content.load();
            content.commonContent = msg.finalBaseUri;
            reveal.metadataRevealed = true;
            reveal.metadataFrozen = true;
            storage.content = content.toCell();
            storage.reveal = reveal.toCell();
            storage.save();
        }
        FreezeMetadata => {
            var storage = lazy NftCollectionStorage.load();
            requireAdmin(in.senderAddress, storage.adminAddress);
            var reveal = storage.reveal.load();
            reveal.metadataFrozen = true;
            storage.reveal = reveal.toCell();
            storage.save();
        }
        TransferAdmin => {
            var storage = lazy NftCollectionStorage.load();
            requireAdmin(in.senderAddress, storage.adminAddress);
            assert (
                msg.newAdminAddress.getWorkchain() == BASECHAIN &&
                msg.newAdminAddress != storage.adminAddress
            ) throw HopprErrors.InvalidAdminAddress;
            storage.adminAddress = msg.newAdminAddress;
            storage.save();
        }
        else => {
            assert (in.body.isEmpty()) throw HopprErrors.InvalidMessage;
        }
    }
}

fun onBouncedMessage(_in: InMessageBounced) {}

get fun get_collection_data(): (int, cell, address) {
    val storage = lazy NftCollectionStorage.load();
    return (storage.nextItemIndex, storage.content.load().collectionMetadata, storage.adminAddress);
}

get fun get_nft_address_by_index(index: int): address {
    val storage = lazy NftCollectionStorage.load();
    return calcDeployedNftItem(
        index,
        contract.getAddress(),
        storage.assets.load().nftItemCode,
    ).calculateAddress();
}

get fun get_nft_content(_index: int, individualContent: cell): Cell<OffchainMetadataReply> {
    return joinMetadata(
        NftCollectionStorage.load().content.load().commonContent,
        individualContent as unknown as string,
    );
}

get fun get_treasury_address(): address {
    return NftCollectionStorage.load().config.load().immutableTreasuryAddress;
}

get fun get_admin_address(): address {
    return NftCollectionStorage.load().adminAddress;
}

get fun get_quote_config(): (uint256, int, int32) {
    val storage = lazy NftCollectionStorage.load();
    return (storage.quotePublicKey, storage.signerEpoch, storage.config.load().networkId);
}

get fun is_quote_used(quoteHash: uint256): bool {
    val maps = NftCollectionStorage.load().assets.load().maps.load();
    return maps.usedQuoteHashes.get(quoteHash).isFound;
}

get fun get_minted_count(): int {
    return NftCollectionStorage.load().mintedCount;
}

get fun get_giveaway_preminted_count(): int {
    return NftCollectionStorage.load().giveawayPremintedCount;
}

get fun get_giveaway_supply(): int {
    return NftCollectionStorage.load().config.load().giveawaySupply;
}

get fun get_treasury_preminted_count(): int {
    return NftCollectionStorage.load().treasuryPremintedCount;
}

get fun get_treasury_nft_supply(): int {
    return NftCollectionStorage.load().config.load().treasuryNftSupply;
}

get fun get_reserved_allocation_state(): (int, int, int, int) {
    val storage = lazy NftCollectionStorage.load();
    val config = storage.config.load();
    return (
        config.giveawaySupply,
        storage.giveawayPremintedCount,
        config.treasuryNftSupply,
        storage.treasuryPremintedCount,
    );
}

get fun get_whitelist_config(): (uint256, int, int, bool) {
    val storage = lazy NftCollectionStorage.load();
    val whitelist = storage.assets.load().whitelist.load();
    return (
        whitelist.merkleRoot,
        storage.config.load().whitelistMaxClaims,
        whitelist.claimsUsed,
        whitelist.locked,
    );
}

get fun get_whitelist_claimed(wallet: address): bool {
    val key = beginCell().storeAddress(wallet).endCell().hash();
    return NftCollectionStorage
        .load()
        .assets
        .load()
        .maps
        .load()
        .whitelistClaimedWallets
        .get(key)
        .isFound;
}

get fun get_reveal_status(): (bool, uint256, bool, bool, string) {
    val storage = lazy NftCollectionStorage.load();
    val reveal = storage.reveal.load();
    return (
        reveal.delayedRevealEnabled,
        reveal.metadataCommitment,
        reveal.metadataRevealed,
        reveal.metadataFrozen,
        storage.content.load().commonContent,
    );
}

get fun get_mint_config(): (
    int,
    int,
    coins,
    coins,
    coins,
    coins,
    bool,
) {
    val storage = lazy NftCollectionStorage.load();
    val config = storage.config.load();
    return (
        config.maximumSupply,
        config.maximumSupply,
        config.itemDeploymentValue,
        config.collectionExecutionReserve,
        config.outboundMessageReserve,
        config.minimumStorageReserve,
        storage.paused,
    );
}
