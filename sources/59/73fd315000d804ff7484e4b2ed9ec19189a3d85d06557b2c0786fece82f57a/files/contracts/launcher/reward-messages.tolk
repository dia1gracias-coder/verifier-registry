import "../vendor/jetton/messages"

// ---------------------------------------------------------------------------
// Wallet <-> Master
// ---------------------------------------------------------------------------

/// Wallet -> Master. Sent before any balance change. `action` tells the master what to do:
/// ACTION_SYNC: reply indices only (wallet then executes its pending transfer).
/// ACTION_CLAIM: pay accrued + earned for every reward, then reply indices.
/// ACTION_BURN: decrease supply by `burnAmount`; if `sellMinTon != null` forward a sell to the Curve.
struct (0x52570001) Settle {
    queryId: uint64
    owner: address
    balance: coins
    action: uint8
    burnAmount: coins
    sellMinTon: coins?
    stamps: map<uint8, uint128>
    accrued: map<uint8, coins>
}

/// Master -> Wallet. Current indices; `claimed` is true when accrued/earned were paid out.
struct (0x52570002) SettleAck {
    queryId: uint64
    claimed: bool
    indices: map<uint8, uint128>
}

/// Token movement into a wallet. Sender is the master (mint) or a sibling wallet (transfer).
/// `indices` lets the recipient freeze its position before crediting the tokens.
struct (0x52570003) RewardTransferStep {
    queryId: uint64
    jettonAmount: coins
    transferInitiator: address?
    sendExcessesTo: address?
    forwardTonAmount: coins
    indices: map<uint8, uint128>
    @abi.clientType(PayloadInline | PayloadInRef)
    forwardPayload: ForwardPayloadRemainder
}

/// Owner -> Wallet. Claim every reward earned so far.
struct (0x52570004) ClaimRewards {
    queryId: uint64
}

// ---------------------------------------------------------------------------
// Master administration / protocol wiring
// ---------------------------------------------------------------------------

/// Factory -> Master, once.
struct (0x52570010) WireMaster {
    queryId: uint64
    curve: address
    vault: address
}

/// Curve -> Master. Mint `amount` to `to` (buy or graduation liquidity).
struct (0x52570011) MintReward {
    queryId: uint64
    to: address
    amount: coins
    forwardTonAmount: coins
    forwardPayload: cell?
}

/// Curve -> Master. Registers the Pool (excluded from rewards) and closes sells.
struct (0x52570012) CurveGraduated {
    queryId: uint64
    pool: address
}

/// Pool -> Master. Current coin reserve of the pool (excluded from reward supply).
struct (0x52570013) ExcludedUpdate {
    queryId: uint64
    balance: coins
}

/// Vault -> Master. Reward jettons arrived: index[rewardId] += amount * SCALE / circulating.
struct (0x52570014) IndexBump {
    queryId: uint64
    rewardId: uint8
    amount: coins
}

/// Master -> Vault. Nobody could earn this bump (circulating == 0): keep it for later.
struct (0x52570015) IndexBumpRefused {
    queryId: uint64
    rewardId: uint8
    amount: coins
}

/// Master -> Vault. Pay `amount` of reward `rewardId` to `owner`.
struct (0x52570016) PayReward {
    queryId: uint64
    owner: address
    rewardId: uint8
    amount: coins
}

/// Master -> Curve. A holder burned `amount` to sell on the curve.
struct (0x52570017) SellNotify {
    queryId: uint64
    owner: address
    amount: coins
    minTon: coins
}

/// Custom payload of an AskToBurn that means "sell on the curve".
struct (0x52570018) SellIntent {
    minTon: coins
}

/// Anyone -> Master: "where is your market?". Used by the BuybackVault so that its market can only
/// ever be the Curve / Pool the master itself knows (security review F-03).
struct (0x52570019) QueryMarket {
    queryId: uint64
}

/// Master -> asker. `pool` is set after graduation; `curve` is the bonding curve while `curveOpen`.
struct (0x5257001a) MarketAnswer {
    queryId: uint64
    curveOpen: bool
    curve: address?
    pool: address?
}

// ---------------------------------------------------------------------------
// Vault operations
// ---------------------------------------------------------------------------

/// Keeper -> Vault. Swap `spend` TON for reward `rewardId` through a whitelisted DeDust pool.
/// The swap body is built by the vault (receiver = vault, limit = `minOut`).
struct (0x52570020) ConvertReward {
    queryId: uint64
    rewardId: uint8
    pool: address
    spend: coins
    minOut: coins
}

struct (0x52570021) CancelVaultPending {
    queryId: uint64
}

/// Admin -> Vault. The vault discovers its own wallet for that jetton (TEP-89).
struct (0x52570022) AddReward {
    queryId: uint64
    rewardId: uint8
    rewardMaster: address
}

/// Admin -> Vault. Whitelist / unlist a DeDust pool.
struct (0x52570023) SetVaultDex {
    queryId: uint64
    pool: address
    allowed: bool
}

struct (0x52570024) SetVaultRoles {
    queryId: uint64
    admin: address
    keeper: address
    master: address
}

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

const EVENT_TOPIC_INDEX_BUMPED = 0x5257E001
const EVENT_TOPIC_REWARD_PAID = 0x5257E002
const EVENT_TOPIC_REWARD_CONVERTED = 0x5257E003
const EVENT_TOPIC_REWARD_UNALLOCATED = 0x5257E004

struct IndexBumpedEvent {
    rewardId: uint8
    amount: coins
    circulating: coins
    index: uint128
}

struct RewardPaidEvent {
    owner: address
    rewardId: uint8
    amount: coins
}

struct RewardConvertedEvent {
    rewardId: uint8
    spendTon: coins
    received: coins
    minOut: coins
}
