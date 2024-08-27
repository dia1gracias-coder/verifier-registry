import "@stdlib/deploy";
import "./utils/jetton";
import "./oracleManager";

message Deposited {
    from: Address;
    amount: Int as coins;
}

message Withdrawn {
    to: Address;
    amount: Int as coins;
}

message Withdraw {
    amount: Int as coins;
}

message WithdrawFor {
    amount: Int as coins;
    to: Address;
}

contract TonDepository with Deployable, OracleManager {
    owner: Address;
    oracles: map<Address, Bool>;
    jetton_wallet: Address;

    init(owner: Address, master_jetton: Address, oracle: Address) {
        self.owner = owner;

        let init: StateInit = initOf JettonDefaultWallet(myAddress(), master_jetton);
        self.jetton_wallet = contractAddress(init);
        self.activateOracle(oracle, true);
    }

    fun withdraw(to: Address, amount: Int) {
        require(amount > 0, "Amount must be greater than 0");

        send(SendParameters{
                to: self.jetton_wallet,
                value: 0,
                mode: SendRemainingValue,
                bounce: true,
                body: TokenTransfer{ 
                    query_id: 0,
                    amount: amount,
                    destination: to,
                    response_destination: sender(),
                    forward_ton_amount: ton("0.01"),
                    forward_payload: emptySlice()
                 }.toCell()
                
            }
        );
        emit(Withdrawn{to: to, amount: amount}.toCell());
    }

    // The notification from the Jetton Token contract - when current address (as owner) receive the token
    receive(deposit: TokenNotification) {
        require(sender() == self.jetton_wallet, "Funds can be deposited only from the Jetton wallet");
        emit(Deposited{from: deposit.from, amount: deposit.amount}.toCell());
    }

    // Owner withdraw
    receive(withdraw: Withdraw) {
        self.requireOwner();
        self.withdraw(self.owner, withdraw.amount);
    }

    // Oracle withdrawFor some wallet
    receive(withdraw: WithdrawFor) {
        self.requireOracle();
        self.withdraw(withdraw.to, withdraw.amount);
    }

    get fun jetton_wallet(): Address {
        return self.jetton_wallet;
    }

    receive() {}
}