// Persistent on-chain storage layouts for BagRegistry and BagItem.

import "messages.tolk"

// ===========================================================================
// BAG REGISTRY STORAGE (master, owner-less)
//
// C2 note: `nextBagIndex` only ever increases. It is NEVER decremented — see
// BagRegistry.tolk. A failed child deploy leaves a benign "phantom" index;
// indexers skip it via the BagItem `isInitialized` flag.
//
// The BagItem code is embedded into BagRegistry at compile time
// (`@gen/BagItem.code`), so it is intentionally NOT a storage field. This
// removes the old `bagItemCode: cell` field, makes the code immutable, and
// shrinks the master storage to a single counter.
// ===========================================================================

struct BagRegistryStorage {
    /// Index that will be assigned to the next registered bag. Starts at 0.
    nextBagIndex: uint64 = 0
}

fun BagRegistryStorage.load(): BagRegistryStorage {
    return BagRegistryStorage.fromCell(contract.getData());
}

fun BagRegistryStorage.save(self) {
    contract.setData(self.toCell());
}

// ===========================================================================
// BAG ITEM STORAGE (child)
//
// M2 fix: the old design detected init state with a fragile
// `remainingRefsCount()` heuristic. It is replaced by an EXPLICIT 1-bit
// discriminant: `BagItemData` is a union of two structs with no manual
// opcodes, so the compiler emits an `Either` prefix (`0` => NotInitialized,
// `1` => Initialized). The registry serializes the NotInitialized variant at
// deploy time; the BagItem routes on the tag with `match`.
// ===========================================================================

/// Pre-init shape: what the registry writes into a fresh BagItem's data so the
/// item's address is deterministically derivable from (code, index, registry).
struct BagItemDataNotInitialized {
    /// Sequential index assigned by the registry.
    bagIndex: uint64
    /// Parent registry address; the only sender allowed to initialize.
    registryAddress: address
}

/// Fully initialized shape: written once when the registry's init message is
/// processed. From then on the storage stays in this variant forever.
struct BagItemDataInitialized {
    /// Sequential index assigned by the registry.
    bagIndex: uint64
    /// Parent registry address.
    registryAddress: address
    /// TON Storage bag hash.
    bagId: uint256
    /// Bag display name, snake-format string cell.
    name: cell
    /// Category id, 0..5.
    category: uint8
    /// Wallet that registered the bag; only it may deactivate.
    uploaderAddress: address
    /// Registration time (Unix seconds).
    timestamp: uint64
    /// Whether the bag is currently active.
    isActive: bool
    /// TON Storage technical metadata, one ref.
    metadata: Cell<BagMetadata>
}

/// Explicit init-state discriminant. Auto-generated 1-bit `Either` prefix:
///   tag 0 -> BagItemDataNotInitialized
///   tag 1 -> BagItemDataInitialized
type BagItemData = BagItemDataNotInitialized | BagItemDataInitialized

/// Serialize a `BagItemData` value WITH its 1-bit `Either` discriminant.
///
/// This indirection is required for correctness. When `.toCell()` is invoked on
/// a value whose *static* type the compiler has narrowed to a single variant
/// (e.g. `val d: BagItemData = BagItemDataNotInitialized { ... }`), the compiler
/// emits the *bare struct* layout with NO discriminant. `BagItemData.fromCell()`
/// always reads the discriminant, so a bare cell makes it underflow (exit 9).
///
/// Routing the value through a parameter typed as the union forces the compiler
/// to emit the discriminant-bearing union layout, so `toCell`/`fromCell` stay
/// round-trip compatible regardless of how the caller built the value.
fun serializeBagItemData(data: BagItemData): cell {
    return data.toCell();
}

fun BagItemData.load(): BagItemData {
    return BagItemData.fromCell(contract.getData());
}

fun BagItemData.save(self) {
    contract.setData(serializeBagItemData(self));
}

// ===========================================================================
// CHILD ADDRESS DERIVATION
//
// The registry derives a child's address from (BagItem code, deterministic
// pre-init data). The pre-init data MUST be the NotInitialized variant so its
// 1-bit discriminant is `0`; this keeps the address stable and lets the child
// recognize its own uninitialized state.
// ===========================================================================

/// Build the AutoDeployAddress of the BagItem for `bagIndex`, given the
/// registry address and the (compile-time embedded) BagItem code.
fun calcDeployedBagItem(
    bagIndex: uint64,
    registryAddress: address,
    bagItemCode: cell,
): AutoDeployAddress {
    val preInitData: BagItemData = BagItemDataNotInitialized { bagIndex, registryAddress };
    // Serialize via the union-typed helper so the `Either` discriminant (tag 0)
    // is written. A bare `preInitData.toCell()` would omit it and the child's
    // `BagItemData.load()` would underflow on first message (exit 9).
    return { stateInit: { code: bagItemCode, data: serializeBagItemData(preInitData) } };
}
