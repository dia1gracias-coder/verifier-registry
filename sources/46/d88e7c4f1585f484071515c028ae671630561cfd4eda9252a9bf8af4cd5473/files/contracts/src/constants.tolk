// TEP-62 collections use zero-based item indexes. Human-facing edition and
// metadata numbers remain one-based through serialContent(index).
const FIRST_NFT_INDEX = 0
const MAX_COLLECTION_SUPPLY = 10_000
const DEFAULT_MAX_SUPPLY = 10_000
/// Client-approved production model: all 1,500 preminted NFTs go to one
/// dedicated immutable recipient wallet. The remaining 8,500 serials are
/// shared by whitelist claims and paid minting.
const DEFAULT_GIVEAWAY_SUPPLY = 1_500
const DEFAULT_TREASURY_NFT_SUPPLY = 0
const DEFAULT_WHITELIST_MAX_CLAIMS = 1_000
const MAX_MINT_BATCH = 20
const MAX_MERKLE_PROOF_DEPTH = 64
const MAX_QUOTE_LIFETIME = 300
const QUOTE_VERSION = 1
const PAYMENT_ASSET_NATIVE = 0
const NATIVE_ASSET_ID = 0
