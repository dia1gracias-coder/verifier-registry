import "../vendor/jetton/messages"

// Launcher v2 message set. Opcodes shared with v1 keep the v1 semantics; layouts that changed
// (SettleAck, CurveGraduated) are only ever exchanged between v2 contracts. Bounce handlers read
// the first 256 bits of the bounced body: fields that a handler needs after a bounce come first.

// ---------------------------------------------------------------------------
// Wallet <-> Master
// ---------------------------------------------------------------------------

/// Wallet -> Master. Sent before any balance change. `action` tells the master what to do:
/// ACTION_SYNC: reply indices only (wallet then executes its pending transfer).
/// ACTION_CLAIM: reply indices (the wallet computes what it is owed and asks the vault itself).
/// ACTION_BURN: decrease supply by `burnAmount`; if `sellMinTon != null` forward a sell to the market.
struct (0x52570001) Settle {
    queryId: uint64
    owner: address
    action: uint8
    burnAmount: coins
    sellMinTon: coins?
}

/// Master -> Wallet. Current indices. `retry` is set when the first ack bounced: the wallet then
/// freezes conservatively (the lot in flight earns nothing for the retry window).
struct (0x52570002) SettleAck {
    queryId: uint64
    retry: bool
    vault: address?
    indices: map<uint8, uint128>
}

/// Token movement into a wallet. Sender is the master (mint / remint) or a sibling wallet (transfer).
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

/// Master -> Wallet. Same as RewardTransferStep, for coins bought from the Pool: a bounce of this
/// opcode tells the master to restore `poolReserve` and warn the Pool.
struct (0x52570005) PoolDeliver {
    queryId: uint64
    jettonAmount: coins
    sendExcessesTo: address
    forwardTonAmount: coins
    indices: map<uint8, uint128>
}

/// Owner -> Wallet. Clears a `pending` older than PENDING_TIMEOUT (see RewardWallet.tolk).
struct (0x52570006) CancelSettle {
    queryId: uint64
}

/// Master -> Wallet. A reward payout failed at the vault: `amount` of `rewardId` is claimable again.
struct (0x52570007) RestoreAccrued {
    queryId: uint64
    rewardId: uint8
    amount: coins
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

/// Curve -> Master. Mint `amount` to `to` (buy).
struct (0x52570011) MintReward {
    queryId: uint64
    to: address
    amount: coins
    forwardTonAmount: coins
    forwardPayload: cell?
}

/// Curve -> Master. Registers the Pool, credits it `poolSupply` coins and closes the curve.
struct (0x52570012) CurveGraduated {
    queryId: uint64
    pool: address
    poolSupply: coins
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

/// Master -> Curve / Pool. A holder burned `amount` to sell on the market.
struct (0x52570017) SellNotify {
    queryId: uint64
    owner: address
    amount: coins
    minTon: coins
}

/// Custom payload of an AskToBurn that means "sell on the market".
struct (0x52570018) SellIntent {
    minTon: coins
}

/// Anyone -> Master: "where is your market?". Used by the BuybackVault so that its market can only
/// ever be the Curve / Pool the master itself knows.
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
// Payouts (wallet -> vault, vault -> master)
// ---------------------------------------------------------------------------

/// Wallet -> Vault. Pay `amount` of `rewardId` to `owner`; the vault checks that the sender is the
/// wallet of `owner`. `rewardId` and `amount` come before `owner` so a bounce restores `accrued`.
struct (0x52570026) PayRewardReq {
    queryId: uint64
    rewardId: uint8
    amount: coins
    owner: address
}

/// Vault -> Master. The jetton transfer of a payout bounced: relay RestoreAccrued to the wallet.
struct (0x52570027) PayRewardFailed {
    queryId: uint64
    owner: address
    rewardId: uint8
    amount: coins
}

// ---------------------------------------------------------------------------
// Pool <-> Master (coins owned by the pool live in `master.poolReserve`)
// ---------------------------------------------------------------------------

/// Pool -> Master. Deliver `amount` coins from the pool reserve to `to` (a buy).
struct (0x52570030) PoolOut {
    queryId: uint64
    amount: coins
    to: address
    forwardTonAmount: coins
}

/// Curve / Pool -> Master. Give coins back to `to` after a refused sell (they were burned by the Settle).
struct (0x52570031) Remint {
    queryId: uint64
    to: address
    amount: coins
}

/// Master -> Pool. The delivery of `queryId` bounced: `amount` coins are back in the pool reserve.
struct (0x52570032) PoolOutFailed {
    queryId: uint64
    amount: coins
}

/// Pool -> Master. A sell was accepted: `amount` coins now belong to the pool.
struct (0x52570033) PoolCredit {
    queryId: uint64
    amount: coins
}

/// Factory -> Master (admin premint at launch): mint `amount` to `to` outside the curve.
struct (0x52570034) PremintCoins {
    queryId: uint64
    to: address
    amount: coins
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
