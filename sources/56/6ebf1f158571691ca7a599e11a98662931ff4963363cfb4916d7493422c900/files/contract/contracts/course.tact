import "@stdlib/ownable";
import "./certificate.tact";
import "./message";

contract Course with Ownable {
    override const storageReserve: Int = minTonsForStorage;

    next_item_index: Int as uint32 = 0;
    owner: Address;
    collection_content: Cell;   
    cost: Int as coins = ton("10000");

    init(owner: Address, id: Int){
        require(id >= 0, "id should be >= 0");
        self.owner = owner;
        self.collection_content = emptyCell();
    }

    receive(msg: UpdateCourse) {
        self.requireOwner();
        require(msg.cost > 0, "cost must be positive");
        require(msg.content != emptyCell(), "content must be not empty");
        self.collection_content = msg.content;
        self.cost = msg.cost;

        emit(msg.toCell());
        self.notify("Course Successfully Updated".asComment());
    }

    receive("Withdraw") {
        self.requireOwner();
        nativeReserve(minTonsForStorage + gasConsumption, ReserveExact);
        send(SendParameters{
                to: self.owner,
                value: 0,
                mode: SendRemainingBalance,
                bounce: false,
                body: "Withdraw completed".asComment()
        });
    }

    receive(msg: Enrollment) {
        let ctx: Context = context();
        require(ctx.value >= self.cost, "No enough funds to enroll");
        emit(msg.toCell());
        send(SendParameters{
            value: ctx.value - self.cost,
            mode: SendDefaultMode | SendPayGasSeparately,
            to: ctx.sender,
            bounce: false,
            body: "You have successfully enrolled to the course!".asComment()
        });
    }

    receive(msg: Quiz) {
        require(context().value >= gasConsumption, "value should be >= 0.02");
        emit(QuizRecord{
            quizNumber: msg.quizNumber,
            answers: msg.answers,
            student: sender(),
        }.toCell());        
    }

    receive(msg: CertificateIssue){
        self.requireOwner();      
        let nft_init: StateInit = self.getCertificateInit(self.next_item_index);
        send(SendParameters{
                to: contractAddress(nft_init), 
                value: minTonsForStorage, 
                bounce: false,
                mode: SendPayGasSeparately | SendIgnoreErrors,
                body: Transfer {
                    query_id: 0,
                    new_owner: msg.student,
                    response_destination: sender(),
                    custom_payload: msg.certificate_content,
                    forward_amount: 0,
                    forward_payload: emptySlice()
                }.toCell(),
                code: nft_init.code,
                data: nft_init.data
            });

        // dump(self.next_item_index); // Reference at: https://tact-by-example.org/03-emit
        self.next_item_index = self.next_item_index + 1;

        // emit(LogEventMintRecord{ minter: sender(), item_id: self.next_item_index, generate_number: nativeRandom() }.toCell());
        emit(CertificateIssueRecord{item_id: self.next_item_index, student: msg.student}.toCell());
    }

    // ===== Private Methods ===== //
    fun getCertificateInit(item_index: Int): StateInit {
        return initOf Certificate(myAddress(), item_index);
    }


    // ------------------ Get Function  ------------------ //
    get fun get_collection_data(): CollectionData {     
        return CollectionData{
            next_item_index: self.next_item_index, 
            collection_content: self.collection_content, 
            owner_address: self.owner
        };
    }

    get fun get_course_data(): CourseData {     
        return CourseData{
            next_item_index: self.next_item_index, 
            collection_content: self.collection_content, 
            cost: self.cost,
            owner_address: self.owner
        };
    }

    get fun get_nft_address_by_index(item_index: Int): Address?{      
        let initCode: StateInit = self.getCertificateInit(item_index);
        return contractAddress(initCode);
    }
    
    get fun get_nft_content(index: Int, individual_content: Cell): Cell { 
        return individual_content;
    }

    get fun get_balance(): Int {
        return myBalance();
    }
}
