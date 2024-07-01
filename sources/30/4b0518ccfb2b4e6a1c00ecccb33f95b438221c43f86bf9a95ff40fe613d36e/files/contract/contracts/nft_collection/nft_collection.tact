import "./structs";
import "./messages";
import "./../nft_item/nft_item";
// todo: max cap, sell cap
contract NftCollection  {
    
    const minTonsForStorage: Int = ton("0.03");
    const gasConsumption: Int = ton("0.03"); // gas consuption for different operations may differ, so it's better to separate such consts

    next_item_index: Int as uint32 = 0;
    owner_address: Address;
    beneficiary: Address;
    price_per_mint: Int = 50;
    price_per_mint_step: Int = 1000;
    price_per_mint_step_rise: Int = 5;
    royalty_params: RoyaltyParams;
    collection_content: Cell;
    referer_reward: Int = 50;

    init(
        owner_address: Address,
        beneficiary: Address,
        collection_content: Cell,
        price_per_mint: Int,
        price_per_mint_step: Int,
        price_per_mint_step_rise: Int,
        royalty_params: RoyaltyParams
    ){
        self.owner_address = owner_address;
        self.beneficiary = beneficiary;
        self.collection_content = collection_content;
        self.price_per_mint = price_per_mint;
        self.price_per_mint_step = price_per_mint_step;
        self.price_per_mint_step_rise = price_per_mint_step_rise;
        self.royalty_params = royalty_params;
    }

    // [Collection Contract] -> Transfer -> OwnershipAssigned -> NFTExcesses
    receive(msg: Mint){
        let ctx: Context = context(); // get sender Info

        let msgValue: Int = ctx.value;

        require(
            msgValue >=
            self.price_per_mint(),
            "Insufficient funds for minting."
        );

        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = self.minTonsForStorage - min(tonBalanceBeforeMsg, self.minTonsForStorage);

        let refererAmount: Int = 0;

        if (msg.referer != null) {
            refererAmount = (msgValue * self.referer_reward) / 1000;
        }

        let totalDeductions: Int = storageFee + self.gasConsumption;

        require(msgValue >= totalDeductions, "Insufficient funds for storage and gas.");

        let amountToSend: Int = msgValue - totalDeductions - refererAmount;
        send(SendParameters{
            to: self.beneficiary,
            value: amountToSend,
            bounce: false,
            mode: SendIgnoreErrors
        });

        if (refererAmount > 0) {
            send(SendParameters{
                to: msg.referer!!,
                value: refererAmount,
                bounce: false,
                mode: SendIgnoreErrors
            });
        }

        self.mint(ctx.sender, totalDeductions);

    }

    receive(msg: BuilkMint) {
        let ctx: Context = context();
        require(ctx.sender == self.owner_address, "Only owner can perform bulk minting");

        repeat (msg.amount) {
            self.mint(msg.receiver, self.minTonsForStorage);
        }

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
                numerator:  self.royalty_params.numerator,
                denominator: self.royalty_params.denominator,
                destination: self.owner_address
            }.toCell()
        });
    }

    receive(msg: GetBeneficiary) {
        let ctx: Context = context(); // get sender Info
        send(SendParameters{
            to: ctx.sender,
            value: 0,
            mode: 64,
            bounce: false,
            body: Beneficiary {
                query_id: msg.query_id,
                beneficiary: self.beneficiary
            }.toCell()
        });
    }

    receive(msg: AssignBeneficiary) {
        let ctx: Context = context(); // get sender Info
        require(ctx.sender == self.owner_address, "Only owner can set beneficiary address");

        self.beneficiary = msg.beneficiary;

        send(SendParameters{
            to: ctx.sender,
            value: 0,
            mode: SendIgnoreErrors,
            bounce: false,
            body: Excesses {
                query_id: msg.query_id
            }.toCell()
        });
    }

    receive(msg: AssignPricePerMint) {
        let ctx: Context = context(); // get sender Info
        require(ctx.sender == self.owner_address, "Only owner can set price per mint");

        self.price_per_mint = msg.price_per_mint;

        send(SendParameters{
            to: ctx.sender,
            value: 0,
            mode: SendIgnoreErrors,
            bounce: false,
            body: Excesses {
                query_id: msg.query_id
            }.toCell()
        });
    }

    receive(msg: GetPricePerMint) {
        let ctx: Context = context(); // get sender Info
        send(SendParameters{
            to: ctx.sender,
            value: 0,
            mode: 64, 
            bounce: false,
            body: AssignPricePerMint {
                query_id: msg.query_id,
                price_per_mint: self.price_per_mint
            }.toCell()
        });
    }


    // ===== Private Methods ===== //
    fun mint(sender: Address, msgValue: Int) {
        require(self.next_item_index >= 0, "non-sequential NFTs");

        let nft_init: StateInit = self.getNftItemInit(self.next_item_index);
        send(SendParameters{
            to: contractAddress(nft_init),
            value: msgValue,
            bounce: false,
            mode: SendIgnoreErrors,
            body: Transfer {
                query_id: 0,
                new_owner: sender,
                response_destination: self.owner_address,
                custom_payload: emptyCell(),
                forward_amount: 0,
                forward_payload: emptySlice()
            }.toCell(),
            code: nft_init.code,
            data: nft_init.data
        });

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

    get fun get_nft_address_by_index(item_index: Int): Address? {
        let initCode: StateInit = self.getNftItemInit(item_index);
        return contractAddress(initCode);
    }

    get fun getNftItemInit(item_index: Int): StateInit {
        return initOf NftItem(myAddress(), item_index, self.owner_address, self.collection_content);
    }
    
    get fun get_nft_content(index: Int, individual_content: Cell): Cell { 
        let b: StringBuilder = beginString();
        let ic: String = individual_content.asSlice().asString();
        b.append(ic);
        return b.toCell();
    }

    get fun royalty_params(): RoyaltyParams {
        return self.royalty_params;
    }

    get fun beneficiary(): Address {
        return self.beneficiary;
    }

    get fun calc_price_per_mint(price: Int, item_index: Int, step: Int, rise: Int): Int {
        return price + (item_index / step) * rise;
    }

    get fun price_per_mint(): Int {
        return self.calc_price_per_mint(
            self.price_per_mint, self.next_item_index, self.price_per_mint_step, self.price_per_mint_step_rise
        );
    }
    
    get fun owner(): Address {
        return self.owner_address;
    }

    get fun referer_reward(): Int {
        return self.referer_reward;
    }
}