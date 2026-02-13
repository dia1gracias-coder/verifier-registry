// ============================================
// ROLE CONSTANTS
// ============================================
const ROLE_OWNER : uint8 = 1

// ============================================
// OWNER MANAGEMENT CONSTANTS
// ============================================
const MAX_OWNERS : uint8 = 5
const MIN_OWNERS : uint8 = 3
const REQUIRED_SIGNATURES : uint8 = 3 // For future multi-sig

// ============================================
// OWNER OPCODES (0x0002xxxx)
// ============================================
const OPCODE_ADD_OWNER : uint32 = 0x00020001
const OPCODE_REMOVE_OWNER : uint32 = 0x00020002
const OPCODE_DISABLE_OWNER : uint32 = 0x00020003
const OPCODE_ENABLE_OWNER : uint32 = 0x00020004

// ============================================
// PROPOSAL OPCODES (0x0003xxxx) - Future multi-sig
// ============================================
const OPCODE_CREATE_PROPOSAL : uint32 = 0x00030001
const OPCODE_SIGN_PROPOSAL : uint32 = 0x00030002
const OPCODE_EXECUTE_PROPOSAL : uint32 = 0x00030003
const OPCODE_CANCEL_PROPOSAL : uint32 = 0x00030004

// ============================================
// COLLECTION OPCODES (0x0004xxxx) - Future
// ============================================
const OPCODE_DEPLOY_COLLECTION : uint32 = 0x00040001
const OPCODE_PAUSE_COLLECTION : uint32 = 0x00040002
const OPCODE_UNPAUSE_COLLECTION : uint32 = 0x00040003

// ============================================
// NFT OPCODES (0x0005xxxx)
// ============================================
const OPCODE_MINT_NFT : uint32 = 0x00050001
const OPCODE_BATCH_MINT_NFT : uint32 = 0x00050002
const OPCODE_BURN_NFT : uint32 = 0x00050003
const OPCODE_PAUSE_NFT : uint32 = 0x00050004 // Changed from FREEZE
const OPCODE_UNPAUSE_NFT : uint32 = 0x00050005 // Changed from UNFREEZE
const OPCODE_REVOKE_NFT : uint32 = 0x00050006 // New: Multi-sig revoke
const OPCODE_BATCH_TRANSFER : uint32 = 0x00050007 // New: Batch transfer

// ============================================
// TEP-62 STANDARD OPCODES
// ============================================
const OPCODE_TRANSFER : uint32 = 0x5fcc3d14 // TEP-62 transfer
const OPCODE_OWNERSHIP_ASSIGNED : uint32 = 0x05138d91 // TEP-62 notification
const OPCODE_EXCESSES : uint32 = 0xd53276db // Return excess TON

// ============================================
// SYSTEM CONTROL OPCODES (0x0006xxxx)
// ============================================
const OPCODE_PAUSE_MASTER : uint32 = 0x00060001
const OPCODE_UNPAUSE_MASTER : uint32 = 0x00060002

// ============================================
// CONTRACT TYPE CONSTANTS
// ============================================
const JETTON_MASTER_ADDRESS_KEY : uint64 = 1
