import "@stdlib/gas-payments"
import "errors"
import "jetton-utils"
import "messages"
import "storage"
import "fees-management"

type AllowedMessageToMinter =
    | MintNewJettons
    | BurnNotificationForMinter
    | RequestWalletAddress
    | ChangeAdmin
    | ChangeMinterContent
    | SetBuyTax
    | SetSellTax
    | SetFeeWallet
    | SetPaused
    | AddToWhitelist
    | RemoveFromWhitelist
    | SetWhitelistEnabled
    | AddDexPool
    | RemoveDexPool
    | UpgradeCode
    | TransferViaMinterRequest

fun assertSenderIsAdmin(senderAddress: address, adminAddress: address) {
    assert (senderAddress == adminAddress) throw ERR_NOT_ADMIN;
}

fun assertValidTax(taxPercent: int) {
    assert ((taxPercent >= 1) & (taxPercent <= 10)) throw ERR_INVALID_TAX;
}

fun calculateTaxAmount(jettonAmount: coins, taxPercent: int) {
    return jettonAmount * taxPercent / 100;
}

fun syncWalletPermissions(storage: MinterStorage, ownerAddress: address, canSell: bool, queryId: uint64) {
    val syncMsg = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: calcDeployedJettonWallet(ownerAddress, contract.getAddress(), storage.jettonWalletCode),
        value: WALLET_SYNC_TON_AMOUNT,
        body: UpdateWalletPermissions {
            queryId,
            canSell,
        }
    });
    syncMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun sendWalletTransfer(storage: MinterStorage, recipientOwnerAddress: address, transferInitiator: address?, jettonAmount: coins, sendExcessesTo: address?, forwardTonAmount: coins, forwardPayload: ForwardPayloadRemainder, tonAmount: coins) {
    val transferMsg = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: calcDeployedJettonWallet(recipientOwnerAddress, contract.getAddress(), storage.jettonWalletCode),
        value: tonAmount,
        body: InternalTransferStep {
            queryId: 0,
            jettonAmount,
            transferInitiator,
            sendExcessesTo,
            forwardTonAmount,
            forwardPayload,
        }
    });
    transferMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun onBouncedMessage(in: InMessageBounced) {
    in.bouncedBody.skipBouncedPrefix();

    val msg = lazy InternalTransferStep.fromSlice(in.bouncedBody);

    if (msg.transferInitiator == null) {
        return;
    }

    var storage = lazy MinterStorage.load();

    val refundMsg = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: calcDeployedJettonWallet(msg.transferInitiator!, contract.getAddress(), storage.jettonWalletCode),
        value: 0,
        body: InternalTransferStep {
            queryId: msg.queryId,
            jettonAmount: msg.jettonAmount,
            transferInitiator: null,
            sendExcessesTo: msg.sendExcessesTo,
            forwardTonAmount: 0,
            forwardPayload: createEmptySlice(),
        }
    });
    refundMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessageToMinter.fromSlice(in.body);

    match (msg) {
        BurnNotificationForMinter => {
            var storage = lazy MinterStorage.load();
            assert (in.senderAddress == calcAddressOfJettonWallet(msg.burnInitiator, contract.getAddress(), storage.jettonWalletCode)) throw ERR_UNAUTHORIZED;

            storage.totalSupply -= msg.jettonAmount;
            storage.save();

            if (msg.sendExcessesTo == null) {
                return;
            }

            val excessesMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: msg.sendExcessesTo,
                value: 0,
                body: ReturnExcessesBack {
                    queryId: msg.queryId
                }
            });
            excessesMsg.send(SEND_MODE_IGNORE_ERRORS + SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        RequestWalletAddress => {
            assert (in.valueCoins > in.originalForwardFee + MINIMAL_MESSAGE_VALUE_BOUND) throw ERR_NOT_ENOUGH_TON;

            var respondOwnerAddress: Cell<address>? = msg.includeOwnerAddress
                ? msg.ownerAddress.toCell()
                : null;

            var walletAddress: address? = null;
            if (msg.ownerAddress.getWorkchain() == BASECHAIN) {
                var storage = lazy MinterStorage.load();
                walletAddress = calcAddressOfJettonWallet(msg.ownerAddress, contract.getAddress(), storage.jettonWalletCode);
            }

            val respondMsg = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: in.senderAddress,
                value: 0,
                body: ResponseWalletAddress {
                    queryId: msg.queryId,
                    jettonWalletAddress: walletAddress,
                    ownerAddress: respondOwnerAddress,
                }
            });
            respondMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        MintNewJettons => {
            var storage = lazy MinterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.adminAddress);

            var internalTransferMsg = lazy msg.internalTransferMsg.load();
            storage.totalSupply += internalTransferMsg.jettonAmount;
            storage.save();

            val deployMsg = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: calcDeployedJettonWallet(msg.mintRecipient, contract.getAddress(), storage.jettonWalletCode),
                value: msg.tonAmount,
                body: msg.internalTransferMsg,
            });
            deployMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
        }

        ChangeAdmin => {
            var storage = lazy MinterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.adminAddress);
            storage.adminAddress = msg.newAdminAddress;
            storage.save();
        }

        ChangeMinterContent => {
            var storage = lazy MinterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.adminAddress);
            storage.content = msg.newContent;
            storage.save();
        }

        SetBuyTax => {
            assertValidTax(msg.buyTaxPercent);

            var storage = lazy MinterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.adminAddress);
            storage.buyTaxPercent = msg.buyTaxPercent;
            storage.save();
        }

        SetSellTax => {
            assertValidTax(msg.sellTaxPercent);

            var storage = lazy MinterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.adminAddress);
            storage.sellTaxPercent = msg.sellTaxPercent;
            storage.save();
        }

        SetFeeWallet => {
            var storage = lazy MinterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.adminAddress);
            storage.feeWalletAddress = msg.feeWalletAddress;
            storage.save();
        }

        SetPaused => {
            var storage = lazy MinterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.adminAddress);
            storage.paused = msg.paused;
            storage.save();
        }

        AddToWhitelist => {
            var storage = lazy MinterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.adminAddress);
            storage.whitelistAddresses.addFlag(msg.sellerAddress);
            storage.save();
            syncWalletPermissions(storage, msg.sellerAddress, true, msg.queryId);
        }

        RemoveFromWhitelist => {
            var storage = lazy MinterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.adminAddress);
            storage.whitelistAddresses.removeFlag(msg.sellerAddress);
            storage.save();
            syncWalletPermissions(storage, msg.sellerAddress, false, msg.queryId);
        }

        SetWhitelistEnabled => {
            var storage = lazy MinterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.adminAddress);

            if (msg.whitelistEnabled & (storage.whitelistEnabled)) {
                throw ERR_WHITELIST_ALREADY_ENABLED;
            }

            if ((!msg.whitelistEnabled) & (!storage.whitelistEnabled)) {
                throw ERR_WHITELIST_ALREADY_DISABLED;
            }

            storage.whitelistEnabled = msg.whitelistEnabled;
            storage.save();
        }

        AddDexPool => {
            var storage = lazy MinterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.adminAddress);
            storage.dexPoolAddresses.addFlag(msg.dexPoolAddress);
            storage.whitelistAddresses.addFlag(msg.dexPoolAddress);
            storage.save();
            syncWalletPermissions(storage, msg.dexPoolAddress, true, msg.queryId);
        }

        RemoveDexPool => {
            var storage = lazy MinterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.adminAddress);
            storage.dexPoolAddresses.removeFlag(msg.dexPoolAddress);
            storage.whitelistAddresses.removeFlag(msg.dexPoolAddress);
            storage.save();
            syncWalletPermissions(storage, msg.dexPoolAddress, false, msg.queryId);
        }

        UpgradeCode => {
            var storage = lazy MinterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.adminAddress);
            storage.save();
            contract.setCodePostponed(msg.newCode);
        }

        TransferViaMinterRequest => {
            var storage = lazy MinterStorage.load();
            assert (in.senderAddress == calcAddressOfJettonWallet(msg.senderOwnerAddress, contract.getAddress(), storage.jettonWalletCode)) throw ERR_INVALID_WALLET;
            assert (!storage.paused) throw ERR_PAUSED;

            val senderIsDexPool = storage.dexPoolAddresses.isFlagSet(msg.senderOwnerAddress);
            val recipientIsDexPool = storage.dexPoolAddresses.isFlagSet(msg.transferRecipient);
            val senderIsAllowed = (storage.whitelistAddresses.isFlagSet(msg.senderOwnerAddress)) | senderIsDexPool;

            if (storage.whitelistEnabled & (!senderIsAllowed)) {
                throw ERR_NOT_WHITELISTED;
            }

            var taxAmount: coins = 0;
            if (recipientIsDexPool) {
                taxAmount = calculateTaxAmount(msg.jettonAmount, storage.sellTaxPercent);
            } else if (senderIsDexPool) {
                taxAmount = calculateTaxAmount(msg.jettonAmount, storage.buyTaxPercent);
            }

            val netAmount = msg.jettonAmount - taxAmount;
            var taxTransferTonAmount: coins = 0;
            if (taxAmount > 0) {
                taxTransferTonAmount = TAX_TRANSFER_TON_AMOUNT;
            }

            val requiredTonAmount = ROUTED_TRANSFER_BASE_TON + msg.forwardTonAmount +
                taxTransferTonAmount +
                MINTER_ROUTER_GAS_CONSUMPTION;
            assert (in.valueCoins > requiredTonAmount) throw ERR_NOT_ENOUGH_TON;

            if (netAmount > 0) {
                sendWalletTransfer(
                    storage,
                    msg.transferRecipient,
                    msg.senderOwnerAddress,
                    netAmount,
                    msg.sendExcessesTo,
                    msg.forwardTonAmount,
                    msg.forwardPayload,
                    ROUTED_TRANSFER_BASE_TON + msg.forwardTonAmount,
                );
            }

            if (taxAmount > 0) {
                sendWalletTransfer(
                    storage,
                    storage.feeWalletAddress,
                    msg.senderOwnerAddress,
                    taxAmount,
                    msg.sendExcessesTo,
                    0,
                    createEmptySlice(),
                    TAX_TRANSFER_TON_AMOUNT,
                );
            }
        }

        else => {
            assert (in.body.isEmpty()) throw 0xFFFF
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
        mintable: true,
        adminAddress: storage.adminAddress,
        jettonContent: storage.content,
        jettonWalletCode: storage.jettonWalletCode,
    }
}

get fun get_buy_tax(): uint8 {
    val storage = lazy MinterStorage.load();
    return storage.buyTaxPercent;
}

get fun get_sell_tax(): uint8 {
    val storage = lazy MinterStorage.load();
    return storage.sellTaxPercent;
}

get fun get_fee_wallet(): address {
    val storage = lazy MinterStorage.load();
    return storage.feeWalletAddress;
}

get fun get_paused(): bool {
    val storage = lazy MinterStorage.load();
    return storage.paused;
}

get fun get_whitelist_enabled(): bool {
    val storage = lazy MinterStorage.load();
    return storage.whitelistEnabled;
}

get fun get_is_whitelisted(ownerAddress: address): bool {
    val storage = lazy MinterStorage.load();
    return storage.whitelistAddresses.isFlagSet(ownerAddress);
}

get fun get_is_dex_pool(ownerAddress: address): bool {
    val storage = lazy MinterStorage.load();
    return storage.dexPoolAddresses.isFlagSet(ownerAddress);
}

get fun get_wallet_address(ownerAddress: address): address {
    val storage = lazy MinterStorage.load();
    return calcAddressOfJettonWallet(ownerAddress, contract.getAddress(), storage.jettonWalletCode);
}

get fun get_total_supply(): coins {
    val storage = lazy MinterStorage.load();
    return storage.totalSupply;
}

get fun get_admin_address(): address {
    val storage = lazy MinterStorage.load();
    return storage.adminAddress;
}