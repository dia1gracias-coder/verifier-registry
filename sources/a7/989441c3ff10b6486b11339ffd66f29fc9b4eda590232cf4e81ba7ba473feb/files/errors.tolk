// Error codes used by the NFT item/collection contracts.
// Values follow the educational reference implementations where possible.

const ERROR_NOT_FROM_ADMIN = 401;
const ERROR_NOT_FROM_OWNER = 401;
const ERROR_NOT_FROM_COLLECTION = 405;

const ERROR_BATCH_LIMIT_EXCEEDED = 399;
const ERROR_INVALID_ITEM_INDEX = 402;
const ERROR_INCORRECT_FORWARD_PAYLOAD = 708;
const ERROR_INVALID_WORKCHAIN = 333;
const ERROR_TOO_SMALL_REST_AMOUNT = 402;

// Raised when the attached TON is insufficient to cover royalty + forwarding/gas bounds.
const ERROR_NOT_ENOUGH_ATTACHED_TON_FOR_ROYALTY = 403;
