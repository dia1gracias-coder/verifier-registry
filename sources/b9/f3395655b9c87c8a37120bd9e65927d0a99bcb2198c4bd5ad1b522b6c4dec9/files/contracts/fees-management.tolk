/// The NFT item keeps this amount after each transfer, matching the reference TEP-62 item.
const NFT_ITEM_STORAGE_RESERVE = ton("0.05")

/// Hard on-chain limit for the three persistent claim dictionaries. This is intentionally
/// conservative relative to TON's account-state cell limits and must not be raised without a
/// fresh state-growth analysis and independent audit.
const MAX_COLLECTION_SUPPLY = 8000

/// Signup Ape uses deterministic item indexes and stores no per-claim dictionaries in the
/// collection account. Its capacity is therefore a business limit rather than an account-state
/// growth limit. Keep this separate from MAX_COLLECTION_SUPPLY: the paid collection bytecode must
/// never inherit this larger ceiling.
const MAX_SIGNUP_COLLECTION_SUPPLY = 1000000

/// Each new item receives enough value to initialize and retain its storage reserve in local tests.
const NFT_ITEM_DEPLOY_VALUE = ton("0.08")

/// Minimum collection balance protected while processing a claim. There is deliberately no
/// owner sweep: processing buffers remain in the collection until audited dynamic rent economics
/// are available.
const COLLECTION_STORAGE_RESERVE = ton("0.10")

/// Amount left from each mint payment for compute/action fees and growing storage rent.
const CLAIM_PROCESSING_BUFFER = ton("0.07")

/// Owner cannot set a lower claim price. Re-evaluate after any code or network fee change.
const MIN_CLAIM_PRICE = NFT_ITEM_DEPLOY_VALUE + CLAIM_PROCESSING_BUFFER

/// Every TEP-62 transfer performs an authenticated item -> collection -> item
/// policy round trip so a freeze toggle applies immediately to already-minted
/// NFTs. The item sends a fixed, bounded amount; the collection returns the
/// remainder and never uses carry-all mode (which could sweep collection rent
/// reserves or accumulated claim buffers).
const TRANSFER_POLICY_REQUEST_VALUE = ton("0.05")
const TRANSFER_POLICY_PROCESSING_BUFFER = ton("0.02")
const TRANSFER_POLICY_COMPLETION_BUFFER = ton("0.005")
const MIN_NFT_TRANSFER_VALUE = ton("0.065")

/// A bounced item deployment already returned its deploy value to the collection.
/// A retry only supplies a fresh compute/action budget and never pays treasury again.
const RETRY_CLAIM_PAYMENT = CLAIM_PROCESSING_BUFFER

/// Personal vault storage reserve and withdrawal transaction budget.
const VAULT_STORAGE_RESERVE = ton("0.05")
const VAULT_PROCESSING_BUFFER = ton("0.03")
const MIN_VAULT_WITHDRAW_VALUE = ton("0.10")
