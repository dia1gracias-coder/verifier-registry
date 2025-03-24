import "./message.tact";
import "./certificate.tact";
const minTonsForStorage: Int = ton("0.02");
const gasConsumption: Int = ton("0.02");

contract NftCollection {
    next_item_index: Int as uint32 = 0;
    owner_address: Address;
    collection_content: Cell;   
    cost: Int as coins = 256;

    init(owner_address: Address, id: Int){
        self.owner_address = owner_address;
        self.collection_content = emptyCell();
    }

    receive(msg: CertificateIssue){
        let ctx: Context = context(); 
        require(ctx.sender == self.owner_address, "only owner can issue certificate");
        
        let msgValue: Int = ctx.value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        msgValue = msgValue - (storageFee + gasConsumption);
        self.mint(msg.student, msgValue);

        // emit(LogEventMintRecord{ minter: sender(), item_id: self.next_item_index, generate_number: nativeRandom() }.toCell());
        emit(CertificateIssueRecord{item_id: self.next_item_index, student: msg.student}.toCell());
    }

    receive(msg: SetCollectionContent) {
        require(context().sender == self.owner_address, "only owner can update content");
        self.collection_content = msg.collection_content;
    }

    receive(msg: Enrollment) {
        let ctx: Context = context();
        let msgValue: Int = self.msgValue(ctx.value);
        require(msgValue >= self.cost, "Not enough funds to enroll");
        
        let remainingValue = msgValue - self.cost;
        if remainingValue > 0 {
            send(SendParameters{
                value: remainingValue,
                mode: SendDefaultMode,
                to: ctx.sender,
                bounce: false,
                body: "You have successfully enrolled to the course!".asComment()
            });
        }
        emit(msg.toCell());
    }

    receive(msg: SetCost) {
        require(context().sender == self.owner_address, "only owner set cost");
        require(msg.cost > 0, "Cost must be positive");
        self.cost = msg.cost;
    }

    receive("Withdraw") {
        require(context().sender == self.owner_address, "only owner can withdraw");  
        let withdrawValue = myBalance() - minTonsForStorage;
        if withdrawValue > 0 {
            send(SendParameters{
                value: withdrawValue,
                mode: SendDefaultMode,
                to: self.owner_address,
                bounce: false,
                body: "Withdraw completed".asComment()
            });
        }
    }

    // ===== Private Methods ===== //
    fun mint(student: Address, msgValue: Int) {
        require(self.next_item_index >= 0, "non-sequential NFTs");
        let nft_init: StateInit = self.getNftItemInit(self.next_item_index);
        send(SendParameters{
                to: contractAddress(nft_init), 
                value: msgValue, 
                bounce: false,
                mode: SendIgnoreErrors,
                body: Transfer {
                    query_id: 0,
                    new_owner: student,
                    response_destination: self.owner_address,
                    custom_payload: self.collection_content,
                    forward_amount: 0,
                    forward_payload: emptySlice()
                }.toCell(),
                code: nft_init.code,
                data: nft_init.data
            });
        // dump(self.next_item_index); // Reference at: https://tact-by-example.org/03-emit
        self.next_item_index = self.next_item_index + 1;
    }

    // ------------------ Get Function  ------------------ //
    get fun get_collection_data(): CollectionData {     
        let b: StringBuilder = beginString();
        let collectionDataString: String = self.collection_content.asSlice().asString();
        b.append(collectionDataString);
        b.append("meta.json"); // You can changed this your self.
        return CollectionData{
            next_item_index: self.next_item_index, 
            collection_content: b.toCell(), 
            owner_address: self.owner_address
        };
    }

    get fun cost(): Int {
        return self.cost;
    }


    get fun nft_address_by_index(item_index: Int): Address?{      
        let initCode: StateInit = self.getNftItemInit(item_index);
        return contractAddress(initCode);
    }

    get fun getNftItemInit(item_index: Int): StateInit {
        return initOf NftItem(myAddress(), item_index);
    }
    
    get fun nft_content(index: Int, individual_content: Cell): Cell { 
        let b: StringBuilder = beginString();
        let ic: String = individual_content.asSlice().asString();
        b.append(ic);
        return b.toCell();
    }


        fun msgValue(value: Int): Int {
        let tonBalanceBeforeMsg: Int = myBalance() - value;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        return value - (storageFee + gasConsumption);
    }

}
