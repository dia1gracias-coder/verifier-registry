import "@stdlib/deploy";

message AccountCredit {
    requestId: Int as uint64;
    quantity: Int as coins;
    sourceHolder: Address;
    cashbackTo: Address;
    tonForNotify: Int as coins;
}

message AccountTransfer {
    requestId: Int as uint64;
    quantity: Int as coins;
    recipient: Address;
    cashbackTo: Address;
    tonForNotify: Int as coins;
}

message AccountBurn {
    requestId: Int as uint64;
    quantity: Int as coins;
    cashbackTo: Address;
}

message SupplyDecrease {
    requestId: Int as uint64;
    quantity: Int as coins;
    accountOwner: Address;
    cashbackTo: Address;
}

contract TokenAccount {
    tokenBalance: Int as coins;
    accountOwner: Address;
    masterAddress: Address;

    init(accountOwner: Address, masterAddress: Address) {
        self.tokenBalance = 0;
        self.accountOwner = accountOwner;
        self.masterAddress = masterAddress;
    }

    receive(msg: AccountCredit) {
        let isMaster: Bool = sender() == self.masterAddress;

        let sourceWalletState: StateInit = initOf TokenAccount(msg.sourceHolder, self.masterAddress);
        let isWallet: Bool = sender() == contractAddress(sourceWalletState);

        require(isMaster || isWallet, "Unauthorized credit source");
        require(msg.quantity > 0, "Quantity must be positive");

        self.tokenBalance = self.tokenBalance + msg.quantity;
    }

    receive(msg: AccountTransfer) {
        require(sender() == self.accountOwner, "Owner only");
        require(msg.quantity > 0, "Quantity must be positive");
        require(self.tokenBalance >= msg.quantity, "Insufficient token balance");

        self.tokenBalance = self.tokenBalance - msg.quantity;

        let recipientWalletState: StateInit = initOf TokenAccount(msg.recipient, self.masterAddress);

        send(SendParameters{
            to: contractAddress(recipientWalletState),
            value: msg.tonForNotify,
            bounce: false,
            mode: SendIgnoreErrors,
            code: recipientWalletState.code,
            data: recipientWalletState.data,
            body: AccountCredit{
                requestId: msg.requestId,
                quantity: msg.quantity,
                sourceHolder: self.accountOwner,
                cashbackTo: msg.cashbackTo,
                tonForNotify: msg.tonForNotify,
            }.toCell()
        });
    }

    receive(msg: AccountBurn) {
        require(sender() == self.accountOwner, "Owner only");
        require(msg.quantity > 0, "Quantity must be positive");
        require(self.tokenBalance >= msg.quantity, "Insufficient token balance");

        self.tokenBalance = self.tokenBalance - msg.quantity;

        send(SendParameters{
            to: self.masterAddress,
            value: 0,
            bounce: true,
            mode: SendRemainingValue,
            body: SupplyDecrease{
                requestId: msg.requestId,
                quantity: msg.quantity,
                accountOwner: self.accountOwner,
                cashbackTo: msg.cashbackTo,
            }.toCell()
        });
    }

    get fun getTokenBalance(): Int {
        return self.tokenBalance;
    }

    get fun getAccountOwner(): Address {
        return self.accountOwner;
    }

    get fun getMasterAddress(): Address {
        return self.masterAddress;
    }
}
