import "common.tolk"
import "errors.tolk"
import "jetton.tolk"
import "lifecycle.tolk"

struct MarketLpJettonDetail {
    lpJettonMaster: address
    lpJettonWallet: address
    lpJettonEnabled: bool
}

struct MarketDetail {
    collateralJettonMaster: address
    creator: address
    lpJetton: Cell<MarketLpJettonDetail>
}

struct MarketRefs {
    bookAddress: address
    engineAddress: address
    adjudicatorAddress: address
    detail: Cell<MarketDetail>
}

struct MarketAccounting {
    lpBalances: map<address, int64>
}

struct (0x6c707273) LpYieldRestore {
    marketId: uint32
    trader: address
    lpAmount: int64
    payout: int64
    floorPayout: int64
}

struct (0x6c707274) LpTokenRedeemRestore {
    marketId: uint32
    trader: address
    lpAmount: int64
    payout: int64
    floorPayout: int64
    ledgerDebited: bool
}

// R2-1 S4b: bounce-restore payload for a failed seed forward (sent as the JettonTransfer
// customPayload). On bounce the launchpad clears seedForwarded so the escrow is logically
// rolled back and the market becomes abort-eligible (creator can refund + delete).
struct (0x73666272) SeedForwardRestore {
    marketId: uint32
    seed: int64
}

// R2-1 fix: bounce-restore payload for the abort escrow refund (creatorDeposit returned to the
// creator). The refund targets the creator's own collateral wallet (which funded the escrow),
// so it does not bounce in practice; on the rare bounce the jettons return to the launchpad's
// collateral wallet at the jetton level and the market is already deleted, so the handler is a
// no-op beyond observability. Carrying a recognized customPayload keeps the bounce dispatch
// exhaustive (avoids LAUNCHPAD_UNHANDLED_BRANCH).
struct (0x73726672) SeedEscrowRefundRestore {
    marketId: uint32
    creator: address
    amount: int64
}

// Creator liquidity top-up: bounce-restore payload for a failed top-up forward (the
// JettonTransfer customPayload, step 2 -> 3). On bounce the deposit returns to the
// launchpad's collateral wallet; we clear the pending top-up (topUpInFlight = false) so no
// LP is ever credited. Auth on bounce: the launchpad's own collateral jetton wallet.
struct (0x69726672) IncreaseReserveForwardRestore {
    marketId: uint32
    deposit: int64
}

type LpRedeemRestore =
    | LpYieldRestore
    | LpTokenRedeemRestore
    | SeedForwardRestore
    | SeedEscrowRefundRestore
    | IncreaseReserveForwardRestore

// Creator liquidity top-up (EVM AMMEngine.increaseLiquidityFromCreator parity): the
// in-flight top-up bookkeeping for a market, keyed by marketId. Presence in the
// pendingTopUps map == topUpInFlight for that market. Held in a NEW map on LpYieldCustody
// (NOT inlined into LpYieldMarket/LaunchpadMarket, which are near the 1023-bit cell limit).
struct PendingTopUp {
    additionalB: int64
    deposit: int64
}

struct LpYieldCustody {
    wallet: address
    collateralTotal: int64
    pendingAdmin: address?
    pendingAdminReadyAt: int64
    // Creator liquidity top-up: in-flight top-ups keyed by marketId. Empty at deploy. A
    // market is present here only between the verified creator deposit (step 2) and the
    // AMM's IncreaseReserve confirmation/bounce (commit/rollback in step 6 / bounce).
    pendingTopUps: map<uint32, PendingTopUp>
}

struct FactoryCodeHashesTail {
    engineCodeHash: uint256
    adjudicatorCodeHash: uint256
}

struct FactoryCodeHashes {
    ammCodeHash: uint256
    bookCodeHash: uint256
    tail: Cell<FactoryCodeHashesTail>
}

struct LpYieldMarket {
    collateral: int64
    adjudicatorFees: int64
    protocolFees: int64
    settledAt: int64
    winningOutcome: uint8
    lpSettlementFloorCollateral: int64
    lpSettlementFloorReported: bool
    registryConfirmedAt: int64
    adjudicatorConfirmedAt: int64
    creatorLpJettonMinted: bool
    // R2-1 S4: AMM-reserve seed orchestration (factory path only).
    // seedRequired: this market's AMM reserve must be seeded by the launchpad
    //   (set on FactoryCreateMarket creation; the AMM is freshly deployed with
    //   launchpadFeeRouter==launchpad once factory setup confirms).
    // seedForwarded: the escrowed seed jetton has been forwarded to the AMM's
    //   collateral wallet (set when the forward is dispatched; guards re-forward).
    // seedConfirmedAt: timestamp the AMM confirmed FactorySetupConfirmed{setup:16}.
    // The seed-forward destination is the AMM address itself (the recipient OWNER); the
    // launchpad's own collateral jetton wallet derives the AMM's wallet, so no AMM-wallet
    // field is stored here.
    seedRequired: bool
    seedForwarded: bool
    seedConfirmedAt: int64
    // R2-1 fix: true while the escrowed creator seed physically sits in the launchpad's own
    // collateral jetton wallet (so the launchpad can refund it on abort). Set true at creation
    // (creation is jetton-transfer-first, so the escrow is always in launchpad custody then);
    // set false once the seed is forwarded to the AMM; set true again only if the FORWARD
    // itself bounces (SeedForwardRestore returns the jettons here). A SeedReserve bounce leaves
    // it false — there the seed already landed on the AMM as the launchpad's trader-collateral
    // and is recovered by the operator via the AMM's WithdrawCollateral, not refunded here.
    seedHeldByLaunchpad: bool
    // Creator-set initial probability: the seed inventory (qYes, qNo) the launchpad derived
    // from initialProbabilityBps and used to size the seed. TON analogue of EVM
    // AMMEngine._seedQYes/_seedQNo. Both 0 at the default 50/50 (so existing markets store
    // (0, 0) and stay byte-identical). Stored for settlement/floor parity — though on TON
    // the LP-floor liability is computed from trader positions (traderYes/traderNo), so the
    // seed inventory is already excluded by construction (see report). Kept for audit/parity
    // and to record the on-chain seed shape a creator opened the market at.
    seedQYes: int64
    seedQNo: int64
}

struct LaunchpadMarket {
    ammAddress: address
    lifecycle: uint8
    outcomeCount: uint8
    startTime: int64
    deadline: int64
    trialEnd: int64
    bBase: int64
    creatorDeposit: int64
    feeAccrued: int64
    lpYield: Cell<LpYieldMarket>
    graduationThreshold: int64
    lpSupply: int64
    graduatedAt: int64
    expiredAt: int64
    refs: Cell<MarketRefs>
    accounting: Cell<MarketAccounting>
}

struct LaunchpadCollateralConfig {
    collateralJettonMaster: address
    collateralJettonWallet: address
    collateralDecimals: uint8
}

struct StorageExtra {
    admin: address
    operatorAddress: address
    registryAddress: address
    lpYield: Cell<LpYieldCustody>
    factoryCodeHashes: Cell<FactoryCodeHashes>
    collateralConfig: Cell<LaunchpadCollateralConfig>
    markets: map<uint32, LaunchpadMarket>
}

struct Storage {
    sequence: uint32
    marketCount: uint32
    defaultTrialPeriod: int64
    // EVM parity (FeeRouter graduationBps): this is the graduation ratio in basis points
    // (NOT an absolute threshold). The per-market graduation threshold is derived at creation
    // as creatorDeposit * graduationThreshold / 10000 (creatorDeposit == the bBase*ln2 seed),
    // so it scales with each market's liquidity depth instead of being a flat global constant.
    // 10000 == 100% of deposit (EVM default); the field keeps its historical name for ABI
    // stability but is now a bps ratio bounded to (0, 10000].
    graduationThreshold: int64
    paused: bool
    // EVM fee parity (1/2): operator-set protocol-level fee config (the EVM FeeRouter
    // singleton's config; TON has no such singleton so the launchpad holds it). The
    // rate pair (preGrad/postGrad numerators + shared denom) is snapshotted into each
    // AMM at creation (SDK stamps it into the AMM deploy data); operator rate changes
    // apply to FUTURE markets, like EVM snapshots graduationBps. The distribution bps
    // (bBase/lpYield/adjudicator/protocol == 10000) replace the hardcoded postGrad*Bps
    // constants and drive executeAccrueFees's post-grad split.
    preGradFeeNumerator: uint32
    postGradFeeNumerator: uint32
    feeDenominator: uint32
    bBaseBps: uint32
    lpYieldBps: uint32
    adjudicatorBps: uint32
    protocolBps: uint32
    extra: Cell<StorageExtra>
}

struct (0x736f7072) SetOperator {
    operatorAddress: address
}

// ProposeAdmin / AcceptAdmin / SetPaused structs are shared via common.tolk.

// EVM fee parity (1/2): operator-set protocol fee rates (EVM FeeRouter.setPreGradFee /
// setPostGradFee). Bounds: feeDenominator>0, both numerators<denominator, preGrad<=10%
// (pre*10<=den), postGrad<=5% (post*20<=den). Applies to FUTURE markets (snapshot at
// create); existing markets keep the rates stamped into their AMM at creation.
struct (0x73667274) SetFeeRates {
    preGradFeeNumerator: uint32
    postGradFeeNumerator: uint32
    feeDenominator: uint32
}

// EVM fee parity (1/2): operator-set post-graduation fee distribution (EVM
// FeeRouter.setFeeDistribution). The four shares MUST sum to 10000 bps
// (FeeRouter.sol:240 InvalidFeeDistribution) — this is the 100%-sum check.
struct (0x73666473) SetFeeDistribution {
    bBaseBps: uint32
    lpYieldBps: uint32
    adjudicatorBps: uint32
    protocolBps: uint32
}

struct (0x736c7079) SetLpYieldJettonWallet {
    wallet: address
}

// R2-1 S4b: configure the launchpad's collateral jetton wallet AFTER deploy. Breaks the
// deploy-time circularity (the launchpad's own jetton wallet address depends on the
// launchpad address, which would otherwise have to embed the wallet). Admin-only, and
// only while no markets exist (so it stays logically immutable once creation starts) —
// the EVM-immutable baseToken wallet is set exactly once at bring-up.
struct (0x736a6574) SetCollateralJettonWallet {
    wallet: address
}

// R2-1 fix: carries an op tag (0x6c797064 "lypd") so the JettonTransferNotification multiplex
// can distinguish post-graduation LP-yield collateral (routed back from the AMM to the
// launchpad's collateral wallet) from a market-creation seed by the forward-payload opcode
// rather than by sender wallet (which collides — the yield IS the collateral asset).
struct (0x6c797064) LpYieldDepositPayload {
    marketId: uint32
}

// HIGH fix (canon settlement-redemption.md:113-141): the AMM's DistributeLpFloor sweep stamps
// this op tag (0x73666c64 "sfld") on the floor jetton transfer so the collateral-wallet
// multiplex routes it to executeSettlementFloorDeposit (credit floor into marketYield.collateral
// + open settled-LP redemption), distinct from a live LP-yield deposit. Opcode mirrors the AMM.
struct (0x73666c64) SettlementFloorDepositPayload {
    marketId: uint32
}

struct (0x7362d09c) JettonTransferNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: cell?
}

// JettonTransfer struct (0x0f8a7ea5) is shared via jetton.tolk.

struct (0x6d696e74) MintJetton {
    owner: address
    amount: coins
    responseDestination: address
    forwardTonAmount: coins
}

struct (0x595f07bc) BurnJetton {
    queryId: uint64
    amount: coins
    responseDestination: address
    customPayload: cell?
}

struct LpJettonRedeemPayload {
    marketId: uint32
    recipientOwner: address
    responseDestination: address
    queryId: uint64
    jettonTransferValue: coins
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

struct (0x6c707966) RouteLaunchpadYield {
    marketId: uint32
    amount: coins
    bBaseAmount: coins
    adjudicatorAmount: coins
    protocolAmount: coins
    recipientOwner: address
    responseDestination: address
    queryId: uint64
    jettonTransferValue: coins
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

// EVM fee parity (FeeRouter._distributePreGrad): the AMM-bound pre-grad curve deepen. The
// bonding-trade fee already lives in the AMM's feeCollateral; the launchpad computes
// deltaB == floor(fee * fixedScale / ln2Fixed) (== EVM `fee * LN2_INV_WAD / WAD` == fee/ln2)
// and sends this pure-accounting message so the AMM banks `collateral` (== fee) into reserve
// and deepens b by `deltaB` via its shared deepenCurveFromFee helper. Mirrors the post-grad
// RouteLaunchpadYield bBase share, which the AMM also deepens. Op tag matches the AMM struct.
struct (0x64706e62) DeepenFromBondingFee {
    marketId: uint32
    collateral: coins
    deltaB: coins
}

// R2-1 S4: collateralJettonMaster is now read from deploy-config storage
// (EVM-immutable baseToken), so it is no longer a per-market input.
struct CreateMarketDetail {
    lpJettonMaster: address
    lpJettonWallet: address
    lpJettonEnabled: bool
}

struct CreateMarketExtra {
    bookAddress: address
    engineAddress: address
    adjudicatorAddress: address
    detail: Cell<CreateMarketDetail>
}

struct ComponentDeployConfig {
    value: coins
    code: cell
    data: cell
}

struct FactoryCreateMarketComponents {
    ammDeploy: Cell<ComponentDeployConfig>
    bookDeploy: Cell<ComponentDeployConfig>
    engineDeploy: Cell<ComponentDeployConfig>
    // Adjudicator was previously deployed alongside AMM/Book/Engine; it is now
    // PRE-EXISTING — the creator passes its address in FactoryCreateMarketExtra
    // below. Matches the EVM pattern where each market plugs in an oracle /
    // adjudicator address chosen at creation time, and saves ~0.12 TON per
    // market by not deploying a fresh adjudicator contract.
}

struct FactoryCreateMarketExtra {
    components: Cell<FactoryCreateMarketComponents>
    // Pre-existing adjudicator (deployed once, reused by many markets). The
    // launchpad does NOT validate the code at this address — it is the creator's
    // choice, same trust model as EVM where the creator names the resolver. The
    // AMM authes incoming SettleMarket by senderAddress == adjudicatorAddress,
    // so a misconfigured / malicious address simply can't settle the market.
    adjudicatorAddress: address
    detail: Cell<CreateMarketDetail>
}

struct RegistryMarketDetail {
    collateralJettonMaster: address
    creator: address
}

struct RegistryFactoryConfig {
    ammCollateralJettonWallet: address
    engineCollateralJettonWallet: address
}

struct RegistryFactoryMarketDetail {
    collateralJettonMaster: address
    creator: address
    config: Cell<RegistryFactoryConfig>
}

struct RegistryRegisterMarketExtra {
    bookAddress: address
    engineAddress: address
    adjudicatorAddress: address
    detail: Cell<RegistryMarketDetail>
}

struct RegistryRegisterFactoryMarketExtra {
    bookAddress: address
    engineAddress: address
    adjudicatorAddress: address
    detail: Cell<RegistryFactoryMarketDetail>
}

// R2-1 S4: CreateMarket / FactoryCreateMarket are no longer bare top-level
// messages. Creation is jetton-transfer-first: the creator sends the escrowed
// seed collateral to the launchpad's collateralJettonWallet with one of these
// structs as the forward payload. creatorDeposit is removed (it is the verified
// escrowed jetton amount == mulLn2(bBase)); collateralJettonMaster is read from
// deploy-config. The op tag still discriminates the two creation variants.
// Creator-set initial probability: `initialProbabilityBps` (basis points, 5000 == 50%)
// is the YES probability the creator wants the market to open at. 0 is the default-50/50
// sentinel (== 5000) so every existing payload (which never set it) stays byte-identical
// to today's 50/50 market. The launchpad DERIVES (qYes, qNo) and the seed from it; the
// caller never supplies inventory. uint32 is well within the root cell budget here.
struct (0x6c63726d) CreateMarketPayload {
    marketId: uint32
    ammAddress: address
    outcomeCount: uint8
    startTime: int64
    deadline: int64
    bBase: int64
    initialProbabilityBps: uint32
    extra: Cell<CreateMarketExtra>
}

struct (0x66636d6b) FactoryCreateMarketPayload {
    marketId: uint32
    outcomeCount: uint8
    startTime: int64
    deadline: int64
    bBase: int64
    initialProbabilityBps: uint32
    ammCollateralJettonWallet: address
    engineCollateralJettonWallet: address
    extra: Cell<FactoryCreateMarketExtra>
}

type CreateMarketForwardPayload = CreateMarketPayload | FactoryCreateMarketPayload

// Creator liquidity top-up (EVM AMMEngine.increaseLiquidityFromCreator parity): the
// forward payload the creator attaches to a jetton transfer of depositRequired to the
// launchpad's collateralJettonWallet. Discriminated from creation/yield deposits by its
// op tag (0x696e636c "incl") in executeJettonTransferNotification's multiplex.
struct (0x696e636c) IncreaseLiquidityPayload {
    marketId: uint32
    additionalB: int64
}

struct (0x61626f72) AbortUnconfirmedLaunch {
    marketId: uint32
}

struct (0x7265676d) RegisterMarket {
    marketId: uint32
    ammAddress: address
    outcomeCount: uint8
    deadline: int64
    trialEnd: int64
    registeredAt: int64
    extra: Cell<RegistryRegisterMarketExtra>
}

struct (0x72666d6b) RegisterFactoryMarket {
    marketId: uint32
    ammAddress: address
    outcomeCount: uint8
    deadline: int64
    trialEnd: int64
    registeredAt: int64
    extra: Cell<RegistryRegisterFactoryMarketExtra>
}

struct (0x6366676d) ConfigureAdjudicatorMarket {
    marketId: uint32
    resolver: address
    deadline: int64
}

struct (0x6c696665) SetRegistryLifecycle {
    marketId: uint32
    lifecycle: uint8
    winningOutcome: uint8
    timestamp: int64
    tStar: int64
}

struct (0x61666565) AccrueFees {
    marketId: uint32
    trader: address
    amount: int64
}

struct (0x6c66636e) LaunchpadFeeRouteConfirmed {
    marketId: uint32
    trader: address
    amount: int64
    launchpadSequence: uint32
}

// EVM fee parity (1/2): OUTBOUND graduation signal to the market's AMM (op matches the
// AMM's inbound SetAmmGraduated, 0x73677264). Sent once, when willGraduate flips true, so
// the AMM switches preGrad -> postGrad fee. The AMM handler is idempotent (no-op if
// already graduated) and authorized to the launchpad fee router, so a retry is safe.
struct (0x73677264) SetAmmGraduated {
    marketId: uint32
}

// EVM parity: OUTBOUND trial-expiry trading halt to the market's AMM (op matches the AMM's
// inbound HaltTrading, 0x68616c74). Sent from ExpireTrial so the AMM stops accepting trades on
// a market that expired its trial without graduating, mirroring the SetAmmGraduated push.
struct (0x68616c74) HaltTrading {
    marketId: uint32
}

// EVM fee parity (2/2): OUTBOUND stamp of the configured adjudicator into the market's
// AMM (op matches the AMM's inbound SetAdjudicatorAddress, 0x73616a61). Sent once from
// executeRegistryLaunchConfirmed — by then the registry's factory setup has wired the
// AMM's launchpadFeeRouter == launchpad, which is exactly the gate the AMM uses to
// accept this. Lets the adjudicator self-claim its fees (AMM authes WithdrawAdjudicatorFees
// by senderAddress == adjudicatorAddress). RichBounce; a bounce is absorbed (see send site).
struct (0x73616a61) SetAdjudicatorAddress {
    marketId: uint32
    adjudicatorAddress: address
}

// H-1 fix: OUTBOUND stamp of the market's order engine into the AMM (op matches the AMM's
// inbound SetAmmOrderEngine, 0x73616f65). Sent once from executeRegistryLaunchConfirmed
// alongside SetAdjudicatorAddress — by then the AMM's launchpadFeeRouter == launchpad, the gate
// the AMM uses to accept this. It tells the AMM the engine identity so the AMM can classify an
// engine-fee deposit (msg.sender == orderEngine) and route it through the post-grad split.
struct (0x73616f65) SetAmmOrderEngine {
    marketId: uint32
    orderEngine: address
}

// Finding 2 (LOW) fix: operator-gated break-glass re-send of the SetAmmOrderEngine wiring stamp.
// sendAmmSetOrderEngine is NoBounce and fired exactly once (while registryConfirmedAt == 0) and
// is excluded from the factory-setup mask, so a lost message is undetected and leaves the AMM's
// claimAuth.orderEngine == null — an engine-fee deposit would then misclassify as a normal trader
// deposit. This op lets the operator re-stamp the engine into the market's AMM. Mirrors the
// resendAmmSetGraduated break-glass precedent (operator-gated, re-uses sendAmmSetOrderEngine).
struct (0x72736f65) ResendAmmSetOrderEngine {
    marketId: uint32
}

struct (0x65787072) ExpireTrial {
    marketId: uint32
}

struct (0x6c73746c) SettleMarket {
    marketId: uint32
    winningOutcome: uint8
    timestamp: int64
}

struct (0x73636f6e) SettlementConfirmed {
    marketId: uint32
    venue: uint8
    winningOutcome: uint8
    venueSequence: uint32
}

struct (0x6c70666c) RecordLpSettlementFloor {
    marketId: uint32
    floorCollateral: int64
}

struct (0x6c707478) TransferLp {
    marketId: uint32
    recipient: address
    lpAmount: coins
}

struct (0x6c707972) RedeemLp {
    marketId: uint32
    lpAmount: coins
    recipientOwner: address
    responseDestination: address
    queryId: uint64
    jettonTransferValue: coins
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

struct (0x72656366) RegistryLaunchConfirmed {
    marketId: uint32
    registeredAt: int64
}

struct (0x61636366) AdjudicatorLaunchConfirmed {
    marketId: uint32
    configuredAt: int64
}

// R2-1 S4b: the AMM acks the launchpad-router's seed deposit landing (op 0x7365616b
// "seak", matching SoothAmm's SeedCollateralAck). Inbound only on the launchpad; the
// handler fires SeedReserve so the (1-hop SeedReserve / 3-hop deposit) race is gone.
struct (0x7365616b) SeedCollateralAck {
    marketId: uint32
}

// R2-1 S4b: the launchpad's SeedReserve op (op 0x73656564 "seed", matching SoothAmm's
// SeedReserve). Sent to the AMM on the ack; the AMM auth-gates it to launchpadFeeRouter
// (== this launchpad), promoting the escrowed seed trader-collateral into reserve.
struct (0x73656564) SeedReserve {
    marketId: uint32
    amount: coins
}

// Creator liquidity top-up: OUTBOUND IncreaseReserve to the market's AMM (op 0x696e6372
// "incr", matching SoothAmm's IncreaseReserve). Sent on the IncreaseReserveAck; the AMM
// auth-gates it to launchpadFeeRouter (== this launchpad), promotes `amount` of the
// router's trader-collateral into reserve and deepens the curve by `additionalB`.
struct (0x696e6372) IncreaseReserve {
    marketId: uint32
    amount: coins
    additionalB: coins
}

// Creator liquidity top-up: the AMM acks the launchpad-router's top-up deposit landing at
// reserve>0 (op 0x696e616b "inak", matching SoothAmm's IncreaseReserveAck). Inbound only;
// the handler fires IncreaseReserve, making the (1-hop reserve / 3-hop deposit) race-free.
struct (0x696e616b) IncreaseReserveAck {
    marketId: uint32
}

// R2-1 S4b: the AMM confirms it promoted the escrowed seed into reserveCollateral
// by emitting FactorySetupConfirmed{setup:16} back to the launchpad (the AMM's
// SeedReserve handler sends this to its caller == the launchpad/router). Same op
// (0x66636f6e) and field layout as the registry's FactorySetupConfirmed.
struct (0x66636f6e) FactorySetupConfirmed {
    marketId: uint32
    setup: uint8
    venueSequence: uint32
}

struct (0x6c657674) SoothLaunchpadEvent {
    kind: uint32
    marketId: uint32
    sequence: uint32
    actor: address
    lifecycle: uint8
    amount: int64
    aux: int64
}

type AllowedMessage =
    | SetOperator
    | ProposeAdmin
    | AcceptAdmin
    | SetPaused
    | SetFeeRates
    | SetFeeDistribution
    | SetLpYieldJettonWallet
    | SetCollateralJettonWallet
    | JettonTransferNotification
    | AbortUnconfirmedLaunch
    | AccrueFees
    | ResendAmmSetOrderEngine
    | ExpireTrial
    | SettleMarket
    | RecordLpSettlementFloor
    | TransferLp
    | RedeemLp
    | RegistryLaunchConfirmed
    | AdjudicatorLaunchConfirmed
    | FactorySetupConfirmed
    | SeedCollateralAck
    | IncreaseReserveAck

type LaunchpadBounceMessage =
    | JettonTransfer
    | ConfigureAdjudicatorMarket
    | RegisterMarket
    | RegisterFactoryMarket
    | SeedReserve
    | IncreaseReserve
    | SetAmmGraduated

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

        ProposeAdmin => {
            executeProposeAdmin(mutate storage, in.senderAddress, msg);
        }

        AcceptAdmin => {
            executeAcceptAdmin(mutate storage, in.senderAddress);
        }

        SetPaused => {
            executeSetPaused(mutate storage, in.senderAddress, msg);
        }

        SetFeeRates => {
            executeSetFeeRates(mutate storage, in.senderAddress, msg);
        }

        SetFeeDistribution => {
            executeSetFeeDistribution(mutate storage, in.senderAddress, msg);
        }

        SetLpYieldJettonWallet => {
            executeSetLpYieldJettonWallet(mutate storage, in.senderAddress, msg);
        }

        SetCollateralJettonWallet => {
            executeSetCollateralJettonWallet(mutate storage, in.senderAddress, msg);
        }

        JettonTransferNotification => {
            executeJettonTransferNotification(mutate storage, in.senderAddress, in.valueCoins, msg);
        }

        AbortUnconfirmedLaunch => {
            executeAbortUnconfirmedLaunch(mutate storage, in.senderAddress, in.valueCoins, msg);
        }

        AccrueFees => {
            executeAccrueFees(mutate storage, in.senderAddress, in.valueCoins, msg);
        }

        ResendAmmSetOrderEngine => {
            executeResendAmmSetOrderEngine(mutate storage, in.senderAddress, msg);
        }

        ExpireTrial => {
            executeExpireTrial(mutate storage, in.senderAddress, msg);
        }

        SettleMarket => {
            executeSettleMarket(mutate storage, in.senderAddress, msg);
        }

        RecordLpSettlementFloor => {
            executeRecordLpSettlementFloor(mutate storage, in.senderAddress, msg);
        }

        TransferLp => {
            executeTransferLp(mutate storage, in.senderAddress, msg);
        }

        RedeemLp => {
            executeRedeemLp(mutate storage, in.senderAddress, in.valueCoins, msg);
        }

        RegistryLaunchConfirmed => {
            executeRegistryLaunchConfirmed(mutate storage, in.senderAddress, msg);
        }

        AdjudicatorLaunchConfirmed => {
            executeAdjudicatorLaunchConfirmed(mutate storage, in.senderAddress, msg);
        }

        FactorySetupConfirmed => {
            executeFactorySetupConfirmed(mutate storage, in.senderAddress, msg);
        }

        SeedCollateralAck => {
            executeSeedCollateralAck(mutate storage, in.senderAddress, msg);
        }

        IncreaseReserveAck => {
            executeIncreaseReserveAck(mutate storage, in.senderAddress, msg);
        }

        else => {
            assert (in.body.isEmpty()) throw 0xffff;
        }
    }
}

fun onBouncedMessage(in: InMessageBounced) {
    var storage = lazy Storage.load();
    var extra = storage.extra.load();
    var lpYield = extra.lpYield.load();

    val rich = lazy RichBounceBody.fromSlice(in.bouncedBody);
    val bounced = lazy LaunchpadBounceMessage.fromSlice(rich.originalBody.beginParse());
    match (bounced) {
        JettonTransfer => {
            val restore = lazy LpRedeemRestore.fromCell(bounced.customPayload!);
            match (restore) {
                LpYieldRestore => {
                    assert (in.senderAddress == lpYield.wallet) throw Errors.JETTON_WALLET_MISMATCH;
                    assert (
                        bounced.amount == restore.payout
                    ) throw Errors.LAUNCHPAD_BOUNCE_RESTORE_MISMATCH;
                    val result = extra.markets.get(restore.marketId);
                    assert (result.isFound) throw Errors.LAUNCHPAD_MARKET_NOT_FOUND;
                    var market = result.loadValue();
                    var accounting = market.accounting.load();
                    val currentBalance = lpBalanceFor(accounting, restore.trader);
                    assert (
                        currentBalance <= 9223372036854775807 - restore.lpAmount
                    ) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
                    assert (
                        market.lpSupply <= 9223372036854775807 - restore.lpAmount
                    ) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
                    var marketYield = market.lpYield.load();
                    restoreLpYield(
                        mutate marketYield,
                        mutate lpYield,
                        restore.payout,
                        restore.floorPayout,
                    );

                    accounting.lpBalances.set(restore.trader, currentBalance + restore.lpAmount);
                    market.lpSupply += restore.lpAmount;
                    market.lpYield = marketYield.toCell();
                    market.accounting = accounting.toCell();
                    extra.lpYield = lpYield.toCell();
                    extra.markets.set(restore.marketId, market);
                    storage.sequence += 1;
                    storage.extra = extra.toCell();
                    storage.save();
                    emitLaunchpadEvent(
                        10,
                        storage,
                        restore.marketId,
                        restore.trader,
                        market.lifecycle,
                        restore.payout,
                        restore.lpAmount,
                    );
                }

                LpTokenRedeemRestore => {
                    assert (in.senderAddress == lpYield.wallet) throw Errors.JETTON_WALLET_MISMATCH;
                    assert (
                        bounced.amount == restore.payout
                    ) throw Errors.LAUNCHPAD_BOUNCE_RESTORE_MISMATCH;
                    val result = extra.markets.get(restore.marketId);
                    assert (result.isFound) throw Errors.LAUNCHPAD_MARKET_NOT_FOUND;
                    var market = result.loadValue();
                    val refs = market.refs.load();
                    val detail = refs.detail.load();
                    val lpToken = detail.lpJetton.load();
                    assert (lpToken.lpJettonEnabled) throw Errors.LAUNCHPAD_LP_JETTON_MODE_MISMATCH;
                    assert (
                        market.lpSupply <= 9223372036854775807 - restore.lpAmount
                    ) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
                    var marketYield = market.lpYield.load();
                    restoreLpYield(
                        mutate marketYield,
                        mutate lpYield,
                        restore.payout,
                        restore.floorPayout,
                    );

                    if (restore.ledgerDebited) {
                        var accounting = market.accounting.load();
                        val currentBalance = lpBalanceFor(accounting, restore.trader);
                        assert (
                            currentBalance <= 9223372036854775807 - restore.lpAmount
                        ) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
                        accounting
                            .lpBalances
                            .set(restore.trader, currentBalance + restore.lpAmount);
                        market.accounting = accounting.toCell();
                    }
                    market.lpSupply += restore.lpAmount;
                    market.lpYield = marketYield.toCell();
                    extra.lpYield = lpYield.toCell();
                    extra.markets.set(restore.marketId, market);
                    storage.sequence += 1;
                    storage.extra = extra.toCell();
                    storage.save();
                    sendLpJettonMintIfConfigured(
                        lpToken,
                        restore.trader,
                        restore.lpAmount as coins,
                    );
                    emitLaunchpadEvent(
                        10,
                        storage,
                        restore.marketId,
                        restore.trader,
                        market.lifecycle,
                        restore.payout,
                        restore.lpAmount,
                    );
                }

                // R2-1 S4b: the seed forward to the AMM bounced. The bounced jetton
                // transfer returns the seed to the launchpad's collateral wallet (escrow
                // intact on-chain); we clear seedForwarded so the market is logically back
                // to "unseeded" and AbortUnconfirmedLaunch can refund the creator + delete
                // it. Auth: the bounce must originate from the launchpad's own collateral
                // jetton wallet, not the LP-yield wallet.
                SeedForwardRestore => {
                    val collateralConfig = extra.collateralConfig.load();
                    assert (
                        in.senderAddress == collateralConfig.collateralJettonWallet
                    ) throw Errors.JETTON_WALLET_MISMATCH;
                    val result = extra.markets.get(restore.marketId);
                    assert (result.isFound) throw Errors.LAUNCHPAD_MARKET_NOT_FOUND;
                    var market = result.loadValue();
                    var marketYield = market.lpYield.load();
                    if (marketYield.seedForwarded && marketYield.seedConfirmedAt == 0) {
                        marketYield.seedForwarded = false;
                        // The forward bounced: the jettons have returned to the launchpad's
                        // collateral wallet, so the escrow is launchpad-refundable again.
                        marketYield.seedHeldByLaunchpad = true;
                        market.lpYield = marketYield.toCell();
                        extra.markets.set(restore.marketId, market);
                        storage.sequence += 1;
                        storage.extra = extra.toCell();
                        storage.save();
                        emitLaunchpadEvent(
                            23,
                            storage,
                            restore.marketId,
                            market.ammAddress,
                            market.lifecycle,
                            restore.seed,
                            0,
                        );
                    }
                }

                SeedEscrowRefundRestore => {
                    // The abort escrow refund bounced. The jettons have already returned to the
                    // launchpad's collateral wallet at the jetton level and the market is gone,
                    // so there is no state to restore — a no-op beyond the bounce event. Auth:
                    // the bounce must originate from the launchpad's own collateral wallet.
                    assert (
                        in.senderAddress == extra.collateralConfig.load().collateralJettonWallet
                    ) throw Errors.JETTON_WALLET_MISMATCH;
                    emitLaunchpadEvent(
                        18,
                        storage,
                        restore.marketId,
                        restore.creator,
                        lifecycleBonding(),
                        restore.amount,
                        0,
                    );
                }

                // Creator liquidity top-up: the top-up forward to the AMM bounced (step 2 ->
                // 3). The deposit returned to the launchpad's collateral wallet; clear the
                // pending top-up so topUpInFlight is false and no LP is ever credited. The
                // deposit is recoverable by the operator at the launchpad's collateral wallet.
                // Auth: the bounce must originate from the launchpad's own collateral wallet.
                IncreaseReserveForwardRestore => {
                    assert (
                        in.senderAddress == extra.collateralConfig.load().collateralJettonWallet
                    ) throw Errors.JETTON_WALLET_MISMATCH;
                    val pending = lpYield.pendingTopUps.get(restore.marketId);
                    if (pending.isFound) {
                        lpYield.pendingTopUps.delete(restore.marketId);
                        extra.lpYield = lpYield.toCell();
                        storage.sequence += 1;
                        storage.extra = extra.toCell();
                        storage.save();
                        emitLaunchpadEvent(
                            31,
                            storage,
                            restore.marketId,
                            in.senderAddress,
                            lifecycleLive(),
                            restore.deposit,
                            0,
                        );
                    }
                }

                else => {
                    assert (false) throw Errors.LAUNCHPAD_UNHANDLED_BRANCH;
                }
            }
        }

        ConfigureAdjudicatorMarket => {
            executeLaunchSetupBounced(mutate storage, in.senderAddress, bounced.marketId, true);
        }

        RegisterMarket => {
            executeLaunchSetupBounced(mutate storage, in.senderAddress, bounced.marketId, false);
        }

        RegisterFactoryMarket => {
            executeLaunchSetupBounced(mutate storage, in.senderAddress, bounced.marketId, false);
        }

        // R2-1 S4b: SeedReserve bounced at the AMM (e.g. reserve became non-zero before
        // promotion). The seed still sits as the launchpad's trader-collateral in the AMM;
        // we clear seedForwarded so the launch is abort-eligible and route to the abort/
        // refund recovery (executeSeedReserveBounced). Auth: must come from this market's
        // AMM (the only valid SeedReserve recipient).
        SeedReserve => {
            executeSeedReserveBounced(mutate storage, in.senderAddress, bounced.marketId);
        }

        // Creator liquidity top-up: IncreaseReserve bounced at the AMM (step 4 -> 5). The
        // deposit still sits as the launchpad's trader-collateral at the AMM (operator-
        // recoverable via WithdrawCollateral, like the SeedReserve bounce); clear the pending
        // top-up so no LP is credited and the market is consistent. Auth: must come from this
        // market's AMM (the only valid IncreaseReserve recipient).
        IncreaseReserve => {
            executeIncreaseReserveBounced(mutate storage, in.senderAddress, bounced.marketId);
        }

        // EVM fee parity (1/2): the graduation signal bounced at the AMM. Re-send once
        // (NoBounce, loop-free) so the AMM still learns it graduated. Auth: must come from
        // this market's AMM (the only valid SetAmmGraduated recipient).
        SetAmmGraduated => {
            executeSetGraduatedBounced(in.senderAddress, bounced.marketId);
        }
    }
}

// R2-1 S4b: SeedReserve-bounce recovery. The seed was credited to the launchpad's AMM
// trader-ledger (by the deposit) but not promoted into reserve (the bounce). Clearing
// seedForwarded reopens the abort path; AbortUnconfirmedLaunch then deletes the market.
// The seed is recoverable from the AMM as the launchpad's trader-collateral via a
// WithdrawCollateral (operator-driven), so no funds are orphaned. Idempotent.
fun executeSeedReserveBounced(mutate storage: Storage, senderAddress: address, marketId: uint32) {
    var extra = storage.extra.load();
    val result = extra.markets.get(marketId);
    if (result.isFound) {
        var market = result.loadValue();
        assert (senderAddress == market.ammAddress) throw Errors.ADMIN_UNAUTHORIZED;
        var marketYield = market.lpYield.load();
        if (marketYield.seedForwarded && marketYield.seedConfirmedAt == 0) {
            marketYield.seedForwarded = false;
            market.lpYield = marketYield.toCell();
            extra.markets.set(marketId, market);
            storage.sequence += 1;
            storage.extra = extra.toCell();
            storage.save();
            emitLaunchpadEvent(
                24,
                storage,
                marketId,
                senderAddress,
                market.lifecycle,
                market.creatorDeposit,
                0,
            );
        }
    }
}

// EVM fee parity (1/2): graduation-signal bounce recovery. The market is already Live in
// the launchpad (graduation is committed); only the AMM's fee-rate switch is at stake.
// We re-send the signal once (NoBounce, loop-free) and DO NOT mutate launchpad state
// (no sequence bump, no event) so the recovery is invisible to the canonical state/event
// surface — it is a pure best-effort re-delivery. Auth: must come from this market's AMM.
// Residual risk noted in the report — if even this retry fails to land, the AMM keeps the
// preGrad rate (a higher fee for traders, never a fund loss) pending a manual operator
// re-send.
fun executeSetGraduatedBounced(senderAddress: address, marketId: uint32) {
    val storage = lazy Storage.load();
    val extra = storage.extra.load();
    val result = extra.markets.get(marketId);
    if (result.isFound) {
        val market = result.loadValue();
        assert (senderAddress == market.ammAddress) throw Errors.ADMIN_UNAUTHORIZED;
        resendAmmSetGraduated(market.ammAddress, marketId);
    }
}

// Finding 2 (LOW) fix: operator-gated re-send of the SetAmmOrderEngine wiring stamp. The original
// send (sendAmmSetOrderEngine, fired once while registryConfirmedAt == 0) is NoBounce and outside
// the factory-setup mask, so a lost message silently leaves the AMM's claimAuth.orderEngine ==
// null and engine-fee deposits misclassify. This break-glass re-send recovers it. Operator-gated
// like the SetFeeRates/SetFeeDistribution ops. Re-uses the same NoBounce helper, so no new state
// and no event (a pure best-effort re-delivery, matching the resendAmmSetGraduated precedent).
fun executeResendAmmSetOrderEngine(
    mutate storage: Storage,
    senderAddress: address,
    msg: ResendAmmSetOrderEngine,
) {
    val extra = storage.extra.load();
    requireOperator(extra, senderAddress);
    val result = extra.markets.get(msg.marketId);
    assert (result.isFound) throw Errors.LAUNCHPAD_MARKET_NOT_FOUND;
    val market = result.loadValue();
    val refs = market.refs.load();
    sendAmmSetOrderEngine(market.ammAddress, msg.marketId, refs.engineAddress);
}

fun executeSetOperator(mutate storage: Storage, senderAddress: address, msg: SetOperator) {
    var extra = storage.extra.load();
    requireAdmin(extra, senderAddress);
    extra.operatorAddress = msg.operatorAddress;
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitLaunchpadEvent(
        5,
        storage,
        0,
        senderAddress,
        lifecycleBonding(),
        0,
        0,
    );
}

fun executeProposeAdmin(mutate storage: Storage, senderAddress: address, msg: ProposeAdmin) {
    var extra = storage.extra.load();
    requireAdmin(extra, senderAddress);
    var lpYield = extra.lpYield.load();
    lpYield.pendingAdmin = msg.admin;
    lpYield.pendingAdminReadyAt = (blockchain.now() as int64) + 86400;
    storage.sequence += 1;
    extra.lpYield = lpYield.toCell();
    storage.extra = extra.toCell();
    storage.save();
    emitLaunchpadEvent(
        19,
        storage,
        0,
        senderAddress,
        lifecycleBonding(),
        0,
        0,
    );
}

fun executeAcceptAdmin(mutate storage: Storage, senderAddress: address) {
    var extra = storage.extra.load();
    var lpYield = extra.lpYield.load();
    assert (lpYield.pendingAdmin != null) throw Errors.TRADER_UNAUTHORIZED;
    assert (senderAddress == lpYield.pendingAdmin!) throw Errors.TRADER_UNAUTHORIZED;
    assert (blockchain.now() >= lpYield.pendingAdminReadyAt) throw Errors.PENDING_ADMIN_NOT_READY;
    extra.admin = senderAddress;
    lpYield.pendingAdmin = null;
    lpYield.pendingAdminReadyAt = 0;
    storage.sequence += 1;
    extra.lpYield = lpYield.toCell();
    storage.extra = extra.toCell();
    storage.save();
    emitLaunchpadEvent(
        20,
        storage,
        0,
        senderAddress,
        lifecycleBonding(),
        0,
        0,
    );
}

fun executeSetPaused(mutate storage: Storage, senderAddress: address, msg: SetPaused) {
    val extra = storage.extra.load();
    requireAdmin(extra, senderAddress);
    storage.paused = msg.paused;
    storage.sequence += 1;
    storage.save();
    emitLaunchpadEvent(
        6,
        storage,
        0,
        senderAddress,
        lifecycleBonding(),
        0,
        msg.paused ? 1 : 0,
    );
}

// EVM fee parity (1/2): operator-set protocol fee rates. Mirrors EVM
// FeeRouter.setPreGradFee (feeBps<=1000 == 10%) + setPostGradFee (feeBps<=500 == 5%),
// expressed as numerator/denominator: preGrad*10<=den, postGrad*20<=den. Both numerators
// must be < denominator and denominator > 0 (FEE_POLICY_INVALID). Snapshot semantics: the
// new rates apply to FUTURE markets (the SDK stamps the current rates into the AMM at
// creation); already-created markets keep the rates baked into their AMM.
fun executeSetFeeRates(mutate storage: Storage, senderAddress: address, msg: SetFeeRates) {
    val extra = storage.extra.load();
    requireOperator(extra, senderAddress);
    assert (msg.feeDenominator > 0) throw Errors.FEE_POLICY_INVALID;
    assert (msg.preGradFeeNumerator < msg.feeDenominator) throw Errors.FEE_POLICY_INVALID;
    assert (msg.postGradFeeNumerator < msg.feeDenominator) throw Errors.FEE_POLICY_INVALID;
    assert (msg.preGradFeeNumerator * 10 <= msg.feeDenominator) throw Errors.FEE_POLICY_INVALID;
    assert (msg.postGradFeeNumerator * 20 <= msg.feeDenominator) throw Errors.FEE_POLICY_INVALID;
    storage.preGradFeeNumerator = msg.preGradFeeNumerator;
    storage.postGradFeeNumerator = msg.postGradFeeNumerator;
    storage.feeDenominator = msg.feeDenominator;
    storage.sequence += 1;
    storage.save();
    emitLaunchpadEvent(
        26,
        storage,
        0,
        senderAddress,
        lifecycleBonding(),
        msg.preGradFeeNumerator as int64,
        msg.postGradFeeNumerator as int64,
    );
}

// EVM fee parity (1/2): operator-set post-graduation fee distribution. Mirrors EVM
// FeeRouter.setFeeDistribution: the four shares MUST sum to 10000 bps
// (FeeRouter.sol:240-244 InvalidFeeDistribution) — the 100%-sum check. This guarantees
// executeAccrueFees's post-grad split (toProtocol = amount - others) stays >= 0.
fun executeSetFeeDistribution(
    mutate storage: Storage,
    senderAddress: address,
    msg: SetFeeDistribution,
) {
    val extra = storage.extra.load();
    requireOperator(extra, senderAddress);
    assert (
        msg.bBaseBps + msg.lpYieldBps + msg.adjudicatorBps + msg.protocolBps == feeBpsDenominator()
    ) throw Errors.LAUNCHPAD_FEE_DISTRIBUTION_INVALID;
    storage.bBaseBps = msg.bBaseBps;
    storage.lpYieldBps = msg.lpYieldBps;
    storage.adjudicatorBps = msg.adjudicatorBps;
    storage.protocolBps = msg.protocolBps;
    storage.sequence += 1;
    storage.save();
    emitLaunchpadEvent(
        27,
        storage,
        0,
        senderAddress,
        lifecycleBonding(),
        msg.bBaseBps as int64,
        msg.protocolBps as int64,
    );
}

fun executeSetLpYieldJettonWallet(
    mutate storage: Storage,
    senderAddress: address,
    msg: SetLpYieldJettonWallet,
) {
    var extra = storage.extra.load();
    var lpYield = extra.lpYield.load();
    requireAdmin(extra, senderAddress);
    assert (lpYield.collateralTotal == 0) throw Errors.LAUNCHPAD_COLLATERAL_OUTSTANDING;
    lpYield.wallet = msg.wallet;
    extra.lpYield = lpYield.toCell();
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitLaunchpadEvent(
        9,
        storage,
        0,
        senderAddress,
        lifecycleBonding(),
        0,
        0,
    );
}

// R2-1 S4b: one-time bring-up setter for the launchpad's collateral jetton wallet (the
// EVM-immutable baseToken wallet). Admin-only, allowed only before any market exists, so
// the verified-creation gate (sender == collateralJettonWallet) is stable thereafter.
fun executeSetCollateralJettonWallet(
    mutate storage: Storage,
    senderAddress: address,
    msg: SetCollateralJettonWallet,
) {
    var extra = storage.extra.load();
    requireAdmin(extra, senderAddress);
    assert (storage.marketCount == 0) throw Errors.LAUNCHPAD_COLLATERAL_OUTSTANDING;
    var collateralConfig = extra.collateralConfig.load();
    collateralConfig.collateralJettonWallet = msg.wallet;
    extra.collateralConfig = collateralConfig.toCell();
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitLaunchpadEvent(
        25,
        storage,
        0,
        senderAddress,
        lifecycleBonding(),
        0,
        0,
    );
}

// R2-1 S4a: non-factory creation, driven by a verified collateral jetton transfer.
// creatorDeposit == the escrowed seed (== mulLn2(bBase), asserted by the caller),
// collateralJettonMaster sourced from deploy-config. The AMM is caller-supplied
// (pre-deployed/pre-configured) so the launchpad does NOT auto-seed it here
// (seedRequired := false); the escrow is held in launchpad custody, refundable.
fun executeCreateMarket(
    mutate storage: Storage,
    creatorAddress: address,
    inValue: coins,
    creatorDeposit: int64,
    seedQYes: int64,
    seedQNo: int64,
    collateralJettonMaster: address,
    msg: CreateMarketPayload,
) {
    val msgExtra = msg.extra.load();
    val msgDetail = msgExtra.detail.load();
    val detail: MarketDetail = {
        collateralJettonMaster,
        creator: creatorAddress,
        lpJetton: MarketLpJettonDetail {
            lpJettonMaster: msgDetail.lpJettonMaster,
            lpJettonWallet: msgDetail.lpJettonWallet,
            lpJettonEnabled: msgDetail.lpJettonEnabled,
        }.toCell(),
    };
    val refs: MarketRefs = {
        bookAddress: msgExtra.bookAddress,
        engineAddress: msgExtra.engineAddress,
        adjudicatorAddress: msgExtra.adjudicatorAddress,
        detail: detail.toCell(),
    };
    val market = recordCreatedMarket(
        mutate storage,
        creatorAddress,
        inValue,
        0,
        msg.marketId,
        msg.ammAddress,
        msg.outcomeCount,
        msg.startTime,
        msg.deadline,
        msg.bBase,
        creatorDeposit,
        seedQYes,
        seedQNo,
        refs,
        detail,
        msgDetail.lpJettonEnabled,
        false,
    );
    val extra = storage.extra.load();
    sendRegistryRegistration(extra.registryAddress, msg.marketId, market, refs, detail);
    sendAdjudicatorConfiguration(
        msgExtra.adjudicatorAddress,
        msg.marketId,
        creatorAddress,
        msg.deadline,
    );
    sendLpJettonMintIfConfigured(
        detail.lpJetton.load(),
        creatorAddress,
        creatorDeposit as coins,
    );
    emitLaunchpadEvent(
        1,
        storage,
        msg.marketId,
        creatorAddress,
        lifecycleBonding(),
        creatorDeposit,
        market.trialEnd,
    );
}

// R2-1 S4a/S4b: factory creation, driven by a verified collateral jetton transfer.
// Deploys fresh AMM/book/engine/adjudicator, registers via the factory path (which
// wires the AMM's collateral wallet + launchpadFeeRouter==launchpad), and arms the
// seed handoff (seedRequired := true): once the registry confirms factory setup,
// executeRegistryLaunchConfirmed forwards the escrowed seed and dispatches SeedReserve.
fun executeFactoryCreateMarket(
    mutate storage: Storage,
    creatorAddress: address,
    inValue: coins,
    creatorDeposit: int64,
    seedQYes: int64,
    seedQNo: int64,
    collateralJettonMaster: address,
    msg: FactoryCreateMarketPayload,
) {
    val msgExtra = msg.extra.load();
    val components = msgExtra.components.load();
    val ammDeploy = components.ammDeploy.load();
    val bookDeploy = components.bookDeploy.load();
    val engineDeploy = components.engineDeploy.load();
    val extra = storage.extra.load();
    val factoryCodeHashes = extra.factoryCodeHashes.load();
    val factoryCodeHashesTail = factoryCodeHashes.tail.load();
    validateComponentDeploy(ammDeploy, factoryCodeHashes.ammCodeHash);
    validateComponentDeploy(bookDeploy, factoryCodeHashes.bookCodeHash);
    validateComponentDeploy(engineDeploy, factoryCodeHashesTail.engineCodeHash);
    // Adjudicator code-hash validation intentionally dropped: the adjudicator
    // is pre-existing and supplied as an address (see FactoryCreateMarketExtra
    // and the EVM-parity comment there). factoryCodeHashesTail.adjudicatorCodeHash
    // is no longer read here but is retained in storage so the registered ABI /
    // on-chain inspectability doesn't shift under callers reading factoryCodeHashes.

    val workchain = contract.getAddress().getWorkchain();
    val ammAutoDeploy = calculateComponentDeploy(ammDeploy, workchain);
    val bookAutoDeploy = calculateComponentDeploy(bookDeploy, workchain);
    val engineAutoDeploy = calculateComponentDeploy(engineDeploy, workchain);
    val ammAddress = ammAutoDeploy.calculateAddress();
    val bookAddress = bookAutoDeploy.calculateAddress();
    val engineAddress = engineAutoDeploy.calculateAddress();
    val adjudicatorAddress = msgExtra.adjudicatorAddress;

    val msgDetail = msgExtra.detail.load();
    val detail: MarketDetail = {
        collateralJettonMaster,
        creator: creatorAddress,
        lpJetton: MarketLpJettonDetail {
            lpJettonMaster: msgDetail.lpJettonMaster,
            lpJettonWallet: msgDetail.lpJettonWallet,
            lpJettonEnabled: msgDetail.lpJettonEnabled,
        }.toCell(),
    };
    val refs: MarketRefs = {
        bookAddress,
        engineAddress,
        adjudicatorAddress,
        detail: detail.toCell(),
    };
    val requiredValue = requiredFactoryCreateMarketValue(
        ammDeploy,
        bookDeploy,
        engineDeploy,
    );
    val market = recordCreatedMarket(
        mutate storage,
        creatorAddress,
        inValue,
        requiredValue,
        msg.marketId,
        ammAddress,
        msg.outcomeCount,
        msg.startTime,
        msg.deadline,
        msg.bBase,
        creatorDeposit,
        seedQYes,
        seedQNo,
        refs,
        detail,
        false,
        // R2-1 S4b: factory path arms the launchpad-driven AMM-reserve seed.
        true,
    );

    sendFactoryComponentDeploy(ammAutoDeploy, ammDeploy.value);
    sendFactoryComponentDeploy(bookAutoDeploy, bookDeploy.value);
    sendFactoryComponentDeploy(engineAutoDeploy, engineDeploy.value);
    // Adjudicator deploy intentionally NOT sent: it's pre-existing (passed by
    // address in FactoryCreateMarketExtra). Saves ~0.12 TON per market.
    sendRegistryFactoryRegistration(
        extra.registryAddress,
        msg.marketId,
        market,
        refs,
        detail,
        msg.ammCollateralJettonWallet,
        msg.engineCollateralJettonWallet,
    );
    sendFactoryAdjudicatorConfiguration(
        adjudicatorAddress,
        msg.marketId,
        creatorAddress,
        msg.deadline,
    );
    emitLaunchpadEvent(
        1,
        storage,
        msg.marketId,
        creatorAddress,
        lifecycleBonding(),
        creatorDeposit,
        market.trialEnd,
    );
}

fun recordCreatedMarket(
    mutate storage: Storage,
    creatorAddress: address,
    inValue: coins,
    minimumValue: coins,
    marketId: uint32,
    ammAddress: address,
    outcomeCount: uint8,
    startTime: int64,
    deadline: int64,
    bBase: int64,
    creatorDeposit: int64,
    seedQYes: int64,
    seedQNo: int64,
    refs: MarketRefs,
    detail: MarketDetail,
    creatorLpJettonMinted: bool,
    seedRequired: bool,
): LaunchpadMarket {
    var extra = storage.extra.load();
    requireNotPaused(storage.paused);
    validateCreateMarketFields(
        storage,
        marketId,
        outcomeCount,
        startTime,
        deadline,
        bBase,
        creatorDeposit,
    );
    val existing = extra.markets.get(marketId);
    assert (existing.isFound == false) throw Errors.LAUNCHPAD_MARKET_EXISTS;

    var lpBalances: map<address, int64> = [];
    lpBalances.set(creatorAddress, creatorDeposit);
    val accounting: MarketAccounting = { lpBalances };
    val lpJetton = detail.lpJetton.load();
    if (lpJetton.lpJettonEnabled) {
        assert (
            inValue >= minimumValue + createMarketLpJettonValue()
        ) throw Errors.INSUFFICIENT_MESSAGE_VALUE;
    } else {
        assert (inValue >= minimumValue) throw Errors.INSUFFICIENT_MESSAGE_VALUE;
    }
    val trialEnd = computeTrialEnd(storage, startTime, deadline);
    // Per-market graduation threshold = creatorDeposit * graduationBps / 10000 (frozen at creation).
    // Integer division can truncate to 0 with a tiny deposit + low bps (a 0-decimal collateral at
    // graduationBps==1, or a fast-graduation config like deposit=100 @ 2bps): that simply means the
    // market graduates on the first fee accrual (instant graduation) — a valid creator choice, not
    // forbidden. For any normal token (decimals >= 6) the product dwarfs 10000.
    val graduationThresholdAbs = (creatorDeposit * storage.graduationThreshold) /
    feeBpsDenominator();
    val market: LaunchpadMarket = {
        ammAddress,
        lifecycle: lifecycleBonding(),
        outcomeCount,
        startTime,
        deadline,
        trialEnd,
        bBase,
        creatorDeposit,
        feeAccrued: 0,
        lpYield: LpYieldMarket {
            collateral: 0,
            adjudicatorFees: 0,
            protocolFees: 0,
            settledAt: 0,
            winningOutcome: invalidOutcome(),
            lpSettlementFloorCollateral: 0,
            lpSettlementFloorReported: false,
            registryConfirmedAt: 0,
            adjudicatorConfirmedAt: 0,
            creatorLpJettonMinted,
            seedRequired,
            seedForwarded: false,
            seedConfirmedAt: 0,
            // Creation is jetton-transfer-first: the verified seed escrow is in launchpad
            // custody at this point (refundable on abort) for both factory and non-factory.
            seedHeldByLaunchpad: true,
            // Creator-set initial probability: the derived seed inventory (0/0 at 50/50).
            seedQYes,
            seedQNo,
        }.toCell(),
        graduationThreshold: graduationThresholdAbs,
        lpSupply: creatorDeposit,
        graduatedAt: 0,
        expiredAt: 0,
        refs: refs.toCell(),
        accounting: accounting.toCell(),
    };

    extra.markets.set(marketId, market);
    storage.marketCount += 1;
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    return market;
}

fun executeAbortUnconfirmedLaunch(
    mutate storage: Storage,
    senderAddress: address,
    inValue: coins,
    msg: AbortUnconfirmedLaunch,
) {
    var extra = storage.extra.load();
    val result = extra.markets.get(msg.marketId);
    assert (result.isFound) throw Errors.LAUNCHPAD_MARKET_NOT_FOUND;
    val market = result.loadValue();
    val refs = market.refs.load();
    val detail = refs.detail.load();
    assert (
        senderAddress == detail.creator || senderAddress == extra.admin ||
        senderAddress == extra.operatorAddress ||
        senderAddress == extra.registryAddress
    ) throw Errors.ADMIN_UNAUTHORIZED;

    val marketYield = market.lpYield.load();
    val accounting = market.accounting.load();
    val lpToken = detail.lpJetton.load();
    // R2-1 S4b: a seed-required market whose seed never reached reserve (seedConfirmedAt==0)
    // and is not in-flight (seedForwarded==false, e.g. after a forward/SeedReserve bounce)
    // is abort-eligible EVEN if registry+adjudicator setup completed — the AMM reserve is
    // provably 0, so deleting + refunding the escrow is sound. Otherwise the pre-confirmation
    // window (registry OR adjudicator not yet confirmed) gates the abort as before.
    val seedBounceAbortEligible = marketYield.seedRequired && marketYield.seedConfirmedAt == 0 &&
    marketYield.seedForwarded == false;
    assert (
        marketYield.registryConfirmedAt == 0 || marketYield.adjudicatorConfirmedAt == 0 ||
        seedBounceAbortEligible
    ) throw Errors.LAUNCHPAD_PURGE_PRECONDITION;
    // LP jettons, once minted to the creator, are irreversible here -> never abort a
    // tokenized launch whose creator LP was already minted (holds for the seed-bounce path
    // too: a tokenized seed market only mints LP after BOTH confirmations, so a tokenized
    // seed bounce that already minted LP is NOT abort-eligible).
    assert (
        lpToken.lpJettonEnabled == false || marketYield.creatorLpJettonMinted == false
    ) throw Errors.LAUNCHPAD_PURGE_PRECONDITION;
    assert (market.lifecycle == lifecycleBonding()) throw Errors.LAUNCHPAD_PURGE_PRECONDITION;
    assert (market.feeAccrued == 0) throw Errors.LAUNCHPAD_PURGE_PRECONDITION;
    assert (market.lpSupply == market.creatorDeposit) throw Errors.LAUNCHPAD_PURGE_PRECONDITION;
    assert (
        lpBalanceFor(accounting, detail.creator) == market.creatorDeposit
    ) throw Errors.LAUNCHPAD_PURGE_PRECONDITION;
    assert (marketYield.collateral == 0) throw Errors.LAUNCHPAD_PURGE_PRECONDITION;
    assert (marketYield.adjudicatorFees == 0) throw Errors.LAUNCHPAD_PURGE_PRECONDITION;
    assert (marketYield.protocolFees == 0) throw Errors.LAUNCHPAD_PURGE_PRECONDITION;
    assert (marketYield.settledAt == 0) throw Errors.LAUNCHPAD_PURGE_PRECONDITION;
    assert (marketYield.lpSettlementFloorCollateral == 0) throw Errors.LAUNCHPAD_PURGE_PRECONDITION;
    assert (
        marketYield.lpSettlementFloorReported == false
    ) throw Errors.LAUNCHPAD_PURGE_PRECONDITION;
    assert (storage.marketCount > 0) throw Errors.LAUNCHPAD_PURGE_PRECONDITION;

    // R2-1 fix: refund the escrowed seed to the creator if it is still in launchpad custody.
    // Creation is jetton-transfer-first, so the verified creatorDeposit collateral is escrowed
    // in the launchpad's own collateral wallet (seedHeldByLaunchpad); deleting the market
    // without returning it would strand the escrow permanently. seedHeldByLaunchpad is false
    // only when the seed was forwarded to the AMM (and not bounced back) — there the escrow is
    // recovered operator-side via the AMM's WithdrawCollateral, so no launchpad refund here.
    val refundEscrow = marketYield.seedHeldByLaunchpad && market.creatorDeposit > 0;
    if (refundEscrow) {
        assert (
            inValue >= seedForwardValue() + ton("0.02")
        ) throw Errors.INSUFFICIENT_MESSAGE_VALUE;
    }
    val collateralWallet = extra.collateralConfig.load().collateralJettonWallet;

    extra.markets.delete(msg.marketId);
    storage.marketCount -= 1;
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitLaunchpadEvent(
        18,
        storage,
        msg.marketId,
        senderAddress,
        lifecycleBonding(),
        refundEscrow ? market.creatorDeposit : 0,
        0,
    );
    if (refundEscrow) {
        sendSeedEscrowRefund(
            collateralWallet,
            msg.marketId,
            detail.creator,
            market.creatorDeposit,
        );
    }
    if (marketYield.registryConfirmedAt > 0) {
        sendRegistryLaunchAbort(extra.registryAddress, msg.marketId);
    }
}

fun executeLaunchSetupBounced(
    mutate storage: Storage,
    senderAddress: address,
    marketId: uint32,
    notifyRegistryOnAbort: bool,
) {
    var extra = storage.extra.load();
    val result = extra.markets.get(marketId);
    if (result.isFound) {
        val market = result.loadValue();
        val refs = market.refs.load();
        val detail = refs.detail.load();
        assert (
            senderAddress == extra.registryAddress || senderAddress == refs.adjudicatorAddress
        ) throw Errors.ADMIN_UNAUTHORIZED;

        val marketYield = market.lpYield.load();
        val accounting = market.accounting.load();
        val lpToken = detail.lpJetton.load();
        assert (
            marketYield.registryConfirmedAt == 0 || marketYield.adjudicatorConfirmedAt == 0
        ) throw Errors.LAUNCHPAD_PURGE_PRECONDITION;
        assert (
            lpToken.lpJettonEnabled == false || marketYield.creatorLpJettonMinted == false
        ) throw Errors.LAUNCHPAD_PURGE_PRECONDITION;
        assert (market.lifecycle == lifecycleBonding()) throw Errors.LAUNCHPAD_PURGE_PRECONDITION;
        assert (market.feeAccrued == 0) throw Errors.LAUNCHPAD_PURGE_PRECONDITION;
        assert (market.lpSupply == market.creatorDeposit) throw Errors.LAUNCHPAD_PURGE_PRECONDITION;
        assert (
            lpBalanceFor(accounting, detail.creator) == market.creatorDeposit
        ) throw Errors.LAUNCHPAD_PURGE_PRECONDITION;
        assert (marketYield.collateral == 0) throw Errors.LAUNCHPAD_PURGE_PRECONDITION;
        assert (marketYield.adjudicatorFees == 0) throw Errors.LAUNCHPAD_PURGE_PRECONDITION;
        assert (marketYield.protocolFees == 0) throw Errors.LAUNCHPAD_PURGE_PRECONDITION;
        assert (marketYield.settledAt == 0) throw Errors.LAUNCHPAD_PURGE_PRECONDITION;
        assert (
            marketYield.lpSettlementFloorCollateral == 0
        ) throw Errors.LAUNCHPAD_PURGE_PRECONDITION;
        assert (
            marketYield.lpSettlementFloorReported == false
        ) throw Errors.LAUNCHPAD_PURGE_PRECONDITION;
        assert (storage.marketCount > 0) throw Errors.LAUNCHPAD_PURGE_PRECONDITION;

        extra.markets.delete(marketId);
        storage.marketCount -= 1;
        storage.sequence += 1;
        storage.extra = extra.toCell();
        storage.save();
        emitLaunchpadEvent(
            18,
            storage,
            marketId,
            senderAddress,
            lifecycleBonding(),
            0,
            0,
        );
        if (notifyRegistryOnAbort) {
            sendRegistryLaunchAbort(extra.registryAddress, marketId);
        }
    }
}

fun executeJettonTransferNotification(
    mutate storage: Storage,
    senderAddress: address,
    inValue: coins,
    msg: JettonTransferNotification,
) {
    var extra = storage.extra.load();
    var lpYield = extra.lpYield.load();
    assert (msg.amount > 0) throw Errors.NON_POSITIVE_AMOUNT;
    assert (msg.amount <= 9223372036854775807) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
    // R2-1 fix: BOTH market-creation seeds and post-graduation LP-yield collateral arrive at
    // the launchpad's collateral jetton wallet. The LP-yield IS the collateral asset, so the
    // AMM routes the yield collateral back to this same wallet (collateralJettonWallet ==
    // lpYield.wallet for a single collateral token). Discriminating on the *sender* therefore
    // cannot tell creation seeds from yield deposits — the previous code keyed branch order on
    // the wallet and misrouted every yield deposit into market creation, where it reverted and
    // stranded the collateral. Discriminate on the forward-payload op tag instead:
    // LpYieldDepositPayload (lpYieldDepositOpcode) -> yield deposit; otherwise it is a
    // CreateMarketForwardPayload (executeCreateMarketFromJetton validates the union opcode).
    val collateralConfig = extra.collateralConfig.load();
    if (
        senderAddress == collateralConfig.collateralJettonWallet || senderAddress == lpYield.wallet
    ) {
        val forwardCell = msg.forwardPayload!;
        var forwardSlice = forwardCell.beginParse();
        // Read the discriminating op tag ONCE (loadUint advances the slice, so the
        // subsequent branches must reuse this value, not re-read forwardSlice).
        val forwardOp = forwardSlice.loadUint(32);
        if (forwardOp == lpYieldDepositOpcode()) {
            val payload = lazy LpYieldDepositPayload.fromCell(forwardCell);
            executeLpYieldDeposit(
                mutate storage,
                msg.amount as int64,
                payload.marketId,
                msg.sender,
            );
            return;
        }
        // HIGH fix: the AMM's post-settlement LP-floor sweep lands here, tagged sfld. Credit the
        // floor into the market's LP collateral pool and open settled-LP redemption.
        if (forwardOp == settlementFloorDepositOpcode()) {
            val payload = lazy SettlementFloorDepositPayload.fromCell(forwardCell);
            executeSettlementFloorDeposit(
                mutate storage,
                msg.amount as int64,
                payload.marketId,
                msg.sender,
            );
            return;
        }
        // Creator liquidity top-up: an IncreaseLiquidityPayload (op 0x696e636c) routes the
        // deposit into executeIncreaseLiquidityFromJetton (creator-only, computes/verifies
        // depositRequired, arms the pending top-up, forwards the deposit to the AMM). Sender
        // already gated to the collateral wallet above; msg.sender (the unforgeable transfer
        // initiator) is verified == the market's recorded creator inside the handler.
        if (forwardOp == increaseLiquidityOpcode()) {
            val payload = lazy IncreaseLiquidityPayload.fromCell(forwardCell);
            executeIncreaseLiquidityFromJetton(
                mutate storage,
                msg.amount as int64,
                payload.marketId,
                payload.additionalB,
                msg.sender,
            );
            return;
        }
        executeCreateMarketFromJetton(
            mutate storage,
            inValue,
            msg.amount,
            msg.sender,
            collateralConfig.collateralJettonMaster,
            forwardCell,
        );
        return;
    }
    // Neither the collateral wallet nor the LP-yield wallet: an LP-jetton transfer (redeem).
    // executeRedeemLpFromJetton re-verifies senderAddress == lpToken.lpJettonWallet.
    val payload = lazy LpJettonRedeemPayload.fromCell(msg.forwardPayload!);
    executeRedeemLpFromJetton(
        mutate storage,
        senderAddress,
        inValue,
        msg.amount,
        msg.sender,
        payload,
    );
}

// R2-1 fix: post-graduation LP-yield collateral booked into the market pool + the global
// collateralTotal. Reached from the collateral-wallet multiplex (the AMM routes the yield
// collateral back here, tagged with lpYieldDepositOpcode) and from a dedicated lpYield.wallet
// deposit. `depositor` is informational (event only); the funds are pooled per market and
// distributed to LPs through the settlement floor in executeRedeemLp/executeRedeemLpFromJetton.
fun executeLpYieldDeposit(
    mutate storage: Storage,
    amount: int64,
    marketId: uint32,
    depositor: address,
) {
    assert (amount > 0) throw Errors.NON_POSITIVE_AMOUNT;
    var extra = storage.extra.load();
    var lpYield = extra.lpYield.load();
    val result = extra.markets.get(marketId);
    assert (result.isFound) throw Errors.LAUNCHPAD_MARKET_NOT_FOUND;
    var market = result.loadValue();
    assert (market.lifecycle == lifecycleLive()) throw Errors.LAUNCHPAD_LIFECYCLE_INVALID;
    var marketYield = market.lpYield.load();
    assert (
        marketYield.collateral <= 9223372036854775807 - amount
    ) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
    assert (
        lpYield.collateralTotal <= 9223372036854775807 - amount
    ) throw Errors.NUMERIC_BOUNDS_EXCEEDED;

    marketYield.collateral += amount;
    market.lpYield = marketYield.toCell();
    lpYield.collateralTotal += amount;
    extra.lpYield = lpYield.toCell();
    extra.markets.set(marketId, market);
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitLaunchpadEvent(
        7,
        storage,
        marketId,
        depositor,
        market.lifecycle,
        amount,
        marketYield.collateral,
    );
}

// HIGH fix (canon settlement-redemption.md:113-141 / EVM AMMEngine.redeemLP): credit the AMM's
// post-settlement LP-floor sweep into the market's LP collateral pool + the global
// collateralTotal, and mark the floor settled so executeRedeemLp/executeRedeemLpFromJetton open
// and pay the FULL LP entitlement (accumulated lpYield + this swept floor). The floor was
// previously stranded in the AMM reserve. Only the market's own AMM is an accepted source. Works
// at live OR settled lifecycle (the sweep can race the registry's LaunchpadSettleMarket push).
fun executeSettlementFloorDeposit(
    mutate storage: Storage,
    amount: int64,
    marketId: uint32,
    depositor: address,
) {
    assert (amount > 0) throw Errors.NON_POSITIVE_AMOUNT;
    var extra = storage.extra.load();
    var lpYield = extra.lpYield.load();
    val result = extra.markets.get(marketId);
    assert (result.isFound) throw Errors.LAUNCHPAD_MARKET_NOT_FOUND;
    var market = result.loadValue();
    assert (depositor == market.ammAddress) throw Errors.ADMIN_UNAUTHORIZED;
    assert (
        market.lifecycle == lifecycleLive() || market.lifecycle == lifecycleSettled()
    ) throw Errors.LAUNCHPAD_LIFECYCLE_INVALID;
    var marketYield = market.lpYield.load();
    assert (
        marketYield.collateral <= 9223372036854775807 - amount
    ) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
    assert (
        lpYield.collateralTotal <= 9223372036854775807 - amount
    ) throw Errors.NUMERIC_BOUNDS_EXCEEDED;

    // Credit the swept floor into the LP collateral pool (now the FULL entitlement = lpYield +
    // floor) and open redemption. lpSettlementFloorCollateral (the old sub-floor cap) is left
    // untouched/0 — deprecated by this fix, kept only to preserve the purge `== 0` precondition.
    marketYield.collateral += amount;
    marketYield.lpSettlementFloorReported = true;
    market.lpYield = marketYield.toCell();
    lpYield.collateralTotal += amount;
    extra.lpYield = lpYield.toCell();
    extra.markets.set(marketId, market);
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitLaunchpadEvent(
        14,
        storage,
        marketId,
        depositor,
        market.lifecycle,
        amount,
        marketYield.collateral,
    );
}

// R2-1 S4a: jetton-transfer-first market creation. The creator transfers the
// escrowed seed collateral to the launchpad's collateralJettonWallet, carrying a
// CreateMarketPayload | FactoryCreateMarketPayload as the forward payload. The seed
// is recomputed on-chain as mulLn2(bBase) (EVM depositWad = bBase*ln(2)) and the
// transferred amount MUST equal it exactly AND clear minCreatorDeposit (EVM
// MIN_DEPOSIT_WAD = 10 tokens). On any mismatch the message reverts and the jetton
// transfer bounces back to the creator (no half-created market, no orphaned funds).
fun executeCreateMarketFromJetton(
    mutate storage: Storage,
    inValue: coins,
    amount: coins,
    creatorAddress: address,
    collateralJettonMaster: address,
    forwardPayload: cell,
) {
    val extra = storage.extra.load();
    val collateralConfig = extra.collateralConfig.load();
    // EVM parity: AMMEngine requires baseTokenDecimals <= 18 (AMMEngine.sol:182).
    // Also bounds pow10(collateralDecimals) in minCreatorDeposit against overflow.
    assert (collateralConfig.collateralDecimals <= 18) throw Errors.LAUNCHPAD_AMOUNT_INVALID;
    val payload = lazy CreateMarketForwardPayload.fromCell(forwardPayload);
    match (payload) {
        CreateMarketPayload => {
            val (qYes, qNo) = resolveSeedInventory(
                payload.bBase,
                payload.initialProbabilityBps,
                collateralConfig,
            );
            val seed = lmsrSeedFixed(payload.bBase, qYes, qNo);
            assert (amount as int64 == seed) throw Errors.LAUNCHPAD_AMOUNT_INVALID;
            assert (
                seed >= minCreatorDeposit(collateralConfig.collateralDecimals)
            ) throw Errors.LAUNCHPAD_AMOUNT_INVALID;
            executeCreateMarket(
                mutate storage,
                creatorAddress,
                inValue,
                amount as int64,
                qYes as int64,
                qNo as int64,
                collateralJettonMaster,
                payload,
            );
        }

        FactoryCreateMarketPayload => {
            val (qYes, qNo) = resolveSeedInventory(
                payload.bBase,
                payload.initialProbabilityBps,
                collateralConfig,
            );
            val seed = lmsrSeedFixed(payload.bBase, qYes, qNo);
            assert (amount as int64 == seed) throw Errors.LAUNCHPAD_AMOUNT_INVALID;
            assert (
                seed >= minCreatorDeposit(collateralConfig.collateralDecimals)
            ) throw Errors.LAUNCHPAD_AMOUNT_INVALID;
            executeFactoryCreateMarket(
                mutate storage,
                creatorAddress,
                inValue,
                amount as int64,
                qYes as int64,
                qNo as int64,
                collateralJettonMaster,
                payload,
            );
        }

        else => {
            assert (false) throw Errors.LAUNCHPAD_UNHANDLED_BRANCH;
        }
    }
}

fun executeAccrueFees(
    mutate storage: Storage,
    senderAddress: address,
    inValue: coins,
    msg: AccrueFees,
) {
    var extra = storage.extra.load();
    requireNotPaused(storage.paused);
    assert (msg.amount > 0) throw Errors.LAUNCHPAD_AMOUNT_INVALID;
    assert (msg.amount <= 922337203685477) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
    val result = extra.markets.get(msg.marketId);
    assert (result.isFound) throw Errors.LAUNCHPAD_MARKET_NOT_FOUND;
    var market = result.loadValue();
    val refs = market.refs.load();
    // Operator autonomy: the market's own AMM drives accrual + graduation autonomously
    // (its per-trade LaunchpadAccrueFees auto-route). senderAddress == market.ammAddress is
    // the legitimate cross-contract sender; admin/operator are retained only as break-glass.
    // This is the fix that makes the AMM's fee route SUCCEED (it bounced before, when the
    // launchpad gated on requireOperator and the AMM was not the operator) -> graduation now
    // fires from real trades with no operator set.
    //
    // H-1 fix: the AMM is the SOLE cross-contract accrual sender again. The order engine no
    // longer accrues to the launchpad — it forwards the fee JETTONS to the AMM, which credits
    // its own feeCollateral and then routes THIS accrual (so senderAddress == market.ammAddress
    // even for an engine-sourced fee). The old engine-address widening (#34) is reverted.
    requireAmmOrOperator(extra, senderAddress, market.ammAddress);
    val detail = refs.detail.load();
    val lpToken = detail.lpJetton.load();
    if (market.lifecycle == lifecycleLive()) {
        // EVM fee parity (1/2): post-grad split sourced from the operator-set distribution
        // config (the setter guarantees bBase+lpYield+adjudicator+protocol == 10000), with
        // protocol = remainder (EVM FeeRouter.sol:383-386 remainder-to-protocol).
        val toBBase = (msg.amount * storage.bBaseBps) / feeBpsDenominator();
        val toLpYield = (msg.amount * storage.lpYieldBps) / feeBpsDenominator();
        val toAdjudicator = (msg.amount * storage.adjudicatorBps) / feeBpsDenominator();
        val toProtocol = msg.amount - toBBase - toLpYield - toAdjudicator;
        assert (toProtocol >= 0) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
        assert (
            market.feeAccrued <= 9223372036854775807 - msg.amount
        ) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
        assert (market.bBase <= 9223372036854775807 - toBBase) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
        var marketYield = market.lpYield.load();
        assert (
            marketYield.adjudicatorFees <= 9223372036854775807 - toAdjudicator
        ) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
        assert (
            marketYield.protocolFees <= 9223372036854775807 - toProtocol
        ) throw Errors.NUMERIC_BOUNDS_EXCEEDED;

        market.feeAccrued += msg.amount;
        market.bBase += toBBase;
        marketYield.adjudicatorFees += toAdjudicator;
        marketYield.protocolFees += toProtocol;
        market.lpYield = marketYield.toCell();
        extra.markets.set(msg.marketId, market);
        storage.sequence += 1;
        storage.extra = extra.toCell();
        storage.save();
        emitLaunchpadEvent(
            11,
            storage,
            msg.marketId,
            senderAddress,
            lifecycleLive(),
            msg.amount,
            toLpYield,
        );
        sendAmmLaunchpadYieldRoute(
            market.ammAddress,
            msg.marketId,
            toLpYield,
            toBBase,
            toAdjudicator,
            toProtocol,
        );
        // H-1 fix: confirm back to the AMM (the accrual sender is always the AMM now — the
        // engine forwards jettons to the AMM, the AMM accrues). The #34 senderAddress-routing
        // (to support an engine-sourced accrual) is reverted; senderAddress == market.ammAddress
        // here, so this is behavior-preserving for the AMM path.
        sendAmmFeeRouteConfirmed(
            market.ammAddress,
            msg.marketId,
            msg.trader,
            msg.amount,
            storage.sequence,
        );
        return;
    }
    assert (market.lifecycle == lifecycleBonding()) throw Errors.LAUNCHPAD_LIFECYCLE_INVALID;
    assert (blockchain.now() < market.trialEnd) throw Errors.LAUNCHPAD_LIFECYCLE_INVALID;
    assert (
        market.feeAccrued <= 9223372036854775807 - msg.amount
    ) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
    assert (
        market.lpSupply <= 9223372036854775807 - msg.amount
    ) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
    val willGraduate = market.feeAccrued + msg.amount >= market.graduationThreshold;
    if (lpToken.lpJettonEnabled) {
        var requiredValue = lpJettonMintValue();
        if (willGraduate) {
            requiredValue += ton("0.05");
        }
        assert (inValue >= requiredValue) throw Errors.INSUFFICIENT_MESSAGE_VALUE;
    }

    // EVM fee parity (FeeRouter._distributePreGrad:348): the WHOLE pre-grad fee deepens the
    // LMSR curve b. deltaB == floor(fee * fixedScale / ln2Fixed) == fee/ln2 (EVM `fee *
    // LN2_INV_WAD / WAD`). The floor truncates DOWN, so deltaB*ln2 <= fee — the AMM banks the
    // full fee into reserve while deepening b by at most fee/ln2 worth of liability, leaving it
    // over-collateralized (collateral-safe; proven in tests/SoothAmmMath.test.tolk). We grow the
    // launchpad's mirror `market.bBase` in lockstep with the AMM's liquity += deltaB so the
    // creator-top-up depositRequired (mulLn2(bBase+dB)-mulLn2(bBase)) stays priced against the
    // true deepened curve. graduationThreshold is frozen at creation (from creatorDeposit, NOT
    // bBase) so it does NOT move (M1).
    val deltaB = (msg.amount * fixedScale()) / ln2Fixed();
    assert (market.bBase <= 9223372036854775807 - deltaB) throw Errors.NUMERIC_BOUNDS_EXCEEDED;

    var accounting = market.accounting.load();
    val currentBalance = lpBalanceFor(accounting, msg.trader);
    assert (
        currentBalance <= 9223372036854775807 - msg.amount
    ) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
    accounting.lpBalances.set(msg.trader, currentBalance + msg.amount);
    market.feeAccrued += msg.amount;
    market.lpSupply += msg.amount;
    market.bBase += deltaB as int64;
    market.accounting = accounting.toCell();

    storage.sequence += 1;
    var notifyRegistry = false;
    var registryLifecycle = lifecycleBonding();
    var registryTimestamp: int64 = 0;
    emitLaunchpadEvent(
        2,
        storage,
        msg.marketId,
        senderAddress,
        lifecycleBonding(),
        msg.amount,
        market.feeAccrued,
    );
    if (willGraduate) {
        market.lifecycle = lifecycleLive();
        market.graduatedAt = blockchain.now() as int64;
        notifyRegistry = true;
        registryLifecycle = lifecycleLive();
        registryTimestamp = market.graduatedAt;
        emitLaunchpadEvent(
            3,
            storage,
            msg.marketId,
            senderAddress,
            lifecycleLive(),
            market.feeAccrued,
            market.graduatedAt,
        );
    }
    extra.markets.set(msg.marketId, market);
    storage.extra = extra.toCell();
    storage.save();
    sendLpJettonMintIfConfigured(lpToken, msg.trader, msg.amount as coins);
    // EVM fee parity (FeeRouter._distributePreGrad): deepen the AMM's LMSR curve from the
    // bonding fee it already holds. collateral == the fee, deltaB == fee/ln2. Pure accounting
    // message (no jetton movement). Mirrors the post-grad path where the AMM also deepens.
    sendAmmDeepenFromBondingFee(
        market.ammAddress,
        msg.marketId,
        msg.amount as int64,
        deltaB as int64,
    );
    if (notifyRegistry) {
        sendRegistryLifecycleUpdate(
            extra.registryAddress,
            msg.marketId,
            registryLifecycle,
            invalidOutcome(),
            registryTimestamp,
        );
    }
    // EVM fee parity (1/2): when this accrual graduates the market, tell the AMM so it
    // switches to the postGrad fee rate. One-time, idempotent at the AMM, WithBounce +
    // bounce-retry for robustness (notifyRegistry == willGraduate here).
    if (willGraduate) {
        sendAmmSetGraduated(market.ammAddress, msg.marketId);
    }
    sendAmmFeeRouteConfirmed(
        market.ammAddress,
        msg.marketId,
        msg.trader,
        msg.amount,
        storage.sequence,
    );
}

fun executeExpireTrial(mutate storage: Storage, senderAddress: address, msg: ExpireTrial) {
    var extra = storage.extra.load();
    val result = extra.markets.get(msg.marketId);
    assert (result.isFound) throw Errors.LAUNCHPAD_MARKET_NOT_FOUND;
    var market = result.loadValue();
    assert (market.lifecycle != lifecycleLive()) throw Errors.LAUNCHPAD_ALREADY_LIVE;
    assert (market.lifecycle == lifecycleBonding()) throw Errors.LAUNCHPAD_LIFECYCLE_INVALID;
    assert (blockchain.now() >= market.trialEnd) throw Errors.LAUNCHPAD_TRIAL_NOT_ENDED;

    market.lifecycle = lifecycleTrialExpired();
    market.expiredAt = blockchain.now() as int64;
    extra.markets.set(msg.marketId, market);
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    sendRegistryLifecycleUpdate(
        extra.registryAddress,
        msg.marketId,
        lifecycleTrialExpired(),
        invalidOutcome(),
        market.expiredAt,
    );
    // EVM parity (AMMEngine.isTrialExpiredWithoutGraduation): halt trading on the market's AMM
    // now that the trial expired without graduating, so it stops accepting new trades.
    sendAmmHaltTrading(market.ammAddress, msg.marketId);
    emitLaunchpadEvent(
        4,
        storage,
        msg.marketId,
        senderAddress,
        lifecycleTrialExpired(),
        0,
        market.expiredAt,
    );
}

fun executeSettleMarket(mutate storage: Storage, senderAddress: address, msg: SettleMarket) {
    var extra = storage.extra.load();
    requireRegistryOrAdmin(extra, senderAddress);
    assert (msg.timestamp > 0) throw Errors.LAUNCHPAD_TIMESTAMP_INVALID;
    val result = extra.markets.get(msg.marketId);
    assert (result.isFound) throw Errors.LAUNCHPAD_MARKET_NOT_FOUND;
    var market = result.loadValue();
    assert (
        market.lifecycle == lifecycleLive() || market.lifecycle == lifecycleTrialExpired()
    ) throw Errors.LAUNCHPAD_LIFECYCLE_INVALID;
    assert (
        msg.winningOutcome < market.outcomeCount || msg.winningOutcome == invalidOutcome()
    ) throw Errors.UNKNOWN_OUTCOME;
    if (market.lifecycle == lifecycleTrialExpired()) {
        assert (msg.winningOutcome == invalidOutcome()) throw Errors.UNKNOWN_OUTCOME;
    }

    var marketYield = market.lpYield.load();
    market.lifecycle = lifecycleSettled();
    marketYield.winningOutcome = msg.winningOutcome;
    marketYield.settledAt = msg.timestamp;
    market.lpYield = marketYield.toCell();
    extra.markets.set(msg.marketId, market);
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitLaunchpadEvent(
        13,
        storage,
        msg.marketId,
        senderAddress,
        lifecycleSettled(),
        msg.winningOutcome as int64,
        msg.timestamp,
    );
    if (senderAddress == extra.registryAddress) {
        sendRegistrySettlementConfirmation(
            extra.registryAddress,
            msg.marketId,
            settlementVenueLaunchpad(),
            msg.winningOutcome,
            storage.sequence,
        );
    }
}

fun executeRecordLpSettlementFloor(
    mutate storage: Storage,
    senderAddress: address,
    msg: RecordLpSettlementFloor,
) {
    assert (msg.floorCollateral >= 0) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
    var extra = storage.extra.load();
    val result = extra.markets.get(msg.marketId);
    assert (result.isFound) throw Errors.LAUNCHPAD_MARKET_NOT_FOUND;
    var market = result.loadValue();
    assert (senderAddress == market.ammAddress) throw Errors.ADMIN_UNAUTHORIZED;
    assert (
        market.lifecycle == lifecycleLive() || market.lifecycle == lifecycleSettled()
    ) throw Errors.LAUNCHPAD_LIFECYCLE_INVALID;

    // HIGH fix: this report now only OPENS redemption (retro / floor==0 markets where no jettons
    // were swept). The floor value is informational (deferred for retro), so we no longer write it
    // into lpSettlementFloorCollateral (deprecated cap field, kept 0 for the purge precondition).
    var marketYield = market.lpYield.load();
    marketYield.lpSettlementFloorReported = true;
    market.lpYield = marketYield.toCell();
    extra.markets.set(msg.marketId, market);
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitLaunchpadEvent(
        14,
        storage,
        msg.marketId,
        senderAddress,
        market.lifecycle,
        msg.floorCollateral,
        0,
    );
}

fun executeTransferLp(mutate storage: Storage, senderAddress: address, msg: TransferLp) {
    assert (msg.lpAmount > 0) throw Errors.NON_POSITIVE_AMOUNT;
    assert (msg.lpAmount <= 9223372036854775807) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
    val lpAmount = msg.lpAmount as int64;

    var extra = storage.extra.load();
    val result = extra.markets.get(msg.marketId);
    assert (result.isFound) throw Errors.LAUNCHPAD_MARKET_NOT_FOUND;
    var market = result.loadValue();
    val refs = market.refs.load();
    val detail = refs.detail.load();
    val lpToken = detail.lpJetton.load();
    assert (lpToken.lpJettonEnabled == false) throw Errors.LAUNCHPAD_LP_JETTON_MODE_MISMATCH;
    assert (
        market.lifecycle != lifecycleTrialExpired() && market.lifecycle != lifecycleSettled()
    ) throw Errors.LAUNCHPAD_LIFECYCLE_INVALID;

    var accounting = market.accounting.load();
    val senderBalance = lpBalanceFor(accounting, senderAddress);
    assert (senderBalance >= lpAmount) throw Errors.LAUNCHPAD_INSUFFICIENT_LP_BALANCE;
    var recipientBalance = lpBalanceFor(accounting, msg.recipient);
    if (senderAddress != msg.recipient) {
        assert (
            recipientBalance <= 9223372036854775807 - lpAmount
        ) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
        accounting.lpBalances.set(senderAddress, senderBalance - lpAmount);
        recipientBalance += lpAmount;
        accounting.lpBalances.set(msg.recipient, recipientBalance);
        market.accounting = accounting.toCell();
        extra.markets.set(msg.marketId, market);
    }

    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitLaunchpadEvent(
        12,
        storage,
        msg.marketId,
        senderAddress,
        market.lifecycle,
        lpAmount,
        recipientBalance,
    );
}

fun executeRegistryLaunchConfirmed(
    mutate storage: Storage,
    senderAddress: address,
    msg: RegistryLaunchConfirmed,
) {
    assert (msg.registeredAt > 0) throw Errors.LAUNCHPAD_TIMESTAMP_INVALID;
    var extra = storage.extra.load();
    assert (senderAddress == extra.registryAddress) throw Errors.ADMIN_UNAUTHORIZED;
    val result = extra.markets.get(msg.marketId);
    assert (result.isFound) throw Errors.LAUNCHPAD_MARKET_NOT_FOUND;
    var market = result.loadValue();
    var marketYield = market.lpYield.load();
    var mintCreatorLp = false;
    var refs = market.refs.load();
    var detail = refs.detail.load();
    var lpToken = detail.lpJetton.load();
    if (marketYield.registryConfirmedAt == 0) {
        marketYield.registryConfirmedAt = msg.registeredAt;
        if (
            lpToken.lpJettonEnabled && marketYield.creatorLpJettonMinted == false &&
            marketYield.adjudicatorConfirmedAt > 0
        ) {
            marketYield.creatorLpJettonMinted = true;
            mintCreatorLp = true;
        }
        // R2-1 S4b: factory setup is confirmed (registry wired the AMM's collateral
        // wallet + launchpadFeeRouter==launchpad). Forward the escrowed seed to the
        // AMM's collateral wallet exactly once. The seed lands as the launchpad's AMM
        // trader-collateral; the AMM acks (SeedCollateralAck) once it is credited, and
        // only then do we fire SeedReserve (executeSeedCollateralAck) — in-order, no
        // race. Forwarding is RichBounce: a bounce restores the escrow + aborts.
        var forwardSeed = false;
        if (marketYield.seedRequired && marketYield.seedForwarded == false) {
            marketYield.seedForwarded = true;
            // The escrow is leaving launchpad custody for the AMM; it is no longer
            // launchpad-refundable until/unless the forward bounces (SeedForwardRestore).
            marketYield.seedHeldByLaunchpad = false;
            forwardSeed = true;
        }
        market.lpYield = marketYield.toCell();
        extra.markets.set(msg.marketId, market);
        storage.sequence += 1;
        storage.extra = extra.toCell();
        storage.save();
        emitLaunchpadEvent(
            16,
            storage,
            msg.marketId,
            senderAddress,
            market.lifecycle,
            0,
            msg.registeredAt,
        );
        if (mintCreatorLp) {
            sendLpJettonMintIfConfigured(lpToken, detail.creator, market.creatorDeposit as coins);
        }
        if (forwardSeed) {
            sendSeedToAmm(
                extra.collateralConfig.load().collateralJettonWallet,
                market.ammAddress,
                msg.marketId,
                market.creatorDeposit,
            );
        }
        // EVM fee parity (2/2): stamp the configured adjudicator into the AMM now that
        // factory setup has wired launchpadFeeRouter == launchpad (the AMM-side auth for
        // SetAdjudicatorAddress). Gated on seedRequired == factory path: only there is the
        // launchpad the AMM's router, so only there will the AMM accept this. (Non-factory
        // RegisterMarket markets use pre-deployed AMMs whose adjudicator the operator wires
        // out-of-band.) One-time: this whole block runs only while registryConfirmedAt == 0.
        if (marketYield.seedRequired) {
            sendAmmSetAdjudicatorAddress(market.ammAddress, msg.marketId, refs.adjudicatorAddress);
            // H-1 fix: also stamp the order engine into the AMM so the AMM can classify the
            // engine-fee deposit (msg.sender == orderEngine) and route it through the post-grad
            // split — the EVM-faithful destination for an order-engine taker fee.
            sendAmmSetOrderEngine(market.ammAddress, msg.marketId, refs.engineAddress);
        }
    }
}

// R2-1 S4b: the in-order seed trigger. The AMM emits SeedCollateralAck only after the
// launchpad-router's seed deposit is credited (reserve still 0), so receiving it proves
// the seed collateral has LANDED at the AMM as the launchpad's trader-collateral. Only
// then do we fire SeedReserve — guaranteeing executeSeedReserve sees provider.collateral
// >= seed (no 1009 / no bounce). Auth: sender must be THIS market's AMM. Idempotent:
// once seedConfirmedAt is set the SeedReserve already promoted the reserve, so any
// re-delivered ack is ignored (it would otherwise re-fire a doomed reserve!=0 SeedReserve).
fun executeSeedCollateralAck(
    mutate storage: Storage,
    senderAddress: address,
    msg: SeedCollateralAck,
) {
    val extra = storage.extra.load();
    val result = extra.markets.get(msg.marketId);
    assert (result.isFound) throw Errors.LAUNCHPAD_MARKET_NOT_FOUND;
    val market = result.loadValue();
    assert (senderAddress == market.ammAddress) throw Errors.ADMIN_UNAUTHORIZED;
    val marketYield = market.lpYield.load();
    assert (marketYield.seedRequired) throw Errors.LAUNCHPAD_VENUE_SETUP_INVALID;
    assert (marketYield.seedForwarded) throw Errors.LAUNCHPAD_VENUE_SETUP_INVALID;
    if (marketYield.seedConfirmedAt == 0) {
        emitLaunchpadEvent(
            22,
            storage,
            msg.marketId,
            senderAddress,
            market.lifecycle,
            market.creatorDeposit,
            0,
        );
        sendSeedReserveToAmm(market.ammAddress, msg.marketId, market.creatorDeposit);
    }
}

// Creator liquidity top-up (EVM AMMEngine.increaseLiquidityFromCreator parity), step 2.
// Reached from the collateral-wallet multiplex on an IncreaseLiquidityPayload. Verifies the
// caller is the recorded creator and the market is Live, recomputes depositRequired with
// EVM-faithful TWO-ceil math (matching SeedReserve/creation escrow), checks the deposited
// amount EXACTLY equals it, arms the pending top-up (topUpInFlight), commits, then forwards
// the deposit to the AMM (AMM-bump-first; launchpad commits only on the AMM confirmation in
// step 6). graduationThreshold is materialized and intentionally LEFT UNCHANGED (EVM parity:
// FeeRouter graduation uses an immutable bBaseAtCreation snapshot).
fun executeIncreaseLiquidityFromJetton(
    mutate storage: Storage,
    deposit: int64,
    marketId: uint32,
    additionalB: int64,
    creatorAddress: address,
) {
    assert (deposit > 0) throw Errors.NON_POSITIVE_AMOUNT;
    assert (additionalB > 0) throw Errors.LAUNCHPAD_AMOUNT_INVALID;
    assert (additionalB <= 9223372036854775807) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
    var extra = storage.extra.load();
    requireNotPaused(storage.paused);
    var lpYield = extra.lpYield.load();
    val result = extra.markets.get(marketId);
    assert (result.isFound) throw Errors.LAUNCHPAD_MARKET_NOT_FOUND;
    var market = result.loadValue();
    // EVM require(msg.sender == creator): msg.sender (the unforgeable jetton-transfer
    // initiator) must be the recorded market creator.
    val refs = market.refs.load();
    val detail = refs.detail.load();
    assert (creatorAddress == detail.creator) throw Errors.TRADER_UNAUTHORIZED;
    assert (market.lifecycle == lifecycleLive()) throw Errors.LAUNCHPAD_LIFECYCLE_INVALID;
    // One top-up per market in flight (the AMM-bump-first ordering must not interleave two
    // top-ups for the same market). Presence in pendingTopUps == topUpInFlight.
    val existingTopUp = lpYield.pendingTopUps.get(marketId);
    assert (existingTopUp.isFound == false) throw Errors.LAUNCHPAD_VENUE_SETUP_INVALID;
    // bBase grows; guard the curve-deepen + the two-ceil cost basis against overflow.
    assert (market.bBase <= 9223372036854775807 - additionalB) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
    // depositRequired = mulLn2(b + additionalB) - mulLn2(b): TWO separate ceils, mirroring
    // how SeedReserve / the creation escrow size the seed (NOT the trade path's single ceil
    // of the difference). The AMM books exactly this deposited amount into reserve.
    //
    // M2 (ACCEPTED CONSERVATIVE DEVIATION — no code change). EVM `increaseLiquidityFromCreator`
    // charges the at-rest cost delta at the CURRENT (possibly skewed) inventory. TON's mulLn2
    // form prices the top-up at the 50/50 worst-case (b*ln2) for both endpoints, so at a skewed
    // inventory the TON charge is >= the true at-rest cost delta (it OVER-charges, never under).
    // This is solvency-safe by construction (the AMM is over-, never under-, collateralized after
    // a skewed top-up) and is the SAME mulLn2 worst-case basis used for the creation seed; the
    // bonding-fee deepen above (deltaB == fee/ln2, floored DOWN) is likewise solvency-safe. We
    // deliberately keep the conservative mulLn2 basis rather than chase the EVM at-inventory
    // formula. Documented in docs/migration/r2-2-audit-fees-token-atomicity.md.
    val depositRequired = mulLn2(market.bBase + additionalB) - mulLn2(market.bBase);
    assert (depositRequired > 0) throw Errors.LAUNCHPAD_AMOUNT_INVALID;
    assert (deposit == depositRequired) throw Errors.LAUNCHPAD_AMOUNT_INVALID;
    assert (
        market.lpSupply <= 9223372036854775807 - depositRequired
    ) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
    assert (
        market.creatorDeposit <= 9223372036854775807 - depositRequired
    ) throw Errors.NUMERIC_BOUNDS_EXCEEDED;

    // Arm the pending top-up (topUpInFlight = true) and commit BEFORE forwarding. The
    // commit of creatorDeposit/lpSupply/lpBalances/bBase happens only on the AMM
    // confirmation (executeIncreaseReserveConfirmed); a forward/reserve bounce clears this.
    lpYield.pendingTopUps.set(marketId, { additionalB, deposit: depositRequired });
    extra.lpYield = lpYield.toCell();
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitLaunchpadEvent(
        28,
        storage,
        marketId,
        creatorAddress,
        market.lifecycle,
        depositRequired,
        additionalB,
    );
    // Forward the deposit to the AMM (RichBounce; a bounce -> IncreaseReserveForwardRestore
    // clears the pending top-up). The deposit lands as the launchpad's AMM trader-collateral.
    sendIncreaseLiquidityToAmm(
        extra.collateralConfig.load().collateralJettonWallet,
        market.ammAddress,
        marketId,
        depositRequired,
    );
}

// Creator liquidity top-up, step 4. The AMM acks the top-up deposit landing (reserve>0), so
// the deposit is provably the launchpad's AMM trader-collateral. Only then do we fire
// IncreaseReserve. Auth: sender must be THIS market's AMM. Idempotent: gated on the pending
// top-up still being in flight (a re-delivered ack after commit/bounce finds no pending).
fun executeIncreaseReserveAck(
    mutate storage: Storage,
    senderAddress: address,
    msg: IncreaseReserveAck,
) {
    val extra = storage.extra.load();
    val result = extra.markets.get(msg.marketId);
    assert (result.isFound) throw Errors.LAUNCHPAD_MARKET_NOT_FOUND;
    val market = result.loadValue();
    assert (senderAddress == market.ammAddress) throw Errors.ADMIN_UNAUTHORIZED;
    val lpYield = extra.lpYield.load();
    val pending = lpYield.pendingTopUps.get(msg.marketId);
    if (pending.isFound) {
        val topUp = pending.loadValue();
        emitLaunchpadEvent(
            29,
            storage,
            msg.marketId,
            senderAddress,
            market.lifecycle,
            topUp.deposit,
            topUp.additionalB,
        );
        sendIncreaseReserveToAmm(market.ammAddress, msg.marketId, topUp.deposit, topUp.additionalB);
    }
}

// Creator liquidity top-up, step 6 (COMMIT). The AMM confirms it promoted the deposit into
// reserve + deepened the curve (FactorySetupConfirmed{setup:32}). Commit the launchpad-side
// LP mint + bBase bump, then clear the pending top-up. Auth: sender == this market's AMM,
// pending top-up must be in flight. Idempotent: a re-delivered confirm finds no pending and
// is a no-op (the AMM stays deeper than launchpad records on confirm loss — over-collateralized).
// graduationThreshold is LEFT UNCHANGED (EVM parity).
fun executeIncreaseReserveConfirmed(
    mutate storage: Storage,
    senderAddress: address,
    marketId: uint32,
) {
    var extra = storage.extra.load();
    val result = extra.markets.get(marketId);
    assert (result.isFound) throw Errors.LAUNCHPAD_MARKET_NOT_FOUND;
    var market = result.loadValue();
    assert (senderAddress == market.ammAddress) throw Errors.ADMIN_UNAUTHORIZED;
    var lpYield = extra.lpYield.load();
    val pending = lpYield.pendingTopUps.get(marketId);
    if (pending.isFound) {
        val topUp = pending.loadValue();
        var accounting = market.accounting.load();
        val detail = market.refs.load().detail.load();
        val creatorBalance = lpBalanceFor(accounting, detail.creator);
        assert (
            creatorBalance <= 9223372036854775807 - topUp.deposit
        ) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
        assert (
            market.lpSupply <= 9223372036854775807 - topUp.deposit
        ) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
        assert (
            market.creatorDeposit <= 9223372036854775807 - topUp.deposit
        ) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
        assert (
            market.bBase <= 9223372036854775807 - topUp.additionalB
        ) throw Errors.NUMERIC_BOUNDS_EXCEEDED;

        // EVM: liquidity += additionalB (AMM); LP(depositRequired) minted to creator;
        // _marketDeposits/_marketCollateral += depositRequired (the LP basis). graduationThreshold
        // UNCHANGED (FeeRouter uses the immutable bBaseAtCreation snapshot).
        accounting.lpBalances.set(detail.creator, creatorBalance + topUp.deposit);
        market.accounting = accounting.toCell();
        market.creatorDeposit += topUp.deposit;
        market.lpSupply += topUp.deposit;
        market.bBase += topUp.additionalB;
        lpYield.pendingTopUps.delete(marketId);
        extra.lpYield = lpYield.toCell();
        extra.markets.set(marketId, market);
        storage.sequence += 1;
        storage.extra = extra.toCell();
        storage.save();
        emitLaunchpadEvent(
            30,
            storage,
            marketId,
            senderAddress,
            market.lifecycle,
            topUp.deposit,
            topUp.additionalB,
        );
    }
}

// Creator liquidity top-up: IncreaseReserve-bounce recovery (step 4 -> 5). The deposit was
// credited to the launchpad's AMM trader-ledger but not promoted into reserve. Clear the
// pending top-up so no LP is credited; the deposit is recoverable from the AMM as the
// launchpad's trader-collateral via a WithdrawCollateral (operator-driven). Idempotent.
fun executeIncreaseReserveBounced(
    mutate storage: Storage,
    senderAddress: address,
    marketId: uint32,
) {
    var extra = storage.extra.load();
    val result = extra.markets.get(marketId);
    if (result.isFound) {
        val market = result.loadValue();
        assert (senderAddress == market.ammAddress) throw Errors.ADMIN_UNAUTHORIZED;
        var lpYield = extra.lpYield.load();
        val pending = lpYield.pendingTopUps.get(marketId);
        if (pending.isFound) {
            val topUp = pending.loadValue();
            lpYield.pendingTopUps.delete(marketId);
            extra.lpYield = lpYield.toCell();
            storage.sequence += 1;
            storage.extra = extra.toCell();
            storage.save();
            emitLaunchpadEvent(
                31,
                storage,
                marketId,
                senderAddress,
                market.lifecycle,
                topUp.deposit,
                topUp.additionalB,
            );
        }
    }
}

fun executeAdjudicatorLaunchConfirmed(
    mutate storage: Storage,
    senderAddress: address,
    msg: AdjudicatorLaunchConfirmed,
) {
    assert (msg.configuredAt > 0) throw Errors.LAUNCHPAD_TIMESTAMP_INVALID;
    var extra = storage.extra.load();
    val result = extra.markets.get(msg.marketId);
    assert (result.isFound) throw Errors.LAUNCHPAD_MARKET_NOT_FOUND;
    var market = result.loadValue();
    val refs = market.refs.load();
    assert (senderAddress == refs.adjudicatorAddress) throw Errors.ADMIN_UNAUTHORIZED;
    var marketYield = market.lpYield.load();
    var mintCreatorLp = false;
    var detail = refs.detail.load();
    var lpToken = detail.lpJetton.load();
    if (marketYield.adjudicatorConfirmedAt == 0) {
        marketYield.adjudicatorConfirmedAt = msg.configuredAt;
        if (
            lpToken.lpJettonEnabled && marketYield.creatorLpJettonMinted == false &&
            marketYield.registryConfirmedAt > 0
        ) {
            marketYield.creatorLpJettonMinted = true;
            mintCreatorLp = true;
        }
        market.lpYield = marketYield.toCell();
        extra.markets.set(msg.marketId, market);
        storage.sequence += 1;
        storage.extra = extra.toCell();
        storage.save();
        emitLaunchpadEvent(
            17,
            storage,
            msg.marketId,
            senderAddress,
            market.lifecycle,
            0,
            msg.configuredAt,
        );
        if (mintCreatorLp) {
            sendLpJettonMintIfConfigured(lpToken, detail.creator, market.creatorDeposit as coins);
        }
    }
}

// R2-1 S4b: the AMM confirms it promoted the escrowed seed into reserveCollateral.
// The AMM's SeedReserve handler sends FactorySetupConfirmed{setup:16} to its caller
// (the launchpad/router). We accept it only from this market's AMM, only for the
// seed mask, and only after the seed was actually forwarded (idempotent re-delivery
// safe). Records seedConfirmedAt = the AMM reserve is provably == seed.
fun executeFactorySetupConfirmed(
    mutate storage: Storage,
    senderAddress: address,
    msg: FactorySetupConfirmed,
) {
    // Creator liquidity top-up: the AMM emits FactorySetupConfirmed{setup:32} after a
    // successful IncreaseReserve. Route that to the top-up COMMIT; the original seed mask
    // (16) keeps the one-time creation-seed confirmation behaviour unchanged.
    if (msg.setup == factorySetupAmmIncreaseMask()) {
        executeIncreaseReserveConfirmed(mutate storage, senderAddress, msg.marketId);
        return;
    }
    assert (msg.setup == factorySetupAmmSeedMask()) throw Errors.LAUNCHPAD_VENUE_SETUP_INVALID;
    var extra = storage.extra.load();
    val result = extra.markets.get(msg.marketId);
    assert (result.isFound) throw Errors.LAUNCHPAD_MARKET_NOT_FOUND;
    var market = result.loadValue();
    assert (senderAddress == market.ammAddress) throw Errors.ADMIN_UNAUTHORIZED;
    var marketYield = market.lpYield.load();
    assert (marketYield.seedRequired) throw Errors.LAUNCHPAD_VENUE_SETUP_INVALID;
    assert (marketYield.seedForwarded) throw Errors.LAUNCHPAD_VENUE_SETUP_INVALID;
    if (marketYield.seedConfirmedAt == 0) {
        marketYield.seedConfirmedAt = blockchain.now() as int64;
        market.lpYield = marketYield.toCell();
        extra.markets.set(msg.marketId, market);
        storage.sequence += 1;
        storage.extra = extra.toCell();
        storage.save();
        emitLaunchpadEvent(
            21,
            storage,
            msg.marketId,
            senderAddress,
            market.lifecycle,
            market.creatorDeposit,
            marketYield.seedConfirmedAt,
        );
    }
}

fun executeRedeemLp(
    mutate storage: Storage,
    senderAddress: address,
    inValue: coins,
    msg: RedeemLp,
) {
    assert (msg.lpAmount > 0) throw Errors.NON_POSITIVE_AMOUNT;
    assert (msg.lpAmount <= 9223372036854775807) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
    val lpAmount = msg.lpAmount as int64;
    assert (msg.jettonTransferValue > 0) throw Errors.NON_POSITIVE_AMOUNT;
    assert (msg.forwardTonAmount > 0) throw Errors.NON_POSITIVE_AMOUNT;
    assert (
        inValue >= requiredJettonSendValue(msg.jettonTransferValue, msg.forwardTonAmount)
    ) throw Errors.INSUFFICIENT_MESSAGE_VALUE;

    var extra = storage.extra.load();
    var lpYield = extra.lpYield.load();
    val result = extra.markets.get(msg.marketId);
    assert (result.isFound) throw Errors.LAUNCHPAD_MARKET_NOT_FOUND;
    var market = result.loadValue();
    val refs = market.refs.load();
    val detail = refs.detail.load();
    val lpToken = detail.lpJetton.load();
    assert (lpToken.lpJettonEnabled == false) throw Errors.LAUNCHPAD_LP_JETTON_MODE_MISMATCH;
    assert (market.lifecycle == lifecycleSettled()) throw Errors.LAUNCHPAD_LIFECYCLE_INVALID;
    assert (market.lpSupply > 0) throw Errors.LAUNCHPAD_NO_LP_SUPPLY;
    var marketYield = market.lpYield.load();
    // HIGH fix (canon settlement-redemption.md): redemption opens only once the AMM's LP floor has
    // been settled here (lpSettlementFloorReported — set by executeSettlementFloorDeposit for
    // non-retro, or by the deferred report for retro). marketYield.collateral now holds the FULL LP
    // entitlement (accumulated lpYield + the swept floor), so we pay it pro-rata with NO sub-floor
    // cap; solvency stays enforced by the collateral/collateralTotal asserts below.
    assert (marketYield.lpSettlementFloorReported) throw Errors.LAUNCHPAD_NO_REDEEMABLE_COLLATERAL;
    assert (marketYield.collateral > 0) throw Errors.LAUNCHPAD_NO_REDEEMABLE_COLLATERAL;
    val redeemableCollateral = marketYield.collateral;

    var accounting = market.accounting.load();
    val currentBalance = lpBalanceFor(accounting, senderAddress);
    assert (currentBalance >= lpAmount) throw Errors.LAUNCHPAD_INSUFFICIENT_LP_BALANCE;
    val payout = (redeemableCollateral * lpAmount) / market.lpSupply;
    assert (payout > 0) throw Errors.ZERO_REDEMPTION;
    assert (marketYield.collateral >= payout) throw Errors.LAUNCHPAD_NO_REDEEMABLE_COLLATERAL;
    assert (lpYield.collateralTotal >= payout) throw Errors.LAUNCHPAD_NO_REDEEMABLE_COLLATERAL;
    // Deprecated cap machinery (HIGH fix): the floor is now inside marketYield.collateral, so
    // there is no separate sub-floor pool to decrement. floorPayout stays 0 (its bounce restore
    // no-ops). lpSettlementFloorCollateral is left untouched.
    val floorPayout: int64 = 0;

    accounting.lpBalances.set(senderAddress, currentBalance - lpAmount);
    market.lpSupply -= lpAmount;
    marketYield.collateral -= payout;
    market.lpYield = marketYield.toCell();
    market.accounting = accounting.toCell();
    lpYield.collateralTotal -= payout;
    extra.lpYield = lpYield.toCell();
    extra.markets.set(msg.marketId, market);
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitLaunchpadEvent(
        8,
        storage,
        msg.marketId,
        senderAddress,
        market.lifecycle,
        payout,
        lpAmount,
    );

    val transfer: JettonTransfer = {
        queryId: msg.queryId,
        amount: payout,
        destination: msg.recipientOwner,
        responseDestination: msg.responseDestination,
        customPayload: LpYieldRestore {
            marketId: msg.marketId,
            trader: senderAddress,
            lpAmount,
            payout,
            floorPayout,
        }.toCell(),
        forwardTonAmount: msg.forwardTonAmount,
        forwardPayload: msg.forwardPayload,
    };
    val outMsg = createMessage({
        bounce: BounceMode.RichBounce,
        value: msg.jettonTransferValue,
        dest: lpYield.wallet,
        body: transfer,
    });
    outMsg.send(SEND_MODE_REGULAR);
}

fun executeRedeemLpFromJetton(
    mutate storage: Storage,
    senderAddress: address,
    inValue: coins,
    lpTokenAmount: coins,
    tokenOwner: address,
    payload: LpJettonRedeemPayload,
) {
    assert (lpTokenAmount > 0) throw Errors.NON_POSITIVE_AMOUNT;
    assert (lpTokenAmount <= 9223372036854775807) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
    val lpAmount = lpTokenAmount as int64;
    assert (payload.jettonTransferValue > 0) throw Errors.NON_POSITIVE_AMOUNT;
    assert (payload.forwardTonAmount > 0) throw Errors.NON_POSITIVE_AMOUNT;
    assert (
        inValue >=
        requiredJettonSendValue(payload.jettonTransferValue, payload.forwardTonAmount) +
        lpJettonBurnValue()
    ) throw Errors.INSUFFICIENT_MESSAGE_VALUE;

    var extra = storage.extra.load();
    var lpYield = extra.lpYield.load();
    val result = extra.markets.get(payload.marketId);
    assert (result.isFound) throw Errors.LAUNCHPAD_MARKET_NOT_FOUND;
    var market = result.loadValue();
    val refs = market.refs.load();
    val detail = refs.detail.load();
    val lpToken = detail.lpJetton.load();
    assert (lpToken.lpJettonEnabled) throw Errors.LAUNCHPAD_LP_JETTON_MODE_MISMATCH;
    assert (senderAddress == lpToken.lpJettonWallet) throw Errors.JETTON_WALLET_MISMATCH;
    assert (market.lifecycle == lifecycleSettled()) throw Errors.LAUNCHPAD_LIFECYCLE_INVALID;
    assert (market.lpSupply > 0) throw Errors.LAUNCHPAD_NO_LP_SUPPLY;
    var marketYield = market.lpYield.load();
    // HIGH fix (canon settlement-redemption.md): see executeRedeemLp. Redemption opens only once
    // the AMM's LP floor has settled here; marketYield.collateral holds the FULL entitlement
    // (lpYield + swept floor) and is paid pro-rata with no sub-floor cap.
    assert (marketYield.lpSettlementFloorReported) throw Errors.LAUNCHPAD_NO_REDEEMABLE_COLLATERAL;
    assert (marketYield.collateral > 0) throw Errors.LAUNCHPAD_NO_REDEEMABLE_COLLATERAL;
    val redeemableCollateral = marketYield.collateral;

    var accounting = market.accounting.load();
    var ledgerDebited = false;
    val currentBalance = lpBalanceFor(accounting, tokenOwner);
    if (currentBalance >= lpAmount) {
        accounting.lpBalances.set(tokenOwner, currentBalance - lpAmount);
        market.accounting = accounting.toCell();
        ledgerDebited = true;
    }
    val payout = (redeemableCollateral * lpAmount) / market.lpSupply;
    assert (payout > 0) throw Errors.ZERO_REDEMPTION;
    assert (marketYield.collateral >= payout) throw Errors.LAUNCHPAD_NO_REDEEMABLE_COLLATERAL;
    assert (lpYield.collateralTotal >= payout) throw Errors.LAUNCHPAD_NO_REDEEMABLE_COLLATERAL;
    // Deprecated cap machinery (HIGH fix): floor now lives in marketYield.collateral. floorPayout
    // stays 0; lpSettlementFloorCollateral untouched.
    val floorPayout: int64 = 0;

    market.lpSupply -= lpAmount;
    marketYield.collateral -= payout;
    market.lpYield = marketYield.toCell();
    lpYield.collateralTotal -= payout;
    extra.lpYield = lpYield.toCell();
    extra.markets.set(payload.marketId, market);
    storage.sequence += 1;
    storage.extra = extra.toCell();
    storage.save();
    emitLaunchpadEvent(
        8,
        storage,
        payload.marketId,
        tokenOwner,
        market.lifecycle,
        payout,
        lpAmount,
    );

    val burn: BurnJetton = {
        queryId: payload.queryId,
        amount: lpAmount as coins,
        responseDestination: contract.getAddress(),
        customPayload: null,
    };
    val burnMsg = createMessage({
        bounce: BounceMode.NoBounce,
        value: lpJettonBurnValue(),
        dest: lpToken.lpJettonWallet,
        body: burn,
    });
    burnMsg.send(SEND_MODE_REGULAR);

    val transfer: JettonTransfer = {
        queryId: payload.queryId,
        amount: payout,
        destination: payload.recipientOwner,
        responseDestination: payload.responseDestination,
        customPayload: LpTokenRedeemRestore {
            marketId: payload.marketId,
            trader: tokenOwner,
            lpAmount,
            payout,
            floorPayout,
            ledgerDebited,
        }.toCell(),
        forwardTonAmount: payload.forwardTonAmount,
        forwardPayload: payload.forwardPayload,
    };
    val outMsg = createMessage({
        bounce: BounceMode.RichBounce,
        value: payload.jettonTransferValue,
        dest: lpYield.wallet,
        body: transfer,
    });
    outMsg.send(SEND_MODE_REGULAR);
}

// R2-1 S4a: creatorDeposit dropped — it is no longer a free input. The escrowed
// seed is verified == mulLn2(bBase) && >= minCreatorDeposit at the jetton-transfer
// entry, so creation never needs to re-check it here.
fun validateCreateMarketFields(
    storage: Storage,
    marketId: uint32,
    outcomeCount: uint8,
    startTime: int64,
    deadline: int64,
    bBase: int64,
    creatorDeposit: int64,
) {
    assert (marketId > 0) throw Errors.NON_POSITIVE_AMOUNT;
    // Binary-only at creation: the AMM rejects outcomeCount != 2 (executeCreateMarket), so the
    // launchpad must not record a 3-outcome market the AMM would then refuse to initialize.
    assert (outcomeCount == 2) throw Errors.UNKNOWN_OUTCOME;
    assert (startTime >= blockchain.now()) throw Errors.LAUNCHPAD_TIMESTAMP_INVALID;
    assert (deadline > startTime) throw Errors.LAUNCHPAD_TIMESTAMP_INVALID;
    assert (bBase > 0) throw Errors.LAUNCHPAD_AMOUNT_INVALID;
    assert (creatorDeposit > 0) throw Errors.LAUNCHPAD_AMOUNT_INVALID;
    assert (storage.defaultTrialPeriod > 0) throw Errors.LAUNCHPAD_AMOUNT_INVALID;
    // EVM parity: LaunchpadEngine.setDefaultTrialPeriod requires period <= 30 days
    // (LaunchpadEngine.sol:193). 2592000 == 30 * 24 * 3600 seconds.
    assert (storage.defaultTrialPeriod <= 2592000) throw Errors.LAUNCHPAD_AMOUNT_INVALID;
    assert (
        storage.graduationThreshold > 0 && storage.graduationThreshold <= feeBpsDenominator()
    ) throw Errors.LAUNCHPAD_AMOUNT_INVALID;
}

fun validateComponentDeploy(config: ComponentDeployConfig, expectedCodeHash: uint256) {
    assert (config.value > 0) throw Errors.NON_POSITIVE_AMOUNT;
    assert (expectedCodeHash != 0) throw Errors.LAUNCHPAD_CODE_HASH_MISMATCH;
    assert (config.code.hash() == expectedCodeHash) throw Errors.LAUNCHPAD_CODE_HASH_MISMATCH;
}

fun computeTrialEnd(storage: Storage, startTime: int64, deadline: int64) {
    var trialDuration = storage.defaultTrialPeriod;
    // EVM LaunchpadEngine.sol:432 caps the trial at 30% of the time-to-deadline, but SKIPS that
    // cap for infinite-deadline markets (they use the full defaultTrialPeriod) — matched below.
    // (At the sentinel, (deadline - startTime) * 3 is huge but computed in TVM's 257-bit math, so
    // without the skip the cap simply wouldn't bind; the skip mirrors EVM intent cleanly.) The
    // trial still expires for infinite markets (matches EVM) — only the deadline-relative cap is off.
    if (deadline != infiniteDeadline()) {
        val durationToDeadline = deadline - startTime;
        val maxTrialDuration = (durationToDeadline * 3) / 10;
        if (trialDuration > maxTrialDuration) {
            trialDuration = maxTrialDuration;
        }
    }
    return startTime + trialDuration;
}

fun requireAdmin(extra: StorageExtra, senderAddress: address) {
    assert (senderAddress == extra.admin) throw Errors.ADMIN_UNAUTHORIZED;
}

fun requireOperator(extra: StorageExtra, senderAddress: address) {
    assert (
        senderAddress == extra.admin || senderAddress == extra.operatorAddress
    ) throw Errors.ADMIN_UNAUTHORIZED;
}

// Operator autonomy: fee accrual is authed to the market's own AMM (the autonomous driver of
// accrual + graduation), with admin/operator retained as break-glass. ammAddress is the
// per-market AMM the launchpad already records, so a wrong-market AMM cannot accrue here.
fun requireAmmOrOperator(extra: StorageExtra, senderAddress: address, ammAddress: address) {
    assert (
        senderAddress == ammAddress || senderAddress == extra.admin ||
        senderAddress == extra.operatorAddress
    ) throw Errors.ADMIN_UNAUTHORIZED;
}

fun requireRegistryOrAdmin(extra: StorageExtra, senderAddress: address) {
    assert (
        senderAddress == extra.admin || senderAddress == extra.registryAddress
    ) throw Errors.ADMIN_UNAUTHORIZED;
}

fun lpBalanceFor(accounting: MarketAccounting, owner: address): int64 {
    val result = accounting.lpBalances.get(owner);
    if (result.isFound) {
        return result.loadValue();
    }
    return 0;
}

fun restoreLpYield(
    mutate marketYield: LpYieldMarket,
    mutate lpYield: LpYieldCustody,
    payout: int64,
    floorPayout: int64,
): void {
    assert (
        marketYield.collateral <= 9223372036854775807 - payout
    ) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
    assert (
        lpYield.collateralTotal <= 9223372036854775807 - payout
    ) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
    assert (floorPayout >= 0) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
    if (floorPayout > 0) {
        assert (
            marketYield.lpSettlementFloorReported
        ) throw Errors.LAUNCHPAD_BOUNCE_RESTORE_MISMATCH;
        assert (
            marketYield.lpSettlementFloorCollateral <= 9223372036854775807 - floorPayout
        ) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
        marketYield.lpSettlementFloorCollateral += floorPayout;
    }
    marketYield.collateral += payout;
    lpYield.collateralTotal += payout;
}

// requiredJettonSendValue is shared via jetton.tolk.

fun createMarketLpJettonValue(): coins {
    return ton("0.18");
}

fun lpJettonMintValue(): coins {
    return ton("0.08");
}

fun lpJettonBurnValue(): coins {
    return ton("0.04");
}

fun feeBpsDenominator() {
    return 10000;
}

// R2-1 fix: op tag of LpYieldDepositPayload, used by the JettonTransferNotification multiplex
// to distinguish a post-graduation LP-yield collateral deposit from a market-creation seed
// (both arrive at the launchpad's collateral wallet). Must equal the struct prefix above.
fun lpYieldDepositOpcode(): uint32 {
    return 0x6c797064;
}

// HIGH fix: forward-payload op tag for the AMM's post-settlement LP-floor sweep. Must match the
// SettlementFloorDepositPayload struct prefix here and the AMM's stamp in sooth_amm_core.tolk.
fun settlementFloorDepositOpcode(): uint32 {
    return 0x73666c64;
}

// Creator liquidity top-up: the forward-payload op tag (0x696e636c "incl") that routes a
// creator's collateral deposit into executeIncreaseLiquidityFromJetton. Must match the
// IncreaseLiquidityPayload struct prefix and the wrapper's builder.
fun increaseLiquidityOpcode(): uint32 {
    return 0x696e636c;
}

// EVM fee parity (1/2): the post-graduation distribution shares (bBase/lpYield/adjudicator
// /protocol) are now operator-set protocol-level config in the launchpad Storage
// (executeSetFeeDistribution, the 10000-sum check), replacing the hardcoded
// postGraduation*Bps() constants. executeAccrueFees reads storage.{bBase,lpYield,
// adjudicator,protocol}Bps. Deploy defaults (5000/3000/1000/1000) are stamped by the SDK.

// R2-1 S1: seed-sizing math (EVM parity for market creation).
//
// TON is 50%-only (the AMM forces yes=no=0 at creation), so the EVM
// `depositWad = logSumExp(bBase, qYes, qNo)` collapses to `depositWad = bBase * ln(2)`.
// In the AMM's fixed-point world this is exactly `lmsrCostFixed(_, 0, 0, 0) =
// liquidity * lnFixed(2 * fixedScale())` (sooth_amm_core.tolk:2302-2318: maxInventory=0,
// sumExp = expFixed(0) + expFixed(0) = 2 * fixedScale(), so the cost reduces to
// liquidity * lnFixed(2 * fixedScale())). ceilFixed of that fixed-point cost is the seed
// the launchpad must escrow so the seed exactly backs the AMM's initial reserve
// requirement at inventory (0,0).
//
// `ln2Fixed()` is the VERIFIED on-chain value of the AMM's `lnFixed(2 * fixedScale())`
// (sooth_amm_core.tolk:2347-2360 evaluated in the TVM emulator == 693147174). NOTE: this
// is 693147174, NOT 693147180559945309/1e9 == 693147181 from the EVM `LN2_WAD` (the
// r2-1 design doc's 693147181 is the EVM-rounded value; the TON AMM's own Taylor-series
// lnFixed truncates to 693147174). We mirror the AMM's own constant so the seed equals
// the AMM cost EXACTLY, not the EVM WAD approximation. Proven in
// tests/r2-1-seed-math.spec.ts and pinned natively in tests/SoothLaunchpadSeed.test.tolk
// (launchpad side) + tests/SoothAmmMath.test.tolk (AMM side).
fun fixedScale(): int {
    return 1000000000;
}

fun ln2Fixed(): int {
    return 693147174;
}

// CEIL of bBase * ln(2): seed >= AMM cost at (0,0), mirroring EVM `fromWadCeil`.
fun mulLn2(bBase: int): int {
    return (bBase * ln2Fixed() + fixedScale() - 1) / fixedScale();
}

// Creator-set initial probability (EVM LMSRMath parity). The launchpad is the trust
// boundary (it verifies amount == seed), so it must DERIVE (qYes, qNo) from (bBase,
// probBps) and compute the seed itself — never trust a caller-supplied inventory. To do
// that on-chain it needs the same fixed-point primitives the AMM uses to price the curve.
//
// These five primitives (expFixed / expPositiveFixed / lnFixed / ceilFixed / floorFixed)
// are copied VERBATIM (bit-for-bit) from sooth_amm_core.tolk (~2747-2792). Bit-for-bit
// equality with the AMM is the whole point: the launchpad-derived seed MUST equal the
// reserve cost the AMM computes from the same inventory, or the `amount == seed` check
// would reject a correctly-funded market (or accept an under-funded one). The cross-
// contract pin is asserted natively in tests/SoothLaunchpadSeed.test.tolk (launchpad ==
// AMM lnFixed/expFixed over a range) and tests/r2-1-seed-math.spec.ts. DO NOT "improve"
// these — any change must be mirrored in BOTH contracts and re-pinned.
fun expFixed(value: int) {
    if (value < -50000000000) {
        return 0;
    }
    if (value < 0) {
        val positive = expPositiveFixed(-value);
        return (fixedScale() * fixedScale()) / positive;
    }
    return expPositiveFixed(value);
}

fun expPositiveFixed(value: int) {
    var term = fixedScale();
    var sum = fixedScale();
    var n = 1;
    repeat (60) {
        term = (term * value) / (fixedScale() * n);
        sum += term;
        n += 1;
    }
    return sum;
}

fun lnFixed(value: int) {
    assert (value > 0) throw Errors.FIXED_POINT_VALUE_NON_POSITIVE;
    val z = ((value - fixedScale()) * fixedScale()) / (value + fixedScale());
    val z2 = (z * z) / fixedScale();
    var term = z;
    var sum = 0;
    var denominator = 1;
    repeat (40) {
        sum += term / denominator;
        term = (term * z2) / fixedScale();
        denominator += 2;
    }
    return 2 * sum;
}

fun ceilFixed(value: int) {
    assert (value >= 0) throw Errors.FIXED_POINT_VALUE_NEGATIVE;
    return (value + fixedScale() - 1) / fixedScale();
}

fun floorFixed(value: int) {
    assert (value >= 0) throw Errors.FIXED_POINT_VALUE_NEGATIVE;
    return value / fixedScale();
}

// Binary LMSR cost at inventory (qYes, qNo) — the launchpad twin of the AMM's
// lmsrCostFixed for outcomeCount == 2 (markets are binary-only at creation). Mirrors
// sooth_amm_core.tolk:2725-2741 exactly with maybeInventory dropped: maxInventory is the
// larger of the two, sumExp = exp((qYes-max)/b) + exp((qNo-max)/b), cost = max*scale +
// b*ln(sumExp). At (0,0) this collapses to b*lnFixed(2*scale) == bBase*ln(2) == mulLn2(b).
fun lmsrCostBinaryFixed(liquidity: int, yesInventory: int, noInventory: int): int {
    var maxInventory = yesInventory;
    if (noInventory > maxInventory) {
        maxInventory = noInventory;
    }
    var sumExp = expFixed(((yesInventory - maxInventory) * fixedScale()) / liquidity);
    sumExp += expFixed(((noInventory - maxInventory) * fixedScale()) / liquidity);
    return (maxInventory * fixedScale()) + (liquidity * lnFixed(sumExp));
}

// Seed = CEIL of the binary LMSR cost at the creator's initial inventory (qYes, qNo).
// CEIL (never floor) so the escrowed seed always backs the AMM's reserve requirement at
// that inventory, mirroring EVM `fromWadCeil` on `logSumExp(b, qYes, qNo)`. The 50/50
// case (0,0) is byte-identical to mulLn2(bBase) by construction (both ceil of the same
// fixed-point cost b*lnFixed(2*scale)); pinned in tests/SoothLaunchpadSeed.test.tolk.
fun lmsrSeedFixed(bBase: int, yesInventory: int, noInventory: int): int {
    return ceilFixed(lmsrCostBinaryFixed(bBase, yesInventory, noInventory));
}

// Creator-set initial probability -> initial inventory (qYes, qNo) in atoms, mirroring
// EVM LMSRMath.calculateInitialQuantities (~251-284). Probability is BASIS POINTS (1..9999;
// 5000 == 50%), matching the launchpad's existing bps convention. FLOOR rounding on the
// inventory atoms (EVM floors qYes/qNo); one side > 0, the other exactly 0; 50% -> (0, 0).
//
//   p > 50%: logit = ln(p / (1-p)); qYes = floor(bBase * logit / scale), qNo = 0
//   p < 50%: logit = ln((1-p) / p); qNo = floor(bBase * logit / scale), qYes = 0
//
// ratioFixed scales p/(1-p) into fixedScale units before lnFixed. Validated against the
// EVM parity table (LAYER3-CREATOR.md, b=1000: 60% -> qYes 405, 70% -> qYes 847) in
// tests/r2-1-seed-skew.spec.ts and natively in tests/SoothLaunchpadSeed.test.tolk.
// Returns (qYes, qNo). Caller clamps to maxInventoryAtoms / reverts on int64 overflow.
fun calculateInitialQuantities(bBase: int, probBps: int): (int, int) {
    assert (probBps >= 1 && probBps <= 9999) throw Errors.LAUNCHPAD_AMOUNT_INVALID;
    if (probBps == 5000) {
        return (0, 0);
    }
    if (probBps > 5000) {
        val ratioFixed = (probBps * fixedScale()) / (10000 - probBps);
        val logit = lnFixed(ratioFixed);
        val qYes = floorFixed(bBase * logit);
        return (qYes, 0);
    }
    val ratioFixed = ((10000 - probBps) * fixedScale()) / probBps;
    val logit = lnFixed(ratioFixed);
    val qNo = floorFixed(bBase * logit);
    return (0, qNo);
}

// Map the wire probability (0 == default-50/50 sentinel, else 1..9999 bps) to the seed
// inventory (qYes, qNo) the launchpad will both size the seed from AND record. The AMM
// stores inventory as int64 atoms, so a revert here on extreme odds (qYes/qNo > int64 max)
// is the launchpad-side guard the instruction calls for — the launchpad does not know the
// AMM's maxInventoryAtoms, so the int64 ceiling is the hard bound it can enforce; the AMM's
// own executeCreateMarket re-checks min/maxInventoryAtoms when it receives the inventory.
fun resolveSeedInventory(
    bBase: int64,
    initialProbabilityBps: uint32,
    collateralConfig: LaunchpadCollateralConfig,
): (int, int) {
    val probBps = initialProbabilityBps == 0 ? 5000 : (initialProbabilityBps as int);
    val (qYes, qNo) = calculateInitialQuantities(bBase, probBps);
    // Inventory is one-sided (the other is exactly 0) and non-negative by construction.
    assert (qYes >= 0 && qNo >= 0) throw Errors.LAUNCHPAD_AMOUNT_INVALID;
    assert (qYes == 0 || qNo == 0) throw Errors.LAUNCHPAD_AMOUNT_INVALID;
    // Revert on odds so extreme the derived inventory would not fit the AMM's int64 fields.
    assert (
        qYes <= 9223372036854775807 && qNo <= 9223372036854775807
    ) throw Errors.NUMERIC_BOUNDS_EXCEEDED;
    return (qYes, qNo);
}

fun pow10(exponent: int): int {
    var result = 1;
    repeat (exponent) {
        result *= 10;
    }
    return result;
}

// EVM `MIN_DEPOSIT_WAD = 10e18` -> on TON, 10 collateral tokens in atoms.
// DEFINED but NOT enforced this stage (enforcement is R2-1 S4).
fun minCreatorDeposit(collateralDecimals: int): int {
    return 10 * pow10(collateralDecimals);
}

fun sendRegistryRegistration(
    registryAddress: address,
    marketId: uint32,
    market: LaunchpadMarket,
    refs: MarketRefs,
    detail: MarketDetail,
): void {
    val registryDetail: RegistryMarketDetail = {
        collateralJettonMaster: detail.collateralJettonMaster,
        creator: detail.creator,
    };
    val registryExtra: RegistryRegisterMarketExtra = {
        bookAddress: refs.bookAddress,
        engineAddress: refs.engineAddress,
        adjudicatorAddress: refs.adjudicatorAddress,
        detail: registryDetail.toCell(),
    };
    val registerMarket: RegisterMarket = {
        marketId,
        ammAddress: market.ammAddress,
        outcomeCount: market.outcomeCount,
        deadline: market.deadline,
        trialEnd: market.trialEnd,
        registeredAt: blockchain.now() as int64,
        extra: registryExtra.toCell(),
    };
    val registerMsg = createMessage({
        bounce: BounceMode.NoBounce,
        value: ton("0.05"),
        dest: registryAddress,
        body: registerMarket,
    });
    registerMsg.send(SEND_MODE_REGULAR);
}

fun sendRegistryFactoryRegistration(
    registryAddress: address,
    marketId: uint32,
    market: LaunchpadMarket,
    refs: MarketRefs,
    detail: MarketDetail,
    ammCollateralJettonWallet: address,
    engineCollateralJettonWallet: address,
): void {
    val factoryConfig: RegistryFactoryConfig = {
        ammCollateralJettonWallet,
        engineCollateralJettonWallet,
    };
    val registryDetail: RegistryFactoryMarketDetail = {
        collateralJettonMaster: detail.collateralJettonMaster,
        creator: detail.creator,
        config: factoryConfig.toCell(),
    };
    val registryExtra: RegistryRegisterFactoryMarketExtra = {
        bookAddress: refs.bookAddress,
        engineAddress: refs.engineAddress,
        adjudicatorAddress: refs.adjudicatorAddress,
        detail: registryDetail.toCell(),
    };
    val registerMarket: RegisterFactoryMarket = {
        marketId,
        ammAddress: market.ammAddress,
        outcomeCount: market.outcomeCount,
        deadline: market.deadline,
        trialEnd: market.trialEnd,
        registeredAt: blockchain.now() as int64,
        extra: registryExtra.toCell(),
    };
    val registerMsg = createMessage({
        bounce: BounceMode.RichBounce,
        // H-1 fix: 0.17 -> 0.25 to fund the registry's two new factory-setup sends (engine <-
        // AMM collateral wallet, AMM <- order engine) in sendFactoryComponentConfiguration.
        value: ton("0.25"),
        dest: registryAddress,
        body: registerMarket,
    });
    registerMsg.send(SEND_MODE_REGULAR);
}

fun calculateComponentDeploy(config: ComponentDeployConfig, workchain: int8): AutoDeployAddress {
    return { workchain, stateInit: { code: config.code, data: config.data } };
}

fun sendFactoryComponentDeploy(dest: AutoDeployAddress, value: coins): void {
    val deployMsg = createMessage({
        bounce: BounceMode.NoBounce,
        value,
        dest,
        body: beginCell().endCell(),
    });
    deployMsg.send(SEND_MODE_REGULAR);
}

fun requiredFactoryCreateMarketValue(
    ammDeploy: ComponentDeployConfig,
    bookDeploy: ComponentDeployConfig,
    engineDeploy: ComponentDeployConfig,
): coins {
    // H-1 fix: +0.06 over the prior 0.22 to fund the registry's two new factory-setup sends
    // (engine <- AMM collateral wallet, AMM <- order engine) at ~0.03 each.
    // The adjudicator term was removed in the adjudicator-decoupling change — the contract
    // is pre-existing, so no deploy value is needed here. Net effect: a factory create-market
    // is ~0.12 TON cheaper than before.
    return ammDeploy.value + bookDeploy.value + engineDeploy.value + ton("0.28");
}

fun sendRegistryLaunchAbort(registryAddress: address, marketId: uint32): void {
    val abort: AbortUnconfirmedLaunch = { marketId };
    val abortMsg = createMessage({
        bounce: BounceMode.NoBounce,
        value: ton("0.03"),
        dest: registryAddress,
        body: abort,
    });
    abortMsg.send(SEND_MODE_REGULAR);
}

fun sendAdjudicatorConfiguration(
    adjudicatorAddress: address,
    marketId: uint32,
    resolver: address,
    deadline: int64,
): void {
    val configure: ConfigureAdjudicatorMarket = {
        marketId,
        resolver,
        deadline,
    };
    val configureMsg = createMessage({
        bounce: BounceMode.NoBounce,
        value: ton("0.05"),
        dest: adjudicatorAddress,
        body: configure,
    });
    configureMsg.send(SEND_MODE_REGULAR);
}

fun sendFactoryAdjudicatorConfiguration(
    adjudicatorAddress: address,
    marketId: uint32,
    resolver: address,
    deadline: int64,
): void {
    val configure: ConfigureAdjudicatorMarket = {
        marketId,
        resolver,
        deadline,
    };
    val configureMsg = createMessage({
        bounce: BounceMode.RichBounce,
        value: ton("0.05"),
        dest: adjudicatorAddress,
        body: configure,
    });
    configureMsg.send(SEND_MODE_REGULAR);
}

fun sendRegistryLifecycleUpdate(
    registryAddress: address,
    marketId: uint32,
    lifecycle: uint8,
    winningOutcome: uint8,
    timestamp: int64,
): void {
    val update: SetRegistryLifecycle = {
        marketId,
        lifecycle,
        winningOutcome,
        timestamp,
        tStar: 0,
    };
    val updateMsg = createMessage({
        bounce: BounceMode.NoBounce,
        value: ton("0.05"),
        dest: registryAddress,
        body: update,
    });
    updateMsg.send(SEND_MODE_REGULAR);
}

fun sendAmmLaunchpadYieldRoute(
    ammAddress: address,
    marketId: uint32,
    amount: int64,
    bBaseAmount: int64,
    adjudicatorAmount: int64,
    protocolAmount: int64,
): void {
    if (amount > 0 || bBaseAmount > 0 || adjudicatorAmount > 0 || protocolAmount > 0) {
        val forwardPayload = beginCell()
            .storeUint(1, 1)
            .storeRef(LpYieldDepositPayload { marketId: marketId }.toCell())
            .toSlice();
        val route: RouteLaunchpadYield = {
            marketId,
            amount: amount as coins,
            bBaseAmount: bBaseAmount as coins,
            adjudicatorAmount: adjudicatorAmount as coins,
            protocolAmount: protocolAmount as coins,
            recipientOwner: contract.getAddress(),
            responseDestination: contract.getAddress(),
            queryId: blockchain.logicalTime() as uint64,
            jettonTransferValue: launchpadYieldJettonTransferValue(),
            forwardTonAmount: launchpadYieldForwardTonAmount(),
            forwardPayload,
        };
        val routeMsg = createMessage({
            bounce: BounceMode.NoBounce,
            value: launchpadYieldRouteValue(),
            dest: ammAddress,
            body: route,
        });
        routeMsg.send(SEND_MODE_REGULAR);
    }
}

// EVM fee parity (FeeRouter._distributePreGrad): tell the market's AMM to deepen its LMSR
// curve from the bonding-trade fee it already holds in feeCollateral. collateral == the fee,
// deltaB == floor(fee * fixedScale / ln2Fixed) (== fee/ln2). The AMM banks `collateral`
// feeCollateral->reserveCollateral and does liquidity += deltaB via the SAME phase-agnostic
// helper the post-grad path uses. NoBounce: a pure-accounting message with no restorable
// launchpad-side state — if it fails to land the fee simply stays in the AMM's feeCollateral
// (re-sendable, never lost). Auth on the AMM is senderAddress == launchpadFeeRouter == this
// launchpad, the SAME gate as sendAmmLaunchpadYieldRoute. Value mirrors the other AMM accrual
// signals (SetGraduated / FeeRouteConfirmed) — pure accounting, no jetton transfer to fund.
fun sendAmmDeepenFromBondingFee(
    ammAddress: address,
    marketId: uint32,
    collateral: int64,
    deltaB: int64,
): void {
    if (collateral > 0 && deltaB > 0) {
        val deepen: DeepenFromBondingFee = {
            marketId,
            collateral: collateral as coins,
            deltaB: deltaB as coins,
        };
        val deepenMsg = createMessage({
            bounce: BounceMode.NoBounce,
            value: ton("0.02"),
            dest: ammAddress,
            body: deepen,
        });
        deepenMsg.send(SEND_MODE_REGULAR);
    }
}

// R2-1 S4b: forward the escrowed seed collateral to the AMM. We send a standard
// JettonTransfer to the launchpad's OWN collateral jetton wallet (`collateralJettonWallet`),
// with `destination` == the AMM address (the recipient OWNER). The launchpad's wallet
// derives the AMM's collateral wallet and routes the seed there; the AMM's wallet then
// delivers a JettonTransferNotification{sender == launchpad}, which the AMM credits to the
// launchpad's trader-ledger and acks (SeedCollateralAck). RichBounce so that a failed
// forward bounces with a SeedForwardRestore payload -> the escrow is rolled back + the
// market can be aborted (no orphaned seed). forwardTonAmount funds the AMM's ack send.
fun sendSeedToAmm(
    launchpadCollateralWallet: address,
    ammAddress: address,
    marketId: uint32,
    seed: int64,
): void {
    val transfer: JettonTransfer = {
        queryId: blockchain.logicalTime() as uint64,
        amount: seed as coins,
        destination: ammAddress,
        responseDestination: contract.getAddress(),
        customPayload: SeedForwardRestore { marketId, seed }.toCell(),
        forwardTonAmount: seedForwardTonAmount(),
        forwardPayload: beginCell().endCell().beginParse(),
    };
    val outMsg = createMessage({
        bounce: BounceMode.RichBounce,
        value: seedForwardValue(),
        dest: launchpadCollateralWallet,
        body: transfer,
    });
    outMsg.send(SEND_MODE_REGULAR);
}

// Creator liquidity top-up: forward the creator's verified top-up deposit to the AMM's
// collateral wallet (clone of sendSeedToAmm). The deposit lands as the launchpad's AMM
// trader-collateral and the AMM acks (IncreaseReserveAck). RichBounce so a failed forward
// returns the deposit + clears the pending top-up (IncreaseReserveForwardRestore). The empty
// forwardPayload makes this an ordinary collateral deposit at the AMM (the router-ledger +
// reserve>0 detector classifies it as a top-up).
fun sendIncreaseLiquidityToAmm(
    launchpadCollateralWallet: address,
    ammAddress: address,
    marketId: uint32,
    deposit: int64,
): void {
    val transfer: JettonTransfer = {
        queryId: blockchain.logicalTime() as uint64,
        amount: deposit as coins,
        destination: ammAddress,
        responseDestination: contract.getAddress(),
        customPayload: IncreaseReserveForwardRestore { marketId, deposit }.toCell(),
        forwardTonAmount: seedForwardTonAmount(),
        forwardPayload: beginCell().endCell().beginParse(),
    };
    val outMsg = createMessage({
        bounce: BounceMode.RichBounce,
        value: seedForwardValue(),
        dest: launchpadCollateralWallet,
        body: transfer,
    });
    outMsg.send(SEND_MODE_REGULAR);
}

// R2-1 fix: refund the launchpad-held seed escrow to the creator on abort. Structurally a
// JettonTransfer of the escrowed creatorDeposit from the launchpad's own collateral wallet
// (which holds the escrow while seedHeldByLaunchpad) to the creator's wallet, mirroring
// sendSeedToAmm. RichBounce + SeedEscrowRefundRestore keep a (rare) failed delivery
// dispatch-safe; the abort caller funds the send value (seedForwardValue).
fun sendSeedEscrowRefund(
    launchpadCollateralWallet: address,
    marketId: uint32,
    creator: address,
    amount: int64,
): void {
    val transfer: JettonTransfer = {
        queryId: blockchain.logicalTime() as uint64,
        amount: amount as coins,
        destination: creator,
        responseDestination: contract.getAddress(),
        customPayload: SeedEscrowRefundRestore { marketId, creator, amount }.toCell(),
        forwardTonAmount: seedForwardTonAmount(),
        forwardPayload: beginCell().endCell().beginParse(),
    };
    val outMsg = createMessage({
        bounce: BounceMode.RichBounce,
        value: seedForwardValue(),
        dest: launchpadCollateralWallet,
        body: transfer,
    });
    outMsg.send(SEND_MODE_REGULAR);
}

// R2-1 S4b: fire SeedReserve to the AMM once the ack proves the seed has landed. The AMM
// auth-gates it to launchpadFeeRouter (== this launchpad) and the first-seed reserve==0
// guard, promoting the launchpad's trader-collateral into reserveCollateral. RichBounce:
// a SeedReserve bounce (e.g. reserve became non-zero) routes to the abort path.
fun sendSeedReserveToAmm(ammAddress: address, marketId: uint32, seed: int64): void {
    val reserve: SeedReserve = { marketId, amount: seed as coins };
    val outMsg = createMessage({
        bounce: BounceMode.RichBounce,
        value: ton("0.03"),
        dest: ammAddress,
        body: reserve,
    });
    outMsg.send(SEND_MODE_REGULAR);
}

// Creator liquidity top-up: fire IncreaseReserve to the AMM once the ack proves the top-up
// deposit landed (clone of sendSeedReserveToAmm). The AMM auth-gates it to launchpadFeeRouter
// (== this launchpad), promotes the deposit into reserve and deepens the curve by additionalB.
// RichBounce: an IncreaseReserve bounce routes to executeIncreaseReserveBounced.
fun sendIncreaseReserveToAmm(
    ammAddress: address,
    marketId: uint32,
    deposit: int64,
    additionalB: int64,
): void {
    val reserve: IncreaseReserve = {
        marketId,
        amount: deposit as coins,
        additionalB: additionalB as coins,
    };
    val outMsg = createMessage({
        bounce: BounceMode.RichBounce,
        value: ton("0.03"),
        dest: ammAddress,
        body: reserve,
    });
    outMsg.send(SEND_MODE_REGULAR);
}

fun seedForwardValue(): coins {
    return ton("0.1");
}

fun seedForwardTonAmount(): coins {
    return ton("0.05");
}

fun sendAmmFeeRouteConfirmed(
    ammAddress: address,
    marketId: uint32,
    trader: address,
    amount: int64,
    launchpadSequence: uint32,
): void {
    val confirmation: LaunchpadFeeRouteConfirmed = {
        marketId,
        trader,
        amount,
        launchpadSequence,
    };
    val outMsg = createMessage({
        bounce: BounceMode.NoBounce,
        value: ton("0.01"),
        dest: ammAddress,
        body: confirmation,
    });
    outMsg.send(SEND_MODE_REGULAR);
}

// EVM fee parity (1/2): tell the market's AMM it graduated so it switches preGrad ->
// postGrad fee. Sent once when willGraduate flips. WithBounce so a transient AMM failure
// is observable (onBouncedMessage re-sends once, NoBounce, to terminate any loop). The
// AMM handler is idempotent + router-authorized, so re-delivery is safe.
fun sendAmmSetGraduated(ammAddress: address, marketId: uint32): void {
    val graduated: SetAmmGraduated = { marketId };
    val outMsg = createMessage({
        bounce: BounceMode.RichBounce,
        value: ton("0.02"),
        dest: ammAddress,
        body: graduated,
    });
    outMsg.send(SEND_MODE_REGULAR);
}

// EVM parity: best-effort trial-expiry halt to the market's AMM. NoBounce — a bounce has no
// restorable state, and the market settles INVALID via the trial-expired path regardless; for
// launchpad-created markets the AMM's launchpadFeeRouter == this launchpad, so it lands.
fun sendAmmHaltTrading(ammAddress: address, marketId: uint32): void {
    val halt: HaltTrading = { marketId };
    val outMsg = createMessage({
        bounce: BounceMode.NoBounce,
        value: ton("0.02"),
        dest: ammAddress,
        body: halt,
    });
    outMsg.send(SEND_MODE_REGULAR);
}

// EVM fee parity (2/2): stamp the configured adjudicator into the market's AMM. Sent on
// RegistryLaunchConfirmed (factory setup done => AMM launchpadFeeRouter == launchpad, the
// AMM-side auth gate). NoBounce: a bounce here would have no restorable state and we never
// want to re-enter creation on a transient AMM failure; if it fails to land the AMM simply
// has no adjudicator stamped and the operator re-sends (the adjudicator can't self-claim
// until then, a liveness-only concern — never a fund loss).
fun sendAmmSetAdjudicatorAddress(
    ammAddress: address,
    marketId: uint32,
    adjudicatorAddress: address,
): void {
    val stamp: SetAdjudicatorAddress = { marketId, adjudicatorAddress };
    val outMsg = createMessage({
        bounce: BounceMode.NoBounce,
        value: ton("0.02"),
        dest: ammAddress,
        body: stamp,
    });
    outMsg.send(SEND_MODE_REGULAR);
}

// H-1 fix: stamp the market's order engine into the AMM. Sent on RegistryLaunchConfirmed
// (factory setup done => AMM launchpadFeeRouter == launchpad, the AMM-side auth gate),
// alongside sendAmmSetAdjudicatorAddress. NoBounce for the same reason: a bounce has no
// restorable state; if it fails to land the AMM simply will not classify engine-fee deposits
// (they would fall to traderCollateral as a normal deposit — recoverable, never a fund loss),
// and the operator re-sends. A liveness-only concern.
fun sendAmmSetOrderEngine(ammAddress: address, marketId: uint32, orderEngine: address): void {
    val stamp: SetAmmOrderEngine = { marketId, orderEngine };
    val outMsg = createMessage({
        bounce: BounceMode.NoBounce,
        value: ton("0.02"),
        dest: ammAddress,
        body: stamp,
    });
    outMsg.send(SEND_MODE_REGULAR);
}

// Loop-free retry of the graduation signal on bounce: NoBounce so a persistent AMM
// failure cannot re-enter this path. Residual risk (noted in the report): if even this
// retry fails to land, the AMM keeps charging the preGrad rate (a higher fee for traders,
// never a fund loss or solvency issue); recovery is a manual operator re-send.
fun resendAmmSetGraduated(ammAddress: address, marketId: uint32): void {
    val graduated: SetAmmGraduated = { marketId };
    val outMsg = createMessage({
        bounce: BounceMode.NoBounce,
        value: ton("0.02"),
        dest: ammAddress,
        body: graduated,
    });
    outMsg.send(SEND_MODE_REGULAR);
}

fun sendLpJettonMintIfConfigured(
    detail: MarketLpJettonDetail,
    owner: address,
    amount: coins,
): void {
    if (detail.lpJettonEnabled) {
        val mint: MintJetton = {
            owner,
            amount,
            responseDestination: contract.getAddress(),
            forwardTonAmount: 0,
        };
        val mintMsg = createMessage({
            bounce: BounceMode.NoBounce,
            value: lpJettonMintValue(),
            dest: detail.lpJettonMaster,
            body: mint,
        });
        mintMsg.send(SEND_MODE_REGULAR);
    }
}

fun launchpadYieldRouteValue(): coins {
    return ton("0.04");
}

fun launchpadYieldJettonTransferValue(): coins {
    return ton("0.03");
}

fun launchpadYieldForwardTonAmount(): coins {
    return ton("0.01");
}

fun emitLaunchpadEvent(
    kind: uint32,
    storage: Storage,
    marketId: uint32,
    actor: address,
    lifecycle: uint8,
    amount: int64,
    aux: int64,
): void {
    val eventMsg = createExternalLogMessage({
        dest: ExtOutLogBucket { topic: kind as uint248 },
        body: SoothLaunchpadEvent {
            kind,
            marketId,
            sequence: storage.sequence,
            actor,
            lifecycle,
            amount,
            aux,
        },
    });
    eventMsg.send(SEND_MODE_REGULAR);
}

// R2-1 S4b: the AMM-reserve seed confirmation bit (mirrors the AMM's
// factorySetupAmmSeedMask() == 16). The AMM emits FactorySetupConfirmed{setup:16}
// to the launchpad after a successful SeedReserve.
fun factorySetupAmmSeedMask(): uint8 {
    return 16;
}

// Creator liquidity top-up: the AMM-reserve top-up confirmation bit (mirrors the AMM's
// factorySetupAmmIncreaseMask() == 32). The AMM emits FactorySetupConfirmed{setup:32}
// to the launchpad after a successful IncreaseReserve, triggering the launchpad commit.
fun factorySetupAmmIncreaseMask(): uint8 {
    return 32;
}

// Lifecycle + INVALID-outcome helpers are shared via lifecycle.tolk (single source of truth).

fun settlementVenueLaunchpad(): uint8 {
    return 4;
}

fun sendRegistrySettlementConfirmation(
    registryAddress: address,
    marketId: uint32,
    venue: uint8,
    winningOutcome: uint8,
    venueSequence: uint32,
): void {
    val confirmation: SettlementConfirmed = {
        marketId,
        venue,
        winningOutcome,
        venueSequence,
    };
    val outMsg = createMessage({
        bounce: BounceMode.NoBounce,
        value: ton("0.005"),
        dest: registryAddress,
        body: confirmation,
    });
    outMsg.send(SEND_MODE_REGULAR);
}

get fun launchpadState() {
    val storage = lazy Storage.load();
    val extra = storage.extra.load();
    val lpYield = extra.lpYield.load();
    return (
        storage.sequence,
        storage.marketCount,
        storage.defaultTrialPeriod,
        storage.graduationThreshold,
        storage.paused,
        extra.admin,
        lpYield.pendingAdmin,
        lpYield.pendingAdminReadyAt,
        extra.operatorAddress,
        extra.registryAddress,
        lpYield.wallet,
        lpYield.collateralTotal,
        storage.preGradFeeNumerator,
        storage.postGradFeeNumerator,
        storage.feeDenominator,
        storage.bBaseBps,
        storage.lpYieldBps,
        storage.adjudicatorBps,
        storage.protocolBps,
    );
}

// R2-1 S1: expose the deploy-time collateral config (EVM immutable baseToken/decimals).
// Present + exposed but UNUSED by creation logic this stage (S4 switches creation over).
get fun launchpadCollateralConfig() {
    val storage = lazy Storage.load();
    val extra = storage.extra.load();
    val collateralConfig = extra.collateralConfig.load();
    return (
        collateralConfig.collateralJettonMaster,
        collateralConfig.collateralJettonWallet,
        collateralConfig.collateralDecimals,
        minCreatorDeposit(collateralConfig.collateralDecimals),
    );
}

get fun market(marketId: uint32) {
    val storage = lazy Storage.load();
    val extra = storage.extra.load();
    val result = extra.markets.get(marketId);
    assert (result.isFound) throw Errors.LAUNCHPAD_MARKET_NOT_FOUND;
    val market = result.loadValue();
    val marketYield = market.lpYield.load();
    val refs = market.refs.load();
    val detail = refs.detail.load();
    val lpToken = detail.lpJetton.load();
    return (
        marketId,
        market.ammAddress,
        refs.bookAddress,
        refs.engineAddress,
        refs.adjudicatorAddress,
        detail.collateralJettonMaster,
        detail.creator,
        market.lifecycle,
        market.outcomeCount,
        market.startTime,
        market.deadline,
        market.trialEnd,
        market.bBase,
        market.creatorDeposit,
        market.feeAccrued,
        marketYield.collateral,
        marketYield.adjudicatorFees,
        marketYield.protocolFees,
        market.graduationThreshold,
        market.lpSupply,
        market.graduatedAt,
        market.expiredAt,
        marketYield.settledAt,
        marketYield.winningOutcome,
        marketYield.lpSettlementFloorCollateral,
        marketYield.lpSettlementFloorReported,
        marketYield.registryConfirmedAt,
        marketYield.adjudicatorConfirmedAt,
        marketYield.creatorLpJettonMinted,
        lpToken.lpJettonMaster,
        lpToken.lpJettonWallet,
        lpToken.lpJettonEnabled,
        marketYield.seedRequired,
        marketYield.seedForwarded,
        marketYield.seedConfirmedAt,
        marketYield.seedQYes,
        marketYield.seedQNo,
    );
}

get fun lpBalance(marketId: uint32, owner: address) {
    val storage = lazy Storage.load();
    val extra = storage.extra.load();
    val result = extra.markets.get(marketId);
    assert (result.isFound) throw Errors.LAUNCHPAD_MARKET_NOT_FOUND;
    val market = result.loadValue();
    val accounting = market.accounting.load();
    return lpBalanceFor(accounting, owner);
}

get fun isGraduated(marketId: uint32) {
    val storage = lazy Storage.load();
    val extra = storage.extra.load();
    val result = extra.markets.get(marketId);
    assert (result.isFound) throw Errors.LAUNCHPAD_MARKET_NOT_FOUND;
    val market = result.loadValue();
    return market.lifecycle == lifecycleLive();
}

get fun isTrialExpiredWithoutGraduation(marketId: uint32) {
    val storage = lazy Storage.load();
    val extra = storage.extra.load();
    val result = extra.markets.get(marketId);
    assert (result.isFound) throw Errors.LAUNCHPAD_MARKET_NOT_FOUND;
    val market = result.loadValue();
    return market.lifecycle == lifecycleTrialExpired() && market.graduatedAt == 0;
}
