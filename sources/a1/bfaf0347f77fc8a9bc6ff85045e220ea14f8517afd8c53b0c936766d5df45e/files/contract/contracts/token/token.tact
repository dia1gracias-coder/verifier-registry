import "./jetton";
import "./curve";
import "../messages/mint";
import "../messages/buy";
import "../messages/sell";
import "../messages/exit";
import "@stdlib/deploy";

contract Token with Jetton, BondingCurve {
    seqno: Int as uint64;
    total_supply: Int as coins;
    owner: Address;
    creator: Address;
    bonding_curve: Bool;
    content: Cell;
    max_supply: Int;
    circulating_supply: Int;
    init(seqno: Int, owner: Address, creator: Address, content: Cell, start_amount: Int){
        self.seqno = seqno;
        self.total_supply = 0;
        self.owner = owner;
        self.creator = creator;
        self.bonding_curve = true;
        self.content = content;
        self.max_supply = 1000000000 * pow(10, 9); // 1B * 10^9
        self.circulating_supply = 0;
    }

    //////////////////////////////////////////////////////////////////////
    // ** RECEIVER METHODS **
    //////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////
    // METHOD: Token_New
    // DESCRIPTION: This method is used to mint new tokens
    // If less than 0.2 TON are provided when calling this method,
    // the creator will not receive any tokens.
    //////////////////////////////////////////////////////////////////////
    receive(msg: Token_New){
        let ctx: Context = context();
        require(msg.initial_sender == self.creator, "CALLER_NOT_CREATOR");
        require(ctx.sender == self.owner, "TOKEN_NOT_OWNER");
        require(self.total_supply == 0, "TOKEN_ALREADY_MINTED");
        if (ctx.value > ton("0.2")) {
            let amountIn: Int = self.estimate_buy_curve_piecewise(msg.amountOut, 0, self.circulating_supply, 0);
            let tonAfterFee: Int = (ctx.value - ton("0.2"));
            require(tonAfterFee >= amountIn, "MINTING_INSUFFICIENT_TONS");
            require(amountIn >= ton("0"), "MINTING_INSUFFICIENT_TONS");
            self.mint(msg.initial_sender, msg.amountOut, msg.initial_sender);
            self.circulating_supply += msg.amountOut;
        }
        // Mint to the minter wallet which stores all tokens for the bonding curve
        self.mint(self.owner, (self.CURVE_MAX_SUPPLY - msg.amountOut), msg.initial_sender);
    }

    //////////////////////////////////////////////////////////////////////
    // METHOD: Curve_Buy
    receive(msg: Curve_Buy){
        require(self.bonding_curve, "CURVE_BONDING_DISABLED");
        let ctx: Context = context();
        let tonAfterFee: Int = (ctx.value - ton("0.1"));
        require(tonAfterFee > ton("0"), "INSUFFICIENT_FUNDS");
        require(tonAfterFee >= msg.amountIn, "INSUFFICIENT_FUNDS");
        let output: Int = self.estimate_buy_curve_piecewise(msg.amountIn,
            msg.amountOut,
            self.circulating_supply,
            msg.slippage
        );
        let output_under: Int = msg.amountOut * (100 - msg.slippage) / 100;
        let output_over: Int = msg.amountOut * (100 + msg.slippage) / 100;
        require(output >= output_under && output <= output_over, "USER_OUTPUT_BEYOND_SLIPPAGE");
        self.circulating_supply += output;
        let minterWallet: StateInit = initOf JettonDefaultWallet(self.owner, myAddress());
        // send the tokens from our wallet to the buyer
        // FROM: MINTER WALLET
        // TO: SENDER OF THE MESSAGE (BUYER)
        send(SendParameters{
                to: contractAddress(minterWallet),
                value: (ctx.value - msg.amountIn),
                // mode: SendRemainingValue,
                bounce: true,
                body: TokenTransfer{
                    query_id: 0,
                    destination: ctx.sender,
                    amount: output,
                    response_destination: ctx.sender,
                    forward_ton_amount: 0,
                    forward_payload: beginCell().endCell().asSlice()
                }.toCell()
            }
        );
    }

    //////////////////////////////////////////////////////////////////////
    // METHOD: Curve_Sell
    receive(msg: Curve_Sell){
        require(self.bonding_curve, "CURVE_BONDING_DISABLED");
        let ctx: Context = context();
        require(ctx.value > ton("0.11"), "INSUFFICIENT_FUNDS");
        require(msg.amountIn > 0, "AMOUNT_IN_0");
        // calculate the amount of tons we need to send to the seller
        let output: Int = self.estimate_sell_curve_piecewise(msg.amountIn,
            msg.amountOut,
            self.circulating_supply,
            msg.slippage
        );
        let min_amount_out: Int = msg.amountOut * (100 - msg.slippage) / 100;
        require(output >= min_amount_out, "USER_OUTPUT_UNDER_SLIPPAGE");
        require(myBalance() >= output, "CURVE_OUT_OF_FUNDS");
        let senderWallet: StateInit = initOf JettonDefaultWallet(ctx.sender, myAddress());
        // sender sends minter the tokens
        // FROM: SENDER OF THE MESSAGE (SELLER)
        // TO: OUR MINTER WALLET
        send(SendParameters{
                to: contractAddress(senderWallet),
                value: (ctx.value - ton("0.01")), // leave 0.05 TON for the fee of the next call
                mode: SendRemainingValue,
                bounce: true,
                body: TokenTransfer{
                    query_id: 0,
                    destination: self.owner,
                    amount: msg.amountIn,
                    response_destination: ctx.sender,
                    forward_ton_amount: 0,
                    forward_payload: beginCell().endCell().asSlice()
                }.toCell()
            }
        );
        // send the TON coins to the seller
        // FROM: OUR CONTRACT
        // TO: SENDER OF THE MESSAGE (SELLER)
        send(SendParameters{
                to: ctx.sender,
                value: (output + ton("0.01")), // leave 0.05 TON for the fee of the next call
                bounce: false,
                mode: (SendRemainingValue + SendIgnoreErrors)
            }
        );
    }

    //////////////////////////////////////////////////////////////////////
    // METHOD: Token_Exit
    // DESCRIPTION: This method is used to exit the bonding curve
    // It sends all the remaining tokens to the minter contract which calls
    // STON.fi to create a liquidity pool using our TONs and 200M jettons.
    receive(msg: TOKEN_EXIT_START){
        let ctx: Context = context();
        require(self.circulating_supply == self.CURVE_MAX_SUPPLY, "CURVE_NOT_EMPTY");
        require(ctx.sender == self.owner, "SENDER_NOT_MINTER");
        self.bonding_curve = false;
        // MINT TO MINTER CONTRACT
        self.mint(self.owner, self.STON_MAX_SUPPLY, self.owner);
        send(SendParameters{
                to: self.owner,
                body: TOKEN_EXIT{creator: self.creator, min_lp_out: msg.min_lp_out}.toCell(),
                value: myBalance(),
                bounce: true,
                mode: (SendRemainingValue + SendIgnoreErrors)
            }
        );
    }
}