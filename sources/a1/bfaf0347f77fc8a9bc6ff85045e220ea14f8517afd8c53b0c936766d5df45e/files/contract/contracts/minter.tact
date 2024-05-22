import "./token/token";
import "./messages/mint";
import "./messages/buy";
import "./messages/sell";
import "./messages/exit";
import "./messages/token";
import "./fees/messages";
import "@stdlib/deploy";
import "@stdlib/ownable";

contract Minter with Deployable, Ownable {
    owner: Address;
    index: Int as uint32 = 0;
    record: map<Int, Address>;
    exists: map<Address, Bool>;
    FEE_MASTER: Address;
    init(seqno: Int, owner: Address, fee_master: Address){
        self.owner = owner;
        self.FEE_MASTER = fee_master;
    }
    const MIN_CREATE_FEE: Int = ton("0.05");
    const MIN_MINT_FEE: Int = ton("0.05");

    /////////////////////////////////////////////////////

    receive(msg: Minter_Create){
        let ctx: Context = context();
        let token: StateInit = initOf Token(self.index, myAddress(), ctx.sender, msg.content, msg.amountOut);
        self.record.set(self.index, contractAddress(token));
        self.exists.set(contractAddress(token), true);
        self.index = (self.index + 1);
        require(ctx.value > (self.MIN_CREATE_FEE + ton("0.2")), "INSUFFICIENT_FUNDS");
        send(SendParameters{
                to: contractAddress(token),
                value: (context().value - self.MIN_CREATE_FEE),
                // mode: SendRemainingValue,
                bounce: false,
                code: token.code,
                data: token.data,
                body: Token_New{
                    query_id: msg.query_id,
                    initial_sender: ctx.sender,
                    amountIn: msg.amountIn,
                    amountOut: msg.amountOut
                }.toCell()
            }
        );
    }

    receive(msg: TOKEN_EXIT_START){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "ONLY_OWNER");
        send(SendParameters{
                to: msg.token,
                value: 0,
                bounce: true,
                mode: SendRemainingValue,
                body: TOKEN_EXIT_START{token: msg.token, min_lp_out: msg.min_lp_out}.toCell()
            }
        );
    }

    receive(msg: TOKEN_EXIT){
        let ctx: Context = context();
        require(ctx.value > ton("0.3"), "INSUFFICIENT_FUNDS");
        require(self.exists.get(ctx.sender), "Token does not exist!");
        let ston_fi: Address = address("EQBsGx9ArADUrREB34W-ghgsCgBShvfUr4Jvlu-0KGc33Rbt");
        let p_ton: Address = address("EQBsGx9ArADUrREB34W-ghgsCgBShvfUr4Jvlu-0KGc33Rbt");
        let MINTER_PTON_WALLET: StateInit = initOf JettonDefaultWallet(myAddress(), p_ton);
        let ROUTER_TOKEN_WALLET: StateInit = initOf JettonDefaultWallet(ston_fi, ctx.sender);
        let ROUTER_PTON_WALLET: StateInit = initOf JettonDefaultWallet(ston_fi, p_ton);
        send(SendParameters{
                to: contractAddress(MINTER_PTON_WALLET),
                value: (ctx.value / 5 + ton("0.15")),
                bounce: true,
                body: TokenTransfer{
                    query_id: 0,
                    destination: ston_fi,
                    amount: ctx.value, // 200M tokens
                    response_destination: ctx.sender,
                    forward_ton_amount: 0,
                    forward_payload: PROVIDE_LP{
                        token_wallet1: contractAddress(ROUTER_TOKEN_WALLET),
                        min_lp_out: msg.min_lp_out
                    }.toCell().asSlice()
                }.toCell()
            }
        );
        let MINTER_JETTON_WALLET: StateInit = initOf JettonDefaultWallet(myAddress(), ctx.sender);
        // send the tokens from our wallet to the buyer
        // FROM: MINTER WALLET
        // TO: SENDER OF THE MESSAGE (BUYER)
        send(SendParameters{
                to: contractAddress(MINTER_JETTON_WALLET),
                value: ton("0.15"),
                bounce: true,
                body: TokenTransfer{
                    query_id: 0,
                    destination: ston_fi,
                    amount: 200000000 * 1000000000, // 200M tokens
                    response_destination: ctx.sender,
                    forward_ton_amount: 0,
                    forward_payload: beginCell().endCell().asSlice()
                }.toCell()
            }
        );
        // SEND FEES TO FEE_MASTER
        send(SendParameters{to: self.FEE_MASTER, value: 0, bounce: true, mode: SendRemainingValue});
    }

    receive(msg: TransferNotification){
        // token is to be burned
        require(self.exists.get(sender()), "Token does not exist!");
        let ourWallet: StateInit = initOf JettonDefaultWallet(myAddress(), sender());
        // burn these tokens
        send(SendParameters{
                to: contractAddress(ourWallet),
                value: 0,
                bounce: true,
                mode: SendRemainingValue,
                body: TokenBurn{
                    query_id: msg.query_id,
                    amount: msg.jetton_amount,
                    response_destination: myAddress(),
                    custom_payload: beginCell().endCell()
                }.toCell()
            }
        );
    }

    receive(msg: FEE_MASTER_NEW){
        require(sender() == self.owner, "ONLY_OWNER");
        self.FEE_MASTER = msg.fee_master;
    }

    receive(msg: TokenExcesses){}

    get fun get_fee_master(): Address {
        return self.FEE_MASTER;
    }

    get fun get_index(): Int {
        return self.index;
    }

    get fun get_address_by_index(index: Int): Address {
        return self.record.get(index)!!;
    }
}