import "../constant";
import "../lp_wallet";
import "../lp_account";

struct StateInitWithAddress {
    stateInit: StateInit;
    address: Address;
}

trait PoolBaseTrait {
    router: Address;
    token0Address: Address;
    token1Address: Address;

    fun requireMessageFromRouter() {
        nativeThrowUnless(ONLY_ROUTER, sender() == self.router);
    }

    fun requireMessageFromWallet(owner: Address) : StateInitWithAddress {
        let lpWalletInit: StateInit = initOf LpWallet(owner, myAddress());
        let lpWalletAddress: Address = contractAddress(lpWalletInit);
        nativeThrowUnless(ONLY_WALLET, sender() == lpWalletAddress);
        return StateInitWithAddress {
            stateInit: lpWalletInit,
            address: lpWalletAddress,
        }
    }

    fun requireMessageFromAccount(owner: Address) : StateInitWithAddress {
        let lpAccountInit: StateInit = initOf LpAccount(owner, myAddress());
        let lpAccountAddress: Address = contractAddress(lpAccountInit);
        nativeThrowUnless(ONLY_ACCOUNT, sender() == lpAccountAddress);
        return StateInitWithAddress {
            stateInit: lpAccountInit,
            address: lpAccountAddress,
        }
    }

    fun payTo(queryId: Int, code: Int, user: Address, amount0: Int, amount1: Int) {
        self.payToWithValueAndMode(queryId, code, user, amount0, amount1, 0, SendRemainingValue);
    }

    fun payToWithValueAndMode(queryId: Int, code: Int, user: Address, amount0: Int, amount1: Int, value: Int, mode: Int) {
        send(
            SendParameters {
                to: self.router,
                value: value,
                bounce: true,
                mode: mode,
                body: PayTo {
                    queryId: queryId,
                    owner: user,
                    exitCode: code,
                    amount0Out: amount0,
                    token0Address: self.token0Address,
                    amount1Out: amount1,
                    token1Address: self.token1Address,
                }.toCell(),
            }
        );
    }
}
