type StonFiTlbEither<X, Y> = StonFiTlbEitherLeft<X> | StonFiTlbEitherRight<Y>

@inline
fun StonFiTlbEither<X, Y>.left(value: X): StonFiTlbEitherLeft<X> {
    return StonFiTlbEitherLeft { value };
}

@inline
fun StonFiTlbEither<X, Y>.right(value: Y): StonFiTlbEitherRight<Y> {
    return StonFiTlbEitherRight { value };
}

struct (0b0) StonFiTlbEitherLeft<X> {
    value: X
}

struct (0b1) StonFiTlbEitherRight<X> {
    value: X
}

enum Errors {
    NotOwner = 100
    InvalidSwapConfig = 0x1001
    InvalidReferralFee = 0x1002
    InvalidForwardTonAmount = 0x1003
    InvalidRoutePreset = 0x1004
    InvalidMessage = 0xFFFF
}

struct RoutePresetRoutes {
    sourceWalletAddress: address
    routerWalletAddress: address
    firstHopReceiverAddress: address
}

struct RoutePresetTokens {
    tokenWallet1Address: address
}

struct RoutePresetTargets {
    secondRouterWalletAddress: address
    receiverAddress: address
    referrerAddress: address
}

struct RoutePresetFees {
    refundAddress: address
    excessesAddress: address
    fwdGas: coins
    refundFwdGas: coins
}

struct RoutePreset {
    routes: Cell<RoutePresetRoutes>
    tokens: Cell<RoutePresetTokens>
    targets: Cell<RoutePresetTargets>
    fees: Cell<RoutePresetFees>
}

struct Storage {
    id: uint32
    owner: address
    routePreset: RoutePreset?
}

fun Storage.load(): Storage {
    return Storage.fromCell(contract.getData());
}

fun Storage.save(self) {
    contract.setData(self.toCell());
}

fun RoutePreset.loadRoutes(self): RoutePresetRoutes {
    return self.routes.load();
}

fun RoutePreset.loadTokens(self): RoutePresetTokens {
    return self.tokens.load();
}

fun RoutePreset.loadTargets(self): RoutePresetTargets {
    return self.targets.load();
}

fun RoutePreset.loadFees(self): RoutePresetFees {
    return self.fees.load();
}

fun RoutePreset.validate(self): void {
    val fees = self.loadFees();
    assert (fees.fwdGas > 0) throw Errors.InvalidRoutePreset;
    assert (fees.refundFwdGas > 0) throw Errors.InvalidRoutePreset;
}

fun unwrapRoutePreset(value: RoutePreset?): RoutePreset {
    if (value == null) {
        throw Errors.InvalidRoutePreset;
    }

    return value;
}

struct SwapRouteBody {
    minOut: coins
    receiver: address
    fwdGas: coins
    customPayload: cell?
    refundFwdGas: coins
    refundPayload: cell?
    refFee: uint16
    refAddress: address
}

fun SwapRouteBody.withCustomPayload(self, customPayload: cell?): SwapRouteBody {
    return SwapRouteBody {
        minOut: self.minOut,
        receiver: self.receiver,
        fwdGas: self.fwdGas,
        customPayload,
        refundFwdGas: self.refundFwdGas,
        refundPayload: self.refundPayload,
        refFee: self.refFee,
        refAddress: self.refAddress,
    };
}

struct SwapPlan {
    tokenWallet1: address
    refundAddress: address
    excessesAddress: address
    txDeadline: uint64
    routeBody: Cell<SwapRouteBody>
}

fun SwapPlan.validateForSwap(self): void {
    val routeBody = self.routeBody.load();
    assert (routeBody.customPayload == null) throw Errors.InvalidSwapConfig;
    assert (routeBody.refFee <= 100) throw Errors.InvalidReferralFee;
}

fun SwapPlan.validateForSimpleSwapWithReferral(self): void {
    self.validateForSwap();
    assert (self.routeBody.load().refFee > 0) throw Errors.InvalidReferralFee;
}

fun SwapPlan.validateForRefundSwap(self): void {
    self.validateForSwap();
    assert (self.routeBody.load().refFee == 0) throw Errors.InvalidReferralFee;
}

fun SwapPlan.validateForCrossSwapFirstLeg(self): void {
    self.validateForSwap();
    assert (self.routeBody.load().fwdGas > 0) throw Errors.InvalidForwardTonAmount;
}

struct (0x6664de2a) StonFiSwapPayload {
    tokenWallet1: address
    refundAddress: address
    excessesAddress: address
    txDeadline: uint64
    routeBody: Cell<SwapRouteBody>
}

struct (0x69cf1a5b) StonFiCrossSwapPayload {
    tokenWallet1: address
    refundAddress: address
    excessesAddress: address
    txDeadline: uint64
    routeBody: Cell<SwapRouteBody>
}

fun buildStonFiSwapPayload(plan: SwapPlan, customPayload: cell? = null): StonFiSwapPayload {
    val routeBody = plan.routeBody.load();
    return StonFiSwapPayload {
        tokenWallet1: plan.tokenWallet1,
        refundAddress: plan.refundAddress,
        excessesAddress: plan.excessesAddress,
        txDeadline: plan.txDeadline,
        routeBody: routeBody.withCustomPayload(customPayload).toCell(),
    };
}

fun buildStonFiCrossSwapPayload(plan: SwapPlan): StonFiCrossSwapPayload {
    return StonFiCrossSwapPayload {
        tokenWallet1: plan.tokenWallet1,
        refundAddress: plan.refundAddress,
        excessesAddress: plan.excessesAddress,
        txDeadline: plan.txDeadline,
        routeBody: plan.routeBody,
    };
}

fun buildStonFiMultiRouterSwapPayload(
    firstPlan: SwapPlan,
    secondPlan: SwapPlan,
): StonFiSwapPayload {
    return buildStonFiSwapPayload(firstPlan, buildStonFiSwapPayload(secondPlan).toCell());
}

struct (0x0f8a7ea5) JettonTransfer {
    queryId: uint64
    amount: coins
    destination: address
    responseDestination: address
    customPayload: cell?
    forwardTonAmount: coins
    forwardPayload: StonFiTlbEither<RemainingBitsAndRefs, Cell<RemainingBitsAndRefs>>
}

struct (0x5f5a0001) ExecuteSimpleSwapWithReferral {
    queryId: uint64
    sourceWalletAddress: address
    routerWalletAddress: address
    amount: coins
    forwardTonAmount: coins
    swapPlan: Cell<SwapPlan>
}

struct (0x5f5a0002) ExecuteCrossSwapSameRouter {
    queryId: uint64
    sourceWalletAddress: address
    routerWalletAddress: address
    amount: coins
    forwardTonAmount: coins
    firstPlan: Cell<SwapPlan>
    secondPlan: Cell<SwapPlan>
}

struct (0x5f5a0003) ExecuteRefundSwap {
    queryId: uint64
    sourceWalletAddress: address
    routerWalletAddress: address
    amount: coins
    forwardTonAmount: coins
    swapPlan: Cell<SwapPlan>
}

struct (0x5f5a0004) UpdateRoutePreset {
    routePreset: RoutePreset
}

struct (0x5f5a0005) ExecuteCrossSwapDifferentRouters {
    queryId: uint64
    sourceWalletAddress: address
    routerWalletAddress: address
    amount: coins
    forwardTonAmount: coins
    firstPlan: Cell<SwapPlan>
    secondPlan: Cell<SwapPlan>
}
