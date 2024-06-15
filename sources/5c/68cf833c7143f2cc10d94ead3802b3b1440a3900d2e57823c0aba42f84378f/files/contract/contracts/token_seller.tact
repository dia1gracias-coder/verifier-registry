import "./withdrawable.tact";
import "./pools/pool_messages.tact";
message Deploy {
    tokenWallet: Address;
    usdtWallet: Address;
    usdtToTokenFactor: Factor;
    tonToTokenFactor: Factor;
}
message Buy {
    queryId: Int as uint64;
}
message UpdateConfig {
    usdtToTokenFactor: Factor;
    tonToTokenFactor: Factor;
    usdtWallet: Address?;
}

struct Factor {
    numerator: Int as uint32;
    denominator: Int as uint32;
}
struct BuyRequest {
    buyer: Address;
    amount: Int as coins;
}
struct BuyStatus {
    queryId: Int as uint64;
    amount: Int as coins;
    buyer: Address;
    tonToUsdtFactor: Factor?;
    description: String;
}
const MIN_GAS_TOKEN_TRANSFER: Int = ton("0.015");
const MIN_GAS: Int = ton("0.25"); 
const MIN_GAS_TO_VESTING: Int = ton("0.1");
const ADD_TO_VESTING_MIN_GAS: Int = ton("0.15");

contract TokenSeller with WithdrawableJettonsOwner {
    owner: Address;
    vesting: Address;
    index: Int as uint8; 
    tokenAmountOnSale: Int as coins;
    tokenWallet: Address?; 
    usdtWallet: Address?; 

    usdtToTokenFactor: Factor?; 
    tonToTokenFactor: Factor?;
    buyRequests: map<Int, BuyRequest>;
    init(vesting: Address, index: Int){
        // deployer becomes owner
        self.owner = sender();
        self.vesting = vesting;
        self.index = index;
        self.tokenAmountOnSale = 0;
        self.buyRequests = emptyMap();
    }

    receive(request: Deploy){
        self.requireOwner();
        require(self.tokenWallet == null, "Already deployed");
        self.tokenWallet = request.tokenWallet;
        self.usdtWallet = request.usdtWallet;
        self.usdtToTokenFactor = request.usdtToTokenFactor;
        self.tonToTokenFactor = request.tonToTokenFactor;
    }

    receive(request: UpdateConfig){
        self.requireOwner();
        self.usdtToTokenFactor = request.usdtToTokenFactor;
        self.tonToTokenFactor = request.tonToTokenFactor;
        if (request.usdtWallet != null) {
            self.usdtWallet = request.usdtWallet;
        }
        self.reply("Config updated".asComment());
    }

    // buy with TON
    receive(request: Buy){
        require(self.tokenAmountOnSale > 0, "No tokens on sale!");
        let costs: Int = ((MIN_GAS + MIN_GAS_TO_VESTING) + ADD_TO_VESTING_MIN_GAS);
        require(context().value >= costs, "Not enough for processing");
        let tonAmount: Int = (context().value - costs);
        let tokenAmount: Int = self.mult(tonAmount, self.tonToTokenFactor!!);
         if (tokenAmount == 0) {
            return;
        }
        require(self.buyRequests.get(request.queryId) == null, "Request is already registered");
        let buyRequest: BuyRequest = BuyRequest{buyer: sender(), amount: tonAmount};
        self.buyRequests.set(request.queryId, buyRequest);
        nativeReserve((myBalance() - costs), 0);
        
       
        let notUsedTonAmount: Int = 0;
        if (tokenAmount > self.tokenAmountOnSale) {
            notUsedTonAmount = self.div((tokenAmount - self.tokenAmountOnSale), self.tonToTokenFactor!!);
            tokenAmount = self.tokenAmountOnSale;
        }
        emit(BuyStatus{
                queryId: request.queryId,
                amount: tokenAmount,
                buyer: buyRequest.buyer,
                tonToUsdtFactor: null,
                description: "Buy with TON"
            }.toCell()
        );

        self.buyRequests.set(request.queryId, null);

        self.addToVesting(request.queryId, buyRequest.buyer, tokenAmount, notUsedTonAmount);
        send(SendParameters{to: sender(), value: 0, mode: SendRemainingValue | SendIgnoreErrors});
    }

    override fun onTokenNotification(notification: TokenNotification) {
        // the owner deposits some amount of tokens for the sale
        if (sender() == self.tokenWallet && notification.from == self.owner) {
            self.deposit(notification);
            return ;
        }
        if (sender() == self.tokenWallet && notification.from == self.vesting) {
            self.tokenAmountOnSale += notification.amount;
            let buyer: Address = notification.forward_payload.loadAddress();
            emit(BuyStatus{
                    queryId: notification.queryId,
                    amount: notification.amount,
                    buyer: buyer,
                    tonToUsdtFactor: null,
                    description: "Vesting failed"
                }.toCell()
            );
            return ;
        }

    }

    bounced(msg: Slice){
        let op: Int = msg.loadUint(32);
        if (op == 0) {
            return ;
        }
        let queryId: Int = msg.loadUint(64);
        let sb: StringBuilder = beginString();
        sb.append("Request failed. Op: ");
        sb.append(op.toString());
        sb.append(". QueryId: ");
        sb.append(queryId.toString());
        emit(sb.toString().asComment());
    }

    
    receive(msg: Slice){}

    override fun requireSpecialCondition(request: Withdraw) {
        if (request.tokenWallet == self.tokenWallet) {
            require((self.tokenAmountOnSale - request.amount) >= 0, "Not enough tokens to withdraw");
            self.tokenAmountOnSale -= request.amount;
        }
    }

    fun addToVesting(queryId: Int, beneficiary: Address, amount: Int, tonValue: Int) {
        self.tokenAmountOnSale -= amount;
        self.sendTokensWithValue(self.tokenWallet!!,
            TokenTransfer{
                queryId: queryId,
                amount: amount,
                destination: self.vesting,
                response_destination: beneficiary,
                custom_payload: null,
                forward_ton_amount: ADD_TO_VESTING_MIN_GAS,
                forward_payload: beginCell().storeAddress(beneficiary).endCell().asSlice()
            },
            ((tonValue + ADD_TO_VESTING_MIN_GAS) + MIN_GAS_TO_VESTING)
        );
    }

    fun mult(input: Int, factor: Factor): Int {
        return input * factor.numerator / factor.denominator;
    }

    fun div(input: Int, factor: Factor): Int {
        return input * factor.denominator / factor.numerator;
    }

    fun deposit(notification: TokenNotification) {
        self.tokenAmountOnSale += notification.amount;
        send(SendParameters{
                bounce: false,
                to: notification.from,
                value: 0,
                body: "Deposit completed".asComment(),
                mode: SendRemainingValue | SendIgnoreErrors
            }
        );
    }

    get fun vesting(): Address {
        return self.vesting;
    }

    get fun usdtWallet(): Address? {
        return self.usdtWallet;
    }

    get fun tokenWallet(): Address? {
        return self.tokenWallet;
    }

    get fun usdtToTokenFactor(): Factor? {
        return self.usdtToTokenFactor;
    }

    get fun tonToTokenFactor(): Factor? {
        return self.tonToTokenFactor;
    }

    get fun tokenAmountOnSale(): Int {
        return self.tokenAmountOnSale;
    }

    get fun buyRequests(): map<Int, BuyRequest> {
        return self.buyRequests;
    }

    get fun index(): Int {
        return self.index;
    }
}