import "@stdlib/deploy";
import "@stdlib/ownable";
import "@stdlib/stoppable";

struct Stake {
    stake: Int;
    notWithdrawn: Int;
    timestamp: Int;
    partner: Address;
    percentage: Int as uint8;
}

message Deposit {
    partner: Address;
    value: Int as coins;
}

message Reinvest {
    value: Int as coins;
}

message Withdraw {
    value: Int as coins;
}

message Migrate {
    value: Int as coins;
}

message LeaveCat {
    cat: Address;
    leave: Bool;
}

message UpdatePartner {
    account: Address;
    newPartner: Address;
}

message UpdateDepositRate {
    a: Int;
    b: Int;
    c: Int;
    d: Int;
    e: Int;
    f: Int;
    g: Int;
    h: Int;
    i: Int;
}

message UpdateRefferalsRate {
    a: Int;
    b: Int;
    c: Int;
    d: Int;
    e: Int;
    f: Int;
    g: Int;
    h: Int;
    i: Int;
    j: Int;
}

message IncrementTime {
    hours: Int;
}

contract CAT with Deployable, OwnableTransferable, Resumable {
    INIT_PERCENTAGES: map<Int, Int>; 
    INIT_AMOUNTS: map<Int, Int>;
    PERCENTAGES: map<Int, Int> ;
    val: Int as uint32;
    left: map<Address, Bool>;
    stake: map<Address, Stake>;
    stopped: Bool;
    owner: Address;
    unknown: map<Int,Stake>;
    current_time: Int;
    init() {
        self.owner = sender();
        self.current_time = now();
        self.stopped = false;
        self.val = 0;
        self.INIT_AMOUNTS.set(0, ton("50000"));
        self.INIT_AMOUNTS.set(1, ton("30000"));
        self.INIT_AMOUNTS.set(2, ton("15000"));
        self.INIT_AMOUNTS.set(3, ton("8500"));
        self.INIT_AMOUNTS.set(4, ton("3000"));
        self.INIT_AMOUNTS.set(5, ton("1500"));
        self.INIT_AMOUNTS.set(6, ton("500"));
        self.INIT_AMOUNTS.set(7, ton("50"));
        self.INIT_AMOUNTS.set(8, ton("1"));
        self.unknown.set(0, Stake{
                stake: 0, 
                notWithdrawn: 0, 
                timestamp: now(), 
                partner: newAddress(0,0), 
                percentage: 0
            });
    }

    // receive(msg: Initial) {
    //     self.INIT_PERCENTAGES.set(0, 37);
    //     self.INIT_PERCENTAGES.set(1, 35);
    //     self.INIT_PERCENTAGES.set(2, 32);
    //     self.INIT_PERCENTAGES.set(3, 30);
    //     self.INIT_PERCENTAGES.set(4, 25);
    //     self.INIT_PERCENTAGES.set(5, 20);
    //     self.INIT_PERCENTAGES.set(6, 16);
    //     self.INIT_PERCENTAGES.set(7, 12);
    //     self.INIT_PERCENTAGES.set(8, 10);

    //     self.PERCENTAGES.set(0, 100);
    //     self.PERCENTAGES.set(1, 70);
    //     self.PERCENTAGES.set(2, 50);
    //     self.PERCENTAGES.set(3, 30);
    //     self.PERCENTAGES.set(4, 20);
    //     self.PERCENTAGES.set(5, 10);
    //     self.PERCENTAGES.set(6, 10);
    //     self.PERCENTAGES.set(7, 8);
    //     self.PERCENTAGES.set(8, 5);
    //     self.PERCENTAGES.set(9, 3);
    // }

    receive() {
        send(SendParameters{
        // bounce is set to true by default
        to: sender(), // sending message back to the sender
        value: 0, // don't add Toncoins to the message...
        mode: SendRemainingValue | SendIgnoreErrors, // ...except for ones received from the sender due to SendRemainingValue
        body: "Hello, World".asComment() // asComment converts a String to a Cell with a comment
    });
    }

    receive(msg: IncrementTime) {
        self.current_time = self.current_time + msg.hours *  86400;
    }

    receive(msg: Deposit) {
        emit("Deposit processing 0".asComment());
        self.requireNotStopped();
        require(msg.partner != sender(), "Cannot set your own address as partner");
        require(msg.value > 0, "Zero amount");
        let sender: Address = sender();
        let investor_stake: Stake? = self.stake.get(sender);
        emit("Deposit processing 1".asComment());
        if (investor_stake == null) {
            self.left.set(sender, false);
            self.stake.set(sender(), Stake{
                stake: msg.value, 
                notWithdrawn: 0, 
                timestamp: self.current_time, 
                partner: msg.partner, 
                percentage: 0
            });
            self._updateNotWithdrawn(sender);
            self._updatePercentage(sender);
        } else {
            self._updateNotWithdrawn(sender);
            let investor_stake_: Stake = self.stake.get(sender)!!;
            self.stake.set(sender(), Stake{
                stake: investor_stake_.stake + msg.value, 
                notWithdrawn: investor_stake_.notWithdrawn, 
                timestamp: investor_stake_.timestamp, 
                partner: investor_stake_.partner, 
                percentage: investor_stake_.percentage
            });
            self._updatePercentage(sender);
        }
        
        emit("Deposit handled".asComment());
    }

    receive(msg: Reinvest) {
        self.requireNotStopped();
        require(msg.value > 0, "Zero amount");
        let sender: Address = sender();
        let val: Int = msg.value;
        let check_stake: Stake? = self.stake.get(sender);
        if (check_stake == null) {
            return;
        }
        self._updateNotWithdrawn(sender);
        let investor_stake: Stake = self.stake.get(sender)!!;
        require(val <= (investor_stake).notWithdrawn, "Balance too low");
        self.stake.set(sender, Stake{
            stake: (investor_stake).stake + val,
            notWithdrawn: (investor_stake).notWithdrawn - val, 
            timestamp: (investor_stake).timestamp, ///////////////////////
            partner: (investor_stake).partner, 
            percentage: (investor_stake).percentage
        });
        self._updatePercentage(sender);
        emit("Reinvest handled".asComment());
    }

    receive(msg: Withdraw) {
        self.requireNotStopped();
        require(msg.value > 0, "Zero amount");
        let sender: Address = sender();
        let check_stake: Stake? = self.stake.get(sender);
        if (check_stake == null) {
            return;
        }
        let val: Int = msg.value;
        require(self.left.get(sender) == false, "Left");
        self._updateNotWithdrawn(sender);
        let investor_stake: Stake = self.stake.get(sender)!!;
        require(val <= investor_stake.notWithdrawn, "Balance too low");
        let fee: Int = (val * 5) / 100;
        self.stake.set(sender, Stake{
            stake: investor_stake.stake, 
            notWithdrawn: investor_stake.notWithdrawn - val,
            timestamp: investor_stake.timestamp, 
            partner: investor_stake.partner, 
            percentage: investor_stake.percentage 
        });
        send(SendParameters{
            to: sender,
            bounce: true,
            value: (val/100*99) - fee,
            mode: 0
        });
        send(SendParameters{
            to: self.owner,
            bounce: true,
            value: fee,
            mode: 0
        });
        emit("User withdraw handled".asComment());
    }
    
    receive(msg: Migrate) {
        self.requireOwner();
        require(myBalance() > msg.value, "Insufficient balance");
        send(SendParameters{
            to: self.owner,
            bounce: true,
            value: msg.value,
            mode: SendRemainingValue + SendIgnoreErrors
        });
        emit("Migrate handled".asComment());
    }

    receive(msg: LeaveCat) {
        self.requireOwner();
        self.left.set(msg.cat, msg.leave);
        emit("Leave handled".asComment());
    }
    
    receive(msg: UpdatePartner) { 
        self.requireOwner();
        require(msg.account != msg.newPartner, "Cannot set user address as partner");
        let investor_stake: Stake = self.stake.get(msg.account)!!;
        self.stake.set(msg.account, Stake{
            stake: investor_stake.stake, 
            notWithdrawn: investor_stake.notWithdrawn,
            timestamp: investor_stake.timestamp, 
            partner: msg.newPartner, 
            percentage: investor_stake.percentage
        });
        emit("Update partner handled".asComment());
    }

    receive(msg: UpdateDepositRate) { 
        self.requireOwner();
        require(msg.a > msg.i, "Invalid rates");
        self.INIT_PERCENTAGES.set(0, msg.a);
        self.INIT_PERCENTAGES.set(1, msg.b);
        self.INIT_PERCENTAGES.set(2, msg.c);
        self.INIT_PERCENTAGES.set(3, msg.d);
        self.INIT_PERCENTAGES.set(4, msg.e);
        self.INIT_PERCENTAGES.set(5, msg.f);
        self.INIT_PERCENTAGES.set(6, msg.g);
        self.INIT_PERCENTAGES.set(7, msg.h);
        self.INIT_PERCENTAGES.set(8, msg.i);
        emit("UpdateDepositRate handled".asComment());
    }

    receive(msg: UpdateRefferalsRate) { 
        self.requireOwner();
        require(msg.a > msg.j, "Invalid rates");
        self.PERCENTAGES.set(0, msg.a);
        self.PERCENTAGES.set(1, msg.b);
        self.PERCENTAGES.set(2, msg.c);
        self.PERCENTAGES.set(3, msg.d);
        self.PERCENTAGES.set(4, msg.e);
        self.PERCENTAGES.set(5, msg.f);
        self.PERCENTAGES.set(6, msg.g);
        self.PERCENTAGES.set(7, msg.h);
        self.PERCENTAGES.set(8, msg.i);
        self.PERCENTAGES.set(9, msg.j);
        emit("UpdateRefferalsRate handled".asComment());
    }

    fun pendingReward(account: Address): Int {
        let investor_stake: Stake = self.stake.get(account)!!;
        return ((investor_stake.stake * ((self.current_time - investor_stake.timestamp) / 86400) * self.getPercent(account)) / 1000);
    }

    fun _updateNotWithdrawn(account: Address) {
        let sender: Address = sender();
        let pending: Int = self.pendingReward(sender);
        let investor_stake: Stake = self.stake.get(sender)!!;
        self.stake.set(sender, Stake{
            stake: investor_stake.stake, 
            notWithdrawn: investor_stake.notWithdrawn + pending,
            timestamp: self.current_time, ////////////////
            partner: investor_stake.partner, 
            percentage: investor_stake.percentage 
        });
        self._traverseTree(investor_stake.partner, pending);
    }

    fun _traverseTree(account: Address, value: Int) {
        let i: Int = 0;
        if (value > 0) {
            while (i < 10) {
                let check_stake: Stake? = self.stake.get(account);
                if (check_stake == null) {
                    return;
                }
                let investor_stake: Stake = self.stake.get(account)!!;
                if (investor_stake.stake > 0) {
                    self.stake.set(account, Stake{
                        stake: investor_stake.stake, 
                        notWithdrawn: investor_stake.notWithdrawn + ((value * self.PERCENTAGES.get(i)!!)/1000),
                        timestamp: investor_stake.timestamp, 
                        partner: investor_stake.partner, 
                        percentage: investor_stake.percentage
                    });
                }
                account = investor_stake.partner;
                i = i + 1;
            }
        }
    }

    fun getPercent(account: Address) : Int{
        let i: Int = 0;
        let investor_stake: Stake = self.stake.get(account)!!;
        while (i < 9) {
            if (investor_stake.stake >= self.INIT_AMOUNTS.get(i)!!) {
                return self.INIT_PERCENTAGES.get(i)!!;
            }
            i = i + 1;
        }
        return self.INIT_PERCENTAGES.get(4)!!;
    }

    fun _updatePercentage(account: Address): Int { 
        let i: Int = 0;
        let investor_stake: Stake = self.stake.get(account)!!;
        while (i < 9) {
            if (investor_stake.stake >= self.INIT_AMOUNTS.get(i)!!) {
                self.stake.set(account, Stake{
                    stake: investor_stake.stake, 
                    notWithdrawn: investor_stake.notWithdrawn,
                    timestamp: investor_stake.timestamp, ///////////////////
                    partner: investor_stake.partner, 
                    percentage: self.INIT_PERCENTAGES.get(i)!!
                });
                return i;
            }
            i = i + 1;
        }
        return self.INIT_PERCENTAGES.get(4)!!;
    }

    get fun get_percent(account: Address) : Int{
        let i: Int = 0;
        let investor_stake: Stake = self.stake.get(account)!!;
        while (i < 9) {
            if (investor_stake.stake >= self.INIT_AMOUNTS.get(i)!!) {
                return self.INIT_PERCENTAGES.get(i)!!;
            }
            i = i + 1;
        }
        return self.INIT_PERCENTAGES.get(4)!!;
    }

    get fun pending_reward(account: Address): Int {
        let investor_stake: Stake = self.stake.get(account)!!;
        return ((investor_stake.stake * ((self.current_time - investor_stake.timestamp) / 86400) * self.getPercent(account)) / 1000);
    }

    get fun my_stake(account: Address): Int {
        if (self.stake.get(account) == null) {
            return 0;
        }
            let investor_stake: Stake = self.stake.get(account)!!;
            return investor_stake.stake;
    }

    get fun my_not_withdrawn(account: Address): Int {
        if (self.stake.get(account) == null) {
            return 0;
        }
        let pending: Int = self.pendingReward(account);
        let investor_stake: Stake = self.stake.get(account)!!;
        return investor_stake.notWithdrawn + pending;
    }

    get fun my_partner(account: Address): Address {
        if (self.stake.get(account) == null) {
            return newAddress(0, 0);
        }
        let pending: Int = self.pendingReward(account);
        let investor_stake: Stake = self.stake.get(account)!!;
        return investor_stake.partner;
    }

    get fun cat_balance(): Int {
        return myBalance();
    }
}