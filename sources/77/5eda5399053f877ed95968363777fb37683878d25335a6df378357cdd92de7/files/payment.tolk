tolk 1.2

struct Storage {
    storeWallet: address
    salt: uint32
}

struct (0x11111111) WithdrawTon {
    amount: coins
}

struct (0x22222222) WithdrawJetton {
    contractJettonWallet: address
    amount: coins
}

type Withdraw = WithdrawJetton | WithdrawTon

struct (0x0f8a7ea5) JettonTransfer {
    queryId: uint64
    amount: coins
    destination: address
    responseDestination: address?
    customPayload: cell?
    forwardTonAmount: coins
    forwardPayload: cell?
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy Withdraw.fromSlice(in.body);
    val storage = lazy Storage.fromCell(contract.getData());

    var withdrawMsg: OutMessage;
    match (msg) {
        WithdrawJetton => {
            withdrawMsg = createMessage({
                bounce: BounceMode.NoBounce,
                value: in.valueCoins - 1,
                dest: msg.contractJettonWallet,
                body: JettonTransfer {
                    queryId: 0,
                    amount: msg.amount,
                    destination: storage.storeWallet,
                    responseDestination: in.senderAddress,
                    customPayload: null,
                    forwardTonAmount: 1,
                    forwardPayload: null,
                },
            });
        }
        WithdrawTon => {
            withdrawMsg = createMessage({
                bounce: BounceMode.NoBounce,
                value: msg.amount,
                dest: storage.storeWallet,
            });
        }
        else => {
            return;
        }
    }

    withdrawMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
}
