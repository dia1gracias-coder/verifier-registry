import "@stdlib/deploy";
struct UserState {
    principal: Int as coins;
    lastClaim: Int as uint32; // unix seconds
}

contract Pyramid with Deployable {
    owner: Address;
    period: Int as uint32; // X seconds
    users: map<Address, UserState>; // huge map

    init(owner: Address, period: Int){
        self.owner = owner;
        self.period = period;
        // maps in storage are empty by default
    }

    // DEPOSIT: просто переводи TON на адрес контракта (без payload)
    receive(){
        let s = sender();
        let add = context().value;
        if (self.users.exists(s)) {
            let u = self.users.get(s)!!;
            u.principal += add;
            self.users.set(s, u);
        } else {
            self.users.set(s, UserState{principal: add, lastClaim: now()});
        }
    }

    // CLAIM: отправь комментарий "claim" (text message body)
    receive("claim"){
        let s = sender();
        if (!self.users.exists(s)) {
            return;
        }
        let u = self.users.get(s)!!;
        let t = now();
        if ((t - u.lastClaim) < self.period) {
            // раньше X секунд — просто ничего не делаем (без санкций)
            return;
        }

        // опоздал — доход за пропущенные периоды сгорает
        u.lastClaim = t;
        self.users.set(s, u);
        let reward = (u.principal * 20) / 100; // 20% от тела

        // выплата, если есть баланс (держим небольшой резерв на газ/фии)
        let reserve: Int = ton("0.05");
        let avail = myBalance() - reserve;
        if (avail <= 0 || reward <= 0) {
            return;
        }
        let pay = reward;
        if (pay > avail) {
            pay = avail;
        }
        send(SendParameters{to: s, value: pay, bounce: false});
    }

    // getters (удобно для фронта/скриптов)
    get fun principalOf(a: Address): Int {
        if (self.users.exists(a)) {
            return self.users.get(a)!!.principal;
        }
        return 0;
    }

    get fun lastClaimOf(a: Address): Int {
        if (self.users.exists(a)) {
            return self.users.get(a)!!.lastClaim;
        }
        return 0;
    }

    get fun pending(a: Address): Int {
        if (!self.users.exists(a)) {
            return 0;
        }
        let u = self.users.get(a)!!;
        let t = now();
        if ((t - u.lastClaim) < self.period) {
            return 0;
        }
        return (u.principal * 20) / 100;
    }
}