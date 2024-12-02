import "./message.tact";
import "@stdlib/deploy";
import "@stdlib/ownable";
import "@stdlib/content";
import "./itemContract.tact";

const DEPLOY_GAS: Int = ton("0.03");     // Было 0.04
const FORWARD_GAS: Int = ton("0.01");     // Было 0.02



contract NftContractsecond with Deployable {
    next_item_index: Int as uint16;
    owner_address: Address;
    royalty_params: RoyaltyParams?;                      
    collection_content: Cell;
    nonce: Int;
    nft_contents: map<Int, Cell>;

     

    init(owner_address: Address, collection_content: Cell, royalty_params: RoyaltyParams , nonce: Int){
        self.owner_address = owner_address;
        self.collection_content = collection_content; 
        self.royalty_params = royalty_params;
        self.nonce = nonce;
        self.next_item_index = 0;
        
    }

    fun validateContent(content: Cell) {
        let slice: Slice = content.asSlice();
        require(slice.bits() <= 1016, "Content too long");  // 127 байт * 8 бит = 1016 бит
        
        let prefix: Int = slice.loadUint(8);
        require(prefix == 1, "Invalid content prefix");
    }
   



    receive(msg: Mint){
        let ctx: Context = context();
        let msgValue: Int = ctx.value;
        require(msgValue >= ton("0.05"), "Insufficient funds");
        
        let individual_content: Cell = msg.custom_payload;
        self.validateContent(individual_content);
        
        self.nft_contents.set(self.next_item_index, individual_content);
        
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        msgValue = msgValue - (storageFee + gasConsumption);
        
        require(msgValue >= ton("0.03"), "Insufficient funds for NFT deployment");
        
        self.mint(sender(), msgValue, individual_content);

        //emit(LogEventMintRecord{ minter: sender(), item_id: self.next_item_index, generate_number: nativeRandom() }.toCell());
    }

    // ===== Private Methods ===== //
    fun mint(sender: Address, msgValue: Int, individual_content: Cell) {
        require(self.next_item_index >= 0, "non-sequential NFTs");

        let nft_init: StateInit = self.getNftItemInit(self.next_item_index);
        let nft_address: Address = contractAddress(nft_init);
         // Добавляем проверки
       
        // 1. Первая транзакция: Деплой
        send(SendParameters{
            to: nft_address,
            value: ton("0.07"),
            bounce: true,
            mode: SendIgnoreErrors,
            code: nft_init.code,
            data: nft_init.data,
            // Запрашиваем callback после деплоя
            body: InitDeployed{
                query_id: 0,
                nft_address: nft_address,
                sender: sender,
                individual_content: individual_content
            }.toCell()
        });

        self.next_item_index = self.next_item_index + 1;
    }

    receive(msg: InitDeployedTrue) {
    require(msg.nft_address == sender(), "Invalid NFT address");
    send(SendParameters{
        to: msg.nft_address,
        value: 0,
        bounce: true,
        mode: SendRemainingValue,  // Отправляем весь остаток
        body: Transfer {
            query_id: msg.query_id,
            new_owner: msg.sender,
            response_destination: self.owner_address,
            custom_payload: msg.individual_content,
            forward_amount: ton("0.01"),
            forward_payload: emptySlice()
        }.toCell()
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
                query_id: 0,
                numerator:  (self.royalty_params!!).numerator,
                denominator: (self.royalty_params!!).denominator,
                destination: self.owner_address
            }.toCell()
        });        
    }

    // ------------------ Get Function  ------------------ //
    get fun get_collection_data(): CollectionData {     
         // You can changed this your self.
        return CollectionData{
            next_item_index: self.next_item_index, 
            collection_content: self.collection_content, 
            owner_address: self.owner_address

        };
    }

    get fun get_nft_address_by_index(item_index: Int): Address {  
       let initCode: StateInit = self.getNftItemInit(item_index);
        return contractAddress(initCode);
    }
   
    get fun getNftItemInit(item_index: Int): StateInit {
        return initOf NftItem(myAddress(), item_index);
    }
  
    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
       return individual_content;
    }


    get fun royalty_params(): RoyaltyParams {
        return self.royalty_params!!;
    }
}


