import "@stdlib/deploy";
import "./messages";
import "./structs";
import "../nft_sale/nft_sale";

contract JettonExchange with Deployable {
    marketAddress: Address;
    jettonAddress: Address;
    isExchangeable: Bool;
    init(marketAddress: Address, jettonAddress: Address){
        self.marketAddress = marketAddress;
        self.jettonAddress = jettonAddress;
        self.isExchangeable = false;
    }

    receive(msg: EnableExchangeJetton){
        self.requireSenderAsMarketAddress();
        self.isExchangeable = true;
    }

    receive(msg: DisableExchangeJetton){
        self.requireSenderAsMarketAddress();
        send(SendParameters{to: self.marketAddress, value: 0, mode: SendRemainingBalance | SendDestroyIfZero});
        self.isExchangeable = false;
    }

    receive(msg: TokenTransferNotification){
        let ctx: Context = context();
        self.requireJettonIsExchangeable();
        require(ctx.sender == self.jettonAddress, "Invalid sender");
        let purchasePrice: Int = msg.amount;
        let buyerAddress: Address = msg.from;
        let queryId: Int = msg.query_id;
        let forwardPayload: Slice = msg.forward_payload;
        let subOp: Int = forwardPayload.preloadUint(32);
        let nftSaleAddress: Address = forwardPayload.loadAddress();
        
        let reverseValue: Int = self.countReverseValue(ctx.value);
        nativeReserve(reverseValue, 0);
        
        send(SendParameters{
            to:nftSaleAddress,
            value: 0,
            bounce:true,
            mode: SendRemainingValue,
            body: BuyWithAnotherJetton{
                query_id: queryId,
                purchase_price: purchasePrice,
                buyer_address: buyerAddress,
            }.toCell()
        });
    }

    bounced(msg: bounced<BuyWithAnotherJetton>){
     
    }

    fun requireSenderAsMarketAddress() {
        require(sender() == self.marketAddress, "Invalid sender");
    }

    fun requireJettonIsExchangeable() {
        require(self.isExchangeable, "This jetton is not added to market exchange tokens");
    }

    fun countReverseValue(value: Int): Int {
        let tonBalanceBeforeRecvMsg: Int = (myBalance() - value);
        return tonBalanceBeforeRecvMsg < ton("0.001") ? ton("0.001") : tonBalanceBeforeRecvMsg + ton("0.000001");
    }

    get fun get_exchange_data(): ExchangeData {
        return
            ExchangeData{
                marketAddress: self.marketAddress,
                jettonAddress: self.jettonAddress,
                isExchangeable: self.isExchangeable
            };
    }
    
}