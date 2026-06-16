// Minimal Toncoin kept on a contract balance to pay storage rent.
const MIN_TONS_FOR_STORAGE = ton("0.05")

// Toncoin attached to each NFT item deployment (storage + deploy fees).
// The rest of the mint payment stays on the collection balance as revenue.
const NFT_DEPLOY_AMOUNT = ton("0.06")
