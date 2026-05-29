import "common.tolk"
import "errors.tolk"
import "lifecycle.tolk"

struct MarketDetail {
    collateralJettonMaster: address
    creator: address
}

struct FactoryComponentConfig {
    ammCollateralJettonWallet: address
    engineCollateralJettonWallet: address
}

struct FactoryMarketDetail {
    collateralJettonMaster: address
    creator: address
    config: Cell<FactoryComponentConfig>
}

struct MarketRefs {
    bookAddress: address
    engineAddress: address
    adjudicatorAddress: address
    detail: Cell<MarketDetail>
}

struct RegisterMarketExtra {
    bookAddress: address
    engineAddress: address
    adjudicatorAddress: address
    detail: Cell<MarketDetail>
}

struct RegisterFactoryMarketExtra {
    bookAddress: address
    engineAddress: address
    adjudicatorAddress: address
    detail: Cell<FactoryMarketDetail>
}

struct MarketEntry {
    ammAddress: address
    lifecycle: uint8
    outcomeCount: uint8
    deadline: int64
    trialEnd: int64
    registeredAt: int64
    graduatedAt: int64
    settledAt: int64
    winningOutcome: uint8
    tStar: int64
    activationConfirmationMask: uint8
    activationFailureMask: uint8
    settlementConfirmationMask: uint8
    settlementFailureMask: uint8
    factorySetupConfirmationMask: uint8
    refs: Cell<MarketRefs>
    launchpadAddress: address
}

// Operator autonomy: governance-set trusted launchpad (config-level; distinct from the
// per-market MarketEntry.launchpadAddress recorded at registration). This is the single
// legitimate sender for launchpad-originated lifecycle entries — market registration and
// the BONDING-state transitions (graduation -> LIVE, trial expiry -> TRIAL_EXPIRED).
// Set by governance via SetLaunchpad (admin-gated, mirrors SetOperator). Held in a sub-cell
// ref because StorageExtra is already at its 1023-bit budget (admin + pendingAdmin + operator
// + the two dicts).
struct RegistryLaunchpadConfig {
    launchpadAddress: address
}

struct StorageExtra {
    admin: address
    pendingAdmin: address?
    pendingAdminReadyAt: int64
    operatorAddress: address
    launchpadConfig: Cell<RegistryLaunchpadConfig>
    markets: map<uint32, MarketEntry>
    factorySetupPending: map<address, uint32>
}

struct Storage {
    sequence: uint32
    marketCount: uint32
    defaultTrialPeriod: int64
    invalidationBuffer: int64
    paused: bool
    extra: Cell<StorageExtra>
}

struct (0x736f7072) SetOperator {
    operatorAddress: address
}

// Operator autonomy: governance-set trusted launchpad. Admin-gated (mirrors SetOperator).
// op 0x736c6170 == "slap" (Set LAunchPad). The SDK stamps the launchpad address into the
// deploy config; this setter rotates it under governance.
struct (0x736c6170) SetLaunchpad {
    launchpadAddress: address
}

// ProposeAdmin / AcceptAdmin / SetPaused structs are shared via common.tolk.

struct (0x7265676d) RegisterMarket {
    marketId: uint32
    ammAddress: address
    outcomeCount: uint8
    deadline: int64
    trialEnd: int64
    registeredAt: int64
    extra: Cell<RegisterMarketExtra>
}

struct (0x72666d6b) RegisterFactoryMarket {
    marketId: uint32
    ammAddress: address
    outcomeCount: uint8
    deadline: int64
    trialEnd: int64
    registeredAt: int64
    extra: Cell<RegisterFactoryMarketExtra>
}

struct (0x61626f72) AbortLaunchRegistration {
    marketId: uint32
}

struct (0x6c696665) SetLifecycle {
    marketId: uint32
    lifecycle: uint8
    winningOutcome: uint8
    timestamp: int64
    tStar: int64
}

struct (0x7374746c) AmmSettleMarket {
    marketId: uint32
    winningOutcome: uint8
    tStar: int64
}

struct (0x7365746c) OrderEngineSettleMarket {
    marketId: uint32
    winningOutcome: uint8
}

// EVM parity (OrderEngine.sol:747 _requireBeforeDeadline / AMMEngine.sol:246): orderbook venues
// must reject fill/match/mint past the market deadline. The registry — the canonical lifecycle
// authority — carries the market's deadline on this shared-opcode activation so both venues
// (engine + book) seal it into their Storage at activate and gate trades on it. infiniteDeadline()
// sentinel disables the gate per EVM `type(uint64).max` opt-out.
struct (0x61637476) ActivateMarket {
    marketId: uint32
    deadline: int64
}

struct (0x61636f6e) ActivationConfirmed {
    marketId: uint32
    venue: uint8
    venueSequence: uint32
}

struct (0x6c73746c) LaunchpadSettleMarket {
    marketId: uint32
    winningOutcome: uint8
    timestamp: int64
}

struct (0x696e766c) InvalidateMarket {
    marketId: uint32
}

struct (0x73636f6e) SettlementConfirmed {
    marketId: uint32
    venue: uint8
    winningOutcome: uint8
    venueSequence: uint32
}

struct (0x66636f6e) FactorySetupConfirmed {
    marketId: uint32
    setup: uint8
    venueSequence: uint32
}

struct (0x73726f74) PostSettlementRoot {
    marketId: uint32
    merkleRoot: uint256
}

struct (0x72616374) RetryActivationFanout {
    marketId: uint32
}

struct (0x7273746c) RetrySettlementFanout {
    marketId: uint32
}

struct (0x726f6f74) AmmPostSettlementRoot {
    marketId: uint32
    merkleRoot: uint256
}

struct (0x736a6574) SetCollateralJettonWallet {
    wallet: address
}

struct (0x736c6672) SetLaunchpadFeeRouter {
    router: address?
}

struct (0x6273656e) SetOrderEngine {
    engineAddress: address
}

// H-1 fix: OUTBOUND stamp of the AMM's address into the order engine (op matches the engine's
// inbound SetAmmAddress, 0x73616d77). Sent in the factory-setup phase alongside the engine's own
// SetCollateralJettonWallet, so the engine knows the owner address to forward taker fees to (it
// emits a JettonTransfer from its own wallet with `destination` == this AMM). The registry holds
// market.ammAddress for this market, so this is a free addition to the existing wiring fan-out.
struct (0x73616d77) SetAmmAddress {
    ammAddress: address
}

struct (0x72656366) RegistryLaunchConfirmed {
    marketId: uint32
    registeredAt: int64
}

struct (0x72657674) SoothMarketRegistryEvent {
    kind: uint32
    marketId: uint32
    sequence: uint32
    actor: address
    lifecycle: uint8
    winningOutcome: uint8
    aux: int64
}

type AllowedMessage =
    | SetOperator
    | SetLaunchpad
    | ProposeAdmin
    | AcceptAdmin
    | SetPaused
    | RegisterMarket
    | RegisterFactoryMarket
    | AbortLaunchRegistration
    | SetLifecycle
    | InvalidateMarket
    | ActivationConfirmed
    | SettlementConfirmed
    | FactorySetupConfirmed
    | PostSettlementRoot
    | RetryActivationFanout
    | RetrySettlementFanout

type RegistryBounceMessage =
    | SetCollateralJettonWallet
    | SetLaunchpadFeeRouter
    | SetOrderEngine
    | ActivateMarket
    | AmmSettleMarket
    | OrderEngineSettleMarket
    | LaunchpadSettleMarket

fun Storage.load() {
    return Storage.fromCell(contract.getData());
}

fun Storage.save(self) {
    contract.setData(self.toCell());
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessage.fromSlice(in.body);
    var storage = lazy Storage.load();
    match (msg) {
        SetOperator => {
            executeSetOperator(mutate storage, in.senderAddress, msg);
        }

        SetLaunchpad => {
            executeSetLaunchpad(mutate storage, in.senderAddress, msg);
        }

        ProposeAdmin => {
            executeProposeAdmin(mutate storage, in.senderAddress, msg);
        }

        AcceptAdmin => {
            executeAcceptAdmin(mutate storage, in.senderAddress);
        }

        SetPaused => {
            executeSetPaused(mutate storage, in.senderAddress, msg);
        }

        RegisterMarket => {
            executeRegisterMarket(mutate storage, in.senderAddress, msg);
        }

        RegisterFactoryMarket => {
            executeRegisterFactoryMarket(mutate storage, in.senderAddress, msg);
        }

        AbortLaunchRegistration => {
            executeAbortLaunchRegistration(mutate storage, in.senderAddress, msg);
        }

        SetLifecycle => {
            executeSetLifecycle(mutate storage, in.senderAddress, msg);
        }

        InvalidateMarket => {
            executeInvalidateMarket(mutate storage, in.senderAddress, msg);
        }

        ActivationConfirmed => {
            executeActivationConfirmed(mutate storage, in.senderAddress, msg);
        }

        SettlementConfirmed => {
            executeSettlementConfirmed(mutate storage, in.senderAddress, msg);
        }

        FactorySetupConfirmed => {
            executeFactorySetupConfirmed(mutate storage, in.senderAddress, msg);
        }

        PostSettlementRoot => {
            executePostSettlementRoot(mutate storage, in.senderAddress, msg);
        }

        RetryActivationFanout => {
            executeRetryActivationFanout(mutate storage, in.senderAddress, msg);
        }

        RetrySettlementFanout => {
            executeRetrySettlementFanout(mutate storage, in.senderAddress, msg);
        }

        else => {
            assert (in.body.isEmpty()) throw 0xffff;
        }
    }
}

fun onBouncedMessage(in: InMessageBounced) {
    val rich = lazy RichBounceBody.fromSlice(in.bouncedBody);
    val bounced = lazy RegistryBounceMessage.fromSlice(rich.originalBody.beginParse());
    var storage = lazy Storage.load();
    match (bounced) {
        SetCollateralJettonWallet => {
            executeFactorySetupBounced(mutate storage, in.senderAddress);
        }

        SetLaunchpadFeeRouter => {
            executeFactorySetupBounced(mutate storage, in.senderAddress);
        }

        SetOrderEngine => {
            executeFactorySetupBounced(mutate storage, in.senderAddress);
        }

        ActivateMarket => {
            executeOrderbookActivationBounced(mutate storage, in.senderAddress, bounced.marketId);
        }

        AmmSettleMarket => {
            executeSettlementPropagationBounced(
                mutate storage,
                in.senderAddress,
                bounced.marketId,
                bounced.winningOutcome,
                settlementVenueAmm(),
            );
        }

        OrderEngineSettleMarket => {
            executeOrderbookSettlementPropagationBounced(
                mutate storage,
                in.senderAddress,
                bounced.marketId,
                bounced.winningOutcome,
            );
        }

        LaunchpadSettleMarket => {
            executeSettlementPropagationBounced(
                mutate storage,
                in.senderAddress,
                bounced.marketId,
                bounced.winningOutcome,
                settlementVenueLaunchpad(),
            );
        }
    }
}

fun executeSetOperator(mutate storage: Storage, senderAddress: address, msg: SetOperator) {
    var extra = storage.extra.load();
    requireAdmin(extra, senderAddress);
    extra.operatorAddress = msg.operatorAddress;
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitRegistryEvent(
        3,
        storage,
        0,
        senderAddress,
        0,
        invalidOutcome(),
        0,
    );
}

// Operator autonomy: governance rotates the trusted launchpad. Admin-gated (same gate as
// SetOperator). The new launchpad becomes the only legitimate sender for Register* and the
// BONDING-state lifecycle entries (LIVE/TRIAL_EXPIRED).
fun executeSetLaunchpad(mutate storage: Storage, senderAddress: address, msg: SetLaunchpad) {
    var extra = storage.extra.load();
    requireAdmin(extra, senderAddress);
    extra.launchpadConfig = RegistryLaunchpadConfig {
        launchpadAddress: msg.launchpadAddress,
    }.toCell();
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitRegistryEvent(
        15,
        storage,
        0,
        senderAddress,
        0,
        invalidOutcome(),
        0,
    );
}

fun executeProposeAdmin(mutate storage: Storage, senderAddress: address, msg: ProposeAdmin) {
    var extra = storage.extra.load();
    requireAdmin(extra, senderAddress);
    extra.pendingAdmin = msg.admin;
    extra.pendingAdminReadyAt = (blockchain.now() as int64) + 86400;
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitRegistryEvent(
        8,
        storage,
        0,
        senderAddress,
        0,
        invalidOutcome(),
        0,
    );
}

fun executeAcceptAdmin(mutate storage: Storage, senderAddress: address) {
    var extra = storage.extra.load();
    assert (extra.pendingAdmin != null) throw Errors.TRADER_UNAUTHORIZED;
    assert (senderAddress == extra.pendingAdmin!) throw Errors.TRADER_UNAUTHORIZED;
    assert (blockchain.now() >= extra.pendingAdminReadyAt) throw Errors.PENDING_ADMIN_NOT_READY;
    extra.admin = senderAddress;
    extra.pendingAdmin = null;
    extra.pendingAdminReadyAt = 0;
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitRegistryEvent(
        9,
        storage,
        0,
        senderAddress,
        0,
        invalidOutcome(),
        0,
    );
}

fun executeSetPaused(mutate storage: Storage, senderAddress: address, msg: SetPaused) {
    val extra = storage.extra.load();
    requireAdmin(extra, senderAddress);
    storage.paused = msg.paused;
    storage.sequence += 1;
    storage.save();
    emitRegistryEvent(
        4,
        storage,
        0,
        senderAddress,
        0,
        invalidOutcome(),
        msg.paused ? 1 : 0,
    );
}

fun executeRegisterMarket(mutate storage: Storage, senderAddress: address, msg: RegisterMarket) {
    var extra = storage.extra.load();
    requireLaunchpad(extra, senderAddress);
    requireNotPaused(storage.paused);
    validateRegistryConfig(storage);
    validateMarketRegistration(msg);
    val existing = extra.markets.get(msg.marketId);
    assert (existing.isFound == false) throw Errors.REGISTRY_MARKET_EXISTS;

    val msgExtra = msg.extra.load();
    val msgDetail = msgExtra.detail.load();
    val detail: MarketDetail = {
        collateralJettonMaster: msgDetail.collateralJettonMaster,
        creator: msgDetail.creator,
    };
    val refs: MarketRefs = {
        bookAddress: msgExtra.bookAddress,
        engineAddress: msgExtra.engineAddress,
        adjudicatorAddress: msgExtra.adjudicatorAddress,
        detail: detail.toCell(),
    };
    val market: MarketEntry = {
        ammAddress: msg.ammAddress,
        lifecycle: lifecycleBonding(),
        outcomeCount: msg.outcomeCount,
        deadline: msg.deadline,
        trialEnd: msg.trialEnd,
        registeredAt: msg.registeredAt,
        graduatedAt: 0,
        settledAt: 0,
        winningOutcome: invalidOutcome(),
        tStar: 0,
        activationConfirmationMask: 0,
        activationFailureMask: 0,
        settlementConfirmationMask: 0,
        settlementFailureMask: 0,
        factorySetupConfirmationMask: factorySetupAllMask(),
        refs: refs.toCell(),
        launchpadAddress: senderAddress,
    };

    extra.markets.set(msg.marketId, market);
    storage.marketCount += 1;
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitRegistryEvent(
        1,
        storage,
        msg.marketId,
        senderAddress,
        lifecycleBonding(),
        invalidOutcome(),
        msg.registeredAt,
    );
    sendLaunchpadRegistrationConfirmation(senderAddress, msg.marketId, msg.registeredAt);
}

fun executeRegisterFactoryMarket(
    mutate storage: Storage,
    senderAddress: address,
    msg: RegisterFactoryMarket,
) {
    var extra = storage.extra.load();
    requireLaunchpad(extra, senderAddress);
    requireNotPaused(storage.paused);
    validateRegistryConfig(storage);
    validateFactoryMarketRegistration(msg);
    val existing = extra.markets.get(msg.marketId);
    assert (existing.isFound == false) throw Errors.REGISTRY_MARKET_EXISTS;

    val msgExtra = msg.extra.load();
    val msgDetail = msgExtra.detail.load();
    val detail: MarketDetail = {
        collateralJettonMaster: msgDetail.collateralJettonMaster,
        creator: msgDetail.creator,
    };
    val refs: MarketRefs = {
        bookAddress: msgExtra.bookAddress,
        engineAddress: msgExtra.engineAddress,
        adjudicatorAddress: msgExtra.adjudicatorAddress,
        detail: detail.toCell(),
    };
    val market: MarketEntry = {
        ammAddress: msg.ammAddress,
        lifecycle: lifecycleBonding(),
        outcomeCount: msg.outcomeCount,
        deadline: msg.deadline,
        trialEnd: msg.trialEnd,
        registeredAt: msg.registeredAt,
        graduatedAt: 0,
        settledAt: 0,
        winningOutcome: invalidOutcome(),
        tStar: 0,
        activationConfirmationMask: 0,
        activationFailureMask: 0,
        settlementConfirmationMask: 0,
        settlementFailureMask: 0,
        factorySetupConfirmationMask: 0,
        refs: refs.toCell(),
        launchpadAddress: senderAddress,
    };

    extra.markets.set(msg.marketId, market);
    extra.factorySetupPending.set(market.ammAddress, msg.marketId);
    extra.factorySetupPending.set(refs.engineAddress, msg.marketId);
    extra.factorySetupPending.set(refs.bookAddress, msg.marketId);
    storage.marketCount += 1;
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitRegistryEvent(
        1,
        storage,
        msg.marketId,
        senderAddress,
        lifecycleBonding(),
        invalidOutcome(),
        msg.registeredAt,
    );
    sendFactoryComponentConfiguration(market, refs, msgDetail.config.load());
}

fun executeAbortLaunchRegistration(
    mutate storage: Storage,
    senderAddress: address,
    msg: AbortLaunchRegistration,
) {
    var extra = storage.extra.load();
    val result = extra.markets.get(msg.marketId);
    assert (result.isFound) throw Errors.REGISTRY_MARKET_NOT_FOUND;
    val market = result.loadValue();
    val refs = market.refs.load();
    assert (senderAddress == market.launchpadAddress) throw Errors.ADMIN_UNAUTHORIZED;
    assert (market.lifecycle == lifecycleBonding()) throw Errors.REGISTRY_LIFECYCLE_INVALID;
    assert (storage.marketCount > 0) throw Errors.REGISTRY_LIFECYCLE_INVALID;

    extra.markets.delete(msg.marketId);
    clearFactorySetupPending(mutate extra, market, refs);
    storage.marketCount -= 1;
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitRegistryEvent(
        6,
        storage,
        msg.marketId,
        senderAddress,
        lifecycleBonding(),
        invalidOutcome(),
        0,
    );
}

fun executeSetLifecycle(mutate storage: Storage, senderAddress: address, msg: SetLifecycle) {
    var extra = storage.extra.load();
    requireNotPaused(storage.paused);
    assert (msg.timestamp > 0) throw Errors.REGISTRY_TIMESTAMP_INVALID;
    validateLifecycle(msg.lifecycle);
    validateWinningOutcome(msg.winningOutcome);

    val result = extra.markets.get(msg.marketId);
    assert (result.isFound) throw Errors.REGISTRY_MARKET_NOT_FOUND;
    var market = result.loadValue();
    // Operator autonomy: per-sender lifecycle authz, branched by the CURRENT lifecycle so
    // each (current -> next) transition is authed to exactly its one legitimate sender:
    //   - from BONDING  -> the launchpad originates graduation (LIVE) and trial expiry
    //     (TRIAL_EXPIRED): sender == config.launchpadAddress.
    //   - from LIVE/RESOLVING/ATTESTED/TRIAL_EXPIRED -> the market's adjudicator originates
    //     resolve (RESOLVING), attest (ATTESTED), settle (SETTLED), and dispute rollback to
    //     LIVE: sender == market.refs.adjudicatorAddress (the existing PostSettlementRoot /
    //     SettlementConfirmed per-ref idiom). The target LIVE is thus correctly split:
    //     graduation from BONDING is the launchpad; a dispute rollback from RESOLVING/
    //     ATTESTED is the adjudicator. isValidTransition still gates the (current, next) pair.
    if (market.lifecycle == lifecycleBonding()) {
        requireLaunchpad(extra, senderAddress);
    } else {
        val authRefs = market.refs.load();
        assert (senderAddress == authRefs.adjudicatorAddress) throw Errors.ADMIN_UNAUTHORIZED;
    }
    assert (
        isValidTransition(market.lifecycle, msg.lifecycle, msg.winningOutcome)
    ) throw Errors.REGISTRY_LIFECYCLE_INVALID;

    market.lifecycle = msg.lifecycle;
    market.winningOutcome = msg.winningOutcome;
    market.tStar = msg.tStar;
    if (msg.lifecycle == lifecycleLive() && market.graduatedAt == 0) {
        market.graduatedAt = msg.timestamp;
    }
    if (msg.lifecycle == lifecycleSettled()) {
        market.settledAt = msg.timestamp;
    }

    extra.markets.set(msg.marketId, market);
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitRegistryEvent(
        2,
        storage,
        msg.marketId,
        senderAddress,
        msg.lifecycle,
        msg.winningOutcome,
        msg.timestamp,
    );
    if (msg.lifecycle == lifecycleLive()) {
        sendOrderbookActivation(market, msg.marketId);
    }
    if (msg.lifecycle == lifecycleSettled()) {
        sendSettlementPropagation(market, msg.marketId, msg.winningOutcome);
    }
}

fun executeInvalidateMarket(
    mutate storage: Storage,
    senderAddress: address,
    msg: InvalidateMarket,
) {
    var extra = storage.extra.load();
    val result = extra.markets.get(msg.marketId);
    assert (result.isFound) throw Errors.REGISTRY_MARKET_NOT_FOUND;
    var market = result.loadValue();
    // EVM parity (TruthMarket.invalidate): permissionless invalidation is the
    // "no resolution arrived in time / adjudicator unreachable" fallback, allowed from ANY
    // non-settled lifecycle (incl. RESOLVING/ATTESTED) once now >= deadline + invalidationBuffer.
    // The (long) buffer is the protection — a stalled/unreachable adjudicator can always be
    // routed around after it elapses, exactly as in the EVM reference.
    assert (market.lifecycle != lifecycleSettled()) throw Errors.REGISTRY_LIFECYCLE_INVALID;
    // EVM TruthMarket.sol:179-180 reverts InfiniteDeadline() — an infinite-deadline market opted
    // out of the permissionless-timeout safety net. Without this guard the sentinel deadline would
    // make `now() >= deadline + buffer` false forever (the sum is computed in TVM's 257-bit math, so
    // it does NOT overflow), rejecting with the misleading REGISTRY_INVALIDATION_TOO_EARLY instead
    // of the correct "never invalidatable" semantic. So the guard is for EVM parity + a clear error.
    assert (market.deadline != infiniteDeadline()) throw Errors.INFINITE_DEADLINE;
    assert (
        blockchain.now() >= market.deadline + storage.invalidationBuffer
    ) throw Errors.REGISTRY_INVALIDATION_TOO_EARLY;

    market.lifecycle = lifecycleSettled();
    market.winningOutcome = invalidOutcome();
    market.tStar = 0;
    market.settledAt = blockchain.now() as int64;
    extra.markets.set(msg.marketId, market);
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitRegistryEvent(
        5,
        storage,
        msg.marketId,
        senderAddress,
        lifecycleSettled(),
        invalidOutcome(),
        market.settledAt,
    );
    sendSettlementPropagation(market, msg.marketId, invalidOutcome());
    sendAdjudicatorInvalidation(market, msg.marketId);
}

fun executeActivationConfirmed(
    mutate storage: Storage,
    senderAddress: address,
    msg: ActivationConfirmed,
) {
    var extra = storage.extra.load();
    val result = extra.markets.get(msg.marketId);
    assert (result.isFound) throw Errors.REGISTRY_MARKET_NOT_FOUND;
    var market = result.loadValue();
    assert (market.lifecycle == lifecycleLive()) throw Errors.REGISTRY_LIFECYCLE_INVALID;
    val refs = market.refs.load();
    val venueMask = orderbookActivationVenueMask(refs, senderAddress, msg.venue);
    assert (venueMask > 0) throw Errors.REGISTRY_VENUE_MASK_INVALID;

    if (settlementMaskHas(market.activationConfirmationMask, venueMask) == false) {
        market.activationConfirmationMask += venueMask;
        if (settlementMaskHas(market.activationFailureMask, venueMask)) {
            market.activationFailureMask -= venueMask;
        }
        extra.markets.set(msg.marketId, market);
        storage.sequence += 1;
        storage.extra = extra.toCell();
        storage.save();
        emitRegistryEvent(
            13,
            storage,
            msg.marketId,
            senderAddress,
            lifecycleLive(),
            market.winningOutcome,
            market.activationConfirmationMask as int64,
        );
    }
}

fun executeOrderbookActivationBounced(
    mutate storage: Storage,
    senderAddress: address,
    marketId: uint32,
) {
    var extra = storage.extra.load();
    val result = extra.markets.get(marketId);
    if (result.isFound) {
        var market = result.loadValue();
        if (market.lifecycle == lifecycleLive()) {
            val refs = market.refs.load();
            val venueMask = orderbookActivationBouncedMask(refs, senderAddress);
            if (
                venueMask > 0 &&
                settlementMaskHas(market.activationFailureMask, venueMask) == false &&
                settlementMaskHas(market.activationConfirmationMask, venueMask) == false
            ) {
                market.activationFailureMask += venueMask;
                extra.markets.set(marketId, market);
                storage.sequence += 1;
                storage.extra = extra.toCell();
                storage.save();
                emitRegistryEvent(
                    14,
                    storage,
                    marketId,
                    senderAddress,
                    lifecycleLive(),
                    market.winningOutcome,
                    market.activationFailureMask as int64,
                );
            }
        }
    }
}

fun executeSettlementConfirmed(
    mutate storage: Storage,
    senderAddress: address,
    msg: SettlementConfirmed,
) {
    var extra = storage.extra.load();
    val result = extra.markets.get(msg.marketId);
    assert (result.isFound) throw Errors.REGISTRY_MARKET_NOT_FOUND;
    var market = result.loadValue();
    assert (market.lifecycle == lifecycleSettled()) throw Errors.REGISTRY_LIFECYCLE_INVALID;
    assert (market.winningOutcome == msg.winningOutcome) throw Errors.REGISTRY_LIFECYCLE_INVALID;
    val refs = market.refs.load();
    val venueMask = settlementVenueMask(market, refs, senderAddress, msg.venue);
    assert (venueMask > 0) throw Errors.REGISTRY_VENUE_MASK_INVALID;

    if (settlementMaskHas(market.settlementConfirmationMask, venueMask) == false) {
        market.settlementConfirmationMask += venueMask;
        if (settlementMaskHas(market.settlementFailureMask, venueMask)) {
            market.settlementFailureMask -= venueMask;
        }
        extra.markets.set(msg.marketId, market);
        storage.sequence += 1;
        storage.extra = extra.toCell();
        storage.save();
        emitRegistryEvent(
            7,
            storage,
            msg.marketId,
            senderAddress,
            lifecycleSettled(),
            msg.winningOutcome,
            market.settlementConfirmationMask as int64,
        );
    }
}

fun executeOrderbookSettlementPropagationBounced(
    mutate storage: Storage,
    senderAddress: address,
    marketId: uint32,
    winningOutcome: uint8,
) {
    var extra = storage.extra.load();
    val result = extra.markets.get(marketId);
    if (result.isFound) {
        val market = result.loadValue();
        val refs = market.refs.load();
        if (senderAddress == refs.engineAddress) {
            executeSettlementPropagationBounced(
                mutate storage,
                senderAddress,
                marketId,
                winningOutcome,
                settlementVenueOrderEngine(),
            );
        } else if (senderAddress == refs.bookAddress) {
            executeSettlementPropagationBounced(
                mutate storage,
                senderAddress,
                marketId,
                winningOutcome,
                settlementVenueBook(),
            );
        }
    }
}

fun executeSettlementPropagationBounced(
    mutate storage: Storage,
    senderAddress: address,
    marketId: uint32,
    winningOutcome: uint8,
    venue: uint8,
) {
    var extra = storage.extra.load();
    val result = extra.markets.get(marketId);
    if (result.isFound) {
        var market = result.loadValue();
        if (market.lifecycle == lifecycleSettled() && market.winningOutcome == winningOutcome) {
            val refs = market.refs.load();
            val venueMask = settlementVenueMask(market, refs, senderAddress, venue);
            if (
                venueMask > 0 &&
                settlementMaskHas(market.settlementFailureMask, venueMask) == false &&
                settlementMaskHas(market.settlementConfirmationMask, venueMask) == false
            ) {
                market.settlementFailureMask += venueMask;
                extra.markets.set(marketId, market);
                storage.sequence += 1;
                storage.extra = extra.toCell();
                storage.save();
                emitRegistryEvent(
                    12,
                    storage,
                    marketId,
                    senderAddress,
                    lifecycleSettled(),
                    winningOutcome,
                    market.settlementFailureMask as int64,
                );
            }
        }
    }
}

fun executeFactorySetupConfirmed(
    mutate storage: Storage,
    senderAddress: address,
    msg: FactorySetupConfirmed,
) {
    var extra = storage.extra.load();
    val pending = extra.factorySetupPending.get(senderAddress);
    assert (pending.isFound) throw Errors.REGISTRY_VENUE_MASK_INVALID;
    assert (pending.loadValue() == msg.marketId) throw Errors.REGISTRY_VENUE_MASK_INVALID;

    val result = extra.markets.get(msg.marketId);
    assert (result.isFound) throw Errors.REGISTRY_MARKET_NOT_FOUND;
    var market = result.loadValue();
    assert (market.lifecycle == lifecycleBonding()) throw Errors.REGISTRY_LIFECYCLE_INVALID;
    val refs = market.refs.load();
    val setupMask = factorySetupMaskFor(market, refs, senderAddress, msg.setup);
    assert (setupMask > 0) throw Errors.VENUE_SETUP_INVALID;

    if (setupMaskHas(market.factorySetupConfirmationMask, setupMask) == false) {
        market.factorySetupConfirmationMask += setupMask;
        val setupComplete = market.factorySetupConfirmationMask == factorySetupAllMask();
        extra.markets.set(msg.marketId, market);
        if (setupComplete) {
            clearFactorySetupPending(mutate extra, market, refs);
        }
        storage.sequence += 1;
        storage.extra = extra.toCell();
        storage.save();
        emitRegistryEvent(
            11,
            storage,
            msg.marketId,
            senderAddress,
            lifecycleBonding(),
            invalidOutcome(),
            market.factorySetupConfirmationMask as int64,
        );
        if (setupComplete) {
            sendLaunchpadRegistrationConfirmation(
                market.launchpadAddress,
                msg.marketId,
                market.registeredAt,
            );
        }
    }
}

fun executeFactorySetupBounced(mutate storage: Storage, senderAddress: address) {
    var extra = storage.extra.load();
    val pending = extra.factorySetupPending.get(senderAddress);
    if (pending.isFound) {
        val marketId = pending.loadValue();
        val result = extra.markets.get(marketId);
        if (result.isFound) {
            val market = result.loadValue();
            val refs = market.refs.load();
            assert (market.lifecycle == lifecycleBonding()) throw Errors.REGISTRY_LIFECYCLE_INVALID;
            assert (storage.marketCount > 0) throw Errors.REGISTRY_LIFECYCLE_INVALID;
            extra.markets.delete(marketId);
            clearFactorySetupPending(mutate extra, market, refs);
            storage.marketCount -= 1;
            storage.sequence += 1;
            storage.extra = extra.toCell();
            storage.save();
            emitRegistryEvent(
                6,
                storage,
                marketId,
                senderAddress,
                lifecycleBonding(),
                invalidOutcome(),
                0,
            );
            sendLaunchpadRegistrationAbort(market.launchpadAddress, marketId);
        } else {
            extra.factorySetupPending.delete(senderAddress);
            storage.extra = extra.toCell();
            storage.save();
        }
    }
}

fun executePostSettlementRoot(
    mutate storage: Storage,
    senderAddress: address,
    msg: PostSettlementRoot,
) {
    var extra = storage.extra.load();
    val result = extra.markets.get(msg.marketId);
    assert (result.isFound) throw Errors.REGISTRY_MARKET_NOT_FOUND;
    val market = result.loadValue();
    val refs = market.refs.load();
    assert (senderAddress == refs.adjudicatorAddress) throw Errors.ADMIN_UNAUTHORIZED;
    assert (market.lifecycle == lifecycleSettled()) throw Errors.REGISTRY_LIFECYCLE_INVALID;
    assert (market.tStar > 0) throw Errors.ADJUDICATOR_TSTAR_INVALID;
    assert (msg.merkleRoot > 0) throw Errors.NON_POSITIVE_AMOUNT;

    val rootMsg: AmmPostSettlementRoot = { marketId: msg.marketId, merkleRoot: msg.merkleRoot };
    val outMsg = createMessage({
        bounce: BounceMode.NoBounce,
        value: ton("0.03"),
        dest: market.ammAddress,
        body: rootMsg,
    });
    storage.sequence += 1;
    storage.save();
    emitRegistryEvent(
        8,
        storage,
        msg.marketId,
        senderAddress,
        lifecycleSettled(),
        market.winningOutcome,
        market.tStar,
    );
    outMsg.send(SEND_MODE_REGULAR);
}

fun executeRetryActivationFanout(
    mutate storage: Storage,
    senderAddress: address,
    msg: RetryActivationFanout,
) {
    val extra = storage.extra.load();
    requireOperator(extra, senderAddress);
    val result = extra.markets.get(msg.marketId);
    assert (result.isFound) throw Errors.REGISTRY_MARKET_NOT_FOUND;
    val market = result.loadValue();
    assert (market.lifecycle == lifecycleLive()) throw Errors.REGISTRY_LIFECYCLE_INVALID;
    assert (
        market.activationConfirmationMask != orderbookVenueAllMask()
    ) throw Errors.REGISTRY_LIFECYCLE_INVALID;
    sendOrderbookActivation(market, msg.marketId);
}

fun executeRetrySettlementFanout(
    mutate storage: Storage,
    senderAddress: address,
    msg: RetrySettlementFanout,
) {
    val extra = storage.extra.load();
    requireOperator(extra, senderAddress);
    val result = extra.markets.get(msg.marketId);
    assert (result.isFound) throw Errors.REGISTRY_MARKET_NOT_FOUND;
    val market = result.loadValue();
    assert (market.lifecycle == lifecycleSettled()) throw Errors.REGISTRY_LIFECYCLE_INVALID;
    assert (
        market.settlementConfirmationMask != settlementVenueAllMask()
    ) throw Errors.REGISTRY_LIFECYCLE_INVALID;
    sendSettlementPropagation(market, msg.marketId, market.winningOutcome);
}

fun sendSettlementPropagation(market: MarketEntry, marketId: uint32, winningOutcome: uint8): void {
    val refs = market.refs.load();
    val ammSettle: AmmSettleMarket = {
        marketId,
        winningOutcome,
        tStar: market.tStar,
    };
    val ammMsg = createMessage({
        bounce: BounceMode.RichBounce,
        // Audit follow-up: bumped 0.03 -> 0.1 to fund the AMM's retro-settle outbound chain
        // (sendLaunchpadSettlementFloor 0.05 + sendRegistrySettlementConfirmation 0.005 + gas).
        // Non-retro settle is well under-budget either way; retro markets without prior trade
        // balance would otherwise underflow on the action phase.
        value: ton("0.1"),
        dest: market.ammAddress,
        body: ammSettle,
    });
    ammMsg.send(SEND_MODE_REGULAR);

    val engineSettle: OrderEngineSettleMarket = { marketId, winningOutcome };
    val engineMsg = createMessage({
        bounce: BounceMode.RichBounce,
        value: ton("0.03"),
        dest: refs.engineAddress,
        body: engineSettle,
    });
    engineMsg.send(SEND_MODE_REGULAR);

    val bookMsg = createMessage({
        bounce: BounceMode.RichBounce,
        value: ton("0.03"),
        dest: refs.bookAddress,
        body: engineSettle,
    });
    bookMsg.send(SEND_MODE_REGULAR);

    val launchpadSettle: LaunchpadSettleMarket = {
        marketId,
        winningOutcome,
        timestamp: market.settledAt,
    };
    val launchpadMsg = createMessage({
        bounce: BounceMode.RichBounce,
        value: ton("0.03"),
        dest: market.launchpadAddress,
        body: launchpadSettle,
    });
    launchpadMsg.send(SEND_MODE_REGULAR);
}

fun sendFactoryComponentConfiguration(
    market: MarketEntry,
    refs: MarketRefs,
    config: FactoryComponentConfig,
): void {
    val ammWallet: SetCollateralJettonWallet = { wallet: config.ammCollateralJettonWallet };
    val ammWalletMsg = createMessage({
        bounce: BounceMode.RichBounce,
        value: ton("0.03"),
        dest: market.ammAddress,
        body: ammWallet,
    });
    ammWalletMsg.send(SEND_MODE_REGULAR);

    val ammRouter: SetLaunchpadFeeRouter = { router: market.launchpadAddress };
    val ammRouterMsg = createMessage({
        bounce: BounceMode.RichBounce,
        value: ton("0.03"),
        dest: market.ammAddress,
        body: ammRouter,
    });
    ammRouterMsg.send(SEND_MODE_REGULAR);

    val engineWallet: SetCollateralJettonWallet = { wallet: config.engineCollateralJettonWallet };
    val engineWalletMsg = createMessage({
        bounce: BounceMode.RichBounce,
        value: ton("0.03"),
        dest: refs.engineAddress,
        body: engineWallet,
    });
    engineWalletMsg.send(SEND_MODE_REGULAR);

    // H-1 fix: tell the engine the AMM's address (its taker-fee forward target's owner). The
    // engine emits a JettonTransfer from its own wallet with `destination` == this AMM, so the
    // fee lands in the AMM's collateral wallet. The engine confirms this step back with
    // factorySetupEngineAmmWalletMask (16).
    val engineAmmAddress: SetAmmAddress = { ammAddress: market.ammAddress };
    val engineAmmAddressMsg = createMessage({
        bounce: BounceMode.RichBounce,
        value: ton("0.03"),
        dest: refs.engineAddress,
        body: engineAmmAddress,
    });
    engineAmmAddressMsg.send(SEND_MODE_REGULAR);

    val bookEngine: SetOrderEngine = { engineAddress: refs.engineAddress };
    val bookEngineMsg = createMessage({
        bounce: BounceMode.RichBounce,
        value: ton("0.03"),
        dest: refs.bookAddress,
        body: bookEngine,
    });
    bookEngineMsg.send(SEND_MODE_REGULAR);
}

fun sendOrderbookActivation(market: MarketEntry, marketId: uint32): void {
    val refs = market.refs.load();
    // EVM-parity deadline plumbing: the engine + book seal market.deadline into their Storage on
    // activate and reject fills/mints once now >= deadline. infiniteDeadline() sentinel disables.
    val activation: ActivateMarket = { marketId, deadline: market.deadline };
    val engineMsg = createMessage({
        bounce: BounceMode.RichBounce,
        value: ton("0.005"),
        dest: refs.engineAddress,
        body: activation,
    });
    engineMsg.send(SEND_MODE_REGULAR);

    val bookMsg = createMessage({
        bounce: BounceMode.RichBounce,
        value: ton("0.005"),
        dest: refs.bookAddress,
        body: activation,
    });
    bookMsg.send(SEND_MODE_REGULAR);
}

fun sendAdjudicatorInvalidation(market: MarketEntry, marketId: uint32): void {
    val refs = market.refs.load();
    val invalidate: InvalidateMarket = { marketId };
    val adjudicatorMsg = createMessage({
        bounce: BounceMode.NoBounce,
        value: ton("0.03"),
        dest: refs.adjudicatorAddress,
        body: invalidate,
    });
    adjudicatorMsg.send(SEND_MODE_REGULAR);
}

fun sendLaunchpadRegistrationConfirmation(
    launchpadAddress: address,
    marketId: uint32,
    registeredAt: int64,
): void {
    val confirmation: RegistryLaunchConfirmed = { marketId, registeredAt };
    val confirmationMsg = createMessage({
        bounce: BounceMode.NoBounce,
        value: ton("0.01"),
        dest: launchpadAddress,
        body: confirmation,
    });
    confirmationMsg.send(SEND_MODE_REGULAR);
}

fun sendLaunchpadRegistrationAbort(launchpadAddress: address, marketId: uint32): void {
    val abort: AbortLaunchRegistration = { marketId };
    val abortMsg = createMessage({
        bounce: BounceMode.NoBounce,
        // The launchpad's abort refunds the creator's launchpad-held seed escrow via a jetton
        // transfer, so this registry-driven teardown must attach enough value to fund it (the
        // launchpad asserts inValue covers the refund send). 0.2 covers seedForwardValue + gas.
        value: ton("0.2"),
        dest: launchpadAddress,
        body: abort,
    });
    abortMsg.send(SEND_MODE_REGULAR);
}

fun requireAdmin(extra: StorageExtra, senderAddress: address) {
    assert (senderAddress == extra.admin) throw Errors.ADMIN_UNAUTHORIZED;
}

fun requireOperator(extra: StorageExtra, senderAddress: address) {
    assert (
        senderAddress == extra.admin || senderAddress == extra.operatorAddress
    ) throw Errors.ADMIN_UNAUTHORIZED;
}

// Operator autonomy: the config-level trusted launchpad is the single legitimate sender
// for market registration and the BONDING-state lifecycle entries (LIVE/TRIAL_EXPIRED).
fun requireLaunchpad(extra: StorageExtra, senderAddress: address) {
    val launchpadConfig = extra.launchpadConfig.load();
    assert (senderAddress == launchpadConfig.launchpadAddress) throw Errors.ADMIN_UNAUTHORIZED;
}

fun validateMarketRegistration(msg: RegisterMarket) {
    assert (msg.marketId > 0) throw Errors.NON_POSITIVE_AMOUNT;
    assert (msg.outcomeCount == 2) throw Errors.UNKNOWN_OUTCOME;
    assert (msg.deadline > msg.registeredAt) throw Errors.REGISTRY_TIMESTAMP_INVALID;
    assert (
        msg.trialEnd >= msg.registeredAt && msg.trialEnd <= msg.deadline
    ) throw Errors.REGISTRY_TIMESTAMP_INVALID;
}

fun validateFactoryMarketRegistration(msg: RegisterFactoryMarket) {
    assert (msg.marketId > 0) throw Errors.NON_POSITIVE_AMOUNT;
    assert (msg.outcomeCount == 2) throw Errors.UNKNOWN_OUTCOME;
    assert (msg.deadline > msg.registeredAt) throw Errors.REGISTRY_TIMESTAMP_INVALID;
    assert (
        msg.trialEnd >= msg.registeredAt && msg.trialEnd <= msg.deadline
    ) throw Errors.REGISTRY_TIMESTAMP_INVALID;
}

// EVM parity: LaunchpadEngine.setInvalidationBuffer requires
// 1 hours <= buffer <= 30 days (LaunchpadEngine.sol:199). The buffer is a deploy
// config value (no on-chain setter on TON), so it is validated at the first market
// lifecycle entry (registration) — the earliest point it can affect behaviour, and
// always before executeInvalidateMarket consumes it. 3600 == 1h, 2592000 == 30d.
fun validateRegistryConfig(storage: Storage) {
    assert (storage.invalidationBuffer >= 3600) throw Errors.REGISTRY_TIMESTAMP_INVALID;
    assert (storage.invalidationBuffer <= 2592000) throw Errors.REGISTRY_TIMESTAMP_INVALID;
}

fun validateLifecycle(lifecycle: uint8) {
    assert (lifecycle <= lifecycleSettled()) throw Errors.REGISTRY_LIFECYCLE_INVALID;
}

fun validateWinningOutcome(winningOutcome: uint8) {
    assert (winningOutcome <= invalidOutcome()) throw Errors.UNKNOWN_OUTCOME;
}

fun settlementVenueMask(
    market: MarketEntry,
    refs: MarketRefs,
    senderAddress: address,
    venue: uint8,
) {
    if (venue == settlementVenueAmm() && senderAddress == market.ammAddress) {
        return 1 as uint8;
    }
    if (venue == settlementVenueOrderEngine() && senderAddress == refs.engineAddress) {
        return 2 as uint8;
    }
    if (venue == settlementVenueBook() && senderAddress == refs.bookAddress) {
        return 4 as uint8;
    }
    if (venue == settlementVenueLaunchpad() && senderAddress == market.launchpadAddress) {
        return 8 as uint8;
    }
    return 0 as uint8;
}

fun orderbookActivationVenueMask(refs: MarketRefs, senderAddress: address, venue: uint8) {
    if (venue == settlementVenueOrderEngine() && senderAddress == refs.engineAddress) {
        return settlementVenueOrderEngineMask();
    }
    if (venue == settlementVenueBook() && senderAddress == refs.bookAddress) {
        return settlementVenueBookMask();
    }
    return 0 as uint8;
}

fun orderbookActivationBouncedMask(refs: MarketRefs, senderAddress: address) {
    if (senderAddress == refs.engineAddress) {
        return settlementVenueOrderEngineMask();
    }
    if (senderAddress == refs.bookAddress) {
        return settlementVenueBookMask();
    }
    return 0 as uint8;
}

fun settlementMaskHas(mask: uint8, bit: uint8) {
    return ((mask / bit) % 2) == 1;
}

fun setupMaskHas(mask: uint8, bit: uint8) {
    return ((mask / bit) % 2) == 1;
}

fun factorySetupMaskFor(
    market: MarketEntry,
    refs: MarketRefs,
    senderAddress: address,
    setup: uint8,
) {
    if (senderAddress == market.ammAddress && setup == factorySetupAmmWalletMask()) {
        return factorySetupAmmWalletMask();
    }
    if (senderAddress == market.ammAddress && setup == factorySetupAmmRouterMask()) {
        return factorySetupAmmRouterMask();
    }
    if (senderAddress == refs.engineAddress && setup == factorySetupEngineWalletMask()) {
        return factorySetupEngineWalletMask();
    }
    if (senderAddress == refs.engineAddress && setup == factorySetupEngineAmmWalletMask()) {
        return factorySetupEngineAmmWalletMask();
    }
    if (senderAddress == refs.bookAddress && setup == factorySetupBookEngineMask()) {
        return factorySetupBookEngineMask();
    }
    return 0 as uint8;
}

fun clearFactorySetupPending(
    mutate extra: StorageExtra,
    market: MarketEntry,
    refs: MarketRefs,
): void {
    extra.factorySetupPending.delete(market.ammAddress);
    extra.factorySetupPending.delete(refs.engineAddress);
    extra.factorySetupPending.delete(refs.bookAddress);
}

fun isValidTransition(current: uint8, next: uint8, winningOutcome: uint8) {
    if (current == lifecycleBonding()) {
        return next == lifecycleLive() || next == lifecycleTrialExpired();
    }
    if (current == lifecycleLive()) {
        if (next == lifecycleResolving()) {
            return true;
        }
        return next == lifecycleSettled() && winningOutcome == invalidOutcome();
    }
    if (current == lifecycleTrialExpired()) {
        return next == lifecycleSettled() && winningOutcome == invalidOutcome();
    }
    if (current == lifecycleResolving()) {
        if (next == lifecycleAttested() || next == lifecycleLive()) {
            return true;
        }
        return next == lifecycleSettled() && winningOutcome == invalidOutcome();
    }
    if (current == lifecycleAttested()) {
        return next == lifecycleSettled() || next == lifecycleLive();
    }
    return false;
}

fun emitRegistryEvent(
    kind: uint32,
    storage: Storage,
    marketId: uint32,
    actor: address,
    lifecycle: uint8,
    winningOutcome: uint8,
    aux: int64,
): void {
    val eventMsg = createExternalLogMessage({
        dest: ExtOutLogBucket { topic: kind as uint248 },
        body: SoothMarketRegistryEvent {
            kind,
            marketId,
            sequence: storage.sequence,
            actor,
            lifecycle,
            winningOutcome,
            aux,
        },
    });
    eventMsg.send(SEND_MODE_REGULAR);
}

// Lifecycle + INVALID-outcome helpers are shared via lifecycle.tolk (single source of truth).

fun settlementVenueAmm(): uint8 {
    return 1;
}

fun settlementVenueOrderEngine(): uint8 {
    return 2;
}

fun settlementVenueBook(): uint8 {
    return 3;
}

fun settlementVenueLaunchpad(): uint8 {
    return 4;
}

fun settlementVenueOrderEngineMask(): uint8 {
    return 2;
}

fun settlementVenueBookMask(): uint8 {
    return 4;
}

fun orderbookVenueAllMask(): uint8 {
    return 6;
}

fun settlementVenueAllMask(): uint8 {
    return 15;
}

fun factorySetupAmmWalletMask(): uint8 {
    return 1;
}

fun factorySetupAmmRouterMask(): uint8 {
    return 2;
}

fun factorySetupEngineWalletMask(): uint8 {
    return 4;
}

fun factorySetupBookEngineMask(): uint8 {
    return 8;
}

// H-1 fix: the engine confirms it received the AMM's collateral wallet (its taker-fee forward
// target) with this mask bit (matches the engine's factorySetupEngineAmmWalletMask).
fun factorySetupEngineAmmWalletMask(): uint8 {
    return 16;
}

fun factorySetupAllMask(): uint8 {
    // H-1 fix: 15 -> 31, adding the engine-AMM-wallet step (mask 16). The AMM-order-engine stamp
    // is sent by the LAUNCHPAD post-confirmation (RegistryLaunchConfirmed), so it is not a
    // registry-tracked setup step and is not part of this mask.
    return 31;
}

get fun registryState() {
    val storage = lazy Storage.load();
    val extra = storage.extra.load();
    val launchpadConfig = extra.launchpadConfig.load();
    return (
        storage.sequence,
        storage.marketCount,
        storage.defaultTrialPeriod,
        storage.invalidationBuffer,
        storage.paused,
        extra.admin,
        extra.pendingAdmin,
        extra.pendingAdminReadyAt,
        extra.operatorAddress,
        launchpadConfig.launchpadAddress,
    );
}

get fun market(marketId: uint32) {
    val storage = lazy Storage.load();
    val extra = storage.extra.load();
    val result = extra.markets.get(marketId);
    assert (result.isFound) throw Errors.REGISTRY_MARKET_NOT_FOUND;
    val market = result.loadValue();
    val refs = market.refs.load();
    val detail = refs.detail.load();
    return (
        marketId,
        market.ammAddress,
        refs.bookAddress,
        refs.engineAddress,
        refs.adjudicatorAddress,
        detail.collateralJettonMaster,
        detail.creator,
        market.launchpadAddress,
        market.lifecycle,
        market.outcomeCount,
        market.deadline,
        market.trialEnd,
        market.registeredAt,
        market.graduatedAt,
        market.settledAt,
        market.winningOutcome,
        market.tStar,
        market.activationConfirmationMask,
        market.activationFailureMask,
        market.settlementConfirmationMask,
        market.settlementFailureMask,
        market.factorySetupConfirmationMask,
    );
}
