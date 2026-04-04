import "@stdlib/deploy";
import "./token_account.tact";

message IssueUnits {
    quantity: Int as coins;
    beneficiary: Address;
}

contract LabToken with Deployable {
    administrator: Address;
    circulatingAmount: Int as coins;
    tokenTitle: String;
    tokenTicker: String;
    fractionDigits: Int as uint8;

    init(administrator: Address, tokenTitle: String, tokenTicker: String, fractionDigits: Int as uint8) {
        self.administrator = administrator;
        self.circulatingAmount = 0;
        self.tokenTitle = tokenTitle;
        self.tokenTicker = tokenTicker;
        self.fractionDigits = fractionDigits;
    }

    receive(msg: IssueUnits) {
        require(sender() == self.administrator, "Administrator only");
        require(msg.quantity > 0, "Quantity must be positive");

        self.circulatingAmount = self.circulatingAmount + msg.quantity;

        let walletState: StateInit = initOf TokenAccount(msg.beneficiary, myAddress());

        send(SendParameters{
            to: contractAddress(walletState),
            value: 0,
            bounce: false,
            mode: SendRemainingValue,
            code: walletState.code,
            data: walletState.data,
            body: AccountCredit{
                requestId: 0,
                quantity: msg.quantity,
                sourceHolder: myAddress(),
                cashbackTo: self.administrator,
                tonForNotify: 0,
            }.toCell()
        });
    }

    receive(msg: SupplyDecrease) {
        let expectedWallet: StateInit = initOf TokenAccount(msg.accountOwner, myAddress());

        require(sender() == contractAddress(expectedWallet), "Invalid burn sender");
        require(msg.quantity > 0, "Quantity must be positive");
        require(self.circulatingAmount >= msg.quantity, "Supply underflow");

        self.circulatingAmount = self.circulatingAmount - msg.quantity;
    }

    get fun getCirculatingAmount(): Int {
        return self.circulatingAmount;
    }

    get fun getAdministrator(): Address {
        return self.administrator;
    }

    get fun getTokenTitle(): String {
        return self.tokenTitle;
    }

    get fun getTokenTicker(): String {
        return self.tokenTicker;
    }

    get fun getFractionDigits(): Int {
        return self.fractionDigits;
    }
}
