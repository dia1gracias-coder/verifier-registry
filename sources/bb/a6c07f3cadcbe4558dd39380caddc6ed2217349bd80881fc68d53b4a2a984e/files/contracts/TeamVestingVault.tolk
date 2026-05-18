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

type AllowedTeamVestingMessage = SyncTeamPriceLevel | ClaimTeam | SetTeamJettonWallet

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
        SyncTeamPriceLevel => {
            var storage = lazy TeamVestingStorage.load();
            assert (in.senderAddress == storage.oracle) throw Errors.NotAdmin;
            assert (msg.confirmedLevel >= 11) throw Errors.InvalidLevel;
            assert (msg.confirmedLevel <= 15) throw Errors.InvalidLevel;
            if (msg.confirmedLevel > storage.confirmedLevel) {
                storage.confirmedLevel = msg.confirmedLevel;
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
    val transferMessage = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: teamJettonWallet!,
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
    transferMessage.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
}

fun vested(storage: TeamVestingStorage): coins {
    if (storage.confirmedLevel <= 10) {
        return 0;
    }
    var releaseStages = storage.confirmedLevel - 10;
    if (releaseStages > 5) {
        releaseStages = 5;
    }
    return storage.totalHi * releaseStages / 5;
}

get fun vesting_state(): (uint8, coins, coins) {
    val storage = lazy TeamVestingStorage.load();
    return (storage.confirmedLevel, storage.claimedHi, vested(storage));
}
