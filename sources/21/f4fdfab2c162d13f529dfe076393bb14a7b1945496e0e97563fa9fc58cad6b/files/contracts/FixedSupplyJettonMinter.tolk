import "../gen/StandardJettonWallet.code"
import "errors"
import "fees-management"
import "jetton-messages"
import "jetton-storage"
import "jetton-utils"
import "sharding"

contract FixedSupplyJettonMinter {
    author: "Diamond Club / TON reference Jetton v2.1"
    version: "1.0.0"
    description: "Immutable one-shot fixed-supply TEP-74/TEP-89 Jetton master"
    incomingMessages: AllowedMessageToFixedMinter
    storage: FixedMinterStorage
}

type AllowedMessageToFixedMinter =
    | MintNewJettons
    | BurnNotificationForMinter
    | RequestWalletAddress
    | ReserveReady
    | TopUpTons

fun onBouncedMessage(in: InMessageBounced) {
    in.bouncedBody.skipBouncedPrefix();
    val msg = lazy InternalTransferStep.fromSlice(in.bouncedBody);

    var storage = lazy FixedMinterStorage.load();
    assert (
        in.senderAddress ==
        calcAddressOfStandardJettonWallet(
            storage.reserveController,
            contract.getAddress(),
            standardJettonWalletCompiledCode(),
        )
    ) throw Errors.NotValidWallet;
    assert (storage.totalSupply >= msg.jettonAmount) throw Errors.InvalidSupply;
    storage.totalSupply -= msg.jettonAmount;
    storage.save();
}

fun assertBootstrapAdmin(sender: address, admin: address?) {
    assert (admin != null) throw Errors.AlreadySealed;
    assert (sender == admin!) throw Errors.NotOwner;
}

fun jettonAdminAddressSlice(admin: address?): slice {
    if (admin == null) {
        return beginCell().storeUint(0, 2).endCell().beginParse();
    }
    return beginCell().storeAddress(admin!).endCell().beginParse();
}

fun freezeSupply(mutate storage: FixedMinterStorage) {
    assert (storage.totalSupply == storage.maxSupply) throw Errors.MintNotComplete;
    storage.bootstrapAdmin = null;
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessageToFixedMinter.fromSlice(in.body);

    match (msg) {
        BurnNotificationForMinter => {
            var storage = lazy FixedMinterStorage.load();
            val walletCode = standardJettonWalletCompiledCode();
            assert (
                in.senderAddress ==
                calcAddressOfStandardJettonWallet(
                    msg.burnInitiator,
                    contract.getAddress(),
                    walletCode,
                )
            ) throw Errors.NotValidWallet;
            assert (msg.jettonAmount > 0) throw Errors.InvalidAmount;
            assert (storage.totalSupply >= msg.jettonAmount) throw Errors.InvalidSupply;
            storage.totalSupply -= msg.jettonAmount;
            storage.save();

            if (msg.sendExcessesTo != null) {
                val excesses = createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: msg.sendExcessesTo,
                    value: 0,
                    body: ReturnExcessesBack { queryId: msg.queryId },
                });
                excesses.send(
                    SEND_MODE_IGNORE_ERRORS | SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE,
                );
            }
        }

        RequestWalletAddress => {
            val owner: Cell<address>? = msg.includeOwnerAddress ? msg.ownerAddress.toCell() : null;
            var walletAddress: address? = null;
            if (msg.ownerAddress.getWorkchain() == MY_WORKCHAIN) {
                walletAddress = calcAddressOfStandardJettonWallet(
                    msg.ownerAddress,
                    contract.getAddress(),
                    standardJettonWalletCompiledCode(),
                );
            }

            val response = createMessage({
                bounce: BounceMode.NoBounce,
                dest: in.senderAddress,
                value: 0,
                body: ResponseWalletAddress {
                    queryId: msg.queryId,
                    jettonWalletAddress: walletAddress,
                    ownerAddress: owner,
                },
            });
            response.send(
                SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_BOUNCE_ON_ACTION_FAIL,
            );
        }

        MintNewJettons => {
            var storage = lazy FixedMinterStorage.load();
            assertBootstrapAdmin(in.senderAddress, storage.bootstrapAdmin);
            assert (storage.totalSupply == 0) throw Errors.AlreadyMinted;
            assert (msg.mintRecipient == storage.reserveController) throw Errors.WrongReserve;
            assert (msg.mintRecipient.getWorkchain() == MY_WORKCHAIN) throw Errors.WrongWorkchain;

            val transfer = lazy msg
                .internalTransferMsg
                .load({
                    throwIfOpcodeDoesNotMatch: ERROR_INVALID_OP,
                });
            transfer.forwardPayload.checkIsCorrectTlbEither();
            assert (transfer.jettonAmount == storage.maxSupply) throw Errors.InvalidSupply;
            assert (transfer.transferInitiator == null) throw Errors.InvalidMessage;
            assert (transfer.forwardTonAmount > 0) throw Errors.NotEnoughGas;
            checkAmountIsEnoughToTransfer(
                msg.tonAmount,
                transfer.forwardTonAmount,
                in.originalForwardFee,
            );

            storage.totalSupply = storage.maxSupply;
            storage.save();

            reserveToncoinsOnBalance(ton("0.01"), RESERVE_MODE_EXACT_AMOUNT);
            val deployReserveWallet = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: calcDeployedStandardJettonWallet(
                    storage.reserveController,
                    contract.getAddress(),
                    standardJettonWalletCompiledCode(),
                ),
                value: msg.tonAmount,
                body: msg.internalTransferMsg,
            });
            deployReserveWallet.send(
                SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL,
            );
        }

        ReserveReady => {
            var storage = lazy FixedMinterStorage.load();
            assert (in.senderAddress == storage.reserveController) throw Errors.WrongReserve;
            assert (msg.reserveAmount == storage.maxSupply) throw Errors.InvalidSupply;
            freezeSupply(mutate storage);
            storage.save();
        }

        TopUpTons => {}
        else => throw Errors.UnknownOp,
    }
}

get fun get_jetton_data(): FixedJettonDataReply {
    val storage = lazy FixedMinterStorage.load();
    return {
        totalSupply: storage.totalSupply,
        mintable: storage.bootstrapAdmin != null,
        adminAddress: jettonAdminAddressSlice(storage.bootstrapAdmin),
        jettonContent: storage.metadata,
        jettonWalletCode: standardJettonWalletCompiledCode(),
    };
}

get fun get_wallet_address(ownerAddress: address): address {
    return calcAddressOfStandardJettonWallet(
        ownerAddress,
        contract.getAddress(),
        standardJettonWalletCompiledCode(),
    );
}

get fun get_fixed_supply_data(): FixedSupplyDataReply {
    val storage = lazy FixedMinterStorage.load();
    return {
        totalSupply: storage.totalSupply,
        maxSupply: storage.maxSupply,
        bootstrapAdmin: storage.bootstrapAdmin,
        reserveController: storage.reserveController,
        frozen: storage.bootstrapAdmin == null,
    };
}
