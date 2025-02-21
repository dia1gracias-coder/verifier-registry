import "@stdlib/deploy";
import "@stdlib/ownable";
import "./lottery.tact";
import "./referral_wallet.tact";
message Draw {
    lotteryId: Int;
}
message EmergencyWithdraw {
    lotteryId: Int;
}
message SetOperator {
    operator: Address;
}

message Create {
    price: Int;
    endTime: Int;
    discountDivisor: Int;
}

contract LotteryFactory with Deployable, Ownable {
    owner: Address;
    operator: Address;
    lotteryCnt: Int as uint256;
    referrers: map<Int, Address>;
    referrer_cnt: Int;
    withdraw_end: Int as uint256;
    //////////////////////////
    // const MinLengthLottery: Int = (3600 * 4) - 300;
    // const MaxLengthLottery: Int = ((3600 * 24) * 4) + 300;
    const MinTonForStorage: Int = ton("0.01");
    // const MinDiscountDivisor: Int = 300;
    //////////////////////////
    init(){
        self.owner = sender();
        self.lotteryCnt = 0;
        self.referrer_cnt = 0;
        self.withdraw_end = 0;
        self.operator = sender();
    }

    receive(msg: SetOperator){
        self.requireOwner();
        self.operator = msg.operator;
    }

    receive(msg: Create){
        require(sender() == self.owner || sender() == self.operator, "Access is denied");
        // require((msg.endTime - now()) > self.MinLengthLottery, "Lottery length outside of range");
        // require(msg.discountDivisor >= self.MinDiscountDivisor, "Discount divisor too low");
        let init: StateInit = initOf Lottery(myAddress(), self.lotteryCnt);
        send(SendParameters{
                to: contractAddress(init),
                value: ton("0.085"),
                mode: SendIgnoreErrors,
                code: init.code,
                data: init.data,
                body: CreateLottery{
                    creator: self.owner,
                    operator: self.operator,
                    endTime: msg.endTime,
                    price: msg.price,
                    discountDivisor: msg.discountDivisor
                }.toCell()
            }
        );
        self.lotteryCnt = self.lotteryCnt + 1;
    }

    receive(msg: Draw){
        require(sender() == self.owner || sender() == self.operator, "Access is denied");
        let init: StateInit = initOf Lottery(myAddress(), msg.lotteryId);
        send(SendParameters{
                to: contractAddress(init),
                value: ton("0.035"),
                mode: SendIgnoreErrors,
                code: init.code,
                data: init.data,
                body: "draw".asComment()
            }
        );
        self.withdraw_end = now() + (3660 * 72);
    }

    receive("createRefWallet"){
        self.referrer_cnt = self.referrer_cnt + 1;
        let init: StateInit = initOf ReferralWallet(myAddress(), self.referrer_cnt);
        send(SendParameters{
                to: contractAddress(init),
                value: ton("0.015"),
                mode: SendIgnoreErrors,
                code: init.code,
                data: init.data,
                body: CreateWallet{owner: sender()}.toCell()
            }
        );
        self.referrers.set(self.referrer_cnt, sender());
    }

    receive("withdraw_ref"){
        let seqno = self.reffererNumber(sender());
        let init: StateInit = initOf ReferralWallet(myAddress(), seqno);
        send(SendParameters{
                to: contractAddress(init),
                value: ton("0.01"),
                mode: SendIgnoreErrors,
                code: init.code,
                data: init.data,
                body: "withdraw".asComment()
            }
        );
    }

    receive(msg: EmergencyWithdraw){
        self.requireOwner();
        let init: StateInit = initOf Lottery(myAddress(), msg.lotteryId);
        send(SendParameters{
                to: contractAddress(init),
                value: ton("0.01"),
                mode: SendIgnoreErrors,
                code: init.code,
                data: init.data,
                body: Withdraw{target: sender()}.toCell()
            }
        );
    }

    get fun lotteryCnt(): Int {
        return self.lotteryCnt;
    }

    get fun lotteryAddress(seqno: Int): Address {
        return contractAddress(initOf Lottery(myAddress(), seqno));
    }

    get fun referrerWalletAddress(user: Address): Address {
        let seqno = self.reffererNumber(user);
        return contractAddress(initOf ReferralWallet(myAddress(), seqno));
    }

    get fun reffererNumber(user: Address): Int {
        let i = 0;
        while (i <= self.referrer_cnt) {
            i = i + 1;
            if (self.referrers.get(i)!! == user) {
                return i;
            }
        }
        return i;
    }
}