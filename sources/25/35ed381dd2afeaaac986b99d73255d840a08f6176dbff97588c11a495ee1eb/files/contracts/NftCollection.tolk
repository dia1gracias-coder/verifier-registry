import "@stdlib/strings"
import "errors"
import "fees-management"
import "messages"
import "name-utils"
import "types"

contract NftCollection {
    author: "@Games Names"
    version: "1.5.0"
    description: "Permanent @games player names with one included deterministic pattern"
    incomingMessages: AllowedMessageToNftCollection
    storage: NftCollectionStorage
}

type AllowedMessageToNftCollection =
    | MintAcknowledged
    | MintReservedName
    | MintPublicName
    | RetryFinalizeMint
    | ClaimFailedMintRefund
    | ProposeConfigUpdate
    | ExecuteConfigUpdate
    | CancelConfigUpdate
    | SetMintPaused
    | ProposeCollectionAdmin
    | AcceptCollectionAdmin
    | CancelCollectionAdmin
    | LoadInitialCatalogEntry
    | FinalizeInitialCatalog
    | RequestRoyaltyParams

type AllowedBouncedMessage = InitializeNameNft | RequestMintAcknowledgement

const ITEM_METADATA_DESCRIPTION = "Permanent player name in the @games ecosystem, owned as a transferable TON NFT with no renewals."
const ITEM_RENDERER_ARCHIVE = "ipfs://bafybeiegiz6bazo2bzocasqfawmd757ca6vtg45tshjjrqhokrkydvmwcm"

fun getMintState(registry: RegistryStorage, nameHash: uint256): int {
    if (registry.activeNames.exists(nameHash)) {
        return MINT_STATE_ACTIVE;
    }
    if (registry.pendingMints.exists(nameHash)) {
        return MINT_STATE_PENDING;
    }
    return MINT_STATE_UNMINTED;
}

fun RegistryStorage.allocateItemIndex(mutate self): uint256 {
    var recycled = self.recycled.load();
    if (recycled.head < recycled.tail) {
        val lookup = recycled.indexes.get(recycled.head);
        assert (lookup.isFound) throw Errors.InvalidPendingMintState;
        val itemIndex = lookup.loadValue();
        recycled.indexes.delete(recycled.head);
        recycled.head += 1;
        self.recycled = recycled.toCell();
        return itemIndex;
    }
    val itemIndex = self.nextItemIndex;
    self.nextItemIndex += 1;
    return itemIndex;
}

fun RegistryStorage.recycleItemIndex(mutate self, itemIndex: uint256) {
    var recycled = self.recycled.load();
    recycled.indexes.set(recycled.tail, itemIndex);
    recycled.tail += 1;
    self.recycled = recycled.toCell();
}

fun RegistryStorage.peekNextItemIndex(self): uint256 {
    val recycled = self.recycled.load();
    if (recycled.head < recycled.tail) {
        val lookup = recycled.indexes.get(recycled.head);
        assert (lookup.isFound) throw Errors.InvalidPendingMintState;
        return lookup.loadValue();
    }
    return self.nextItemIndex;
}

fun resolveItemIndex(registry: RegistryStorage, nameHash: uint256): uint256 {
    val activeLookup = registry.activeNames.get(nameHash);
    if (activeLookup.isFound) {
        return activeLookup.loadValue();
    }
    val pendingLookup = registry.pendingMints.get(nameHash);
    if (pendingLookup.isFound) {
        return pendingLookup.loadValue().itemIndex;
    }
    return registry.peekNextItemIndex();
}

fun resolveCategoryAndPrice(
    pricing: PricingStorage,
    nameHash: uint256,
    length: int,
): (int, coins) {
    val lookup = pricing.catalog.get(nameHash);
    if (!lookup.isFound) {
        return (NAME_STATUS_PUBLIC, pricing.prices.load().priceForLength(length));
    }
    val entry = lookup.loadValue();
    if (entry.status == NAME_STATUS_VIP) {
        return (NAME_STATUS_VIP, entry.price);
    }
    return (entry.status, 0);
}

fun deployNameItem(
    itemIndex: uint256,
    nftItemCode: cell,
    attachTonAmount: coins,
    initParams: InitializeNameNft,
) {
    val deployMsg = createMessage({
        bounce: BounceMode.RichBounce,
        dest: calcDeployedNftItem(itemIndex, contract.getAddress(), nftItemCode),
        value: attachTonAmount,
        body: initParams,
    });
    deployMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun buildIndividualContent(name: string): Cell<SnakeString> {
    // The item keeps the canonical name itself. The collection getter turns it
    // into TEP-64 semi-chain metadata whose identity fields remain on-chain.
    return stringToSnakeCell(name);
}

fun validateCatalogEntry(
    name: string,
    status: int,
    price: coins,
    reservedFor: address?,
    pricing: PricingStorage,
): uint256 {
    val length = validateCanonicalName(name);
    assert (
        status == NAME_STATUS_PUBLIC || status == NAME_STATUS_VIP ||
        status == NAME_STATUS_RESERVED ||
        status == NAME_STATUS_BLOCKED
    ) throw Errors.InvalidCatalogStatus;
    if (status == NAME_STATUS_VIP) {
        val basePrice = pricing.prices.load().priceForLength(length);
        assert (price >= basePrice) throw Errors.VipPriceTooLow;
    }
    if (reservedFor != null) {
        assert (status == NAME_STATUS_RESERVED) throw Errors.InvalidRecipient;
        assert (reservedFor.getWorkchain() == BASECHAIN) throw Errors.InvalidRecipient;
    }
    return canonicalNameHash(name);
}

fun validateCatalogAction(
    action: UpdateCatalogEntryAction,
    pricing: PricingStorage,
): uint256 {
    return validateCatalogEntry(
        action.name,
        action.status,
        action.price,
        action.reservedFor,
        pricing,
    );
}

fun mintPublicName(
    payerAddress: address,
    paymentValue: coins,
    queryId: uint64,
    pricingVersion: uint32,
    maxPrice: coins,
    recipientAddress: address,
    name: string,
) {
    var storage = NftCollectionStorage.load();
    assert (!storage.paused) throw Errors.MintPaused;
    assert (recipientAddress.getWorkchain() == BASECHAIN) throw Errors.InvalidRecipient;

    val length = validateCanonicalName(name);
    val nameHash = canonicalNameHash(name);
    val pricing = storage.pricing.load();
    assert (pricingVersion == pricing.pricingVersion) throw Errors.PriceVersionChanged;

    val (category, price) = resolveCategoryAndPrice(pricing, nameHash, length);
    assert (category != NAME_STATUS_RESERVED) throw Errors.NameReserved;
    assert (category != NAME_STATUS_BLOCKED) throw Errors.NameBlocked;
    assert (price <= maxPrice) throw Errors.PriceAboveMaximum;

    var registry = storage.registry.load();
    assert (getMintState(registry, nameHash) == MINT_STATE_UNMINTED) throw Errors.NameAlreadyMinted;

    val requiredValue = price + pricing.itemDeployValue + MINT_GAS_BUDGET + DIRECT_MINT_GAS_BUDGET;
    assert (paymentValue >= requiredValue) throw Errors.InsufficientMintValue;

    val itemIndex = registry.allocateItemIndex();

    registry
        .pendingMints
        .set(
            nameHash,
            {
                itemIndex,
                payerAddress,
                queryId,
                price,
                refundAmount: paymentValue - requiredValue,
                state: PENDING_MINT_DEPLOYING as uint1,
            },
        );
    storage.registry = registry.toCell();
    storage.save();

    deployNameItem(
        itemIndex,
        storage.nftItemCode,
        pricing.itemDeployValue,
        {
            queryId,
            nameHash,
            ownerAddress: recipientAddress,
            category: category as uint2,
            mintPrice: price,
            mintedAt: blockchain.now() as uint64,
            name,
            content: buildIndividualContent(name),
        },
    );
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessageToNftCollection.fromSlice(in.body);

    match (msg) {
        MintPublicName => {
            mintPublicName(
                in.senderAddress,
                in.valueCoins,
                msg.queryId,
                msg.pricingVersion,
                msg.maxPrice,
                msg.recipientAddress,
                msg.name,
            );
        }

        RetryFinalizeMint => {
            assert (in.valueCoins >= RETRY_FINALIZE_VALUE) throw Errors.InsufficientRetryValue;
            validateCanonicalName(msg.name);
            val nameHash = canonicalNameHash(msg.name);
            val storage = NftCollectionStorage.load();
            val registry = storage.registry.load();
            val pendingLookup = registry.pendingMints.get(nameHash);
            assert (pendingLookup.isFound) throw Errors.PendingMintNotFound;
            val pending = pendingLookup.loadValue();
            assert (pending.state == PENDING_MINT_DEPLOYING) throw Errors.InvalidPendingMintState;
            val expectedItem = calcDeployedNftItem(
                pending.itemIndex,
                contract.getAddress(),
                storage.nftItemCode,
            ).calculateAddress();
            val retryMsg = createMessage({
                bounce: BounceMode.RichBounce,
                dest: expectedItem,
                value: RETRY_ITEM_REQUEST_VALUE,
                body: RequestMintAcknowledgement {
                    queryId: pending.queryId,
                    nameHash,
                    retryCaller: in.senderAddress,
                },
            });
            retryMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
        }

        ClaimFailedMintRefund => {
            assert (
                in.valueCoins >= CLAIM_FAILED_MINT_REFUND_VALUE
            ) throw Errors.InsufficientRetryValue;
            validateCanonicalName(msg.name);
            val nameHash = canonicalNameHash(msg.name);
            var storage = NftCollectionStorage.load();
            var registry = storage.registry.load();
            val pendingLookup = registry.pendingMints.get(nameHash);
            assert (pendingLookup.isFound) throw Errors.PendingMintNotFound;
            val pending = pendingLookup.loadValue();
            assert (pending.state == PENDING_MINT_REFUND_DUE) throw Errors.RefundNotReady;
            assert (pending.refundAmount > 0) throw Errors.RefundNotReady;

            registry.pendingMints.delete(nameHash);
            storage.registry = registry.toCell();
            storage.save();

            val refundMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: pending.payerAddress,
                value: pending.refundAmount,
                body: ReturnExcessesBack { queryId: msg.queryId },
            });
            refundMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
        }

        MintReservedName => {
            var storage = NftCollectionStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw Errors.NotFromAdmin;
            assert (!storage.paused) throw Errors.MintPaused;
            assert (msg.recipientAddress.getWorkchain() == BASECHAIN) throw Errors.InvalidRecipient;

            validateCanonicalName(msg.name);
            val nameHash = canonicalNameHash(msg.name);
            val pricing = storage.pricing.load();
            val catalogLookup = pricing.catalog.get(nameHash);
            assert (catalogLookup.isFound) throw Errors.NameReserved;
            val catalogEntry = catalogLookup.loadValue();
            assert (catalogEntry.status == NAME_STATUS_RESERVED) throw Errors.NameReserved;
            if (catalogEntry.reservedFor != null) {
                assert (
                    catalogEntry.reservedFor == msg.recipientAddress
                ) throw Errors.ReservedForOtherAddress;
            }

            var registry = storage.registry.load();
            assert (
                getMintState(registry, nameHash) == MINT_STATE_UNMINTED
            ) throw Errors.NameAlreadyMinted;

            val requiredValue = pricing.itemDeployValue + MINT_GAS_BUDGET;
            assert (in.valueCoins >= requiredValue) throw Errors.InsufficientMintValue;
            val itemIndex = registry.allocateItemIndex();
            registry
                .pendingMints
                .set(
                    nameHash,
                    {
                        itemIndex,
                        payerAddress: in.senderAddress,
                        queryId: msg.queryId,
                        price: 0,
                        refundAmount: in.valueCoins - requiredValue,
                        state: PENDING_MINT_DEPLOYING as uint1,
                    },
                );
            storage.registry = registry.toCell();
            storage.save();

            deployNameItem(
                itemIndex,
                storage.nftItemCode,
                pricing.itemDeployValue,
                {
                    queryId: msg.queryId,
                    nameHash,
                    ownerAddress: msg.recipientAddress,
                    category: NAME_STATUS_RESERVED as uint2,
                    mintPrice: 0,
                    mintedAt: blockchain.now() as uint64,
                    name: msg.name,
                    content: buildIndividualContent(msg.name),
                },
            );
        }

        MintAcknowledged => {
            var storage = NftCollectionStorage.load();
            var registry = storage.registry.load();
            val pendingLookup = registry.pendingMints.get(msg.nameHash);
            assert (pendingLookup.isFound) throw Errors.PendingMintNotFound;
            val pending = pendingLookup.loadValue();
            assert (pending.state == PENDING_MINT_DEPLOYING) throw Errors.InvalidPendingMintState;
            assert (pending.queryId == msg.queryId) throw Errors.InvalidMintAcknowledgement;

            val expectedItem = calcDeployedNftItem(
                pending.itemIndex,
                contract.getAddress(),
                storage.nftItemCode,
            ).calculateAddress();
            assert (in.senderAddress == expectedItem) throw Errors.InvalidMintAcknowledgement;

            registry.pendingMints.delete(msg.nameHash);
            registry.activeNames.set(msg.nameHash, pending.itemIndex);
            storage.registry = registry.toCell();
            storage.save();

            if (pending.price > 0) {
                val pricing = storage.pricing.load();
                val treasuryMsg = createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: pricing.treasuryAddress,
                    value: pending.price,
                    body: MintProceeds {
                        queryId: msg.queryId,
                        nameHash: msg.nameHash,
                    },
                });
                treasuryMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
            }

            if (pending.refundAmount > 0) {
                val refundMsg = createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: pending.payerAddress,
                    value: pending.refundAmount,
                    body: ReturnExcessesBack { queryId: msg.queryId },
                });
                refundMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
            }
        }

        LoadInitialCatalogEntry => {
            var storage = NftCollectionStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw Errors.NotFromAdmin;
            assert (storage.paused) throw Errors.CatalogInitializationRequiresPause;

            var pricing = storage.pricing.load();
            var initialization = pricing.catalogInitialization.load();
            assert (!initialization.finalized) throw Errors.CatalogInitializationFinalized;
            assert (
                msg.index == initialization.loadedCount
            ) throw Errors.CatalogInitializationIndexMismatch;
            assert (
                initialization.loadedCount < initialization.expectedCount
            ) throw Errors.CatalogInitializationCountMismatch;
            assert (msg.status != NAME_STATUS_PUBLIC) throw Errors.InvalidCatalogStatus;
            if (msg.status == NAME_STATUS_RESERVED) {
                assert (msg.reservedFor != null) throw Errors.InvalidRecipient;
            }

            val nameHash = validateCatalogEntry(
                msg.name,
                msg.status,
                msg.price,
                msg.reservedFor,
                pricing,
            );
            assert (!pricing.catalog.exists(nameHash)) throw Errors.CatalogEntryAlreadyExists;

            val registry = storage.registry.load();
            assert (
                getMintState(registry, nameHash) == MINT_STATE_UNMINTED
            ) throw Errors.NameAlreadyMinted;

            pricing
                .catalog
                .set(
                    nameHash,
                    {
                        status: msg.status,
                        price: msg.price,
                        reservedFor: msg.reservedFor,
                    },
                );
            initialization.rollingHash = nextInitialCatalogHash(
                initialization.rollingHash,
                msg.index,
                nameHash,
                msg.status,
                msg.price,
                msg.reservedFor,
            );
            initialization.loadedCount += 1;
            pricing.catalogInitialization = initialization.toCell();
            storage.pricing = pricing.toCell();
            storage.save();
        }

        FinalizeInitialCatalog => {
            var storage = NftCollectionStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw Errors.NotFromAdmin;
            assert (storage.paused) throw Errors.CatalogInitializationRequiresPause;

            var pricing = storage.pricing.load();
            var initialization = pricing.catalogInitialization.load();
            assert (!initialization.finalized) throw Errors.CatalogInitializationFinalized;
            assert (
                initialization.loadedCount == initialization.expectedCount
            ) throw Errors.CatalogInitializationCountMismatch;
            assert (
                initialization.rollingHash == initialization.expectedHash
            ) throw Errors.CatalogInitializationHashMismatch;

            initialization.finalized = true;
            pricing.catalogInitialization = initialization.toCell();
            pricing.pricingVersion += 1;
            storage.pricing = pricing.toCell();
            storage.save();
        }

        ProposeConfigUpdate => {
            var storage = NftCollectionStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw Errors.NotFromAdmin;
            assert (
                storage.pricing.load().catalogInitialization.load().finalized
            ) throw Errors.CatalogInitializationNotFinalized;

            // Parse once at proposal time so malformed or unknown actions cannot occupy storage.
            val action = lazy AllowedTimelockAction.fromCell(msg.action);
            match (action) {
                UpdateCatalogEntryAction => {
                    validateCatalogAction(action, storage.pricing.load());
                }
                UpdateBasePricesAction => {
                    action.prices.load().assertValid();
                }
                UpdateTreasuryAction => {
                    assert (
                        action.treasuryAddress.getWorkchain() == BASECHAIN
                    ) throw Errors.InvalidRecipient;
                }
                UpdateItemDeployValueAction => {
                    assert (
                        action.itemDeployValue >= MIN_ITEM_DEPLOY_VALUE &&
                        action.itemDeployValue <= MAX_ITEM_DEPLOY_VALUE
                    ) throw Errors.InvalidItemDeployValue;
                }
                UpdateRoyaltyAction => {
                    val royalty = action.royaltyParams.load();
                    assert (
                        royalty.denominator > 0 && royalty.numerator < royalty.denominator
                    ) throw Errors.InvalidTimelockAction;
                    assert (
                        royalty.royaltyAddress.getWorkchain() == BASECHAIN
                    ) throw Errors.InvalidRecipient;
                }
                else => throw Errors.InvalidTimelockAction,
            }

            var registry = storage.registry.load();
            val proposalId = calculateProposalId(
                storage.adminAddress,
                registry.governanceEpoch,
                msg.queryId,
                msg.action,
            );
            assert (!registry.proposals.exists(proposalId)) throw Errors.ProposalAlreadyExists;
            val executeAfter = (blockchain.now() + CONFIG_TIMELOCK_DELAY) as uint64;
            registry
                .proposals
                .set(
                    proposalId,
                    {
                        governanceEpoch: registry.governanceEpoch,
                        executeAfter,
                        expiresAt: (executeAfter + CONFIG_PROPOSAL_EXECUTION_WINDOW) as uint64,
                        action: msg.action,
                    },
                );
            storage.registry = registry.toCell();
            storage.save();
        }

        ExecuteConfigUpdate => {
            var storage = NftCollectionStorage.load();
            var registry = storage.registry.load();
            val lookup = registry.proposals.get(msg.proposalId);
            assert (lookup.isFound) throw Errors.ProposalNotFound;
            val proposal = lookup.loadValue();
            assert (
                proposal.governanceEpoch == registry.governanceEpoch
            ) throw Errors.StaleGovernanceProposal;
            assert (blockchain.now() >= proposal.executeAfter) throw Errors.TimelockNotReady;
            assert (blockchain.now() <= proposal.expiresAt) throw Errors.ProposalExpired;

            val action = lazy AllowedTimelockAction.fromCell(proposal.action);
            match (action) {
                UpdateCatalogEntryAction => {
                    var pricing = storage.pricing.load();
                    val nameHash = validateCatalogAction(action, pricing);
                    assert (
                        getMintState(registry, nameHash) == MINT_STATE_UNMINTED
                    ) throw Errors.NameAlreadyMinted;

                    if (action.status == NAME_STATUS_PUBLIC) {
                        pricing.catalog.delete(nameHash);
                    } else {
                        pricing
                            .catalog
                            .set(
                                nameHash,
                                {
                                    status: action.status,
                                    price: action.price,
                                    reservedFor: action.reservedFor,
                                },
                            );
                    }
                    pricing.pricingVersion += 1;
                    storage.pricing = pricing.toCell();
                }
                UpdateBasePricesAction => {
                    val prices = action.prices.load();
                    prices.assertValid();
                    var pricing = storage.pricing.load();
                    pricing.prices = action.prices;
                    pricing.pricingVersion += 1;
                    storage.pricing = pricing.toCell();
                }
                UpdateTreasuryAction => {
                    assert (
                        action.treasuryAddress.getWorkchain() == BASECHAIN
                    ) throw Errors.InvalidRecipient;
                    var pricing = storage.pricing.load();
                    pricing.treasuryAddress = action.treasuryAddress;
                    storage.pricing = pricing.toCell();
                }
                UpdateItemDeployValueAction => {
                    assert (
                        action.itemDeployValue >= MIN_ITEM_DEPLOY_VALUE &&
                        action.itemDeployValue <= MAX_ITEM_DEPLOY_VALUE
                    ) throw Errors.InvalidItemDeployValue;
                    var pricing = storage.pricing.load();
                    pricing.itemDeployValue = action.itemDeployValue;
                    pricing.pricingVersion += 1;
                    storage.pricing = pricing.toCell();
                }
                UpdateRoyaltyAction => {
                    val royalty = action.royaltyParams.load();
                    assert (
                        royalty.denominator > 0 && royalty.numerator < royalty.denominator
                    ) throw Errors.InvalidTimelockAction;
                    var details = storage.details.load();
                    details.royaltyParams = action.royaltyParams;
                    storage.details = details.toCell();
                }
                else => throw Errors.InvalidTimelockAction,
            }

            registry.proposals.delete(msg.proposalId);
            storage.registry = registry.toCell();
            storage.save();
        }

        CancelConfigUpdate => {
            var storage = NftCollectionStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw Errors.NotFromAdmin;
            var registry = storage.registry.load();
            assert (registry.proposals.exists(msg.proposalId)) throw Errors.ProposalNotFound;
            registry.proposals.delete(msg.proposalId);
            storage.registry = registry.toCell();
            storage.save();
        }

        SetMintPaused => {
            var storage = NftCollectionStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw Errors.NotFromAdmin;
            if (!msg.paused) {
                assert (
                    storage.pricing.load().catalogInitialization.load().finalized
                ) throw Errors.CatalogInitializationNotFinalized;
            }
            storage.paused = msg.paused;
            storage.save();
        }

        ProposeCollectionAdmin => {
            var storage = NftCollectionStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw Errors.NotFromAdmin;
            assert (msg.newAdminAddress.getWorkchain() == BASECHAIN) throw Errors.InvalidRecipient;
            var registry = storage.registry.load();
            registry.pendingAdmin = {
                newAdminAddress: msg.newAdminAddress,
                executeAfter: (blockchain.now() + CONFIG_TIMELOCK_DELAY) as uint64,
                expiresAt: (blockchain.now() + CONFIG_TIMELOCK_DELAY +
                CONFIG_PROPOSAL_EXECUTION_WINDOW) as uint64,
            };
            storage.registry = registry.toCell();
            storage.save();
        }

        AcceptCollectionAdmin => {
            var storage = NftCollectionStorage.load();
            var registry = storage.registry.load();
            val pending = registry.pendingAdmin;
            assert (pending != null) throw Errors.PendingAdminNotFound;
            assert (in.senderAddress == pending.newAdminAddress) throw Errors.NotFromAdmin;
            assert (blockchain.now() >= pending.executeAfter) throw Errors.AdminTransferNotReady;
            assert (blockchain.now() <= pending.expiresAt) throw Errors.ProposalExpired;

            storage.adminAddress = pending.newAdminAddress;
            registry.governanceEpoch += 1;
            registry.pendingAdmin = null;
            storage.registry = registry.toCell();
            storage.save();
        }

        CancelCollectionAdmin => {
            var storage = NftCollectionStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw Errors.NotFromAdmin;
            var registry = storage.registry.load();
            assert (registry.pendingAdmin != null) throw Errors.PendingAdminNotFound;
            registry.pendingAdmin = null;
            storage.registry = registry.toCell();
            storage.save();
        }

        RequestRoyaltyParams => {
            val storage = NftCollectionStorage.load();
            val details = storage.details.load();
            val respondMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: in.senderAddress,
                value: 0,
                body: ResponseRoyaltyParams {
                    queryId: msg.queryId,
                    royaltyParams: details.royaltyParams.load(),
                },
            });
            respondMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        else => {
            assert (in.body.isEmpty()) throw 0xFFFF;
        }
    }
}

fun onBouncedMessage(in: InMessageBounced) {
    val rich = RichBounceBody.fromSlice(in.bouncedBody);
    val bounced = lazy AllowedBouncedMessage.fromCell(rich.originalBody);
    match (bounced) {
        InitializeNameNft => {
            var storage = NftCollectionStorage.load();
            var registry = storage.registry.load();
            val pendingLookup = registry.pendingMints.get(bounced.nameHash);
            assert (pendingLookup.isFound) throw Errors.PendingMintNotFound;
            val pending = pendingLookup.loadValue();
            assert (pending.queryId == bounced.queryId) throw Errors.InvalidMintAcknowledgement;
            assert (pending.state == PENDING_MINT_DEPLOYING) throw Errors.InvalidPendingMintState;
            val expectedItem = calcDeployedNftItem(
                pending.itemIndex,
                contract.getAddress(),
                storage.nftItemCode,
            ).calculateAddress();
            assert (in.senderAddress == expectedItem) throw Errors.InvalidMintAcknowledgement;

            registry.recycleItemIndex(pending.itemIndex);
            val refundValue = pending.price + pending.refundAmount + in.valueCoins;
            var failed = pending;
            failed.price = 0;
            failed.refundAmount = refundValue;
            failed.state = PENDING_MINT_REFUND_DUE as uint1;
            registry.pendingMints.set(bounced.nameHash, failed);
            storage.registry = registry.toCell();
            storage.save();
        }
        RequestMintAcknowledgement => {
            val storage = NftCollectionStorage.load();
            val pendingLookup = storage.registry.load().pendingMints.get(bounced.nameHash);
            assert (pendingLookup.isFound) throw Errors.PendingMintNotFound;
            val pending = pendingLookup.loadValue();
            assert (pending.queryId == bounced.queryId) throw Errors.InvalidMintAcknowledgement;
            assert (pending.state == PENDING_MINT_DEPLOYING) throw Errors.InvalidPendingMintState;
            val expectedItem = calcDeployedNftItem(
                pending.itemIndex,
                contract.getAddress(),
                storage.nftItemCode,
            ).calculateAddress();
            assert (in.senderAddress == expectedItem) throw Errors.InvalidMintAcknowledgement;
            if (in.valueCoins > 0) {
                val retryRefund = createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: bounced.retryCaller,
                    value: in.valueCoins,
                    body: ReturnExcessesBack { queryId: bounced.queryId },
                });
                retryRefund.send(SEND_MODE_PAY_FEES_SEPARATELY);
            }
        }
    }
}

get fun get_collection_data(): CollectionDataReply {
    val storage = NftCollectionStorage.load();
    val details = storage.details.load();
    val content = details.content.load();
    return {
        nextItemIndex: storage.registry.load().nextItemIndex,
        collectionMetadata: content.collectionMetadata,
        adminAddress: storage.adminAddress,
    };
}

get fun get_nft_address_by_index(itemIndex: int): address {
    val storage = NftCollectionStorage.load();
    return calcDeployedNftItem(
        itemIndex as uint256,
        contract.getAddress(),
        storage.nftItemCode,
    ).calculateAddress();
}

get fun royalty_params(): RoyaltyParams {
    val storage = NftCollectionStorage.load();
    return storage.details.load().royaltyParams.load();
}

get fun get_nft_content(
    _itemIndex: int,
    individualNftContent: Cell<SnakeString>,
): cell {
    val storage = NftCollectionStorage.load();
    val content = storage.details.load().content.load();
    val canonicalName = individualNftContent as unknown as string;
    val metadataUri = StringBuilder
        .create()
        .append(content.commonContent as unknown as string)
        .append(canonicalName)
        .append(".json")
        .build();
    val displayName = StringBuilder.create().append("@").append(canonicalName).build();

    var metadata: map<uint256, string_prefixed0x> = [];
    metadata.set("uri".sha256(), metadataUri.prefixWith00());
    metadata.set("name".sha256(), displayName.prefixWith00());
    metadata.set("description".sha256(), ITEM_METADATA_DESCRIPTION.prefixWith00());
    metadata.set("canonical_name".sha256(), canonicalName.prefixWith00());
    metadata.set("identity_storage".sha256(), "on-chain".prefixWith00());
    metadata.set("renderer_archive".sha256(), ITEM_RENDERER_ARCHIVE.prefixWith00());
    return beginCell()
        .storeUint(NFT_ITEM_CONTENT_PREFIX, 8)
        .storeDict(metadata.toLowLevelDict())
        .endCell();
}

get fun get_name_quote(name: string): NameQuoteReply {
    val length = validateCanonicalName(name);
    val nameHash = canonicalNameHash(name);
    val storage = NftCollectionStorage.load();
    val pricing = storage.pricing.load();
    val registry = storage.registry.load();
    val (status, price) = resolveCategoryAndPrice(pricing, nameHash, length);
    val itemIndex = resolveItemIndex(registry, nameHash);
    return {
        nameHash,
        itemIndex,
        length: length as uint8,
        status: status as uint2,
        mintState: getMintState(registry, nameHash) as uint2,
        price,
        requiredValue: price + pricing.itemDeployValue + MINT_GAS_BUDGET + DIRECT_MINT_GAS_BUDGET,
        pricingVersion: pricing.pricingVersion,
        itemAddress: calcDeployedNftItem(
            itemIndex,
            contract.getAddress(),
            storage.nftItemCode,
        ).calculateAddress(),
    };
}

get fun get_collection_config(): CollectionConfigReply {
    val storage = NftCollectionStorage.load();
    val pricing = storage.pricing.load();
    val catalogInitialization = pricing.catalogInitialization.load();
    return {
        adminAddress: storage.adminAddress,
        treasuryAddress: pricing.treasuryAddress,
        paused: storage.paused,
        pricingVersion: pricing.pricingVersion,
        itemDeployValue: pricing.itemDeployValue,
        prices: pricing.prices.load(),
        timelockDelay: CONFIG_TIMELOCK_DELAY as uint32,
        proposalExecutionWindow: CONFIG_PROPOSAL_EXECUTION_WINDOW as uint32,
        governanceEpoch: storage.registry.load().governanceEpoch,
        catalogExpectedCount: catalogInitialization.expectedCount,
        catalogLoadedCount: catalogInitialization.loadedCount,
        catalogRollingHash: catalogInitialization.rollingHash,
        catalogExpectedHash: catalogInitialization.expectedHash,
        catalogFinalized: catalogInitialization.finalized,
    };
}

get fun get_name_hash(name: string): uint256 {
    validateCanonicalName(name);
    return canonicalNameHash(name);
}

get fun get_proposal_id(queryId: uint64, action: cell): uint256 {
    val storage = NftCollectionStorage.load();
    val registry = storage.registry.load();
    return calculateProposalId(storage.adminAddress, registry.governanceEpoch, queryId, action);
}

get fun get_proposal_state(proposalId: uint256): ProposalStateReply {
    val registry = NftCollectionStorage.load().registry.load();
    val lookup = registry.proposals.get(proposalId);
    if (!lookup.isFound) {
        return {
            exists: false,
            governanceEpoch: 0,
            executeAfter: 0,
            expiresAt: 0,
            action: null,
        };
    }
    val proposal = lookup.loadValue();
    return {
        exists: true,
        governanceEpoch: proposal.governanceEpoch,
        executeAfter: proposal.executeAfter,
        expiresAt: proposal.expiresAt,
        action: proposal.action,
    };
}

get fun get_pending_mint(name: string): PendingMintReply {
    validateCanonicalName(name);
    val registry = NftCollectionStorage.load().registry.load();
    val lookup = registry.pendingMints.get(canonicalNameHash(name));
    if (!lookup.isFound) {
        return {
            exists: false,
            itemIndex: 0,
            payerAddress: null,
            queryId: 0,
            price: 0,
            refundAmount: 0,
            state: PENDING_MINT_DEPLOYING as uint1,
        };
    }
    val pending = lookup.loadValue();
    return {
        exists: true,
        itemIndex: pending.itemIndex,
        payerAddress: pending.payerAddress,
        queryId: pending.queryId,
        price: pending.price,
        refundAmount: pending.refundAmount,
        state: pending.state,
    };
}

get fun get_pending_admin(): PendingAdminReply {
    val pending = NftCollectionStorage.load().registry.load().pendingAdmin;
    if (pending == null) {
        return {
            exists: false,
            newAdminAddress: null,
            executeAfter: 0,
            expiresAt: 0,
        };
    }
    return {
        exists: true,
        newAdminAddress: pending.newAdminAddress,
        executeAfter: pending.executeAfter,
        expiresAt: pending.expiresAt,
    };
}
