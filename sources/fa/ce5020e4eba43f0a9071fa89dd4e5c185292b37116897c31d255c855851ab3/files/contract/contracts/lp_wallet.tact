import "@stdlib/deploy";
import "./msgs/wallet_msg.tact";
import "./constant";


@interface("org.ton.jetton.wallet")
contract LpWallet {
    const minTonsForStorage: Int = ton("0.01");
    const gasConsumption: Int = ton("0.01");

    balance: Int as coins = 0;
    owner: Address;
    master: Address;
    init(owner: Address, master: Address){
        self.owner = owner;
        self.master = master;
    }

    //token transfers
    receive(msg: TokenTransfer){
        // 0xf8a7ea5
        let ctx: Context = context(); // Check sender
        nativeThrowUnless(ONLY_WALLET_OWNER, sender() == self.owner);

        let fwd_count = msg.forwardTonAmount > 0 ? 2 : 1;
        let final: Int =
        (((ctx.readForwardFee() * fwd_count + 2 * self.gasConsumption) + self.minTonsForStorage) + msg.forwardTonAmount); // Gas checks
        nativeThrowUnless(INVALID_VALUE, ctx.value > final);

        // Update balance
        self.balance = (self.balance - msg.amount);
        nativeThrowUnless(INVALID_BALANCE, self.balance >= 0);

        let init: StateInit = initOf LpWallet(msg.destination, self.master);
        let wallet_address: Address = contractAddress(init);
        send(SendParameters{
          to: wallet_address,
          value: 0,
          mode: SendRemainingValue,
          bounce: true,
          body: TokenTransferInternal{
            // 0x178d4519
            queryId: msg.queryId,
            amount: msg.amount,
            from: self.owner,
            responseDestination: msg.responseDestination,
            forwardTonAmount: msg.forwardTonAmount,
            forwardPayload: msg.forwardPayload
          }.toCell(),
          code: init.code,
          data: init.data
          });
    }

    //internal message handlers
    receive(msg: TokenTransferInternal){
        // 0x178d4519
        let ctx: Context = context();
        if (ctx.sender != self.master) {
            let sinit: StateInit = initOf LpWallet(msg.from, self.master);
            nativeThrowUnless(INVALID_SENDER, contractAddress(sinit) == ctx.sender);
        }
        // Update balance
        self.balance = (self.balance + msg.amount);
        nativeThrowUnless(INVALID_BALANCE, self.balance >= 0);

        // Get value for gas
        let msg_value: Int = self.msg_value(ctx.value);
        let fwd_fee: Int = ctx.readForwardFee();
        if (msg.forwardTonAmount > 0) {
            msg_value = ((msg_value - msg.forwardTonAmount) - fwd_fee);
            send(SendParameters{
              to: self.owner,
              value: msg.forwardTonAmount,
              mode: SendPayGasSeparately,
              bounce: false,
              body: TokenNotification{
                // 0x7362d09c -- Remind the new Owner
                queryId: msg.queryId,
                amount: msg.amount,
                from: msg.from,
                forwardPayload: msg.forwardPayload
               }.toCell()
            });
        }
        // 0xd53276db -- Cashback to the original Sender
        if (msg.responseDestination != null && msg_value > 0) {
            send(SendParameters{
              to: msg.responseDestination!!,
              value: msg_value,
              bounce: false,
              body: TokenExcesses{
              queryId: msg.queryId}.toCell(),
              mode: SendIgnoreErrors
            });
        }
    }

    //burning tokens
    receive(msg: TokenBurn){
        let ctx: Context = context();
        nativeThrowUnless(ONLY_WALLET_OWNER, sender() == self.owner);// Check sender

        self.balance = (self.balance - msg.amount); // Update balance
        nativeThrowUnless(INVALID_BALANCE, self.balance >= 0);

        let fwd_fee: Int = ctx.readForwardFee(); // Gas checks
        nativeThrowUnless(INVALID_VALUE, ctx.value > (fwd_fee + 2 * self.gasConsumption));//和标准有点差异

        // Burn tokens
        send(SendParameters{
          to: self.master,
          value: 0,
          mode: SendRemainingValue,
          bounce: true,
          body: TokenBurnNotification{
            queryId: msg.queryId,
            amount: msg.amount,
            sender: self.owner,
            responseDestination: msg.responseDestination
          }.toCell()
        });
    }

    fun msg_value(value: Int): Int {
        let msgValue: Int = value;
        let tonBalanceBeforeMsg: Int = (myBalance() - msgValue);
        let storageFee: Int = (self.minTonsForStorage - min(tonBalanceBeforeMsg, self.minTonsForStorage));
        msgValue = (msgValue - (storageFee + self.gasConsumption));
        return msgValue;
    }

    bounced(msg: bounced<TokenTransferInternal>){
        self.balance = (self.balance + msg.amount);
    }

    bounced(msg: bounced<TokenBurnNotification>){
        self.balance = (self.balance + msg.amount);
    }

    get fun get_wallet_data(): JettonWalletData {
        return  JettonWalletData{
                  balance: self.balance,
                  owner: self.owner,
                  master: self.master,
                  code: initOf LpWallet(self.owner, self.master).code};
    }
}
