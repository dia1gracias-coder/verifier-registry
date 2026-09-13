import "../common/consts"
import "../common/errors"
import "../vendor/jetton/messages"
import "relay-messages"

contract PotRelay {
    author: "GRAMDESKS"
    version: "0.1.0"
    description: "Escrow relay for the Pot: holds the Omniston position so the bought stock (delivered without forward TON) can be flushed to the Pot with a transfer notification. Only ever transfers to the Pot."
    storage: PotRelayStorage
    incomingMessages: AllowedMessageToRelay
}

type AllowedMessageToRelay =
    | TransferNotificationForRecipient
    | Flush
    | SetRelayRoles
    | SetUsdtWallet
    | ReturnExcessesBack

/// Minimum value a Flush must carry: jetton transfer compute + forward to the Pot + the Pot's own settlement compute.
const FLUSH_MIN_VALUE = ton("0.1")
/// Forward TON attached to every transfer to the Pot: enough for the Pot's `TransferNotificationForRecipient` handler.
const FLUSH_FORWARD_TON = ton("0.05")

fun onInternalMessage(in: InMessage) {
    var storage = lazy PotRelayStorage.load();
    val msg = lazy AllowedMessageToRelay.fromSlice(in.body);

    match (msg) {
        TransferNotificationForRecipient => {
            // Only USDT sent by the Pot opens a position. Anything else (stock deliveries, third-party USDT) is
            // simply kept in the corresponding wallet until someone flushes it to the Pot.
            if (storage.usdtWallet == null || in.senderAddress != storage.usdtWallet! || msg.transferInitiator == null || msg.transferInitiator! != storage.pot) {
                return;
            }
            val usdtWallet = storage.usdtWallet!;
            var p = msg.forwardPayload;
            val (fwdBits, fwdRefs) = p.remainingBitsAndRefsCount();
            // the Pot always sends the order as a ref (Either bit = 1)
            assert (fwdBits >= 1 && fwdRefs == 1 && p.loadBool()) throw Errors.IncorrectForwardPayload;
            val order = RelayOrder.fromCell(p.loadRef());
            assert (order.owner == storage.pot) throw Errors.PayloadOwnerMismatch;

            val transfer = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: usdtWallet,
                value: 0,
                body: AskToTransfer {
                    queryId: order.queryId,
                    jettonAmount: msg.jettonAmount,
                    transferRecipient: storage.escrowMinter,
                    sendExcessesTo: contract.getAddress(),
                    customPayload: null,
                    forwardTonAmount: order.swapForwardTon,
                    forwardPayload: beginCell().storeBool(true).storeRef(order.swap).endCell().beginParse(),
                },
            });
            transfer.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        Flush => {
            assert (in.valueCoins >= FLUSH_MIN_VALUE) throw Errors.InsufficientValue;
            if (storage.usdtWallet != null && msg.jettonWallet == storage.usdtWallet!) {
                // USDT leaves only on the keeper's say-so: a third party could otherwise refund a position in flight
                val roles = lazy storage.roles.load();
                assert (in.senderAddress == roles.keeper || in.senderAddress == roles.admin) throw Errors.NotFromKeeper;
            }
            val transfer = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: msg.jettonWallet,
                value: 0,
                body: AskToTransfer {
                    queryId: msg.queryId,
                    jettonAmount: msg.amount,
                    transferRecipient: storage.pot,
                    sendExcessesTo: in.senderAddress,
                    customPayload: null,
                    forwardTonAmount: FLUSH_FORWARD_TON,
                    forwardPayload: emptyForwardPayload(),
                },
            });
            transfer.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        SetRelayRoles => {
            val roles = lazy storage.roles.load();
            assert (in.senderAddress == roles.admin) throw Errors.NotFromAdmin;
            storage.roles = RelayRoles { admin: msg.admin, keeper: msg.keeper }.toCell();
            storage.save();
        }

        SetUsdtWallet => {
            val roles = lazy storage.roles.load();
            assert (in.senderAddress == roles.admin) throw Errors.NotFromAdmin;
            storage.usdtWallet = msg.usdtWallet;
            storage.save();
        }

        ReturnExcessesBack => {
            // gas excesses from our own jetton transfers: keep, they fund storage
        }

        else => {
            // plain TON top-ups are welcome; unknown opcodes bounce
            assert (in.body.isEmpty() || in.body.preloadUint(32) == 0) throw 0xFFFF;
        }
    }
}

fun onBouncedMessage(in: InMessageBounced) {
    // a rejected transfer (wrong wallet, insufficient balance) leaves the relay untouched
}

get fun get_relay_data(): RelayDataReply {
    val storage = lazy PotRelayStorage.load();
    val roles = lazy storage.roles.load();
    return {
        pot: storage.pot,
        escrowMinter: storage.escrowMinter,
        usdtWallet: storage.usdtWallet,
        admin: roles.admin,
        keeper: roles.keeper,
    };
}
