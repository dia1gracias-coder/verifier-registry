// Storage layouts, message bodies and address helpers for the per-node stake
// contract (`StakeVault`) and its non-transferable stake-receipt jetton
// (`StakeReceiptWallet`). See BLOCKCHAIN_ECONOMICS §8 (staking/slashing/unbonding)
// and §8.5 (transfer-locked TEP-74 stake-receipt jetton).

import "common"

// ---------------------------------------------------------------------------
// Custom opcodes (distinct 32-bit tags)
// ---------------------------------------------------------------------------

const OP_TOP_UP = 0x534b_4b00
const OP_STAKE_DEPOSIT = 0x534b_4b01
const OP_STAKE_UNBOND = 0x534b_4b02
const OP_STAKE_WITHDRAW = 0x534b_4b03
const OP_STAKE_KEEPER = 0x534b_4b04
const OP_STAKE_SLASH = 0x534b_4b05
const OP_RECEIPT_BURN = 0x534b_4b06
const OP_RECEIPT_MINT = 0x534b_4b07

// ---------------------------------------------------------------------------
// Stake-receipt jetton wallet (per-holder, TEP-74 shaped, transfer-LOCKED)
// ---------------------------------------------------------------------------

struct ReceiptWalletStorage {
    status: uint4   // bit 0 = transfers locked (always set: the receipt is non-transferable)
    balance: coins  // receipt units held (1:1 with bonded TON)
    owner: address  // node operator
    master: address // the StakeVault that minted this receipt
}

fun ReceiptWalletStorage.load(): ReceiptWalletStorage {
    return ReceiptWalletStorage.fromCell(contract.getData());
}

fun ReceiptWalletStorage.save(self) {
    contract.setData(self.toCell());
}

// Mint — master-only. The receipt is non-transferable, so it is never minted via
// a sibling internal-transfer; the master credits the wallet directly. (We keep
// the standard TEP-74 transfer opcode below purely so a real transfer attempt
// hits the lock.)
struct (0x534b_4b07) ReceiptMint {
    queryId: uint64
    amount: coins
}

// TEP-74 outgoing transfer — always rejected for the stake receipt (anti-exit).
struct (0x0f8a7ea5) JettonTransfer {
    queryId: uint64
    amount: coins
    destination: address
    responseDestination: address?
    customPayload: cell?
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

// Master-driven burn (on withdraw or slash). Only the StakeVault may send it.
struct (0x534b_4b06) ReceiptBurn {
    queryId: uint64
    amount: coins
}

struct (0x534b_4b00) ReceiptTopUp {
    queryId: uint64
}

// Getter shape for `get_wallet_data` (TEP-74).
struct ReceiptWalletData {
    balance: coins
    owner: address
    minter: address
    code: cell
}

// ---------------------------------------------------------------------------
// Stake vault (per node) — also the receipt jetton master
// ---------------------------------------------------------------------------

// Slash split + payout targets, kept in a child cell (bit budget).
struct SlashConfig {
    treasury: address
    redundancyPool: address
    splitChallengerBps: uint16
    splitRedundancyBps: uint16
    splitBurnBps: uint16
    splitTreasuryBps: uint16
}

struct VaultConfig {
    minStake: coins         // eligibility threshold (0 = free tier, public only)
    unbondingPeriod: uint32 // cooldown secs; MUST be >= challengeWindow (validated off-chain)
    challengeWindow: uint32 // optimistic-settlement window secs
    keeperGrace: uint32     // extra secs after cooldown before a keeper may act
    keeperBountyBps: uint16 // keeper reward (bps of the withdrawn amount)
    slasher: address        // authorized slasher (the dispute contract)
    receiptWalletCode: cell // code of StakeReceiptWallet (for deterministic mint)
    slash: Cell<SlashConfig>
}

struct VaultStorage {
    owner: address         // node operator wallet
    staked: coins          // currently bonded
    unbondingAmount: coins // in cooldown (still slashable)
    unbondingAt: uint32    // unix ts the cooldown started (0 = none)
    totalSupply: coins     // receipts outstanding (== staked + unbondingAmount)
    bindingHash: uint256   // wallet<->node identity binding hash (§3.2)
    config: Cell<VaultConfig>
}

fun VaultStorage.load(): VaultStorage {
    return VaultStorage.fromCell(contract.getData());
}

fun VaultStorage.save(self) {
    contract.setData(self.toCell());
}

// Vault messages
struct (0x534b_4b01) StakeDeposit {
    queryId: uint64
    amount: coins // how much of the attached value to bond + mint as receipt
}

struct (0x534b_4b02) StakeRequestUnbond {
    queryId: uint64
    amount: coins
}

struct (0x534b_4b03) StakeWithdraw {
    queryId: uint64
}

struct (0x534b_4b04) StakeKeeperWithdraw {
    queryId: uint64
}

struct (0x534b_4b05) StakeSlash {
    queryId: uint64
    amount: coins
    reason: uint8       // SlashReason discriminant (mirrors §8.3)
    challenger: address // receives the challenger bounty share
}

// Getter shapes
struct VaultState {
    staked: coins
    unbondingAmount: coins
    unbondingAt: uint32
    totalSupply: coins
    eligible: bool // staked >= minStake AND no unbonding in progress
}

// ---------------------------------------------------------------------------
// Deterministic receipt-wallet address (mirrors the TEP-74 jetton pattern)
// ---------------------------------------------------------------------------

fun calcDeployedReceiptWallet(
    owner: address,
    master: address,
    walletCode: cell,
): AutoDeployAddress {
    val empty: ReceiptWalletStorage = {
        status: RECEIPT_STATUS_LOCKED,
        balance: 0,
        owner: owner,
        master: master,
    };
    return { workchain: BASECHAIN, stateInit: { code: walletCode, data: empty.toCell() } };
}

fun calcReceiptWalletAddress(owner: address, master: address, walletCode: cell): address {
    return calcDeployedReceiptWallet(owner, master, walletCode).calculateAddress();
}
