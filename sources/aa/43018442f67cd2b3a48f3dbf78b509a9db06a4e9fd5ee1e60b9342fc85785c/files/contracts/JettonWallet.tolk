import "@stdlib/gas-payments"
import "errors"
import "fees-management"
import "jetton-utils"
import "messages"
import "sharding"
import "storage"

// VISB asymmetric transfer guard (master doc v3.5.2, §21.1).
// Pre-2026-10-15 00:00 UTC, only these 5 addresses can be sender OR recipient.
// Post-unlock, all transfers allowed unconditionally (guard becomes no-op).
const VISB_UNLOCK_TS: int = 1792022400

// Whitelist slot 1: Cold (Ledger TON acct 0, VISB master holder)
const VISB_COLD: address = address("UQAYqnXgFIfShpqKIetWSpYSHgoo-3knNEwc2YUlDEh0Dqdy")

// Whitelist slot 2: Hot (VPS-signed, active operator wallet)
const VISB_HOT: address = address("EQB2TvIBFa-pAwOXSI0FGA69pzsHj1XgeKQUEtZvIoJmv3oc")

// Whitelist slot 3: Utilization (VPS-signed, user balance pool)
const VISB_UTILIZATION: address = address("EQAJ_mCjmMrrPamvRDVz2_pASgFESSuCMbxtWlZPgyLZhWZb")

// Whitelist slot 4: Investor allocation v2 (off-VPS, password-manager only)
const VISB_INVESTOR_ALLOCATION_V2: address = address("EQDFqowsHSEvuohd8UGEjBYMtBPohAuFrIH0C7yXyG_dl-y0")

// Whitelist slot 5: Airgap reserve (off-VPS, password-manager only)
const VISB_AIRGAP_RESERVE: address = address("EQAxZDmv8aBcvjBPgcprl1jGayEVigg1dRNpr7JL3A6KBXKH")

@inline
fun isVisbWhitelisted(addr: address): bool {
    return addr == VISB_COLD || addr == VISB_HOT || addr == VISB_UTILIZATION ||
    addr == VISB_INVESTOR_ALLOCATION_V2 ||
    addr == VISB_AIRGAP_RESERVE;
}

contract JettonWallet {
    author: "Acton User"
    version: "1.0.0"
    description: "Standard Jetton Wallet. TEP-74 and TEP-89 compliant"
    storage: WalletStorage
    incomingMessages: AllowedMessageToWallet
}

type AllowedMessageToWallet =
    | AskToTransfer
    | AskToBurn
    | InternalTransferStep
    | TopUpTons

type BounceOpToHandle = InternalTransferStep | BurnNotificationForMinter

fun onBouncedMessage(in: InMessageBounced) {
    in.bouncedBody.skipBouncedPrefix();

    val msg = lazy BounceOpToHandle.fromSlice(in.bouncedBody);
    val restoreAmount = match (msg) {
        InternalTransferStep => msg.jettonAmount,
        BurnNotificationForMinter => msg.jettonAmount,
    };

    var storage = lazy WalletStorage.load();
    storage.jettonBalance += restoreAmount;
    storage.save();
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessageToWallet.fromSlice(in.body);

    match (msg) {
        InternalTransferStep => {
            var storage = lazy WalletStorage.load();
            if (in.senderAddress != storage.minterAddress) {
                assert (
                    in.senderAddress ==
                    calcAddressOfJettonWallet(
                        msg.transferInitiator!,
                        storage.minterAddress,
                        contract.getCode(),
                    )
                ) throw Errors.NotValidWallet;
            }
            storage.jettonBalance += msg.jettonAmount;
            storage.save();

            if (msg.forwardTonAmount != 0) {
                val notifyOwnerMsg = createMessage({
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
                notifyOwnerMsg.send(
                    SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL,
                );
            }

            if (msg.sendExcessesTo != null) {
                val toLeaveOnBalance = contract.getOriginalBalance() - in.valueCoins +
                contract.getStorageDuePayment();
                reserveToncoinsOnBalance(
                    max(toLeaveOnBalance, calculateJettonWalletMinStorageFee()),
                    RESERVE_MODE_AT_MOST,
                );

                val excessesMsg = createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: msg.sendExcessesTo,
                    value: 0,
                    body: ReturnExcessesBack { queryId: msg.queryId },
                });
                // SAFETY: It is safe because of reserveToncoinsOnBalance() called earlier
                excessesMsg.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS);
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

            var storage = lazy WalletStorage.load();

            // VISB asymmetric transfer guard (master doc v3.5.2, §2 item 26).
            // Pre-2026-10-15 00:00 UTC: allow transfer only if either the sender
            // (wallet owner) or the recipient is in the 5-address whitelist.
            // After unlock: guard becomes no-op, all transfers allowed.
            if (blockchain.now() < VISB_UNLOCK_TS) {
                assert (
                    isVisbWhitelisted(storage.ownerAddress) ||
                    isVisbWhitelisted(msg.transferRecipient)
                ) throw Errors.LockedUntilUnlock;
            }

            assert (in.senderAddress == storage.ownerAddress) throw Errors.NotOwner;
            assert (storage.jettonBalance >= msg.jettonAmount) throw Errors.BalanceError;
            storage.jettonBalance -= msg.jettonAmount;
            storage.save();

            val deployMsg = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: calcDeployedJettonWallet(
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
            deployMsg.send(
                SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_BOUNCE_ON_ACTION_FAIL,
            );
        }

        AskToBurn => {
            checkAmountIsEnoughToBurn(in.valueCoins);

            var storage = lazy WalletStorage.load();
            assert (in.senderAddress == storage.ownerAddress) throw Errors.NotOwner;
            assert (storage.jettonBalance >= msg.jettonAmount) throw Errors.BalanceError;
            storage.jettonBalance -= msg.jettonAmount;
            storage.save();

            val notifyMinterMsg = createMessage({
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
            notifyMinterMsg.send(
                SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_BOUNCE_ON_ACTION_FAIL,
            );
        }

        TopUpTons => {
            // just accept tons
        }

        else => throw 0xFFFF,
    }
}

get fun get_wallet_data(): JettonWalletDataReply {
    val storage = lazy WalletStorage.load();

    return {
        jettonBalance: storage.jettonBalance,
        ownerAddress: storage.ownerAddress,
        minterAddress: storage.minterAddress,
        jettonWalletCode: contract.getCode(),
    };
}
