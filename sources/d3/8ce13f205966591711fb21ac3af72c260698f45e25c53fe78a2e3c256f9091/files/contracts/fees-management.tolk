// Source: https://github.com/ton-blockchain/acton-contracts/blob/master/nft-v1.1/contracts/fees-management.tolk
// Extra: PERMIT_DOMAIN_MINT for the minter, not part of TEP-62.

const MIN_TONS_FOR_STORAGE = ton("0.05")

/// Maximum NFTs per batch deploy — bounded by the 255-action TVM limit.
const BATCH_SIZE_LIMIT = 250

const PERMIT_DOMAIN_MINT: uint32 = 0x4D494E54
