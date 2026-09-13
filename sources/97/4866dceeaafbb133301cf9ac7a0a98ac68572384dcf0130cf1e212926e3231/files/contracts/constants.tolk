
const ONE_YEAR = 31536000

const AUCTION_DURATION = 600
const AUCTION_PROLONGATION = 60
const MIN_BID_STEP_PERCENT = 105

const MIN_DOMAIN_LENGTH = 1
const MAX_DOMAIN_LENGTH = 126
const MAX_TEXT_HOPS = 16
const TLD_SUFFIX = 0x2E67726D

const GRM_UNIT = 1000000000

const MIN_TONS_FOR_STORAGE = ton("0.05")
const MIN_TONS_FOR_COLLECTION = ton("0.1")
const MIN_BID_TON = ton("0.15")
const MIN_DIRECT_BID_TON = ton("0.07")
const MIN_FINALIZE_TON = ton("0.1")
const GAS_SETTLE = ton("0.05")
const GAS_NOTIFY = ton("0.01")
const GAS_FUNDING_NOTIFY = ton("0.02")

const DNS_NEXT_RESOLVER_PREFIX = 0xba93

const IMAGE_URL_PREFIX = "https://dns-cdn.gramcoin.org/dnsimage/"
const IMAGE_URL_SUFFIX = ".png"
const NAME_SUFFIX = ".grm"
const DOMAIN_DESCRIPTION = "A .grm blockchain domain. Grm DNS is a service that allows users to assign a human-readable name to crypto wallets, smart contracts, and websites."

const KEY_NAME = "name".sha256()
const KEY_DESCRIPTION = "description".sha256()
const KEY_IMAGE = "image".sha256()
const KEY_NEXT_RESOLVER = "dns_next_resolver".sha256()

const KEY_WALLET = "wallet".sha256()
const KEY_SITE = "site".sha256()
const KEY_STORAGE = "storage".sha256()

const DNS_SMC_ADDRESS_PREFIX = 0x9fd3
const DNS_ADNL_ADDRESS_PREFIX = 0xad01
const DNS_STORAGE_ADDRESS_PREFIX = 0x7473
