const DEPLOY_MESSAGE_OP = 1;
const JETTON_TRANSFER_NOTIFICATION_OP = 0x7362d09c;
const AUTHORIZE_WALLET_OP = 2584504897;
const REVOKE_WALLET_OP = 2827734651;

const ERR_ONLY_OWNER = 401;
const ERR_UNAUTHORIZED_WALLET = 402;

struct (0x7362d09c) JettonTransferNotification {
    queryId: uint64;
    amount: coins;
    sender: address;
    forwardPayload: cell;
}

struct (0x0f8a7ea5) JettonTransferInternal {
    queryId: uint64;
    amount: coins;
    destination: address;
    responseDestination: address;
    customPayload: cell?;
    forwardTonAmount: coins;
    forwardPayload: cell?;
}

fun loadStorage(): (address, map<address, bool>) {
    var ds = contract.getData().beginParse();
    ds.loadUint(1); // reserved prefix bit for compatibility with current wrapper init data
    val owner = ds.loadAddress();

    var walletsLowLevel: dict = null;
    if (!ds.isEmpty()) {
        walletsLowLevel = ds.loadDict();
    }

    return (owner, createMapFromLowLevelDict<address, bool>(walletsLowLevel));
}

fun saveStorage(owner: address, wallets: map<address, bool>) {
    val data = beginCell()
        .storeUint(0, 1)
        .storeAddress(owner)
        .storeDict(wallets.toLowLevelDict())
        .endCell();
    contract.setData(data);
}

fun isWalletAuthorizedInMap(wallets: map<address, bool>, wallet: address): bool {
    val r = wallets.get(wallet);
    return r.isFound && r.loadValue();
}

fun sendJettonTransfer(
    originalQueryId: uint64,
    originalSender: address,
    jettonWallet: address,
    destination: address,
    amount: coins,
    forwardTonAmount: coins,
    forwardPayload: cell?,
    carryAll: bool
) {
    if (amount <= 0) {
        return;
    }

    val sendMode = carryAll ? SEND_MODE_CARRY_ALL_BALANCE : SEND_MODE_PAY_FEES_SEPARATELY;

    createMessage({
        bounce: false,
        value: (50000000 + forwardTonAmount),
        dest: jettonWallet,
        body: JettonTransferInternal {
            queryId: originalQueryId,
            amount: amount,
            destination: destination,
            responseDestination: originalSender,
            customPayload: null,
            forwardTonAmount: forwardTonAmount,
            forwardPayload: forwardPayload,
        },
    }).send(sendMode);
}

fun sendJettonBack(transfer: JettonTransferNotification, jettonWallet: address) {
    sendJettonTransfer(
        transfer.queryId,
        transfer.sender,
        jettonWallet,
        transfer.sender,
        transfer.amount,
        0,
        null,
        false
    );
}

fun sendJettonBackByData(queryId: uint64, sender: address, amount: coins, jettonWallet: address) {
    sendJettonTransfer(
        queryId,
        sender,
        jettonWallet,
        sender,
        amount,
        0,
        null,
        false
    );
}

fun processDistribution(
    queryId: uint64,
    amount: coins,
    sender: address,
    jettonWallet: address,
    forwardPayload: cell
) {
    var payload = forwardPayload.beginParse();

    try {
        val primaryTo = payload.loadAddress();
        val primaryValue = payload.loadCoins();
        val primaryForwardAmount = payload.loadCoins();
        val primaryBody = payload.loadRef();

        var secondaryTo: address? = null;
        var secondaryValue: coins = 0;
        var tailTo: address? = null;
        var tailValue: coins = 0;

        try {
            secondaryTo = payload.loadAddress();
            secondaryValue = payload.loadCoins();
        } catch {
        }

        if (secondaryTo != null) {
            try {
                tailTo = payload.loadAddress();
                tailValue = payload.loadCoins();
            } catch {
            }
        }

        var totalToDistribute: coins = primaryValue;
        if (secondaryTo != null) {
            totalToDistribute += secondaryValue;
        }
        if (tailTo != null) {
            totalToDistribute += tailValue;
        }

        if (totalToDistribute > amount) {
            sendJettonBackByData(queryId, sender, amount, jettonWallet);
            return;
        }

        val remainingAmount = amount - totalToDistribute;
        val hasRemaining = remainingAmount > 0;

        sendJettonTransfer(
            queryId,
            sender,
            jettonWallet,
            primaryTo,
            primaryValue,
            primaryForwardAmount,
            primaryBody,
            (secondaryTo == null) && (tailTo == null) && !hasRemaining
        );

        if (secondaryTo != null) {
            sendJettonTransfer(
                queryId,
                sender,
                jettonWallet,
                secondaryTo!!,
                secondaryValue,
                0,
                null,
                (tailTo == null) && !hasRemaining
            );
        }

        if (tailTo != null) {
            sendJettonTransfer(
                queryId,
                sender,
                jettonWallet,
                tailTo!!,
                tailValue,
                0,
                null,
                !hasRemaining
            );
        }

        if (hasRemaining) {
            sendJettonTransfer(
                queryId,
                sender,
                jettonWallet,
                sender,
                remainingAmount,
                0,
                null,
                true
            );
        }
    } catch {
        sendJettonBackByData(queryId, sender, amount, jettonWallet);
    }
}

fun onInternalMessage(in: InMessage) {
    if (in.body.remainingBitsCount() < 32) {
        return;
    }

    val (owner, wallets) = loadStorage();

    var body = in.body;
    val op = body.loadUint(32);

    if (op == DEPLOY_MESSAGE_OP) {
        return;
    }

    if (op == AUTHORIZE_WALLET_OP) {
        assert (in.senderAddress == owner) throw ERR_ONLY_OWNER;
        val wallet = body.loadAddress();
        var updated = wallets;
        updated.set(wallet, true);
        saveStorage(owner, updated);
        return;
    }

    if (op == REVOKE_WALLET_OP) {
        assert (in.senderAddress == owner) throw ERR_ONLY_OWNER;
        val wallet = body.loadAddress();
        var updated = wallets;
        updated.set(wallet, false);
        saveStorage(owner, updated);
        return;
    }

    if (op == JETTON_TRANSFER_NOTIFICATION_OP) {
        assert (isWalletAuthorizedInMap(wallets, in.senderAddress)) throw ERR_UNAUTHORIZED_WALLET;

        try {
            var notifyBody = in.body;
            notifyBody.loadUint(32); // op
            val queryId = notifyBody.loadUint(64);
            val amount = notifyBody.loadCoins();
            val sender = notifyBody.loadAddress();

            // Jetton standard encodes forward_payload as (Either Cell ^Cell).
            // We support the common right branch where payload is in a reference.
            val isRight = notifyBody.loadUint(1);
            if (isRight != 1) {
                sendJettonBackByData(queryId, sender, amount, in.senderAddress);
                return;
            }

            val forwardPayload = notifyBody.loadRef();
            processDistribution(queryId, amount, sender, in.senderAddress, forwardPayload);
        } catch {
            return;
        }
        return;
    }
}

@method_id(201)
fun getOwner(): address {
    val (owner, _) = loadStorage();
    return owner;
}

@method_id(202)
fun isWalletAuthorized(wallet: address): bool {
    val (_, wallets) = loadStorage();
    return isWalletAuthorizedInMap(wallets, wallet);
}
