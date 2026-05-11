import "JettonWallet.code"
import "errors"
import "jetton-utils"
import "messages"
import "sharding"
import "storage"

contract JettonMinter {
    author: "Acton User"
    version: "1.0.0"
    description: "Fixed-supply immutable Jetton Minter. TEP-74 and TEP-89 compatible getters/discovery."
    storage: MinterStorage
    incomingMessages: AllowedMessageToMinter
}

type AllowedMessageToMinter =
    | InitializeFixedSupply
    | BurnNotificationForMinter
    | RequestWalletAddress
    | TopUpTons

/// If the one-time initial wallet deployment bounces, allow retry.
/// totalSupply is NOT changed here: supply is fixed in storage and is only reduced by real burns.
fun onBouncedMessage(in: InMessageBounced) {
    in.bouncedBody.skipBouncedPrefix();
    val msg = lazy InternalTransferStep.fromSlice(in.bouncedBody);

    var storage = lazy MinterStorage.load();

    if (msg.jettonAmount == storage.totalSupply) {
        storage.supplyInitialized = false;
        storage.save();
    }
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessageToMinter.fromSlice(in.body);

    match (msg) {
        InitializeFixedSupply => {
            var storage = lazy MinterStorage.load();

            assert (!storage.supplyInitialized) throw 0xFFE0;
            assert (storage.totalSupply > 0) throw 0xFFE1;
            assert (
                storage.initialOwnerAddress.getWorkchain() == MY_WORKCHAIN
            ) throw Errors.WrongWorkchain;

            storage.supplyInitialized = true;
            storage.save();

            reserveToncoinsOnBalance(
                ton("0.01"),
                RESERVE_MODE_EXACT_AMOUNT,
            );

            val jettonWalletCode = jettonWalletCompiledCode();
            val deployMsg = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: calcDeployedJettonWallet(
                    storage.initialOwnerAddress,
                    contract.getAddress(),
                    jettonWalletCode,
                ),
                value: msg.tonAmount,
                body: InternalTransferStep {
                    queryId: msg.queryId,
                    jettonAmount: storage.totalSupply,
                    transferInitiator: null,
                    sendExcessesTo: msg.sendExcessesTo,
                    forwardTonAmount: 0,
                    forwardPayload: beginCell().storeUint(0, 1).endCell().beginParse(),
                },
            });
            deployMsg.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
        }

        BurnNotificationForMinter => {
            var storage = lazy MinterStorage.load();
            val jettonWalletCode = jettonWalletCompiledCode();
            assert (
                in.senderAddress ==
                calcAddressOfJettonWallet(
                    msg.burnInitiator,
                    contract.getAddress(),
                    jettonWalletCode,
                )
            ) throw Errors.NotValidWallet;

            storage.totalSupply -= msg.jettonAmount;
            storage.save();

            if (msg.sendExcessesTo == null) {
                return;
            }

            val excessesMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: msg.sendExcessesTo,
                value: 0,
                body: ReturnExcessesBack { queryId: msg.queryId },
            });
            excessesMsg.send(SEND_MODE_IGNORE_ERRORS | SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        RequestWalletAddress => {
            val ownerAddress: Cell<address>? = msg.includeOwnerAddress
                ? msg.ownerAddress.toCell()
                : null;

            var walletAddress: address? = null;
            if (msg.ownerAddress.getWorkchain() == MY_WORKCHAIN) {
                val jettonWalletCode = jettonWalletCompiledCode();
                walletAddress = calcAddressOfJettonWallet(
                    msg.ownerAddress,
                    contract.getAddress(),
                    jettonWalletCode,
                );
            }

            val respondMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: in.senderAddress,
                value: 0,
                body: ResponseWalletAddress {
                    queryId: msg.queryId,
                    jettonWalletAddress: walletAddress,
                    ownerAddress,
                },
            });
            respondMsg.send(
                SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_BOUNCE_ON_ACTION_FAIL,
            );
        }

        TopUpTons => {
            // Just accept tons.
        }

        else => throw 0xFFFF,
    }
}

get fun get_jetton_data(): JettonDataReply {
    val storage = lazy MinterStorage.load();
    val jettonWalletCode = jettonWalletCompiledCode();

    return {
        totalSupply: storage.totalSupply,
        mintable: false,
        adminAddress: null,
        jettonContent: storage.metadata as Cell<OnchainMetadataReply>,
        jettonWalletCode,
    };
}

get fun get_wallet_address(ownerAddress: address): address {
    val jettonWalletCode = jettonWalletCompiledCode();
    return calcAddressOfJettonWallet(ownerAddress, contract.getAddress(), jettonWalletCode);
}
