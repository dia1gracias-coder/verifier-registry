import "@stdlib/deploy";
import "./types.tact";

/*
  ACCOUNT
  author: @a3_ton
*/

contract Account {
    owner: Address;
    bank: Address;
    creditProportion: Int as uint8;
    init(owner: Address, bank: Address){
        self.owner = owner;
        self.bank = bank;
        self.creditProportion = 25;
    }

    receive("done"){
        throw(0);
    }

    receive(msg: Deposit){
        throw(0);
    }

    receive(msg: Withdraw){
        require(sender() == self.owner, "Insufficient privelegies");
        let value: Int = ((myBalance() - msg.amount) - STORAGE);
        require(value > 0, "Insufficient value");
        send(SendParameters{to: self.owner, value: msg.amount, mode: SendPayGasSeparately});
    }

    receive(msg: AccountIssue){
        require(sender() == self.owner, "Insufficient privelegies");
        send(SendParameters{to: self.bank, value: 0, bounce: true, mode: SendRemainingValue, body: msg.toCell()});
    }

    receive(msg: BankIssueCredit){
        require(sender() == self.bank, "Insufficient privelegies");
        send(SendParameters{
                to: msg.address,
                value: (msg.size + msg.premium),
                bounce: true,
                mode: SendPayGasSeparately,
                body: Issue{premium: msg.premium, proportion: self.creditProportion}.toCell()
            }
        );
    }

    receive(msg: AccountDispose){
        require(sender() == self.owner, "Insufficient privelegies");
        send(SendParameters{
                to: msg.credit,
                value: 0,
                bounce: true,
                mode: SendRemainingValue,
                body: Dispose{owner: self.owner}.toCell()
            }
        );
    }

    receive(msg: GetNft){
        require(sender() == self.owner, "Invalid privelegies");
        send(SendParameters{
                to: msg.nft,
                value: 0,
                bounce: true,
                mode: SendRemainingValue,
                body: Transfer{
                    queryId: 0,
                    newOwner: self.owner,
                    responseDestination: self.owner,
                    customPayload: null,
                    forwardAmount: msg.forward,
                    forwardPayload: msg.payload
                }.toCell()
            }
        );
    }

    receive(msg: AccountProportion){
        require(sender() == self.bank, "Insufficient privelegies");
        self.creditProportion = msg.proportion;
    }

    receive(msg: Destroy){
        require(sender() == self.owner, "Invalid privelegies");
        send(SendParameters{to: self.owner, value: 0, mode: SendRemainingBalance, body: "Destroy payout".asComment()});
    }

    get fun owner(): Address {
        return self.owner;
    }

    get fun bank(): Address {
        return self.bank;
    }

    get fun balance(): Int {
        return (myBalance() - STORAGE);
    }
}