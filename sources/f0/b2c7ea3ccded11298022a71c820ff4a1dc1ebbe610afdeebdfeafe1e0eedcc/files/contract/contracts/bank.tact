import "@stdlib/deploy";
import "./types.tact";
import "./account.tact";
import "./credit.tact";

/*
  BANK
  author: @a3_ton
*/

const DIVIDENDS: Int = 70;

contract Bank with Deployable {
    admin: Address;
    bot: Address;
    creditPremium: Int as uint8;
    init(admin: Address, bot: Address){
        self.admin = admin;
        self.bot = bot;
        self.creditPremium = 10;
    }

    receive(msg: CreateAccount){
        let init: StateInit = initOf Account(sender(), myAddress());
        let address: Address = contractAddress(init);
        send(SendParameters{
                to: address,
                value: 0,
                mode: SendRemainingValue,
                code: init.code,
                data: init.data,
                body: "done".asComment()
            }
        );
    }

    receive(msg: OwnershipAssignedWithCredit){
        let sender: Address = sender();
        let value: Int = context().value;
        if (value < ton("0.15")) {
            // Вернуть обратно при нехватке газа
            send(SendParameters{
                    to: sender,
                    value: 0,
                    bounce: true,
                    mode: SendRemainingValue,
                    body: Transfer{
                        queryId: msg.queryId,
                        newOwner: msg.prevOwner,
                        responseDestination: msg.prevOwner,
                        customPayload: null,
                        forwardAmount: 0,
                        forwardPayload: beginCell().storeInt(0, 1).endCell().asSlice()
                    }.toCell()
                }
            );
            return ;
        }
        let payload: CreditData = msg.forwardPayload;
        let init: StateInit = initOf Credit(payload);
        let address: Address = contractAddress(init);
        send(SendParameters{
                to: address,
                value: ton("0.05"),
                mode: SendIgnoreErrors,
                code: init.code,
                data: init.data,
                body: "done".asComment()
            }
        );
        nativeReserve((myBalance() - value), 0);
        send(SendParameters{
                to: sender,
                value: 0,
                bounce: true,
                mode: SendRemainingBalance,
                body: Transfer{
                    queryId: msg.queryId,
                    newOwner: address,
                    responseDestination: msg.prevOwner,
                    customPayload: null,
                    forwardAmount: ton("0.05"),
                    forwardPayload: beginCell().storeInt(0, 1).endCell().asSlice()
                }.toCell()
            }
        );
    }

    receive(msg: Income){
        throw(0);
    }

    receive(msg: AccountIssue){
        let creditAgents: CreditAgents = CreditAgents{borrower: msg.borrower, lender: sender()};
        let creditService: CreditService = CreditService{pawn: msg.pawn};
        let creditData: CreditData = CreditData{
            size: msg.size,
            interest: msg.interest,
            duration: msg.duration,
            addresses: beginCell().storeRef(creditAgents.toCell()).storeRef(creditService.toCell()).endCell()
        };
        let init: StateInit = initOf Credit(creditData);
        let address: Address = contractAddress(init);
        let premium: Int = msg.size * self.creditPremium / PERCENT_BASE;
        send(SendParameters{
                to: sender(),
                value: 0,
                mode: SendRemainingValue,
                body: BankIssueCredit{size: msg.size, address: address, premium: premium}.toCell()
            }
        );
    }

    receive(msg: SetProportion){
        require(sender() == self.bot, "Insufficient privelegies");
        let init: StateInit = initOf Account(msg.user, myAddress());
        let address: Address = contractAddress(init);
        send(SendParameters{
                to: address,
                value: 0,
                mode: SendRemainingValue,
                body: AccountProportion{proportion: msg.proportion}.toCell()
            }
        );
    }

    receive(msg: Settings){
        require(sender() == self.admin, "Insufficient privelegies");
        self.bot = msg.bot;
        self.creditPremium = msg.premium;
    }

    receive(msg: Payout){
        require(sender() == self.admin, "Insufficient privelegies");
        let profit: Int = (myBalance() - GAS_INSURANCE);
        let dividends: Int = profit * DIVIDENDS / PERCENT_BASE;
        send(SendParameters{to: msg.contract, value: dividends, mode: 0, body: "Dividends payout".asComment()});
        send(SendParameters{to: self.admin, value: (profit - dividends), mode: 0, body: "Team payout".asComment()});
    }

    receive(msg: GetNft){
        require(sender() == self.admin, "Invalid privelegies");
        send(SendParameters{
                to: msg.nft,
                value: 0,
                bounce: true,
                mode: SendRemainingValue,
                body: Transfer{
                    queryId: 0,
                    newOwner: self.admin,
                    responseDestination: self.admin,
                    customPayload: null,
                    forwardAmount: msg.forward,
                    forwardPayload: msg.payload // beginCell().storeInt(0, 1).endCell().asSlice()
                }.toCell()
            }
        );
    }

    receive(msg: Destroy){
        require(sender() == self.admin, "Invalid privelegies");
        send(SendParameters{to: self.admin, value: 0, mode: SendRemainingBalance, body: "Destroy payout".asComment()});
    }

    get fun account(owner: Address): Address {
        let init: StateInit = initOf Account(owner, myAddress());
        return contractAddress(init);
    }

    get fun credit(data: CreditData): Address {
        let init: StateInit = initOf Credit(data);
        return contractAddress(init);
    }

    get fun balance(): Int {
        return (myBalance() - STORAGE);
    }
}