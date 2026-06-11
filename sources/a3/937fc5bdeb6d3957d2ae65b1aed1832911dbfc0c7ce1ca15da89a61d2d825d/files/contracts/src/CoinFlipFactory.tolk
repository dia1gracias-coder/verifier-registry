import "types"

contract CoinFlipFactory {
    author: "TON Coin Flip"
    version: "0.2.0"
    description: "Coin-flip platform: creates per-game escrow contracts, holds platform params"
    storage: FactoryStorage
    incomingMessages: AllowedFactoryMessage
}

type AllowedFactoryMessage =
    | CreateGame
    | SetFee
    | SetLimits
    | SetTreasury
    | SetPaused
    | SetGameCode
    | ProposeAdmin
    | ClaimAdmin
    | CancelAdminTransfer

fun assertSenderIsAdmin(senderAddress: address, admin: address) {
    assert (senderAddress == admin) throw Errors.NotAdmin;
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedFactoryMessage.fromSlice(in.body);

    match (msg) {
        CreateGame => {
            var storage = FactoryStorage.load();
            assert (!storage.paused) throw Errors.GamePaused;
            assert (
                msg.stake >= storage.minStake && msg.stake <= storage.maxStake
            ) throw Errors.InvalidStake;
            assert (in.valueCoins >= msg.stake + CREATE_GAS_RESERVE) throw Errors.InsufficientValue;

            val gameId = storage.gamesCount;
            storage.gamesCount += 1;
            storage.save();

            val joinDeadline = (blockchain.now() + storage.joinTimeout) as uint32;
            // Snapshot of platform params: later admin changes must not affect this game
            val initialGameStorage: GameStorage = {
                config: GameConfig {
                    gameId,
                    factory: contract.getAddress(),
                    creator: in.senderAddress,
                    stake: msg.stake,
                    aSideHeads: msg.aSideHeads,
                    feeBps: storage.feeBps,
                    revealTimeout: storage.revealTimeout,
                    joinDeadline,
                    ext: GameConfigExt {
                        commitment: msg.commitment,
                        treasury: storage.treasury,
                    }.toCell(),
                }.toCell(),
                status: STATUS_CREATED,
                opponent: null,
                seedB: 0,
                revealDeadline: 0,
            };
            val gameDeploy: AutoDeployAddress = {
                stateInit: { code: storage.gameCode, data: initialGameStorage.toCell() },
            };

            val ev = createExternalLogMessage({
                dest: ExtOutLogBucket { topic: TOPIC_GAME_CREATED },
                body: EvGameCreated {
                    gameId,
                    game: gameDeploy.calculateAddress(),
                    creator: in.senderAddress,
                    stake: msg.stake,
                    joinDeadline,
                },
            });
            ev.send(SEND_MODE_REGULAR);

            // Forward the full remaining message value (stake escrow + gas buffer)
            val deployMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: gameDeploy,
                value: 0,
            });
            deployMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        SetFee => {
            var storage = FactoryStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.admin());
            assert (msg.feeBps <= MAX_FEE_BPS) throw Errors.FeeTooHigh;
            storage.feeBps = msg.feeBps;
            storage.save();
        }

        SetLimits => {
            var storage = FactoryStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.admin());
            assert (msg.minStake > 0 && msg.minStake <= msg.maxStake) throw Errors.InvalidLimits;
            assert (msg.joinTimeout > 0 && msg.revealTimeout > 0) throw Errors.InvalidLimits;
            storage.minStake = msg.minStake;
            storage.maxStake = msg.maxStake;
            storage.joinTimeout = msg.joinTimeout;
            storage.revealTimeout = msg.revealTimeout;
            storage.save();
        }

        SetTreasury => {
            var storage = FactoryStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.admin());
            storage.treasury = msg.treasury;
            storage.save();
        }

        SetPaused => {
            var storage = FactoryStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.admin());
            storage.paused = msg.paused;
            storage.save();
        }

        SetGameCode => {
            // Affects only games created after this point (constitution VIII)
            var storage = FactoryStorage.load();
            assertSenderIsAdmin(in.senderAddress, storage.admin());
            storage.gameCode = msg.code;
            storage.save();
        }

        ProposeAdmin => {
            // Step 1 of admin handover: the current admin nominates a successor
            // (e.g. a multisig). Control does not move until the successor claims.
            var storage = FactoryStorage.load();
            var gov = storage.gov.load();
            assert (in.senderAddress == gov.admin) throw Errors.NotAdmin;
            gov.pendingAdmin = msg.newAdmin;
            storage.gov = gov.toCell();
            storage.save();
        }

        ClaimAdmin => {
            // Step 2: only the nominated successor can accept, which proves the
            // new address is reachable and avoids handing control to a typo.
            var storage = FactoryStorage.load();
            var gov = storage.gov.load();
            assert (gov.pendingAdmin != null) throw Errors.NoPendingAdmin;
            assert (in.senderAddress == gov.pendingAdmin!) throw Errors.NotPendingAdmin;
            gov.admin = gov.pendingAdmin!;
            gov.pendingAdmin = null;
            storage.gov = gov.toCell();
            storage.save();
        }

        CancelAdminTransfer => {
            var storage = FactoryStorage.load();
            var gov = storage.gov.load();
            assert (in.senderAddress == gov.admin) throw Errors.NotAdmin;
            gov.pendingAdmin = null;
            storage.gov = gov.toCell();
            storage.save();
        }

        else => {
            // Plain TON transfers are accepted as a balance top-up
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
        }
    }
}

fun onBouncedMessage(_in: InMessageBounced) {}

get fun factoryData(): FactoryStorage {
    return FactoryStorage.load();
}

get fun gamesCount(): int {
    val storage = FactoryStorage.load();
    return storage.gamesCount;
}

get fun governance(): GovernanceData {
    val storage = FactoryStorage.load();
    val gov = storage.gov.load();
    return {
        admin: gov.admin,
        pendingAdmin: gov.pendingAdmin,
        treasury: storage.treasury,
    };
}
