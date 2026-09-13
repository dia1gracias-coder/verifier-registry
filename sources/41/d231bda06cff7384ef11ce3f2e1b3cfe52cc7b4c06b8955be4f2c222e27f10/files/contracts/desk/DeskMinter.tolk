import "../common/consts"
import "../common/errors"
import "../vendor/jetton/messages"
import "desk-messages"
import "../pot/pot-messages"

contract DeskMinter {
    author: "GRAMDESKS"
    version: "0.1.0"
    description: "Public mint: burns a fixed $DESK deposit, splits the TON surcharge between Pot and protocol, and asks the Collection to deploy the desk."
    storage: DeskMinterStorage
    incomingMessages: AllowedMessageToMinter
}

type AllowedMessageToMinter =
    | TransferNotificationForRecipient
    | DeployDeskOk
    | RetryDeploy
    | RetryBurn
    | SetDeskMinterPaused
    | SetDeskMinterConfig
    | ChangeDeskMinterAdmin
    | ReturnExcessesBack

const DEPLOY_MSG_VALUE = DESK_DEPLOY_VALUE + REGISTER_DESK_VALUE + ton("0.03")
const POT_TOPUP_SOURCE_MINT = 1

fun keepOwnBalance(incomingValue: coins) {
    val keep = max(contract.getOriginalBalance() - incomingValue, MIN_STORAGE_RESERVE);
    reserveToncoinsOnBalance(keep, RESERVE_MODE_AT_MOST);
}

fun returnDeposit(wallet: address, to: address, amount: coins, queryId: uint64, incomingValue: coins) {
    keepOwnBalance(incomingValue);
    val back = createMessage({
        bounce: BounceMode.NoBounce,
        dest: wallet,
        value: 0,
        body: AskToTransfer {
            queryId,
            jettonAmount: amount,
            transferRecipient: to,
            sendExcessesTo: to,
            customPayload: null,
            forwardTonAmount: 0,
            forwardPayload: emptyForwardPayload(),
        },
    });
    back.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS);
}

fun sendDeploy(collection: address, serial: uint32, owner: address, queryId: uint64, value: coins, mode: int) {
    val deploy = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: collection,
        value,
        body: DeployDesk { queryId, serial, owner },
    });
    deploy.send(mode);
}

/// Burns a deposit held by our wallet. The body carries the amount in its first 256 bits so a
/// bounce lets us recover it (opcode 32 + queryId 64 + amount ≤ 124 bits).
fun sendBurn(wallet: address, amount: coins, queryId: uint64, value: coins, mode: int) {
    val burn = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: wallet,
        value,
        body: AskToBurn { queryId, jettonAmount: amount, sendExcessesTo: contract.getAddress(), customPayload: null },
    });
    burn.send(mode);
}

fun onInternalMessage(in: InMessage) {
    var storage = lazy DeskMinterStorage.load();
    val msg = lazy AllowedMessageToMinter.fromSlice(in.body);

    match (msg) {
        TransferNotificationForRecipient => {
            val config = lazy storage.config.load();
            assert (config.deskJettonWallet != null && in.senderAddress == config.deskJettonWallet) throw Errors.NotFromDeskWallet;
            if (msg.transferInitiator == null) {
                // jettons minted straight to the Minter: nothing to return them to; keep
                return;
            }
            val initiator: address = msg.transferInitiator;
            val valid = !storage.paused
                && storage.minted < storage.cap
                && msg.jettonAmount == config.depositAmount
                && in.valueCoins >= config.surcharge + MINT_GAS
                && initiator.getWorkchain() == BASECHAIN;

            if (!valid) {
                returnDeposit(config.deskJettonWallet, initiator, msg.jettonAmount, msg.queryId, in.valueCoins);
                return;
            }

            val serial = storage.minted;
            storage.minted += 1;
            storage.pendingDeploys.set(serial, initiator);
            storage.save();

            sendBurn(config.deskJettonWallet, msg.jettonAmount, msg.queryId, BURN_VALUE, SEND_MODE_PAY_FEES_SEPARATELY);

            sendDeploy(storage.collection, serial, initiator, msg.queryId, DEPLOY_MSG_VALUE, SEND_MODE_PAY_FEES_SEPARATELY);

            val protocolShare = (config.surcharge * config.protocolShareBps) / 10000;
            val potShare = config.surcharge - protocolShare;
            if (potShare > 0) {
                val toPot = createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: storage.pot,
                    value: potShare,
                    body: PotTopUp { queryId: msg.queryId, source: POT_TOPUP_SOURCE_MINT },
                });
                toPot.send(SEND_MODE_PAY_FEES_SEPARATELY);
            }
            if (protocolShare > 0) {
                val toProtocol = createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: config.protocolWallet,
                    value: protocolShare,
                });
                toProtocol.send(SEND_MODE_PAY_FEES_SEPARATELY);
            }

            keepOwnBalance(in.valueCoins);
            val excesses = createMessage({
                bounce: BounceMode.NoBounce,
                dest: initiator,
                value: 0,
                body: ReturnExcessesBack { queryId: msg.queryId },
            });
            excesses.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS);
        }

        DeployDeskOk => {
            assert (in.senderAddress == storage.collection) throw Errors.NotFromCollection;
            storage.pendingDeploys.delete(msg.serial);
            storage.save();
        }

        RetryDeploy => {
            val found = storage.pendingDeploys.get(msg.serial);
            assert (found.isFound) throw Errors.NoPendingDeploy;
            assert (in.valueCoins >= DEPLOY_MSG_VALUE) throw Errors.InsufficientValue;
            sendDeploy(storage.collection, msg.serial, found.loadValue(), msg.queryId, 0, SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        RetryBurn => {
            assert (storage.unburned > 0) throw Errors.NothingPending;
            assert (in.valueCoins >= BURN_VALUE) throw Errors.InsufficientValue;
            val config = lazy storage.config.load();
            val amount = storage.unburned;
            storage.unburned = 0;
            storage.save();
            sendBurn(config.deskJettonWallet!, amount, msg.queryId, 0, SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        SetDeskMinterPaused => {
            assert (in.senderAddress == storage.admin) throw Errors.NotFromAdmin;
            storage.paused = msg.paused;
            storage.save();
        }

        SetDeskMinterConfig => {
            assert (in.senderAddress == storage.admin) throw Errors.NotFromAdmin;
            storage.config = msg.config;
            storage.save();
        }

        ChangeDeskMinterAdmin => {
            assert (in.senderAddress == storage.admin) throw Errors.NotFromAdmin;
            storage.admin = msg.newAdmin;
            storage.save();
        }

        ReturnExcessesBack => {
            // excesses from burn / deploy: keep as gas reserve
        }

        else => {
            assert (in.body.isEmpty() || in.body.preloadUint(32) == 0) throw 0xFFFF;
        }
    }
}

fun onBouncedMessage(in: InMessageBounced) {
    // DeployDesk bounced (collection out of gas / paused): serial stays in pendingDeploys, anyone can RetryDeploy.
    // AskToBurn bounced (wallet busy / underfunded): the deposit is still in our wallet, anyone can RetryBurn.
    in.bouncedBody.skipBouncedPrefix();
    val op = in.bouncedBody.loadUint(32);
    if (op == 0x595f07bc) {
        in.bouncedBody.skipBits(64);
        val amount = in.bouncedBody.loadCoins();
        var storage = lazy DeskMinterStorage.load();
        storage.unburned += amount;
        storage.save();
    }
}

get fun get_minter_data(): DeskMinterDataReply {
    val storage = lazy DeskMinterStorage.load();
    return {
        admin: storage.admin,
        collection: storage.collection,
        pot: storage.pot,
        minted: storage.minted,
        cap: storage.cap,
        paused: storage.paused,
        unburned: storage.unburned,
        config: storage.config.load(),
        pendingDeploys: storage.pendingDeploys,
    };
}
