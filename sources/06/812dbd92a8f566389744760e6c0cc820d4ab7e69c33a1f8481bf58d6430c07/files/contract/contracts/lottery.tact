import "@stdlib/deploy";

message(0x7362d09c) TokenNotification {
    query_id: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining;
}

message(0xd53276db) TokenExcesses {
    queryId: Int as uint64;
}

message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}


message Feed {
    query_id: Int as uint64;
}

message ChangeFee{
    feePercent: Int as uint8;
}

message ChangeOwner{
    newOwner: Address;
}

message(0xea06185d) Swap{
    query_id: Int as uint64;
    amount: Int as coins;
    swap_step: SwapStep;
    swap_params: Cell;//SwapParams
}

struct SwapStep{
    pool_addr: Address;
    params: SwapStepParams;
}

struct SwapStepParams{
    kind: Bool = false;
    limit: Int as coins;
    next: Cell? = null;
}

struct SwapParams{
    deadline: Int as uint32 = 0;
    recipient_addr: Address? = null;
    referral_addr: Address? = null;
    fulfill_payload: Cell? = null;
    reject_payload: Cell? = null;
}

message FeedEvent{
    feeder: Address;
    feed_amount: Int as coins;
    win_amount: Int as coins;
}

const MIN_BALANCE: Int = ton("0.5");
const TRADE_FEE: Int = ton("0.2");
const JETTON_TRANSFER_PAYLOAD : Int = ton("0.05");

contract Lottery with Deployable {
    id: Int as uint32;
    tonVaultAddr: Address;
    poolAddr: Address;
    jettonVaultAddr: Address;
    ownerAddr: Address;
    jettonWalletAddr: Address? = null;
    feePercent: Int as uint8;

    totalJettonValue: Int as coins = 0;

    init(id: Int, poolAddr: Address, tonVaultAddr: Address, jettonVaultAddr: Address, feePercent: Int) {
        self.id = id;
        self.poolAddr = poolAddr;
        self.jettonVaultAddr = jettonVaultAddr;
        self.tonVaultAddr = tonVaultAddr;
        self.ownerAddr = sender();
        self.feePercent = feePercent;
    }

    receive(msg: TokenNotification) {
        require(msg.from == self.jettonVaultAddr, "Wrong jetton source");

        let isFirstFeed: Bool = self.totalJettonValue == 0;
        self.totalJettonValue += msg.amount;
        if (isFirstFeed){
            self.jettonWalletAddr = sender();
            return;
        }

        msg.forward_payload.loadInt(1);
        let cell: Cell = msg.forward_payload.loadRef();
        let slice: Slice = cell.beginParse();
        let senderAddress :Address = slice.loadAddress();

        let balance_twelve_percents : Int = (self.totalJettonValue / 100) *12;

        let cutted_msg_value : Int = (min(msg.amount, balance_twelve_percents)/100)*80;

        let randomValue: Int = random(0, self.totalJettonValue)+1;

        if (randomValue<=cutted_msg_value){
            let balancePercent: Int = self.totalJettonValue / 100;
            let winningValue: Int = balancePercent * (85 - self.feePercent);
            let feeValue: Int = balancePercent * self.feePercent;

            if (self.jettonWalletAddr!=null){
                send(SendParameters{
                    to: self.jettonWalletAddr!!,
                    value: JETTON_TRANSFER_PAYLOAD,
                    mode: SendPayGasSeparately + SendIgnoreErrors,
                    bounce: false,
                    body: TokenTransfer{
                        queryId: msg.query_id,
                        amount: winningValue,
                        destination: senderAddress, 
                        response_destination: senderAddress,
                        custom_payload: null,
                        forward_ton_amount: 0,
                        forward_payload: "Payout from pump pig".asComment().asSlice()
                    }.toCell()
                });

                self.totalJettonValue-=winningValue;

                emit(FeedEvent{
                    feeder: senderAddress,
                    feed_amount: msg.amount,
                    win_amount: winningValue
                }.toCell());

                send(SendParameters{
                    to: self.jettonWalletAddr!!,
                    value: myBalance() - context().value - MIN_BALANCE,
                    mode: SendPayGasSeparately + SendIgnoreErrors,
                    bounce: false,
                    body: TokenTransfer{
                        queryId: msg.query_id,
                        amount: feeValue,
                        destination: self.ownerAddr, 
                        response_destination: self.ownerAddr,
                        custom_payload: null,
                        forward_ton_amount: 0,
                        forward_payload: "Payout fee".asComment().asSlice()
                    }.toCell()
                });

                self.totalJettonValue-=feeValue;
            }

        } else {
                emit(FeedEvent{
                    feeder: senderAddress,
                    feed_amount: msg.amount,
                    win_amount: 0
                }.toCell());
        }
    }

    receive(msg: Feed){
        let tradeValue: Int = context().value;
        let balanceAfterTrade: Int = myBalance() - tradeValue;
        if (balanceAfterTrade<MIN_BALANCE){
            tradeValue -= (MIN_BALANCE-balanceAfterTrade);
        }
        send(SendParameters{
            to: self.tonVaultAddr,
            value: tradeValue,
            mode: 0,
            body: Swap{
                    query_id: msg.query_id,
                    amount: tradeValue - TRADE_FEE,
                    swap_step: SwapStep{
                        pool_addr: self.poolAddr,
                        params: SwapStepParams{
                            limit: 0
                        }
                    },
                    swap_params: SwapParams{
                            fulfill_payload: beginCell().storeAddress(sender()).endCell()
                    }.toCell()
                }.toCell()
        });
    }

    receive(msg: ChangeFee){
        require(sender() == self.ownerAddr, "Only owner is allowed to change fee");
        self.feePercent = msg.feePercent;
    }

    receive(msg: ChangeOwner){
        require(sender() == self.ownerAddr, "Only owner is allowed to change owner");
        self.ownerAddr = msg.newOwner;
    }

    receive(msg: TokenExcesses)
    {
        
    }


    get fun id(): Int {
        return self.id;
    }

    get fun getTotalAmount() : Int{
        return self.totalJettonValue;
    }

    get fun getFee(): Int {
        return self.feePercent;
    }
}
