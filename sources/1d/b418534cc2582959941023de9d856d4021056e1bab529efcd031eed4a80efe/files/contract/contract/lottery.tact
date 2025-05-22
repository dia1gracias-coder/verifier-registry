import "@stdlib/ownable";
import "@stdlib/stoppable";

message ChangeConfig {
    bid: Int as uint128;
    minPrize: Int as uint128;
    maxPrize: Int as uint128;
}

const MinTonStorage: Int = ton("0.02");

contract LotteryContract with OwnableTransferable, Stoppable, Resumable {
    owner: Address;
    stopped: Bool;
    bid: Int as uint128;
    minPrize: Int as uint128;
    maxPrize: Int as uint128;

    init(bid: Int as uint128, minPrize: Int as uint128, maxPrize: Int as uint128) {
        self.owner = sender();
        self.stopped = false;
        self.bid = bid;
        self.minPrize = minPrize;
        self.maxPrize = maxPrize;
    }

    //Accept Ton
    receive() {}

    receive("stop") {
        self.requireOwner();
        self.stopped = true;
    }

    receive("resume") {
        self.requireOwner();
        self.stopped = false;
    }

    receive("bid") {
        self.requireNotStopped();
        if (context().value == self.bid) {
            let seed: Int = getSeed();
            setSeed(seed);
            //randomize the prize
            let prize: Int = random(self.minPrize, self.maxPrize);

            if (myBalance() < prize) {
                send(SendParameters {
                    to: sender(),
                    value: self.bid,
                    bounce: false,
                    mode: SendRemainingValue + SendIgnoreErrors,
                    body: "insufficient funds".asComment(),
                });
            } else {
                send(SendParameters {
                    to: sender(),
                    value: prize,
                    bounce: false,
                    mode: SendRemainingValue + SendIgnoreErrors,
                    body: "You won!".asComment(),
                });
            }
        } else {
            let str1: String = "Bid must be";
            let str2: String = self.bid.toCoinsString();
            let str3: String = "Ton";
            let sb: StringBuilder = beginString();
            sb.append(str1);
            sb.append(str2);
            sb.append(str3);
            let str4: String = sb.toString();

            send(SendParameters {
                to: sender(),
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: str4.asComment(),
            });
        }
    }

    receive("withdraw") {
        self.requireOwner();
        send(SendParameters {
            to: sender(),
            bounce: true,
            value: myBalance() - context().value - MinTonStorage,
            mode: SendRemainingValue + SendIgnoreErrors,
            body: "Withdraw".asComment(),
        });
    }

    receive(msg: ChangeConfig) {
        self.requireOwner();
        self.bid = msg.bid;
        self.minPrize = msg.minPrize;
        self.maxPrize = msg.maxPrize;

        send(SendParameters {
            to: sender(),
            value: ton("0.0015"),
            mode: SendRemainingValue + SendIgnoreErrors,
            body: "Config changed".asComment(),
        });
    }

    //getter functions
    get fun get_bid(): Int {
        return self.bid;
    }

    get fun get_minPrize(): Int {
        return self.minPrize;
    }

    get fun get_maxPrize(): Int {
        return self.maxPrize;
    }
}
