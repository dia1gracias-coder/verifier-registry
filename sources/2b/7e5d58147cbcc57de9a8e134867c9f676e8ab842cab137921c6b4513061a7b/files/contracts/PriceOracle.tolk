import "errors"
import "tokenomics-messages"
import "tokenomics-storage"

contract PriceOracle {
    author: "100wan"
    version: "0.2.0"
    description: "HI USDT price threshold oracle"
    storage: PriceOracleStorage
    incomingMessages: AllowedOracleMessage
}

type AllowedOracleMessage =
    | ReportGrowthPrice
    | ConfirmGrowthLevel
    | ReportTeamPrice
    | ConfirmTeamLevel
    | SetOracleTargets
    | SetCampaignWinnerTarget

fun onBouncedMessage(_in: InMessageBounced) {}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedOracleMessage.fromSlice(in.body);

    match (msg) {
        ReportGrowthPrice => {
            var storage = lazy PriceOracleStorage.load();
            assert (in.senderAddress == storage.admin) throw Errors.NotAdmin;
            var growth = storage.growth.load();
            growth.lastPrice = msg.price;

            val nextLevel = growth.confirmedLevel + 1;
            if (nextLevel > 10) {
                storage.growth = growth.toCell();
                storage.save();
                return;
            }

            if (msg.price >= growthThreshold(nextLevel)) {
                if (growth.candidateLevel != nextLevel) {
                    growth.candidateLevel = nextLevel;
                    growth.levelStartedAt = blockchain.now() as uint32;
                }
            } else {
                growth.candidateLevel = 0;
                growth.levelStartedAt = 0;
            }

            storage.growth = growth.toCell();
            storage.save();
        }

        ReportTeamPrice => {
            var storage = lazy PriceOracleStorage.load();
            assert (in.senderAddress == storage.admin) throw Errors.NotAdmin;
            var team = storage.team.load();
            team.lastPrice = msg.price;

            val nextLevel = team.confirmedLevel + 1;
            if (nextLevel > 4) {
                storage.team = team.toCell();
                storage.save();
                return;
            }

            if (msg.price >= teamThreshold(nextLevel)) {
                if (team.candidateLevel != nextLevel) {
                    team.candidateLevel = nextLevel;
                    team.levelStartedAt = blockchain.now() as uint32;
                }
            } else {
                team.candidateLevel = 0;
                team.levelStartedAt = 0;
            }

            storage.team = team.toCell();
            storage.save();
        }

        SetOracleTargets => {
            var storage = lazy PriceOracleStorage.load();
            assert (in.senderAddress == storage.admin) throw Errors.NotAdmin;
            val currentTargets = storage.targets.load();
            storage.targets = PriceOracleTargets {
                growthEngine: msg.growthEngine,
                teamVestingVault: msg.teamVestingVault,
                merkleRewardVault: msg.merkleRewardVault,
                campaignTargets: currentTargets.campaignTargets,
            }.toCell();
            storage.save();
        }

        SetCampaignWinnerTarget => {
            var storage = lazy PriceOracleStorage.load();
            assert (in.senderAddress == storage.admin) throw Errors.NotAdmin;
            val targets = storage.targets.load();
            storage.targets = PriceOracleTargets {
                growthEngine: targets.growthEngine,
                teamVestingVault: targets.teamVestingVault,
                merkleRewardVault: targets.merkleRewardVault,
                campaignTargets: PriceOracleCampaignTargets {
                    campaignWinnerVault: msg.campaignWinnerVault,
                }.toCell(),
            }.toCell();
            storage.save();
        }

        ConfirmGrowthLevel => {
            var storage = lazy PriceOracleStorage.load();
            var growth = storage.growth.load();
            val nextLevel = growth.confirmedLevel + 1;
            assert (nextLevel <= 10) throw Errors.InvalidLevel;
            assert (growth.candidateLevel == nextLevel) throw Errors.TimerNotStarted;
            assert (growth.levelStartedAt != 0) throw Errors.TimerNotStarted;
            assert (
                blockchain.now() >= growth.levelStartedAt + storage.confirmationDelay
            ) throw Errors.TimerNotMature;

            growth.confirmedLevel = nextLevel;
            growth.candidateLevel = 0;
            growth.levelStartedAt = 0;
            storage.growth = growth.toCell();
            val targets = storage.targets.load();
            val growthEngine = targets.growthEngine;
            val campaignWinnerVault = targets.campaignTargets.load().campaignWinnerVault;
            val merkleRewardVault = targets.merkleRewardVault;
            storage.save();

            if (growthEngine != null) {
                val growthMessage = createMessage({
                    bounce: true,
                    dest: growthEngine!,
                    value: ton("0.05"),
                    body: SetGrowthConfirmedLevel { growthConfirmedLevel: nextLevel },
                });
                growthMessage.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
            }

            if (campaignWinnerVault != null) {
                val winnerMessage = createMessage({
                    bounce: true,
                    dest: campaignWinnerVault!,
                    value: ton("0.05"),
                    body: SetGrowthConfirmedLevel { growthConfirmedLevel: nextLevel },
                });
                winnerMessage.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
            }

            if (merkleRewardVault != null) {
                val rewardMessage = createMessage({
                    bounce: true,
                    dest: merkleRewardVault!,
                    value: ton("0.05"),
                    body: SetRewardGrowthLevel { growthConfirmedLevel: nextLevel },
                });
                rewardMessage.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
            }
        }

        ConfirmTeamLevel => {
            var storage = lazy PriceOracleStorage.load();
            var team = storage.team.load();
            val nextLevel = team.confirmedLevel + 1;
            assert (nextLevel <= 4) throw Errors.InvalidLevel;
            assert (team.candidateLevel == nextLevel) throw Errors.TimerNotStarted;
            assert (team.levelStartedAt != 0) throw Errors.TimerNotStarted;
            assert (
                blockchain.now() >= team.levelStartedAt + storage.confirmationDelay
            ) throw Errors.TimerNotMature;

            val confirmedAt = blockchain.now() as uint32;
            team.confirmedLevel = nextLevel;
            team.candidateLevel = 0;
            team.levelStartedAt = 0;
            storage.team = team.toCell();
            val teamVestingVault = storage.targets.load().teamVestingVault;
            storage.save();

            if (teamVestingVault != null) {
                val teamMessage = createMessage({
                    bounce: true,
                    dest: teamVestingVault!,
                    value: ton("0.05"),
                    body: SyncTeamPriceLevel {
                        teamConfirmedLevel: nextLevel,
                        confirmedAt,
                    },
                });
                teamMessage.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
            }
        }

        else => {
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
        }
    }
}

get fun growth_confirmed_level(): uint8 {
    val storage = lazy PriceOracleStorage.load();
    return storage.growth.load().confirmedLevel;
}

get fun team_confirmed_level(): uint8 {
    val storage = lazy PriceOracleStorage.load();
    return storage.team.load().confirmedLevel;
}

get fun growth_candidate_state(): (uint8, uint32, uint64) {
    val storage = lazy PriceOracleStorage.load();
    val growth = storage.growth.load();
    return (growth.candidateLevel, growth.levelStartedAt, growth.lastPrice);
}

get fun team_candidate_state(): (uint8, uint32, uint64) {
    val storage = lazy PriceOracleStorage.load();
    val team = storage.team.load();
    return (team.candidateLevel, team.levelStartedAt, team.lastPrice);
}

get fun growth_threshold_for(level: uint8): uint64 {
    return growthThreshold(level);
}

get fun team_threshold_for(level: uint8): uint64 {
    return teamThreshold(level);
}

fun growthThreshold(level: int): uint64 {
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
    throw Errors.InvalidLevel;
}

fun teamThreshold(level: int): uint64 {
    if (level == 1) {
        return 100000000;
    }
    if (level == 2) {
        return 500000000;
    }
    if (level == 3) {
        return 1000000000;
    }
    if (level == 4) {
        return 5000000000;
    }
    throw Errors.InvalidLevel;
}
