// Per-node stake contract (BLOCKCHAIN_ECONOMICS §8). Non-custodial: no human key
// controls the funds — deposit, unbond cooldown, slashing and keeper withdrawal
// are all governed by contract code. The vault is ALSO the master of this node's
// transfer-locked stake-receipt jetton (§8.5): it mints 1:1 on deposit and burns
// on withdrawal/slash.
//
// This contract is only ever touched by PAID work. Free jobs (§8.2) bypass it
// entirely via the off-chain NoopSettlement path.

import "common"
import "stake_types"

contract StakeVault {
    storage: VaultStorage
    incomingMessages: AllowedMessageToVault
}

type AllowedMessageToVault =
    | StakeDeposit
    | StakeRequestUnbond
    | StakeWithdraw
    | StakeKeeperWithdraw
    | StakeSlash
    | ReceiptTopUp

fun onBouncedMessage(_in: InMessageBounced) {}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessageToVault.fromSlice(in.body);

    match (msg) {
        // Deposit: bond `amount` (held non-custodially in this contract) and mint
        // an equal amount of the transfer-locked stake-receipt jetton to the owner.
        StakeDeposit => {
            var storage = lazy VaultStorage.load();
            assert (in.senderAddress == storage.owner) throw ERROR_NOT_OWNER;
            assert (in.valueCoins >= msg.amount + MIN_TONS_FOR_STORAGE) throw ERROR_NOT_ENOUGH_GAS;

            storage.staked += msg.amount;
            storage.totalSupply += msg.amount;
            storage.save();

            val cfg = storage.config.load();
            mintReceipt(
                storage.owner,
                contract.getAddress(),
                cfg.receiptWalletCode,
                msg.amount,
                msg.queryId,
            );
        }

        // Begin unbonding: move `amount` from the bonded bucket into the cooldown
        // bucket. The cooldown stake stays SLASHABLE (§8.4) and the receipt stays
        // locked until withdrawal completes.
        StakeRequestUnbond => {
            var storage = lazy VaultStorage.load();
            assert (in.senderAddress == storage.owner) throw ERROR_NOT_OWNER;
            assert (storage.unbondingAt == 0) throw ERROR_UNBOND_IN_PROGRESS;
            assert (msg.amount > 0 && msg.amount <= storage.staked) throw ERROR_NOTHING_TO_UNBOND;

            storage.staked -= msg.amount;
            storage.unbondingAmount = msg.amount;
            storage.unbondingAt = blockchain.now() as uint32;
            storage.save();
        }

        // Owner withdrawal after the cooldown elapses: release the cooled stake and
        // burn the matching receipts.
        StakeWithdraw => {
            var storage = lazy VaultStorage.load();
            assert (in.senderAddress == storage.owner) throw ERROR_NOT_OWNER;
            assert (storage.unbondingAmount > 0) throw ERROR_NO_UNBONDING;
            val cfg = storage.config.load();
            val readyAt = storage.unbondingAt + cfg.unbondingPeriod;
            assert (blockchain.now() >= readyAt) throw ERROR_COOLDOWN_NOT_ELAPSED;

            val amount = storage.unbondingAmount;
            storage.unbondingAmount = 0;
            storage.unbondingAt = 0;
            storage.totalSupply -= amount;
            storage.save();

            burnReceipt(
                storage.owner,
                contract.getAddress(),
                cfg.receiptWalletCode,
                amount,
                msg.queryId,
            );
            payout(storage.owner, amount);
        }

        // Keeper liveness (TON idiom, §8.4): once cooldown + grace elapses, ANYONE
        // can finalize an unresponsive owner's withdrawal and earn a small bounty.
        StakeKeeperWithdraw => {
            var storage = lazy VaultStorage.load();
            assert (storage.unbondingAmount > 0) throw ERROR_NO_UNBONDING;
            val cfg = storage.config.load();
            val keeperAt = storage.unbondingAt + cfg.unbondingPeriod + cfg.keeperGrace;
            assert (blockchain.now() >= keeperAt) throw ERROR_KEEPER_TOO_EARLY;

            val amount = storage.unbondingAmount;
            storage.unbondingAmount = 0;
            storage.unbondingAt = 0;
            storage.totalSupply -= amount;
            storage.save();

            val bounty = mulDivFloor(amount, cfg.keeperBountyBps, BPS_DENOM);
            burnReceipt(
                storage.owner,
                contract.getAddress(),
                cfg.receiptWalletCode,
                amount,
                msg.queryId,
            );
            payout(storage.owner, amount - bounty);
            if (bounty > 0) {
                payout(in.senderAddress, bounty);
            }
        }

        // Graduated slashing (§8.3) by the authorized slasher (dispute contract).
        // Takes from the bonded bucket first, then the still-slashable cooldown
        // bucket, splits the slashed funds per config, and burns the receipts.
        StakeSlash => {
            var storage = lazy VaultStorage.load();
            val cfg = storage.config.load();
            assert (in.senderAddress == cfg.slasher) throw ERROR_NOT_SLASHER;
            val slashable = storage.staked + storage.unbondingAmount;
            assert (msg.amount > 0 && msg.amount <= slashable) throw ERROR_SLASH_EXCEEDS_STAKE;

            val fromStaked = min(msg.amount, storage.staked);
            storage.staked -= fromStaked;
            storage.unbondingAmount -= (msg.amount - fromStaked);
            storage.totalSupply -= msg.amount;
            storage.save();

            burnReceipt(
                storage.owner,
                contract.getAddress(),
                cfg.receiptWalletCode,
                msg.amount,
                msg.queryId,
            );
            applySlashSplit(cfg.slash.load(), msg.amount, msg.challenger);
        }

        ReceiptTopUp => {
            // accept TON top-ups for storage rent
        }

        else => {
            assert (in.body.isEmpty()) throw ERROR_INVALID_OP;
        }
    }
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

fun mintReceipt(owner: address, master: address, walletCode: cell, amount: coins, queryId: int) {
    val dest = calcDeployedReceiptWallet(owner, master, walletCode);
    val m = createMessage({
        bounce: BounceMode.NoBounce,
        dest: dest,
        value: MIN_TONS_FOR_STORAGE,
        body: ReceiptMint {
            queryId: queryId,
            amount: amount,
        },
    });
    m.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun burnReceipt(owner: address, master: address, walletCode: cell, amount: coins, queryId: int) {
    val dest = calcReceiptWalletAddress(owner, master, walletCode);
    val m = createMessage({
        bounce: BounceMode.NoBounce,
        dest: dest,
        value: ton("0.02"),
        body: ReceiptBurn {
            queryId: queryId,
            amount: amount,
        },
    });
    m.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_IGNORE_ERRORS);
}

fun payout(to: address, amount: coins) {
    val m = createMessage({
        bounce: BounceMode.NoBounce,
        dest: to,
        value: amount,
    });
    m.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_IGNORE_ERRORS);
}

// Split slashed funds: challenger bounty / redundancy-reward pool / burn /
// treasury (§8.3). The burn share is simply left locked in this contract (no key
// can release it), which removes it from circulation.
fun applySlashSplit(sc: SlashConfig, amount: coins, challenger: address) {
    val sum = sc.splitChallengerBps + sc.splitRedundancyBps + sc.splitBurnBps + sc.splitTreasuryBps;
    assert (sum == BPS_DENOM) throw ERROR_INVALID_SPLIT;

    val challengerAmt = mulDivFloor(amount, sc.splitChallengerBps, BPS_DENOM);
    val redundancyAmt = mulDivFloor(amount, sc.splitRedundancyBps, BPS_DENOM);
    val treasuryAmt = mulDivFloor(amount, sc.splitTreasuryBps, BPS_DENOM);
    // burn share = remainder, left locked in the vault forever.

    if (challengerAmt > 0) {
        payout(challenger, challengerAmt);
    }
    if (redundancyAmt > 0) {
        payout(sc.redundancyPool, redundancyAmt);
    }
    if (treasuryAmt > 0) {
        payout(sc.treasury, treasuryAmt);
    }
}

// ---------------------------------------------------------------------------
// Getters
// ---------------------------------------------------------------------------

get fun get_vault_state(): VaultState {
    val storage = lazy VaultStorage.load();
    val cfg = storage.config.load();
    val eligible = storage.staked >= cfg.minStake && storage.unbondingAt == 0;
    return {
        staked: storage.staked,
        unbondingAmount: storage.unbondingAmount,
        unbondingAt: storage.unbondingAt,
        totalSupply: storage.totalSupply,
        eligible: eligible,
    };
}

get fun get_owner(): address {
    val storage = lazy VaultStorage.load();
    return storage.owner;
}

get fun get_binding_hash(): int {
    val storage = lazy VaultStorage.load();
    return storage.bindingHash;
}

get fun get_receipt_wallet_address(owner: address): address {
    val storage = lazy VaultStorage.load();
    val cfg = storage.config.load();
    return calcReceiptWalletAddress(owner, contract.getAddress(), cfg.receiptWalletCode);
}

get fun is_eligible(): bool {
    val storage = lazy VaultStorage.load();
    val cfg = storage.config.load();
    return storage.staked >= cfg.minStake && storage.unbondingAt == 0;
}
