import "./array.tact";

// TODO: optimise array interactions?
trait Leaderboard {
    leaderboard: MapArray;

    fun processUser(userEntry: PlayerRecord) {
        let currIdx: Int = self.find(userEntry.userAddress);
        if (currIdx != -1) {
            let currRecord: PlayerRecord = self.leaderboard.get(currIdx);
            if (userEntry.score <= currRecord.score) {
                return;
            }
            self.leaderboard.deleteAt(currIdx);
        }

        let length = self.leaderboard.length;
        let idx = self.findLastWorseThan(userEntry.score);
        if (idx == length && length == self.leaderboard.maxSize) {
            return;
        }

        self.leaderboard.insertAt(userEntry, idx);
    }

    fun findLastWorseThan(score: Int): Int {
        if (self.leaderboard.length == 0) {
            return 0;
        }

        let result = self.leaderboard.length;

        let i: Int = self.leaderboard.length - 1;
        while (i >= 0) {
            if (self.leaderboard.get(i).score >= score) {
                return result;
            }
            result = i;
            i -= 1;
        }

        return result;
    }

    fun find(addr: Address): Int {
        let i: Int = 0;
        let length: Int = self.leaderboard.length;
        while (i < length) {
            if (self.leaderboard.get(i).userAddress == addr) {
                return i;
            }
            i += 1;
        }

        return -1;
    }
}
