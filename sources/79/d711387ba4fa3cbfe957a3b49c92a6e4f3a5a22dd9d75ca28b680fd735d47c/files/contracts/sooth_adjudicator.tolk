import "common.tolk"
import "errors.tolk"
import "lifecycle.tolk"

struct AdjudicatorMarketState {
    phase: uint8
    outcome: uint8
    tStar: int64
    deadline: int64
    vetoEndsAt: int64
    resolver: address
    dataHash: uint256
    configuredAt: int64
    settledAt: int64
}

struct AdjudicatorRouting {
    registryAddress: address?
    pendingAdmin: address?
    pendingAdminReadyAt: int64
}

struct StorageExtra {
    admin: address
    launchpadAddress: address
    // EVM AdjudicatorBase keeps a per-adjudicator guardian whitelist (mapping(address=>bool)),
    // not a single guardian. A guardian is approved iff its key is present; revoke deletes the
    // key. Any one approved guardian can dispute alone (simple whitelist, not an M-of-N threshold).
    guardians: map<address, int64>
    routing: Cell<AdjudicatorRouting>
    markets: map<uint32, AdjudicatorMarketState>
}

struct Storage {
    sequence: uint32
    marketCount: uint32
    vetoPeriod: int64
    // EVM parity (AdjudicatorBase.sol:127-133): resolve is rejected once
    // block.timestamp >= deadline + invalidationBuffer. The EVM reads the buffer from
    // TruthMarket.invalidationBuffer(); TON has no sync cross-contract read, so the
    // operator MUST set this consistent with the registry's invalidationBuffer
    // (cached-replica pattern, same as every other cross-contract value). Validated
    // >= 1h && <= 30d, mirroring the registry/launchpad buffer bound.
    invalidationBuffer: int64
    paused: bool
    extra: Cell<StorageExtra>
}

struct (0x736c6e63) SetLaunchpad {
    launchpadAddress: address
}

// EVM AdjudicatorBase.approveGuardian / revokeGuardian (owner-managed whitelist). Idempotent.
struct (0x61677561) AddGuardian {
    guardianAddress: address
}

struct (0x72677561) RemoveGuardian {
    guardianAddress: address
}

struct (0x73726567) SetRegistry {
    registryAddress: address?
}

// ProposeAdmin / AcceptAdmin / SetPaused structs are shared via common.tolk.

struct (0x6366676d) ConfigureMarket {
    marketId: uint32
    resolver: address
    deadline: int64
}

struct (0x7265736f) ResolveMarket {
    marketId: uint32
    outcome: uint8
    dataHash: uint256
    tStar: int64
}

struct (0x61747473) AttestMarket {
    marketId: uint32
}

struct (0x7365746c) SettleMarket {
    marketId: uint32
}

struct (0x64737074) DisputeMarket {
    marketId: uint32
}

struct (0x696e766c) InvalidateMarket {
    marketId: uint32
}

struct (0x6c696665) SetRegistryLifecycle {
    marketId: uint32
    lifecycle: uint8
    winningOutcome: uint8
    timestamp: int64
    tStar: int64
}

struct (0x73726f74) RegistryPostSettlementRoot {
    marketId: uint32
    merkleRoot: uint256
}

struct (0x70726f74) PostSettlementRoot {
    marketId: uint32
    merkleRoot: uint256
}

// EVM fee parity (2/2): the adjudicator's own trigger to claim its accrued fees from a
// market AMM. EVM-faithful self-claim: the AMM authes WithdrawAdjudicatorFees by
// senderAddress == its stamped adjudicatorAddress, so this adjudicator can only ever
// drain the markets whose adjudicatorAddress == this contract. We deliberately do NOT
// verify ammAddress <-> marketId here: a wrong ammAddress simply bounces at the AMM
// (sender mismatch or marketId mismatch). recipient is where the AMM forwards the
// collateral Jetton (EVM sends to the adjudicator; here it is caller-specified so the
// operator can sweep to a treasury wallet without an extra hop).
struct (0x636d6665) ClaimMarketFees {
    ammAddress: address
    marketId: uint32
    amount: coins
    recipient: address
    responseDestination: address
    queryId: uint64
    jettonTransferValue: coins
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

// Mirrors SoothAmm's WithdrawAdjudicatorFees (op 0x616a6665) byte-for-byte so the AMM
// parses it. Sent by executeClaimMarketFees.
struct (0x616a6665) WithdrawAdjudicatorFees {
    marketId: uint32
    amount: coins
    recipientOwner: address
    responseDestination: address
    queryId: uint64
    jettonTransferValue: coins
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

// The only outbound message this contract sends with RichBounce; named so onBouncedMessage
// can match it.
type AdjudicatorBounceMessage = WithdrawAdjudicatorFees

struct (0x61636366) AdjudicatorLaunchConfirmed {
    marketId: uint32
    configuredAt: int64
}

struct (0x61657674) SoothAdjudicatorEvent {
    kind: uint32
    marketId: uint32
    sequence: uint32
    actor: address
    phase: uint8
    outcome: uint8
    aux: int64
}

type AllowedMessage =
    | SetLaunchpad
    | AddGuardian
    | RemoveGuardian
    | SetRegistry
    | ProposeAdmin
    | AcceptAdmin
    | SetPaused
    | ConfigureMarket
    | ResolveMarket
    | AttestMarket
    | SettleMarket
    | DisputeMarket
    | InvalidateMarket
    | PostSettlementRoot
    | ClaimMarketFees

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
        SetLaunchpad => {
            executeSetLaunchpad(mutate storage, in.senderAddress, msg);
        }

        AddGuardian => {
            executeAddGuardian(mutate storage, in.senderAddress, msg);
        }

        RemoveGuardian => {
            executeRemoveGuardian(mutate storage, in.senderAddress, msg);
        }

        SetRegistry => {
            executeSetRegistry(mutate storage, in.senderAddress, msg);
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

        ConfigureMarket => {
            executeConfigureMarket(mutate storage, in.senderAddress, msg);
        }

        ResolveMarket => {
            executeResolveMarket(mutate storage, in.senderAddress, msg);
        }

        AttestMarket => {
            executeAttestMarket(mutate storage, in.senderAddress, msg);
        }

        SettleMarket => {
            executeSettleMarket(mutate storage, in.senderAddress, msg);
        }

        DisputeMarket => {
            executeDisputeMarket(mutate storage, in.senderAddress, msg);
        }

        InvalidateMarket => {
            executeInvalidateMarket(mutate storage, in.senderAddress, msg);
        }

        PostSettlementRoot => {
            executePostSettlementRoot(mutate storage, in.senderAddress, msg);
        }

        ClaimMarketFees => {
            executeClaimMarketFees(mutate storage, in.senderAddress, in.valueCoins, msg);
        }

        else => {
            assert (in.body.isEmpty()) throw 0xffff;
        }
    }
}

fun executeSetLaunchpad(mutate storage: Storage, senderAddress: address, msg: SetLaunchpad) {
    var extra = storage.extra.load();
    requireAdmin(extra, senderAddress);
    extra.launchpadAddress = msg.launchpadAddress;
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitAdjudicatorEvent(
        6,
        storage,
        0,
        senderAddress,
        phaseIdle(),
        invalidOutcome(),
        0,
    );
}

// EVM approveGuardian: owner-only, idempotent. aux=1 marks an approval in the event.
fun executeAddGuardian(mutate storage: Storage, senderAddress: address, msg: AddGuardian) {
    var extra = storage.extra.load();
    requireAdmin(extra, senderAddress);
    extra.guardians.set(msg.guardianAddress, 1);
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitAdjudicatorEvent(
        7,
        storage,
        0,
        senderAddress,
        phaseIdle(),
        invalidOutcome(),
        1,
    );
}

// EVM revokeGuardian: owner-only, idempotent, no last-guardian floor (an empty whitelist just
// means no one can dispute — matches EVM, which lets the owner revoke every guardian). aux=0.
fun executeRemoveGuardian(mutate storage: Storage, senderAddress: address, msg: RemoveGuardian) {
    var extra = storage.extra.load();
    requireAdmin(extra, senderAddress);
    extra.guardians.delete(msg.guardianAddress);
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitAdjudicatorEvent(
        7,
        storage,
        0,
        senderAddress,
        phaseIdle(),
        invalidOutcome(),
        0,
    );
}

fun executeSetRegistry(mutate storage: Storage, senderAddress: address, msg: SetRegistry) {
    var extra = storage.extra.load();
    requireAdmin(extra, senderAddress);
    var routing = extra.routing.load();
    routing.registryAddress = msg.registryAddress;
    storage.sequence += 1;
    extra.routing = routing.toCell();
    storage.extra = extra.toCell();
    storage.save();
    emitAdjudicatorEvent(
        9,
        storage,
        0,
        senderAddress,
        phaseIdle(),
        invalidOutcome(),
        0,
    );
}

fun executeProposeAdmin(mutate storage: Storage, senderAddress: address, msg: ProposeAdmin) {
    var extra = storage.extra.load();
    requireAdmin(extra, senderAddress);
    var routing = extra.routing.load();
    routing.pendingAdmin = msg.admin;
    routing.pendingAdminReadyAt = (blockchain.now() as int64) + 86400;
    storage.sequence += 1;
    extra.routing = routing.toCell();
    storage.extra = extra.toCell();
    storage.save();
    emitAdjudicatorEvent(
        11,
        storage,
        0,
        senderAddress,
        phaseIdle(),
        invalidOutcome(),
        0,
    );
}

fun executeAcceptAdmin(mutate storage: Storage, senderAddress: address) {
    var extra = storage.extra.load();
    var routing = extra.routing.load();
    assert (routing.pendingAdmin != null) throw Errors.TRADER_UNAUTHORIZED;
    assert (senderAddress == routing.pendingAdmin!) throw Errors.TRADER_UNAUTHORIZED;
    assert (blockchain.now() >= routing.pendingAdminReadyAt) throw Errors.PENDING_ADMIN_NOT_READY;
    extra.admin = senderAddress;
    routing.pendingAdmin = null;
    routing.pendingAdminReadyAt = 0;
    storage.sequence += 1;
    extra.routing = routing.toCell();
    storage.extra = extra.toCell();
    storage.save();
    emitAdjudicatorEvent(
        12,
        storage,
        0,
        senderAddress,
        phaseIdle(),
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
    emitAdjudicatorEvent(
        8,
        storage,
        0,
        senderAddress,
        phaseIdle(),
        invalidOutcome(),
        msg.paused ? 1 : 0,
    );
}

fun executeConfigureMarket(mutate storage: Storage, senderAddress: address, msg: ConfigureMarket) {
    var extra = storage.extra.load();
    requireLaunchpad(extra, senderAddress);
    requireNotPaused(storage.paused);
    validateAdjudicatorConfig(storage);
    assert (msg.marketId > 0) throw Errors.NON_POSITIVE_AMOUNT;
    assert (msg.deadline > 0) throw Errors.REGISTRY_TIMESTAMP_INVALID;
    val existing = extra.markets.get(msg.marketId);
    assert (existing.isFound == false) throw Errors.ADJUDICATOR_MARKET_EXISTS;

    val market: AdjudicatorMarketState = {
        phase: phaseActive(),
        outcome: invalidOutcome(),
        tStar: 0,
        deadline: msg.deadline,
        vetoEndsAt: 0,
        resolver: msg.resolver,
        dataHash: 0,
        configuredAt: blockchain.now() as int64,
        settledAt: 0,
    };
    extra.markets.set(msg.marketId, market);
    storage.marketCount += 1;
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitAdjudicatorEvent(
        1,
        storage,
        msg.marketId,
        senderAddress,
        phaseActive(),
        invalidOutcome(),
        market.configuredAt,
    );
    sendLaunchpadConfigurationConfirmation(
        extra.launchpadAddress,
        msg.marketId,
        market.configuredAt,
    );
}

fun executeResolveMarket(mutate storage: Storage, senderAddress: address, msg: ResolveMarket) {
    var extra = storage.extra.load();
    requireNotPaused(storage.paused);
    validateOutcome(msg.outcome);
    val result = extra.markets.get(msg.marketId);
    assert (result.isFound) throw Errors.ADJUDICATOR_MARKET_NOT_FOUND;
    var market = result.loadValue();
    assert (senderAddress == market.resolver) throw Errors.ADJUDICATOR_RESOLVER_UNAUTHORIZED;
    assert (
        market.phase == phaseActive() || market.phase == phaseDisputed()
    ) throw Errors.ADJUDICATOR_PHASE_INVALID;
    assert (msg.tStar >= 0) throw Errors.NON_POSITIVE_AMOUNT;
    if (msg.tStar > 0) {
        assert (msg.tStar <= blockchain.now()) throw Errors.TSTAR_OUT_OF_RANGE;
        assert (msg.tStar <= market.deadline) throw Errors.TSTAR_OUT_OF_RANGE;
    }
    // EVM parity (AdjudicatorBase.sol:127-133): reject resolution once
    // block.timestamp >= deadline + invalidationBuffer. Resolution legitimately
    // happens AFTER the trading deadline (the outcome becomes known then), so the
    // window is [start, deadline+buffer), NOT capped at deadline. EVM AdjudicatorBase.sol:128
    // SKIPS this window for infinite-deadline markets (the adjudicator can resolve forever) — the
    // explicit skip below matches that. (The sentinel sum is computed in TVM's 257-bit math and
    // does NOT overflow, so the bare assert would also pass; the skip documents the EVM intent.)
    // The buffer is a local cached replica of the registry's (no sync cross-contract read on TON)
    // — operator MUST keep them consistent. Its [1h,30d] bound is validated at ConfigureMarket.
    if (market.deadline != infiniteDeadline()) {
        assert (
            blockchain.now() < market.deadline + storage.invalidationBuffer
        ) throw Errors.ADJUDICATOR_DEADLINE_PASSED;
    }

    market.phase = phaseResolved();
    market.outcome = msg.outcome;
    market.tStar = msg.tStar;
    market.dataHash = msg.dataHash;
    market.vetoEndsAt = (blockchain.now() as int64) + storage.vetoPeriod;
    market.settledAt = 0;
    extra.markets.set(msg.marketId, market);
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitAdjudicatorEvent(
        2,
        storage,
        msg.marketId,
        senderAddress,
        phaseResolved(),
        msg.outcome,
        market.vetoEndsAt,
    );
    sendRegistryLifecycle(
        extra,
        msg.marketId,
        lifecycleResolving(),
        msg.outcome,
        blockchain.now() as int64,
        market.tStar,
    );
}

fun executeAttestMarket(mutate storage: Storage, senderAddress: address, msg: AttestMarket) {
    var extra = storage.extra.load();
    requireNotPaused(storage.paused);
    val result = extra.markets.get(msg.marketId);
    assert (result.isFound) throw Errors.ADJUDICATOR_MARKET_NOT_FOUND;
    var market = result.loadValue();
    assert (market.phase == phaseResolved()) throw Errors.ADJUDICATOR_PHASE_INVALID;

    market.phase = phaseAttested();
    extra.markets.set(msg.marketId, market);
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitAdjudicatorEvent(
        3,
        storage,
        msg.marketId,
        senderAddress,
        phaseAttested(),
        market.outcome,
        market.vetoEndsAt,
    );
    sendRegistryLifecycle(
        extra,
        msg.marketId,
        lifecycleAttested(),
        market.outcome,
        blockchain.now() as int64,
        market.tStar,
    );
}

fun executeSettleMarket(mutate storage: Storage, senderAddress: address, msg: SettleMarket) {
    var extra = storage.extra.load();
    requireNotPaused(storage.paused);
    val result = extra.markets.get(msg.marketId);
    assert (result.isFound) throw Errors.ADJUDICATOR_MARKET_NOT_FOUND;
    var market = result.loadValue();
    assert (market.phase == phaseAttested()) throw Errors.ADJUDICATOR_PHASE_INVALID;
    assert (blockchain.now() >= market.vetoEndsAt) throw Errors.ADJUDICATOR_VETO_NOT_ENDED;

    market.phase = phaseSettled();
    market.settledAt = blockchain.now() as int64;
    extra.markets.set(msg.marketId, market);
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitAdjudicatorEvent(
        4,
        storage,
        msg.marketId,
        senderAddress,
        phaseSettled(),
        market.outcome,
        market.settledAt,
    );
    sendRegistryLifecycle(
        extra,
        msg.marketId,
        lifecycleSettled(),
        market.outcome,
        market.settledAt,
        market.tStar,
    );
}

fun executeDisputeMarket(mutate storage: Storage, senderAddress: address, msg: DisputeMarket) {
    var extra = storage.extra.load();
    requireNotPaused(storage.paused);
    assert (
        extra.guardians.get(senderAddress).isFound
    ) throw Errors.ADJUDICATOR_GUARDIAN_UNAUTHORIZED;
    val result = extra.markets.get(msg.marketId);
    assert (result.isFound) throw Errors.ADJUDICATOR_MARKET_NOT_FOUND;
    var market = result.loadValue();
    assert (
        market.phase == phaseResolved() || market.phase == phaseAttested()
    ) throw Errors.ADJUDICATOR_PHASE_INVALID;
    assert (blockchain.now() < market.vetoEndsAt) throw Errors.ADJUDICATOR_VETO_ENDED;

    market.phase = phaseDisputed();
    market.outcome = invalidOutcome();
    market.tStar = 0;
    market.dataHash = 0;
    market.vetoEndsAt = 0;
    extra.markets.set(msg.marketId, market);
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitAdjudicatorEvent(
        5,
        storage,
        msg.marketId,
        senderAddress,
        phaseDisputed(),
        invalidOutcome(),
        blockchain.now() as int64,
    );
    sendRegistryLifecycle(
        extra,
        msg.marketId,
        lifecycleLive(),
        invalidOutcome(),
        blockchain.now() as int64,
        0,
    );
}

fun executeInvalidateMarket(
    mutate storage: Storage,
    senderAddress: address,
    msg: InvalidateMarket,
) {
    var extra = storage.extra.load();
    requireNotPaused(storage.paused);
    requireRegistry(extra, senderAddress);
    val result = extra.markets.get(msg.marketId);
    assert (result.isFound) throw Errors.ADJUDICATOR_MARKET_NOT_FOUND;
    var market = result.loadValue();
    assert (market.phase != phaseSettled()) throw Errors.ADJUDICATOR_PHASE_INVALID;

    market.phase = phaseSettled();
    market.outcome = invalidOutcome();
    market.tStar = 0;
    market.dataHash = 0;
    market.vetoEndsAt = 0;
    market.settledAt = blockchain.now() as int64;
    extra.markets.set(msg.marketId, market);
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitAdjudicatorEvent(
        10,
        storage,
        msg.marketId,
        senderAddress,
        phaseSettled(),
        invalidOutcome(),
        market.settledAt,
    );
}

fun executePostSettlementRoot(
    mutate storage: Storage,
    senderAddress: address,
    msg: PostSettlementRoot,
) {
    var extra = storage.extra.load();
    val result = extra.markets.get(msg.marketId);
    assert (result.isFound) throw Errors.ADJUDICATOR_MARKET_NOT_FOUND;
    val market = result.loadValue();
    // EVM parity (AdjudicatorBase.sol:235): the merkle root for market M can only be posted by
    // M's OWN resolver, not the adjudicator's global admin. Mirrors the executeResolve gate
    // (sooth_adjudicator.tolk:450) so root-posting authority lives per-market with the resolver.
    assert (senderAddress == market.resolver) throw Errors.ADJUDICATOR_RESOLVER_UNAUTHORIZED;
    assert (market.phase == phaseSettled()) throw Errors.ADJUDICATOR_PHASE_INVALID;
    assert (market.tStar > 0) throw Errors.ADJUDICATOR_TSTAR_INVALID;
    assert (msg.merkleRoot > 0) throw Errors.NON_POSITIVE_AMOUNT;
    val routing = extra.routing.load();
    assert (routing.registryAddress != null) throw Errors.REGISTRY_MARKET_NOT_FOUND;

    val rootMsg: RegistryPostSettlementRoot = {
        marketId: msg.marketId,
        merkleRoot: msg.merkleRoot,
    };
    val outMsg = createMessage({
        bounce: BounceMode.NoBounce,
        value: ton("0.05"),
        dest: routing.registryAddress!,
        body: rootMsg,
    });
    storage.sequence += 1;
    storage.save();
    emitAdjudicatorEvent(
        13,
        storage,
        msg.marketId,
        senderAddress,
        phaseSettled(),
        market.outcome,
        market.tStar,
    );
    outMsg.send(SEND_MODE_REGULAR);
}

// EVM fee parity (2/2): claim this adjudicator's accrued fees from a market AMM
// (EVM AMMEngine.claimAdjudicatorFees:587 — there the adjudicator calls the engine
// directly). Auth here is the adjudicator's own admin/operator (requireAdmin): the
// privileged operator decides WHEN to claim and WHERE the collateral lands. The AMM's
// senderAddress == adjudicatorAddress check is the REAL gate on WHICH market can be
// drained — only the AMM whose stamped adjudicatorAddress equals this contract will pay,
// so a wrong ammAddress simply bounces. We do not load/verify the local market entry
// for the same reason (the AMM is the source of truth on fee custody). The outbound
// WithdrawAdjudicatorFees is RichBounce so a rejecting AMM bounces back cleanly into
// onBouncedMessage (no adjudicator state was mutated, so the bounce is a safe no-op).
fun executeClaimMarketFees(
    mutate storage: Storage,
    senderAddress: address,
    inValue: coins,
    msg: ClaimMarketFees,
) {
    val extra = storage.extra.load();
    requireAdmin(extra, senderAddress);
    requireNotPaused(storage.paused);
    assert (msg.amount > 0) throw Errors.NON_POSITIVE_AMOUNT;
    assert (msg.amount <= 9223372036854775807) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
    assert (msg.jettonTransferValue > 0) throw Errors.NON_POSITIVE_AMOUNT;
    assert (msg.forwardTonAmount > 0) throw Errors.NON_POSITIVE_AMOUNT;
    val routeValue = msg.jettonTransferValue + ton("0.01");
    assert (inValue >= routeValue) throw Errors.INSUFFICIENT_MESSAGE_VALUE;

    storage.sequence += 1;
    storage.save();
    emitAdjudicatorEvent(
        14,
        storage,
        msg.marketId,
        senderAddress,
        phaseIdle(),
        invalidOutcome(),
        msg.amount as int64,
    );

    val withdraw: WithdrawAdjudicatorFees = {
        marketId: msg.marketId,
        amount: msg.amount,
        recipientOwner: msg.recipient,
        responseDestination: msg.responseDestination,
        queryId: msg.queryId,
        jettonTransferValue: msg.jettonTransferValue,
        forwardTonAmount: msg.forwardTonAmount,
        forwardPayload: msg.forwardPayload,
    };
    val withdrawMsg = createMessage({
        bounce: BounceMode.RichBounce,
        value: routeValue,
        dest: msg.ammAddress,
        body: withdraw,
    });
    withdrawMsg.send(SEND_MODE_REGULAR);
}

// EVM fee parity (2/2): a ClaimMarketFees that the target AMM rejected bounces back as
// the original WithdrawAdjudicatorFees body. executeClaimMarketFees mutated no custody
// state (it only forwards), so absorbing the bounce is correct — no restore needed. We
// parse it to confirm it is the message we sent; any other bounced body falls through
// (no-op) just like every other contract's unmatched-bounce path.
fun onBouncedMessage(in: InMessageBounced) {
    val rich = lazy RichBounceBody.fromSlice(in.bouncedBody);
    val bounced = lazy AdjudicatorBounceMessage.fromSlice(rich.originalBody.beginParse());
    match (bounced) {
        WithdrawAdjudicatorFees => {
            // No-op: the AMM rejected the claim and made no change; nothing to restore.
        }
    }
}

fun sendRegistryLifecycle(
    extra: StorageExtra,
    marketId: uint32,
    lifecycle: uint8,
    winningOutcome: uint8,
    timestamp: int64,
    tStar: int64,
): void {
    val routing = extra.routing.load();
    if (routing.registryAddress != null) {
        val registryMsg: SetRegistryLifecycle = {
            marketId,
            lifecycle,
            winningOutcome,
            timestamp,
            tStar,
        };
        val outMsg = createMessage({
            bounce: BounceMode.NoBounce,
            value: ton("0.05"),
            dest: routing.registryAddress!,
            body: registryMsg,
        });
        outMsg.send(SEND_MODE_REGULAR);
    }
}

fun sendLaunchpadConfigurationConfirmation(
    launchpadAddress: address,
    marketId: uint32,
    configuredAt: int64,
): void {
    val confirmation: AdjudicatorLaunchConfirmed = { marketId, configuredAt };
    val outMsg = createMessage({
        bounce: BounceMode.NoBounce,
        value: ton("0.01"),
        dest: launchpadAddress,
        body: confirmation,
    });
    outMsg.send(SEND_MODE_REGULAR);
}

fun requireAdmin(extra: StorageExtra, senderAddress: address) {
    assert (senderAddress == extra.admin) throw Errors.ADMIN_UNAUTHORIZED;
}

fun requireLaunchpad(extra: StorageExtra, senderAddress: address) {
    assert (
        senderAddress == extra.launchpadAddress
    ) throw Errors.ADJUDICATOR_LAUNCHPAD_UNAUTHORIZED;
}

fun requireRegistry(extra: StorageExtra, senderAddress: address) {
    val routing = extra.routing.load();
    assert (routing.registryAddress != null) throw Errors.ADJUDICATOR_REGISTRY_UNAUTHORIZED;
    assert (
        senderAddress == routing.registryAddress!
    ) throw Errors.ADJUDICATOR_REGISTRY_UNAUTHORIZED;
}

fun validateOutcome(outcome: uint8) {
    assert (outcome <= invalidOutcome()) throw Errors.UNKNOWN_OUTCOME;
}

// EVM parity: the resolve-deadline guard uses invalidationBuffer, which mirrors the
// registry's [1h,30d] bound (LaunchpadEngine.sol:199). Validated at ConfigureMarket
// — the adjudicator's per-market registration entry, before any market exists that
// the resolve guard could act on. 3600 == 1h, 2592000 == 30d.
fun validateAdjudicatorConfig(storage: Storage) {
    assert (storage.invalidationBuffer >= 3600) throw Errors.ADJUDICATOR_DEADLINE_PASSED;
    assert (storage.invalidationBuffer <= 2592000) throw Errors.ADJUDICATOR_DEADLINE_PASSED;
}

fun emitAdjudicatorEvent(
    kind: uint32,
    storage: Storage,
    marketId: uint32,
    actor: address,
    phase: uint8,
    outcome: uint8,
    aux: int64,
): void {
    val eventMsg = createExternalLogMessage({
        dest: ExtOutLogBucket { topic: kind as uint248 },
        body: SoothAdjudicatorEvent {
            kind,
            marketId,
            sequence: storage.sequence,
            actor,
            phase,
            outcome,
            aux,
        },
    });
    eventMsg.send(SEND_MODE_REGULAR);
}

fun phaseIdle(): uint8 {
    return 0;
}

fun phaseActive(): uint8 {
    return 1;
}

fun phaseResolved(): uint8 {
    return 2;
}

fun phaseAttested(): uint8 {
    return 3;
}

fun phaseSettled(): uint8 {
    return 4;
}

fun phaseDisputed(): uint8 {
    return 5;
}

// Lifecycle + INVALID-outcome helpers are shared via lifecycle.tolk (single source of truth).

get fun adjudicatorState() {
    val storage = lazy Storage.load();
    val extra = storage.extra.load();
    val routing = extra.routing.load();
    return (
        storage.sequence,
        storage.marketCount,
        storage.vetoPeriod,
        storage.invalidationBuffer,
        storage.paused,
        extra.admin,
        routing.pendingAdmin,
        routing.pendingAdminReadyAt,
        extra.launchpadAddress,
        routing.registryAddress,
    );
}

// EVM AdjudicatorBase.isGuardian: membership in the guardian whitelist. Replaces the single
// guardianAddress slot that adjudicatorState() used to expose (a map can't be flattened there).
get fun isGuardian(account: address): bool {
    val storage = lazy Storage.load();
    val extra = storage.extra.load();
    return extra.guardians.get(account).isFound;
}

get fun marketState(marketId: uint32) {
    val storage = lazy Storage.load();
    val extra = storage.extra.load();
    val result = extra.markets.get(marketId);
    assert (result.isFound) throw Errors.ADJUDICATOR_MARKET_NOT_FOUND;
    val market = result.loadValue();
    return (
        marketId,
        market.phase,
        market.outcome,
        market.tStar,
        market.deadline,
        market.vetoEndsAt,
        market.resolver,
        market.dataHash,
        market.configuredAt,
        market.settledAt,
    );
}

get fun canSettle(marketId: uint32) {
    val storage = lazy Storage.load();
    val extra = storage.extra.load();
    val result = extra.markets.get(marketId);
    if (result.isFound == false) {
        return false;
    }
    val market = result.loadValue();
    if (market.phase != phaseAttested()) {
        return false;
    }
    return blockchain.now() >= market.vetoEndsAt;
}

get fun adjudicatorType() {
    return 0;
}

get fun supportsTStar() {
    return true;
}
