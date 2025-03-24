import "@stdlib/deploy";
import "@stdlib/ownable";
import "./item";

struct CollectionData {
    next_index: Int;
    content: Cell;
    owner: Address;
}

contract NftCollection with OwnableTransferable {
    owner: Address;
    next_index: Int as uint256 = 0;
    content: Cell;
    minTonsForStorage:Int = ton("0.05");

    init(owner: Address, content: Cell) {
        self.owner = owner;
        self.content = content;
    }

    receive(deploy: Deploy) {
        let ctx:Context = context();
        let balance_befor: Int = myBalance() - ctx.value;
        if (balance_befor < self.minTonsForStorage) {
            ctx.value -= min(self.minTonsForStorage - balance_befor, ton("0.05"));
        }
        if (ctx.value>0){
            send(SendParameters{
            to: sender(),
            value: ctx.value,
            mode: 0,
            body: DeployOk{queryId: deploy.queryId}.toCell()
            });
        }
    }

    receive(msg: RequestNftDeploy) {
        self.requireOwner();

        let nft_init: StateInit = initOf NftItem(myAddress(), self.next_index);
        send(SendParameters{
            to: contractAddress(nft_init),
            value: msg.amount,
            mode: SendPayGasSeparately,
            bounce: false,
            data: nft_init.data,
            code: nft_init.code,
            body: NftDeploy{
                query_id: msg.query_id,
                index: self.next_index,
                owner: msg.owner,
                content: msg.content,
                BIP_value: msg.BIP_value
            }.toCell()
        });
        self.next_index += 1;

        let ctx: Context = context();
        let balance_befor: Int = myBalance() - ctx.value - msg.amount;
        if (balance_befor < self.minTonsForStorage) {
            ctx.value -= max(self.minTonsForStorage - balance_befor, ton("0.05"));
        }
        if (ctx.value>0){
            send(SendParameters{
                to: msg.owner,
                value: ctx.value,
                mode: 0,
                body: NftExcesses{
                    query_id: msg.query_id
                    }.toCell()
            });
        }

    }

    receive() {}

    get fun get_collection_data(): CollectionData {
        return CollectionData{next_index: self.next_index, content: self.content, owner: self.owner};
    }
    get fun get_nft_address_by_index(index: Int): Address {
        return contractAddress(initOf NftItem(myAddress(), index));
    }
    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        return individual_content;
    }
}