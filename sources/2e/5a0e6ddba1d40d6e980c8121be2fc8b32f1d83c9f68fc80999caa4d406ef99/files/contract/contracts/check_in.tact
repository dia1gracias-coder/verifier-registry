import "@stdlib/deploy";
import "./imports/time_utils.tact";

message UserCheckIn {
    userID: Int as uint256;
}
message UserCheckInInternal {
    userID: Int as uint256;
    sender: Address;
    checkInDate: Int as uint64;
}

@interface("ai.bot3.checkin")
contract CheckIn with Deployable {
    init(){}

    receive(msg: UserCheckIn){
        let ctx: Context = context();
        let uinit: StateInit = self.getCheckInUserInit(msg.userID);
        let currentDate: Int = extract_date(now());
        send(SendParameters{
                to: contractAddress(uinit),
                value: 0,
                bounce: false,
                mode: SendRemainingValue,
                body: UserCheckInInternal{userID: msg.userID, sender: ctx.sender, checkInDate: currentDate}.toCell(),
                code: uinit.code,
                data: uinit.data
            }
        );
    }

    fun getCheckInUserInit(userID: Int): StateInit {
        return initOf CheckInUser(userID, myAddress());
    }
    // ====== Get Methods ====== //

    get fun getCurrentDate(): Int {
        return extract_date(now());
    }

    get fun getCheckInUserAddress(userId: Int): Address {
        let uinit: StateInit = self.getCheckInUserInit(userId);
        return contractAddress(uinit);
    }
}

struct CheckInUserData {
    userID: Int as uint256; // 签到用户
    master: Address; // 父合约
    checkInTime: Int as uint256; //上次签到时间
}

@interface("ai.bot3.checkin.user")
contract CheckInUser
{
    userID: Int as uint256; // 签到用户
    master: Address; // 父合约
    checkInTime: Int as uint256; //上次签到时间

    const minTonsForStorage: Int = ton("0.01");
    const gasConsumption: Int = ton("0.01");

    init(userID: Int, master: Address){
        self.userID = userID;
        self.master = master;
        self.checkInTime = 0;
    }

    receive(msg: UserCheckInInternal) {
      
        let ctx: Context = context();
        // 必须是master call
        require(ctx.sender == self.master, "Invalid sender");
        if (self.checkInTime >= msg.checkInDate) {
            // 不满足签到时间
            throw(500);
        }
        // 签到记录用户最后一次签到日期
        self.checkInTime = msg.checkInDate;
        // 将剩余的value 还回去
        let userCheckInEvent: Builder = beginCell();
        userCheckInEvent = userCheckInEvent.storeUint(msg.userID, 256); // 签到用户ID
        userCheckInEvent = userCheckInEvent.storeUint(msg.checkInDate, 64); // 签到日期
        userCheckInEvent = userCheckInEvent.storeInt(now(), 64); // 签到时间
        userCheckInEvent = userCheckInEvent.storeAddress(msg.sender); // 签到钱包

        send(SendParameters{to: msg.sender, value: self.msgValue(ctx.value), mode: SendIgnoreErrors, body: userCheckInEvent.endCell()});
    }


    // 计算出实际可以用的ton,排除存储费和转发费
    get fun msgValue(value: Int): Int {
        let msgValue: Int = value;
        let tonBalanceBeforeMsg: Int = (myBalance() - msgValue);
        let storageFee: Int = (self.minTonsForStorage - min(tonBalanceBeforeMsg, self.minTonsForStorage));
        msgValue = (msgValue - (storageFee + self.gasConsumption));
        return msgValue;
    }

    // ====== Get Methods ====== //
    get fun getCheckInUserData(): CheckInUserData {
        return CheckInUserData{userID: self.userID, master: self.master, checkInTime: self.checkInTime};
    }

    get fun getUserCheckInTime(): Int? {
        return self.checkInTime;
    }
}