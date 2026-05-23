// Message bodies for BagRegistry and BagItem.
//
// M3 fix: every on-chain message is a struct with an explicit 32-bit opcode,
// grouped into a union and routed with `match` in the entrypoints.
//
// M1 fix (schema margin): the original AddBag carried `name`, `description`,
// `files` and `dirName` as four top-level refs — exactly the 4-ref cell cap,
// leaving zero room to ever extend the schema. The TON Storage technical
// fields are now nested into a single `Cell<BagMetadata>` ref, so AddBag and
// BagItemInitParams each use only 2 refs and stay extensible.
// ===========================================================================
// SHARED PAYLOAD TYPES
// ===========================================================================

/// TON Storage technical metadata for a bag. Carried as one ref (`Cell<...>`)
/// inside AddBag, the init params and the on-chain BagItem storage.
struct BagMetadata {
    /// Human-readable description, snake-format string cell.
    description: cell
    /// Total bag size in bytes.
    bagSize: uint64
    /// Number of files in the bag.
    filesCount: uint32
    /// Dictionary cell: file index -> (name, size).
    files: cell
    /// TON Storage piece size used for transfers.
    pieceSize: uint32
    /// Merkle root hash for integrity verification.
    merkleHash: uint256
    /// Root directory name, snake-format string cell.
    dirName: cell
}

// ===========================================================================
// REGISTRY -> ITEM : deploy / init params
// ===========================================================================

/// Body of the deploy message sent by BagRegistry to a fresh BagItem.
///
/// Opcode 0x42495F49 = "BI_I" (Bag Item Init). A dedicated opcode lets the
/// BagItem reject any non-init traffic that reaches it while uninitialized.
struct (0x42495F49) BagItemInitParams {
    /// TON Storage bag hash.
    bagId: uint256
    /// Category id, 0..5 (validated by the registry before deploy).
    category: uint8
    /// Wallet that registered the bag (refunded surplus is unrelated; this is
    /// just provenance). Becomes the only address allowed to deactivate.
    uploaderAddress: address
    /// Registration time (registry block time).
    timestamp: uint64
    /// Bag display name, snake-format string cell.
    name: cell
    /// TON Storage technical metadata, one ref.
    metadata: Cell<BagMetadata>
}

// ===========================================================================
// MESSAGES TO BAG REGISTRY
// ===========================================================================

/// Register a new bag. Permissionless: anyone may send it; the sender only
/// pays gas + child funding and is refunded the surplus (C3).
///
/// Opcode 0x41444247 = "ADBG" (ADd BaG).
struct (0x41444247) AddBag {
    /// TON Storage bag hash. Must be non-zero.
    bagId: uint256
    /// Category id, 0..5.
    category: uint8
    /// Bag display name, snake-format string cell.
    name: cell
    /// TON Storage technical metadata, one ref.
    metadata: Cell<BagMetadata>
}

/// Union of every internal message BagRegistry accepts.
type BagRegistryMessage = AddBag

// ===========================================================================
// MESSAGES TO BAG ITEM
// ===========================================================================

/// Deactivate a bag. Only the recorded uploader may send it.
///
/// Opcode 0x44454143 = "DEAC" (DEACtivate).
struct (0x44454143) DeactivateBag {}

/// Union of every internal message a fully initialized BagItem accepts.
/// (The one-shot init message uses the BagItemInitParams opcode separately.)
type BagItemMessage = DeactivateBag

// ===========================================================================
// BAG ITEM GETTER REPLY SHAPES
//
// These are pure data shapes returned by the BagItem get-methods. They live
// here (not in BagItem.tolk) so generated wrappers — which import only
// `messages` and `storage` — can name the getter return types. L3: while
// uninitialized, getters return clean sentinels rather than placeholder data.
// ===========================================================================

/// Identity + status reply for a bag.
struct BagDataReply {
    /// Whether the bag has been initialized by the registry.
    isInitialized: bool
    /// Sequential registry index (valid in both states).
    bagIndex: uint64
    /// Parent registry address (valid in both states).
    registryAddress: address
    /// TON Storage bag hash (0 while uninitialized).
    bagId: uint256
    /// Bag display name cell (empty cell while uninitialized).
    name: cell
    /// Category id (0 while uninitialized).
    category: uint8
    /// Uploader wallet (none-address while uninitialized).
    uploaderAddress: address
    /// Registration time (0 while uninitialized).
    timestamp: uint64
    /// Active status (false while uninitialized).
    isActive: bool
}

/// Static identity: (bagIndex, registryAddress). Valid in both states.
struct StaticDataReply {
    bagIndex: uint64
    registryAddress: address
}

/// TON Storage technical metadata of the bag.
struct StorageMetadataReply {
    /// True when the bag is initialized; the remaining fields are sentinels
    /// (empty cells / zeros) when false.
    isInitialized: bool
    description: cell
    bagSize: uint64
    filesCount: uint32
    files: cell
    pieceSize: uint32
    merkleHash: uint256
    dirName: cell
}
