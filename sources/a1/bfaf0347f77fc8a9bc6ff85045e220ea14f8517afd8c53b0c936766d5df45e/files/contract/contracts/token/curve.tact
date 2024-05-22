import "@stdlib/deploy";
import "../messages/buy";

trait BondingCurve {
    
    //////////////////////////////////////////////////////////////////////
    // ** VARIABLES **
    //
    //////////////////////////////////////////////////////////////////////
    // CIRCULATION_SUPPLY IS THE NUMBER OF TOKENS THAT ARE CIRCULATING
    circulating_supply: Int;
    // Bonding_Curve is a boolean representing whether the curve is
    // tradeable or not
    bonding_curve: Bool;
    // Owner refers to the minter contract that holds the jettons for the
    // token's bonding curve
    owner: Address;
    //////////////////////////////////////////////////////////////////////

    
    //////////////////////////////////////////////////////////////////////
    // ** CURVE CONSTANTS **
    //////////////////////////////////////////////////////////////////////

    // BONDING CURVE CAN CONTAIN A MAXIMUM OF 800M TOKENS
    const CURVE_MAX_SUPPLY: Int = 800000000 * pow(10, 9); // 800M * 10^9
    // WE MINT 200M TOKENS TO THE MINTER TO DEPOSIT INTO STON
    const STON_MAX_SUPPLY: Int = 200000000 * pow(10, 9); // 200M * 10^9
    // 9 DECIMAL PLACES FOR THE JETTON
    const DECIMALS_9: Int = 1000000000;
    // K DETERMINES THE STEEPNESS
    const K: Int = 4;
    // SCALE FACTOR FOR K
    const K_SCALE: Int = 1 * pow(10, 32);
    // INITIAL STARTING PRICE
    const MIN_PRICE: Int = 1030;
    //////////////////////////////////////////////////////////////////////


    //////////////////////////////////////////////////////////////////////
    // ** CALCULATION HELPER FUNCTIONS **
    //////////////////////////////////////////////////////////////////////

    // input is the number of TONs to spend
    // output is the number of tokens to receive
    // supply is the circulating supply of the token
    // slippage is the maximum percentage of slippage allowed
    fun estimate_buy_curve_piecewise(input: Int, output: Int, supply: Int, slippage: Int): Int {
        require(supply + input <= self.CURVE_MAX_SUPPLY, "CURVE_MAX_SUPPLY_REACHED");
        require(supply + input >= 0, "CURVE_SUPPLY_NEGATIVE");

        require(supply <= supply + output, "INVALID_INPUT");

        let low: Int = 0;
        let high: Int = output;
        let optimal_output: Int = 0;

        while (low <= high) {
            let mid: Int = (low + high) / 2;

            let calc_cost: Int = self.second_order_estimation(mid, supply);

            if (calc_cost <= input) {
                optimal_output = mid;
                low = mid + (1 * self.DECIMALS_9); // Try to find a larger valid output
            } else {
                high = mid - (1 * self.DECIMALS_9); // Try to find a smaller valid output
            }
        }

        require(
            optimal_output >= (output * (100 - slippage) / 100),
            "SLIPPAGE_EXCEEDED"
        );

        return optimal_output;
    }

    // input is the number of tons to sell
    // output is the number of TONs to receive
    // tons is the amount of tons in the bonding curve
    // slippage is the maximum percentage of slippage allowed
    fun estimate_sell_curve_piecewise(input: Int, output: Int, supply: Int, slippage: Int): Int {
        require(supply - input >= 0, "CURVE_SUPPLY_NEGATIVE");
        require(supply - input <= self.CURVE_MAX_SUPPLY, "CURVE_MAX_SUPPLY_REACHED");

        require(supply >= supply - input, "INVALID_INPUT");

        let calc_output: Int = self.second_order_estimation(-input, supply);

        require(
            calc_output >= (output * (100 - slippage) / 100),
            "SLIPPAGE_EXCEEDED"
        );
        return calc_output;
    }


    fun second_order_estimation(tokens: Int, supply: Int): Int {
        let price: Int = self.curve_buy(supply);
        let new_price: Int = self.curve_buy(supply + tokens);

        let midpoint: Int = (price + new_price) / 2;
        let half_delta: Int = abs(tokens) / 2;

        let quartile_1: Int = (price + midpoint) / 2;
        let quartile_3: Int = (midpoint + new_price) / 2;

        let cost_1: Int = half_delta * quartile_1;
        let cost_3: Int = half_delta * quartile_3;

        let calc_output: Int = (cost_1 + cost_3) / self.DECIMALS_9;

        return calc_output;
    }

    // ** Quadratic function: y = k * x^2 + b **
    // ** Gets the price of the token at a given circulating supply point **
    fun curve_buy(supply: Int): Int {
        let square: Int = supply * supply;

        return ((self.K * square) / self.K_SCALE) + self.MIN_PRICE;
    }


    //////////////////////////////////////////////////////////////////////
    // ** GETTERS **
    //////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////
    // GETTER: ESTIMATE
    // INPUTS:
    // - tokens: the number of tokens to mint
    // - supply: the current circulating supply of the token
    // OUTPUT:
    // - the estimated cost of minting the tokens
    //////////////////////////////////////////////////////////////////////
    get fun estimate(tokens: Int, supply: Int): Int {
        return self.second_order_estimation(tokens, supply);
    }
    //////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////
    // GETTER: BUY_OUTPUT
    // INPUTS:
    // - input_tons: the number of TONs to spend
    // - output_jettons: the number of tokens to receive
    // - supply: the current circulating supply of the token
    // - slippage: the maximum percentage of slippage allowed
    // OUTPUT:
    // - amount of jettons that will be minted
    //////////////////////////////////////////////////////////////////////
    get fun buy_output(input_tons: Int, output_jettons: Int, supply: Int, slippage: Int): Int {
        return self.estimate_buy_curve_piecewise(
            input_tons,
            output_jettons,
            supply,
            slippage    
        );
    }
    //////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////
    // GETTER: SELL_COST
    // INPUTS: 
    // - input_jettons: the number of tokens to sell
    // - output_tons: the number of TONs to receive
    // - supply: the current circulating supply of the token
    // - slippage: the maximum percentage of slippage allowed
    // OUTPUT:
    // - amount of TONs that will be received
    //////////////////////////////////////////////////////////////////////
    get fun sell_cost(input_jettons: Int, output_tons: Int, supply: Int, slippage: Int): Int {
        return self.estimate_sell_curve_piecewise(
            input_jettons,
            output_tons,
            supply,
            slippage
        );
    }
    //////////////////////////////////////////////////////////////////////
}
