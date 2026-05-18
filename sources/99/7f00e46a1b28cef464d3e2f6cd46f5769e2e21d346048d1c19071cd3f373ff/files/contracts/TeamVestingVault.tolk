import "errors"
import "messages"
import "tokenomics-messages"
import "tokenomics-storage"

contract TeamVestingVault {
    author: "100wan"
    version: "0.1.0"
    description: "HI V1 team vesting vault"
    storage: TeamVestingStorage
    incomingMessages: AllowedTeamVestingMessage
}

type AllowedTeamVestingMessage = SyncLevel10 | ClaimTeam | SetTeamJettonWallet

type TeamBounceMessage = AskToTransfer

fun onBouncedMessage(in: InMessageBounced) {
    in.bouncedBody.skipBouncedPrefix();
    val msg = lazy TeamBounceMessage.fromSlice(in.bouncedBody);

    var storage = lazy TeamVestingStorage.load();
    val amount = storage.pendingTransfers.mustGet(msg.queryId, Errors.InvalidMessage);
    storage.claimedHi -= amount;
    storage.pendingTransfers.delete(msg.queryId);
    storage.save();
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedTeamVestingMessage.fromSlice(in.body);

    match (msg) {
        SyncLevel10 => {
            var storage = lazy TeamVestingStorage.load();
            assert (in.senderAddress == storage.oracle) throw Errors.NotAdmin;
            if (storage.level10ConfirmedAt == 0) {
                storage.level10ConfirmedAt = msg.confirmedAt;
                storage.save();
            }
        }

        SetTeamJettonWallet => {
            var storage = lazy TeamVestingStorage.load();
            val config = storage.config.load();
            assert (in.senderAddress == config.admin) throw Errors.NotAdmin;
            storage.teamJettonWallet = msg.teamJettonWallet;
            storage.save();
        }

        ClaimTeam => {
            var storage = lazy TeamVestingStorage.load();
            val config = storage.config.load();
            assert (in.senderAddress == config.admin) throw Errors.NotAdmin;
            assert (storage.level10ConfirmedAt != 0) throw Errors.InvalidLevel;
            assert (in.valueCoins >= ton("0.25")) throw Errors.InsufficientAttachedTon;
            val amount = vested(storage) - storage.claimedHi;
            assert (amount > 0) throw Errors.NoClaimableAmount;
            storage.claimedHi += amount;
            sendTeamJettons(mutate storage, amount, in.valueCoins);
            storage.save();
        }

        else => {
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
        }
    }
}

fun sendTeamJettons(mutate storage: TeamVestingStorage, amount: coins, value: coins) {
    val config = storage.config.load();
    val teamJettonWallet = storage.teamJettonWallet;
    assert (teamJettonWallet != null) throw Errors.JettonWalletNotConfigured;
    val queryId = storage.nextQueryId;
    storage.nextQueryId += 1;
    storage.pendingTransfers.set(queryId, amount);
    val msg = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: teamJettonWallet!!,
        value,
        body: AskToTransfer {
            queryId,
            jettonAmount: amount,
            transferRecipient: config.teamWallet,
            sendExcessesTo: config.admin,
            customPayload: null,
            forwardTonAmount: 0,
            forwardPayload: beginCell().storeUint(0, 1).endCell().beginParse(),
        },
    });
    msg.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
}

fun vested(storage: TeamVestingStorage): coins {
    if (storage.level10ConfirmedAt == 0) {
        return 0;
    }
    val elapsed = blockchain.now() - storage.level10ConfirmedAt;
    var installments = elapsed / 2592000 + 1;
    if (installments > 10) {
        installments = 10;
    }
    return storage.totalHi * installments / 10;
}

get fun vesting_state(): (uint32, coins, coins) {
    val storage = lazy TeamVestingStorage.load();
    return (storage.level10ConfirmedAt, storage.claimedHi, vested(storage));
}
