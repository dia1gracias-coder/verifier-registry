import "@stdlib/deploy";
import "./messages.tact";
import "./utils/ownerControllers.tact";
import "./item.tact";
import "./utils/functions.tact";
const minTonsForStorage: Int = ton("0.02");
const gasConsumption: Int = ton("0.02");

contract Collection with Deployable {
    next_item_index: Int as uint256 = 0;
    owner_address: Address;
    content: Cell;
    daytona: Address;
    numerator: Int;
    denominator: Int = 1000;
    destination: Address;

    destroyed: Bool = false;
    price: Int as coins = ton("1");

    init(
        content: Cell,
    ){
        self.owner_address = sender();
        self.daytona = sender();
        self.numerator = 100;
        self.destination = sender();
        self.content = content;

    }

    receive() {}
    receive(msg: MintType) {
        require(context().value >= self.price * msg.amount, "Not enough coins to mint nft");

        repeat (msg.amount) {
            self.createNft(sender(), msg);
            self.next_item_index = self.next_item_index + 1;
        }
    }

    fun createNft (owner: Address, msg: MintType) {
        let nft: StateInit = self.getNftItemInit(self.next_item_index);

        send(SendParameters{
            to: contractAddress(nft),
            value: ton("0.02"),
            bounce: false,
            mode: SendPayGasSeparately,
            body: Mint {
                collectionOwner: self.owner_address,
                owner: sender(),
                content_storage: self.content,
            }.toCell(),
            code: nft.code,
            data: nft.data
        });
    }

    receive(msg: GetRoyaltyParams) {   
        let ctx: Context = context(); // get sender Info
        send(SendParameters{
            to: ctx.sender,
            value: 0,
            mode: 64, 
            bounce: false,
            body: ReportRoyaltyParams {
                query_id: msg.query_id,
                numerator:  self.numerator,
                denominator: self.denominator,
                destination: self.destination
            }.toCell()
        });        
    }

    receive("Profit") {
        if (sender() != self.daytona) {
            return;
        }

        send(SendParameters{
            to: sender(),
            value: myBalance() - ton("0.05"),
            bounce: false,
            body: "Daytona project profit".asComment()
        });
    }

    // ------------------ Get Function  ------------------ //
    get fun get_collection_data(): CollectionData {
        let b: StringBuilder = beginString();
        let a: String = self.content.asSlice().asString();
        b.append(a);
        b.append("collection.json");

        return CollectionData{
            next_item_index: self.next_item_index, 
            collection_content: b.toCell(), 
            owner_address: self.owner_address,
        };
    }

    get fun get_nft_address_by_index(item_index: Int): Address?{      
        let initCode: StateInit = self.getNftItemInit(item_index);
        return contractAddress(initCode);
    }

    get fun getNftItemInit(item_index: Int): StateInit {
        return initOf NftItem(myAddress(), item_index);
    }
    
    get fun get_nft_content(index: Int, individual_content: Cell): Cell { 
        let b: StringBuilder = beginString();
        let ic: String = individual_content.asSlice().asString();
        b.append(ic);
        return b.toCell();
    }

    get fun royalty_params(): RoyaltyParams {
        return RoyaltyParams{
            numerator: self.numerator,
            denominator: self.denominator,
            destination: self.destination
        };
    }
}
