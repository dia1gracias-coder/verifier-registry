import "@stdlib/deploy";
import "@stdlib/ownable";
import "./item";
import "./nft_collection";
import "../feeJetton/wallet";


contract BIPChanger {
    jetton_wallet_address: Address;
    nft_collection_content: Cell;
    nft_collection_address: Address;

    const minTonsForStorage: Int = ton("0.05");

    init(nft_collection_content:Cell, jetton_master: Address) {
        self.nft_collection_content = nft_collection_content;
        self.jetton_wallet_address = contractAddress(initOf JettonDefaultWallet(myAddress(),jetton_master));

        self.nft_collection_address = contractAddress(initOf NftCollection(myAddress(),nft_collection_content));
    }

    receive(deploy: Deploy) {
        let ctx:Context = context();
        let balance_befor: Int = myBalance() - ctx.value;
        if (balance_befor < self.minTonsForStorage) {
            ctx.value -= min(self.minTonsForStorage - balance_befor, ton("0.05"));
        }

        let init = initOf NftCollection(myAddress(),self.nft_collection_content);
        send(SendParameters{
            to: self.nft_collection_address,
            value: ctx.value,
            mode: SendIgnoreErrors,
            body: Deploy{
                queryId: deploy.queryId
                }.toCell(),
            code: init.code,
            data: init.data
            });

    }

//    CHANGE BIP TO NFT
    receive(msg: TokenNotification){
        require(sender() == self.jetton_wallet_address, "Invalid sender");

        let ctx:Context = context();
        let balance_befor: Int = myBalance() - ctx.value;
        if (balance_befor < self.minTonsForStorage) {
            ctx.value -= min(self.minTonsForStorage - balance_befor, ton("0.05"));
        }
        send(SendParameters{
            to: self.nft_collection_address,
            value: ctx.value,
            mode: 0,
            body: RequestNftDeploy{
                query_id: msg.query_id,
                amount: ton("0.03"),
                owner: msg.from,
                content: self.get_content(msg.amount),
                BIP_value: msg.amount
            }.toCell()
        });
    }

    receive(msg: NftOwnershipAssigned){
        let ctx:Context = context();
        if (ctx.sender == contractAddress(initOf NftItem(self.nft_collection_address,msg.index))){


            let balance_befor: Int = myBalance() - ctx.value - ton("0.02");
            if (balance_befor < self.minTonsForStorage) {
                ctx.value -= min(self.minTonsForStorage - balance_befor, ton("0.05"));
            }

            if ctx.value>ton("0.06"){
                send(SendParameters{
                to: self.jetton_wallet_address,
                value: ctx.value,
                mode: 0,
                body: TokenTransfer{
                query_id: msg.query_id,
                amount: msg.BIP_value,
                destination: msg.prev_owner,
                response_destination: msg.prev_owner,
                forward_ton_amount: 0,
                forward_payload: beginCell().endCell().asSlice()
                }.toCell()
                });

                send(SendParameters{
                to: ctx.sender,
                value: ton("0.02"),
                mode: 0,
                body: NftDestroy{
                query_id: msg.query_id,
                response_destination: msg.prev_owner
                }.toCell()
                });

            } else {
                send(SendParameters{
                to: ctx.sender,
                value: ton("0.03"),
                mode: 0,
                body: NftTransfer{
                    query_id: msg.query_id,
                    new_owner:msg.prev_owner,
                    response_destination: myAddress(),
                    forward_amount: 0,
                    forward_payload: beginCell().endCell().asSlice()
                }.toCell()
                });
            }


        }
    }

    receive() {}
    receive(str: String) {}
    receive(slice: Slice) {}

    get fun get_content(value:Int): Cell {
        let link = beginString()
                .concat("https://nft.biptoken.xyz/CreateItemMetadata?value=")
                .concat(value.toCoinsString());

        return beginCell().storeUint(1, 8).storeSlice(link.toSlice()).endCell();
    }
}