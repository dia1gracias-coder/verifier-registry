import "errors"
import "tokenomics-messages"
import "tokenomics-storage"

contract PriceOracle {
    author: "100wan"
    version: "0.1.0"
    description: "HI V1 price threshold oracle"
    storage: PriceOracleStorage
    incomingMessages: AllowedOracleMessage
}

type AllowedOracleMessage = ReportPrice | ConfirmLevel | SetOracleTargets | SetCampaignWinnerTarget

fun onBouncedMessage(_in: InMessageBounced) {}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedOracleMessage.fromSlice(in.body);

    match (msg) {
        ReportPrice => {
            var storage = lazy PriceOracleStorage.load();
            assert (in.senderAddress == storage.admin) throw Errors.NotAdmin;
            storage.lastPrice = msg.price;

            val nextLevel = storage.confirmedLevel + 1;
            if (nextLevel > 15) {
                storage.save();
                return;
            }

            if (msg.price >= threshold(nextLevel)) {
                if (storage.candidateLevel != nextLevel) {
                    storage.candidateLevel = nextLevel;
                    storage.levelStartedAt = blockchain.now() as uint32;
                }
            } else {
                storage.candidateLevel = 0;
                storage.levelStartedAt = 0;
            }

            storage.save();
        }

        SetOracleTargets => {
            var storage = lazy PriceOracleStorage.load();
            assert (in.senderAddress == storage.admin) throw Errors.NotAdmin;
            storage.publicSale = msg.publicSale;
            storage.teamVestingVault = msg.teamVestingVault;
            storage.save();
        }

        SetCampaignWinnerTarget => {
            var storage = lazy PriceOracleStorage.load();
            assert (in.senderAddress == storage.admin) throw Errors.NotAdmin;
            storage.campaignTargets = PriceOracleCampaignTargets {
                campaignWinnerVault: msg.campaignWinnerVault,
            }.toCell();
            storage.save();
        }

        ConfirmLevel => {
            var storage = lazy PriceOracleStorage.load();
            val nextLevel = storage.confirmedLevel + 1;
            assert (nextLevel <= 15) throw Errors.InvalidLevel;
            assert (storage.candidateLevel == nextLevel) throw Errors.TimerNotStarted;
            assert (storage.levelStartedAt != 0) throw Errors.TimerNotStarted;
            assert (
                blockchain.now() >= storage.levelStartedAt + storage.confirmationDelay
            ) throw Errors.TimerNotMature;

            val confirmedAt = blockchain.now() as uint32;
            storage.confirmedLevel = nextLevel;
            storage.candidateLevel = 0;
            storage.levelStartedAt = 0;
            val publicSale = storage.publicSale;
            val teamVestingVault = storage.teamVestingVault;
            val campaignWinnerVault = storage.campaignTargets.load().campaignWinnerVault;
            storage.save();

            if (publicSale != null) {
                val saleMessage = createMessage({
                    bounce: true,
                    dest: publicSale!,
                    value: ton("0.05"),
                    body: SetConfirmedLevel { confirmedLevel: nextLevel },
                });
                saleMessage.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
            }

            if (nextLevel >= 11 && teamVestingVault != null) {
                val teamMessage = createMessage({
                    bounce: true,
                    dest: teamVestingVault!,
                    value: ton("0.05"),
                    body: SyncTeamPriceLevel {
                        confirmedLevel: nextLevel,
                        confirmedAt,
                    },
                });
                teamMessage.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
            }

            if (nextLevel <= 10 && campaignWinnerVault != null) {
                val winnerMessage = createMessage({
                    bounce: true,
                    dest: campaignWinnerVault!,
                    value: ton("0.05"),
                    body: SetConfirmedLevel { confirmedLevel: nextLevel },
                });
                winnerMessage.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
            }
        }

        else => {
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
        }
    }
}

get fun confirmed_level(): uint8 {
    val storage = lazy PriceOracleStorage.load();
    return storage.confirmedLevel;
}

get fun candidate_state(): (uint8, uint32, uint64) {
    val storage = lazy PriceOracleStorage.load();
    return (storage.candidateLevel, storage.levelStartedAt, storage.lastPrice);
}

get fun threshold_for(level: uint8): uint64 {
    return threshold(level);
}

fun threshold(level: int): uint64 {
    if (level == 1) {
        return 800000;
    }
    if (level == 2) {
        return 1600000;
    }
    if (level == 3) {
        return 3200000;
    }
    if (level == 4) {
        return 6400000;
    }
    if (level == 5) {
        return 12800000;
    }
    if (level == 6) {
        return 25600000;
    }
    if (level == 7) {
        return 51200000;
    }
    if (level == 8) {
        return 102400000;
    }
    if (level == 9) {
        return 204800000;
    }
    if (level == 10) {
        return 409600000;
    }
    if (level == 11) {
        return 500000000;
    }
    if (level == 12) {
        return 1000000000;
    }
    if (level == 13) {
        return 2000000000;
    }
    if (level == 14) {
        return 3000000000;
    }
    if (level == 15) {
        return 5000000000;
    }
    throw Errors.InvalidLevel;
}
