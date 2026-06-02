tolk 1.3

import "errors"
import "storage"
import "messages"
import "signatures"
import "events"
import "fees"

const DOMAIN_CREATE_GAME: string = ":createGame"
const DOMAIN_CASH_OUT: string = ":cashOut"
const DOMAIN_MARK_LOST: string = ":markLost"

fun onInternalMessage(in: InMessage) {
    if (in.body.isEmpty()) {
        emitDepositReceived(in.senderAddress, in.valueCoins);
        return;
    }

    val msg = Incoming.fromSlice(in.body);
    match (msg) {
        AddAdminPubkey => {
            var storage = ContractStorage.load();
            assertSenderIsOwner(in.senderAddress, storage.owner);
            var dicts = storage.loadDicts();
            assert (dicts.adminPubkeys.addIfNotExists(msg.pubkey, true)) throw ERR_ADMIN_ALREADY_EXISTS;
            storage.saveDicts(dicts);
            storage.save();
            emitAdminAdded(msg.queryId, msg.pubkey);
        }
        RemoveAdminPubkey => {
            var storage = ContractStorage.load();
            assertSenderIsOwner(in.senderAddress, storage.owner);
            var dicts = storage.loadDicts();
            assert (dicts.adminPubkeys.delete(msg.pubkey)) throw ERR_ADMIN_NOT_FOUND;
            storage.saveDicts(dicts);
            storage.save();
            emitAdminRemoved(msg.queryId, msg.pubkey);
        }
        ChangeOwner => {
            var storage = ContractStorage.load();
            assertSenderIsOwner(in.senderAddress, storage.owner);
            storage.nextOwner = msg.newOwner;
            storage.save();
        }
        ClaimOwner => {
            var storage = ContractStorage.load();
            assert (storage.nextOwner != null) throw ERR_NO_PENDING_OWNER;
            assert (in.senderAddress == storage.nextOwner) throw ERR_NOT_NEXT_OWNER;
            val previousOwner = storage.owner;
            storage.owner = storage.nextOwner;
            storage.nextOwner = null;
            storage.save();
            emitOwnershipTransferred(msg.queryId, previousOwner, storage.owner);
        }
        DropOwner => {
            var storage = ContractStorage.load();
            assertSenderIsOwner(in.senderAddress, storage.owner);
            val previousOwner = storage.owner;
            storage.owner = null;
            storage.nextOwner = null;
            storage.save();
            emitOwnershipTransferred(msg.queryId, previousOwner, null);
        }
        SetMessagePrefix => {
            var storage = ContractStorage.load();
            assertSenderIsOwner(in.senderAddress, storage.owner);
            assertFlatString(msg.newPrefix);
            storage.messagePrefix = msg.newPrefix;
            storage.save();
            emitMessagePrefixChanged(msg.queryId);
        }
        RegisterAcceptedJetton => {
            var storage = ContractStorage.load();
            assertSenderIsOwner(in.senderAddress, storage.owner);
            var dicts = storage.loadDicts();
            dicts.acceptedJettonWallets.set(msg.jettonMasterHash, msg.ourJettonWalletAddress);
            storage.saveDicts(dicts);
            storage.save();
        }
        WithdrawFunds => {
            handleWithdraw(in.senderAddress, in.valueCoins, msg);
        }
        ProposeUpgrade => {
            var storage = ContractStorage.load();
            assertSenderIsOwner(in.senderAddress, storage.owner);
            storage.pendingUpgrade = (PendingUpgrade {
                newCode: msg.newCode,
                executeAfter: (blockchain.now() + UPGRADE_TIMELOCK_SECS) as uint32,
            }).toCell();
            storage.save();
        }
        ExecuteUpgrade => {
            var storage = ContractStorage.load();
            assertSenderIsOwner(in.senderAddress, storage.owner);
            assert (storage.pendingUpgrade != null) throw ERR_NO_PENDING_UPGRADE;
            val pending = storage.pendingUpgrade!.load();
            assert (blockchain.now() >= pending.executeAfter) throw ERR_UPGRADE_TOO_EARLY;
            storage.pendingUpgrade = null;
            storage.save();
            contract.setCodePostponed(pending.newCode);
        }
        CancelUpgrade => {
            var storage = ContractStorage.load();
            assertSenderIsOwner(in.senderAddress, storage.owner);
            storage.pendingUpgrade = null;
            storage.save();
        }
        CreateNativeGame  => { handleCreateNativeGame(in.senderAddress, in.valueCoins, msg); }
        CreateZeroBetGame => { handleCreateZeroBetGame(in.senderAddress, in.valueCoins, msg); }
        CashOut           => { handleCashOut(in.senderAddress, in.valueCoins, msg); }
        MarkLost          => { handleMarkLost(in.senderAddress, in.valueCoins, msg); }
        JettonNotify      => { handleJettonNotify(in.senderAddress, in.valueCoins, msg); }
    }
}

fun handleWithdraw(senderAddress: address, valueCoins: coins, msg: WithdrawFunds) {
    val storage = ContractStorage.load();
    assertSenderIsOwner(senderAddress, storage.owner);
    assert (msg.amount > 0) throw ERR_INSUFFICIENT_VALUE;
    if (msg.jettonMasterHash == null) {
        val available = contract.getOriginalBalance() - MIN_TREASURY_RESERVE;
        assert (msg.amount <= available) throw ERR_INSUFFICIENT_BALANCE;
        createMessage({
            bounce: BounceMode.NoBounce,
            value: msg.amount,
            dest: msg.recipient,
        }).send(SEND_MODE_PAY_FEES_SEPARATELY);
    } else {
        val dicts = storage.loadDicts();
        val r = dicts.acceptedJettonWallets.get(msg.jettonMasterHash!);
        assert (r.isFound) throw ERR_JETTON_NOT_ACCEPTED;
        val ourJW = r.loadValue();
        createMessage({
            bounce: BounceMode.RichBounce,
            value: GAS_FOR_JETTON_PAYOUT as coins,
            dest: ourJW,
            body: JettonTransferOut {
                queryId: msg.queryId,
                amount: msg.amount,
                destination: msg.recipient,
                responseDestination: contract.getAddress(),
                customPayload: null,
                forwardTonAmount: 0 as coins,
                forwardPayload: createEmptyForwardPayload(),
            },
        }).send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
    }
}

// Empty forward payload (no forward notification on the receiving jetton wallet).
fun createEmptyForwardPayload(): RemainingBitsAndRefs {
    return beginCell().endCell().beginParse() as RemainingBitsAndRefs;
}

// Verifies sig + domain hash + deadline; returns decoded inputs and body.
fun verifyCreate(inputsCell: Cell<CreateGameInputs>, signature: bits512,
                 signerPubkey: uint256, storage: ContractStorage): (CreateGameInputs, CreateGameBody) {
    val dicts = storage.loadDicts();
    val inputs = inputsCell.load();
    val body = inputs.body.load();
    verifyAdminSignature(inputsCell.hash(), signature, signerPubkey, dicts);
    assert (inputs.domainHash == buildDomainHash(storage.messagePrefix, DOMAIN_CREATE_GAME)) throw ERR_INVALID_SIGNATURE;
    assert (blockchain.now() <= inputs.deadline) throw ERR_DEADLINE_EXPIRED;
    return (inputs, body);
}

// Inserts game record into the games map; throws ERR_GAME_ALREADY_EXISTS on duplicate.
fun insertGame(mutate storage: ContractStorage, inputs: CreateGameInputs, body: CreateGameBody,
               isNative: bool, jettonMasterHash: uint256?) {
    var dicts = storage.loadDicts();
    val game = (Game {
        player: body.player,
        betAmount: body.betAmount,
        createdAt: blockchain.now() as uint32,
        isNative: isNative,
        creditKind: body.creditKind,
        jettonMasterHash: jettonMasterHash,
        gameSeedHash: inputs.gameSeedHash,
    }).toCell();
    assert (dicts.games.addIfNotExists(inputs.preliminaryGameIdHash, game)) throw ERR_GAME_ALREADY_EXISTS;
    storage.saveDicts(dicts);
    emitGameCreated(GameCreatedLog {
        preliminaryGameIdHash: inputs.preliminaryGameIdHash,
        player: body.player,
        extra: (GameCreatedLogExtra {
            betAmount: body.betAmount,
            isNative: isNative,
            creditKind: body.creditKind,
            jettonMasterHash: jettonMasterHash,
            gameSeedHash: inputs.gameSeedHash,
            algoVersion: body.algoVersion,
            gameConfig: body.gameConfig,
        }).toCell(),
    });
}

// --- resolve helpers ---

// Loads + removes the active game, verifying the reveal matches the commitment.
fun resolveGame(mutate storage: ContractStorage, prelimHash: uint256, reveal: ResolveReveal): Game {
    var dicts = storage.loadDicts();
    val r = dicts.games.get(prelimHash);
    assert (r.isFound) throw ERR_GAME_NOT_FOUND;
    val game = Game.fromCell(r.loadValue());
    val expected = computeSeedCommitmentHash(reveal.gameSeed, reveal.gameConfig, reveal.algoVersion);
    assert (expected == game.gameSeedHash) throw ERR_SEED_HASH_MISMATCH;
    dicts.games.delete(prelimHash);
    storage.saveDicts(dicts);
    return game;
}

// Refund the relayer's unused gas; treasury keeps its prior (pre-message) balance.
fun refundRelayer(relayer: address) {
    reserveToncoinsOnBalance(0, RESERVE_MODE_EXACT_AMOUNT | RESERVE_MODE_INCREASE_BY_ORIGINAL_BALANCE | RESERVE_MODE_BOUNCE_ON_ACTION_FAIL);
    createMessage({ bounce: BounceMode.NoBounce, value: 0 as coins, dest: relayer }).send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS);
}

// --- game-op handlers ---
fun handleCreateNativeGame(senderAddress: address, valueCoins: coins, msg: CreateNativeGame) {
    var storage = ContractStorage.load();
    val (inputs, body) = verifyCreate(msg.inputs, msg.signature, msg.signerPubkey, storage);
    assert (body.betAmount > 0) throw ERR_WRONG_OPCODE;
    assert (body.jettonMasterHash == null) throw ERR_WRONG_OPCODE;
    assert (valueCoins >= body.betAmount + GAS_CREATE) throw ERR_INSUFFICIENT_VALUE;
    insertGame(mutate storage, inputs, body, true, null);
    storage.save();
    // Reserve original balance + incoming bet; refund unused gas overpay to the relayer.
    reserveToncoinsOnBalance(body.betAmount, RESERVE_MODE_EXACT_AMOUNT | RESERVE_MODE_INCREASE_BY_ORIGINAL_BALANCE | RESERVE_MODE_BOUNCE_ON_ACTION_FAIL);
    createMessage({ bounce: BounceMode.NoBounce, value: 0 as coins, dest: senderAddress })
        .send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS);
}
fun handleCreateZeroBetGame(senderAddress: address, valueCoins: coins, msg: CreateZeroBetGame) {
    var storage = ContractStorage.load();
    val (inputs, body) = verifyCreate(msg.inputs, msg.signature, msg.signerPubkey, storage);
    assert (body.betAmount == 0) throw ERR_WRONG_OPCODE;
    assert (body.jettonMasterHash == null) throw ERR_WRONG_OPCODE;
    assert (valueCoins >= GAS_CREATE) throw ERR_INSUFFICIENT_VALUE;
    insertGame(mutate storage, inputs, body, true, null);  // isNative=true bookkeeping; no funds move
    storage.save();
    refundRelayer(senderAddress);
}

fun handleCashOut(senderAddress: address, valueCoins: coins, msg: CashOut) {
    var storage = ContractStorage.load();
    val dicts0 = storage.loadDicts();
    val inputs = msg.inputs.load();
    verifyAdminSignature(msg.inputs.hash(), msg.signature, msg.signerPubkey, dicts0);
    assert (inputs.domainHash == buildDomainHash(storage.messagePrefix, DOMAIN_CASH_OUT)) throw ERR_INVALID_SIGNATURE;
    assert (blockchain.now() <= inputs.deadline) throw ERR_DEADLINE_EXPIRED;
    assert (valueCoins >= GAS_RESOLVE) throw ERR_INSUFFICIENT_VALUE;

    val reveal = inputs.reveal.load();
    val game = resolveGame(mutate storage, inputs.preliminaryGameIdHash, reveal);

    // Funded games are resolved by the player; sponsored games by the backend relayer.
    if (game.betAmount > 0) {
        assert (senderAddress == game.player) throw ERR_NOT_GAME_PLAYER;
    }
    storage.save();

    emitGameStatusUpdated(GameStatusUpdatedLog {
        preliminaryGameIdHash: inputs.preliminaryGameIdHash,
        status: GameStatus.Won as uint8,
        reveal: (GameStatusUpdatedLogReveal {
            gameSeed: reveal.gameSeed,
            gameState: reveal.gameState,
        }).toCell(),
    });

    if (game.betAmount == 0) { refundRelayer(senderAddress); return; }

    if (game.isNative) {
        if (inputs.payoutAmount > 0) {
            // Compute-phase check so the action phase cannot fail (no bounce needed).
            assert (contract.getOriginalBalance() >= inputs.payoutAmount + MIN_TREASURY_RESERVE) throw ERR_INSUFFICIENT_BALANCE;
            createMessage({ bounce: BounceMode.NoBounce, value: inputs.payoutAmount, dest: game.player })
                .send(SEND_MODE_PAY_FEES_SEPARATELY);
            emitPayoutSent(PayoutSentLog {
                preliminaryGameIdHash: inputs.preliminaryGameIdHash,
                player: game.player,
                amount: inputs.payoutAmount,
            });
        }
        // Reserve = original_balance - payoutAmount, then refund the remainder to the relayer.
        reserveToncoinsOnBalance(inputs.payoutAmount, RESERVE_MODE_EXACT_AMOUNT | RESERVE_MODE_INCREASE_BY_ORIGINAL_BALANCE | RESERVE_MODE_NEGATE_AMOUNT | RESERVE_MODE_BOUNCE_ON_ACTION_FAIL);
        createMessage({ bounce: BounceMode.NoBounce, value: 0 as coins, dest: senderAddress }).send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS);
    } else {
        handleJettonPayout(senderAddress, game, inputs.preliminaryGameIdHash, inputs.payoutAmount, msg.queryId);
    }
}

fun handleJettonPayout(senderAddress: address, game: Game, prelimHash: uint256, payoutAmount: coins, queryId: uint64) {
    if (payoutAmount > 0) {
        val dicts = ContractStorage.load().loadDicts();
        val r = dicts.acceptedJettonWallets.get(game.jettonMasterHash!);
        assert (r.isFound) throw ERR_JETTON_NOT_ACCEPTED;
        val ourJW = r.loadValue();
        // Snapshot of the pruned game, carried in customPayload so a bounce can re-insert it.
        val restore = beginCell().storeUint(prelimHash, 256).storeRef(game.toCell() as cell).endCell();
        createMessage({
            bounce: BounceMode.RichBounce,
            value: GAS_FOR_JETTON_PAYOUT as coins,
            dest: ourJW,
            body: JettonTransferOut {
                queryId,
                amount: payoutAmount,
                destination: game.player,
                responseDestination: contract.getAddress(),
                customPayload: restore,
                forwardTonAmount: 0 as coins,
                forwardPayload: createEmptyForwardPayload(),
            },
        }).send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
        emitPayoutSent(PayoutSentLog {
            preliminaryGameIdHash: prelimHash,
            player: game.player,
            amount: payoutAmount,
        });
    }
    refundRelayer(senderAddress);
}

fun handleMarkLost(senderAddress: address, valueCoins: coins, msg: MarkLost) {
    var storage = ContractStorage.load();
    val dicts0 = storage.loadDicts();
    val inputs = msg.inputs.load();
    verifyAdminSignature(msg.inputs.hash(), msg.signature, msg.signerPubkey, dicts0);
    assert (inputs.domainHash == buildDomainHash(storage.messagePrefix, DOMAIN_MARK_LOST)) throw ERR_INVALID_SIGNATURE;
    assert (blockchain.now() <= inputs.deadline) throw ERR_DEADLINE_EXPIRED;
    assert (valueCoins >= GAS_RESOLVE) throw ERR_INSUFFICIENT_VALUE;

    val reveal = inputs.reveal.load();
    val game = resolveGame(mutate storage, inputs.preliminaryGameIdHash, reveal);
    storage.save();

    emitGameStatusUpdated(GameStatusUpdatedLog {
        preliminaryGameIdHash: inputs.preliminaryGameIdHash,
        status: GameStatus.Lost as uint8,
        reveal: (GameStatusUpdatedLogReveal {
            gameSeed: reveal.gameSeed,
            gameState: reveal.gameState,
        }).toCell(),
    });
    // Loss: native/jetton bets already in treasury (house keeps them); credit is BE-only.
    refundRelayer(senderAddress);
}
fun handleJettonNotify(senderAddress: address, valueCoins: coins, msg: JettonNotify) {
    var storage = ContractStorage.load();
    var dicts = storage.loadDicts();

    // Forward payload either-bit: 1 = request stored in a ref. Parse explicitly.
    var fwd = msg.forwardPayload;
    assert (fwd.loadBool()) throw ERR_WRONG_OPCODE;
    val req = CreateJettonGameRequest.fromCell(fwd.loadRef());

    val inputs = req.inputs.load();
    val body = inputs.body.load();

    // Authenticate the jetton wallet BEFORE trusting anything. Anyone can send a
    // fake notify; only our registered wallet has custody of the player's jettons.
    assert (body.jettonMasterHash != null) throw ERR_JETTON_NOT_ACCEPTED;
    val r = dicts.acceptedJettonWallets.get(body.jettonMasterHash!);
    assert (r.isFound) throw ERR_JETTON_NOT_ACCEPTED;
    assert (senderAddress == r.loadValue()) throw ERR_FAKE_JETTON_WALLET;

    // Validate as a single boolean (gas check included) so any failure REFUNDS:
    // the jettons already left the player's wallet, so throwing would strand them.
    val ok =
        inputs.domainHash == buildDomainHash(storage.messagePrefix, DOMAIN_CREATE_GAME)
        && dicts.adminPubkeys.exists(req.signerPubkey)
        && isSignatureValid(req.inputs.hash(), req.signature as slice, req.signerPubkey)
        && blockchain.now() <= inputs.deadline
        && body.betAmount > 0
        && msg.amount == body.betAmount
        && msg.fromAddress == body.player
        && valueCoins >= GAS_CREATE
        && !dicts.games.exists(inputs.preliminaryGameIdHash);

    if (!ok) {
        // Refund the jettons back to the player from our wallet.
        createMessage({
            bounce: BounceMode.RichBounce,
            value: GAS_FOR_JETTON_PAYOUT as coins,
            dest: senderAddress,
            body: JettonTransferOut {
                queryId: msg.queryId,
                amount: msg.amount,
                destination: msg.fromAddress,
                responseDestination: contract.getAddress(),
                customPayload: null,
                forwardTonAmount: 0 as coins,
                forwardPayload: createEmptyForwardPayload(),
            },
        }).send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
        return;
    }

    insertGame(mutate storage, inputs, body, false, body.jettonMasterHash);
    storage.save();
    refundRelayer(msg.fromAddress);
}

fun onBouncedMessage(in: InMessageBounced) {
    // We only ever send RichBounce on outgoing JettonTransferOut. A bounce means
    // the transfer failed at our jetton wallet (e.g. insufficient jetton balance).
    val prefix = in.bouncedBody.preloadUint(32);
    if (prefix != 0xFFFFFFFE) {
        return;  // legacy / unexpected bounce shape — nothing to restore
    }
    val rich = lazy RichBounceBody.fromSlice(in.bouncedBody);

    // Recover the full original JettonTransferOut body.
    val orig = lazy JettonTransferOut.fromCell(rich.originalBody);

    // A payout carries a restore snapshot in customPayload; a refund carries null.
    if (orig.customPayload == null) {
        return;  // refund bounce: jettons already back with the player, nothing to do
    }
    var restore = orig.customPayload!.beginParse();
    val prelimHash = restore.loadUint(256);
    val gameCell = restore.loadRef();
    val game = Game.fromCell(gameCell);

    var storage = ContractStorage.load();
    var dicts = storage.loadDicts();
    // Re-insert the pruned game so the player can be paid on retry. addIfNotExists
    // keeps it idempotent if a duplicate bounce somehow arrives.
    dicts.games.addIfNotExists(prelimHash, gameCell as Cell<Game>);
    storage.saveDicts(dicts);
    storage.save();

    emitPayoutFailed(PayoutFailedLog {
        preliminaryGameIdHash: prelimHash as uint256,
        player: game.player,
        amount: orig.amount,
    });
}

// ---- getters ------------------------------------------------------------
get fun getOwner(): address? { return ContractStorage.load().owner; }
get fun getNextOwner(): address? { return ContractStorage.load().nextOwner; }
get fun getMessagePrefix(): string { return ContractStorage.load().messagePrefix; }
get fun isAdminPubkey(pubkey: uint256): bool {
    return ContractStorage.load().loadDicts().adminPubkeys.exists(pubkey);
}
get fun getGameExists(preliminaryGameIdHash: uint256): bool {
    return ContractStorage.load().loadDicts().games.exists(preliminaryGameIdHash);
}
// Active game record cell, or null if absent (resolved/never existed).
get fun getGame(preliminaryGameIdHash: uint256): cell? {
    val r = ContractStorage.load().loadDicts().games.get(preliminaryGameIdHash);
    return r.isFound ? r.loadValue() as cell : null;
}
get fun getDomainHashCreateGame(): uint256 {
    return buildDomainHash(ContractStorage.load().messagePrefix, DOMAIN_CREATE_GAME);
}
get fun getDomainHashCashOut(): uint256 {
    return buildDomainHash(ContractStorage.load().messagePrefix, DOMAIN_CASH_OUT);
}
get fun getDomainHashMarkLost(): uint256 {
    return buildDomainHash(ContractStorage.load().messagePrefix, DOMAIN_MARK_LOST);
}
