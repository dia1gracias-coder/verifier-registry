import "@stdlib/deploy";
import "./msgs/account_msg.tact";
import "./msgs/pool_msg.tact";
import "./constant.tact";

struct GetterLPAccountData {
    userAddress: Address;
    poolAddress: Address;
    amount0: Int;
    amount1: Int;
}

contract LpAccount with Deployable{

    const minTon: Int = ton("0.000001");
    const zeroTon: Int = ton("0");
    const requiredGas: Int = ton("0.01");


    amount0: Int = 0;//token0 amount  by token0 address hash >  token1 address hash
    amount1: Int = 0;//token1 amount  by token0 address hash >  token1 address hash
    userAddress: Address;//user address
    poolAddress: Address;//pool address

    init(userAddress: Address, poolAddress: Address) {
        self.userAddress = userAddress;
        self.poolAddress = poolAddress;
    }

    //get lp account info
    get fun getLPAccountData(): GetterLPAccountData {
        return GetterLPAccountData {
            userAddress: self.userAddress,
            poolAddress: self.poolAddress,
            amount0: self.amount0,
            amount1: self.amount1,
        };
    }

    //add liquidity
    receive(msg: AddLiquidity) {
        let ctx: Context = context(); // Check sender
        nativeThrowUnless(ONLY_POOL, sender() == self.poolAddress);

        self.amount0 = self.amount0 + msg.newAmount0;
        self.amount1 = self.amount1 + msg.newAmount1;
        if (msg.minLPOut > self.zeroTon && ((self.amount0 > self.minTon) && (self.amount1 > self.minTon))){
            send(SendParameters{
              to: self.poolAddress,
              value: 0,
              mode: SendRemainingBalance,
              bounce: true,
              body: CbAddLiquidity{
                queryId: msg.queryId,
                amount0: self.amount0,
                amount1: self.amount1,
                userAddress: self.userAddress,
                minLpOut:msg.minLPOut
              }.toCell()
            });
            self.amount0 = 0;
            self.amount1 = 0;
        }
    }

    //get lp account info
    receive(msg: LPAccountData) {
        self.reply(LPAccountDataResponse{
            queryId: msg.queryId,
            userAddress:self.userAddress,
            poolAddress:self.poolAddress,
            amount0:self.amount0,
            amount1:self.amount1
        }.toCell());
    }

    //refund amount
    receive(msg: RefundMe) {
        let ctx: Context = context(); // Check sender
        nativeThrowUnless(ONLY_USER, sender() == self.userAddress);
        nativeThrowUnless(NO_LIQUIDITY, self.amount0 > self.zeroTon || self.amount1 > self.zeroTon);
        send(SendParameters{
          to: self.poolAddress,
          value: 0,
          mode: SendRemainingValue,
          bounce: true,
          body: CbRefundMe{
            queryId: msg.queryId,
            amount0: self.amount0,
            amount1: self.amount1,
            userAddress: self.userAddress,
          }.toCell()
        });
        self.amount0 = 0;
        self.amount1 = 0;
    }

    //directly add liquidity
    receive(msg: DirectAddLiquidity) {
        let ctx: Context = context(); // Check sender
        nativeThrowUnless(ONLY_USER, sender() == self.userAddress);
        nativeThrowUnless(ZERO_OUTPUT, msg.minLPOut > self.zeroTon && (msg.amount0 > self.minTon && msg.amount1 > self.minTon));
        self.amount0 = self.amount0 - msg.amount0;
        self.amount1 = self.amount1 - msg.amount1;
        nativeThrowUnless(NO_LIQUIDITY, self.amount0 >= self.zeroTon && self.amount1 >= self.zeroTon);
        send(SendParameters{
          to: self.poolAddress,
          value: 0,
          mode: SendRemainingValue,
          bounce: true,
          body: CbAddLiquidity{
            queryId: msg.queryId,
            amount0: msg.amount0,
            amount1: msg.amount1,
            userAddress: self.userAddress,
            minLpOut:msg.minLPOut
          }.toCell()
        });
    }

    //reset gas
    receive(msg: ResetGas) {
        let ctx: Context = context(); // Check sender
        nativeThrowUnless(ONLY_USER, sender() == self.userAddress);
        nativeThrowUnless(INSUFFICIENT_GAS, myBalance() > self.requiredGas);
        send(SendParameters{
          to: self.userAddress,
          value: myBalance() - self.requiredGas,
          mode: 0,
          bounce: true
        });
    }
}

