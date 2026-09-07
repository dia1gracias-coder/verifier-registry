import "@stdlib/gas-payments"
import "errors"
import "fees-management"
import "jetton-messages"
import "jetton-storage"
import "jetton-utils"
import "sharding"

contract StandardJettonWallet {
    author: "Diamond Club / TON reference Jetton v2.1"
    version: "1.0.0"
    description: "Standard TEP-74/TEP-89 Jetton Wallet with burn"
    incomingMessages: AllowedMessageToStandardWallet
    storage: StandardWalletStorage
}

type AllowedMessageToStandardWallet = AskToTransfer | AskToBurn | InternalTransferStep | TopUpTons

type StandardWalletBounce = InternalTransferStep | BurnNotificationForMinter

fun onBouncedMessage(in: InMessageBounced) {
    in.bouncedBody.skipBouncedPrefix();
    val msg = StandardWalletBounce.fromSlice(in.bouncedBody);
    val restoreAmount = match (msg) {
        InternalTransferStep => msg.jettonAmount,
        BurnNotificationForMinter => msg.jettonAmount,
    };

    var storage = lazy StandardWalletStorage.load();
    storage.jettonBalance += restoreAmount;
    storage.save();

    // A successful AskToTransfer followed by a failed InternalTransferStep is
    // otherwise invisible to the wallet owner: the Jettons are restored here,
    // while the original owner contract waits forever for the downstream leg.
    // Emit an authenticated receipt from this wallet after protecting its
    // storage reserve. Burn bounces retain the standard silent behavior.
    match (msg) {
        InternalTransferStep => {
            val originalBalance = contract.getOriginalBalance() - in.valueCoins +
            contract.getStorageDuePayment();
            reserveToncoinsOnBalance(
                max(originalBalance, calculateJettonWalletMinStorageFee()),
                RESERVE_MODE_AT_MOST,
            );
            val receipt = createMessage({
                bounce: BounceMode.NoBounce,
                dest: storage.ownerAddress,
                value: 0,
                body: JettonTransferFailed {
                    queryId: msg.queryId,
                    jettonAmount: msg.jettonAmount,
                },
            });
            // SAFETY: storage rent is protected above and the receipt is a
            // best-effort owner notification carrying only bounced remainder.
            receipt.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS);
        }
        BurnNotificationForMinter => {}
    }
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessageToStandardWallet.fromSlice(in.body);

    match (msg) {
        InternalTransferStep => {
            var storage = lazy StandardWalletStorage.load();
            if (in.senderAddress != storage.minterAddress) {
                assert (
                    in.senderAddress ==
                    calcAddressOfStandardJettonWallet(
                        msg.transferInitiator!,
                        storage.minterAddress,
                        contract.getCode(),
                    )
                ) throw Errors.NotValidWallet;
            }
            storage.jettonBalance += msg.jettonAmount;
            storage.save();

            // TEP-74 does not require a transfer_notification when the sender
            // attaches no explicit forward TON.  A DEX refund is different:
            // STON.fi returns the principal with the Controller as both the
            // recipient owner and the excess destination, preserves the
            // operation payload, but sets forwardTonAmount to zero.  In that
            // exact shape, return the remaining gas with an authenticated
            // transfer_notification instead of a data-less excess.  The
            // recipient can then verify the exact amount, initiating owner and
            // payload; all ordinary zero-forward transfers remain unchanged.
            val zeroForwardOwnerReceipt = msg.forwardTonAmount == 0 && msg.sendExcessesTo != null &&
            msg.sendExcessesTo! == storage.ownerAddress;

            if (msg.forwardTonAmount != 0 || zeroForwardOwnerReceipt) {
                val notification = createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: storage.ownerAddress,
                    value: msg.forwardTonAmount,
                    body: TransferNotificationForRecipient {
                        queryId: msg.queryId,
                        jettonAmount: msg.jettonAmount,
                        transferInitiator: msg.transferInitiator,
                        forwardPayload: msg.forwardPayload,
                    },
                });
                if (zeroForwardOwnerReceipt) {
                    val originalBalance = contract.getOriginalBalance() - in.valueCoins +
                    contract.getStorageDuePayment();
                    reserveToncoinsOnBalance(
                        max(originalBalance, calculateJettonWalletMinStorageFee()),
                        RESERVE_MODE_AT_MOST,
                    );
                    // SAFETY: the wallet reserve is protected above.  This is
                    // the same gas-return path as the standard excess below,
                    // with the principal receipt carried in its body.
                    notification.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS);
                } else {
                    notification.send(
                        SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL,
                    );
                }
            }

            if (msg.sendExcessesTo != null && !zeroForwardOwnerReceipt) {
                val originalBalance = contract.getOriginalBalance() - in.valueCoins +
                contract.getStorageDuePayment();
                reserveToncoinsOnBalance(
                    max(originalBalance, calculateJettonWalletMinStorageFee()),
                    RESERVE_MODE_AT_MOST,
                );
                val excesses = createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: msg.sendExcessesTo,
                    value: 0,
                    body: ReturnExcessesBack { queryId: msg.queryId },
                });
                // SAFETY: the wallet storage reserve is protected by reserveToncoinsOnBalance().
                excesses.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS);
            }
        }

        AskToTransfer => {
            msg.forwardPayload.checkIsCorrectTlbEither();
            assert (
                msg.transferRecipient.getWorkchain() == MY_WORKCHAIN
            ) throw Errors.WrongWorkchain;
            checkAmountIsEnoughToTransfer(
                in.valueCoins,
                msg.forwardTonAmount,
                in.originalForwardFee,
            );

            var storage = lazy StandardWalletStorage.load();
            assert (in.senderAddress == storage.ownerAddress) throw Errors.NotOwner;
            assert (msg.jettonAmount > 0) throw Errors.InvalidAmount;
            assert (storage.jettonBalance >= msg.jettonAmount) throw Errors.Balance;
            storage.jettonBalance -= msg.jettonAmount;
            storage.save();

            val transfer = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: calcDeployedStandardJettonWallet(
                    msg.transferRecipient,
                    storage.minterAddress,
                    contract.getCode(),
                ),
                value: 0,
                body: InternalTransferStep {
                    queryId: msg.queryId,
                    jettonAmount: msg.jettonAmount,
                    transferInitiator: storage.ownerAddress,
                    sendExcessesTo: msg.sendExcessesTo,
                    forwardTonAmount: msg.forwardTonAmount,
                    forwardPayload: msg.forwardPayload,
                },
            });
            transfer.send(
                SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_BOUNCE_ON_ACTION_FAIL,
            );
        }

        AskToBurn => {
            checkAmountIsEnoughToBurn(in.valueCoins);
            var storage = lazy StandardWalletStorage.load();
            assert (in.senderAddress == storage.ownerAddress) throw Errors.NotOwner;
            assert (msg.jettonAmount > 0) throw Errors.InvalidAmount;
            assert (storage.jettonBalance >= msg.jettonAmount) throw Errors.Balance;
            storage.jettonBalance -= msg.jettonAmount;
            storage.save();

            val notification = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: storage.minterAddress,
                value: 0,
                body: BurnNotificationForMinter {
                    queryId: msg.queryId,
                    jettonAmount: msg.jettonAmount,
                    burnInitiator: storage.ownerAddress,
                    sendExcessesTo: msg.sendExcessesTo,
                },
            });
            notification.send(
                SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_BOUNCE_ON_ACTION_FAIL,
            );
        }

        TopUpTons => {}
        else => throw Errors.UnknownOp,
    }
}

get fun get_wallet_data(): StandardJettonWalletDataReply {
    val storage = lazy StandardWalletStorage.load();
    return {
        jettonBalance: storage.jettonBalance,
        ownerAddress: storage.ownerAddress,
        minterAddress: storage.minterAddress,
        jettonWalletCode: contract.getCode(),
    };
}
