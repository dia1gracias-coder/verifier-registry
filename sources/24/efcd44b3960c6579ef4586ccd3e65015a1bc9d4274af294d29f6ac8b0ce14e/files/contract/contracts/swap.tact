import "@stdlib/deploy";
import "@stdlib/ownable";

struct SwapStep {
    poolAddress: Address;
    kind: Int as uint1 = 0;
    limit: Int as coins = 0;
    nextStep: Cell?;
}

struct SwapParams {
    deadline: Int as uint32 = 0;
    recipientAddress: Address? = null;
    referralAddress: Address? = null;
    fulfillPayload: Cell? = null;
    rejectPayload: Cell? = null;
}

message(0xea06185d) NativeSwap {
    queryId: Int as uint64 = 0;
    amount: Int as coins;
    poolAddress: Address;
    kind: Int as uint1 = 0;
    limit: Int as coins = 0;
    nextStep: SwapStep? = null;
    swapParams: SwapParams;
}

contract DeDustSwapContract with Deployable, OwnableTransferable {
    owner: Address;
   
    const DEDUST_TON_VAULT: Address = address("EQDa4VOnTYlLvDJ0gZjNYm5PXfSmmtL6Vs6A_CZEtXCNICq_");
    const DEDUST_TON_USDT_POOL: Address = address("EQA-X_yo3fzzbDbJ_0bzFWKqtRuZFIRa1sJsveZJ1YpViO3r");    
    const USDT_MASTER_ADDR: Address = address("EQCxE6mUtQJKFnGfaROTKOt1lZbDiiX1kCixRv7Nw2Id_sDs");
    
    totalDeposited: Int as coins = 0;
    lastConversionTime: Int as uint64 = 0;
    conversionInterval: Int as uint64 = 86400;
    
    init(owner: Address) {
        self.owner = owner;
    }

    receive() {
        let ctx: Context = context();
        self.totalDeposited += ctx.value;
    }

    receive("convert_ton") {
        
        let currentTime: Int = now();
        require(currentTime - self.lastConversionTime >= self.conversionInterval, "Too early for next conversion");
        
        let balance: Int = myBalance();
        
        let MIN_BALANCE: Int = ton("0.1");
        let GAS_COST: Int = ton("0.05");
        let DEDUST_FEE: Int = ton("0.2");
        
        let swapAmount: Int = balance - GAS_COST - MIN_BALANCE - DEDUST_FEE;
        require(swapAmount > ton("0.1"), "Insufficient balance for swap after fees");
        
        self.swapToncoinForUSDT(swapAmount);

        self.lastConversionTime = currentTime;
    }

    fun swapToncoinForUSDT(swapAmount: Int) {
        send(SendParameters {
            // Address of the TON vault to send the message to
            to: self.DEDUST_TON_VAULT,
            // Amount to swap plus a trade fee (0.2 TON)
            value: swapAmount + ton("0.2"),
            body: NativeSwap {
                amount: swapAmount,
                // Address of the swap pool, which is the TON/USDT pair
                poolAddress: self.DEDUST_TON_USDT_POOL,
                // Set of parameters relevant for the whole swap
                swapParams: SwapParams {
                    recipientAddress: self.owner,
                    deadline: 0,
                    referralAddress: null,
                    fulfillPayload: null,
                    rejectPayload: null
                },
            }.toCell(),
        });
    }

    receive("withdraw_ton") {
        require(sender() == self.owner, "Only owner");
        send(SendParameters{
            to: self.owner,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors,
            body: emptyCell()
        });
    }

    get fun getTotalDeposited(): Int {
        return self.totalDeposited;
    }
    
    get fun getLastConversionTime(): Int {
        return self.lastConversionTime;
    }
    
    get fun contractBalance(): Int {
        return myBalance();
    }
    
    get fun getOwner(): Address {
        return self.owner;
    }
    
    get fun dedustTonVault(): Address {
        return self.DEDUST_TON_VAULT;
    }
    
    get fun dedustPool(): Address {
        return self.DEDUST_TON_USDT_POOL;
    }
    
    get fun getNextConversionTime(): Int {
        return self.lastConversionTime + self.conversionInterval;
    }
}