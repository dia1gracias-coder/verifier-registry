import "@stdlib/deploy";
import "./messages";
import "./structs";
import "../jetton_exchange/jetton_exchange";

contract NftSale with Deployable {
    const minGasAmount: Int = ton("1");
    isComplete: Bool = false;
    startAt: Int as uint32;
    finishAt: Int as uint32;
    marketAddress: Address; // aka admin address
    nftAddress: Address;
    nftOwnerAddress: Address;
    fullPrice: Int as coins;
    jettonAddress: Address;

    // fees: Royalty;

    init(isComplete: Bool,
        startAt: Int,
        finishAt: Int,
        marketAddress: Address,
        nftAddress: Address,
        nftOwnerAddress: Address,
        fullPrice: Int,
        jettonAddress: Address){
        // fees: Royalty
        require(sender() == marketAddress, "Invalid sender");
        self.startAt = startAt;
        self.finishAt = finishAt;
        self.marketAddress = marketAddress;
        self.nftAddress = nftAddress;
        self.nftOwnerAddress = nftOwnerAddress;
        self.fullPrice = fullPrice;
        self.jettonAddress = jettonAddress;
        // self.fees = fees;
    }

    receive(msg: BuyWithTon){
        let ctx: Context = context();
        require(ctx.value >= (self.minGasAmount + self.fullPrice), "Not enough funds to buy NFT");
        
        let queryId: Int = msg.query_id;
        let newNftOwnerAddress: Address = ctx.sender;
        // send seller the full price of the NFT
        send(SendParameters{
                to: self.nftOwnerAddress,
                value: (self.fullPrice + (myBalance() - ctx.value)),
                bounce: false,
                mode: SendPayGasSeparately
            }
        );
        //TODO: send marketplace fee and royalty fee

        //send nft to the new owner
        send(SendParameters{
                to: ctx.sender,
                value: 0,
                bounce: false,
                mode: SendRemainingBalance | SendDestroyIfZero,
                body: Transfer{
                    query_id: queryId,
                    new_owner: newNftOwnerAddress,
                    response_destination: newNftOwnerAddress,
                    custom_payload: emptyCell(),
                    forward_amount: 0,
                    forward_payload: emptySlice()
                }.toCell()
            }
        );
    }

    receive(msg: BuyWithAnotherJetton){
        let ctx: Context = context();
        let exchangeJettonStateInit: StateInit = initOf JettonExchange(self.marketAddress, self.jettonAddress);
        require(contractAddress(exchangeJettonStateInit) == ctx.sender, "Invalid sender");
        require(ctx.value >= self.minGasAmount || msg.purchase_price >= self.fullPrice, "Not enough funds to buy NFT");
        
        let queryId: Int = msg.query_id;
        let purchasePrice: Int = msg.purchase_price;
    }

    receive(msg: CancelSaleNft){}

    get fun get_sale_data(): NFTData {
        return
            NFTData{
                isComplete: self.isComplete,
                startAt: self.startAt,
                finishAt: self.finishAt,
                marketAddress: self.marketAddress,
                nftAddress: self.nftAddress,
                nftOwnerAddress: self.nftOwnerAddress,
                fullPrice: self.fullPrice,
                jettonAddress: self.jettonAddress
                // fees: self.fees
            };
    }
}