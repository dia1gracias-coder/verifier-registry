import "@stdlib/ownable";
import "@stdlib/deploy";

message StoreHash {
    date: Int as uint32;    // YYYYMMDD format, e.g. 20260312
    hash: Int as uint256;   // SHA-256 hash of daily snapshot
}

contract SyntharisVault with Deployable, Ownable {
    owner: Address;
    hashes: map<Int as uint32, Int as uint256>;
    latestDate: Int as uint32 = 0;
    totalEntries: Int as uint32 = 0;

    init(owner: Address) {
        self.owner = owner;
    }

    // Only owner can store hashes
    receive(msg: StoreHash) {
        self.requireOwner();
        require(msg.date > 0, "Invalid date");
        require(self.hashes.get(msg.date) == null, "Hash already stored for this date");

        self.hashes.set(msg.date, msg.hash);
        self.totalEntries = self.totalEntries + 1;

        if (msg.date > self.latestDate) {
            self.latestDate = msg.date;
        }

        // Return excess gas to sender
        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors,
            body: "ok".asComment()
        });
    }

    // Read hash by date
    get fun getHash(date: Int): Int? {
        return self.hashes.get(date);
    }

    // Get the latest stored date
    get fun getLatestDate(): Int {
        return self.latestDate;
    }

    // Get total number of entries
    get fun getTotalEntries(): Int {
        return self.totalEntries;
    }
}
