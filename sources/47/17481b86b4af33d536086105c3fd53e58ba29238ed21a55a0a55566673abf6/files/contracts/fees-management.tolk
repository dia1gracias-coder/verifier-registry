/// Minimum balance retained by each initialized NFT item.
const MIN_TONS_FOR_STORAGE = ton("0.05")

/// Value sent from an initialized item back to the collection with mint acknowledgement.
const ITEM_ACK_VALUE = ton("0.015")

/// Budget retained by the collection for mint, acknowledgement, payout and refund fees.
const MINT_GAS_BUDGET = ton("0.08")

/// Budget for validating and starting a public mint directly from the user's payment.
const DIRECT_MINT_GAS_BUDGET = ton("0.03")

/// Caller-funded budget for asking an already initialized item to repeat its mint ack.
const RETRY_FINALIZE_VALUE = ton("0.05")

/// Amount forwarded to the item during recovery. The remainder covers both hops' fees.
const RETRY_ITEM_REQUEST_VALUE = ton("0.03")

/// Default deployment value used by scripts and test fixtures.
const DEFAULT_ITEM_DEPLOY_VALUE = ton("0.12")

const CONFIG_TIMELOCK_DELAY = 60 * 60 * 48

/// A proposal must execute within seven days after its 48-hour timelock completes.
const CONFIG_PROPOSAL_EXECUTION_WINDOW = 60 * 60 * 24 * 7

/// Caller-funded budget for claiming a refund after an NFT deployment failure.
const CLAIM_FAILED_MINT_REFUND_VALUE = ton("0.03")

const MIN_ITEM_DEPLOY_VALUE = ton("0.08")
const MAX_ITEM_DEPLOY_VALUE = ton("1")
