import "@stdlib/deploy";
import "./msgs/router_msg";
import "./msgs/pool_msg";
import "./msgs/wallet_msg";
import "./pool";
import "./constant";
import "./utils";

const SWAP: Int = 0x25938561;
const PROVIDE_LP: Int = 0xfcf9e58f;
const TRANSFER_BOUNCE_LOCKED: Int = 0x0a0dbdcb;
const TRANSFER_BOUNCE_INVALID_REQUEST: Int = 0x19727ea8;

struct Upgrade {
    endCode: Int as uint64;
    endAdmin: Int as uint64;
    admin: Address?;
    code: Cell?;
}

struct RouterData {
    locked: Bool;
    adminAddress: Address;
    tempUpgrade: Upgrade;
}

@name(set_code)
native setCode(code: Cell);

contract Router with Deployable {
    // store code & admin upgrade data and their waiting periods
    tempUpgrade: Upgrade = Upgrade {
        endCode: 0,
        endAdmin: 0,
        admin: null,
        code: null,
    };

    locked: Bool; // stop Swap & ProvideLP if locked
    adminAddress: Address; // only admin can upgrade or manage router data

    // router constructor
    init(
        locked: Bool,
        adminAddress: Address,
    ) {
        self.locked = locked;
        self.adminAddress = adminAddress;
    }

    // get pool StateInit
    get fun getPoolStateInit(
        jettonWallet0: Address,
        jettonWallet1: Address,
    ) : StateInit {
        if (jettonWallet0.asSlice().hash() > jettonWallet1.asSlice().hash()) {
            return initOf Pool(myAddress(), jettonWallet0, jettonWallet1);
        }
        return initOf Pool(myAddress(), jettonWallet1, jettonWallet0);
    }

    // compute pool address from its wallet addresses
    get fun getPoolAddress(
        jettonWallet0: Address,
        jettonWallet1: Address,
    ) : Address {
        let init: StateInit = self.getPoolStateInit(jettonWallet0, jettonWallet1);
        return contractAddress(init);
    }

    // allow off-chain queries for router date
    get fun getRouterData(): RouterData {
        return RouterData {
            locked: self.locked,
            adminAddress: self.adminAddress,
            tempUpgrade: self.tempUpgrade,
        };
    }

    // process PayTo messages from pool for sending refund or swap-out amount to users
    receive(msg: PayTo) {
        let ctx: Context = context();

        let gasRequired: Int = getComputeFee(100000, false);
        let poolAddress = self.getPoolAddress(msg.token0Address, msg.token1Address);
        nativeThrowUnless(INVALID_CALLER, poolAddress == ctx.sender);

        let tonAmount: Int = 0;
        let mode = SendRemainingValue;

        // split the gas fee if there are two pays
        if (msg.amount0Out > 0 && msg.amount1Out > 0) {
            tonAmount = (ctx.value - gasRequired) / 2;
            mode = 0;
        }
        if (msg.amount0Out > 0) {
            let body = TokenTransfer {
                queryId: msg.queryId,
                amount: msg.amount0Out,
                destination: msg.owner,
                responseDestination: msg.owner,
                customPayload: null,
                forwardTonAmount: 0,
                forwardPayload:
                    beginCell()
                        .storeUint(0, 1)
                        .storeUint(msg.exitCode, 32)
                        .endCell(),
            };
            send(SendParameters{
                to: msg.token0Address,
                value: tonAmount,
                mode: mode + SendIgnoreErrors,
                body: body.toCell(),
            });
        }

        if (msg.amount1Out > 0) {
            let body = TokenTransfer {
                queryId: msg.queryId,
                amount: msg.amount1Out,
                destination: msg.owner,
                responseDestination: msg.owner,
                customPayload: null,
                forwardTonAmount: 0,
                forwardPayload:
                    beginCell()
                        .storeUint(0, 1)
                        .storeUint(msg.exitCode, 32)
                        .endCell(),
            };
            send(SendParameters{
                to: msg.token1Address,
                value: tonAmount,
                mode: mode + SendIgnoreErrors,
                body: body.toCell(),
            });
        }
    }

    // process swap or provide-lp requests from users
    // properly repack them here and send to pool for actual handling
    receive(msg: TokenNotification) {
        let ctx: Context = context();
        nativeThrowUnless(INVALID_AMOUNT, msg.amount > 0);

        let fwdFee: Int = ctx.readForwardFee();
        let payload = msg.forwardPayload!!.asSlice();
        let op: Int = payload.loadUint(32);
        let tokenWallet: Address = payload.loadAddress();
        let init = self.getPoolStateInit(ctx.sender, tokenWallet);
        let poolAddress = contractAddress(init);

        // refund users if insufficient fees, invalid token pair, or locked
        if (fwdFee * 6 > ctx.value || ctx.sender == tokenWallet || self.locked) {
            let builder: Builder = beginCell().storeUint(0, 1);
            if (self.locked) {
                builder.storeUint(TRANSFER_BOUNCE_LOCKED, 32);
            } else {
                builder.storeUint(TRANSFER_BOUNCE_INVALID_REQUEST, 32);
            }
            let body = TokenTransfer {
                queryId: msg.queryId,
                amount: msg.amount,
                destination: msg.from,
                responseDestination: msg.from,
                customPayload: null,
                forwardTonAmount: 0,
                forwardPayload: builder.endCell(),
            };
            send(SendParameters{
                to: ctx.sender,
                value: 0,
                mode: SendRemainingValue,
                body: body.toCell(),
            });
        } else if (op == SWAP) {
            let minOut = payload.loadCoins();
            let toAddress = payload.loadAddress();
            let hasRef = payload.loadUint(1);

            let refAddress: Address? = null;
            if (hasRef == 1) {
                refAddress = payload.loadAddress();
            }
            let refMessageValue = payload.loadCoins();

            let hasNext = payload.loadBool();
            let next: SwapNext? = null;
            if (hasNext) {
                next = SwapNext.fromCell(payload.loadRef());
            }
            let body = Swap {
                queryId: msg.queryId,
                fromUserAddress: toAddress,
                tokenWallet: ctx.sender,
                amount: msg.amount,
                minOut,
                fromRealUser: msg.from,
                refAddress,
                refMessageValue,
                next,
            };
            send(SendParameters{
                to: poolAddress,
                value: 0,
                mode: SendRemainingValue,
                body: body.toCell(),
                code: init.code,
                data: init.data,
            });
        } else if (op == PROVIDE_LP) {
            let minLpOut = payload.loadCoins();
            let amount0: Int = 0;
            let amount1: Int = 0;
            if (ctx.sender.asSlice().hash() > tokenWallet.asSlice().hash()) {
                amount0 = msg.amount;
            } else {
                amount1 = msg.amount;
            }

            let body = ProvideLpOnSingleSide {
                queryId: msg.queryId,
                ownerAddress: msg.from,
                minLpOut,
                amount0,
                amount1,
            };
            send(SendParameters{
                to: poolAddress,
                value: 0,
                mode: SendRemainingValue,
                body: body.toCell(),
                code: init.code,
                data: init.data,
            });
        }
    }

    // process CbSwap from pool to initiate another swap request
    receive(msg: CbSwap) {
        let ctx: Context = context();
        let swapNext = msg.next;
        let fwdFee: Int = ctx.readForwardFee();
        if (fwdFee * 6 > ctx.value || msg.tokenWallet == swapNext.tokenAddress || self.locked) {
            let builder: Builder = beginCell().storeUint(0, 1);
            if (self.locked) {
                builder.storeUint(TRANSFER_BOUNCE_LOCKED, 32);
            } else {
                builder.storeUint(TRANSFER_BOUNCE_INVALID_REQUEST, 32);
            }
            let body = TokenTransfer {
                queryId: msg.queryId,
                amount: msg.amount,
                destination: msg.fromUserAddress,
                responseDestination: msg.fromUserAddress,
                customPayload: null,
                forwardTonAmount: 0,
                forwardPayload: builder.endCell(),
            };
            send(SendParameters{
                to: msg.tokenWallet,
                value: 0,
                mode: SendRemainingValue,
                body: body.toCell(),
            });
        } else {
            let init = self.getPoolStateInit(msg.tokenWallet, swapNext.tokenAddress);
            let poolAddress = contractAddress(init);
            let next: SwapNext? = null;
            if (swapNext.next != null) {
                next = SwapNext.fromCell(swapNext.next);
            }
            let body = Swap {
                queryId: msg.queryId,
                fromUserAddress: msg.fromUserAddress,
                tokenWallet: msg.tokenWallet,
                amount: msg.amount,
                minOut: swapNext.minOut,
                fromRealUser: msg.fromRealUser,
                refAddress: msg.refAddress,
                refMessageValue: msg.refMessageValue,
                next,
            };
            send(SendParameters{
                to: poolAddress,
                value: 0,
                mode: SendRemainingValue,
                body: body.toCell(),
                code: init.code,
                data: init.data,
            });
        }
    }

    // set pool fees
    receive(msg: SetFees) {
        nativeThrowUnless(ONLY_ADMIN, sender() == self.adminAddress);
        let poolAddress = self.getPoolAddress(msg.jettonWallet0, msg.jettonWallet1);
        let body = SetFeesFromRouter{
            queryId: msg.queryId,
            newLpFee: msg.newLpFee,
            newProtocolFee: msg.newProtocolFee,
            newRefFee: msg.newRefFee,
            newProtocolFeeAddress: msg.newProtocolFeeAddress,
        };
        send(SendParameters{
            to: poolAddress,
            value: 0,
            mode: SendRemainingValue,
            body: body.toCell(),
        });
    }

    // collect fees from pool
    receive(msg: CollectFees) {
        nativeThrowUnless(ONLY_ADMIN, sender() == self.adminAddress);
        let poolAddress = self.getPoolAddress(msg.jettonWallet0, msg.jettonWallet1);
        let body = CollectFeesFromRouter{
            queryId: msg.queryId,
        };
        send(SendParameters{
            to: poolAddress,
            value: 0,
            mode: SendRemainingValue,
            body: body.toCell(),
        });
    }

    // lock swap & provide-lp operations
    receive(msg: Lock) {
        nativeThrowUnless(ONLY_ADMIN, sender() == self.adminAddress);
        self.locked = true;
    }

    // unlock swap & provide-lp operations
    receive(msg: Unlock) {
        nativeThrowUnless(ONLY_ADMIN, sender() == self.adminAddress);
        self.locked = false;
    }

    // send excessive balance to admin
    receive(msg: RouterResetGas) {
        nativeThrowUnless(ONLY_ADMIN, sender() == self.adminAddress);
        send(SendParameters{
            to: self.adminAddress,
            value: myBalance() - REQUIRED_TON_RESERVE,
            mode: 0,
        });
    }

    // request pool to forward its excessive balance to admin
    receive(msg: ResetPoolGas) {
        nativeThrowUnless(ONLY_ADMIN, sender() == self.adminAddress);
        let poolAddress = self.getPoolAddress(msg.jettonWallet0, msg.jettonWallet1);
        let body = ResetPoolGasFromRouter{
            queryId: msg.queryId,
        };
        send(SendParameters{
            to: poolAddress,
            value: 0,
            mode: SendRemainingValue,
            body: body.toCell(),
        });
    }

    // compute and return pool address; for external contract use
    receive(msg: GetterPoolAddress) {
        nativeReserve(0, ReserveAddOriginalBalance);
        nativeThrowIf(WRONG_ADDRESS, msg.token0 == msg.token1);

        let poolAddress = self.getPoolAddress(msg.token0, msg.token1);
        let body = PoolAddress {
            queryId: msg.queryId,
            poolAddress,
        };
        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingBalance,
            body: body.toCell(),
        });
    }

    // initiate code upgrade
    receive(msg: InitCodeUpgrade) {
        nativeThrowUnless(ONLY_ADMIN, sender() == self.adminAddress);
        nativeThrowUnless(INVALID_CALL, self.tempUpgrade.endCode == 0);
        self.tempUpgrade.code = msg.code;
        self.tempUpgrade.endCode = now() + TWODAYS;
    }

    // initiate admin upgrade
    receive(msg: InitAdminUpgrade) {
        nativeThrowUnless(ONLY_ADMIN, sender() == self.adminAddress);
        nativeThrowUnless(INVALID_CALL, self.tempUpgrade.endAdmin == 0);
        self.tempUpgrade.admin = msg.admin;
        self.tempUpgrade.endAdmin = now() + TWODAYS;
    }

    // cancel admin upgrade
    receive(msg: CancelAdminUpgrade) {
        nativeThrowUnless(ONLY_ADMIN, sender() == self.adminAddress);
        nativeThrowUnless(INVALID_CALL, self.tempUpgrade.endAdmin > 0);
        self.tempUpgrade.admin = null;
        self.tempUpgrade.endAdmin = 0;
    }

    // cancel code upgrade
    receive(msg: CancelCodeUpgrade) {
        nativeThrowUnless(ONLY_ADMIN, sender() == self.adminAddress);
        nativeThrowUnless(INVALID_CALL, self.tempUpgrade.endCode > 0);
        self.tempUpgrade.code = null;
        self.tempUpgrade.endCode = 0;
    }

    // apply code & admin upgrade; should be called after the waiting period ends
    receive(msg: FinalizeUpgrades) {
        nativeThrowUnless(ONLY_ADMIN, sender() == self.adminAddress);
        nativeThrowUnless(INVALID_CALL, self.tempUpgrade.endCode +  self.tempUpgrade.endAdmin > 0);

        if (self.tempUpgrade.endCode > 0 && now() >= self.tempUpgrade.endCode) {
            setCode(self.tempUpgrade.code!!);
            self.tempUpgrade.endCode = 0;
            self.tempUpgrade.code = null;
        }

        if (self.tempUpgrade.endAdmin > 0 && now() >= self.tempUpgrade.endAdmin) {
            self.adminAddress = self.tempUpgrade.admin!!;
            self.tempUpgrade.endAdmin = 0;
            self.tempUpgrade.admin = null;
        }
    }
}
