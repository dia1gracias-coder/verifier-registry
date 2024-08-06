import "./messages";
import "@stdlib/deploy";

contract DedustHandler with Deployable{
    //master: Address;
    //user: Address;
    pool: Address;
    //const NONE: Address = address("");
    
    const process_fee: Int = ton("0.01");
    const dedust_fwd_ton_amount: Int = ton("0.15");
    const minimum_fee: Int = ton("0.01");
    const transfer_jetton_fee: Int = ton("0.04");

    const DEDUST_PTON: Address = address("EQDa4VOnTYlLvDJ0gZjNYm5PXfSmmtL6Vs6A_CZEtXCNICq_");
    const DEDUST_SWAP_JETTON: Int = 0xe3a0d482;
    const DEDUST_SWAP_NATIVE: Int = 0xea06185d;
    const DEDUST_SWAP_SUCCESS: Int = 0x22220000;
    const DEDUST_SWAP_FAIL: Int = 0x22220001;
    const DEDUST_JETTON: Int = 0x11330000;

    override const storageReserve: Int = ton("0.01");

    init(pool: Address) {
        self.pool = pool;
    }

    receive(msg: SwapNativeInDedust){
        //require(sender() == self.master, "not allowed");
        require(msg.amount > 0, "amount = 0");
        self.pool = msg.pool;

        let ctx: Context = context();
        let isValid: Bool = self.checkValidForDedustNative(msg.amount);
        if (!(isValid)) {
            self.forwardAll(sender(), "not valid in native".asComment(), false, null);
            return ;
        }
        self.handleDedustNative(msg);
        
    }   

    fun checkValidForDedustNative(amount: Int): Bool {
        let ctx: Context = context();
        if (ctx.value < ((self.dedust_fwd_ton_amount + self.process_fee) + amount)) {
            return false;
        }
        return true;
    }     

    fun handleDedustNative(msg: SwapNativeInDedust) {
        let body: Cell = DedustNativeSwapInfo{
            op: self.DEDUST_SWAP_NATIVE,
            query_id: msg.query_id,
            amount: msg.amount,
            pool: msg.pool,
            kind: false,
            minReturn: msg.minReturn,
            next: msg.next,
            swapParams: DedustSwapParams{
                deadline: 0,
                recipient_addr: msg.recipient_addr,
                referral_addr: msg.referral_addr,
                fufill_payload: null,
                reject_payload: null,
            }.toCell()
        }.toCell();
        self.forwardAll(self.DEDUST_PTON, body, false, null);
    }

    fun forwardAll(to: Address, body: Cell?, bounce: Bool, init: StateInit?) {
        if (myBalance() > self.storageReserve) {
            nativeReserve(self.storageReserve, ReserveExact);
            send(SendParameters{
                to: to,
                value: 0,
                bounce: bounce,
                mode: SendRemainingBalance | SendIgnoreErrors,
                body: body,
            });
        } else {
            self.forward(to,body,bounce,init);
        }

    }    
    
    receive(msg: TokenNotification){

        self.handleDedustJetton(msg);
           
    }

    fun handleDedustJetton(msg: TokenNotification) {
        let payload: Cell = DedustJettonSwapInfo{
            op: self.DEDUST_SWAP_JETTON,
            pool: self.pool,
            kind: false,
            minReturn: 0,
            next: null,
            swapParams: DedustSwapParams{
                deadline: 0,
                recipient_addr: null,
                referral_addr: null,
                fufill_payload: null,
                reject_payload: null,
            }.toCell()
        }.toCell();
        // because the fwd_payload is stored as remaining, which means i need to handle the maybe ref part.
        // otherwise, it will overflow the cell.
        // payloadRef.asSlice means that i just concat the cell into TokenTransfer cell.
        let payloadRef: Cell = beginCell().storeUint(1,1).storeRef(payload).endCell();
        let transfer: Cell = TokenTransfer{
            query_id: msg.query_id,
            amount: msg.amount,
            destination: msg.from,
            response_destination: null,
            custom_payload: null,
            forward_ton_amount: self.dedust_fwd_ton_amount,
            forward_payload: payloadRef.asSlice()
        }.toCell();
        self.forwardAll(sender(), transfer, false, null);
    }
    



    receive(msg: String) {
    }


    receive(msg: WithdrawInfo) {
        //require(sender() == self.user, "not valid");
        if (msg.isNative) {
            send(SendParameters{to: msg.to!!, value: msg.value!!, mode: SendRemainingValue, bounce:false, body: "withdraw native".asComment()});
        } else {
            self.forwardAll(msg.token!!,JettonTransfer{
                    query_id: 999,
                    amount: msg.amount!!,
                    destination: msg.to!!,
                    response_destination: sender(),
                    custom_payload: null,
                    forward_ton_amount: 0,
                    forward_payload: JettonTransferForwardPayload{is_right: false, value: "withdraw jetton".asComment().asSlice()}
                }.toCell(), false, null);
        }
    }
} 