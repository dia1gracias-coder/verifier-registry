import "@stdlib/deploy";
import "./types.tact";

/*
  CREDIT
  author: @a3_ton
*/

const SECONDS_PER_DAY: Int = 86400;
const PERCENT_DAY_BASE: Int = 10000;
const STATUS_NOT_INIT: Int = 0;
const STATUS_INIT: Int = 1;
const STATUS_ACTIVE: Int = 2;
const STATUS_INACTIVE: Int = 3;

contract Credit with Deployable {
    status: Int as uint8; // Статус залога
    borrower: Address; // Заёмщик
    lender: Address; // Займодавец
    pawn: Address; // Залог
    bank: Address; // Банк
    size: Int as coins; // Размер кредита в нанотонах
    interest: Int as uint16; // Процент в год
    duration: Int as uint32; // Продолжительность в секундах
    start: Int as uint32; // Время начала unixtime
    proportion: Int as uint8; // Доля ювелира в процентах
    premium: Int as coins; // Размер надбавки в нанотонах

    init(data: CreditData){
        self.status = STATUS_NOT_INIT;
        self.size = data.size;
        self.interest = data.interest;
        self.duration = data.duration;
        let addresses: Slice = data.addresses.beginParse();
        let agents: Slice = addresses.loadRef().beginParse();
        let service: Slice = addresses.loadRef().beginParse();
        self.borrower = agents.loadAddress();
        self.lender = agents.loadAddress();
        self.pawn = service.loadAddress();
        self.bank = newAddress(0, 0);
        self.start = now();
        self.proportion = 25;
        self.premium = 0;
    }

    receive(msg: OwnershipAssigned){
        require(sender() == self.pawn, "Invalid pawn");
        self.bank = msg.prevOwner;
        self.status = STATUS_INIT;
    }

    receive(msg: Issue){
        require(self.status == STATUS_INIT, "Not init");
        require(sender() == self.lender, "Invalid lender");
        self.premium = msg.premium;
        self.proportion = msg.proportion;
        require((self.size + self.premium) < (myBalance() - STORAGE), "Insufficient balance");
        send(SendParameters{to: self.borrower, bounce: true, value: self.size, mode: SendPayGasSeparately});
        self.status = STATUS_ACTIVE;
    }

     fun earned(): Int {
        let durationSeconds: Int = (now() - self.start);
        return self.size * durationSeconds * self.interest / SECONDS_PER_DAY / PERCENT_DAY_BASE;
    }

     fun arrear(): Int {
        return (self.size + self.earned());
    }

     fun redeem() {
        require(self.status == STATUS_ACTIVE, "Not active");
        let earned: Int = self.earned();
        let total: Int = (self.size + self.premium);
        require((total + earned) < (myBalance() - GAS_INSURANCE), "Insufficient debt");
        let profit: Int = earned * self.proportion / PERCENT_BASE;
        send(SendParameters{
                to: self.lender,
                value: (total + profit),
                mode: SendPayGasSeparately,
                body: Deposit{queryId: 0}.toCell()
            }
        );
        if (earned > 0) {
            send(SendParameters{
                    to: self.bank,
                    value: (earned - profit),
                    mode: SendPayGasSeparately,
                    body: Income{queryId: 0}.toCell()
                }
            );
        }
        send(SendParameters{
                to: self.pawn,
                value: 0,
                bounce: true,
                mode: SendRemainingBalance,
                body: Transfer{
                    queryId: 0,
                    newOwner: self.borrower,
                    responseDestination: self.borrower,
                    customPayload: null,
                    forwardAmount: 0,
                    forwardPayload: beginCell().storeInt(0, 1).endCell().asSlice()
                }.toCell()
            }
        );
        self.status = STATUS_INACTIVE;
    }

    receive(msg: String){
        self.redeem();
    }

    receive(msg: Redeem){
        // require(sender() == self.borrower, "Invalid borrower");
        self.redeem();
    }

    receive(msg: Dispose){
        require(self.status == STATUS_ACTIVE, "Not active");
        require(sender() == self.lender, "Invalid sender");
        require(now() >= (self.start + self.duration), "Invalid time");
        send(SendParameters{
                to: self.bank,
                value: self.premium,
                mode: SendPayGasSeparately,
                body: Income{queryId: 0}.toCell()
            }
        );
        send(SendParameters{
                to: self.pawn,
                value: 0,
                bounce: true,
                mode: SendRemainingBalance,
                body: Transfer{
                    queryId: 0,
                    newOwner: msg.owner,
                    responseDestination: msg.owner,
                    customPayload: null,
                    forwardAmount: 0,
                    forwardPayload: beginCell().storeInt(0, 1).endCell().asSlice()
                }.toCell()
            }
        );
        self.status = STATUS_INACTIVE;
    }

    receive(msg: Refuse){
        require(self.status == STATUS_ACTIVE, "Not active");
        require(sender() == self.borrower, "Invalid borrower");
        send(SendParameters{
                to: self.bank,
                value: self.premium,
                mode: SendPayGasSeparately,
                body: Income{queryId: 0}.toCell()
            }
        );
        send(SendParameters{
                to: self.pawn,
                value: 0,
                bounce: true,
                mode: SendRemainingBalance,
                body: Transfer{
                    queryId: 0,
                    newOwner: self.lender,
                    responseDestination: self.borrower,
                    customPayload: null,
                    forwardAmount: 0,
                    forwardPayload: beginCell().storeInt(0, 1).endCell().asSlice()
                }.toCell()
            }
        );
        self.status = STATUS_INACTIVE;
    }

    receive(msg: Cancel){
        require(self.status == STATUS_INIT, "Not init");
        require(sender() == self.borrower, "Invalid borrower");
        send(SendParameters{
                to: self.pawn,
                value: 0,
                bounce: true,
                mode: SendRemainingBalance,
                body: Transfer{
                    queryId: 0,
                    newOwner: self.borrower,
                    responseDestination: self.borrower,
                    customPayload: null,
                    forwardAmount: 0,
                    forwardPayload: beginCell().storeInt(0, 1).endCell().asSlice()
                }.toCell()
            }
        );
        self.status = STATUS_NOT_INIT;
    }

    receive("done"){
        throw(0);
    }

    get fun status(): Int {
        return self.status;
    }

    get fun debt(): Int {
        return self.arrear();
    }

    get fun end(): Int {
        return (self.start + self.duration);
    }
}