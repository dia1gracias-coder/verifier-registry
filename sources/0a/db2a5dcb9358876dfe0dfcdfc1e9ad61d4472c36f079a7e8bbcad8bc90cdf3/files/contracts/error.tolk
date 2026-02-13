// ============================================
// SYSTEM ERRORS
// ============================================
const ERROR_UNKNOWN_OPERATION : uint16 = 0xFFFF

// ============================================
// PERMISSION ERRORS (1001-1019)
// ============================================
const ERROR_NOT_ADMIN : uint16 = 1001
const ERROR_NOT_OWNER : uint16 = 1002
const ERROR_NOT_AUTHORIZED : uint16 = 1003

// ============================================
// VALIDATION ERRORS (1020-1039)
// ============================================
const ERROR_INVALID_ROLE : uint16 = 1020
const ERROR_INVALID_WORKCHAIN : uint16 = 1021
const ERROR_INVALID_ADDRESS : uint16 = 1022
const ERROR_INVALID_CONTENT : uint16 = 1023
const ERROR_INVALID_BATCH_SIZE: uint16 = 1024;  // Batch size is 0
const ERROR_BATCH_TOO_LARGE: uint16 = 1025;     // Batch size exceeds maximum
// Add to error.tolk
const ERROR_INSUFFICIENT_BALANCE: uint16 = 1026;  // Not enough balance to withdraw

// ============================================
// OWNER STATE ERRORS (1045-1059)
// ============================================
const ERROR_MAX_OWNERS_REACHED : uint16 = 1045
const ERROR_MINIMUM_OWNERS_REQUIRED : uint16 = 1046
const ERROR_OWNER_ALREADY_EXISTS : uint16 = 1047
const ERROR_OWNER_NOT_FOUND : uint16 = 1048
const ERROR_OWNER_ALREADY_DISABLED : uint16 = 1049
const ERROR_OWNER_ALREADY_ACTIVE : uint16 = 1050
const ERROR_CANNOT_REMOVE_OWNER : uint16 = 1051

// ============================================
// SYSTEM STATE ERRORS (1060-1069)
// ============================================
const ERROR_MASTER_ALREADY_PAUSED : uint16 = 1060
const ERROR_MASTER_NOT_PAUSED : uint16 = 1061
const ERROR_MASTER_PAUSED : uint16 = 1062
const ERROR_COLLECTION_ALREADY_PAUSED : uint16 = 1063
const ERROR_COLLECTION_NOT_PAUSED : uint16 = 1064

// ============================================
// CAPACITY ERRORS (1070-1079)
// ============================================
const ERROR_MAX_COLLECTIONS_REACHED : uint16 = 1070
const ERROR_MAX_ITEMS_REACHED : uint16 = 1071

// ============================================
// NFT ITEM ERRORS (1080-1099)
// ============================================
const ERROR_NFT_PAUSED : uint16 = 1080
const ERROR_NFT_NOT_PAUSED : uint16 = 1081
const ERROR_INSUFFICIENT_VALUE : uint16 = 1082
const ERROR_NFT_NOT_INITIALIZED : uint16 = 1083
