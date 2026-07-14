import "@stdlib/gas-payments"
import "shared/constants"
import "shared/errors"
import "shared/fees_management"
import "shared/messages"
import "shared/storage"
import "shared/utils"

type AllowedMessageToMinter =
    | TransferNotificationForRecipient
    | BurnNotificationForMinter
    | RequestWalletAddress
    | SetUsdtWallet
    | ChangeMinterAdmin
    | ChangeMinterContent

fun emptyForwardPayload(): ForwardPayloadRemainder {
    return beginCell().storeBool(false).endCell().beginParse();
}

fun sendUsdtFromReserve(
    usdtJettonWallet: address,
    queryId: uint64,
    usdtAmount: coins,
    recipient: address,
) {
    val transferMsg = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: usdtJettonWallet,
        value: 0,
        body: AskToTransfer {
            queryId,
            jettonAmount: usdtAmount,
            transferRecipient: recipient,
            sendExcessesTo: recipient,
            customPayload: null,
            forwardTonAmount: 0,
            forwardPayload: emptyForwardPayload(),
        },
    });
    transferMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
}

type BounceOpToMinter = InternalTransferStep | AskToTransfer

fun onBouncedMessage(in: InMessageBounced) {
    in.bouncedBody.skipBouncedPrefix();

    val msg = lazy BounceOpToMinter.fromSlice(in.bouncedBody);
    match (msg) {
        InternalTransferStep => {
            var storage = lazy MinterStorage.load();
            storage.totalSupply -= msg.jettonAmount;
            storage.save();
        }
        AskToTransfer => {}
    }
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessageToMinter.fromSlice(in.body);

    match (msg) {
        TransferNotificationForRecipient => {
            var storage = lazy MinterStorage.load();
            assert (storage.usdtJettonWallet != null) throw ERR_USDT_WALLET_NOT_SET;
            assert (in.senderAddress == storage.usdtJettonWallet!) throw ERR_NOT_FROM_USDT_WALLET;

            if (msg.transferInitiator == null) {
                return;
            }
            val depositor = msg.transferInitiator!;
            val usdtAmount = msg.jettonAmount;
            val xtrAmount = mulDivFloor(usdtAmount, ONE_XTR, USDT_UNITS_PER_XTR);

            if ((xtrAmount == 0) | (in.valueCoins < MINT_GAS_REQUIRED)) {
                sendUsdtFromReserve(storage.usdtJettonWallet!, msg.queryId, usdtAmount, depositor);
                return;
            }

            storage.totalSupply += xtrAmount;
            storage.save();

            val mintMsg = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: calcDeployedJettonWallet(
                    depositor,
                    contract.getAddress(),
                    storage.jettonWalletCode
                ),
                value: 0,
                body: InternalTransferStep {
                    queryId: msg.queryId,
                    jettonAmount: xtrAmount,
                    transferInitiator: null,
                    sendExcessesTo: depositor,
                    forwardTonAmount: 0,
                    forwardPayload: emptyForwardPayload(),
                },
            });
            mintMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        BurnNotificationForMinter => {
            var storage = lazy MinterStorage.load();
            assert (
                in.senderAddress ==
                calcAddressOfJettonWallet(
                    msg.burnInitiator,
                    contract.getAddress(),
                    storage.jettonWalletCode
                )
            ) throw ERR_UNAUTHORIZED_BURN;
            assert (storage.usdtJettonWallet != null) throw ERR_USDT_WALLET_NOT_SET;

            val usdtAmount = mulDivFloor(msg.jettonAmount, USDT_UNITS_PER_XTR, ONE_XTR);
            assert (usdtAmount > 0) throw ERR_BURN_PAYOUT_TOO_SMALL;
            assert (in.valueCoins >= BURN_PAYOUT_GAS_REQUIRED) throw ERR_NOT_ENOUGH_TON;

            storage.totalSupply -= msg.jettonAmount;
            storage.save();

            val excessesTo = msg.sendExcessesTo != null ? msg.sendExcessesTo! : msg.burnInitiator;
            val payoutMsg = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: storage.usdtJettonWallet!,
                value: 0,
                body: AskToTransfer {
                    queryId: msg.queryId,
                    jettonAmount: usdtAmount,
                    transferRecipient: msg.burnInitiator,
                    sendExcessesTo: excessesTo,
                    customPayload: null,
                    forwardTonAmount: 0,
                    forwardPayload: emptyForwardPayload(),
                },
            });
            payoutMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        RequestWalletAddress => {
            assert (
                in.valueCoins > in.originalForwardFee + MINIMAL_MESSAGE_VALUE_BOUND
            ) throw ERR_NOT_ENOUGH_AMOUNT_TO_RESPOND;

            var respondOwnerAddress: Cell<address>? = msg.includeOwnerAddress
                ? msg.ownerAddress.toCell()
                : null;

            var walletAddress: address? = null;
            if (msg.ownerAddress.getWorkchain() == BASECHAIN) {
                var storage = lazy MinterStorage.load();
                walletAddress = calcAddressOfJettonWallet(
                    msg.ownerAddress,
                    contract.getAddress(),
                    storage.jettonWalletCode
                );
            }

            val respondMsg = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: in.senderAddress,
                value: 0,
                body: ResponseWalletAddress {
                    queryId: msg.queryId,
                    jettonWalletAddress: walletAddress,
                    ownerAddress: respondOwnerAddress,
                },
            });
            respondMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        SetUsdtWallet => {
            var storage = lazy MinterStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw ERR_NOT_FROM_ADMIN;
            assert (storage.usdtJettonWallet == null) throw ERR_USDT_WALLET_ALREADY_SET;
            storage.usdtJettonWallet = msg.usdtJettonWallet;
            storage.save();
        }

        ChangeMinterAdmin => {
            var storage = lazy MinterStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw ERR_NOT_FROM_ADMIN;
            storage.adminAddress = msg.newAdminAddress;
            storage.save();
        }

        ChangeMinterContent => {
            var storage = lazy MinterStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw ERR_NOT_FROM_ADMIN;
            storage.content = msg.newContent;
            storage.save();
        }

        else => {
            assert (in.body.isEmpty()) throw 0xFFFF;
        }
    }
}

struct JettonDataReply {
    totalSupply: int
    mintable: bool
    adminAddress: address
    jettonContent: cell
    jettonWalletCode: cell
}

get fun get_jetton_data(): JettonDataReply {
    val storage = lazy MinterStorage.load();

    return {
        totalSupply: storage.totalSupply,
        mintable: true, // mintable, but only via USDT deposits
        adminAddress: storage.adminAddress,
        jettonContent: storage.content,
        jettonWalletCode: storage.jettonWalletCode,
    };
}

get fun get_wallet_address(ownerAddress: address): address {
    val storage = lazy MinterStorage.load();
    return calcAddressOfJettonWallet(ownerAddress, contract.getAddress(), storage.jettonWalletCode);
}

struct StablecoinDataReply {
    usdtJettonMaster: address
    usdtJettonWallet: address?
    usdtUnitsPerXtr: int
}

get fun get_stablecoin_data(): StablecoinDataReply {
    val storage = lazy MinterStorage.load();

    return {
        usdtJettonMaster: storage.usdtJettonMaster,
        usdtJettonWallet: storage.usdtJettonWallet,
        usdtUnitsPerXtr: USDT_UNITS_PER_XTR,
    };
}
