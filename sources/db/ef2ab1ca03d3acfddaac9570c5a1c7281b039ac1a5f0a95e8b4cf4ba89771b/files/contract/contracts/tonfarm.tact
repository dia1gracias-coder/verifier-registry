import "@stdlib/deploy";
import "./messages.tact";

struct Tarif {
    life_days: Int;
    percent: Int;
}

struct Deposit {
    tarif: Int;
    amount: Int;
    time: Int;
}

struct UserInfo {
    total_dividends: Int;
    total_invested: Int;
    total_withdrawn: Int;
    total_match_bonus: Int;
    total_structure: map<Int, Int>; // Use a map for dynamic key-value pairs
    total_refCount: Int;
    total_refDeposits: Int;
}

struct Player {
    upline: Address;
    dividends: Int;
    match_bonus: Int;
    last_payout: Int;
    total_invested: Int;
    total_withdrawn: Int;
    total_match_bonus: Int;
    deposits: map<Int, Deposit>;
    structure: map<Int, Int>;
    refCount: Int;
    refDeposits: Int;
    index: Int;
}

struct ContractDataInfo {
    contract_invested: Int;
    contract_withdraw: Int;
    contract_match_bonus: Int;
}

contract TonfarmRWA with Deployable {
    owner: Address;
    mrktcap1: Address;
    mrktcap2: Address;
    mrktcap3: Address;

    invested: Int = 0;
    withdrawn: Int = 0;
    match_bonus: Int = 0;
    locked: Bool = false;

    ref_bonuses: map<Int, Int>;
    tarifs: map<Int, Tarif>;
    players: map<Address, Player>;

    init(mrktcap1: Address, mrktcap2: Address, mrktcap3: Address) {
        self.owner = myAddress();
        self.mrktcap1 = mrktcap1;
        self.mrktcap2 = mrktcap2;
        self.mrktcap3 = mrktcap3;
        self.ref_bonuses.set(0, 50);
        self.ref_bonuses.set(1, 50);
        self.ref_bonuses.set(2, 20);
        self.ref_bonuses.set(3, 5);
        self.ref_bonuses.set(4, 5);


        let tarifPercent: Int = 250;
        let tarifDuration: Int = 125;

        while(tarifDuration < 156){
            self.tarifs.set(tarifDuration, Tarif{life_days: tarifDuration, percent: tarifPercent});
            tarifPercent = tarifPercent + 3;
            tarifDuration = tarifDuration  + 1;
        }
    }

    receive(msg: Deposit_msg) {
        require(msg.tarif != null, "Not Input Tarif");
        require(msg.sender != null, "Not Input Sender Address");
        require(self.tarifs.get(msg.tarif) != null, "Tarif not found");
        require(msg.amount >= 100000000, "Minimum deposit amount is 0.1 TON");
        require(self.players.get(msg.sender) != null, "Player not found");

        let player: Player = self.players.get(msg.sender)!!;

        self._setUpline(msg.sender, msg.upline, msg.amount);

        player.deposits.set(player.index, Deposit{
            tarif: msg.tarif,
            amount: msg.amount,
            time: now()
        });

        player.index = player.index + 1;

        player.total_invested += msg.amount;
        self.invested += msg.amount;

        self._refPayout(msg.sender, msg.amount);

        let fee : Int = msg.amount * 11 / 100;
        send(SendParameters{to:self.mrktcap1, value:fee * 59 / 100});
        send(SendParameters{to:self.mrktcap2, value:fee * 33 / 100});
        send(SendParameters{to:self.mrktcap3, value:fee * 8 / 100});

        let result_player: Player = self.players.get(player.upline)!!;
        result_player.refDeposits = result_player.refDeposits + msg.amount;
    }

    receive("Withdraw") {
        let player : Player = self.players.get(context().sender)!!;
        self._payout(context().sender);

        require(player.dividends > 0 || player.match_bonus > 0, "Zero amount");

        let amount : Int = player.dividends + player.match_bonus;
        player.dividends = 0;
        player.match_bonus = 0;
        player.total_withdrawn += amount;
        self.withdrawn += amount;

        let fee : Int = amount * 11 / 100;
        let netAmount : Int = amount - fee;

        send(SendParameters{to:self.mrktcap1, value:fee * 59 / 100});
        send(SendParameters{to:self.mrktcap2, value:fee * 33 / 100});
        send(SendParameters{to:self.mrktcap3, value:fee * 8 / 100});
        send(SendParameters{to:context().sender, value:netAmount});
    }

    fun _payout(addr: Address) {
        let payout : Int = self.payoutOf(addr);
        if (payout > 0) {
            let player : Player = self.players.get(addr)!!;
            player.last_payout = now();
            player.dividends += payout;
        }
    }

    fun _refPayout(addr: Address, amount: Int) {
        let player: Player = self.players.get(addr)!!;
        let up : Address = player.upline;
        let i : Int = 0;
        while(self.ref_bonuses.get(i) == null)
        {
            if( up != null){
                let bonus : Int = self.ref_bonuses.get(i)!!;
                bonus = amount * bonus / 1000;
                let player_db : Player = self.players.get(up)!!;
                player_db.match_bonus = player_db.match_bonus + bonus;
                player_db.total_match_bonus = player_db.total_match_bonus + bonus;
                self.match_bonus = self.match_bonus + bonus;
                up = player_db.upline;
                i = i + 1;
            }
        }
    }

    fun _setUpline(addr: Address, upline: Address, amount: Int) {
        let player : Player = self.players.get(addr)!!;
        if (player.upline == null && addr != self.owner) {
            let result_player : Player = self.players.get(upline)!!;
            if (upline == null || result_player.deposits == null) {
                upline = self.owner;
            }
            player.upline = upline;
            result_player.refCount = result_player.refCount + 1;
            let current_upline : Address = upline;
            let i : Int = 0;
            while(i<5) {
                if (current_upline != null) {
                    let current_player : Player = self.players.get(current_upline)!!;
                    let current_structure : Int = current_player.structure.get(i)!!;
                    current_structure = current_structure + 1;
                    current_player.structure.set(i,current_structure);
                    current_upline = current_player.upline;
                    i = i + 1;
                }
            }
        }
    }

    fun payoutOf(addr: Address) : Int {
        let player : Player = self.players.get(addr)!!;
        let value : Int = 0;
        let i : Int = 0;
        while( player.deposits.get(i)!=null){
            let dep : Deposit = player.deposits.get(i)!!;
            let tarif : Tarif = self.tarifs.get(dep.tarif)!!;
            let time_end : Int = dep.time + tarif.life_days * 86400;
            let from : Int = max(player.last_payout, dep.time);
            let to : Int = min(now(), time_end);
            if (from < to) {
                value = value + dep.amount * (to - from) * tarif.percent / tarif.life_days / 8640000;
            }
            i = i + 1;
        }
        return value;
    }

    fun userInfo(addr: Address) : UserInfo {
        let player : Player = self.players.get(addr)!!;
        let payout : Int = self.payoutOf(addr);
        return UserInfo{
            total_dividends: payout + player.dividends + player.match_bonus,
            total_invested: player.total_invested,
            total_withdrawn: player.total_withdrawn,
            total_match_bonus: player.total_match_bonus,
            total_structure: player.structure,
            total_refCount: player.refCount,
            total_refDeposits: player.refDeposits
        };
    }

    fun contractInfo() : ContractDataInfo {
        return ContractDataInfo{ contract_invested: self.invested, contract_withdraw: self.withdrawn, contract_match_bonus: self.match_bonus};
    }
}
