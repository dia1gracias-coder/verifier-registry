

import "../common/message";
import "../common/constants";

// Modified implementation of https://github.com/howardpen9/nft-template-in-tact/blob/tutorial/sources/contract.tact

inline fun msgValue(value: Int): Int {
    let tonBalanceBeforeMsg: Int = myBalance() - value;
    let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
    return value - (storageFee + gasConsumption);
}

contract Item with Rarity {
    nftCollectionAddress: Address;
    nftItemIndex: Int as uint64;
    isInitialized: Bool;
    owner: Address?;
    individualContent: Cell?;
    collectorData: ItemCollectorData?;

    init(nftCollectionAddress: Address, nftItemIndex: Int as uint64) {
        self.nftCollectionAddress = nftCollectionAddress;
        self.nftItemIndex = nftItemIndex;
        self.isInitialized = false;
    }

    // Empty receiver for the deployment,
    receive() {}

    receive(msg: Transfer) {
        let ctx: Context = context(); // Reference: https://docs.tact-lang.org/language/ref/common#context
        let msgValue: Int = msgValue(ctx.value);
        
        if (self.isInitialized == false) {  // Initial Transfer, aka the "Minting" of the NFT
            require(ctx.sender == self.nftCollectionAddress, "initialized tx need from collection");
            self.isInitialized = true;
            self.owner = msg.newOwner;
            self.individualContent = msg.customPayload;

            // Extract collector points from forwardPayload if provided
            if (msg.forwardPayload.bits() >= 16) { // 16 bits for points
                let collectorPoints: Int = msg.forwardPayload.loadUint(16);

                self.collectorData = ItemCollectorData {
                    collectorPoints: collectorPoints,
                    rarity: self.calculateRarity(collectorPoints),
                };
            }

            send(SendParameters{
                to: msg.responseDestination!!,
                value: msgValue,
                mode: SendPayGasSeparately,
                body: Excesses { queryId: msg.queryId }.toCell()
            });
        } else {
            require(ctx.sender == self.owner!!, "not owner");
            self.owner = msg.newOwner;  // change current owner to the new_owner
            if (msg.forwardAmount > 0) {
                send(SendParameters{
                    to: msg.newOwner,
                    value: msg.forwardAmount,
                    mode:  SendPayGasSeparately, 
                    bounce: true,
                    body: NFTOwnershipAssigned{
                        queryId: msg.queryId,
                        previousOwner: ctx.sender,
                        forwardPayload: msg.forwardPayload
                    }.toCell()
                }); 
            }

            msgValue -= ctx.readForwardFee(); 
            if (msg.responseDestination != null) { 
                send(SendParameters{ 
                    to: msg.responseDestination!!,
                    value: msgValue - msg.forwardAmount,
                    mode: SendPayGasSeparately,
                    bounce: true,
                    body: Excesses { queryId: msg.queryId }.toCell()
                });
            } 
        }
    }

    // Calculate current collection score
    inline fun calculateCurrentCollectionScore(): Int {
        if (self.collectorData == null) {
            return 0;
        }
        
        let currentData: ItemCollectorData = self.collectorData!!;        
        return currentData.collectorPoints;
    }

    receive(msg: GetStaticData){ 
        let ctx: Context = context();
        send(SendParameters {
            to: ctx.sender,
            value: 0,
            mode: 64,  // (return msg amount except gas fees) 
            bounce: true,
            body: ReportStaticData{
                queryId: msg.queryId,
                indexId: self.nftItemIndex,
                collectionAddress: self.nftCollectionAddress
            }.toCell()
        });
    }


    // Getter for NFT data including rarity and collector points
    get fun get_nft_data(): NftData {
        let b: StringBuilder = beginString();
        b.append((self.individualContent!!).asSlice().asString());
        b.append(self.nftCollectionAddress.toString());
        b.append("/");
        b.append(self.nftItemIndex.toString());
        return NftData {
            init: self.owner == null ? 0 : 1, // If not 0, it is initialized
            index: self.nftItemIndex,
            collectionAddress: self.nftCollectionAddress,
            owner: self.owner,
            individualContent: b.toCell()
        };
    }

    get fun get_collector_data(): ItemCollectorData? {
        if (self.collectorData == null) {
            return null;
        }
        
        let currentData: ItemCollectorData = self.collectorData!!;
        
        // Return current data with dynamically calculated collection score
        return ItemCollectorData {
            collectorPoints: self.calculateCurrentCollectionScore(),
            rarity: currentData.rarity        
        };
    }
}

