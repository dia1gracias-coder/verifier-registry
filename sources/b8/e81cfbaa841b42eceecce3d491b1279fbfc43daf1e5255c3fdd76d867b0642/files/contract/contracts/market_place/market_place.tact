import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages";
import "./structs";
import "./nft_sale/nft_sale";
import "./jetton_exchange/jetton_exchange";

contract Marketplace with OwnableTransferable,Deployable {
    owner: Address;

    init(owner: Address){
        self.owner = owner;
    }

    receive(msg: OwnershipAssigned){
        let ctx: Context = context();
        let nftItemAddress: Address = ctx.sender;
        let queryId: Int = msg.query_id;
        let nftOwnerAddress: Address = msg.prev_owner;
        let forwardPayload: Slice = msg.forward_payload;

        let subOp: Int = forwardPayload.preloadUint(32);
        require(subOp == 0x0fe0ede, "Invalid sub-op");

        let saleNftMessage: SaleNft = SaleNft.fromSlice(forwardPayload);
        let nftData: NFTData = saleNftMessage.stateInit;
        let nftSaleInit: StateInit = initOf NftSale(nftData.isComplete, nftData.startAt, nftData.finishAt, nftData.marketAddress,nftData.nftAddress,nftData.nftOwnerAddress ,nftData.fullPrice,nftData.jettonAddress);
        let nftSaleAddress: Address = contractAddress(nftSaleInit);

        //send 0.02 TON to the nft sale contract(new owner)
        send(SendParameters{
                to: nftSaleAddress,
                value: ton("0.02"),
                mode: SendPayGasSeparately,
                bounce: false,
                code: nftSaleInit.code,
                data: nftSaleInit.data
            }
        );

        let reverseValue: Int = self.countReverseValue(ctx.value);
        nativeReserve(reverseValue, 0);

        // trasnfer the ownership to the nft sale contract
        send(SendParameters{
                to: nftItemAddress,
                value: 0,
                mode: SendRemainingBalance,
                body: Transfer{
                    query_id: queryId,
                    new_owner: nftSaleAddress,
                    response_destination: nftOwnerAddress,
                    custom_payload: emptyCell(),
                    forward_amount: 0,
                    forward_payload: emptySlice()
                }.toCell()
            }
        );
    }

    receive(msg: AddExchangeJetton){
        self.requireOwner();
        let sinit: StateInit = initOf JettonExchange(myAddress(), msg.jetton_address);
        send(SendParameters{
                to: contractAddress(sinit),
                value: 0,
                bounce:false,
                mode: SendRemainingValue,
                body: EnableExchangeJetton{}.toCell(),
                code: sinit.code,
                data: sinit.data
            }
        );
    }

    receive(msg: RemoveExchangeJetton){
        self.requireOwner();
        let sinit: StateInit = initOf JettonExchange(myAddress(), msg.jetton_address);
        send(SendParameters{
                to: contractAddress(sinit),
                value: 0,
                bounce:false,
                mode: SendRemainingValue,
                body: DisableExchangeJetton{}.toCell()
            }
        );
    }

    fun countReverseValue(value: Int): Int {
        let tonBalanceBeforeRecvMsg: Int = (myBalance() - value);
        return tonBalanceBeforeRecvMsg < ton("0.001") ? ton("0.001") : tonBalanceBeforeRecvMsg + ton("0.000001");
    }
}