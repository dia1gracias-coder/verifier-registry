import "./alone_messages.tact";
import "@stdlib/deploy";
import "@stdlib/ownable";

const minTonsForStorage: Int = ton("0.01");
const gasConsumption: Int = ton("0.01");


contract EventFactory with Deployable {
    factory_owner: Address;

    init(factory_owner: Address){
        self.factory_owner = factory_owner;
    }

    receive(msg: CreateEvent){
        let event_init: StateInit = initOf Event(msg.owner_address, msg.collection_content, msg.ticketContent, msg.ticketCost, msg.guardAddress, msg.tickets_amount);

        let ctx = context();

        send(SendParameters{
            to: contractAddress(event_init), 
            value: ctx.value - (minTonsForStorage + gasConsumption), 
            mode: SendPayGasSeparately,
            body: emptyCell(),
            code: event_init.code,
            data: event_init.data
        });
    }
}

contract Event with Deployable {
    next_item_index: Int as uint32 = 0;
    owner_address: Address;
    royalty_params: RoyaltyParams?;
    collection_content: Cell;
    ticketContent: Cell;
    ticketCost: Int;
    guardAddress: Address;
    tickets_amount: Int;

    init(owner_address: Address, collection_content: Cell, ticketContent: Cell, ticketCost: Int, guardAddress: Address, tickets_amount: Int) {
        self.owner_address = owner_address;
        self.collection_content = collection_content;
        self.ticketContent = ticketContent;
        self.ticketCost = ticketCost;
        self.guardAddress = guardAddress;
        self.tickets_amount = tickets_amount; // -1 - inf, n - n tickets for event
    }

    receive("Mint") {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;
        
        // Рассчитываем общую требуемую сумму
        require(msgValue >= self.ticketCost, "Insufficient funds");
        require(self.tickets_amount == -1 || self.tickets_amount >= 1, "Sold out");

        // Отправляем плату за минт организатору
        send(SendParameters{
            to: self.owner_address,
            value: msgValue - 2 * (min(minTonsForStorage, abs(minTonsForStorage - myBalance())) + gasConsumption),
            mode: SendIgnoreErrors,
            bounce: false,
            body: emptyCell()
        });
        
        // Рассчитываем доступные средства для создания NFT
        // let remainingForNft = msgValue - totalRequired;
        
        // Минтим NFT с оставшимися средствами
        self.mint(ctx.sender, (min(minTonsForStorage, abs(minTonsForStorage - myBalance())) + gasConsumption));


    }

    // ===== Private Methods ===== //
    fun mint(sender: Address, msgValue: Int) {
        require(self.next_item_index >= 0, "non-sequential NFTs");
        let nft_init: StateInit = self.getNftItemInit(self.next_item_index);
        send(SendParameters{
            to: contractAddress(nft_init), 
            value: msgValue, 
            bounce: false,
            // mode: SendIgnoreErrors,
            body: Transfer {
                query_id: 0,
                new_owner: sender,
                response_destination: self.owner_address,
                custom_payload: self.ticketContent,
                forward_amount: 0,
                forward_payload: emptySlice()
            }.toCell(),
            code: nft_init.code,
            data: nft_init.data
        });
        self.next_item_index = self.next_item_index + 1;
        self.tickets_amount -= 1;
    }

    receive(msg: TicketDataForPunch){

        require(sender() == self.guardAddress, "Only Guard is allowed");

        let init: StateInit = self.getNftItemInit(msg.index);
        send(SendParameters{
            to: contractAddress(init),
            body: "Punch the ticket".asComment(), 
            value: ton("0.01"),              
            mode: SendIgnoreErrors
        });
    }

    receive(msg: EntranceGuard){
        require(sender() == self.owner_address, "Only host are allowed to change guard");
        // dump(sender());
        // // let ctx: Context = context();
        // dump(self.owner_address);
        self.guardAddress = msg.guardAddress;
    }

    // ------------------ Get Functions ------------------ //
    get fun get_collection_data(): CollectionData {     
        // let b: StringBuilder = beginString();
        // let collectionDataString: String = self.collection_content.asSlice().asString();
        // b.append(collectionDataString);
        // b.append("meta.json");
        return CollectionData{
            next_item_index: self.next_item_index, 
            collection_content: self.collection_content, 
            owner_address: self.owner_address
        };
    }

    get fun get_tickets_amount(): Int {
        return self.tickets_amount;
    }

    get fun get_nft_address_by_index(item_index: Int): Address? {      
        let initCode: StateInit = self.getNftItemInit(item_index);
        return contractAddress(initCode);
    }

    get fun getNftItemInit(item_index: Int): StateInit {
        return initOf Ticket(myAddress(), item_index);
    }
    
    get fun get_nft_content(index: Int, individual_content: Cell): Cell { 
        let b: StringBuilder = beginString();
        let ic: String = individual_content.asSlice().asString();
        b.append(ic);
        return b.toCell();
    }
}

contract Ticket {
    collection_address: Address;
    item_index: Int;
    is_initialized: Bool;
    punched: Bool = false;

    owner: Address?;
    individual_content: Cell?;

    init(collection_address: Address, item_index: Int) {
        require(sender() == collection_address, "not from collection");
        self.collection_address = collection_address;
        self.item_index = item_index;
        self.is_initialized = false;
    }

    receive(msg: Transfer) {
        let ctx: Context = context();
        // dump("Here");

        let msgValue: Int = ctx.value;
        // dump(msgValue);
        if (self.is_initialized == false) {
            // dump("Here2");

            require(ctx.sender == self.collection_address, "initialized tx need from collection");
            self.is_initialized = true;
            self.owner = msg.new_owner;
            self.individual_content = msg.custom_payload;
            send(SendParameters{
                to: msg.response_destination!!,
                value: max(0, msgValue - (minTonsForStorage + gasConsumption)),
                mode: SendPayGasSeparately,
                body: Excesses { query_id: msg.query_id }.toCell()
            });
        } else {
            require(ctx.sender == self.owner!!, "not owner");
            self.owner = msg.new_owner;
            if (msg.forward_amount > 0) {
                dump("Here3");

                send(SendParameters{
                    to: msg.new_owner,
                    value: msg.forward_amount,
                    mode: SendPayGasSeparately, 
                    bounce: true,
                    body: OwnershipAssigned{
                        query_id: msg.query_id,
                        prev_owner: ctx.sender,
                        forward_payload: msg.forward_payload
                    }.toCell()
                }); 
            }
            if (msg.response_destination != null) { 
                dump("Here4");

                send(SendParameters{ 
                    to: msg.response_destination!!,
                    value: msgValue - msg.forward_amount,
                    mode: SendPayGasSeparately,
                    bounce: true,
                    body: Excesses { query_id: msg.query_id }.toCell()
                });
            } 
        }
    }
    
    receive("Punch the ticket") {
        let ctx: Context = context();
        require(ctx.sender == self.collection_address, "Only guard can punch");
        self.punched = true;
    }

    receive(msg: GetStaticData) { 
        let ctx: Context = context();
        send(SendParameters {
            to: ctx.sender,
            value: 0,
            mode: 64,
            bounce: true,
            body: ReportStaticData{
                query_id: msg.query_id,
                index_id: self.item_index,
                collection: self.collection_address
            }.toCell()
        });
    }

    fun msgValue(value: Int): Int {
        let tonBalanceBeforeMsg: Int = myBalance() - value;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        return value - (storageFee + gasConsumption);
    }

    // --------- Get Function --------- //
    get fun get_nft_data(): GetNftData {

        return GetNftData {
            is_initialized: self.is_initialized, 
            index: self.item_index, 
            collection_address: self.collection_address, 
            owner_address: self.owner!!,
            individual_content: self.individual_content,
            punched: self.punched
        };
    }
}