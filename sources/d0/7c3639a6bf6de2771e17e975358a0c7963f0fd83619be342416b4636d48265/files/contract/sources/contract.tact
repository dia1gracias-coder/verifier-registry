import "@stdlib/deploy";
message Add {
    amount: Int as coins;
}
message(2025010100) UserVote {
    timestamp: Int;
    value: Bool;
}

message(2025010101) UserClaim {
    amount: Int as coins;
}

message(2025010102) SetResult {
    timestamp: Int;
    value: Bool;
}

message(2025010103) SetConfig {
    mode: Int;
}

const INIT_BALANCE: Int = 2025011901;
const TAKE_BALANCE: Int = 2025011902;

struct VoteItem {
    value: Bool;
    amount: Int as coins;
    odd: Int;
}
struct Vote {
    timestamp: Int;
    result: Bool?;
    users: map<Address, VoteItem>;
}

struct Odd {
    odd: Int;
    trueAmount: Int;
    falseAmount: Int;
}

contract TonBetPlayContract with Deployable {
    owner: Address;
    votes: map<Int, Vote>;
    odds: map<Int, Odd>;
    users: map<Address, Int>;
    threshold: Int;
    init(owner: Address){
        self.owner = owner;
        self.votes = emptyMap();
        self.users = emptyMap();
        // self.threshold = 1000000000; // 1 ton
        self.threshold = 100000000; // 1 ton
    }

    fun get_timestamp(): Int {
        // return 0;
        return now() / (60 * 5);
    }

    fun vote(v: UserVote, amount: Int) {
        let now: Int = self.get_timestamp();
        require(now == v.timestamp, "Expired");

        let ctx: Context = context();
        if (!self.votes.exists(now)) {
            self.votes.set(now, Vote{timestamp: now, users: emptyMap()});
            self.odds.set(now, Odd{odd: 90, trueAmount: 0, falseAmount:0});
        }
        let minuteVote = self.votes.get(now)!!;
        let oddVote = self.odds.get(now)!!;

        minuteVote.users.set(ctx.sender, VoteItem{value: v.value, amount: amount, odd: oddVote.odd});
        self.votes.set(now, minuteVote);
        if(v.value) {
            oddVote.trueAmount = oddVote.trueAmount + amount;
            if(oddVote.trueAmount - oddVote.falseAmount > self.threshold) {
                oddVote.odd = oddVote.odd - 1;
            }
        } else {
            oddVote.falseAmount = oddVote.falseAmount + amount;
            if(oddVote.falseAmount - oddVote.trueAmount > self.threshold) {
                oddVote.odd = oddVote.odd + 1;
            }
        }
        self.odds.set(now, oddVote);
    }

    fun claim(v: UserClaim) {
        let ctx: Context = context();
        let balance = self.users.get(ctx.sender);
        require(balance != null, "Not enough balance");
        require(balance!! >= v.amount, "Not enough balance");
        send(SendParameters{
            to: ctx.sender,
            value: v.amount,
            mode: SendIgnoreErrors,
            body: "CLAIM".asComment(),
        });
        self.users.set(ctx.sender, balance!! - v.amount);
    }

    fun setResult(v: SetResult) {
        let ctx: Context = context();
        // require(ctx.sender == self.owner, "Invalid sender");
        if (self.votes.exists(v.timestamp)) {
            let minuteVote = self.votes.get(v.timestamp)!!;
            minuteVote.result = v.value;
            self.votes.set(v.timestamp, minuteVote);
            // payout
            foreach (key, value in minuteVote.users) {
                if(value.value == v.value) {
                    let previousValue = self.users.get(key);
                    if(previousValue == null) {
                        self.users.set(key, value.amount + (value.amount * value.odd / 100));
                    } else {
                        self.users.set(key, previousValue!! + value.amount + (value.amount * value.odd / 100));
                    }
                }
            }
        }
    }

    receive(vote: UserVote){
        let ctx: Context = context();
        self.vote(vote, ctx.value);
    }

    receive(config: SetConfig){
        let ctx: Context = context();
        if(config.mode == INIT_BALANCE) {
            return;
        }
        if(config.mode == TAKE_BALANCE) {
            require(sender() == self.owner, "Only owner is allowed to withdraw");
            send(SendParameters{
                to: sender(),
                bounce: true,
                value: 0,
                mode: SendRemainingBalance + SendIgnoreErrors
            });
        }
    }

    receive(claim: UserClaim){
        self.claim(claim);
        self.reply("claimed".asComment());
    }

    receive(result: SetResult){
        self.setResult(result);
        self.reply("ok".asComment());
    }

    get fun my_vote(user: Address): VoteItem? {
        let timstamp: Int = self.get_timestamp();
        let minuteVote = self.votes.get(timstamp);
        if(minuteVote == null) {
            return null;
        }
        let userVote = minuteVote!!.users.get(user);
        if(userVote == null) {
            return null;
        }
        return userVote!!;
    }

    get fun my_balance(user: Address): Int? {
        return self.users.get(user);
    }
}