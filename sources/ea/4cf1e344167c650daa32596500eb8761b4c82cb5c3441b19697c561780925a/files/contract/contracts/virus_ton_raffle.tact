import "@stdlib/ownable";
import "./messages";

contract VirusTonRaffle with Ownable {
    state: Int as uint8;
    //stage 1 - epidemic
    //stage 2 - claim viruses
    //stage 3 - winner choosed

    //state fields
    infected: Int as uint32 = 0;
    tickets: Int as uint64 = 0;

    //virus settings
    season_end_date: Int as uint32;
    season_target_infections: Int as uint32;
    days_for_claim: Int = 3;

    //just winners :)
    winners:map<Int, Int>;

    //raffle rules
    fun choose_winners() {
        nativeRandomizeLt();
        self.chooseWinnersForSumAndCount(1, ton("5000"));
        self.chooseWinnersForSumAndCount(1, ton("2000"));
        self.chooseWinnersForSumAndCount(1, ton("1000"));
        self.chooseWinnersForSumAndCount(100, ton("20"));
    }

    //epidemic stage logic
    external(msg: StageEpidemic) {
        require(self.state == 1, "Epidemia stage passed");
        self.requireSignature(msg.data.hash(), msg.signature);

        let msgSlice: Slice = msg.data.beginParse();
        let seqno: Int = msgSlice.loadUint(32);
        require(seqno == self.seqno, "Sequence number is not correct");
        self.seqno += 1;
        commit();
        let new_infected: Int = msgSlice.loadUint(32);

        require(new_infected >= self.infected, "New infected must be greater");
        acceptMessage();
        self.infected = new_infected;

        if (self.infected >= self.season_target_infections) {
            self.state = 2;
            self.state_start_date = now();
        }
    }

    //claim stage logic
    external(msg: StageClaim) {
        require(self.state == 2, "Wrong stage for claim operation");
        self.requireSignature(msg.data.hash(), msg.signature);

        let msgSlice: Slice = msg.data.beginParse();
        let seqno: Int = msgSlice.loadUint(32);
        require(seqno == self.seqno, "Sequence number is not correct");
        self.seqno += 1;
        commit();
        let new_tickets: Int = msgSlice.loadUint(64);

        self.tickets = new_tickets;
        acceptMessage();

        if (now() >= self.state_start_date + self.days_for_claim *  self.day_seconds) {
            self.state = 3;
            self.choose_winners();
        }
    }

    //final stage - sending TONs to winners
    receive(msg: SendRewards) {
        self.requireOwner();
        require(self.state == 3, "Wrong stage for rewards operation");
        self.state = 1;
        commit();
        self.sendRewards(msg.winners);
        self.sendCashback();
    }

    fun chooseWinnersForSumAndCount(count:Int, sum:Int) {
        let i: Int = 0;
        while(i < count) {
            let randomKey: Int = nativeRandomInterval(self.tickets);
            if (self.winners.get(randomKey) == null) {
                self.winners.set(randomKey, sum);
                i+=1;
            }
        }
    }

    //service fields and methods
    state_start_date: Int as uint32 = 0;
    seqno: Int as uint32 = 0;
    owner: Address;
    pubkey: Int as uint256;
    const day_seconds:Int = 86400;

    init(pubkey:Int, season_end_date: Int, season_target_infections: Int) {
        self.pubkey = pubkey;
        self.state = 1;
        self.state_start_date = now();
        self.season_end_date = season_end_date;
        self.season_target_infections = season_target_infections;
        self.owner = sender();
        self.winners = emptyMap();
    }

    receive(){
        self.requireOwner();
        //deploy or simple receive
    }

    receive(msg: UpdateSettings) {
        self.requireOwner();
        require(msg.season_end_date >= self.season_end_date, "New season end date must be greater");
        self.season_end_date = msg.season_end_date;
        self.days_for_claim = msg.days_for_claim;
    }

    receive(msg: ClaimIfSeasonFailed) {
        self.requireOwner();
        require(now() > self.season_end_date, "Season is not finished yet");
        self.sendCashback();
    }

    fun requireSignature(hash: Int, signature: Slice) {
        let checkBool: Bool = checkSignature(hash, signature, self.pubkey);
        require(checkBool==true, "Signature not valid");
    }

    fun sendCashback() {
        send(
            SendParameters{
                to: self.owner,
                value: 0,
                bounce: false,
                mode: SendRemainingBalance + SendIgnoreErrors
            }
        );
    }

    fun sendRewards(winners: map<Int, Address>) {
        foreach (key, address in winners) {
            let value: Int = self.winners.get(key)!!;
            send(
                SendParameters{
                    to: address,
                    value: value,
                    bounce: false,
                    mode: SendIgnoreErrors + SendPayGasSeparately,
                    body: "Congrats! You win in  @the_virus_bot raffle!".asComment()
                }
            );
        }
    }

    //getters methods
    get fun seq_no(): Int {
        return self.seqno;
    }

    get fun balance(): Int{
        return myBalance();
    }

    get fun state(): Int {
        return self.state;
    }

    get fun season_end_date(): Int {
        return self.season_end_date;
    }

    get fun days_for_claim(): Int {
        return self.days_for_claim;
    }

    get fun state_start_date(): Int {
        return self.state_start_date;
    }
    get fun claim_end_date(): Int {
        if (self.state == 2) {
            return self.state_start_date + self.days_for_claim * self.day_seconds;
        }
        return 0;
    }
    get fun season_target_infections(): Int {
        return self.season_target_infections;
    }
    get fun contract_time(): Int {
        return now();
    }
    get fun tickets(): Int {
        return self.tickets;
    }

    get fun infected(): Int {
        return self.infected;
    }

    get fun winners(): map<Int, Int>{
        return self.winners;
    }
}
