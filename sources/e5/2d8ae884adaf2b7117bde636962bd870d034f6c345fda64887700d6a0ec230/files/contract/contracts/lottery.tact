import "@stdlib/deploy";

const NANO_COUNT: Int = 1_000_000_000;

message TransferEvent {
    amount: Int as int64;
    recipient: Address;
}

message EntryEvent {
    sender: Address;
    amount: Int as int64;
}

contract QuickLotteryTON with Deployable {
    const DRAW_EVERY: Int = 24 * 60 * 60; // Once every day at most.
    const MIN_PARTICIPANTS: Int = 10;

    lastDrawTime: Int;
    participants: map<Address, Int>;
    participantCount: Int;
    betPool: Int;
    deployer: Address;

    init() {
        nativeReserve(ton("1.0"), ReserveAtMost | ReserveBounceIfActionFail);

        self.deployer = sender();
        self.participantCount = 0;
        self.betPool = 0;
        self.participants = emptyMap();
        self.lastDrawTime = now();
    }

    receive("enter") {
        let amount: Int = context().value;
        if (amount < NANO_COUNT || amount % NANO_COUNT != 0) {
            self.reply("Can only enter with 1 TON or multiples of 1 TON.".asComment());
            return;
        }

        let sender: Address = sender();
        if (self.participants.exists(sender)) {
            self.reply("You have already entered this draw.".asComment());
            return;
        }

        self.participants.set(sender, amount);
        self.participantCount += 1;
        self.betPool += amount;

        // Emit entry event
        emit(EntryEvent{sender: sender, amount: amount}.toCell());

        // Send confirmation message to participant with bet amount
        let sb: StringBuilder = beginString();
        sb.append("Successfully entered the lottery draw with ");
        sb.append((amount / NANO_COUNT).toString());
        sb.append(" TON!");

        send(SendParameters{
            to: sender,
            bounce: false,
            value: 0, // No TON refunded
            mode: SendIgnoreErrors | SendPayFwdFeesSeparately,
            body: sb.toString().asComment()
        });
    }

    receive("draw") {
        // Check time since last draw
        let remaining: Int = self.DRAW_EVERY - (now() - self.lastDrawTime);
        if (remaining > 0) {
            let sb: StringBuilder = beginString();
            sb.append("Cannot draw yet, ");
            sb.append(remaining.toString());
            sb.append(" seconds remaining until next draw.");
            self.reply(sb.toString().asComment());
            return;
        }
        if (self.participantCount < self.MIN_PARTICIPANTS) {
            self.reply("Not enough participants for draw.".asComment());
            return;
        }

        // Send 1% fee to owner
        let ownerFee: Int = self.betPool / 100;
        if (ownerFee > 0) {
            emit(TransferEvent{amount: ownerFee, recipient: self.deployer}.toCell());
            send(SendParameters{
                to: self.deployer,
                bounce: true,
                value: ownerFee,
                mode: SendIgnoreErrors
            });
        }

        // Determine prize pool and winner count
        let pool: Int = self.betPool - ownerFee;
        let targetWinners: Int = self.participantCount / 10; // 10% winners

        // Select winners
        let winners: map<Address, Int> = emptyMap();
        let winnerCount: Int = 0;
        let totalWinnerWeight: Int = 0;

        // First pass: try to select winners with 10% chance
        while (winnerCount == 0) {
            foreach (adr, winnerWeight in self.participants) {
                if (random(1, 100) <= 10 && winnerCount < targetWinners) {
                    winners.set(adr, winnerWeight);
                    totalWinnerWeight += winnerWeight;
                    winnerCount += 1;
                }
            }
        }

        // Distribute prizes proportionally to bet amounts
        foreach (winnerAddress, winnerWeight in winners) {
            let prize: Int = pool * winnerWeight / totalWinnerWeight;
            if (prize > 0) {
                // Create notification message with prize amount
                let sb: StringBuilder = beginString();
                sb.append("Congratulations! You won ");
                sb.append((prize).toString());
                sb.append(" nanoTON in the lottery draw!");

                // Emit transfer event
                emit(TransferEvent{amount: prize, recipient: winnerAddress}.toCell());

                // Send prize with notification message in a single transaction
                send(SendParameters{
                    to: winnerAddress,
                    bounce: true,
                    value: prize,
                    mode: SendIgnoreErrors,
                    body: sb.toString().asComment()
                });
            }
        }

        // Reset lottery
        self.participantCount = 0;
        self.betPool = 0;
        self.participants = emptyMap();
        self.lastDrawTime = now();
    }


    get fun participantCount(): Int {
        return self.participantCount;
    }

    get fun betPool(): Int {
        return self.betPool;
    }

    get fun balance(): Int {
        return myBalance();
    }
}
