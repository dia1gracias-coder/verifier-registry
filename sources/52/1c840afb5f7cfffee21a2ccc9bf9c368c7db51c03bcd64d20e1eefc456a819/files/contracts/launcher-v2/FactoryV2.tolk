import "../common/errors"
import "../vendor/jetton/messages"
import "factory-messages"
import "factory-types"
import "fee-splitter-types"
import "launcher-messages"
import "launcher-types"
import "reward-messages"
import "reward-types"
import "vault-types"

contract FactoryV2 {
    author: "GRAMDESKS"
    version: "2.0.0"
    description: "Launchpad factory: deploys RewardMaster, RewardVault, FeeSplitter and Curve for a new coin in one transaction, wires them, opens the curve and performs the creator's first buy. Codes and roles change through a 48 h timelock; an admin premint migrates an existing coin."
    storage: FactoryStorage
    incomingMessages: AllowedMessageToFactory
}

type AllowedMessageToFactory =
    | CreateLaunch
    | SetFactoryPaused
    | SetFactoryConfig
    | ProposeFactoryChange
    | ApplyFactoryChange
    | TopUpTons
    | ReturnExcessesBack

/// Gas budget of a launch on top of launchFee + firstBuyTon (deploys, wiring, discovery, first buy gas).
const LAUNCH_GAS = ton("1")
const MASTER_DEPLOY_VALUE = ton("0.15")
const VAULT_DEPLOY_VALUE = ton("0.1")
const VAULT_DISCOVERY_PER_REWARD = ton("0.04")
const SPLITTER_DEPLOY_VALUE = ton("0.1")
const CURVE_DEPLOY_VALUE = ton("0.15")
const WIRE_VALUE = ton("0.05")
const OPEN_VALUE = ton("0.05")
/// Gas the Curve keeps from a Buy (must match CurveV2.BUY_GAS).
const CURVE_BUY_GAS = ton("0.15")
/// Value attached to each PremintCoins (master compute + wallet deploy).
const PREMINT_VALUE = ton("0.05")

fun emitFactoryEvent<T>(topic: int, body: T) {
    val ev = createExternalLogMessage({
        dest: ExtOutLogBucket { topic: topic as uint248 },
        body,
    });
    ev.send(SEND_MODE_REGULAR);
}

/// TON (rounded up) a fresh curve collects for `coinOut` coins.
fun CurveDefaults.tonInFor(self, coinOut: coins): coins {
    val num = self.virtualTon0 * coinOut;
    val den = self.virtualToken0 - coinOut;
    return ((num + den - 1) / den) as coins;
}

/// Bounds every launch must respect (docs/10 §7).
fun FactoryConfig.assertValid(self) {
    assert (self.splits.isValid(self.minProtocolBps)) throw Errors.InvalidSplits;
    val d = self.curve.load();
    assert (
        d.feeBps <= 1000 && d.poolLpFeeBps + d.poolProtocolFeeBps <= 1000
    ) throw Errors.InvalidParams;
    assert (
        d.curveSupply > 0 && d.poolSupply > 0 && d.curveSupply < d.virtualToken0 &&
        d.virtualTon0 > 0
    ) throw Errors.InvalidParams;
    // a buy under 0.01 TON is dust (gas alone is BUY_GAS): the floor keeps spam and zero-output buys off the curve
    assert (d.minBuy >= MIN_BUY_FLOOR) throw Errors.InvalidParams;
    assert (
        d.graduationFee >= CURVE_GRADUATION_GAS + GRADUATION_FEE_MARGIN
    ) throw Errors.InvalidParams;
    val sellOutNet = d.tonInFor(d.curveSupply);
    val sellOutTon = sellOutNet + (sellOutNet * d.feeBps) / (10000 - d.feeBps);
    // the pool must receive liquidity whichever trigger fires
    assert (
        d.graduationTon > d.graduationFee && sellOutNet > d.graduationFee
    ) throw Errors.InvalidParams;
    assert (sellOutTon >= d.graduationTon || d.sellOutGraduation) throw Errors.InvalidParams;
}

fun masterInit(codes: FactoryCodes, seq: uint64, metadata: cell): AutoDeployAddress {
    return {
        workchain: BASECHAIN,
        stateInit: {
            code: codes.master,
            data: RewardMasterStorage {
                totalSupply: 0,
                poolReserve: 0,
                curveOpen: false,
                pool: null,
                roles: RewardMasterRoles {
                    factory: contract.getAddress(),
                    seq,
                    curve: null,
                    vault: null,
                }.toCell(),
                indices: [],
                remainders: [],
                metadata,
            }.toCell(),
        },
    };
}

fun vaultInit(
    codes: FactoryCodes,
    roles: FactoryRoles,
    config: FactoryConfig,
    master: address,
    rewards: map<uint8, address>,
): AutoDeployAddress {
    var slots: map<uint8, RewardSlot> = [];
    var seen: map<address, bool> = [];
    var count = 0;
    var r = rewards.findFirst();
    while (r.isFound) {
        assert (r.getKey() == count && count < MAX_REWARDS) throw Errors.TooManyRewards;
        val rewardMaster = r.loadValue();
        assert (config.rewardWhitelist.exists(rewardMaster)) throw Errors.DestNotWhitelisted;
        // one slot per jetton master: the vault attributes TEP-89 answers by master, a duplicate would leave its
        // slot undiscovered for ever and stall every conversion of the coin (audit 3, SEC-201)
        assert (!seen.exists(rewardMaster)) throw Errors.InvalidParams;
        seen.set(rewardMaster, true);
        slots.set(
            r.getKey(),
            RewardSlot {
                rewardMaster,
                vaultWallet: null,
                carry: 0,
                paid: 0,
            },
        );
        count += 1;
        r = rewards.iterateNext(r);
    }
    val more = codes.more.load();
    return {
        workchain: BASECHAIN,
        stateInit: {
            code: codes.vault,
            data: RewardVaultStorage {
                rewardCount: count as uint8,
                cycleNext: 0,
                totalTonIn: 0,
                totalTonSpent: 0,
                reserve: config.vaultReserve,
                pendingTimeout: config.vaultPendingTimeout,
                payoutNonce: 0,
                roles: RewardVaultRoles {
                    admin: roles.admin,
                    keeper: roles.keeper,
                    master,
                    walletCode: more.wallet,
                }.toCell(),
                rewards: slots,
                dexVault: config.dexVault,
                pending: null,
                extra: VaultExtra {
                    dexPools: config.dexPools,
                    payouts: [],
                    proposal: null,
                }.toCell(),
            }.toCell(),
        },
    };
}

fun splitterInit(
    codes: FactoryCodes,
    roles: FactoryRoles,
    routes: FactoryRoutes,
    config: FactoryConfig,
    splits: FeeSplits,
    vault: address,
    active: bool,
): AutoDeployAddress {
    return {
        workchain: BASECHAIN,
        stateInit: {
            code: codes.splitter,
            data: FeeSplitterStorage {
                admin: roles.admin,
                active,
                locked: 0,
                accrued: 0,
                totalIn: 0,
                minSplit: config.minSplit,
                minProtocolBps: config.minProtocolBps,
                routes: FeeRoutes {
                    protocol: roles.protocol,
                    pot: routes.pot,
                    buyback: routes.buyback,
                }.toCell(),
                reward: RewardRoute { vault, splits }.toCell(),
                proposal: null,
            }.toCell(),
        },
    };
}

fun curveInit(
    codes: FactoryCodes,
    roles: FactoryRoles,
    config: FactoryConfig,
    master: address,
    splitter: address,
    premint: Premint?,
): AutoDeployAddress {
    val d = config.curve.load();
    val more = codes.more.load();
    var sold: coins = 0;
    var realTon: coins = 0;
    var net: coins = 0;
    if (premint != null) {
        sold = premint.sold;
        realTon = premint.seedTon;
        net = d.tonInFor(sold);
    }
    return {
        workchain: BASECHAIN,
        stateInit: {
            code: more.curve,
            data: CurveStorage {
                state: CURVE_INIT,
                virtualTon: d.virtualTon0 + net,
                virtualToken: d.virtualToken0 - sold,
                realTon,
                sold,
                pool: null,
                roles: CurveRoles {
                    factory: contract.getAddress(),
                    master,
                    splitter,
                }.toCell(),
                params: CurveParams {
                    protocol: roles.protocol,
                    feeBps: d.feeBps,
                    curveSupply: d.curveSupply,
                    poolSupply: d.poolSupply,
                    graduationTon: d.graduationTon,
                    graduationFee: d.graduationFee,
                    minBuy: d.minBuy,
                    poolLpFeeBps: d.poolLpFeeBps,
                    poolProtocolFeeBps: d.poolProtocolFeeBps,
                    walletCode: more.wallet,
                }.toCell(),
            }.toCell(),
        },
    };
}

fun deployWith<T>(dest: AutoDeployAddress, value: coins, body: T) {
    val m = createMessage({ bounce: BounceMode.NoBounce, dest, value, body });
    m.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun countRewards(rewards: map<uint8, address>): int {
    var count = 0;
    var r = rewards.findFirst();
    while (r.isFound) {
        count += 1;
        r = rewards.iterateNext(r);
    }
    return count;
}

/// Checks a premint against the curve defaults; returns (holders, total coins).
fun Premint.check(self, d: CurveDefaults): (int, coins) {
    var holders = 0;
    var total: coins = 0;
    var r = self.holders.findFirst();
    while (r.isFound) {
        assert (r.getKey().getWorkchain() == BASECHAIN) throw Errors.InvalidWorkchain;
        val amount = r.loadValue();
        assert (amount > 0) throw Errors.InvalidParams;
        total += amount;
        holders += 1;
        r = self.holders.iterateNext(r);
    }
    assert (holders > 0 && holders <= MAX_PREMINT) throw Errors.InvalidParams;
    // the curve starts where those coins would have left it, backed by at least the TON they would have cost
    assert (total == self.sold && self.sold < d.curveSupply) throw Errors.InvalidParams;
    assert (self.seedTon >= d.tonInFor(self.sold)) throw Errors.InvalidParams;
    return (holders, total);
}

fun onInternalMessage(in: InMessage) {
    var storage = lazy FactoryStorage.load();
    val msg = lazy AllowedMessageToFactory.fromSlice(in.body);

    match (msg) {
        CreateLaunch => {
            assert (!storage.paused) throw Errors.FactoryPaused;
            val roles = storage.roles.load();
            val routes = storage.routes.load();
            val config = storage.config.load();
            val codes = storage.gov.load().codes.load();
            assert (in.senderAddress.getWorkchain() == BASECHAIN) throw Errors.InvalidWorkchain;
            var splits = config.splits;
            if (msg.splits != null) {
                assert (in.senderAddress == roles.admin) throw Errors.NotFromAdmin;
                val s = msg.splits;
                assert (s.isValid(config.minProtocolBps)) throw Errors.InvalidSplits;
                splits = s;
            }
            var premint: Premint? = null;
            var premintHolders = 0;
            var preminted: coins = 0;
            var seedTon: coins = 0;
            if (msg.premint != null) {
                assert (in.senderAddress == roles.admin) throw Errors.NotFromAdmin;
                val p = msg.premint.load();
                val (holders, total) = p.check(config.curve.load());
                premint = p;
                premintHolders = holders;
                preminted = total;
                seedTon = p.seedTon;
            }
            // the value must cover every fixed send of this handler: LAUNCH_GAS pays the 4 deploys + wiring + our own
            // compute; the first buy's gas and the per-reward discovery come on top (SEC-105)
            val rewardsGas = countRewards(msg.rewards) * VAULT_DISCOVERY_PER_REWARD;
            val firstBuyGas: coins = msg.firstBuyTon > 0 ? CURVE_BUY_GAS : (0 as coins);
            assert (
                in.valueCoins >=
                config.launchFee + msg.firstBuyTon + firstBuyGas + rewardsGas + seedTon +
                premintHolders * PREMINT_VALUE +
                LAUNCH_GAS
            ) throw Errors.LaunchFeeUnpaid;

            val seq = storage.seq;
            storage.seq += 1;
            storage.save();

            val master = masterInit(codes, seq, msg.metadata);
            val masterAddress = master.calculateAddress();
            val vault = vaultInit(codes, roles, config, masterAddress, msg.rewards);
            val vaultAddress = vault.calculateAddress();
            val rewardCount = countRewards(msg.rewards);
            val splitter = splitterInit(
                codes,
                roles,
                routes,
                config,
                splits,
                vaultAddress,
                rewardCount > 0,
            );
            val splitterAddress = splitter.calculateAddress();
            val curve = curveInit(
                codes,
                roles,
                config,
                masterAddress,
                splitterAddress,
                premint,
            );
            val curveAddress = curve.calculateAddress();

            // keep our previous balance; everything attached to this message is spent on the launch
            reserveToncoinsOnBalance(
                contract.getOriginalBalance() - in.valueCoins,
                RESERVE_MODE_EXACT_AMOUNT,
            );

            deployWith(master, MASTER_DEPLOY_VALUE, TopUpTons {});
            deployWith(
                vault,
                VAULT_DEPLOY_VALUE + rewardCount * VAULT_DISCOVERY_PER_REWARD,
                TopUpTons {},
            );
            deployWith(splitter, SPLITTER_DEPLOY_VALUE, TopUpTons {});
            deployWith(curve, CURVE_DEPLOY_VALUE + seedTon, TopUpTons {});

            val wire = createMessage({
                bounce: BounceMode.NoBounce,
                dest: masterAddress,
                value: WIRE_VALUE,
                body: WireMaster {
                    queryId: msg.queryId,
                    curve: curveAddress,
                    vault: vaultAddress,
                },
            });
            wire.send(SEND_MODE_PAY_FEES_SEPARATELY);
            val open = createMessage({
                bounce: BounceMode.NoBounce,
                dest: curveAddress,
                value: OPEN_VALUE,
                body: OpenCurve { queryId: msg.queryId },
            });
            open.send(SEND_MODE_PAY_FEES_SEPARATELY);
            if (premint != null) {
                var r = premint.holders.findFirst();
                while (r.isFound) {
                    val mint = createMessage({
                        bounce: BounceMode.NoBounce,
                        dest: masterAddress,
                        value: PREMINT_VALUE,
                        body: PremintCoins {
                            queryId: msg.queryId,
                            to: r.getKey(),
                            amount: r.loadValue(),
                        },
                    });
                    mint.send(SEND_MODE_PAY_FEES_SEPARATELY);
                    r = premint.holders.iterateNext(r);
                }
            }
            if (msg.firstBuyTon > 0) {
                val firstBuy = createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: curveAddress,
                    value: msg.firstBuyTon + CURVE_BUY_GAS,
                    body: Buy {
                        queryId: msg.queryId,
                        minOut: 0,
                        recipient: in.senderAddress,
                    },
                });
                firstBuy.send(SEND_MODE_PAY_FEES_SEPARATELY);
            }
            if (config.launchFee > 0) {
                val fee = createMessage({ bounce: BounceMode.NoBounce, dest: roles.protocol, value: config.launchFee });
                fee.send(SEND_MODE_PAY_FEES_SEPARATELY);
            }
            emitFactoryEvent(
                EVENT_TOPIC_LAUNCH_CREATED,
                LaunchCreatedEvent {
                    seq,
                    creator: in.senderAddress,
                    addresses: LaunchAddresses {
                        master: masterAddress,
                        vault: vaultAddress,
                        more: LaunchAddressesMore {
                            splitter: splitterAddress,
                            curve: curveAddress,
                        }.toCell(),
                    }.toCell(),
                    rewardCount: rewardCount as uint8,
                    firstBuyTon: msg.firstBuyTon,
                    codeVersion: LAUNCHER_CODE_VERSION,
                    preminted,
                },
            );
            // whatever is left of the gas budget goes back to the creator
            val excesses = createMessage({
                bounce: BounceMode.NoBounce,
                dest: in.senderAddress,
                value: 0,
                body: ReturnExcessesBack { queryId: msg.queryId },
            });
            // SAFETY: last action after a RESERVE of what we held before this message: carries the incoming value minus our fixed sends (rule 1, docs/10)
            excesses.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS);
        }

        SetFactoryPaused => {
            val roles = lazy storage.roles.load();
            assert (in.senderAddress == roles.admin) throw Errors.NotFromAdmin;
            storage.paused = msg.paused;
            storage.save();
        }

        SetFactoryConfig => {
            val roles = lazy storage.roles.load();
            assert (in.senderAddress == roles.admin) throw Errors.NotFromAdmin;
            msg.config.load().assertValid();
            storage.config = msg.config;
            storage.save();
        }

        ProposeFactoryChange => {
            val roles = lazy storage.roles.load();
            assert (in.senderAddress == roles.admin) throw Errors.NotFromAdmin;
            // the payload must parse now, not in 48 h
            if (msg.kind == PROPOSAL_CODES) {
                val codes = FactoryCodes.fromCell(msg.payload);
                codes.more.load();
            } else if (msg.kind == PROPOSAL_ROLES) {
                val p = RolesProposal.fromCell(msg.payload);
                p.roles.load();
                p.routes.load();
            } else {
                throw Errors.InvalidParams;
            }
            var gov = storage.gov.load();
            val readyAt = (blockchain.now() + FACTORY_DELAY) as uint32;
            gov.proposal = FactoryProposal {
                kind: msg.kind,
                payload: msg.payload,
                readyAt,
            }.toCell();
            storage.gov = gov.toCell();
            storage.save();
            // the proposal itself is announced: the 48 h only protect someone who is told
            emitFactoryEvent(
                EVENT_TOPIC_FACTORY_CHANGED,
                FactoryChangedEvent {
                    kind: msg.kind,
                    applied: false,
                    readyAt,
                },
            );
        }

        ApplyFactoryChange => {
            val roles = lazy storage.roles.load();
            assert (in.senderAddress == roles.admin) throw Errors.NotFromAdmin;
            var gov = storage.gov.load();
            assert (gov.proposal != null) throw Errors.NothingPending;
            val proposal = gov.proposal.load();
            assert (blockchain.now() >= proposal.readyAt) throw Errors.PendingNotExpired;
            if (proposal.kind == PROPOSAL_CODES) {
                gov.codes = proposal.payload as Cell<FactoryCodes>;
            } else {
                val p = RolesProposal.fromCell(proposal.payload);
                storage.roles = p.roles;
                storage.routes = p.routes;
            }
            gov.proposal = null;
            storage.gov = gov.toCell();
            storage.save();
            emitFactoryEvent(
                EVENT_TOPIC_FACTORY_CHANGED,
                FactoryChangedEvent {
                    kind: proposal.kind,
                    applied: true,
                    readyAt: proposal.readyAt,
                },
            );
        }

        TopUpTons => {
            // accept
        }

        ReturnExcessesBack => {
            // excess of the creator's first buy comes back to us (the Buy sender): kept as gas reserve
        }

        else => {
            assert (in.body.isEmpty() || in.body.preloadUint(32) == 0) throw 0xFFFF;
        }
    }
}

get fun get_factory_data(): FactoryDataReply {
    val storage = lazy FactoryStorage.load();
    val gov = storage.gov.load();
    return {
        seq: storage.seq,
        paused: storage.paused,
        roles: storage.roles.load(),
        routes: storage.routes.load(),
        config: storage.config.load(),
        proposal: gov.proposal != null ? gov.proposal.load() : null,
    };
}

get fun get_factory_codes(): FactoryCodes {
    val storage = lazy FactoryStorage.load();
    return storage.gov.load().codes.load();
}

/// Deterministic addresses of a launch, computable before it happens.
/// `splits` / `premint` = null for a regular launch, or the admin overrides used for that launch.
get fun get_launch_addresses(
    seq: uint64,
    metadata: cell,
    rewards: map<uint8, address>,
    splits: Cell<FeeSplits>?,
    premint: Cell<Premint>?,
): LaunchAddresses {
    val storage = lazy FactoryStorage.load();
    val roles = storage.roles.load();
    val routes = storage.routes.load();
    val config = storage.config.load();
    val codes = storage.gov.load().codes.load();
    val master = masterInit(codes, seq, metadata).calculateAddress();
    val vault = vaultInit(codes, roles, config, master, rewards).calculateAddress();
    val s = splits == null ? config.splits : splits.load();
    val splitter = splitterInit(
        codes,
        roles,
        routes,
        config,
        s,
        vault,
        countRewards(rewards) > 0,
    ).calculateAddress();
    val p: Premint? = premint == null ? null : premint.load();
    val curve = curveInit(
        codes,
        roles,
        config,
        master,
        splitter,
        p,
    ).calculateAddress();
    return {
        master,
        vault,
        more: LaunchAddressesMore { splitter, curve }.toCell(),
    };
}

get fun get_code_version(): int {
    return LAUNCHER_CODE_VERSION;
}
