import "errors"
import "messages"
import "tokenomics-messages"
import "tokenomics-storage"

contract CampaignWinnerVault {
    author: "100wan"
    version: "0.1.0"
    description: "HI campaign winner locked reward vault"
    storage: CampaignWinnerStorage
    incomingMessages: AllowedCampaignWinnerMessage
}

type AllowedCampaignWinnerMessage =
    | RegisterCampaignWinner
    | ClaimCampaignWinner
    | SetCampaignWinnerJettonWallet
    | SetConfirmedLevel

type CampaignWinnerBounceMessage = AskToTransfer

const CAMPAIGN_WINNER_ALLOCATION_HI = 5000000 * 1000000000
const CAMPAIGN_WINNER_MAX_COUNT = 80

fun onBouncedMessage(in: InMessageBounced) {
    in.bouncedBody.skipBouncedPrefix();
    val msg = lazy CampaignWinnerBounceMessage.fromSlice(in.bouncedBody);

    var storage = lazy CampaignWinnerStorage.load();
    val pending = storage.pendingTransfers.mustGet(msg.queryId, Errors.InvalidMessage);
    val pos = storage.winners.mustGet(pending.winner, Errors.WinnerMissing);
    storage
        .winners
        .set(
            pending.winner,
            { entryLevel: pos.entryLevel, claimedHi: pos.claimedHi - pending.amount },
        );
    storage.totalClaimedHi -= pending.amount;
    storage.pendingTransfers.delete(msg.queryId);
    storage.save();
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedCampaignWinnerMessage.fromSlice(in.body);

    match (msg) {
        RegisterCampaignWinner => {
            var storage = lazy CampaignWinnerStorage.load();
            val config = storage.config.load();
            assert (in.senderAddress == config.admin) throw Errors.NotAdmin;
            assert (!storage.winners.exists(msg.winner)) throw Errors.WinnerExists;
            assert (
                storage.winnerCount < CAMPAIGN_WINNER_MAX_COUNT
            ) throw Errors.WinnerLimitExceeded;
            storage
                .winners
                .set(
                    msg.winner,
                    { entryLevel: storage.confirmedLevel, claimedHi: 0 },
                );
            storage.winnerCount += 1;
            storage.save();
        }

        SetConfirmedLevel => {
            var storage = lazy CampaignWinnerStorage.load();
            assert (in.senderAddress == storage.oracle) throw Errors.NotAdmin;
            assert (msg.confirmedLevel > storage.confirmedLevel) throw Errors.InvalidLevel;
            assert (msg.confirmedLevel <= 10) throw Errors.InvalidLevel;
            storage.confirmedLevel = msg.confirmedLevel;
            storage.save();
        }

        SetCampaignWinnerJettonWallet => {
            var storage = lazy CampaignWinnerStorage.load();
            val config = storage.config.load();
            assert (in.senderAddress == config.admin) throw Errors.NotAdmin;
            storage.winnerJettonWallet = msg.winnerJettonWallet;
            storage.save();
        }

        ClaimCampaignWinner => {
            var storage = lazy CampaignWinnerStorage.load();
            assert (in.valueCoins >= ton("0.25")) throw Errors.InsufficientAttachedTon;
            val pos = storage.winners.mustGet(in.senderAddress, Errors.WinnerMissing);
            val amount = winnerClaimable(storage.confirmedLevel, pos);
            assert (amount > 0) throw Errors.NoClaimableAmount;
            storage
                .winners
                .set(
                    in.senderAddress,
                    { entryLevel: pos.entryLevel, claimedHi: pos.claimedHi + amount },
                );
            storage.totalClaimedHi += amount;
            sendWinnerJettons(mutate storage, in.senderAddress, amount, in.valueCoins);
            storage.save();
        }

        else => {
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
        }
    }
}

fun sendWinnerJettons(
    mutate storage: CampaignWinnerStorage,
    winner: address,
    amount: coins,
    value: coins,
) {
    val config = storage.config.load();
    val winnerJettonWallet = storage.winnerJettonWallet;
    assert (winnerJettonWallet != null) throw Errors.JettonWalletNotConfigured;
    val queryId = storage.nextQueryId;
    storage.nextQueryId += 1;
    storage
        .pendingTransfers
        .set(
            queryId,
            { winner, amount },
        );
    val transferMessage = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: winnerJettonWallet!,
        value,
        body: AskToTransfer {
            queryId,
            jettonAmount: amount,
            transferRecipient: winner,
            sendExcessesTo: config.admin,
            customPayload: null,
            forwardTonAmount: 0,
            forwardPayload: beginCell().storeUint(0, 1).endCell().beginParse(),
        },
    });
    transferMessage.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
}

fun winnerClaimable(confirmedLevel: uint8, pos: CampaignWinnerPosition): coins {
    val unlockedBps = 5 + winnerHistoricalUnlockedBps(confirmedLevel) -
    winnerHistoricalUnlockedBps(pos.entryLevel);
    val unlocked = CAMPAIGN_WINNER_ALLOCATION_HI * unlockedBps / 100;
    return unlocked - pos.claimedHi;
}

fun winnerHistoricalUnlockedBps(level: uint8): uint8 {
    if (level == 0) {
        return 0;
    }
    if (level >= 10) {
        return 95;
    }
    return level * 10;
}

get fun winner_state(winner: address): (bool, uint8, coins, coins) {
    val storage = lazy CampaignWinnerStorage.load();
    val found = storage.winners.get(winner);
    if (!found.isFound) {
        return (false, storage.confirmedLevel, 0, 0);
    }
    val pos = found.loadValue();
    return (true, pos.entryLevel, pos.claimedHi, winnerClaimable(storage.confirmedLevel, pos));
}

get fun vault_state(): (uint8, uint16, coins) {
    val storage = lazy CampaignWinnerStorage.load();
    return (storage.confirmedLevel, storage.winnerCount, storage.totalClaimedHi);
}

get fun claimable(winner: address): coins {
    val storage = lazy CampaignWinnerStorage.load();
    val pos = storage.winners.mustGet(winner, Errors.WinnerMissing);
    return winnerClaimable(storage.confirmedLevel, pos);
}

get fun confirmed_level(): uint8 {
    val storage = lazy CampaignWinnerStorage.load();
    return storage.confirmedLevel;
}
