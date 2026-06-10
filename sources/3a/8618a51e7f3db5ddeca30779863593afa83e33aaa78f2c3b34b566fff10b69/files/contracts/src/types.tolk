// Shared types for the TON Coin Flip platform.
// See docs/specification.md for the full protocol description.

enum Errors {
    NotAdmin = 100
    NotCreator = 101
    GamePaused = 102
    InvalidStake = 103
    InsufficientValue = 104
    FeeTooHigh = 105
    SelfPlayNotAllowed = 106
    WrongState = 107
    JoinDeadlinePassed = 108
    EscrowUnderfunded = 109
    CommitmentMismatch = 110
    RevealDeadlinePassed = 111
    RevealDeadlineNotReached = 112
    InvalidLimits = 113
    InvalidMessage = 0xFFFF
}

// Game lifecycle states (specification §5)
const STATUS_CREATED = 0
const STATUS_JOINED = 1
const STATUS_SETTLED = 2
const STATUS_TIMED_OUT = 3
const STATUS_CANCELLED = 4

// Fee is measured in basis points of the pot; the cap is hardcoded (constitution III, IX)
const BPS_DENOMINATOR = 10000
const MAX_FEE_BPS = 1000 // 10%

// Gas reserves: the part of the attached value that is NOT counted as stake.
// Anything above stake + reserve is refunded (join) or swept to the winner (settle).
const CREATE_GAS_RESERVE = ton("0.1")
const JOIN_GAS_RESERVE = ton("0.05")
const MIN_REFUND = ton("0.01")

// ---------------------------------------------------------------------------
// Storage
// ---------------------------------------------------------------------------

struct FactoryStorage {
    admin: address
    treasury: address
    feeBps: uint16
    minStake: coins
    maxStake: coins
    joinTimeout: uint32
    revealTimeout: uint32
    paused: bool
    gamesCount: uint64
    gameCode: cell
}

fun FactoryStorage.load(): FactoryStorage {
    return FactoryStorage.fromCell(contract.getData());
}

fun FactoryStorage.save(self) {
    contract.setData(self.toCell());
}

// Immutable per-game parameters, snapshotted from the factory at creation time
// (constitution VIII: later admin changes never affect an existing game).
// Split into two cells: three addresses + commitment exceed the 1023-bit cell limit.
struct GameConfigExt {
    commitment: uint256
    treasury: address
}

struct GameConfig {
    gameId: uint64
    factory: address
    creator: address
    stake: coins
    aSideHeads: bool
    feeBps: uint16
    revealTimeout: uint32
    joinDeadline: uint32
    ext: Cell<GameConfigExt>
}

struct GameStorage {
    config: Cell<GameConfig>
    status: uint8
    opponent: address?
    seedB: uint256
    revealDeadline: uint32
}

fun GameStorage.load(): GameStorage {
    return GameStorage.fromCell(contract.getData());
}

fun GameStorage.save(self) {
    contract.setData(self.toCell());
}

// Flattened read-only view returned by the `gameData` get-method
struct GameData {
    gameId: uint64
    factory: address
    creator: address
    stake: coins
    commitment: uint256
    aSideHeads: bool
    feeBps: uint16
    treasury: address
    joinDeadline: uint32
    status: uint8
    opponent: address?
    seedB: uint256
    revealDeadline: uint32
}

// ---------------------------------------------------------------------------
// Incoming messages (specification §6)
// ---------------------------------------------------------------------------

// Factory
struct (0xC0F10001) CreateGame {
    stake: coins
    commitment: uint256
    aSideHeads: bool
}

struct (0xC0F10002) SetFee {
    feeBps: uint16
}

struct (0xC0F10003) SetLimits {
    minStake: coins
    maxStake: coins
    joinTimeout: uint32
    revealTimeout: uint32
}

struct (0xC0F10004) SetTreasury {
    treasury: address
}

struct (0xC0F10005) SetPaused {
    paused: bool
}

struct (0xC0F10006) SetGameCode {
    code: cell
}

// Game
struct (0xC0F20001) JoinGame {
    seedB: uint256
}

struct (0xC0F20002) Reveal {
    secretA: uint256
}

struct (0xC0F20003) ClaimTimeout {}

struct (0xC0F20004) CancelGame {}

// ---------------------------------------------------------------------------
// Events (external-out log messages, indexed by ExtOutLogBucket topic)
// ---------------------------------------------------------------------------

const TOPIC_GAME_CREATED = 1
const TOPIC_GAME_JOINED = 2
const TOPIC_GAME_SETTLED = 3
const TOPIC_GAME_TIMED_OUT = 4
const TOPIC_GAME_CANCELLED = 5

struct (0xC0FE0001) EvGameCreated {
    gameId: uint64
    game: address
    creator: address
    stake: coins
    joinDeadline: uint32
}

struct (0xC0FE0002) EvGameJoined {
    gameId: uint64
    opponent: address
    seedB: uint256
    revealDeadline: uint32
}

struct (0xC0FE0003) EvGameSettled {
    gameId: uint64
    coinIsHeads: bool
    winner: address
    payout: coins
    fee: coins
}

struct (0xC0FE0004) EvGameTimedOut {
    gameId: uint64
    winner: address
    payout: coins
    fee: coins
}

struct (0xC0FE0005) EvGameCancelled {
    gameId: uint64
    refund: coins
}

// ---------------------------------------------------------------------------
// Provably-fair helpers (shared by contracts, tests and the off-chain verifier)
// ---------------------------------------------------------------------------

// commitment = SHA256(secretA as a 32-byte big-endian value)
fun calcCommitment(secretA: uint256): uint256 {
    return beginCell().storeUint(secretA, 256).endCell().beginParse().bitsHash();
}

// coin = LSB(secretA XOR seedB); true = heads (орел), false = tails (решка)
fun calcCoinIsHeads(secretA: uint256, seedB: uint256): bool {
    return ((secretA ^ seedB) & 1) == 1;
}

// fee = floor(pot * feeBps / 10000); the rounding dust stays in the winner payout
fun calcFee(pot: coins, feeBps: int): coins {
    return pot * feeBps / BPS_DENOMINATOR;
}
