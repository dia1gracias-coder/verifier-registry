//Source from https://github.com/tact-lang/tact/blob/793ea9b688444913e55c61b03fe4c60d273c74d1/src/benchmarks/contracts/nft-item.tact


contract NftItem {
    collection_address: Address;
    item_index: Int; 
    is_initialized: Bool;

    owner: Address?;
    individual_content: Cell?;

    init(collection_address: Address, item_index: Int){
        require(sender() == collection_address, "not from collection");
        self.collection_address = collection_address;
        self.item_index = item_index;
        self.is_initialized = false;
    }

    receive(msg: Transfer){
        let ctx: Context = context(); // Reference: https://docs.tact-lang.org/language/ref/common#context
        let msgValue: Int = self.msgValue(ctx.value);
        
        if (self.is_initialized == false) {  // Initial Transfer, aka the "Minting" of the NFT
            require(ctx.sender == self.collection_address, "initialized tx need from collection");
            self.is_initialized = true;
            self.owner = msg.new_owner;
            self.individual_content = msg.custom_payload;
            send(SendParameters{
                to: msg.response_destination!!,
                value: msgValue,
                mode: SendPayGasSeparately,
                body: Excesses { query_id: msg.query_id }.toCell()
            });
        } else {
            require(ctx.sender == self.owner!!, "not owner");
            self.owner = msg.new_owner;  // change current owner to the new_owner
            if (msg.forward_amount > 0) {
                send(SendParameters{
                    to: msg.new_owner,
                    value: msg.forward_amount,
                    mode:  SendPayGasSeparately, 
                    bounce: true,
                    body: OwnershipAssigned{
                        query_id: msg.query_id,
                        prev_owner: ctx.sender,
                        forward_payload: msg.forward_payload
                    }.toCell()
                }); 
            }

            msgValue = msgValue - ctx.readForwardFee(); 
            if (msg.response_destination != null) { 
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
    
    receive(msg: GetStaticData){ 
        let ctx: Context = context();
        send(SendParameters {
            to: ctx.sender,
            value: 0,
            mode: 64,  // (return msg amount except gas fees) 
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

    // --------- Get Function  --------- //
    get fun get_nft_data(): GetNftData {
        let b: StringBuilder = beginString();
        let collectionData: String = (self.individual_content!!).asSlice().asString();
        b.append(collectionData);
        
        b.append(self.collection_address.toString());
        b.append("/");
        b.append(self.item_index.toString());
        b.append(".json");

        return GetNftData {
            is_initialized: self.is_initialized, 
            index: self.item_index, 
            collection_address: self.collection_address, 
            owner_address: self.owner!!,
            individual_content: b.toCell()
        };
    }

    // fun get_raw_address(address: Address): String {
    //     let wc = address.wc;
    //     let hash = address.hash; // CellSlice of 256 bits (32 bytes)

    //     // Convert workchain ID (e.g., 0) to string
    //     let wc_str = wc.toString();

    //     // Convert the 32-byte hash into a hex string
    //     let hash_str = hex_encode(hash);

    //     return wc_str + ":" + hash_str;
    // }
}




// import "./constants";
// import "./messages-nft";

// inline fun sendMsg(toAddress: Address, amount: Int, op: Int, queryId: Int, payload: Builder, sendMode: Int) {
//     let msgBody = beginCell().storeUint(op, 32).storeUint(queryId, 64);

//     if (payload.bits() != 0) {
//         msgBody = msgBody.storeBuilder(payload);
//     }

//     message(MessageParameters {
//         bounce: false,
//         to: toAddress,
//         value: amount,
//         body: msgBody.endCell(),
//         mode: sendMode,
//     });
// }

// contract NFTItem(
//     owner: Address?,
//     content: Cell?,
//     collectionAddress: Address,
//     itemIndex: Int as uint64,
// ) {
//     receive() {} //to ignore empty messages

//     receive(msg: Slice) {
//         // Check if owner == null, which means the contract hasn't been initialized yet
//         // owner is used as an initialization flag: if null - contract is not initialized,
//         // if not null - contract has been initialized before
//         // This prevents contract re-initialization since initialization should happen only once
//         // We use similar checks in other methods (e.g., Transfer, GetStaticData) with throwUnless(NotInit, self.owner != null)
//         // to ensure the contract is properly initialized before executing any operations
//         throwUnless(InvalidData, self.owner == null);

//         let owner: Address = msg.loadAddress();
//         let content: Cell = msg.loadRef();

//         throwUnless(IncorrectDeployer, sender() == self.collectionAddress);
//         self.owner = owner;
//         self.content = content;
//     }

//     receive(msg: Transfer) {
//         throwUnless(NotInit, self.owner != null);
//         throwUnless(IncorrectSender, sender() == self.owner);
//         throwUnless(IncorrectForwardPayload, msg.forwardPayload.bits() >= 1);
//         forceBasechain(msg.newOwner);

//         let fwdFees: Int = context().readForwardFee();

//         let restAmount: Int = myBalance() - minTonsForStorage;
//         if (msg.forwardAmount > 0) {
//             restAmount -= (msg.forwardAmount + fwdFees);
//         }

//         // when we load addr_none$00 in tact we got null
//         let needResponse: Bool = (msg.responseDestination != null);
//         if (needResponse) {
//             restAmount -= fwdFees;
//         }

//         throwUnless(InvalidFees, restAmount >= 0);

//         if (msg.forwardAmount > 0) {
//             sendMsg(msg.newOwner, msg.forwardAmount, OwnershipAssigned, msg.queryId, beginCell().storeAddress(self.owner!!).storeSlice(msg.forwardPayload), SendPayFwdFeesSeparately);
//         }
//         if (needResponse) {
//             forceBasechain(msg.responseDestination!!);
//             sendMsg(msg.responseDestination!!, restAmount, Excesses, msg.queryId, beginCell(), SendPayFwdFeesSeparately);
//         }
//         self.owner = msg.newOwner;
//     }

//     receive(msg: GetStaticData) {
//         throwUnless(NotInit, self.owner != null);

//         sendMsg(sender(), 0, ReportStaticData, msg.queryId, beginCell().storeUint(self.itemIndex, 256).storeAddress(self.collectionAddress), SendRemainingValue); // implementation detail
//     }

//     get fun get_nft_data(): NFTData {
//         return NFTData {
//             init: self.owner != null ? -1 : 0, // -1 is true
//             itemIndex: self.itemIndex,
//             collectionAddress: self.collectionAddress,
//             owner: self.owner,
//             content: self.content,
//         };
//     }
// }