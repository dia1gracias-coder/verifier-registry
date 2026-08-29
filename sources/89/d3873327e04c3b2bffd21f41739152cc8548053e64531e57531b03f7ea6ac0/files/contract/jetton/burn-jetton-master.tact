// SPDX-License-Identifier: MIT
// BURN Jetton master (TEP-74 + TEP-64). Max supply 1000 BURN (9 decimals).

import "./burn-jetton-wallet";

/// 1000 tokens * 10^9 nano
const BURN_MAX_SUPPLY_NANO: Int = 1000 * pow(10, 9);
/// TEP-89: headroom for provide_wallet_address computation (reference jetton-minter-discoverable.fc).
const provideAddressGasConsumption: Int = ton("0.01");

struct BurnJettonMasterState {
    totalSupply: Int as coins;
    mintable: Bool;
    adminAddress: Address;
    jettonContent: Cell;
    jettonWalletCode: Cell;
}

struct MasterFeeParamsView {
    burnRateBps: Int;
    stakingRateBps: Int;
    treasuryRateBps: Int;
    stakingPoolOwner: Address;
    treasuryOwner: Address;
    feeDestinationsActive: Bool;
}

struct EffectiveFeeParams {
    burnBps: Int;
    stakingBps: Int;
    treasuryBps: Int;
}

contract BurnJettonMaster(
    totalSupply: Int as coins,
    admin: Address,
    timelock: Address,
    content: Cell,
    mintable: Bool,
    burnRateBps: Int,
    stakingRateBps: Int,
    treasuryRateBps: Int,
    stakingPoolOwner: Address,
    treasuryOwner: Address,
    feeDestinationsActive: Bool,
    excludedHead: Cell,
    excludedCount: Int,
    dynamicBurnEnabled: Bool,
    largeTxThreshold: Int as coins,
    activityThreshold: Int,
    maxBurnRateBps: Int,
    txCountLastHour: Int,
    activityHourBucket: Int,
    autoReduceThreshold: Int as coins,
    lowBurnBps: Int,
    lowStakingBps: Int,
    lowTreasuryBps: Int,
    // IMP-MNAUD-F22: governance-tunable TON gas gates (Timelock via SetGasParams).
    // Deploy defaults MUST equal the post-F17 W1 wallet constants (1.0 / 0.55 /
    // 0.07 / 0.01 / 0.06 / 0.05) so behavior without governance intervention is
    // identical to pre-F22. Values are propagated to wallets inside
    // JettonUpdateFeeConfig via the existing push channels only (no live-resolve).
    gasMinTonFeePath: Int as coins,
    gasPerInternalDeployTon: Int as coins,
    gasPoolFwdMin: Int as coins,
    gasTreasuryFwdMin: Int as coins,
    gasBurnNotify: Int as coins,
    gasPropagate: Int as coins,
) {
    /// Plain TON from Timelock (governance fee-config / excluded-list ops) must not bounce
    /// back — that would ping-pong with Timelock's generic receive() (RC-A / IMP-RELAY-04).
    /// Jetton wallets use typed handlers only (no bare receive), so no JW↔Master loop.
    receive() {
        if (sender() != self.timelock) {
            cashback(sender());
        }
    }

    receive(msg: ProvideWalletAddress) {
        let ctx = context();
        let fwdFee = ctx.readForwardFee();
        require(
            ctx.value > fwdFee + provideAddressGasConsumption,
            "Insufficient gas for wallet discovery",
        );

        let ownerWorkchain: Int = parseStdAddress(msg.ownerAddress.asSlice()).workchain;
        let walletResolvable: Bool = ownerWorkchain == Basechain;

        message(MessageParameters {
            body: makeTep89TakeWalletAddressMsg(walletResolvable, msg),
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
        });
    }

    receive(msg: Mint) {
        require(sender() == self.admin, "Incorrect sender");
        require(self.mintable, "Mint is closed");
        require(
            self.totalSupply + msg.mintMessage.amount <= BURN_MAX_SUPPLY_NANO,
            "Mint cap exceeded",
        );

        checkEitherForwardPayload(msg.mintMessage.forwardPayload);

        let ctx = context();
        require(
            ctx.value >
                minTonsForStorage +
                msg.mintMessage.forwardTonAmount +
                ctx.readForwardFee() +
                getForwardFee(walletStateInitCells, walletStateInitBits, false) +
                2 * getComputeFee(gasForTransfer, false),
            "Insufficient gas for mint",
        );

        self.totalSupply += msg.mintMessage.amount;

        deploy(DeployParameters {
            value: 0,
            bounce: true,
            mode: SendRemainingValue | SendBounceIfActionFail,
            body: msg.mintMessage.toCell(),
            init: getBurnJettonWalletInit(msg.receiver),
        });
    }

    receive(msg: CloseMint) {
        require(sender() == self.admin, "Incorrect sender");
        // Irreversible: no receiver ever sets mintable back to true.
        self.mintable = false;
    }

    receive(msg: JettonBurnNotification) {
        let s = parseStdAddress(sender().asSlice());
        let wallet = getBurnJettonBasechainWalletByOwner(msg.sender);
        require(s.workchain == Basechain && s.address == wallet.hash!!, "Unauthorized burn");

        let hour = now() / 3600;
        if (hour != self.activityHourBucket) {
            self.activityHourBucket = hour;
            self.txCountLastHour = 0;
        }
        self.txCountLastHour += 1;

        self.totalSupply -= msg.amount;

        if (msg.responseDestination != null) {
            message(MessageParameters {
                to: msg.responseDestination!!,
                body: JettonExcesses { queryId: msg.queryId }.toCell(),
                value: 0,
                bounce: false,
                mode: SendRemainingValue | SendIgnoreErrors,
            });
        }
    }

    receive(msg: JettonUpdateContent) {
        require(sender() == self.admin, "Incorrect sender");
        self.content = msg.content;
    }

    receive(msg: ChangeOwner) {
        require(sender() == self.admin, "Incorrect sender");
        self.admin = msg.newOwner;
    }

    receive(msg: SetFeeParams) {
        require(sender() == self.timelock, "Only timelock");
        // MNAUD-9/M-1: total fee capped at MAX_TOTAL_FEE_BPS (500 = 5%); negative
        // legs are rejected so the sum check cannot be gamed into a confiscatory leg.
        require(
            msg.burn_rate_bps >= 0 &&
                msg.staking_rate_bps >= 0 &&
                msg.treasury_rate_bps >= 0 &&
                msg.burn_rate_bps + msg.staking_rate_bps + msg.treasury_rate_bps <= MAX_TOTAL_FEE_BPS,
            "Invalid fee bps",
        );
        self.burnRateBps = msg.burn_rate_bps;
        self.stakingRateBps = msg.staking_rate_bps;
        self.treasuryRateBps = msg.treasury_rate_bps;
    }

    receive(msg: SetFeeDestinations) {
        require(sender() == self.timelock, "Only timelock");
        self.stakingPoolOwner = msg.staking_pool;
        self.treasuryOwner = msg.treasury;
        self.feeDestinationsActive = true;
    }

    receive(msg: AddExcluded) {
        require(sender() == self.timelock, "Only timelock");
        if (!isInExcludedChain(msg.address, self.excludedHead)) {
            require(self.excludedCount < MAX_EXCLUDED_ADDRESSES, "Max excluded");
            self.excludedHead = excludedChainPrepend(self.excludedHead, msg.address);
            self.excludedCount += 1;
        }
    }

    receive(msg: RemoveExcluded) {
        require(sender() == self.timelock, "Only timelock");
        if (isInExcludedChain(msg.address, self.excludedHead)) {
            self.excludedHead = excludedChainRemove(msg.address, self.excludedHead);
            self.excludedCount -= 1;
        }
    }

    receive(msg: SetDynamicBurnEnabled) {
        require(sender() == self.timelock, "Only timelock");
        self.dynamicBurnEnabled = msg.enabled;
    }

    receive(msg: SetDynamicBurnThresholds) {
        require(sender() == self.timelock, "Only timelock");
        self.largeTxThreshold = msg.large_tx_threshold;
        self.activityThreshold = msg.activity_threshold;
    }

    receive(msg: SetAutoReduceParams) {
        require(sender() == self.timelock, "Only timelock");
        // MNAUD-9/M-1: low-supply params are an alternate effective-fee source —
        // the uniform MAX_TOTAL_FEE_BPS cap applies to this path as well.
        require(
            msg.low_burn_bps >= 0 &&
                msg.low_staking_bps >= 0 &&
                msg.low_treasury_bps >= 0 &&
                msg.low_burn_bps + msg.low_staking_bps + msg.low_treasury_bps <= MAX_TOTAL_FEE_BPS,
            "Invalid low fee bps",
        );
        self.autoReduceThreshold = msg.threshold;
        self.lowBurnBps = msg.low_burn_bps;
        self.lowStakingBps = msg.low_staking_bps;
        self.lowTreasuryBps = msg.low_treasury_bps;
    }

    receive(msg: SetTimelock) {
        require(sender() == self.timelock, "Only timelock");
        self.timelock = msg.newTimelock;
    }

    receive(msg: SetGasParams) {
        require(sender() == self.timelock, "Only timelock");
        // IMP-MNAUD-F22: const caps (MAX_TOTAL_FEE_BPS pattern) + on-chain coherence
        // invariant — reject any configuration where the entry gate could admit an
        // attach that then fails the fee-fanout require (F10 strand band). Same
        // check is re-run wallet-side on JettonUpdateFeeConfig receipt.
        let gas = GasParamsView {
            minTonFeePath: msg.min_ton_fee_path,
            perInternalDeployTon: msg.per_internal_deploy_ton,
            poolForwardMin: msg.gas_pool_forward_min,
            treasuryForwardMin: msg.gas_treasury_forward_min,
            burnNotifyTon: msg.gas_burn_notify_ton,
            propagateTon: msg.gas_propagate_ton,
        };
        require(isValidGasParams(gas), "Invalid gas params");
        self.gasMinTonFeePath = msg.min_ton_fee_path;
        self.gasPerInternalDeployTon = msg.per_internal_deploy_ton;
        self.gasPoolFwdMin = msg.gas_pool_forward_min;
        self.gasTreasuryFwdMin = msg.gas_treasury_forward_min;
        self.gasBurnNotify = msg.gas_burn_notify_ton;
        self.gasPropagate = msg.gas_propagate_ton;
    }

    receive(msg: SyncFeeConfigToWallet) {
        require(sender() == self.timelock, "Only timelock");
        require(self.feeDestinationsActive, "Fee destinations not configured on master");

        let ctx = context();
        require(ctx.value > ton("0.03"), "Insufficient TON for sync");

        self.pushFeeConfigToOwner(msg.queryId, msg.owner);
    }

    receive(msg: PropagateFeeConfigToOwner) {
        require(self.feeDestinationsActive, "Fee destinations not configured on master");
        require(getBurnJettonWalletByOwner(msg.sender_owner) == sender(), "Unauthorized jetton wallet");
        self.pushFeeConfigToOwner(msg.queryId, msg.recipient_owner);
    }

    /// Live excluded-list resolution for transfers with stale wallet fee-config snapshots (IMP-STKFEE-02).
    receive(msg: ResolveJettonTransfer) {
        require(self.feeDestinationsActive, "Fee destinations not configured on master");
        require(getBurnJettonWalletByOwner(msg.sender_owner) == sender(), "Unauthorized jetton wallet");

        let excludedTransfer = isInExcludedChain(msg.sender_owner, self.excludedHead)
            || isInExcludedChain(msg.destination, self.excludedHead);

        let ctx = context();
        let cfgPushTon = ton("0.04");
        require(ctx.value > cfgPushTon + ton("0.05"), "Insufficient TON for resolve");

        let low = self.totalSupply < self.autoReduceThreshold;
        let effBurn = low ? self.lowBurnBps : self.burnRateBps;
        let effStake = low ? self.lowStakingBps : self.stakingRateBps;
        let effTreas = low ? self.lowTreasuryBps : self.treasuryRateBps;

        let cfg = JettonUpdateFeeConfig {
            queryId: msg.queryId,
            burn_rate_bps: effBurn,
            staking_rate_bps: effStake,
            treasury_rate_bps: effTreas,
            staking_pool: self.stakingPoolOwner,
            treasury: self.treasuryOwner,
            dynamic_burn_enabled: self.dynamicBurnEnabled,
            large_tx_threshold: self.largeTxThreshold,
            activity_threshold: self.activityThreshold,
            max_burn_rate_bps: self.maxBurnRateBps,
            tx_count_snapshot: self.txCountLastHour,
            activity_hour_bucket: self.activityHourBucket,
            low_supply_mode: low,
            excluded_count: self.excludedCount,
            excluded_head: self.excludedHead,
            gas_min_ton_fee_path: self.gasMinTonFeePath,
            gas_per_internal_deploy_ton: self.gasPerInternalDeployTon,
            gas_pool_forward_min: self.gasPoolFwdMin,
            gas_treasury_forward_min: self.gasTreasuryFwdMin,
            gas_burn_notify_ton: self.gasBurnNotify,
            gas_propagate_ton: self.gasPropagate,
        };

        message(MessageParameters {
            body: cfg.toCell(),
            to: getBurnJettonWalletByOwner(msg.sender_owner),
            value: cfgPushTon,
            bounce: false,
            mode: SendPayGasSeparately | SendIgnoreErrors,
        });

        message(MessageParameters {
            body: CommitJettonTransfer {
                queryId: msg.queryId,
                amount: msg.amount,
                destination: msg.destination,
                responseDestination: msg.responseDestination,
                forwardTonAmount: msg.forwardTonAmount,
                forwardPayload: msg.forwardPayload,
                excludedTransfer: excludedTransfer,
            }.toCell(),
            to: getBurnJettonWalletByOwner(msg.sender_owner),
            value: 0,
            bounce: true,
            mode: SendRemainingValue | SendIgnoreErrors,
        });
    }

    inline fun pushFeeConfigToOwner(queryId: Int, owner: Address) {
        let low = self.totalSupply < self.autoReduceThreshold;
        let effBurn = low ? self.lowBurnBps : self.burnRateBps;
        let effStake = low ? self.lowStakingBps : self.stakingRateBps;
        let effTreas = low ? self.lowTreasuryBps : self.treasuryRateBps;

        let cfg = JettonUpdateFeeConfig {
            queryId: queryId,
            burn_rate_bps: effBurn,
            staking_rate_bps: effStake,
            treasury_rate_bps: effTreas,
            staking_pool: self.stakingPoolOwner,
            treasury: self.treasuryOwner,
            dynamic_burn_enabled: self.dynamicBurnEnabled,
            large_tx_threshold: self.largeTxThreshold,
            activity_threshold: self.activityThreshold,
            max_burn_rate_bps: self.maxBurnRateBps,
            tx_count_snapshot: self.txCountLastHour,
            activity_hour_bucket: self.activityHourBucket,
            low_supply_mode: low,
            excluded_count: self.excludedCount,
            excluded_head: self.excludedHead,
            gas_min_ton_fee_path: self.gasMinTonFeePath,
            gas_per_internal_deploy_ton: self.gasPerInternalDeployTon,
            gas_pool_forward_min: self.gasPoolFwdMin,
            gas_treasury_forward_min: self.gasTreasuryFwdMin,
            gas_burn_notify_ton: self.gasBurnNotify,
            gas_propagate_ton: self.gasPropagate,
        };

        // IMP-MNAUD-F14: deploy with StateInit so SyncFeeConfigToWallet activates
        // uninit wallets (treasury never receives a mint at bootstrap). Same init
        // as mint; body is JettonUpdateFeeConfig (emptyCfg → active on receive).
        deploy(DeployParameters {
            value: 0,
            bounce: false,
            mode: SendRemainingValue | SendIgnoreErrors,
            body: cfg.toCell(),
            init: getBurnJettonWalletInit(owner),
        });
    }

    bounced(msg: bounced<JettonTransferInternal>) {
        self.totalSupply -= msg.amount;
    }

    /// IMP-MNAUD-F18: residual (non-balance) commit-hop failure. Balance failures are
    /// reported wallet-side (JettonTransferCommitFailed → owner); anything else that
    /// bounces here cannot be routed on-chain — the bounce prefix has no owner address —
    /// so emit an external event instead of swallowing the failure silently.
    bounced(msg: bounced<CommitJettonTransfer>) {
        emit(CommitJettonTransferBounced { queryId: msg.queryId, amount: msg.amount }.toCell());
    }

    get fun get_jetton_data(): BurnJettonMasterState {
        return BurnJettonMasterState {
            totalSupply: self.totalSupply,
            mintable: self.mintable,
            adminAddress: self.admin,
            jettonContent: self.content,
            jettonWalletCode: codeOf BurnJettonWallet,
        };
    }

    get fun get_timelock_address(): Address {
        return self.timelock;
    }

    get fun get_wallet_address(ownerAddress: Address): Address {
        return getBurnJettonWalletByOwner(ownerAddress);
    }

    get fun get_fee_params(): MasterFeeParamsView {
        return MasterFeeParamsView {
            burnRateBps: self.burnRateBps,
            stakingRateBps: self.stakingRateBps,
            treasuryRateBps: self.treasuryRateBps,
            stakingPoolOwner: self.stakingPoolOwner,
            treasuryOwner: self.treasuryOwner,
            feeDestinationsActive: self.feeDestinationsActive,
        };
    }

    get fun get_effective_fee_params(): EffectiveFeeParams {
        let low = self.totalSupply < self.autoReduceThreshold;
        return EffectiveFeeParams {
            burnBps: low ? self.lowBurnBps : self.burnRateBps,
            stakingBps: low ? self.lowStakingBps : self.stakingRateBps,
            treasuryBps: low ? self.lowTreasuryBps : self.treasuryRateBps,
        };
    }

    get fun get_is_excluded(holder: Address): Bool {
        return isInExcludedChain(holder, self.excludedHead);
    }

    /// Current governance-tunable TON gas params (IMP-MNAUD-F22).
    get fun get_gas_params(): GasParamsView {
        return GasParamsView {
            minTonFeePath: self.gasMinTonFeePath,
            perInternalDeployTon: self.gasPerInternalDeployTon,
            poolForwardMin: self.gasPoolFwdMin,
            treasuryForwardMin: self.gasTreasuryFwdMin,
            burnNotifyTon: self.gasBurnNotify,
            propagateTon: self.gasPropagate,
        };
    }

    /// Treasury TEP-74 owner address (must match `SetFeeDestinations.treasury` — typically the Treasury contract).
    get fun get_treasury_address(): Address {
        return self.treasuryOwner;
    }
}

inline fun getBurnJettonWalletInit(address: Address): StateInit {
    return initOf BurnJettonWallet(address, myAddress(), 0, jettonWalletEmptyFeeConfig());
}

inline fun getBurnJettonWalletByOwner(jettonWalletOwner: Address): Address {
    return contractAddress(getBurnJettonWalletInit(jettonWalletOwner));
}

inline fun getBurnJettonBasechainWalletByOwner(jettonWalletOwner: Address): BasechainAddress {
    return contractBasechainAddress(getBurnJettonWalletInit(jettonWalletOwner));
}

/// TEP-89 TakeWalletAddress body: addr_none when owner workchain is not basechain.
inline fun makeTep89TakeWalletAddressMsg(walletResolvable: Bool, msg: ProvideWalletAddress): Cell {
    let b = beginCell()
        .storeUint(TakeWalletAddress.opcode(), 32)
        .storeUint(msg.queryId, 64);
    if (walletResolvable) {
        b = b.storeBasechainAddress(getBurnJettonBasechainWalletByOwner(msg.ownerAddress));
    } else {
        b = b.storeUint(0, 2);
    }
    return b
        .storeMaybeRef(msg.includeAddress ? beginCell().storeAddress(msg.ownerAddress).endCell() : null)
        .endCell();
}
