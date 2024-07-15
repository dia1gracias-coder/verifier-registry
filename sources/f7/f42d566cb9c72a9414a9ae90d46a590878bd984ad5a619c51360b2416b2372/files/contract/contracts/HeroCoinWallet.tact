import "@stdlib/ownable";
import "./constants/Error.tact";
import "./messages/Jetton.tact";
import "./traits/Valuable.tact";

struct JettonWalletData {
    balance: Int;     // Current balance of the jetton wallet.
    owner: Address;   // Owner address of the jetton wallet.
    master: Address;  // Master contract bound to the jetton wallet.
    walletCode: Cell; // Jetton wallet's code.
}

/**
 * @dev This contract implements jetton wallet contract for Hero Coin according to 
 * the Jettons standard specification
 * https://github.com/ton-blockchain/TEPs/blob/master/text/0074-jettons-standard.md.
 *
 * It is used to send, to receive and to burn jettons. Each jetton wallet's contract
 * stores wallet balance information for specific users.
 */
@interface("org.ton.jetton.wallet")
contract HeroCoinWallet with Valuable {
    balance: Int;
    owner: Address;
    master: Address;

    /**
     * @dev Initializes the contract with the following parameters:
     * - `master` is the master contract address.
     * - `owner` is the owner address of the current contract.
     */
    init(master: Address, owner: Address) {
        self.balance = 0;
        self.owner = owner;
        self.master = master;
    }

    /**
     * @dev Handles a message to transfer jettons from the sender's TON wallet
     * address to her jetton wallet address.
     * 
     * Requirements:
     * - The sender is restricted to the address who is the owner of the current
     *   jetton wallet.
     * - The current jetton wallet should have sufficient balance.
     * - The message should contain enough Toncoins to process this operation, to
     *   deploy recipient's jetton wallet if needed and to send extra Toncoins for
     *   a transfer notification if enabled.
     * 
     * Actions:
     * - Sends the InternalTransfer message to the recipient's jetton wallet.
     */
    receive(msg: Transfer) {
        let ctx: Context = context();
        nativeThrowUnless(ERROR_CODE_ACCESS_DENIED, ctx.sender == self.owner);
        self.requireValue(ctx);

        self.balance = self.balance - msg.amount; 
        require(self.balance >= 0, "Transfer: Insufficient balance");

        let stateInit: StateInit = self.getJettonWalletInit(msg.destination);  
        send(SendParameters{
            to: contractAddress(stateInit), 
            value: 0,
            mode: SendRemainingValue, 
            bounce: false,
            body: InternalTransfer{
                query_id: msg.query_id,
                amount: msg.amount,
                from: self.owner,
                response_destination: msg.response_destination,
                forward_ton_amount: msg.forward_ton_amount,
                forward_payload: msg.forward_payload
            }.toCell(),
            code: stateInit.code,
            data: stateInit.data
        });
    }

    /**
     * @dev Handles a message to transfer jettons from the sender's jetton wallet
     * address to the recipient's jetton wallet address.
     * 
     * Requirements:
     * - The sender is restricted to the master contract or the sender's jetton
         wallet.
     * - The current jetton wallet should have positive balance as a result.
     * 
     * Actions:
     * - Sends the TransferNotification message to the owner of jetton wallet if
     *   reserving enough Toncoins for such an operation.
     * - Sends the Excesses message with remaining Toncoins to the transfer initiator.
     */
    receive(msg: InternalTransfer) {
        let ctx: Context = context();
        if (ctx.sender != self.master) {
            let stateInit: StateInit = self.getJettonWalletInit(msg.from);
            nativeThrowUnless(ERROR_CODE_ACCESS_DENIED, ctx.sender == contractAddress(stateInit));
        }

        self.balance = self.balance + msg.amount;
        require(self.balance >= 0, "Internal Transfer: Insufficient balance"); 
        
        if (msg.forward_ton_amount > 0) { 
            send(SendParameters{
                to: self.owner,
                value: msg.forward_ton_amount,
                mode: SendPayGasSeparately + SendIgnoreErrors,
                bounce: false,
                body: TransferNotification {
                    query_id: msg.query_id,
                    amount: msg.amount,
                    from: msg.from,
                    forward_payload: msg.forward_payload
                }.toCell()
            });
        }

        let value: Int = self.getRemainingValue(ctx.value) - msg.forward_ton_amount - ctx.readForwardFee();
        if (value > 0) {
            send(SendParameters {
                to: msg.response_destination, 
                value: value,  
                mode: SendIgnoreErrors,
                bounce: false,
                body: Excesses { 
                    query_id: msg.query_id
                }.toCell()
            });
        }
    }

    /**
     * @dev Handles a message to burn jettons on the current jetton wallet.
     * 
     * Requirements:
     * - The sender is restricted to the owner of the jetton wallet..
     * - The current jetton wallet should have sufficient balance.
     * 
     * Actions:
     * - Sends the BurnNotification message to the master contract.
     */
    receive(msg: Burn) {
        let ctx: Context = context();
        nativeThrowUnless(ERROR_CODE_ACCESS_DENIED, ctx.sender == self.owner);

        let fwdFee: Int = ctx.readForwardFee();
        require(ctx.value > fwdFee + 2 * self.gasConsumption + self.minStorageValue, "Burn: Insufficient value");

        self.balance = self.balance - msg.amount;
        require(self.balance >= 0, "Burn: Insufficient balance");

        send(SendParameters{  
            to: self.master,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: BurnNotification{
                query_id: msg.query_id,
                amount: msg.amount,
                owner: self.owner,
                response_destination: self.owner
            }.toCell()
        });
    }

    /**
     * Handles the bounced InternalTransfer message.
     */
    bounced(msg: bounced<InternalTransfer>) {
        self.balance += msg.amount;
    }

    /**
     * Handles the bounced BurnNotification message.
     */
    bounced(msg: bounced<BurnNotification>) {
        self.balance += msg.amount;
    }

    /**
     * @dev Gets state init of the jetton wallet for a given owner.
     */
    fun getJettonWalletInit(owner: Address): StateInit {
        return initOf HeroCoinWallet(self.master, owner);
    }

    /**
     * Gets jetton wallet's information.
     */
    get fun get_wallet_data(): JettonWalletData {
        let stateInit: StateInit = self.getJettonWalletInit(self.owner);
        return JettonWalletData{
            balance: self.balance,
            owner: self.owner,
            master: self.master,
            walletCode: stateInit.code
        };
    }
}
