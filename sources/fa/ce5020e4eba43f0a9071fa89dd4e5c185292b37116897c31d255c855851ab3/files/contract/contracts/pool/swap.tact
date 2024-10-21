import "../msgs/pool_msg";
import "../constant";
import "../utils";

trait SwapTrait with PoolBaseTrait {
    router: Address;                     // Address of the router for managing swaps
    token0Address: Address;              // Address of the first token in the swap
    token1Address: Address;              // Address of the second token in the swap
    lpFee: Int;                          // Fee charged by LP
    protocolFee: Int;                    // Fee charged by the protocol
    refFee: Int;                         // Fee charged for referrals, if any
    reserve0: Int;                       // Current reserve of token0 in the pool
    reserve1: Int;                       // Current reserve of token1 in the pool
    totalSupply: Int;                    // Total supply of liquidity in the pool
    collectedToken0ProtocolFee: Int;     // Collected protocol fees for token0
    collectedToken1ProtocolFee: Int;     // Collected protocol fees for token1
    // Receive and handle a Swap message
    receive(msg: Swap) {
        // Ensure the message is coming from Router
        self.requireMessageFromRouter();
        // Estimate the required gas for computation
        let gasRequired = getComputeFee(40000, false);
        let msgValue = context().value;
        let mode = SendRemainingValue;
        let remainValue = 0;
        // Calculate the amount of tokens to be swapped based on the token being exchanged
        let amountOut = msg.tokenWallet == self.token0Address ? 
            calculateAmountOut(msg.refAddress, msg.amount, self.reserve0, self.reserve1, self.lpFee, self.protocolFee, self.refFee) :
            calculateAmountOut(msg.refAddress, msg.amount, self.reserve1, self.reserve0, self.lpFee, self.protocolFee, self.refFee);
        // Set the amount of token0 or token1 based on which token is being swapped
        let amount0 = msg.tokenWallet == self.token0Address ? msg.amount : 0;
        let amount1 = msg.tokenWallet == self.token0Address ? 0 : msg.amount;
        // Check for liquidity & swap conditions
        if (self.totalSupply <= 0 || amountOut.swapOut <= 0 || amountOut.swapOut < msg.minOut) {
            self.payTo(msg.queryId, PAY_TO_CODE_SWAP_REFUND_NO_LIQ, msg.fromRealUser, amount0, amount1);
            return;
        }
        // Case when token0 is being swapped
        if (amount0 > 0) {
            // Update reserves for token0 and token1
            let reserve0 = self.reserve0 + msg.amount;
            let reserve1 = self.reserve1 - (amountOut.swapOut + amountOut.protocolFeeOut + amountOut.refFeeOut);
            // Check for valid reserve balances after the swap
            if (reserve0 > MAX_COINS || reserve1 <= 0) {
                self.payTo(msg.queryId, PAY_TO_CODE_SWAP_REFUND_NO_LIQ, msg.fromRealUser, amount0, amount1);
                return;
            }
            // Handle referral fee if any
            if (amountOut.refFeeOut > 0) {
                mode = 0;
                remainValue = msgValue - gasRequired - msg.refMessageValue;
                self.payToWithValueAndMode(
                    msg.queryId,
                    PAY_TO_CODE_SWAP_REF,
                    msg.refAddress!!,
                    0, amountOut.refFeeOut,
                    msg.refMessageValue, 
                    SendIgnoreErrors,
                );
            }
            // Handle the next swap in the chain, if any
            if (msg.next != null) {
                // Send the next CBSwap message to Router
                send(
                    SendParameters {
                        to: self.router,
                        value: remainValue,
                        bounce: true,
                        mode: mode,
                        body: CbSwap {
                            queryId: msg.queryId,
                            fromUserAddress: msg.fromUserAddress,
                            tokenWallet: self.token1Address,
                            amount: amountOut.swapOut,
                            fromRealUser: msg.fromRealUser,
                            refAddress: msg.refAddress,
                            refMessageValue: msg.refMessageValue,
                            next: msg.next!!,
                        }.toCell(),
                    }
                );
            } else {
                // Complete the swap by paying out the user
                self.payToWithValueAndMode(
                    msg.queryId,
                    PAY_TO_CODE_SWAP,
                    msg.fromUserAddress,
                    0, amountOut.swapOut,
                    remainValue,
                    mode,
                );
            }
            // Update the pool reserves
            self.reserve0 = reserve0;
            self.reserve1 = reserve1;
            // Case when token0 is being swapped
        } else if (amount1 > 0) {
            // Update reserves for token0 and token1
            let reserve1 = self.reserve1 + msg.amount;
            let reserve0 = self.reserve0 - (amountOut.swapOut + amountOut.protocolFeeOut + amountOut.refFeeOut);
            // Check for valid reserve balances after the swap
            if (reserve1 > MAX_COINS || reserve0 <= 0) {
                self.payTo(msg.queryId, PAY_TO_CODE_SWAP_REFUND_NO_LIQ, msg.fromRealUser, amount0, amount1);
                return;
            }
            // Handle referral fee if any
            if (amountOut.refFeeOut > 0) {
                mode = 0;
                remainValue = msgValue - gasRequired - msg.refMessageValue;
                self.payToWithValueAndMode(
                    msg.queryId,
                    PAY_TO_CODE_SWAP_REF,
                    msg.refAddress!!,
                    amountOut.refFeeOut, 0,
                    msg.refMessageValue, 
                    SendIgnoreErrors,
                );
            }
            // Handle the next swap in the chain, if any
            if (msg.next != null){
                // Send the next CBSwap message to Router
                send(
                    SendParameters {
                        to: self.router,
                        value: remainValue,
                        bounce: true,
                        mode: mode,
                        body: CbSwap {
                            queryId: msg.queryId,
                            fromUserAddress: msg.fromUserAddress,
                            tokenWallet: self.token0Address,
                            amount: amountOut.swapOut,
                            fromRealUser: msg.fromRealUser,
                            refAddress: msg.refAddress,
                            refMessageValue: msg.refMessageValue,
                            next: msg.next!!,
                        }.toCell(),
                    }
                );
            } else {
                    // Complete the swap by paying out the user
                    self.payToWithValueAndMode(
                        msg.queryId,
                        PAY_TO_CODE_SWAP,
                        msg.fromUserAddress,
                        amountOut.swapOut, 0,
                        remainValue,
                        mode,
                    );
            }
            // Update the pool reserves
            self.reserve0 = reserve0;
            self.reserve1 = reserve1;
        }
    }
}
