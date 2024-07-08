import "@stdlib/ownable";
import "@stdlib/deploy";
import "@stdlib/stoppable"; // this would automatically import @stdlib/ownable too!
import "./messages";
struct StonFiSwapInfo {
    swap_op: Int as uint32;
    tokenB: Address;
    min_out: Int as coins;
    to_address: Address;
    ref_address: Slice as remaining;
}
struct StonFiNativeInfo {
    op: Int as uint32;
    tokenA: Address;
    receiver: Address;
    tokenB: Address;
    minReturn: Int as coins;
}
struct StonFiJettonInfo {
    op: Int as uint32;
    tokenA: Address;
    receiver: Address;
    tokenB: Address;
    minReturn: Int as coins;
}
message ChangeFwdFee {
    stonfi_fwd: Int as uint64;
}
const ERR_PARSE_STONFIJETTONINFO: Int = 200400;

contract DexRouter with Deployable, Resumable, OwnableTransferable {
    owner: Address;
    stopped: Bool;
    stonfi_router: Address;
    stonfi_fwd_ton_amount: Int as uint64;
    stonfi_txorigin: Address;
    const STONFI_JETTON: Int = 0x11220000;
    const STONFI_NATIVE: Int = 0x11220001;
    const STONFI_SWAP_OP: Int = 0x25938561;
    const STONFI_TRANSFER_BOUNCE_LOCKED: Int = 0xa0dbdcb; //transfer_bounce_locked
    const STONFI_TRANSFER_BOUNCE_INVALID_REQUEST: Int = 0x19727ea8; //transfer_bounce_invalid_request

    init(owner: Address){
        self.owner = owner;
        self.stopped = false;
        self.stonfi_router = address("EQB3ncyBUTjZUA5EnFKR5_EnOMI9V1tTEAAPaiU71gc4TiUt");
        self.stonfi_txorigin = newAddress(0, 0);
        // https://github.com/crazybee69/TonDcaBot/blob/main/contracts/ton_dca_wallet.tact#L257
        self.stonfi_fwd_ton_amount = ton("0.265");
    }

    receive(msg: TokenNotification){
        require(msg.amount > ton("1"), "at least 1 ton");
        self.requireNotStopped();
        let user: Address = msg.from;
        let payload: Slice = msg.forward_payload;
        let op: Int = payload.preloadUint(32);
        if (self.stonfi_txorigin != newAddress(0, 0)) {
            self.handleRefundJetton(msg, op);
            self.stonfi_txorigin = newAddress(0, 0);
        }
        if (op == self.STONFI_JETTON) {
            let info: StonFiJettonInfo = StonFiJettonInfo{
                op: payload.loadUint(32),
                tokenA: payload.loadAddress(),
                receiver: payload.loadAddress(),
                tokenB: payload.loadAddress(),
                minReturn: payload.loadCoins()
            };
            self.handleStonfiJetton(info, msg.query_id, msg.amount);
            self.stonfi_txorigin = msg.from;
            emit(info.toCell());
        } else if (op == self.STONFI_NATIVE) {} else {
            self.returnToken(sender(), msg.from, msg.amount, msg.query_id);
        }
    }

    fun handleRefundJetton(msg: TokenNotification, op: Int) {
        if (
            msg.from == self.stonfi_router &&
            op == self.STONFI_TRANSFER_BOUNCE_LOCKED ||
            op == self.STONFI_TRANSFER_BOUNCE_INVALID_REQUEST
        ) {
            dump("stonfi call failed");
            emit(msg.toCell());
            self.returnToken(sender(), self.stonfi_txorigin, msg.amount, msg.query_id);
            return ;
        }
    }

    fun returnToken(token: Address, to: Address, amount: Int, query_id: Int) {
        send(SendParameters{
                to: token,
                value: 0,
                mode: SendRemainingValue,
                bounce: false,
                body: TokenTransfer{
                    query_id: query_id,
                    amount: amount,
                    sender: to,
                    response_destination: to,
                    custom_payload: null,
                    forward_ton_amount: 0,
                    forward_payload: beginCell().endCell().beginParse()
                }.toCell()
            }
        );
    }

    fun handleStonfiJetton(info: StonFiJettonInfo, query_id: Int, amount: Int) {
        send(SendParameters{
                to: sender(),
                value: 0,
                mode: SendRemainingValue,
                bounce: false,
                body: TokenTransfer{
                    query_id: query_id,
                    amount: amount,
                    sender: self.stonfi_router,
                    response_destination: info.receiver,
                    custom_payload: null,
                    forward_ton_amount: self.stonfi_fwd_ton_amount,
                    forward_payload: StonFiSwapInfo{
                        swap_op: self.STONFI_SWAP_OP,
                        tokenB: info.tokenB,
                        min_out: info.minReturn,
                        to_address: info.receiver,
                        ref_address: beginCell().endCell().asSlice()
                    }.toCell().asSlice()
                }.toCell()
            }
        );
    }

    receive(msg: ChangeFwdFee){
        self.requireOwner();
        self.stonfi_fwd_ton_amount = msg.stonfi_fwd;
    }
}