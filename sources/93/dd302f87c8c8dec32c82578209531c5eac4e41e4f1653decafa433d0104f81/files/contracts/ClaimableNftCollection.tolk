import "@stdlib/strings"
import "errors"
import "fees-management"
import "messages"
import "types"

contract ClaimableNftCollection {
    author: "Reza Apes"
    version: "1.0.0"
    description: "Signed entitlement NFT collection implementing TEP-62, TEP-64 and TEP-66"
    storage: ClaimableCollectionStorage
    incomingMessages: AllowedMessageToClaimableCollection
}

type AllowedMessageToClaimableCollection =
    | ClaimMint
    | RequestRoyaltyParams
    | SetMintPrice
    | SetPaused
    | SetTransferFrozen
    | SetTreasury
    | SetVoucherSigner
    | BeginOwnerTransfer
    | AcceptOwnerTransfer
    | CancelOwnerTransfer
    | RequestTransferAuthorization

fun requireOwner(sender: address, owner: address) {
    assert (sender == owner) throw Errors.NotFromOwner;
}

fun requireBasechainAddress(addr: address) {
    assert (addr.getWorkchain() == BASECHAIN) throw Errors.InvalidWorkchain;
}

fun requireValidMaxSupply(maxSupply: uint64) {
    assert (maxSupply > 0 && maxSupply <= MAX_COLLECTION_SUPPLY) throw Errors.MaxSupplyOutOfRange;
}

fun deployNftItem(
    itemIndex: uint64,
    nftItemCode: cell,
    recipient: address,
    individualContent: string,
    serial: uint64,
    nonce: uint256,
) {
    val initParams = NftItemInitAtDeployment {
        ownerAddress: recipient,
        individualContent,
        claimContext: ItemClaimContext {
            serial,
            nonce,
            itemIndex,
            recipientAddress: recipient,
        }.toCell(),
        nextTransferNonce: 0,
        pendingTransfer: null,
    }.toCell();
    val deployMessage = createMessage({
        bounce: BounceMode.RichBounce,
        dest: calcDeployedNftItem(itemIndex, contract.getAddress(), nftItemCode),
        value: NFT_ITEM_DEPLOY_VALUE,
        body: initParams,
    });
    deployMessage.send(SEND_MODE_REGULAR | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
}

fun createIndividualContent(serial: uint64): string {
    var builder = StringBuilder.create();
    builder.appendInt(serial);
    builder.append(".json");
    return builder.build();
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessageToClaimableCollection.fromSlice(in.body);

    match (msg) {
        ClaimMint => {
            var storage = ClaimableCollectionStorage.load();
            val immutableConfig = lazy storage.immutableConfig.load();
            val mutableConfig = lazy storage.mutableConfig.load();
            val voucher = lazy msg.voucher.load();
            val nonce = lazy voucher.nonce.load();
            var claimIndexes = storage.claimIndexes.load();

            val claimedLookup = claimIndexes.claimedSerials.get(voucher.serial);
            val failedLookup = claimIndexes.failedClaims.get(voucher.serial);
            val isRetry = claimedLookup.isFound && failedLookup.isFound;

            // Re-check the immutable StateInit value on every claim. This protects the runtime
            // path even if a malformed StateInit was activated without the normal deploy message.
            requireValidMaxSupply(immutableConfig.maxSupply);
            assert (!mutableConfig.paused) throw Errors.CollectionPaused;
            val requiredPayment = isRetry ? RETRY_CLAIM_PAYMENT : mutableConfig.mintPrice;
            assert (in.valueCoins >= requiredPayment) throw Errors.TooLittleValue;
            assert (mutableConfig.mintPrice >= MIN_CLAIM_PRICE) throw Errors.PriceBelowMinimum;
            assert (
                isRetry || storage.nextItemIndex < immutableConfig.maxSupply
            ) throw Errors.SupplyExhausted;
            assert (voucher.serial > 0) throw Errors.InvalidSerial;
            assert (voucher.serial <= immutableConfig.maxSupply) throw Errors.SerialOutOfRange;

            requireBasechainAddress(voucher.recipientAddress);
            assert (in.senderAddress == voucher.recipientAddress) throw Errors.WrongRecipient;
            assert (
                voucher.collectionAddress == contract.getAddress()
            ) throw Errors.WrongCollection;
            assert (
                voucher.voucherDomain == immutableConfig.voucherDomain
            ) throw Errors.WrongVoucherDomain;
            assert (voucher.expiresAt >= blockchain.now() || isRetry) throw Errors.VoucherExpired;
            assert (
                isRetry ||
                isSignatureValid(
                    msg.voucher.hash(),
                    msg.signature as slice,
                    mutableConfig.voucherSignerPublicKey,
                )
            ) throw Errors.InvalidSignature;

            var itemIndex: uint64;
            if (isRetry) {
                val failed = failedLookup.loadValue();
                assert (
                    failed.itemIndex == claimedLookup.loadValue()
                ) throw Errors.SerialAlreadyClaimed;
                assert (failed.nonce == nonce.value) throw Errors.NonceAlreadyUsed;
                assert (
                    failed.recipientAddress == voucher.recipientAddress
                ) throw Errors.WrongRecipient;
                val nonceLookup = claimIndexes.usedNonces.get(nonce.value);
                assert (
                    nonceLookup.isFound && nonceLookup.loadValue() == voucher.serial
                ) throw Errors.NonceAlreadyUsed;
                itemIndex = failed.itemIndex;
                claimIndexes.failedClaims.delete(voucher.serial);
            } else {
                assert (!claimedLookup.isFound) throw Errors.SerialAlreadyClaimed;
                assert (!claimIndexes.usedNonces.exists(nonce.value)) throw Errors.NonceAlreadyUsed;
                itemIndex = storage.nextItemIndex;
                claimIndexes.claimedSerials.set(voucher.serial, itemIndex);
                claimIndexes.usedNonces.set(nonce.value, voucher.serial);
                storage.nextItemIndex += 1;
            }
            storage.claimIndexes = claimIndexes.toCell();
            storage.save();

            reserveToncoinsOnBalance(
                COLLECTION_STORAGE_RESERVE,
                RESERVE_MODE_EXACT_AMOUNT | RESERVE_MODE_BOUNCE_ON_ACTION_FAIL,
            );

            deployNftItem(
                itemIndex,
                immutableConfig.nftItemCode,
                voucher.recipientAddress,
                createIndividualContent(voucher.serial),
                voucher.serial,
                nonce.value,
            );

            val treasuryProceeds = isRetry
                ? (0 as coins)
                : mutableConfig.mintPrice - NFT_ITEM_DEPLOY_VALUE - CLAIM_PROCESSING_BUFFER;
            if (!isRetry && treasuryProceeds > 0) {
                val treasuryMessage = createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: mutableConfig.treasuryAddress,
                    value: treasuryProceeds,
                });
                treasuryMessage.send(SEND_MODE_REGULAR);
            }

            val overpayment = in.valueCoins - requiredPayment;
            if (overpayment > 0) {
                val refundMessage = createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: in.senderAddress,
                    value: overpayment,
                    body: ReturnExcessesBack { queryId: msg.queryId },
                });
                refundMessage.send(SEND_MODE_REGULAR);
            }
        }

        RequestRoyaltyParams => {
            val storage = lazy ClaimableCollectionStorage.load();
            val immutableConfig = lazy storage.immutableConfig.load();
            val response = createMessage({
                bounce: BounceMode.NoBounce,
                dest: in.senderAddress,
                value: 0,
                body: ResponseRoyaltyParams {
                    queryId: msg.queryId,
                    royaltyParams: {
                        numerator: 5,
                        denominator: 100,
                        royaltyAddress: immutableConfig.royaltyAddress,
                    },
                },
            });
            response.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        SetMintPrice => {
            var storage = ClaimableCollectionStorage.load();
            requireOwner(in.senderAddress, storage.ownerAddress);
            assert (msg.mintPrice >= MIN_CLAIM_PRICE) throw Errors.PriceBelowMinimum;
            var mutableConfig = storage.mutableConfig.load();
            mutableConfig.mintPrice = msg.mintPrice;
            storage.mutableConfig = mutableConfig.toCell();
            storage.save();
        }

        SetPaused => {
            var storage = ClaimableCollectionStorage.load();
            requireOwner(in.senderAddress, storage.ownerAddress);
            var mutableConfig = storage.mutableConfig.load();
            mutableConfig.paused = msg.paused;
            storage.mutableConfig = mutableConfig.toCell();
            storage.save();
        }

        SetTransferFrozen => {
            var storage = ClaimableCollectionStorage.load();
            requireOwner(in.senderAddress, storage.ownerAddress);
            var mutableConfig = storage.mutableConfig.load();
            mutableConfig.transferFrozen = msg.transferFrozen;
            storage.mutableConfig = mutableConfig.toCell();
            storage.save();
        }

        SetTreasury => {
            var storage = ClaimableCollectionStorage.load();
            requireOwner(in.senderAddress, storage.ownerAddress);
            requireBasechainAddress(msg.treasuryAddress);
            var mutableConfig = storage.mutableConfig.load();
            mutableConfig.treasuryAddress = msg.treasuryAddress;
            storage.mutableConfig = mutableConfig.toCell();
            storage.save();
        }

        SetVoucherSigner => {
            var storage = ClaimableCollectionStorage.load();
            requireOwner(in.senderAddress, storage.ownerAddress);
            var mutableConfig = storage.mutableConfig.load();
            mutableConfig.voucherSignerPublicKey = msg.signerPublicKey;
            storage.mutableConfig = mutableConfig.toCell();
            storage.save();
        }

        BeginOwnerTransfer => {
            var storage = ClaimableCollectionStorage.load();
            requireOwner(in.senderAddress, storage.ownerAddress);
            requireBasechainAddress(msg.pendingOwnerAddress);
            var mutableConfig = storage.mutableConfig.load();
            mutableConfig.pendingOwnerAddress = msg.pendingOwnerAddress;
            storage.mutableConfig = mutableConfig.toCell();
            storage.save();
        }

        AcceptOwnerTransfer => {
            var storage = ClaimableCollectionStorage.load();
            var mutableConfig = storage.mutableConfig.load();
            assert (mutableConfig.pendingOwnerAddress != null) throw Errors.PendingOwnerNotSet;
            assert (
                in.senderAddress == mutableConfig.pendingOwnerAddress
            ) throw Errors.NotFromPendingOwner;
            storage.ownerAddress = in.senderAddress;
            mutableConfig.pendingOwnerAddress = null;
            storage.mutableConfig = mutableConfig.toCell();
            storage.save();
        }

        CancelOwnerTransfer => {
            var storage = ClaimableCollectionStorage.load();
            requireOwner(in.senderAddress, storage.ownerAddress);
            var mutableConfig = storage.mutableConfig.load();
            mutableConfig.pendingOwnerAddress = null;
            storage.mutableConfig = mutableConfig.toCell();
            storage.save();
        }

        RequestTransferAuthorization => {
            val storage = lazy ClaimableCollectionStorage.load();
            val immutableConfig = lazy storage.immutableConfig.load();
            val mutableConfig = lazy storage.mutableConfig.load();

            // Only this collection's deterministic, immutable item bytecode may
            // query policy. An arbitrary contract cannot use the collection as
            // an authorization oracle or forge a response for a real item.
            val expectedItemAddress = calcDeployedNftItem(
                msg.itemIndex,
                contract.getAddress(),
                immutableConfig.nftItemCode,
            ).calculateAddress();
            assert (in.senderAddress == expectedItemAddress) throw Errors.WrongCollection;
            assert (msg.itemIndex < storage.nextItemIndex) throw Errors.WrongCollection;
            requireBasechainAddress(msg.currentOwnerAddress);
            requireBasechainAddress(msg.newOwnerAddress);

            var allowed = true;
            if (mutableConfig.transferFrozen) {
                val expectedVaultAddress = calcPersonalVault(
                    msg.currentOwnerAddress,
                    immutableConfig.personalVaultCode,
                ).calculateAddress();
                allowed = msg.newOwnerAddress == expectedVaultAddress;
            }

            assert (in.valueCoins > TRANSFER_POLICY_PROCESSING_BUFFER) throw Errors.TooLittleValue;
            val response = createMessage({
                bounce: BounceMode.RichBounce,
                dest: in.senderAddress,
                value: in.valueCoins - TRANSFER_POLICY_PROCESSING_BUFFER,
                body: TransferAuthorization {
                    authorizationNonce: msg.authorizationNonce,
                    allowed,
                },
            });
            response.send(SEND_MODE_REGULAR | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
        }

        else => {
            assert (in.body.isEmpty()) throw 0xFFFF;
            // The generated deployment wrapper sends an empty body. Reject invalid immutable
            // capacity before the StateInit can be considered a usable collection.
            val storage = ClaimableCollectionStorage.load();
            val immutableConfig = storage.immutableConfig.load();
            requireValidMaxSupply(immutableConfig.maxSupply);
            assert (
                storage.nextItemIndex <= immutableConfig.maxSupply
            ) throw Errors.MaxSupplyOutOfRange;
        }
    }
}

fun onBouncedMessage(in: InMessageBounced) {
    val richBounce = lazy RichBounceBody.fromSlice(in.bouncedBody);
    val bouncedBody = richBounce.originalBody.beginParse();
    val (bouncedBits, bouncedRefs) = bouncedBody.remainingBitsAndRefsCount();
    if (bouncedBits == 97 && bouncedRefs == 0 && bouncedBody.preloadUint(32) == 0x54524152) {
        // A policy response can bounce only from the deterministic item it was
        // addressed to. It carries no collection state transition and the item
        // kept its pending transfer, so safely ignore it rather than attempting
        // to decode it as a bounced item-initialization body.
        return;
    }
    val initParams = lazy NftItemInitAtDeployment.fromCell(richBounce.originalBody);
    val context = lazy initParams.claimContext.load();

    var storage = ClaimableCollectionStorage.load();
    val immutableConfig = storage.immutableConfig.load();
    val expectedItem = calcDeployedNftItem(
        context.itemIndex,
        contract.getAddress(),
        immutableConfig.nftItemCode,
    ).calculateAddress();
    assert (in.senderAddress == expectedItem) throw Errors.WrongCollection;

    var claimIndexes = storage.claimIndexes.load();
    val serialLookup = claimIndexes.claimedSerials.get(context.serial);
    val nonceLookup = claimIndexes.usedNonces.get(context.nonce);
    assert (
        serialLookup.isFound && serialLookup.loadValue() == context.itemIndex
    ) throw Errors.SerialAlreadyClaimed;
    assert (
        nonceLookup.isFound && nonceLookup.loadValue() == context.serial
    ) throw Errors.NonceAlreadyUsed;
    claimIndexes
        .failedClaims
        .set(
            context.serial,
            {
                itemIndex: context.itemIndex,
                nonce: context.nonce,
                recipientAddress: context.recipientAddress,
            },
        );
    storage.claimIndexes = claimIndexes.toCell();
    storage.save();
}

get fun get_collection_data(): CollectionDataReply {
    val storage = lazy ClaimableCollectionStorage.load();
    val immutableConfig = lazy storage.immutableConfig.load();
    return {
        nextItemIndex: storage.nextItemIndex,
        collectionMetadata: immutableConfig.collectionMetadata,
        ownerAddress: storage.ownerAddress,
    };
}

get fun get_nft_address_by_index(itemIndex: int): address {
    val storage = lazy ClaimableCollectionStorage.load();
    val immutableConfig = lazy storage.immutableConfig.load();
    return calcDeployedNftItem(
        itemIndex as uint64,
        contract.getAddress(),
        immutableConfig.nftItemCode,
    ).calculateAddress();
}

get fun get_nft_content(
    _itemIndex: int,
    individualNftContent: string,
): Cell<OffchainMetadataReply> {
    val storage = lazy ClaimableCollectionStorage.load();
    val immutableConfig = lazy storage.immutableConfig.load();
    var builder = StringBuilder.create();
    builder.append(immutableConfig.commonContent);
    builder.append(individualNftContent);
    return OffchainMetadataReply { string: builder.build() }.toCell();
}

get fun royalty_params(): RoyaltyParams {
    val storage = lazy ClaimableCollectionStorage.load();
    val immutableConfig = lazy storage.immutableConfig.load();
    return {
        numerator: 5,
        denominator: 100,
        royaltyAddress: immutableConfig.royaltyAddress,
    };
}

get fun get_claim_config(): ClaimConfigReply {
    val storage = lazy ClaimableCollectionStorage.load();
    val immutableConfig = lazy storage.immutableConfig.load();
    val mutableConfig = lazy storage.mutableConfig.load();
    return {
        ownerAddress: storage.ownerAddress,
        pendingOwnerAddress: mutableConfig.pendingOwnerAddress,
        nextItemIndex: storage.nextItemIndex,
        maxSupply: immutableConfig.maxSupply,
        mintPrice: mutableConfig.mintPrice,
        minimumMintPrice: MIN_CLAIM_PRICE,
        paused: mutableConfig.paused,
        transferFrozen: mutableConfig.transferFrozen,
        treasuryAddress: mutableConfig.treasuryAddress,
        voucherSignerPublicKey: mutableConfig.voucherSignerPublicKey,
        voucherDomain: immutableConfig.voucherDomain,
        royaltyAddress: immutableConfig.royaltyAddress,
    };
}

get fun get_claimed_item_index(serial: uint64): ClaimLookupReply {
    val storage = ClaimableCollectionStorage.load();
    val claimIndexes = storage.claimIndexes.load();
    val lookup = claimIndexes.claimedSerials.get(serial);
    if (!lookup.isFound) {
        return { claimed: false, itemIndex: 0 };
    }
    return { claimed: true, itemIndex: lookup.loadValue() };
}

get fun is_nonce_used(nonce: uint256): bool {
    val storage = ClaimableCollectionStorage.load();
    val claimIndexes = storage.claimIndexes.load();
    return claimIndexes.usedNonces.exists(nonce);
}

get fun is_claim_retryable(serial: uint64): bool {
    val storage = ClaimableCollectionStorage.load();
    val claimIndexes = storage.claimIndexes.load();
    return claimIndexes.failedClaims.exists(serial);
}

/// Compile-time on-chain ceiling used by deployment tooling and verification.
get fun get_max_collection_supply(): uint64 {
    return MAX_COLLECTION_SUPPLY as uint64;
}
