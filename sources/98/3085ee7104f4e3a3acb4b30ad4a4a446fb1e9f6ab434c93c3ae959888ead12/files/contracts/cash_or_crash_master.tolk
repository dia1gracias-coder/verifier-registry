tolk 1.3

import "errors"
import "storage"
import "messages"
import "events"
import "signatures"
import "fees"

const DOMAIN_CREATE_GAME: string = ":createGame"
const DOMAIN_CASH_OUT: string = ":cashOut"
const DOMAIN_MARK_LOST: string = ":markLost"

fun onInternalMessage(in: InMessage) {
    if (in.body.isEmpty()) {
        emitDepositReceived(in.senderAddress, in.valueCoins);
        return;
    }

    val msg = MasterIncoming.fromSlice(in.body);
    match (msg) {
        AddAdminPubkey => {
            var storage = MasterStorage.load();
            assertSenderIsOwner(in.senderAddress, storage.owner);
            var dicts = storage.loadDicts();
            assert (dicts.adminPubkeys.addIfNotExists(msg.pubkey, true)) throw ERR_ADMIN_ALREADY_EXISTS;
            storage.saveDicts(dicts);
            storage.save();
            emitAdminAdded(msg.queryId, msg.pubkey);
        }

        RemoveAdminPubkey => {
            var storage = MasterStorage.load();
            assertSenderIsOwner(in.senderAddress, storage.owner);
            var dicts = storage.loadDicts();
            assert (dicts.adminPubkeys.delete(msg.pubkey)) throw ERR_ADMIN_NOT_FOUND;
            storage.saveDicts(dicts);
            storage.save();
            emitAdminRemoved(msg.queryId, msg.pubkey);
        }

        ChangeOwner => {
            var storage = MasterStorage.load();
            assertSenderIsOwner(in.senderAddress, storage.owner);
            storage.nextOwner = msg.newOwner;
            storage.save();
        }

        ClaimOwner => {
            var storage = MasterStorage.load();
            assert (storage.nextOwner != null) throw ERR_NO_PENDING_OWNER;
            assert (in.senderAddress == storage.nextOwner) throw ERR_NOT_NEXT_OWNER;
            val previousOwner = storage.owner;
            storage.owner = storage.nextOwner;
            storage.nextOwner = null;
            storage.save();
            emitOwnershipTransferred(msg.queryId, previousOwner, storage.owner);
        }

        DropOwner => {
            var storage = MasterStorage.load();
            assertSenderIsOwner(in.senderAddress, storage.owner);
            val previousOwner = storage.owner;
            storage.owner = null;
            storage.nextOwner = null;
            storage.save();
            emitOwnershipTransferred(msg.queryId, previousOwner, null);
        }

        SetMessagePrefix => {
            var storage = MasterStorage.load();
            assertSenderIsOwner(in.senderAddress, storage.owner);
            storage.messagePrefix = msg.newPrefix;
            storage.save();
            emitMessagePrefixChanged(msg.queryId);
        }

        WithdrawFunds => {
            val storage = MasterStorage.load();
            assertSenderIsOwner(in.senderAddress, storage.owner);
            assert (msg.amount > 0) throw ERR_INSUFFICIENT_VALUE;

            if (msg.jettonMasterHash == null) {
                // Native withdraw — keep at least MIN_MASTER_STORAGE_RESERVE on balance.
                val available = contract.getOriginalBalance() - MIN_MASTER_STORAGE_RESERVE;
                assert (msg.amount <= available) throw ERR_INSUFFICIENT_BALANCE;
                createMessage({
                    bounce: BounceMode.NoBounce,
                    value: msg.amount,
                    dest: msg.recipient,
                }).send(SEND_MODE_PAY_FEES_SEPARATELY);
            } else {
                // Jetton withdraw via the registered master JW.
                val dicts = storage.loadDicts();
                val r = dicts.acceptedJettonWallets.get(msg.jettonMasterHash!);
                assert (r.isFound) throw ERR_JETTON_NOT_ACCEPTED;
                val masterJW = r.loadValue();
                createMessage({
                    bounce: BounceMode.RichBounce,
                    value: GAS_FOR_JETTON_PAYOUT as coins,
                    dest: masterJW,
                    body: JettonTransferOut {
                        queryId: msg.queryId,
                        amount: msg.amount,
                        destination: msg.recipient,
                        responseDestination: contract.getAddress(),
                        customPayload: null,
                        forwardTonAmount: 0 as coins,
                        forwardPayloadInRef: false,
                    },
                }).send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
            }
        }

        ProposeUpgrade => {
            var storage = MasterStorage.load();
            assertSenderIsOwner(in.senderAddress, storage.owner);
            storage.pendingUpgrade = (PendingUpgrade {
                newMasterCode: msg.newMasterCode,
                newGameWalletCode: msg.newGameWalletCode,
                executeAfter: (blockchain.now() + UPGRADE_TIMELOCK_SECS) as uint32,
            }).toCell();
            storage.save();
        }

        ExecuteUpgrade => {
            var storage = MasterStorage.load();
            assertSenderIsOwner(in.senderAddress, storage.owner);
            assert (storage.pendingUpgrade != null) throw ERR_NO_PENDING_UPGRADE;
            val pending = storage.pendingUpgrade!.load();
            assert (blockchain.now() >= pending.executeAfter) throw ERR_UPGRADE_TOO_EARLY;

            // Apply: optionally update game wallet code, clear pending,
            // and schedule master code swap (takes effect next tx).
            if (pending.newGameWalletCode != null) {
                storage.gameWalletCode = pending.newGameWalletCode!;
            }
            storage.pendingUpgrade = null;
            storage.save();
            contract.setCodePostponed(pending.newMasterCode);
        }

        CancelUpgrade => {
            var storage = MasterStorage.load();
            assertSenderIsOwner(in.senderAddress, storage.owner);
            storage.pendingUpgrade = null;
            storage.save();
        }

        RegisterAcceptedJetton => {
            var storage = MasterStorage.load();
            assertSenderIsOwner(in.senderAddress, storage.owner);
            var dicts = storage.loadDicts();
            dicts.acceptedJettonWallets.set(msg.jettonMasterHash, msg.masterJettonWalletAddress);
            storage.saveDicts(dicts);
            storage.save();
        }

        JettonNotification => {
            // Mandatory: forwardPayload must be in a ref (Right Cell).
            assert (msg.forwardPayloadInRef) throw ERR_WRONG_OPCODE;
            val req = msg.forwardPayload.load();
            val storage = MasterStorage.load();
            val dicts = storage.loadDicts();
            val inputs = req.inputs.load();
            val body = inputs.body.load();

            // Auth: signature over the inputs cell.
            verifyAdminSignature(req.inputs.hash(), req.signature, req.signerPubkey, dicts);
            assert (inputs.domainHash == buildDomainHash(storage.messagePrefix, DOMAIN_CREATE_GAME))
                throw ERR_INVALID_SIGNATURE;
            assert (blockchain.now() <= inputs.deadline) throw ERR_DEADLINE_EXPIRED;

            // Jetton-specific constraints.
            assert (!body.isCredit) throw ERR_WRONG_OPCODE;
            assert (body.jettonMasterHash != null) throw ERR_JETTON_NOT_ACCEPTED;
            // Sender must be the master's own jetton wallet for that jetton.
            val r = dicts.acceptedJettonWallets.get(body.jettonMasterHash!);
            assert (r.isFound) throw ERR_JETTON_NOT_ACCEPTED;
            val expectedJW = r.loadValue();
            assert (in.senderAddress == expectedJW) throw ERR_FAKE_JETTON_WALLET;
            // Bet amount and player address must match the signed payload.
            assert (msg.amount == body.betAmount) throw ERR_INSUFFICIENT_VALUE;
            assert (msg.fromAddress == body.player) throw ERR_NOT_GAME_PLAYER;
            // Need enough native gas attached (alongside the jetton transfer)
            // to cover the deploy + InitGame compute + storage reserve.
            assert (in.valueCoins >= GAS_FOR_NATIVE_CREATE) throw ERR_INSUFFICIENT_VALUE;

            // Deploy the game contract (isNative=false). Bet stays in master's
            // jetton wallet; game holds an IOU only.
            val betCfg = (BetConfig {
                betAmount: body.betAmount,
                createdAt: blockchain.now() as uint32,
                isNative: false,
                isCredit: false,
                creditKind: 0,
                jettonMasterHash: body.jettonMasterHash,
            }).toCell();
            val identity = (GameIdentity {
                preliminaryGameIdHash: inputs.preliminaryGameIdHash,
                gameSeedHash: inputs.gameSeedHash,
                algoVersion: body.algoVersion,
                gameConfig: body.gameConfig,
            }).toCell();
            val initialData = (GameInitialData {
                initFlag: false,
                masterAddress: contract.getAddress(),
                preliminaryGameIdHash: inputs.preliminaryGameIdHash,
            }).toCell() as cell;

            // Forward most of the inbound TON value to the child for deploy gas.
            createMessage({
                bounce: BounceMode.RichBounce,
                value: in.valueCoins - GAS_FOR_NATIVE_CREATE,
                dest: AutoDeployAddress {
                    workchain: BASECHAIN as int8,
                    stateInit: ContractState {
                        code: storage.gameWalletCode,
                        data: initialData,
                    },
                },
                body: InitGame {
                    queryId: msg.queryId,
                    player: body.player,
                    betConfig: betCfg,
                    identity: identity,
                },
            }).send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);

            var s2 = MasterStorage.load();
            s2.gameCounter += 1;
            s2.save();
        }

        RequestJettonPayout => {
            // Auth: sender must be the legitimate game contract.
            assertSenderIsGame(in.senderAddress, msg.preliminaryGameIdHash);
            val storage = MasterStorage.load();
            val dicts = storage.loadDicts();
            // Find master's jetton wallet for the requested jetton.
            val r = dicts.acceptedJettonWallets.get(msg.jettonMasterHash);
            assert (r.isFound) throw ERR_JETTON_NOT_ACCEPTED;
            val masterJW = r.loadValue();

            if (msg.payoutAmount > 0) {
                createMessage({
                    bounce: BounceMode.RichBounce,
                    value: GAS_FOR_JETTON_PAYOUT as coins,
                    dest: masterJW,
                    body: JettonTransferOut {
                        queryId: msg.queryId,
                        amount: msg.payoutAmount,
                        destination: msg.player,
                        responseDestination: contract.getAddress(),
                        customPayload: null,
                        forwardTonAmount: 0 as coins,
                        forwardPayloadInRef: false,
                    },
                }).send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
            }
        }

        CreateNativeGame => {
            var storage = MasterStorage.load();
            val dicts = storage.loadDicts();
            val inputs = msg.inputs.load();
            val body = inputs.body.load();

            // Auth: sig is over the inputs cell hash.
            verifyAdminSignature(msg.inputs.hash(), msg.signature, msg.signerPubkey, dicts);

            // Bind to current contract messagePrefix + this action.
            val expectedDomain = buildDomainHash(storage.messagePrefix, DOMAIN_CREATE_GAME);
            assert (inputs.domainHash == expectedDomain) throw ERR_INVALID_SIGNATURE;
            assert (blockchain.now() <= inputs.deadline) throw ERR_DEADLINE_EXPIRED;
            assert (!body.isCredit) throw ERR_WRONG_OPCODE;
            assert (body.jettonMasterHash == null) throw ERR_WRONG_OPCODE;
            assert (in.valueCoins >= body.betAmount + GAS_FOR_NATIVE_CREATE) throw ERR_INSUFFICIENT_VALUE;

            // Build the bet/identity cells for the child.
            val betCfg = (BetConfig {
                betAmount: body.betAmount,
                createdAt: blockchain.now() as uint32,
                isNative: true,
                isCredit: false,
                creditKind: 0,
                jettonMasterHash: null,
            }).toCell();
            val identity = (GameIdentity {
                preliminaryGameIdHash: inputs.preliminaryGameIdHash,
                gameSeedHash: inputs.gameSeedHash,
                algoVersion: body.algoVersion,
                gameConfig: body.gameConfig,
            }).toCell();

            // Deterministic deploy: child address = hash(stateInit) where
            // stateInit = (gameWalletCode, GameInitialData{false, master, prelimHash}).
            val initialData = (GameInitialData {
                initFlag: false,
                masterAddress: contract.getAddress(),
                preliminaryGameIdHash: inputs.preliminaryGameIdHash,
            }).toCell() as cell;

            createMessage({
                bounce: BounceMode.RichBounce,
                value: in.valueCoins - GAS_FOR_NATIVE_CREATE,
                dest: AutoDeployAddress {
                    workchain: BASECHAIN as int8,
                    stateInit: ContractState {
                        code: storage.gameWalletCode,
                        data: initialData,
                    },
                },
                body: InitGame {
                    queryId: msg.queryId,
                    player: body.player,
                    betConfig: betCfg,
                    identity: identity,
                },
            }).send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);

            storage.gameCounter += 1;
            storage.save();
        }

        CreateZeroBetGame => {
            var storage = MasterStorage.load();
            val dicts = storage.loadDicts();
            val inputs = msg.inputs.load();
            val body = inputs.body.load();

            verifyAdminSignature(msg.inputs.hash(), msg.signature, msg.signerPubkey, dicts);
            val expectedDomain = buildDomainHash(storage.messagePrefix, DOMAIN_CREATE_GAME);
            assert (inputs.domainHash == expectedDomain) throw ERR_INVALID_SIGNATURE;
            assert (blockchain.now() <= inputs.deadline) throw ERR_DEADLINE_EXPIRED;
            // Credit games carry no funds and no jetton routing.
            assert (body.isCredit) throw ERR_WRONG_OPCODE;
            assert (body.betAmount == 0) throw ERR_WRONG_OPCODE;
            assert (body.jettonMasterHash == null) throw ERR_WRONG_OPCODE;
            // Sufficient gas to cover deploy + storage reserve.
            assert (in.valueCoins >= GAS_FOR_NATIVE_CREATE) throw ERR_INSUFFICIENT_VALUE;

            val betCfg = (BetConfig {
                betAmount: 0 as coins,
                createdAt: blockchain.now() as uint32,
                isNative: true,                   // bookkeeping: not jetton-routed
                isCredit: true,
                creditKind: body.creditKind,
                jettonMasterHash: null,
            }).toCell();
            val identity = (GameIdentity {
                preliminaryGameIdHash: inputs.preliminaryGameIdHash,
                gameSeedHash: inputs.gameSeedHash,
                algoVersion: body.algoVersion,
                gameConfig: body.gameConfig,
            }).toCell();
            val initialData = (GameInitialData {
                initFlag: false,
                masterAddress: contract.getAddress(),
                preliminaryGameIdHash: inputs.preliminaryGameIdHash,
            }).toCell() as cell;

            createMessage({
                bounce: BounceMode.RichBounce,
                value: in.valueCoins - GAS_FOR_NATIVE_CREATE,
                dest: AutoDeployAddress {
                    workchain: BASECHAIN as int8,
                    stateInit: ContractState {
                        code: storage.gameWalletCode,
                        data: initialData,
                    },
                },
                body: InitGame {
                    queryId: msg.queryId,
                    player: body.player,
                    betConfig: betCfg,
                    identity: identity,
                },
            }).send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);

            storage.gameCounter += 1;
            storage.save();
        }

        CashOut => {
            val storage = MasterStorage.load();
            val dicts = storage.loadDicts();
            val inputs = msg.inputs.load();

            verifyAdminSignature(msg.inputs.hash(), msg.signature, msg.signerPubkey, dicts);
            val expectedDomain = buildDomainHash(storage.messagePrefix, DOMAIN_CASH_OUT);
            assert (inputs.domainHash == expectedDomain) throw ERR_INVALID_SIGNATURE;
            assert (blockchain.now() <= inputs.deadline) throw ERR_DEADLINE_EXPIRED;
            assert (in.valueCoins >= GAS_FOR_CASHOUT_RELAY) throw ERR_INSUFFICIENT_VALUE;

            createMessage({
                bounce: BounceMode.RichBounce,
                value: in.valueCoins - GAS_FOR_CASHOUT_RELAY,
                dest: inputs.gameContractAddr,
                body: CashOutForward {
                    queryId: msg.queryId,
                    payoutAmount: inputs.payoutAmount,
                    gameSeed: inputs.gameSeed,
                    gameState: inputs.gameState,
                },
            }).send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
        }

        MarkLost => {
            val storage = MasterStorage.load();
            val dicts = storage.loadDicts();
            val inputs = msg.inputs.load();

            verifyAdminSignature(msg.inputs.hash(), msg.signature, msg.signerPubkey, dicts);
            val expectedDomain = buildDomainHash(storage.messagePrefix, DOMAIN_MARK_LOST);
            assert (inputs.domainHash == expectedDomain) throw ERR_INVALID_SIGNATURE;
            assert (blockchain.now() <= inputs.deadline) throw ERR_DEADLINE_EXPIRED;
            assert (in.valueCoins >= GAS_FOR_CASHOUT_RELAY) throw ERR_INSUFFICIENT_VALUE;

            createMessage({
                bounce: BounceMode.RichBounce,
                value: in.valueCoins - GAS_FOR_CASHOUT_RELAY,
                dest: inputs.gameContractAddr,
                body: MarkLostForward {
                    queryId: msg.queryId,
                    gameSeed: inputs.gameSeed,
                    gameState: inputs.gameState,
                },
            }).send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
        }

        LostGameSweep => {
            // Auth: sender must match the deterministic game contract address.
            assertSenderIsGame(in.senderAddress, msg.preliminaryGameIdHash);
            // Funds credited automatically by TVM; nothing else to do.
        }

        RequestNativePayout => {
            // Auth: sender must be the legitimate game contract for that prelim hash.
            assertSenderIsGame(in.senderAddress, msg.preliminaryGameIdHash);

            if (msg.payoutAmount > 0) {
                createMessage({
                    bounce: BounceMode.RichBounce,
                    value: msg.payoutAmount,
                    dest: msg.player,
                }).send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
            }
        }
    }
}

// Helper: asserts that `senderAddress` matches the deterministic deploy
// address for `preliminaryGameIdHash` under this master's gameWalletCode.
fun assertSenderIsGame(senderAddress: address, preliminaryGameIdHash: uint256) {
    val storage = MasterStorage.load();
    val expectedInitData = (GameInitialData {
        initFlag: false,
        masterAddress: contract.getAddress(),
        preliminaryGameIdHash: preliminaryGameIdHash,
    }).toCell() as cell;
    val expectedAddr = (AutoDeployAddress {
        workchain: BASECHAIN as int8,
        stateInit: ContractState {
            code: storage.gameWalletCode,
            data: expectedInitData,
        },
    }).calculateAddress();
    assert (senderAddress == expectedAddr) throw ERR_NOT_FROM_GAME;
}

// Bounces from CreateNativeGame's deploy or from CashOut/MarkLost forwards.
// Phase-3 policy: log/no-op. The deploy-bounce refund path is covered by the
// game contract's own bounce handler — the bet TON returned to the master
// here just stays in the master treasury (the player's bet is retained as
// house revenue if their game contract refused to deploy, which can only
// happen if they reused a preliminaryGameId — explicitly a backend bug).
fun onBouncedMessage(in: InMessageBounced) {
    // No state to restore at the master level. Funds re-credited automatically.
}

// ---- getters ------------------------------------------------------------

get fun getOwner(): address? {
    val storage = MasterStorage.load();
    return storage.owner;
}

get fun getNextOwner(): address? {
    val storage = MasterStorage.load();
    return storage.nextOwner;
}

get fun getMessagePrefix(): string {
    val storage = MasterStorage.load();
    return storage.messagePrefix;
}

get fun getGameCounter(): int {
    val storage = MasterStorage.load();
    return storage.gameCounter;
}

get fun isAdminPubkey(pubkey: uint256): bool {
    val storage = MasterStorage.load();
    val dicts = storage.loadDicts();
    return dicts.adminPubkeys.exists(pubkey);
}

// Computes the deterministic address a game contract would have for a given
// preliminaryGameIdHash, given this master's gameWalletCode.
get fun calcGameAddress(preliminaryGameIdHash: uint256): address {
    val storage = MasterStorage.load();
    val initialData = (GameInitialData {
        initFlag: false,
        masterAddress: contract.getAddress(),
        preliminaryGameIdHash,
    }).toCell() as cell;
    return (AutoDeployAddress {
        workchain: BASECHAIN as int8,
        stateInit: ContractState {
            code: storage.gameWalletCode,
            data: initialData,
        },
    }).calculateAddress();
}

get fun getDomainHashCreateGame(): uint256 {
    val storage = MasterStorage.load();
    return buildDomainHash(storage.messagePrefix, DOMAIN_CREATE_GAME);
}

get fun getDomainHashCashOut(): uint256 {
    val storage = MasterStorage.load();
    return buildDomainHash(storage.messagePrefix, DOMAIN_CASH_OUT);
}

get fun getDomainHashMarkLost(): uint256 {
    val storage = MasterStorage.load();
    return buildDomainHash(storage.messagePrefix, DOMAIN_MARK_LOST);
}
