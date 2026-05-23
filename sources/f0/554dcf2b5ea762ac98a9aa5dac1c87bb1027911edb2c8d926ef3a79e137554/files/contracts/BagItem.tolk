// BagItem — child contract holding one registered TON Storage bag.
//
// Deployed by BagRegistry (the master) with a deterministic address derived
// from (BagItem code, bag index, registry address). Lifecycle:
//
//   1. Deployed in the NotInitialized state (index + registry only).
//   2. Initialized exactly once by the registry's init message.
//   3. Afterwards, only the original uploader may deactivate it.
//   4. On deactivation, the residual balance is refunded to the uploader,
//      keeping only a tiny rent floor so the on-chain record persists.
//
// Audit fixes implemented here:
//   C4 — empty-body messages are accepted as top-ups before any other logic,
//        so the contract is always rechargeable.
//   H1 — DeactivateBag refunds the residual balance to the uploader so no
//        funds remain locked beyond a multi-decade rent floor.
//   M2 — init state is an EXPLICIT union discriminant, routed with `match`,
//        not a fragile `remainingRefsCount()` heuristic.
//   M3 — typed `contract` ABI declaration.
//   L3 — getters return clean sentinels (none-address, zeros) while
//        uninitialized, never a misleading placeholder address.

import "errors.tolk"
import "events.tolk"
import "messages.tolk"
import "storage.tolk"

// ===========================================================================
// ECONOMIC CONSTANTS
//
// DEACTIVATED_FLOOR keeps the item alive after DeactivateBag so the index
// stays queryable on-chain (`get_bag_data` returns `isActive: false`,
// `get_storage_metadata` keeps its data). 0.005 TON covers many decades of
// basechain storage rent for the typical metadata size.
// ===========================================================================

const DEACTIVATED_FLOOR: coins = ton("0.005")

// Mirror of the struct-attached opcode of `DeactivateBag` (messages.tolk).
// Used by the explicit opcode pre-check so an unknown body produces the
// standard TVM "unknown opcode" exit (0xFFFF) rather than the typed parser's
// prefix-mismatch code.
const OP_DEACTIVATE_BAG: int = 0x44454143

// ===========================================================================
// CONTRACT ABI DECLARATION (M3)
//
// Storage is the `BagItemData` union in BOTH states. The deployment shape is
// the union as well: the registry writes the pre-init data through the union
// serializer (`serializeBagItemData`), so the deployed cell always carries the
// 1-bit `Either` discriminant (tag 0 => NotInitialized). Declaring the bare
// `BagItemDataNotInitialized` struct here would advertise a 1-bit-shorter cell,
// yield a wrong deployment address, and make the child underflow on load.
// ===========================================================================

contract BagItem {
    author: "piracy.ton"
    version: "2.0.0"
    description: "Child contract for one indexed TON Storage bag"

    storage: BagItemData
    storageAtDeployment: BagItemDataNotInitialized
    incomingMessages: BagItemMessage
    thrownErrors: BagError
}

// ===========================================================================
// MESSAGE HANDLING
// ===========================================================================

fun onInternalMessage(in: InMessage) {
    // C4: accept empty-body messages as top-ups (storage-rent recharge) before
    // any other logic. Without this, a recharge would be rejected and the
    // contract could eventually be frozen for non-payment.
    if (in.body.isEmpty()) {
        return;
    }

    // M2: explicit init-state discriminant — `match` on the union tag.
    val data = BagItemData.load();
    match (data) {
        BagItemDataNotInitialized => {
            // Only the parent registry may perform the one-shot init.
            assert (in.senderAddress == data.registryAddress) throw BagError.NotFromRegistry;

            // The init body carries the BagItemInitParams opcode; parsing it
            // also validates that opcode.
            val params = BagItemInitParams.fromSlice(in.body);

            val initialized: BagItemData = BagItemDataInitialized {
                bagIndex: data.bagIndex,
                registryAddress: data.registryAddress,
                bagId: params.bagId,
                name: params.name,
                category: params.category,
                uploaderAddress: params.uploaderAddress,
                timestamp: params.timestamp,
                isActive: true,
                metadata: params.metadata,
            };
            initialized.save();
        }

        BagItemDataInitialized => {
            // Explicit opcode pre-check (surfaces 0xFFFF on unknown bodies).
            // Empty bodies were accepted as top-ups in the early return at
            // the top of `onInternalMessage`.
            assert (in.body.preloadUint(32) == OP_DEACTIVATE_BAG) throw 0xFFFF;
            val _msg = DeactivateBag.fromSlice(in.body);

            assert (in.senderAddress == data.uploaderAddress) throw BagError.NotFromUploader;

            // Idempotency guard: refuse a second deactivation on an already
            // inactive bag. Without this check a re-call would emit a
            // duplicate BagRemovedEvent (confusing indexers) and process a
            // no-op refund (wasting the caller's gas). Throwing 272 reverts
            // the message and bounces the value back to the uploader.
            assert (data.isActive) throw BagError.AlreadyInactive;

            // Flip the active flag and persist.
            var updated = data;
            updated.isActive = false;
            updated.save();

            // Emit the deactivation event. It MUST be queued before the
            // reserve + carry-all-balance refund: a forward fee is paid from
            // the balance, and the mode-128 refund below leaves nothing
            // behind to pay later actions with.
            emitBagRemoved({
                bagIndex: data.bagIndex,
                removedBy: in.senderAddress,
            });

            // H1: reserve a tiny rent floor and refund EVERY remaining
            // nanoton to the uploader. The item stays alive (the index
            // remains on-chain queryable, `isActive == false`), but no
            // residual funds are locked beyond a multi-decade reserve.
            reserveToncoinsOnBalance(DEACTIVATED_FLOOR, RESERVE_MODE_EXACT_AMOUNT);
            val refundMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: in.senderAddress,
                // ignored under mode 128 (carry all remaining balance)
                value: 0,
            });
            // SAFETY: mode 128 (carry all remaining balance) runs ONLY after
            // `reserveToncoinsOnBalance(DEACTIVATED_FLOOR, EXACT)` above, so it
            // can never drain the contract below its multi-decade rent floor.
            // Mode 2 (ignore errors) prevents a failed refund action from
            // reverting the already-committed `isActive = false` save + emit.
            // Required invariant: the reserve action must be queued before
            // this send (the action queue is processed in insertion order).
            refundMsg.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS);
        }
    }
}

// ===========================================================================
// GET METHODS
//
// The getter reply shapes (BagDataReply, StaticDataReply, StorageMetadataReply)
// are declared in `messages.tolk` so generated wrappers can name them.
//
// L3: while uninitialized, getters return clean sentinels — a none-address
// (`createAddressNone()`) and zeros — plus a clear `isInitialized` flag. They
// never substitute the registry address for a missing uploader address.
// ===========================================================================

/// Full identity + status of the bag.
get fun get_bag_data(): BagDataReply {
    val data = BagItemData.load();
    match (data) {
        BagItemDataNotInitialized => {
            return {
                isInitialized: false,
                bagIndex: data.bagIndex,
                registryAddress: data.registryAddress,
                bagId: 0,
                name: createEmptyCell(),
                category: 0,
                uploaderAddress: createAddressNone() as address,
                timestamp: 0,
                isActive: false,
            };
        }
        BagItemDataInitialized => {
            return {
                isInitialized: true,
                bagIndex: data.bagIndex,
                registryAddress: data.registryAddress,
                bagId: data.bagId,
                name: data.name,
                category: data.category,
                uploaderAddress: data.uploaderAddress,
                timestamp: data.timestamp,
                isActive: data.isActive,
            };
        }
    }
}

/// Static identity: (bagIndex, registryAddress). Valid in both states.
get fun get_static_data(): StaticDataReply {
    val data = BagItemData.load();
    match (data) {
        BagItemDataNotInitialized => {
            return { bagIndex: data.bagIndex, registryAddress: data.registryAddress };
        }
        BagItemDataInitialized => {
            return { bagIndex: data.bagIndex, registryAddress: data.registryAddress };
        }
    }
}

/// TON Storage technical metadata of the bag.
get fun get_storage_metadata(): StorageMetadataReply {
    val data = BagItemData.load();
    match (data) {
        BagItemDataNotInitialized => {
            return {
                isInitialized: false,
                description: createEmptyCell(),
                bagSize: 0,
                filesCount: 0,
                files: createEmptyCell(),
                pieceSize: 0,
                merkleHash: 0,
                dirName: createEmptyCell(),
            };
        }
        BagItemDataInitialized => {
            val m = data.metadata.load();
            return {
                isInitialized: true,
                description: m.description,
                bagSize: m.bagSize,
                filesCount: m.filesCount,
                files: m.files,
                pieceSize: m.pieceSize,
                merkleHash: m.merkleHash,
                dirName: m.dirName,
            };
        }
    }
}

/// Whether the bag is currently active. False while uninitialized.
get fun is_active(): bool {
    val data = BagItemData.load();
    return match (data) {
        BagItemDataNotInitialized => false,
        BagItemDataInitialized => data.isActive,
    };
}
