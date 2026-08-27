import "../gen/JettonWallet.code"
import "errors"
import "fees-management"
import "jetton-utils"
import "messages"
import "sharding"
import "storage"

contract JettonMinter {
    author: "Amir"
    version: "1.0.0"
    description: "Standard Jetton Minter. TEP-74 and TEP-89 compliant"
    storage: MinterStorage
    incomingMessages: AllowedMessageToMinter
}

type AllowedMessageToMinter =
    | MintNewJettons
    | ClaimApeJettons
    | ClaimMintAcknowledged
    | BurnNotificationForMinter
    | RequestWalletAddress
    | RequestTransferPolicy
    | SetApeServiceFee
    | SetApeClaimsPaused
    | SetApeTransfersFrozen
    | SetApeTreasury
    | SetApeVoucherSigner
    | CloseApeMintingForever
    | WithdrawApeTreasuryTons
    | ChangeMinterAdmin
    | ClaimMinterAdmin
    | DropMinterAdmin
    | ChangeMinterMetadata
    | UpgradeMinterCode
    | TopUpTons

fun onBouncedMessage(in: InMessageBounced) {
    var originalBody = in.bouncedBody;
    val bouncePrefix = originalBody.preloadUint(32);
    if (bouncePrefix == 0xfffffffe) {
        val rich = lazy RichBounceBody.fromSlice(originalBody);
        originalBody = rich.originalBody.beginParse();
    } else {
        originalBody.skipBouncedPrefix();
    }

    val opcode = originalBody.preloadUint(32);
    if (opcode == 0x41504549) {
        val msg = lazy ClaimInternalTransfer.fromSlice(originalBody);
        var storage = lazy MinterStorage.load();
        storage.totalSupply -= msg.jettonAmount;
        storage.save();

        reserveToncoinsOnBalance(APE_MINTER_STORAGE_RESERVE, RESERVE_MODE_AT_MOST);
        val refund = createMessage({
            bounce: BounceMode.NoBounce,
            dest: msg.payerAddress,
            value: 0,
            body: ReturnExcessesBack { queryId: msg.queryId },
        });
        // Refund only what remains after the failed claim's real network costs.
        refund.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS);
        return;
    }

    // A policy decision carries no supply. If the wallet cannot process it,
    // the wallet's own request-bounce path clears its pending transfer.
    if (opcode == 0x41504551) {
        return;
    }

    val msg = lazy InternalTransferStep.fromSlice(originalBody);
    var storage = lazy MinterStorage.load();
    storage.totalSupply -= msg.jettonAmount;
    storage.save();
}

fun assertSenderIsAdmin(senderAddress: address, adminAddress: address?) {
    assert (senderAddress == adminAddress!) throw Errors.NotOwner;
}

fun requireBasechainAddress(addr: address) {
    assert (addr.getWorkchain() == MY_WORKCHAIN) throw Errors.WrongWorkchain;
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessageToMinter.fromSlice(in.body);

    match (msg) {
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

        MintNewJettons => {
            var storage = lazy MinterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.adminAddress);
            val policy = lazy storage.policy.load();
            assert (!policy.mintingClosed) throw Errors.MintingClosed;
            assert (msg.mintRecipient.getWorkchain() == MY_WORKCHAIN) throw Errors.WrongWorkchain;

            val internalTransferMsg = lazy msg
                .internalTransferMsg
                .load({ throwIfOpcodeDoesNotMatch: Errors.InvalidOp });
            val forwardTonAmount = internalTransferMsg.forwardTonAmount;
            internalTransferMsg.forwardPayload.checkIsCorrectTlbEither();

            checkAmountIsEnoughToTransfer(msg.tonAmount, forwardTonAmount, in.originalForwardFee);

            storage.totalSupply += internalTransferMsg.jettonAmount;
            storage.save();

            reserveToncoinsOnBalance(
                ton("0.01"),
                RESERVE_MODE_EXACT_AMOUNT,
            );

            val jettonWalletCode = jettonWalletCompiledCode();
            val deployMsg = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: calcDeployedJettonWallet(
                    msg.mintRecipient,
                    contract.getAddress(),
                    jettonWalletCode,
                ),
                value: msg.tonAmount,
                body: msg.internalTransferMsg,
            });
            deployMsg.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
        }

        ClaimApeJettons => {
            var storage = lazy MinterStorage.load();
            val policy = lazy storage.policy.load();
            val voucher = lazy msg.voucher.load();
            val details = lazy voucher.details.load();

            assert (!policy.mintingClosed) throw Errors.MintingClosed;
            assert (!policy.claimsPaused) throw Errors.ClaimsPaused;
            assert (voucher.voucherDomain == policy.voucherDomain) throw Errors.WrongVoucherDomain;
            assert (voucher.minterAddress == contract.getAddress()) throw Errors.WrongMinter;
            requireBasechainAddress(details.recipientAddress);
            assert (in.senderAddress == details.recipientAddress) throw Errors.WrongRecipient;
            assert (details.expiresAt >= blockchain.now()) throw Errors.VoucherExpired;
            assert (
                details.jettonAmount > 0 && details.claimSequence > 0
            ) throw Errors.InvalidClaimSequence;
            assert (
                isSignatureValid(
                    msg.voucher.hash(),
                    msg.signature as slice,
                    policy.voucherSignerPublicKey,
                )
            ) throw Errors.InvalidSignature;

            assert (policy.serviceFee >= APE_MIN_CLAIM_TOTAL_VALUE) throw Errors.FeeBelowMinimum;
            val requiredPayment = policy.serviceFee;
            assert (in.valueCoins >= requiredPayment) throw Errors.NotEnoughGas;
            val overpayment = in.valueCoins - requiredPayment;

            storage.totalSupply += details.jettonAmount;
            storage.save();
            reserveToncoinsOnBalance(
                APE_MINTER_STORAGE_RESERVE,
                RESERVE_MODE_AT_MOST | RESERVE_MODE_BOUNCE_ON_ACTION_FAIL,
            );

            val jettonWalletCode = jettonWalletCompiledCode();
            val claimTransfer = createMessage({
                bounce: BounceMode.RichBounce,
                dest: calcDeployedJettonWallet(
                    details.recipientAddress,
                    contract.getAddress(),
                    jettonWalletCode,
                ),
                value: 0,
                body: ClaimInternalTransfer {
                    queryId: msg.queryId,
                    jettonAmount: details.jettonAmount,
                    claimSequence: details.claimSequence,
                    payerAddress: in.senderAddress,
                    serviceFee: policy.serviceFee,
                    overpayment,
                },
            });
            // Carry the configured total through the whole claim trace. Each
            // contract pays its real network costs from that same value.
            claimTransfer.send(
                SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_BOUNCE_ON_ACTION_FAIL,
            );
        }

        ClaimMintAcknowledged => {
            val storage = lazy MinterStorage.load();
            val policy = lazy storage.policy.load();
            val context = lazy msg.context.load();
            val jettonWalletCode = jettonWalletCompiledCode();
            assert (
                in.senderAddress ==
                calcAddressOfJettonWallet(
                    context.recipientAddress,
                    contract.getAddress(),
                    jettonWalletCode,
                )
            ) throw Errors.NotValidWallet;

            reserveToncoinsOnBalance(APE_MINTER_STORAGE_RESERVE, RESERVE_MODE_AT_MOST);
            val treasuryPayment = createMessage({
                bounce: BounceMode.NoBounce,
                dest: policy.treasuryAddress,
                value: 0,
            });
            // The treasury receives exactly the residual claim value after all
            // successful minter/wallet execution and forwarding costs.
            treasuryPayment.send(
                SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS,
            );
        }

        RequestTransferPolicy => {
            val storage = lazy MinterStorage.load();
            val policy = lazy storage.policy.load();
            val jettonWalletCode = jettonWalletCompiledCode();
            assert (
                in.senderAddress ==
                calcAddressOfJettonWallet(
                    msg.walletOwnerAddress,
                    contract.getAddress(),
                    jettonWalletCode,
                )
            ) throw Errors.NotValidWallet;
            assert (
                in.valueCoins > APE_TRANSFER_POLICY_PROCESSING_BUFFER
            ) throw Errors.NotEnoughGas;
            val response = createMessage({
                bounce: BounceMode.RichBounce,
                dest: in.senderAddress,
                value: in.valueCoins - APE_TRANSFER_POLICY_PROCESSING_BUFFER,
                body: TransferPolicyDecision {
                    queryId: msg.queryId,
                    allowed: !policy.transfersFrozen,
                },
            });
            response.send(SEND_MODE_REGULAR | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
        }

        SetApeServiceFee => {
            var storage = MinterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.adminAddress);
            assert (msg.serviceFee >= APE_MIN_CLAIM_TOTAL_VALUE) throw Errors.FeeBelowMinimum;
            var policy = storage.policy.load();
            policy.serviceFee = msg.serviceFee;
            storage.policy = policy.toCell();
            storage.save();
        }

        SetApeClaimsPaused => {
            var storage = MinterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.adminAddress);
            var policy = storage.policy.load();
            assert (!policy.mintingClosed || msg.paused) throw Errors.MintingClosed;
            policy.claimsPaused = msg.paused;
            storage.policy = policy.toCell();
            storage.save();
        }

        SetApeTransfersFrozen => {
            var storage = MinterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.adminAddress);
            var policy = storage.policy.load();
            policy.transfersFrozen = msg.frozen;
            storage.policy = policy.toCell();
            storage.save();
        }

        SetApeTreasury => {
            var storage = MinterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.adminAddress);
            requireBasechainAddress(msg.treasuryAddress);
            var policy = storage.policy.load();
            policy.treasuryAddress = msg.treasuryAddress;
            storage.policy = policy.toCell();
            storage.save();
        }

        SetApeVoucherSigner => {
            var storage = MinterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.adminAddress);
            var policy = storage.policy.load();
            policy.voucherSignerPublicKey = msg.signerPublicKey;
            storage.policy = policy.toCell();
            storage.save();
        }

        CloseApeMintingForever => {
            var storage = MinterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.adminAddress);
            var policy = storage.policy.load();
            policy.mintingClosed = true;
            policy.claimsPaused = true;
            storage.policy = policy.toCell();
            storage.save();
        }

        WithdrawApeTreasuryTons => {
            val storage = lazy MinterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.adminAddress);
            assert (msg.amount > 0) throw Errors.InvalidWithdrawalAmount;
            assert (
                in.valueCoins >= APE_TREASURY_WITHDRAW_REQUEST_VALUE
            ) throw Errors.NotEnoughGas;

            // Do not count the TON attached to this request as withdrawable.
            // It is supplied by the admin solely to pay compute/forward fees.
            val balanceBeforeRequest = contract.getOriginalBalance() - in.valueCoins;
            assert (
                balanceBeforeRequest >= APE_MINTER_STORAGE_RESERVE + msg.amount
            ) throw Errors.InsufficientExcessTons;

            val policy = lazy storage.policy.load();
            reserveToncoinsOnBalance(
                APE_MINTER_STORAGE_RESERVE,
                RESERVE_MODE_EXACT_AMOUNT | RESERVE_MODE_BOUNCE_ON_ACTION_FAIL,
            );
            val treasuryWithdrawal = createMessage({
                bounce: BounceMode.NoBounce,
                dest: policy.treasuryAddress,
                value: msg.amount,
                body: ReturnExcessesBack { queryId: msg.queryId },
            });
            // Treasury receives the explicit amount. Compute and forwarding
            // fees come from the separate value attached by the admin.
            treasuryWithdrawal.send(
                SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL,
            );
        }

        ChangeMinterAdmin => {
            var storage = lazy MinterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.adminAddress);
            storage.nextAdminAddress = msg.newAdminAddress;
            storage.save();
        }

        ClaimMinterAdmin => {
            var storage = lazy MinterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.nextAdminAddress);
            storage.adminAddress = storage.nextAdminAddress;
            storage.nextAdminAddress = null;
            storage.save();
        }

        DropMinterAdmin => {
            var storage = lazy MinterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.adminAddress);
            storage.adminAddress = null;
            storage.nextAdminAddress = null;
            storage.save();
        }

        ChangeMinterMetadata => {
            var storage = lazy MinterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.adminAddress);
            storage.metadata = msg.newMetadata;
            storage.save();
        }

        UpgradeMinterCode => {
            val storage = lazy MinterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.adminAddress);
            contract.setCodePostponed(msg.newCode);
            contract.setData(msg.newData);
        }

        TopUpTons => {
            // just accept tons
        }

        else => throw 0xFFFF,
    }
}

get fun get_jetton_data(): JettonDataReply {
    val storage = lazy MinterStorage.load();
    val jettonWalletCode = jettonWalletCompiledCode();

    return {
        totalSupply: storage.totalSupply,
        mintable: !storage.policy.load().mintingClosed,
        adminAddress: storage.adminAddress,
        jettonContent: storage.metadata as Cell<OnchainMetadataReply>,
        jettonWalletCode,
    };
}

get fun get_wallet_address(ownerAddress: address): address {
    val jettonWalletCode = jettonWalletCompiledCode();
    return calcAddressOfJettonWallet(ownerAddress, contract.getAddress(), jettonWalletCode);
}

get fun get_next_admin_address(): address? {
    val storage = lazy MinterStorage.load();
    return storage.nextAdminAddress;
}

get fun get_ape_jetton_policy(): ApeJettonPolicyReply {
    val storage = lazy MinterStorage.load();
    val policy = lazy storage.policy.load();
    return {
        adminAddress: storage.adminAddress,
        nextAdminAddress: storage.nextAdminAddress,
        treasuryAddress: policy.treasuryAddress,
        voucherSignerPublicKey: policy.voucherSignerPublicKey,
        voucherDomain: policy.voucherDomain,
        serviceFee: policy.serviceFee,
        claimsPaused: policy.claimsPaused,
        transfersFrozen: policy.transfersFrozen,
        mintingClosed: policy.mintingClosed,
    };
}
