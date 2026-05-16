import "stonfi_swap_types"

contract StonFiSwap {
    author: "OpenAI"
    version: "0.1.0"
    description: "STON.fi swap POC contract"
    storage: Storage
    incomingMessages: AllowedMessage
}

type AllowedMessage =
    | UpdateRoutePreset
    | ExecuteSimpleSwapWithReferral
    | ExecuteCrossSwapSameRouter
    | ExecuteCrossSwapDifferentRouters
    | ExecuteRefundSwap

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessage.fromSlice(in.body);

    match (msg) {
        UpdateRoutePreset => {
            handleUpdateRoutePreset(in.senderAddress, msg);
        }
        ExecuteSimpleSwapWithReferral => {
            handleSimpleSwapWithReferral(in.senderAddress, msg);
        }
        ExecuteCrossSwapSameRouter => {
            handleCrossSwapSameRouter(in.senderAddress, msg);
        }
        ExecuteCrossSwapDifferentRouters => {
            handleCrossSwapDifferentRouters(in.senderAddress, msg);
        }
        ExecuteRefundSwap => {
            handleRefundSwap(in.senderAddress, msg);
        }
        else => {
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
        }
    }
}

fun handleUpdateRoutePreset(senderAddress: address, msg: UpdateRoutePreset) {
    val storage = lazy Storage.load();
    assert (storage.owner == senderAddress) throw Errors.NotOwner;
    msg.routePreset.validate();

    var updatedStorage = storage;
    updatedStorage.routePreset = msg.routePreset;
    updatedStorage.save();
}

fun handleSimpleSwapWithReferral(senderAddress: address, msg: ExecuteSimpleSwapWithReferral) {
    val storage = lazy Storage.load();
    assert (storage.owner == senderAddress) throw Errors.NotOwner;
    assert (msg.amount > 0) throw Errors.InvalidSwapConfig;
    assert (msg.forwardTonAmount > 0) throw Errors.InvalidForwardTonAmount;
    val swapPlan = msg.swapPlan.load();
    swapPlan.validateForSimpleSwapWithReferral();

    val transfer = buildJettonTransfer(
        swapPlan.excessesAddress,
        msg.queryId,
        msg.amount,
        msg.routerWalletAddress,
        msg.forwardTonAmount,
        buildStonFiSwapPayload(swapPlan),
    );
    sendJettonTransfer(msg.sourceWalletAddress, transfer);
}

fun handleCrossSwapSameRouter(senderAddress: address, msg: ExecuteCrossSwapSameRouter) {
    val storage = lazy Storage.load();
    assert (storage.owner == senderAddress) throw Errors.NotOwner;
    assert (msg.amount > 0) throw Errors.InvalidSwapConfig;
    assert (msg.forwardTonAmount > 0) throw Errors.InvalidForwardTonAmount;
    val firstPlan = msg.firstPlan.load();
    val secondPlan = msg.secondPlan.load();
    firstPlan.validateForCrossSwapFirstLeg();
    secondPlan.validateForSwap();

    val crossPayload = buildStonFiCrossSwapPayload(secondPlan).toCell();
    val firstPayload = buildStonFiSwapPayload(firstPlan, crossPayload);
    val transfer = buildJettonTransfer(
        firstPlan.excessesAddress,
        msg.queryId,
        msg.amount,
        msg.routerWalletAddress,
        msg.forwardTonAmount,
        firstPayload,
    );
    sendJettonTransfer(msg.sourceWalletAddress, transfer);
}

fun handleCrossSwapDifferentRouters(senderAddress: address, msg: ExecuteCrossSwapDifferentRouters) {
    val storage = lazy Storage.load();
    assert (storage.owner == senderAddress) throw Errors.NotOwner;
    assert (msg.amount > 0) throw Errors.InvalidSwapConfig;
    assert (msg.forwardTonAmount > 0) throw Errors.InvalidForwardTonAmount;
    val firstPlan = msg.firstPlan.load();
    val secondPlan = msg.secondPlan.load();
    firstPlan.validateForCrossSwapFirstLeg();
    secondPlan.validateForSwap();

    val multiRouterPayload = buildStonFiMultiRouterSwapPayload(firstPlan, secondPlan);
    val transfer = buildJettonTransfer(
        firstPlan.excessesAddress,
        msg.queryId,
        msg.amount,
        msg.routerWalletAddress,
        msg.forwardTonAmount,
        multiRouterPayload,
    );
    sendJettonTransfer(msg.sourceWalletAddress, transfer);
}

fun handleRefundSwap(senderAddress: address, msg: ExecuteRefundSwap) {
    val storage = lazy Storage.load();
    assert (storage.owner == senderAddress) throw Errors.NotOwner;
    assert (msg.amount > 0) throw Errors.InvalidSwapConfig;
    assert (msg.forwardTonAmount > 0) throw Errors.InvalidForwardTonAmount;
    val swapPlan = msg.swapPlan.load();
    swapPlan.validateForRefundSwap();

    val transfer = buildJettonTransfer(
        swapPlan.excessesAddress,
        msg.queryId,
        msg.amount,
        msg.routerWalletAddress,
        msg.forwardTonAmount,
        buildStonFiSwapPayload(swapPlan),
    );
    sendJettonTransfer(msg.sourceWalletAddress, transfer);
}

fun buildJettonTransfer(
    responseDestination: address,
    queryId: uint64,
    amount: coins,
    destination: address,
    forwardTonAmount: coins,
    swapPayload: StonFiSwapPayload,
): JettonTransfer {
    return JettonTransfer {
        queryId,
        amount,
        destination,
        responseDestination,
        customPayload: null,
        forwardTonAmount,
        forwardPayload: StonFiTlbEither.right(
            swapPayload.toCell() as cell as Cell<RemainingBitsAndRefs>,
        ),
    };
}

fun sendJettonTransfer(sourceWalletAddress: address, transfer: JettonTransfer) {
    val transferMessage = createMessage({
        bounce: true,
        value: ton("0"),
        dest: sourceWalletAddress,
        body: transfer,
    });

    transferMessage.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
}

fun onBouncedMessage(_in: InMessageBounced) {}

get fun routePreset(): RoutePreset? {
    val storage = lazy Storage.load();

    return storage.routePreset;
}

get fun owner(): address {
    val storage = lazy Storage.load();

    return storage.owner;
}
