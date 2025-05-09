import "@stdlib/deploy";

contract ItsWednesdayMyDudes with Deployable {
    phrase: String = "ITSWEDNESDAYMYDUDES";
    progress: Int as uint5 = 0;
    participants: map<Address, Bool> = emptyMap();
    lastCompletionWeek: Int as uint14 = 0;

    receive() {
        self.reply("Exactly one letter required".asComment());
    }

    receive(message: String) {
        if (message == "TOP_UP") {
            return;
        }

        let weekday = ((now() / 86400) + 4) % 7;
        if (weekday != 3) {
            self.reply("Not Wednesday".asComment());
            return;
        }

        let curWeek = ((now() / 86400) + 4) / 7;
        if (self.lastCompletionWeek == curWeek) {
            self.reply("Already completed this Wednesday".asComment());
            return;
        }

        let letters = message.asSlice();
        if (letters.bits() != 8) {
            self.reply("Exactly one letter required".asComment());
            return;
        }

        let letter = letters.loadUint(8);
        if (letter >= 97 && letter <= 122) {
            letter -= 32;
        }
        if (letter < 65 || letter > 90) {
            self.reply("Only A‑Z letters accepted".asComment());
            return;
        }

        if (self.participants.exists(sender())) {
            if (self.tryStartNewGame(letter)) {
                self.reply("Already participated, start a new game".asComment());
            } else {
                self.reset();
                self.reply("Already participated".asComment());
            }
            return;
        }

        let expected = self.letterAt(self.progress);
        if (letter == expected) {
            self.participants.set(sender(), true);
            self.progress += 1;

            if (self.progress == (self.phrase.asSlice().bits() / 8)) {
                self.lastCompletionWeek = curWeek;
                self.broadcastVictory();
                self.reset();
            } else {
                self.reply("Got it!".asComment());
            }
            return;
        }

        if (self.tryStartNewGame(letter)) {
            self.reply("Wrong letter, start a new game".asComment());
        } else {
            self.reset();
            self.reply("Wrong letter, sequence reset".asComment());
        }
    }

    fun tryStartNewGame(letter: Int): Bool {
        if (letter == self.phrase.asSlice().loadUint(8)) {
            self.progress = 1;
            self.participants = emptyMap();
            self.participants.set(sender(), true);

            return true;
        }

        return false;
    }

    fun broadcastVictory() {
        let body = "YEAH! WE DID IT!".asComment();
        let mode = SendRemainingValue + SendPayFwdFeesSeparately;

        foreach (address, state in self.participants) {
            send(SendParameters{
                to: address,
                value: 0,
                bounce: false,
                mode: mode,
                body: body
            });
        }
    }

    fun reset() {
        self.progress = 0;
        self.participants = emptyMap();
    }

    fun letterAt(i: Int): Int {
        let word: Slice = self.phrase.asSlice();
        let offset: Int = i;
        while (offset > 0) {
            word.loadUint(8);
            offset -= 1;
        }
        return word.loadUint(8);
    }

    get fun getProgress(): Int {
        return self.progress;
    }

    get fun getLastCompletionWeek(): Int {
        return self.lastCompletionWeek;
    }

    get fun getParticipants(): map<Address, Bool> {
        return self.participants;
    }
}
