// Exit codes thrown by BagRegistry and BagItem.
//
// L1 fix: only codes that are actually thrown remain. Dead constants
// (ERROR_NOT_FROM_OWNER, ERROR_INSUFFICIENT_BALANCE, ERROR_INVALID_INDEX,
// ERROR_ALREADY_INITIALIZED) were removed.
//
// Declared as an `enum` so the `contract` ABI can export `thrownErrors`.
// User exit codes live in the 256..399 range to avoid clashing with TVM
// reserved codes (0..255) and the standard "unknown opcode" code 0xFFFF.

enum BagError {
    // --- BagRegistry ---
    /// Attached value is below MIN_ADD_BAG_VALUE (M6).
    InsufficientValue = 256
    /// `bagId` is zero, which is never a valid TON Storage bag hash.
    InvalidBagId = 257
    /// `category` is outside the supported 0..5 range.
    InvalidCategory = 258
    /// A user-supplied metadata cell exceeds the configured size bounds (M1).
    MetadataTooLarge = 259
    /// `get_bag_address` was called with an index outside [0, nextBagIndex) (L2).
    IndexOutOfRange = 260

    // --- BagItem ---
    /// An init message for a fresh BagItem did not come from its registry.
    NotFromRegistry = 270
    /// A DeactivateBag message did not come from the recorded uploader.
    NotFromUploader = 271
    /// A DeactivateBag message was sent to a bag that was already deactivated.
    /// Prevents a double-emit of BagRemovedEvent and bounces the gas value back
    /// to the uploader instead of silently re-doing the no-op.
    AlreadyInactive = 272
}
