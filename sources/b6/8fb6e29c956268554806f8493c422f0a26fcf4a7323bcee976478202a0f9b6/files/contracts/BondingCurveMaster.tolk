import "../gen/BondingCurve.code"
import "../gen/JettonMinter.code"
import "bonding-config"
import "bonding-messages"
import "bonding-storage"
import "errors"
import "messages"
import "sharding"
import "storage"

contract BondingCurveMaster {
    author: "pumpfun-ton"
    version: "0.2.0"
    description: "Factory for pump.fun-style bonding-curve launchpads on TON"
    storage: MasterStorage
    incomingMessages: AllowedMessageToMaster
}

type AllowedMessageToMaster =
    | CreateLaunch
    | ChangeMasterAdmin
    | ClaimMasterAdmin
    | ChangeTreasury
    | WithdrawProtocolFees
    | DepositProtocolFees
    | ReinitializeCurve
    | TopUpTons

// Outgoing messages from master that may bounce. Used by onBouncedMessage so the master can
// restore feesBalance precisely when a TreasuryPayout fails to deliver.
type BounceableMasterOps = TreasuryPayout

// Storage reserve so the master never drops below its rent footprint when fees are withdrawn.
// Empirical floor for a contract of this storage shape; bumped if storage grows in v2.
const MASTER_STORAGE_RESERVE: coins = ton("0.05")

fun assertSenderIsAdmin(senderAddress: address, adminAddress: address) {
    assert (senderAddress == adminAddress) throw Errors.NotOwner;
}

fun calcDeployedBondingCurve(
    master: address,
    creator: address,
    salt: uint64,
): AutoDeployAddress {
    val config: LaunchConfig = {
        master,
        creator,
        salt,
        curveSupply: CURVE_SUPPLY,
        dexReserveSupply: DEX_RESERVE_SUPPLY,
        graduationThreshold: GRADUATION_THRESHOLD_TON,
    };
    val initStorage: BondingCurveStorage = {
        state: CURVE_STATE_INITIALIZING,
        jettonMinter: null,
        virtualTonReserve: VIRTUAL_TON_RESERVE_INIT,
        realTonReserve: 0,
        curveJettonBalance: 0,
        feeAccrued: 0,
        config: config.toCell(),
    };
    return {
        workchain: MY_WORKCHAIN,
        stateInit: { code: bondingCurveCompiledCode(), data: initStorage.toCell() },
    };
}

fun calcDeployedJettonMinter(
    admin: address,
    metadata: cell,
): AutoDeployAddress {
    val initStorage: MinterStorage = {
        totalSupply: 0,
        adminAddress: admin,
        nextAdminAddress: null,
        metadata,
    };
    return {
        workchain: MY_WORKCHAIN,
        stateInit: { code: jettonMinterCompiledCode(), data: initStorage.toCell() },
    };
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessageToMaster.fromSlice(in.body);

    match (msg) {
        CreateLaunch => {
            // Minimum value: covers CREATE_LAUNCH_FEE + minter deploy + curve init mint chain.
            assert (in.valueCoins > MIN_CREATE_LAUNCH_VALUE) throw Errors.NotEnoughGas;

            var storage = lazy MasterStorage.load();

            val curveAuto = calcDeployedBondingCurve(
                contract.getAddress(),
                in.senderAddress,
                msg.salt,
            );
            val curveAddr = curveAuto.calculateAddress();
            val minterAuto = calcDeployedJettonMinter(curveAddr, msg.metadata);
            val minterAddr = minterAuto.calculateAddress();

            // Minter deploy needs only its storage init (~0.005) + acceptance gas (~0.002).
            // 0.03 TON gives ~5x margin and covers any forward-fee spike at deploy.
            val minterDeployValue = ton("0.03");
            val deployMinterMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: minterAuto,
                value: minterDeployValue,
                body: TopUpTons {},
            });
            deployMinterMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);

            // Curve gets (in.valueCoins - minter deploy - CREATE_LAUNCH_FEE). Explicit value
            // instead of CARRY_ALL_REMAINING so we keep CREATE_LAUNCH_FEE on the master account.
            val curveDeployValue = in.valueCoins - minterDeployValue - CREATE_LAUNCH_FEE;
            val initBody: InitializeCurve = { queryId: msg.queryId, jettonMinter: minterAddr };
            val deployCurveMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: curveAuto,
                value: curveDeployValue,
                body: initBody,
            });
            deployCurveMsg.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);

            // Credit the launch fee + bump the launch counter atomically. The fee stays on
            // the master's TON balance until WithdrawProtocolFees flushes it to the treasury.
            storage.totalLaunches += 1;
            storage.feesBalance += CREATE_LAUNCH_FEE;
            storage.save();

            // Emit LaunchCreatedEvent (TVM external_out, indexer-friendly).
            val launchEventMsg = createExternalLogMessage({
                dest: ExtOutLogBucket { topic: TOPIC_LAUNCH_CREATED },
                body: LaunchCreatedEvent {
                    creator: in.senderAddress,
                    salt: msg.salt,
                    curveAddress: curveAddr,
                    minterAddress: minterAddr,
                },
            });
            launchEventMsg.send(SEND_MODE_REGULAR);
        }

        ChangeMasterAdmin => {
            var storage = lazy MasterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.admin);
            storage.nextAdmin = msg.newAdmin;
            storage.save();
        }

        ClaimMasterAdmin => {
            var storage = lazy MasterStorage.load();
            assert (storage.nextAdmin != null) throw Errors.NotOwner;
            assert (in.senderAddress == storage.nextAdmin!) throw Errors.NotOwner;
            storage.admin = storage.nextAdmin!;
            storage.nextAdmin = null;
            storage.save();
        }

        ChangeTreasury => {
            var storage = lazy MasterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.admin);
            storage.treasury = msg.newTreasury;
            storage.save();
        }

        WithdrawProtocolFees => {
            var storage = lazy MasterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.admin);
            assert (msg.amount > 0) throw Errors.InvalidMessage;
            assert (storage.feesBalance >= msg.amount) throw Errors.BalanceError;

            storage.feesBalance -= msg.amount;
            storage.save();

            // Use TreasuryPayout (not TopUpTons) so the bounce body carries `amount`. Together
            // with Only256BitsOfBody this lets onBouncedMessage restore feesBalance precisely
            // if the treasury contract rejects the payout.
            val payoutMsg = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: storage.treasury,
                value: msg.amount,
                body: TreasuryPayout {
                    queryId: msg.queryId,
                    amount: msg.amount,
                },
            });
            payoutMsg.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
        }

        DepositProtocolFees => {
            // Authenticate sender by recomputing the deterministic launch address.
            // This is the ONLY way to credit feesBalance — anonymous deposits become donations
            // that sit in the contract balance untracked (admin can reclaim via direct top-up math).
            val expectedCurve = calcDeployedBondingCurve(
                contract.getAddress(),
                msg.creator,
                msg.salt,
            ).calculateAddress();
            assert (in.senderAddress == expectedCurve) throw Errors.NotValidWallet;

            // Credit the exact fee amount the curve flushed (carried in msg.amount), not
            // in.valueCoins which is post forward-fee. Assert the message actually carries enough
            // TON to cover the claim, so a malicious/buggy curve cannot inflate feesBalance.
            assert (in.valueCoins >= msg.amount) throw Errors.BalanceError;

            var storage = lazy MasterStorage.load();
            storage.feesBalance += msg.amount;
            storage.save();
        }

        ReinitializeCurve => {
            // Admin-only recovery for a curve whose init mint bounced (state == INITIALIZING and
            // jettonMinter == null). Recomputes the deterministic curve/minter addresses from
            // (creator, salt, metadata) and re-sends InitializeCurve. The curve's handler asserts
            // the state preconditions, so this is a safe no-op against an already-traded curve.
            val storage = lazy MasterStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.admin);
            assert (in.valueCoins > ton("0.5")) throw Errors.NotEnoughGas;

            val curveAuto = calcDeployedBondingCurve(
                contract.getAddress(),
                msg.creator,
                msg.salt,
            );
            val curveAddr = curveAuto.calculateAddress();
            val minterAuto = calcDeployedJettonMinter(curveAddr, msg.metadata);
            val minterAddr = minterAuto.calculateAddress();

            val initBody: InitializeCurve = { queryId: msg.queryId, jettonMinter: minterAddr };
            val reinitMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: curveAddr,
                value: 0,
                body: initBody,
            });
            reinitMsg.send(
                SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_BOUNCE_ON_ACTION_FAIL,
            );
        }

        TopUpTons => {
            // just accept tons
        }

        else => {
            // SILENT ACCEPT (do not throw). Why we don't throw 0xFFFF on unknown opcodes:
            //   - DeDust CPMM v2 pools refund excess TON to `excessesTo` (= our master) at
            //     the end of a graduation deposit. The refund opcode/format is internal to
            //     DeDust (not in our message union). A `throw` would bounce the refund back
            //     to the pool where it's absorbed and lost.
            //   - Other legitimate integrations may also send bare TON with custom opcodes.
            //   - The cost of accepting unknown messages is zero (state never mutates here);
            //     the cost of rejecting them is real (lost TON refunds at scale).
            // Trade-off favors silent accept. State-changing handlers above are individually
            // sender-authenticated, so accepting unknown ops here cannot grant unauthorized
            // privilege — only deposits TON to our balance, which is fine.
            return;
        }
    }
}

fun onBouncedMessage(in: InMessageBounced) {
    // CreateLaunch's sub-deploys are NoBounce; admin payouts use BOUNCE_ON_ACTION_FAIL.
    // The only path that bounces here is a failed WithdrawProtocolFees send (rare,
    // e.g. treasury contract rejects). Use TreasuryPayout's `amount` to restore feesBalance
    // precisely. ReinitializeCurve's outgoing InitializeCurve is NoBounce so it cannot land here.
    in.bouncedBody.skipBouncedPrefix();
    val parsed = lazy BounceableMasterOps.fromSlice(in.bouncedBody);
    match (parsed) {
        TreasuryPayout => {
            var storage = lazy MasterStorage.load();
            storage.feesBalance += parsed.amount;
            storage.save();
        }
        else => {
            // Unknown bounce: ignore to avoid throwing (bounces don't bounce).
        }
    }
}

get fun get_master_data(): MasterDataReply {
    val storage = lazy MasterStorage.load();
    return {
        admin: storage.admin,
        nextAdmin: storage.nextAdmin,
        treasury: storage.treasury,
        totalLaunches: storage.totalLaunches,
        feesBalance: storage.feesBalance,
    };
}

get fun get_launch_address(creator: address, salt: uint64): address {
    return calcDeployedBondingCurve(contract.getAddress(), creator, salt).calculateAddress();
}

get fun get_storage_reserve(): coins {
    return MASTER_STORAGE_RESERVE;
}

// Returns the protocol version as packed BCD: 0xMMmmpp (major.minor.patch).
// Indexers, frontends, and other contracts use this to detect deployed version.
// Bump on ANY breaking change (storage layout, opcode, math). v3.0.0 = creator fee routing.
get fun get_version(): int {
    return 0x030000;
}
