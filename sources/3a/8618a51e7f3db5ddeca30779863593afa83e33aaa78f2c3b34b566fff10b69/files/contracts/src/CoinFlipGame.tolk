import "types"

contract CoinFlipGame {
    author: "TON Coin Flip"
    version: "0.1.0"
    description: "Single coin-flip game: escrow, commit-reveal, payouts"
    storage: GameStorage
    incomingMessages: AllowedGameMessage
}

type AllowedGameMessage =
    | JoinGame
    | Reveal
    | ClaimTimeout
    | CancelGame

// Sends the platform fee and the winner payout, then destroys the game account.
// The carry-all + destroy mode sweeps the entire remaining balance (pot - fee
// plus any gas dust) to the winner, so no funds can ever be stranded here.
fun payoutAndDestroy(treasury: address, winner: address, fee: coins) {
    if (fee > 0) {
        val feeMsg = createMessage({
            bounce: BounceMode.NoBounce,
            dest: treasury,
            value: fee,
        });
        feeMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
    }
    val payoutMsg = createMessage({
        bounce: BounceMode.NoBounce,
        dest: winner,
        value: 0,
    });
    // SAFETY: the game is in a terminal state (status saved before any send) and
    // must end with a zero balance: the whole escrow minus fee belongs to the
    // winner, and destroying the account guarantees no funds can be stranded.
    // NoBounce ensures the payout lands even on an uninitialized wallet.
    payoutMsg.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_DESTROY);
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedGameMessage.fromSlice(in.body);

    match (msg) {
        JoinGame => {
            var storage = GameStorage.load();
            assert (storage.status == STATUS_CREATED) throw Errors.WrongState;
            val config = storage.config.load();
            assert (blockchain.now() <= config.joinDeadline) throw Errors.JoinDeadlinePassed;
            assert (in.senderAddress != config.creator) throw Errors.SelfPlayNotAllowed;
            assert (
                in.valueCoins >= config.stake + JOIN_GAS_RESERVE
            ) throw Errors.InsufficientValue;
            // The creator escrow must actually be on the balance: a game deployed
            // directly (bypassing the factory) with an unfunded stake must not be
            // joinable, or the joiner's money would back a phantom pot. The balance
            // at compute start already includes this message's value, so subtract
            // it to isolate the creator's contribution — this stays correct even
            // when the joiner overpays, so an overpayment can never mask a missing
            // creator stake.
            assert (
                contract.getOriginalBalance() - in.valueCoins >= config.stake
            ) throw Errors.EscrowUnderfunded;

            storage.opponent = in.senderAddress;
            storage.seedB = msg.seedB;
            storage.revealDeadline = (blockchain.now() + config.revealTimeout) as uint32;
            storage.status = STATUS_JOINED;
            storage.save();

            val ev = createExternalLogMessage({
                dest: ExtOutLogBucket { topic: TOPIC_GAME_JOINED },
                body: EvGameJoined {
                    gameId: config.gameId,
                    opponent: in.senderAddress,
                    seedB: msg.seedB,
                    revealDeadline: storage.revealDeadline,
                },
            });
            ev.send(SEND_MODE_REGULAR);

            // Return everything above stake + gas reserve to the joiner
            val excess = in.valueCoins - config.stake - JOIN_GAS_RESERVE;
            if (excess >= MIN_REFUND) {
                val refundMsg = createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: in.senderAddress,
                    value: excess,
                });
                refundMsg.send(SEND_MODE_REGULAR);
            }
        }

        Reveal => {
            var storage = GameStorage.load();
            assert (storage.status == STATUS_JOINED) throw Errors.WrongState;
            val config = storage.config.load();
            val ext = config.ext.load();
            assert (in.senderAddress == config.creator) throw Errors.NotCreator;
            assert (blockchain.now() <= storage.revealDeadline) throw Errors.RevealDeadlinePassed;
            assert (calcCommitment(msg.secretA) == ext.commitment) throw Errors.CommitmentMismatch;

            val coinIsHeads = calcCoinIsHeads(msg.secretA, storage.seedB);
            val winner = coinIsHeads == config.aSideHeads ? config.creator : storage.opponent!;
            val pot = 2 * config.stake;
            val fee = calcFee(pot, config.feeBps);

            storage.status = STATUS_SETTLED;
            storage.save();

            val ev = createExternalLogMessage({
                dest: ExtOutLogBucket { topic: TOPIC_GAME_SETTLED },
                body: EvGameSettled {
                    gameId: config.gameId,
                    coinIsHeads,
                    winner,
                    payout: pot - fee,
                    fee,
                },
            });
            ev.send(SEND_MODE_REGULAR);

            payoutAndDestroy(ext.treasury, winner, fee);
        }

        ClaimTimeout => {
            // Permissionless: anyone may finalize an expired game, the payout
            // always goes to the opponent (the creator forfeits by not revealing)
            var storage = GameStorage.load();
            assert (storage.status == STATUS_JOINED) throw Errors.WrongState;
            assert (
                blockchain.now() > storage.revealDeadline
            ) throw Errors.RevealDeadlineNotReached;
            val config = storage.config.load();
            val ext = config.ext.load();

            val winner = storage.opponent!;
            val pot = 2 * config.stake;
            val fee = calcFee(pot, config.feeBps);

            storage.status = STATUS_TIMED_OUT;
            storage.save();

            val ev = createExternalLogMessage({
                dest: ExtOutLogBucket { topic: TOPIC_GAME_TIMED_OUT },
                body: EvGameTimedOut {
                    gameId: config.gameId,
                    winner,
                    payout: pot - fee,
                    fee,
                },
            });
            ev.send(SEND_MODE_REGULAR);

            payoutAndDestroy(ext.treasury, winner, fee);
        }

        CancelGame => {
            var storage = GameStorage.load();
            assert (storage.status == STATUS_CREATED) throw Errors.WrongState;
            val config = storage.config.load();
            assert (in.senderAddress == config.creator) throw Errors.NotCreator;

            storage.status = STATUS_CANCELLED;
            storage.save();

            val ev = createExternalLogMessage({
                dest: ExtOutLogBucket { topic: TOPIC_GAME_CANCELLED },
                body: EvGameCancelled {
                    gameId: config.gameId,
                    refund: contract.getOriginalBalance(),
                },
            });
            ev.send(SEND_MODE_REGULAR);

            // Full refund, no fee on a game that never happened (constitution IX)
            val refundMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: config.creator,
                value: 0,
            });
            // SAFETY: status is CANCELLED (saved above) and the entire balance is
            // the creator's own escrow; sweeping it back and destroying the account
            // is the intended terminal outcome. NoBounce so the refund always lands.
            refundMsg.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_DESTROY);
        }

        else => {
            // Plain TON transfers (e.g. the factory deploy carrying the escrow) are accepted
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
        }
    }
}

fun onBouncedMessage(_in: InMessageBounced) {}

get fun gameData(): GameData {
    val storage = GameStorage.load();
    val config = storage.config.load();
    val ext = config.ext.load();
    return {
        gameId: config.gameId,
        factory: config.factory,
        creator: config.creator,
        stake: config.stake,
        commitment: ext.commitment,
        aSideHeads: config.aSideHeads,
        feeBps: config.feeBps,
        treasury: ext.treasury,
        joinDeadline: config.joinDeadline,
        status: storage.status,
        opponent: storage.opponent,
        seedB: storage.seedB,
        revealDeadline: storage.revealDeadline,
    };
}

get fun gameStatus(): int {
    val storage = GameStorage.load();
    return storage.status;
}
