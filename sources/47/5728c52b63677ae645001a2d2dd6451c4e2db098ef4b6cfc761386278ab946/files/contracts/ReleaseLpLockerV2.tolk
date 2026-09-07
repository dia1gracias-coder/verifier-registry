import "@stdlib/gas-payments"
import "errors"
import "jetton-messages"
import "release-messages"
import "release-storage"
import "sharding"
import "ston-lp-utils"

contract ReleaseLpLockerV2 {
    author: "Diamond Club"
    version: "1.1.0"
    description: "Immutable LP locker with confirmed 180-day withdrawal and beneficiary-approved slot transfers"
    incomingMessages: AllowedLockerMessage
    storage: ReleaseLpLockerStorage
}

type AllowedLockerMessage =
    | BindLockerController
    | RegisterLockIntent
    | TransferNotificationForRecipient
    | ProposeSlotTransfer
    | AcceptSlotTransfer
    | CancelSlotTransfer
    | PruneExpiredSlotTransfer
    | WithdrawSlot
    | ReturnExcessesBack
    | ReplayLockAck
    | PruneExpiredLockIntent
    | TopUpTons

const SLOT_TRANSFER_ACCEPTANCE_SECONDS = 7 * 24 * 60 * 60
// The production capacity proof covers at most 10,000 materialized slots plus
// the largest valid companion state. Reject an unsafe init on-chain instead of
// relying only on an off-chain deployment-plan check.
const MAX_SAFE_LOCKER_SLOTS = 10_000
const MIN_SLOT_STORAGE_DEPOSIT = 1_000_000
const MIN_SLOT_TRANSFER_MESSAGE_VALUE = 50_000_000
const MIN_WITHDRAW_WALLET_MESSAGE_VALUE = 200_000_000

fun lockerLoadConfig(
    storage: ReleaseLpLockerStorage,
): (LockerConfig, LockerAuthorities, LockerAssetConfig) {
    val config = storage.config.load();
    return (config, config.authorities.load(), config.asset.load());
}

fun lockerSave(
    mutate storage: ReleaseLpLockerStorage,
    config: LockerConfig,
    authorities: LockerAuthorities,
    asset: LockerAssetConfig,
    dynamic: LockerDynamicState,
) {
    var updatedConfig = config;
    updatedConfig.authorities = authorities.toCell();
    updatedConfig.asset = asset.toCell();
    storage.config = updatedConfig.toCell();
    storage.dynamic = dynamic.toCell();
    storage.save();
}

fun lockerReservePreexistingBalance(incomingValue: coins, additionalReserve: coins = 0) {
    val balanceBeforeIncoming = contract.getOriginalBalance() - incomingValue +
    contract.getStorageDuePayment();
    reserveToncoinsOnBalance(
        balanceBeforeIncoming + additionalReserve,
        RESERVE_MODE_AT_MOST,
    );
}

fun lockerSendAck(
    controllerAddress: address,
    slotId: uint64,
    slot: LockSlot,
    incomingValue: coins,
) {
    lockerReservePreexistingBalance(incomingValue);
    val ack = createMessage({
        bounce: BounceMode.NoBounce,
        dest: controllerAddress,
        value: 0,
        body: LockConfirmed {
            operationId: slotId,
            lpAmount: slot.lpAmount,
            unlockAt: slot.unlockAt,
        },
    });
    // SAFETY: the pre-existing Locker balance is reserved above. The ACK can
    // carry only the unspent value supplied by this authenticated callback or
    // permissionless replay caller.
    ack.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS);
}

fun lockerSendIntentRegistered(
    controllerAddress: address,
    operationId: uint64,
    incomingValue: coins,
    storageDeposit: coins,
) {
    lockerReservePreexistingBalance(incomingValue, storageDeposit);
    val ack = createMessage({
        bounce: BounceMode.NoBounce,
        dest: controllerAddress,
        value: 0,
        body: LockIntentRegistered { operationId },
    });
    // SAFETY: the original balance and the one-time per-slot storage deposit
    // are reserved above. Only caller-funded execution excess can leave.
    ack.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS);
}

fun lockerReturnCallerExcess(recipient: address, queryId: uint64, incomingValue: coins) {
    lockerReservePreexistingBalance(incomingValue);
    val excesses = createMessage({
        bounce: BounceMode.NoBounce,
        dest: recipient,
        value: 0,
        body: ReturnExcessesBack { queryId },
    });
    // SAFETY: the reserve action protects all pre-existing Locker funds, so
    // carry-all returns only caller-funded excess.
    excesses.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS);
}

fun assertSlotTransferFunded(valueCoins: coins, config: LockerConfig) {
    assert (valueCoins >= config.slotTransferMessageValue) throw Errors.NotEnoughGas;
}

fun decrementPendingSlotTransferCount(mutate dynamic: LockerDynamicState) {
    assert (dynamic.pendingSlotTransfersCount > 0) throw Errors.InvalidMessage;
    dynamic.pendingSlotTransfersCount -= 1;
}

fun assertLockIntentMatches(
    intent: LockIntent,
    parties: LockIntentParties,
    terms: LockIntentTerms,
) {
    assert (intent.beneficiary == parties.beneficiary) throw Errors.LockIntentMismatch;
    assert (
        intent.beneficiaryLpWallet == parties.beneficiaryLpWallet
    ) throw Errors.LockIntentMismatch;
    assert (intent.minLpOut == terms.minLpOut) throw Errors.LockIntentMismatch;
    assert (intent.deadline == terms.deadline) throw Errors.LockIntentMismatch;
    assert (intent.expiresAt == terms.expiresAt) throw Errors.LockIntentMismatch;
}

fun onBouncedMessage(in: InMessageBounced) {
    in.bouncedBody.skipBouncedPrefix();
    val msg = lazy AskToTransfer.fromSlice(in.bouncedBody);

    var storage = lazy ReleaseLpLockerStorage.load();
    val (config, authorities, asset) = lockerLoadConfig(storage);
    if (asset.lockerLpWallet == null || in.senderAddress != asset.lockerLpWallet!) {
        return;
    }

    var dynamic = storage.dynamic.load();
    if (dynamic.pendingWithdrawals.exists(msg.queryId)) {
        dynamic.pendingWithdrawals.delete(msg.queryId);
        lockerSave(mutate storage, config, authorities, asset, dynamic);
    }
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedLockerMessage.fromSlice(in.body);

    match (msg) {
        BindLockerController => {
            var storage = lazy ReleaseLpLockerStorage.load();
            val (config, authoritiesLoaded, assetLoaded) = lockerLoadConfig(storage);
            var authorities = authoritiesLoaded;
            var asset = assetLoaded;
            val dynamic = storage.dynamic.load();

            assert (authorities.bootstrapAdmin != null) throw Errors.AlreadySealed;
            assert (in.senderAddress == authorities.bootstrapAdmin!) throw Errors.NotBootstrapAdmin;
            assert (authorities.controllerAddress == null) throw Errors.AlreadySealed;
            assert (asset.lpJettonMaster == null) throw Errors.AlreadySealed;
            assert (asset.poolAddress == null) throw Errors.AlreadySealed;
            assert (asset.lockerLpWallet == null) throw Errors.AlreadySealed;
            assert (config.maxSlots > 0) throw Errors.HardCap;
            assert (config.maxSlots <= MAX_SAFE_LOCKER_SLOTS) throw Errors.HardCap;
            assert (
                config.slotStorageDeposit >= MIN_SLOT_STORAGE_DEPOSIT
            ) throw Errors.InvalidAmount;
            assert (
                config.slotTransferMessageValue >= MIN_SLOT_TRANSFER_MESSAGE_VALUE
            ) throw Errors.InvalidAmount;
            assert (
                config.withdrawWalletMessageValue >= MIN_WITHDRAW_WALLET_MESSAGE_VALUE
            ) throw Errors.InvalidAmount;
            val boundAsset = msg.asset.load();
            assert (
                boundAsset.lpJettonMaster == boundAsset.poolAddress
            ) throw Errors.InvalidPoolSource;
            assert (
                boundAsset.lockerLpWallet ==
                calcAddressOfStonLpWallet(
                    contract.getAddress(),
                    boundAsset.lpJettonMaster,
                    asset.lpWalletCode,
                )
            ) throw Errors.InvalidLpSource;

            authorities.controllerAddress = msg.controllerAddress;
            authorities.bootstrapAdmin = null;
            asset.lpJettonMaster = boundAsset.lpJettonMaster;
            asset.poolAddress = boundAsset.poolAddress;
            asset.lockerLpWallet = boundAsset.lockerLpWallet;
            lockerSave(mutate storage, config, authorities, asset, dynamic);
        }

        RegisterLockIntent => {
            var storage = lazy ReleaseLpLockerStorage.load();
            val (config, authorities, asset) = lockerLoadConfig(storage);
            var dynamic = storage.dynamic.load();
            assert (authorities.controllerAddress != null) throw Errors.LockerNotBound;
            assert (asset.lpJettonMaster != null) throw Errors.LockerNotBound;
            assert (
                in.senderAddress == authorities.controllerAddress!
            ) throw Errors.WrongInputSource;
            assert (in.valueCoins > config.slotStorageDeposit) throw Errors.NotEnoughGas;
            val parties = msg.parties.load();
            val terms = msg.terms.load();
            assert (
                terms.protocolVersion == RELEASE_PROTOCOL_VERSION
            ) throw Errors.InvalidLockPayload;
            assert (
                parties.controllerAddress == authorities.controllerAddress!
            ) throw Errors.InvalidLockPayload;
            assert (terms.lockSeconds == RELEASE_LOCK_SECONDS) throw Errors.InvalidLockPayload;
            assert (terms.minLpOut > 0) throw Errors.InvalidAmount;
            assert (terms.deadline > blockchain.now()) throw Errors.Expired;
            assert (terms.expiresAt >= terms.deadline) throw Errors.InvalidLockPayload;
            assert (
                parties.beneficiary != parties.beneficiaryLpWallet
            ) throw Errors.InvalidLockPayload;
            assert (parties.beneficiary.getWorkchain() == MY_WORKCHAIN) throw Errors.WrongWorkchain;
            assert (
                parties.beneficiaryLpWallet ==
                calcAddressOfStonLpWallet(
                    parties.beneficiary,
                    asset.lpJettonMaster!,
                    asset.lpWalletCode,
                )
            ) throw Errors.InvalidLockPayload;
            assert (!dynamic.slots.exists(msg.queryId)) throw Errors.SlotExists;

            val existing = dynamic.lockIntents.get(msg.queryId);
            var storageDeposit: coins = 0;
            if (existing.isFound) {
                assertLockIntentMatches(existing.loadValue().load(), parties, terms);
            } else {
                assert (
                    dynamic.lockIntentsCount + dynamic.slotsCount < config.maxSlots
                ) throw Errors.HardCap;
                dynamic
                    .lockIntents
                    .set(
                        msg.queryId,
                        LockIntent {
                            beneficiary: parties.beneficiary,
                            beneficiaryLpWallet: parties.beneficiaryLpWallet,
                            minLpOut: terms.minLpOut,
                            deadline: terms.deadline,
                            expiresAt: terms.expiresAt,
                        }.toCell(),
                    );
                dynamic.lockIntentsCount += 1;
                storageDeposit = config.slotStorageDeposit;
            }
            lockerSave(mutate storage, config, authorities, asset, dynamic);
            lockerSendIntentRegistered(
                authorities.controllerAddress!,
                msg.queryId,
                in.valueCoins,
                storageDeposit,
            );
        }

        TransferNotificationForRecipient => {
            var storage = lazy ReleaseLpLockerStorage.load();
            val (config, authorities, asset) = lockerLoadConfig(storage);
            var dynamic = storage.dynamic.load();

            assert (authorities.controllerAddress != null) throw Errors.LockerNotBound;
            assert (asset.lpJettonMaster != null) throw Errors.LockerNotBound;
            assert (asset.poolAddress != null) throw Errors.LockerNotBound;
            assert (asset.lockerLpWallet != null) throw Errors.LockerNotBound;
            assert (in.senderAddress == asset.lockerLpWallet!) throw Errors.InvalidLpSource;
            assert (msg.transferInitiator != null) throw Errors.InvalidPoolSource;
            // STON.fi LP mint notifications identify the liquidity provider as
            // the Jetton `sender`, not the Pool.  For Controller-created
            // liquidity this value is the immutable Controller address.  The
            // message source remains the independently derived Locker LP
            // wallet, so both the LP asset and the authorized provider are
            // authenticated before any slot can be materialized.
            assert (
                msg.transferInitiator! == authorities.controllerAddress!
            ) throw Errors.InvalidPoolSource;
            assert (msg.jettonAmount > 0) throw Errors.InvalidAmount;

            var forwardPayload = msg.forwardPayload;
            val payloadCell = forwardPayload.loadRequiredPayloadRef();
            val payload = LockerDepositPayload.fromCell(payloadCell);
            assert (
                payload.protocolVersion == RELEASE_PROTOCOL_VERSION
            ) throw Errors.InvalidLockPayload;
            assert (payload.operationId == msg.queryId) throw Errors.InvalidLockPayload;
            assert (
                payload.controllerAddress == authorities.controllerAddress!
            ) throw Errors.InvalidLockPayload;
            assert (payload.lockSeconds == RELEASE_LOCK_SECONDS) throw Errors.InvalidLockPayload;
            assert (
                payload.beneficiary != payload.beneficiaryLpWallet
            ) throw Errors.InvalidLockPayload;
            assert (payload.beneficiary.getWorkchain() == MY_WORKCHAIN) throw Errors.WrongWorkchain;
            assert (
                payload.beneficiaryLpWallet ==
                calcAddressOfStonLpWallet(
                    payload.beneficiary,
                    asset.lpJettonMaster!,
                    asset.lpWalletCode,
                )
            ) throw Errors.InvalidLockPayload;
            val existingSlot = dynamic.slots.get(payload.operationId);
            if (existingSlot.isFound) {
                var slot = existingSlot.loadValue().load();
                assert (
                    slot.originBeneficiary == payload.beneficiary
                ) throw Errors.LockIntentMismatch;
                slot.lpAmount += msg.jettonAmount;
                // Every additional LP unit receives a full 180-day lock from
                // the moment it reaches the Locker. A delayed DEX chunk may
                // extend the original slot, but can never inherit a shorter
                // remaining lock or become immediately withdrawable.
                val topUpUnlockAt = (blockchain.now() + RELEASE_LOCK_SECONDS) as uint64;
                if (slot.unlockAt < topUpUnlockAt) {
                    slot.unlockAt = topUpUnlockAt;
                }
                dynamic.slots.set(payload.operationId, slot.toCell());
                dynamic.totalLockedLp += msg.jettonAmount;
                lockerSave(mutate storage, config, authorities, asset, dynamic);
                lockerSendAck(
                    authorities.controllerAddress!,
                    payload.operationId,
                    slot,
                    in.valueCoins,
                );
                return;
            }

            val intentLookup = dynamic.lockIntents.get(payload.operationId);
            assert (intentLookup.isFound) throw Errors.LockIntentNotRegistered;
            val intent = intentLookup.loadValue().load();
            // The LP Jetton Wallet credits tokens before forwarding this
            // notification. Rejecting an authenticated but delayed callback
            // would therefore strand real LP in the Locker wallet without a
            // beneficiary slot. The DEX deadline prevents a new provide_lp;
            // while the pre-registered intent still exists, a late in-flight
            // notification is accepted and receives a fresh full lock term.
            // Controller resolves the LP-vs-refund race only until either
            // principal has actually been recovered.
            assert (intent.beneficiary == payload.beneficiary) throw Errors.LockIntentMismatch;
            assert (
                intent.beneficiaryLpWallet == payload.beneficiaryLpWallet
            ) throw Errors.LockIntentMismatch;
            assert (msg.jettonAmount >= intent.minLpOut) throw Errors.InvalidAmount;

            val now = blockchain.now() as uint64;
            val slot = LockSlot {
                originBeneficiary: payload.beneficiary,
                beneficiary: payload.beneficiary,
                lpAmount: msg.jettonAmount,
                createdAt: now,
                unlockAt: now + RELEASE_LOCK_SECONDS,
                pendingTransfer: null,
            };
            dynamic.lockIntents.delete(payload.operationId);
            dynamic.lockIntentsCount -= 1;
            dynamic.slots.set(payload.operationId, slot.toCell());
            dynamic.slotsCount += 1;
            dynamic.totalLockedLp += msg.jettonAmount;
            lockerSave(mutate storage, config, authorities, asset, dynamic);

            lockerSendAck(
                authorities.controllerAddress!,
                payload.operationId,
                slot,
                in.valueCoins,
            );
        }

        ReplayLockAck => {
            val storage = lazy ReleaseLpLockerStorage.load();
            val (config, authorities, _) = lockerLoadConfig(storage);
            assert (authorities.controllerAddress != null) throw Errors.LockerNotBound;
            // Replay is permissionless for liveness, but its caller must fund
            // the outbound ACK.  Otherwise a valid slot becomes a permanent
            // gas-drain oracle against the Locker balance.
            assert (in.valueCoins > config.withdrawWalletMessageValue) throw Errors.NotEnoughGas;
            val dynamic = storage.dynamic.load();
            val lookup = dynamic.slots.get(msg.slotId);
            assert (lookup.isFound) throw Errors.SlotNotFound;
            lockerSendAck(
                authorities.controllerAddress!,
                msg.slotId,
                lookup.loadValue().load(),
                in.valueCoins,
            );
        }

        ProposeSlotTransfer => {
            var storage = lazy ReleaseLpLockerStorage.load();
            val (config, authorities, asset) = lockerLoadConfig(storage);
            var dynamic = storage.dynamic.load();
            assert (authorities.controllerAddress != null) throw Errors.LockerNotBound;
            assert (asset.lpJettonMaster != null) throw Errors.LockerNotBound;
            assert (asset.lockerLpWallet != null) throw Errors.LockerNotBound;
            assertSlotTransferFunded(in.valueCoins, config);

            val lookup = dynamic.slots.get(msg.slotId);
            assert (lookup.isFound) throw Errors.SlotNotFound;
            var slot = lookup.loadValue().load();
            assert (in.senderAddress == slot.beneficiary) throw Errors.NotBeneficiary;
            assert (!dynamic.pendingWithdrawals.exists(msg.slotId)) throw Errors.WithdrawPending;
            assert (
                msg.newBeneficiary != slot.beneficiary
            ) throw Errors.SlotTransferSameBeneficiary;
            assert (msg.newBeneficiary.getWorkchain() == MY_WORKCHAIN) throw Errors.WrongWorkchain;

            if (slot.pendingTransfer == null) {
                dynamic.pendingSlotTransfersCount += 1;
            }
            slot.pendingTransfer = PendingSlotTransfer {
                newBeneficiary: msg.newBeneficiary,
                expiresAt: (blockchain.now() + SLOT_TRANSFER_ACCEPTANCE_SECONDS) as uint64,
            }.toCell();
            dynamic.slots.set(msg.slotId, slot.toCell());
            lockerSave(mutate storage, config, authorities, asset, dynamic);
            lockerReturnCallerExcess(in.senderAddress, msg.slotId, in.valueCoins);
        }

        AcceptSlotTransfer => {
            var storage = lazy ReleaseLpLockerStorage.load();
            val (config, authorities, asset) = lockerLoadConfig(storage);
            var dynamic = storage.dynamic.load();
            assert (authorities.controllerAddress != null) throw Errors.LockerNotBound;
            assert (asset.lpJettonMaster != null) throw Errors.LockerNotBound;
            assert (asset.lockerLpWallet != null) throw Errors.LockerNotBound;
            assertSlotTransferFunded(in.valueCoins, config);

            val slotLookup = dynamic.slots.get(msg.slotId);
            assert (slotLookup.isFound) throw Errors.SlotNotFound;
            assert (!dynamic.pendingWithdrawals.exists(msg.slotId)) throw Errors.WithdrawPending;
            var slot = slotLookup.loadValue().load();
            assert (slot.pendingTransfer != null) throw Errors.SlotTransferNotPending;
            val transfer = slot.pendingTransfer!.load();
            assert (blockchain.now() <= transfer.expiresAt) throw Errors.SlotTransferExpired;
            assert (
                in.senderAddress == transfer.newBeneficiary
            ) throw Errors.NotProposedBeneficiary;

            // Amount and timestamps are deliberately left untouched. Only the
            // address entitled to the eventual LP withdrawal changes.
            slot.beneficiary = transfer.newBeneficiary;
            slot.pendingTransfer = null;
            dynamic.slots.set(msg.slotId, slot.toCell());
            decrementPendingSlotTransferCount(mutate dynamic);
            lockerSave(mutate storage, config, authorities, asset, dynamic);
            lockerReturnCallerExcess(in.senderAddress, msg.slotId, in.valueCoins);
        }

        CancelSlotTransfer => {
            var storage = lazy ReleaseLpLockerStorage.load();
            val (config, authorities, asset) = lockerLoadConfig(storage);
            var dynamic = storage.dynamic.load();
            assert (authorities.controllerAddress != null) throw Errors.LockerNotBound;
            assertSlotTransferFunded(in.valueCoins, config);

            val slotLookup = dynamic.slots.get(msg.slotId);
            assert (slotLookup.isFound) throw Errors.SlotNotFound;
            var slot = slotLookup.loadValue().load();
            assert (in.senderAddress == slot.beneficiary) throw Errors.NotBeneficiary;
            assert (slot.pendingTransfer != null) throw Errors.SlotTransferNotPending;
            slot.pendingTransfer = null;
            dynamic.slots.set(msg.slotId, slot.toCell());
            decrementPendingSlotTransferCount(mutate dynamic);
            lockerSave(mutate storage, config, authorities, asset, dynamic);
            lockerReturnCallerExcess(in.senderAddress, msg.slotId, in.valueCoins);
        }

        PruneExpiredSlotTransfer => {
            var storage = lazy ReleaseLpLockerStorage.load();
            val (config, authorities, asset) = lockerLoadConfig(storage);
            var dynamic = storage.dynamic.load();
            assert (authorities.controllerAddress != null) throw Errors.LockerNotBound;
            assertSlotTransferFunded(in.valueCoins, config);

            val slotLookup = dynamic.slots.get(msg.slotId);
            assert (slotLookup.isFound) throw Errors.SlotNotFound;
            var slot = slotLookup.loadValue().load();
            assert (slot.pendingTransfer != null) throw Errors.SlotTransferNotPending;
            assert (
                blockchain.now() > slot.pendingTransfer!.load().expiresAt
            ) throw Errors.SlotTransferExpired;
            slot.pendingTransfer = null;
            dynamic.slots.set(msg.slotId, slot.toCell());
            decrementPendingSlotTransferCount(mutate dynamic);
            lockerSave(mutate storage, config, authorities, asset, dynamic);
            lockerReturnCallerExcess(in.senderAddress, msg.slotId, in.valueCoins);
        }

        WithdrawSlot => {
            var storage = lazy ReleaseLpLockerStorage.load();
            val (config, authorities, asset) = lockerLoadConfig(storage);
            var dynamic = storage.dynamic.load();
            assert (authorities.controllerAddress != null) throw Errors.LockerNotBound;
            assert (asset.lpJettonMaster != null) throw Errors.LockerNotBound;
            assert (asset.lockerLpWallet != null) throw Errors.LockerNotBound;

            val lookup = dynamic.slots.get(msg.slotId);
            assert (lookup.isFound) throw Errors.SlotNotFound;
            var slot = lookup.loadValue().load();
            assert (in.senderAddress == slot.beneficiary) throw Errors.NotBeneficiary;
            assert (blockchain.now() >= slot.unlockAt) throw Errors.SlotLocked;
            assert (!dynamic.pendingWithdrawals.exists(msg.slotId)) throw Errors.WithdrawPending;
            assert (in.valueCoins > config.withdrawWalletMessageValue) throw Errors.NotEnoughGas;

            // Starting a withdrawal is an unambiguous cancellation by the
            // current owner. A stale recipient can never accept afterward.
            if (slot.pendingTransfer != null) {
                slot.pendingTransfer = null;
                dynamic.slots.set(msg.slotId, slot.toCell());
                decrementPendingSlotTransferCount(mutate dynamic);
            }
            val beneficiaryLpWallet = calcAddressOfStonLpWallet(
                slot.beneficiary,
                asset.lpJettonMaster!,
                asset.lpWalletCode,
            );

            dynamic
                .pendingWithdrawals
                .set(
                    msg.slotId,
                    PendingWithdrawal {
                        slotId: msg.slotId,
                        beneficiaryLpWallet,
                        lpAmount: slot.lpAmount,
                        initiatedAt: blockchain.now() as uint64,
                    }.toCell(),
                );
            lockerSave(mutate storage, config, authorities, asset, dynamic);

            lockerReservePreexistingBalance(in.valueCoins);
            val transfer = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: asset.lockerLpWallet!,
                value: config.withdrawWalletMessageValue,
                body: AskToTransfer {
                    queryId: msg.slotId,
                    jettonAmount: slot.lpAmount,
                    transferRecipient: slot.beneficiary,
                    sendExcessesTo: contract.getAddress(),
                    customPayload: null,
                    forwardTonAmount: 0,
                    forwardPayload: beginCell().storeUint(0, 1).endCell().beginParse(),
                },
            });
            transfer.send(
                SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL,
            );
        }

        ReturnExcessesBack => {
            var storage = lazy ReleaseLpLockerStorage.load();
            val (config, authorities, asset) = lockerLoadConfig(storage);
            var dynamic = storage.dynamic.load();
            val pendingLookup = dynamic.pendingWithdrawals.get(msg.queryId);
            assert (pendingLookup.isFound) throw Errors.WithdrawNotPending;
            val pending = pendingLookup.loadValue().load();
            assert (
                in.senderAddress == pending.beneficiaryLpWallet
            ) throw Errors.WrongConfirmationWallet;

            val slotLookup = dynamic.slots.get(pending.slotId);
            assert (slotLookup.isFound) throw Errors.SlotNotFound;
            var slot = slotLookup.loadValue().load();
            assert (slot.lpAmount >= pending.lpAmount) throw Errors.InvalidAmount;
            dynamic.pendingWithdrawals.delete(pending.slotId);
            slot.lpAmount -= pending.lpAmount;
            if (slot.lpAmount == 0) {
                dynamic.slots.delete(pending.slotId);
                dynamic.slotsCount -= 1;
            } else {
                dynamic.slots.set(pending.slotId, slot.toCell());
            }
            dynamic.totalLockedLp -= pending.lpAmount;
            dynamic.totalWithdrawnLp += pending.lpAmount;
            lockerSave(mutate storage, config, authorities, asset, dynamic);

            val confirmation = createMessage({
                bounce: BounceMode.NoBounce,
                dest: slot.beneficiary,
                value: 0,
                body: WithdrawConfirmed {
                    slotId: pending.slotId,
                    lpAmount: pending.lpAmount,
                },
            });
            // SAFETY: only the remainder of the authenticated excesses message is returned.
            confirmation.send(
                SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS,
            );
        }

        PruneExpiredLockIntent => {
            var storage = lazy ReleaseLpLockerStorage.load();
            val (config, authorities, asset) = lockerLoadConfig(storage);
            var dynamic = storage.dynamic.load();
            assertSlotTransferFunded(in.valueCoins, config);
            val lookup = dynamic.lockIntents.get(msg.operationId);
            assert (lookup.isFound) throw Errors.LockIntentNotRegistered;
            val intent = lookup.loadValue().load();
            assert (blockchain.now() >= intent.expiresAt) throw Errors.LockIntentNotExpired;
            dynamic.lockIntents.delete(msg.operationId);
            dynamic.lockIntentsCount -= 1;
            lockerSave(mutate storage, config, authorities, asset, dynamic);
            lockerReturnCallerExcess(in.senderAddress, msg.operationId, in.valueCoins);
        }

        TopUpTons => {}
        else => throw Errors.UnknownOp,
    }
}

get fun get_locker_summary(): LockerSummaryReply {
    val storage = lazy ReleaseLpLockerStorage.load();
    val (_, authorities, _) = lockerLoadConfig(storage);
    val dynamic = storage.dynamic.load();
    return {
        sealed: authorities.bootstrapAdmin == null && authorities.controllerAddress != null,
        lockIntentsCount: dynamic.lockIntentsCount,
        slotsCount: dynamic.slotsCount,
        pendingSlotTransfersCount: dynamic.pendingSlotTransfersCount,
        totalLockedLp: dynamic.totalLockedLp,
        totalWithdrawnLp: dynamic.totalWithdrawnLp,
        lockSeconds: RELEASE_LOCK_SECONDS,
        slotTransferAcceptanceSeconds: SLOT_TRANSFER_ACCEPTANCE_SECONDS,
    };
}

get fun get_lock_intent(operationId: uint64): LockIntentReply {
    val storage = lazy ReleaseLpLockerStorage.load();
    val dynamic = storage.dynamic.load();
    val lookup = dynamic.lockIntents.get(operationId);
    if (!lookup.isFound) {
        return {
            exists: false,
            beneficiary: null,
            beneficiaryLpWallet: null,
            minLpOut: 0,
            deadline: 0,
            expiresAt: 0,
        };
    }
    val intent = lookup.loadValue().load();
    return {
        exists: true,
        beneficiary: intent.beneficiary,
        beneficiaryLpWallet: intent.beneficiaryLpWallet,
        minLpOut: intent.minLpOut,
        deadline: intent.deadline,
        expiresAt: intent.expiresAt,
    };
}

get fun get_locker_config(): LockerConfigReply {
    val storage = lazy ReleaseLpLockerStorage.load();
    val (config, authorities, asset) = lockerLoadConfig(storage);
    return {
        bootstrapAdmin: authorities.bootstrapAdmin,
        controllerAddress: authorities.controllerAddress,
        lpJettonMaster: asset.lpJettonMaster,
        poolAddress: asset.poolAddress,
        lpWalletCode: asset.lpWalletCode,
        lockerLpWallet: asset.lockerLpWallet,
        withdrawWalletMessageValue: config.withdrawWalletMessageValue,
        slotTransferMessageValue: config.slotTransferMessageValue,
        slotStorageDeposit: config.slotStorageDeposit,
        maxSlots: config.maxSlots,
    };
}

get fun get_lock_slot(slotId: uint64): LockSlotReply {
    val storage = lazy ReleaseLpLockerStorage.load();
    val (_, _, asset) = lockerLoadConfig(storage);
    val dynamic = storage.dynamic.load();
    val lookup = dynamic.slots.get(slotId);
    if (!lookup.isFound) {
        return {
            exists: false,
            originBeneficiary: null,
            beneficiary: null,
            beneficiaryLpWallet: null,
            lpAmount: 0,
            createdAt: 0,
            unlockAt: 0,
            withdrawPending: false,
        };
    }
    val slot = lookup.loadValue().load();
    val beneficiaryLpWallet = asset.lpJettonMaster == null
        ? null
        : calcAddressOfStonLpWallet(
            slot.beneficiary,
            asset.lpJettonMaster!,
            asset.lpWalletCode,
        );
    return {
        exists: true,
        originBeneficiary: slot.originBeneficiary,
        beneficiary: slot.beneficiary,
        beneficiaryLpWallet,
        lpAmount: slot.lpAmount,
        createdAt: slot.createdAt,
        unlockAt: slot.unlockAt,
        withdrawPending: dynamic.pendingWithdrawals.exists(slotId),
    };
}

get fun get_slot_transfer(slotId: uint64): SlotTransferReply {
    val storage = lazy ReleaseLpLockerStorage.load();
    val dynamic = storage.dynamic.load();
    val slotLookup = dynamic.slots.get(slotId);
    if (!slotLookup.isFound) {
        return {
            exists: false,
            newBeneficiary: null,
            expiresAt: 0,
        };
    }
    val pendingTransfer = slotLookup.loadValue().load().pendingTransfer;
    if (pendingTransfer == null) {
        return {
            exists: false,
            newBeneficiary: null,
            expiresAt: 0,
        };
    }
    val transfer = pendingTransfer!.load();
    return {
        exists: true,
        newBeneficiary: transfer.newBeneficiary,
        expiresAt: transfer.expiresAt,
    };
}
