// ============================================================
//  Grm DNS Domains — every tunable number of the system
// ============================================================

// ---------------- time ----------------
const ONE_YEAR = 31536000 // 365 days — how long a domain stays valid

// ---------------- auction ----------------
const AUCTION_DURATION = 600
// Anti-sniping: a bid in the final AUCTION_PROLONGATION seconds pushes the
// deadline that far out again. When shortening AUCTION_DURATION for testing,
// shorten this too — otherwise every bid lands inside the window and the
// auction can never end.
const AUCTION_PROLONGATION = 60
const MIN_BID_STEP_PERCENT = 105 // each bid must be at least +5%

// ---------------- domain ----------------
const MIN_DOMAIN_LENGTH = 1 // "k.grm" is allowed
const MAX_DOMAIN_LENGTH = 126
const TLD_SUFFIX = 0x2E67726D // ".grm" — stripped if the user typed the full name

// ---------------- GRM jetton ----------------
// GRM has 9 decimals.
const GRM_UNIT = 1000000000

// ---------------- gas ----------------
// None of these is "the price of minting" — they are pure gas figures, and
// everything above them is returned to the sender.
const MIN_TONS_FOR_STORAGE = ton("0.05") // kept on every domain contract
const MIN_TONS_FOR_COLLECTION = ton("0.1") // kept on the collection
// Worst case measured: validating and hashing a 126-character name costs about
// 0.053 TON of gas in the collection alone, then the domain contract still has
// to keep MIN_TONS_FOR_STORAGE. Raising this floor costs bidders nothing —
// whatever is not spent comes straight back as change.
const MIN_BID_TON = ton("0.15") // forward_ton_amount required per bid
const MIN_FINALIZE_TON = ton("0.1") // required to close an auction
const GAS_SETTLE = ton("0.05") // must cover the jetton burn
const GAS_NOTIFY = ton("0.01") // ownership notification to the winner
const GAS_FUNDING_NOTIFY = ton("0.02") // makes the domain wallet notify the domain

// ---------------- DNS ----------------
const DNS_NEXT_RESOLVER_PREFIX = 0xba93

// ---------------- metadata (TEP-64) ----------------
// Written when a domain is first auctioned, derived from the domain itself,
// and rejected by ChangeDnsRecord afterwards. Mirrors the live Gram DNS
// metadata with GRAM renamed to GRM and .gram to .grm.
//   name        -> "<domain>.grm"
//   description -> the constant below, identical for every domain
//   image       -> "https://dns-cdn.gramcoin.org/dnsimage/<domain>.png"
const IMAGE_URL_PREFIX = "https://dns-cdn.gramcoin.org/dnsimage/"
const IMAGE_URL_SUFFIX = ".png"
const NAME_SUFFIX = ".grm"
const DOMAIN_DESCRIPTION = "A .grm blockchain domain. Grm DNS is a service that allows users to assign a human-readable name to crypto wallets, smart contracts, and websites."

const KEY_NAME = "name".sha256()
const KEY_DESCRIPTION = "description".sha256()
const KEY_IMAGE = "image".sha256()
const KEY_NEXT_RESOLVER = "dns_next_resolver".sha256()

// ---------------- DNS record categories (TEP-81) ----------------
// The contract stores record values as opaque cells, exactly like TON DNS, so
// any present or future category works without a contract change. These are
// the well-known ones:
//   wallet  -> dns_smc_address#9fd3    smc_addr:MsgAddressInt flags:uint8
//   site    -> dns_adnl_address#ad01   adnl_addr:bits256 flags:uint8
//           or dns_storage_address#7473 bag_id:bits256
//   storage -> dns_storage_address#7473 bag_id:bits256
const KEY_WALLET = "wallet".sha256()
const KEY_SITE = "site".sha256()
const KEY_STORAGE = "storage".sha256()

const DNS_SMC_ADDRESS_PREFIX = 0x9fd3
const DNS_ADNL_ADDRESS_PREFIX = 0xad01
const DNS_STORAGE_ADDRESS_PREFIX = 0x7473
