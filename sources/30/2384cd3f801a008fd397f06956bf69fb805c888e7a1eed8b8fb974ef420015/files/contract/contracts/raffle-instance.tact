import "@stdlib/deploy";

message BuyTicket {
    secret: Int as uint256;
}

message TriggerDraw {}

struct RaffleInfo {
    master: Address;
    creator: Address;
    endsAt: Int as uint64;
    ticketCount: Int as uint32;
    pot: Int as coins;
    isDrawn: Bool;
    winner: Address?;
    isActive: Bool;
}

contract RaffleInstance with Deployable {

    master: Address;
    creator: Address;
    endsAt: Int as uint64;
    salt: Int as uint256;

    ticketCount: Int as uint32;
    pot: Int as coins;
    accumulatedEntropy: Int as uint256;
    isDrawn: Bool;
    winnerAddr: Address?;

    // Participant storage: map ticket index → buyer address
    participants: map<Int as uint32, Address>;

    init(master: Address, creator: Address, endsAt: Int, salt: Int) {
        self.master = master;
        self.creator = creator;
        self.endsAt = endsAt;
        self.salt = salt;
        self.ticketCount = 0;
        self.pot = 0;
        self.accumulatedEntropy = 0;
        self.isDrawn = false;
        self.winnerAddr = null;
    }

    receive(msg: BuyTicket) {
        let ctx: Context = context();
        let ticketPrice: Int = ton("2");

        require(!self.isDrawn, "Raffle already drawn");
        require(now() < self.endsAt, "Raffle has expired");
        require(ctx.value >= ticketPrice, "Must send at least 2 TON");

        self.participants.set(self.ticketCount, ctx.sender);
        self.ticketCount += 1;
        self.pot += ticketPrice;

        self.accumulatedEntropy = self.accumulatedEntropy ^ msg.secret;

        let overpay: Int = ctx.value - ticketPrice;
        if (overpay > ton("0.01")) {
            send(SendParameters{
                to: ctx.sender,
                value: overpay - ton("0.01"),
                mode: SendPayGasSeparately,
                body: "TON5050 ticket overpay refund".asComment()
            });
        }
    }

    receive(msg: TriggerDraw) {
        require(!self.isDrawn, "Raffle already drawn");
        require(now() >= self.endsAt, "Raffle has not expired yet");

        self.isDrawn = true;

        if (self.ticketCount == 0) {
            return;
        }

        let entropy: Int = self.salt ^ self.accumulatedEntropy ^ now();
        let winnerIndex: Int = entropy % self.ticketCount;
        if (winnerIndex < 0) {
            winnerIndex = -winnerIndex;
        }

        let winner: Address = self.participants.get(winnerIndex)!!;
        self.winnerAddr = winner;

        let halfPot: Int = self.pot / 2;
        let winnerShare: Int = halfPot + (self.pot % 2);
        let creatorShare: Int = halfPot;

        send(SendParameters{
            to: winner,
            value: winnerShare,
            mode: SendPayGasSeparately,
            body: "TON5050 winner payout".asComment()
        });

        send(SendParameters{
            to: self.creator,
            value: creatorShare,
            mode: SendPayGasSeparately,
            body: "TON5050 creator payout".asComment()
        });
    }

    get fun raffleInfo(): RaffleInfo {
        return RaffleInfo{
            master: self.master,
            creator: self.creator,
            endsAt: self.endsAt,
            ticketCount: self.ticketCount,
            pot: self.pot,
            isDrawn: self.isDrawn,
            winner: self.winnerAddr,
            isActive: now() < self.endsAt && !self.isDrawn
        };
    }

    get fun isActive(): Bool {
        return now() < self.endsAt && !self.isDrawn;
    }

    get fun ticketCount(): Int {
        return self.ticketCount;
    }

    get fun pot(): Int {
        return self.pot;
    }

    get fun drawn(): Bool {
        return self.isDrawn;
    }

    get fun winner(): Address? {
        return self.winnerAddr;
    }
}
