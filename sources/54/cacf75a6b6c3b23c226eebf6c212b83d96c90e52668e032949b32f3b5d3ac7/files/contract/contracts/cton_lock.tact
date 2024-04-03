import "@stdlib/deploy";
import "./messages";


message SetLocker {
    length: Int as uint128;
    keys: map<Int, Int>;   // 1,2,3 => time
    lockerInfo: map<Int, Int>; // time => lockAmount
}

message TokenWithdraw {
    amount: Int as uint256;
    jettonWalletAddress: Address;
    receiver: Address;
}


struct LockerInfo {
    owner: Address;
    // jettonWalletAddress: Address;
    totalAmountLocked: Int as uint256;
    totalAmountBalance: Int as uint256;
    lockerLength: Int as uint256;
    lockerMap: map<Int, Int>;
}


contract CTonLock with Deployable {

    owner: Address;
    // jettonWalletAddress: Address;

    totalAmountLocked: Int as uint256 = 0;
    totalAmountBalance: Int as uint256 = 0;

    lockerLength: Int as uint256 = 0;
    lockerTimeMap: map<Int, Int>; // index => time
    lockerMap: map<Int, Int>;    // endTime => lock amount

    init(owner: Address, totalAmount: Int) {
        self.owner = owner;
        // self.jettonWalletAddress = jettonWalletAddress;
        self.totalAmountBalance = totalAmount;
    }

    fun updateLocker() {
        let nowTime: Int = now();
        let i: Int = 0;
        repeat(self.lockerLength) {
            i = i + 1;
            let lockTime: Int = self.lockerTimeMap.get(i)!!;
            if (lockTime <= nowTime) { // open luck
                let lockedAmount: Int = self.lockerMap.get(lockTime)!!;
                if (self.totalAmountLocked > 0 && lockedAmount > 0) {
                    self.totalAmountLocked -= lockedAmount;
                    self.lockerMap.set(lockTime, 0);
                }
            }
        }
    }

    receive (msg: SetLocker) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        let i: Int = 0;
        repeat(msg.length) {
            i = i + 1;
            let lockTime: Int = msg.keys.get(i)!!;
            if (self.lockerMap.get(lockTime) == null) {
                let lockAmountTmp: Int = msg.lockerInfo.get(lockTime)!!;
                self.lockerMap.set(lockTime, lockAmountTmp);
                self.totalAmountLocked += lockAmountTmp;
                self.lockerLength += 1;
                self.lockerTimeMap.set(self.lockerLength, lockTime);
            }
        }
    }


    receive (msg: TokenWithdraw) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        self.updateLocker();
        let remainingAmount: Int = self.totalAmountBalance - msg.amount;
        require(remainingAmount >= self.totalAmountLocked, "Reject withdraw");
        self.totalAmountBalance -= msg.amount;

        send(SendParameters{
            to: msg.jettonWalletAddress,
            value: 0,
            bounce: true,
            mode: SendRemainingValue,
            body: TokenTransfer{
                query_id: 0,
                amount: msg.amount,
                sender: msg.receiver,
                response_destination: myAddress(),
                custom_payload: null,
                forward_ton_amount: 0,
                forward_payload: beginCell().storeUint(0, 1).storeUint(0, 32).endCell().asSlice()
            }.toCell()
        });
    }

    receive("ClaimFee") {
        require(sender() == self.owner, "Only owner can claim fee");
        send(SendParameters{
            to: self.owner,
            value: myBalance() - ton("0.1"),
            bounce: false,
            mode: SendPayGasSeparately
        });
    }

    get fun lockerInfo(): LockerInfo {
        return LockerInfo{
            owner: self.owner,
            // jettonWalletAddress: self.jettonWalletAddress,
            totalAmountLocked: self.totalAmountLocked,
            totalAmountBalance: self.totalAmountBalance,
            lockerLength: self.lockerLength,
            lockerMap: self.lockerMap
        };
    }
}
