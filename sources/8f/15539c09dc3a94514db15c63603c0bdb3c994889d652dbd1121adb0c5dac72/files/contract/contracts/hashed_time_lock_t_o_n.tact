import "@stdlib/deploy";
struct HTLCNotification {
    htlcID: Int;
    sender: Address;
    receiver: Address;
    amount: Int;
    timelock: Int;
    hashlock: Int;
    dstAddress: String;
    phtlcID: Int;
}

message HTLCNotify {
    data: HTLCNotification;
}

struct PHTLC {
    dstAddress: String;
    srcAssetId: Int;
    sender: Address;
    srcAddress: Address;
    timelock: Int; 
    messenger: Address;
    amount: Int;
    refunded: Bool;
    converted: Bool;
    phtlcID: Int;
}

message CreateP{
    data: PHTLCData;
}

struct ConvertPData{
    phtlcID: Int;
    hashlock: Int;
}
message ConvertP{
    data: ConvertPData;
}

struct StringImpl{
    data: String;
}

struct PHTLCData{
    chainIDs: map<Int,Int>;
    dstAddresses: map<Int,StringImpl>;
    dstChainId: Int;
    dstAssetId: Int;
    dstAddress: String;
    srcAssetId: Int;
    srcAddress: Address;
    timelock: Int; 
    messenger: Address;
    amount: Int;
    refunded: Bool;
    converted: Bool;
}

message RefundP{
    phtlcID: Int;
}

struct HTLC {
    hashlock: Int;
    secret: Int;
    amount: Int;
    timelock: Int;
    sender: Address;
    srcAddress: Address;
    redeemed: Bool;
    refunded: Bool;
}

struct TonTransferInitiated {
    __hashlock: Int;
    __amount: Int;
    __chainId: Int ;
    __timelock: Int ;
    __sender: Address;
    __srcAddress: Address;
    __targetCurrencyReceiverAddress: String; 
    __phtlcID: Int;
    __messenger: Address;
}

message Create {
    data: TonTransferInitiated;
}

struct TonTransferClaimed {
    __hashlock: Int;
    __secret: Int;
    __amount: Int;
}

message Redeem {
    data: TonTransferClaimed;
}

struct TonTransferRefunded {
    __hashlock: Int;
    __receiver: Address;
    __amount: Int;
}

message Refund {
    data: TonTransferRefunded;
}

message PreHTLCID {
    phtlcID: Int;
}

struct ChainIDs {
    data: map<Int,Int>;
}

struct DstAddresses {
    data: map<Int,StringImpl>;
}

struct CreatePBatchData{
    chainIds: map<Int, ChainIDs>;
    dstAddresses: map<Int,DstAddresses>;
    dstChainId: map<Int,Int>;
    dstAssetId: map<Int,Address>;
    dstAddress: map<Int,StringImpl>;
    srcAssetId: map<Int,Int>;
    srcAddress: map<Int,Address>;
    timelock: map<Int,Int>;
    messenger: map<Int,Address>;
    amount: map<Int,Int>;
}

message CreatePBatch{
    data: CreatePBatchData;
}
struct ConvertPBatchData{
    phtlcIDs: map<Int,Int>;
    hashlocks: map<Int,Int>;
    }

message ConvertPBatch{
    data: ConvertPBatchData;
}

struct CreateBatchData{
    _srcAddresses: map<Int,Address>;
    _hashlocks: map<Int,Int>;
    _timelocks: map<Int,Int>;
    _chainIDs: map<Int,Int>;
    _targetCurrencyReceiversAddresses: map<Int,StringImpl>;
    _amounts: map<Int,Int>;
    _phtlcIds: map<Int,Int>;
    _messengers: map<Int,Address>;
}

message CreateBatch{
    data: CreateBatchData;
}

struct BatchRedeemData{
    htlcIDs: map<Int,Int>;
    secrets: map<Int,Int>;
}

message BatchRedeem{
    data: BatchRedeemData;
}

contract HashedTimeLockTON with Deployable {
    init() {
        
    }

    contracts: map<Int, HTLC> ;
    pContracts: map<Int, PHTLC>;
    counter: Int = 0;

    fun htlcExsits(hashlock: Int): Bool {
        if(self.contracts.get(hashlock) == null){
            return false;
        }
        return true;
    }

    fun phtlcExists(phtlcID: Int): Bool {
        if(self.pContracts.get(phtlcID) == null){
            return false;
        }
        return true;
    }

    receive(msg: CreateP){
            let ctx: Context = context();

            require(ctx.value != 0,"Funds Not Sent");
            require(msg.data.timelock > now(),"Not Future Timelock");

            self.counter +=1;
            let phtlcID: Int = self.counter;

            self.pContracts.set(phtlcID, PHTLC {
                                                dstAddress: msg.data.dstAddress,
                                                srcAssetId: msg.data.srcAssetId,
                                                sender: ctx.sender,
                                                srcAddress: msg.data.srcAddress,
                                                timelock: msg.data.timelock, 
                                                messenger: msg.data.messenger,
                                                amount: ctx.value,
                                                refunded: false,
                                                converted: false,
                                                phtlcID: phtlcID
                                                });

            emit(PreHTLCID {phtlcID: phtlcID}.toCell());
    }

    receive(msg: CreatePBatch){
        let ctx: Context = context();
        let totalAmount: Int = 0;
        let amount: map<Int,Int> = msg.data.amount;
        
        foreach (key, value in amount) {
            require(value != 0,"Funds Not Sent");
            totalAmount += value;
        }
        require(ctx.value == totalAmount,"Incorrect Data");

        let chainIds: map<Int,ChainIDs> = msg.data.chainIds;
        let dstAddresses: map<Int,DstAddresses> = msg.data.dstAddresses;
        let dstChainId: map<Int,Int> = msg.data.dstChainId;
        let dstAssetId: map<Int,Address> = msg.data.dstAssetId;
        let dstAddress: map<Int,StringImpl> = msg.data.dstAddress;
        let srcAssetId: map<Int,Int> = msg.data.srcAssetId;
        let srcAddress: map<Int,Address> = msg.data.srcAddress;
        let timelock: map<Int,Int> = msg.data.timelock;
        let messenger: map<Int,Address> = msg.data.messenger;

        foreach (key, value in srcAddress) {
            if(dstAddresses.get(key) == null || dstChainId.get(key) == null || dstAssetId.get(key) == null ||
               dstAddress.get(key) == null || srcAssetId.get(key) == null || srcAddress.get(key) == null ||
               timelock.get(key) == null || messenger.get(key) == null || chainIds.get(key) == null || amount.get(key) == null){
                require(false,"Incorrect Data");
               }
        }

        foreach(key,value in timelock){
            require(timelock.get(key)!! > now(),"Not Future Timelock");
        }

        foreach(key,value in srcAddress){
            self.counter +=1;
            let phtlcID: Int = self.counter; 
            self.pContracts.set(phtlcID, PHTLC {
                                                dstAddress: (dstAddress.get(key)!!).data,
                                                srcAssetId: srcAssetId.get(key)!!,
                                                sender: ctx.sender,
                                                srcAddress: srcAddress.get(key)!!,
                                                timelock: timelock.get(key)!!, 
                                                messenger: messenger.get(key)!!,
                                                amount: amount.get(key)!!,
                                                refunded: false,
                                                converted: false,
                                                phtlcID: phtlcID
                                               });

            emit(PreHTLCID {phtlcID: phtlcID}.toCell());
        }
    }

    receive(msg: RefundP){
        require(self.phtlcExists(msg.phtlcID) == true,"Contract Does Not Exist");
        require((self.pContracts.get(msg.phtlcID)!!).refunded == false,"Already Refunded");
        require((self.pContracts.get(msg.phtlcID)!!).converted == false,"Already Converted");
        require((self.pContracts.get(msg.phtlcID)!!).timelock <= now(),"Not Passed Timelock");

        let ctx: Context = context();

        self.pContracts.set(msg.phtlcID,PHTLC  {
                                                dstAddress: (self.pContracts.get(msg.phtlcID)!!).dstAddress,
                                                srcAssetId: (self.pContracts.get(msg.phtlcID)!!).srcAssetId,
                                                sender: (self.pContracts.get(msg.phtlcID)!!).sender,
                                                srcAddress: (self.pContracts.get(msg.phtlcID)!!).srcAddress,
                                                timelock: (self.pContracts.get(msg.phtlcID)!!).timelock, 
                                                messenger: (self.pContracts.get(msg.phtlcID)!!).messenger,
                                                amount: (self.pContracts.get(msg.phtlcID)!!).amount,
                                                refunded: true,
                                                converted: false,
                                                phtlcID: (self.pContracts.get(msg.phtlcID)!!).phtlcID    
                                                });

        send(SendParameters{to: (self.pContracts.get(msg.phtlcID)!!).sender,
                            bounce: true,
                            value: (self.pContracts.get(msg.phtlcID)!!).amount + ctx.value,
                            mode: 0}); 
    }

    receive(msg: ConvertP){
        let ctx: Context = context();
        let htlcID: Int = msg.data.hashlock;

        if(ctx.sender == (self.pContracts.get(msg.data.phtlcID)!!).sender || ctx.sender == (self.pContracts.get(msg.data.phtlcID)!!).messenger){
                    require(self.htlcExsits(htlcID) == false ,"HTLC With That Hashlock Exists");
                    require((self.pContracts.get(msg.data.phtlcID)!!).converted == false,"Already Converted To HTLC");
                    
                    self.pContracts.set(msg.data.phtlcID,PHTLC{
                                                                dstAddress: (self.pContracts.get(msg.data.phtlcID)!!).dstAddress,
                                                                srcAssetId: (self.pContracts.get(msg.data.phtlcID)!!).srcAssetId,
                                                                sender: (self.pContracts.get(msg.data.phtlcID)!!).sender,
                                                                srcAddress: (self.pContracts.get(msg.data.phtlcID)!!).srcAddress,
                                                                timelock: (self.pContracts.get(msg.data.phtlcID)!!).timelock, 
                                                                messenger: (self.pContracts.get(msg.data.phtlcID)!!).messenger,
                                                                amount: (self.pContracts.get(msg.data.phtlcID)!!).amount,
                                                                refunded: false,
                                                                converted: true,
                                                                phtlcID: (self.pContracts.get(msg.data.phtlcID)!!).phtlcID    
                                                               });


                    self.contracts.set(htlcID,HTLC{       
                                                    hashlock: msg.data.hashlock,
                                                    secret: 0x0,
                                                    amount: (self.pContracts.get(msg.data.phtlcID)!!).amount,
                                                    timelock: (self.pContracts.get(msg.data.phtlcID)!!).timelock,
                                                    sender: (self.pContracts.get(msg.data.phtlcID)!!).sender,
                                                    srcAddress: (self.pContracts.get(msg.data.phtlcID)!!).srcAddress,
                                                    redeemed: false,
                                                    refunded: false
                                                   }); 

                    send(SendParameters{to: ctx.sender,
                                        bounce: true,
                                        value: ctx.value,
                                        mode: 0});
                                    
        }else{
            require(false,"No Allowance");
        }
    }

    receive(msg: ConvertPBatch){
        let ctx: Context = context();
        let phtlcIDs: map<Int,Int> = msg.data.phtlcIDs;
        let hashlocks: map<Int,Int> = msg.data.hashlocks;

        foreach(key,value in phtlcIDs){
            require(hashlocks.get(key) != null,"Incorrect Data");
            require(self.phtlcExists(value) == true,"PreHTLC Does Not Exist");
            require(self.pContracts.get(value)!!.converted == false,"Already Converted To HTLC");
        }

        foreach(key,value in hashlocks){
            require(phtlcIDs.get(key) != null,"Incorrect Data");
            require(self.htlcExsits(value) == false,"HTLC With That Hashlock Exists");
        }

        foreach(key,value in phtlcIDs){
            if(ctx.sender == self.pContracts.get(value)!!.sender || ctx.sender == self.pContracts.get(value)!!.messenger){
                    self.pContracts.set(value,PHTLC{
                                                    dstAddress: (self.pContracts.get(value)!!).dstAddress,
                                                    srcAssetId: (self.pContracts.get(value)!!).srcAssetId,
                                                    sender: (self.pContracts.get(value)!!).sender,
                                                    srcAddress: (self.pContracts.get(value)!!).srcAddress,
                                                    timelock: (self.pContracts.get(value)!!).timelock, 
                                                    messenger: (self.pContracts.get(value)!!).messenger,
                                                    amount: (self.pContracts.get(value)!!).amount,
                                                    refunded: false,
                                                    converted: true,
                                                    phtlcID: (self.pContracts.get(value)!!).phtlcID    
                                                    });


                    self.contracts.set(hashlocks.get(key)!!, HTLC{  
                                                                    hashlock: hashlocks.get(key)!!,
                                                                    secret: 0x0,
                                                                    amount: (self.pContracts.get(value)!!).amount,
                                                                    timelock: (self.pContracts.get(value)!!).timelock,
                                                                    sender: (self.pContracts.get(value)!!).sender,
                                                                    srcAddress: (self.pContracts.get(value)!!).srcAddress,
                                                                    redeemed: false,
                                                                    refunded: false
                                                                    });  
            }else{
                require(false,"No Allowance");
            }

        }

        send(SendParameters{to: ctx.sender,
                            bounce: true,
                            value: ctx.value,
                            mode: 0});
    }

    receive(msg: Create){ 
        let ctx: Context = context();
        require(self.htlcExsits(msg.data.__hashlock) == false,"Contract Already Exists"); 
        require(now() <= msg.data.__timelock ,"Not Future Timelock");
        require(ctx.value != 0,"Funds Not Sent");

        self.contracts.set(msg.data.__hashlock,  HTLC  {
                                                        hashlock: msg.data.__hashlock,
                                                        secret: 0x0,
                                                        amount: ctx.value,
                                                        timelock: msg.data.__timelock,
                                                        sender: msg.data.__sender,
                                                        srcAddress: msg.data.__srcAddress,
                                                        redeemed: false,
                                                        refunded: false
                                                        });

        send(SendParameters{to: msg.data.__messenger,
                            bounce: true,
                            value: 20000000,
                            mode: 0,
                            body: HTLCNotify {data: HTLCNotification {
                                                                        htlcID: msg.data.__hashlock,
                                                                        sender: msg.data.__sender,
                                                                        receiver: msg.data.__srcAddress,
                                                                        amount: ctx.value,
                                                                        timelock: msg.data.__timelock,
                                                                        hashlock: msg.data.__hashlock,
                                                                        dstAddress: msg.data.__targetCurrencyReceiverAddress,
                                                                        phtlcID: msg.data.__phtlcID
                                                                    }}.toCell()});           
    }

    receive(msg: CreateBatch){
            let ctx: Context = context();
            let _srcAddresses: map<Int,Address> = msg.data._srcAddresses;
            let _hashlocks: map<Int,Int> = msg.data._hashlocks;
            let _timelocks: map<Int,Int> = msg.data._timelocks;
            let _chainIDs: map<Int,Int> = msg.data._chainIDs;
            let _targetCurrencyReceiversAddresses: map<Int,StringImpl> = msg.data._targetCurrencyReceiversAddresses;
            let _amounts: map<Int,Int> = msg.data._amounts;
            let _phtlcIds: map<Int,Int> = msg.data._phtlcIds;
            let _messengers: map<Int,Address> = msg.data._messengers;
            let totalAmount: Int = 0;

            foreach(key,value in _amounts){
                totalAmount+=value;
                require(value != 0,"Funds Not Sent");
            }
            require(ctx.value == totalAmount,"Incorrect Data");

            foreach(key,value in _srcAddresses){
                if (_hashlocks.get(key) == null || _timelocks.get(key) == null || _chainIDs.get(key) == null || 
                    _targetCurrencyReceiversAddresses.get(key) == null || _amounts.get(key) == null || 
                    _phtlcIds.get(key) == null || _messengers.get(key) == null){
                     require(false,"Incorrect Data");
                   }
            }

            foreach(key,value in _timelocks){
                require(value > now(),"Not Future Timelock");
            }

            foreach(key,value in _hashlocks){
                require(self.htlcExsits(value) == false, "Contract Already Exists");
            }

            foreach(key,value in _hashlocks){
                    self.contracts.set(value, HTLC {
                                                    hashlock: value,
                                                    secret: 0x0,
                                                    amount: _amounts.get(key)!!,
                                                    timelock: _timelocks.get(key)!!,
                                                    sender: ctx.sender,
                                                    srcAddress: _srcAddresses.get(key)!!,
                                                    redeemed: false,
                                                    refunded: false
                                                    });


                    send(SendParameters{to: _messengers.get(key)!!,
                                        bounce: true,
                                        value: 20000000,
                                        mode: 0,
                                        body: HTLCNotify {data: HTLCNotification {
                                                                                    htlcID: value,
                                                                                    sender: ctx.sender,
                                                                                    receiver: _srcAddresses.get(key)!!,
                                                                                    amount: _amounts.get(key)!!,
                                                                                    timelock: _timelocks.get(key)!!,
                                                                                    hashlock: value,
                                                                                    dstAddress: _targetCurrencyReceiversAddresses.get(key)!!.data,
                                                                                    phtlcID: _phtlcIds.get(key)!!
                                                                                }}.toCell()});
                 }
        }

    receive(msg: Redeem) {
        let ctx: Context = context();
        require(self.htlcExsits(msg.data.__hashlock) == true, "Contract Does Not Exist");

        let pre: Int = sha256((msg.data.__secret).toString());
        let hashlockFromSecret: Int = sha256(pre.toString());

        require((self.contracts.get(msg.data.__hashlock)!!).hashlock == hashlockFromSecret,"Hashlock Not Match");
        require((self.contracts.get(msg.data.__hashlock)!!).refunded == false,"Already Refunded");
        require((self.contracts.get(msg.data.__hashlock)!!).redeemed == false,"Already Redeemed");

        self.contracts.set(msg.data.__hashlock, HTLC {
                                                        hashlock: (self.contracts.get(msg.data.__hashlock)!!).hashlock,
                                                        secret: msg.data.__secret,
                                                        amount: (self.contracts.get(msg.data.__hashlock)!!).amount,
                                                        timelock: (self.contracts.get(msg.data.__hashlock)!!).timelock,
                                                        sender: (self.contracts.get(msg.data.__hashlock)!!).sender,
                                                        srcAddress: (self.contracts.get(msg.data.__hashlock)!!).srcAddress,
                                                        redeemed: true,
                                                        refunded: false
                                                        });

        
        send(SendParameters{
                            to: (self.contracts.get(msg.data.__hashlock)!!).srcAddress,
                            bounce: true,
                            value: (self.contracts.get(msg.data.__hashlock)!!).amount + ctx.value,
                            mode: 0
                            });     
    }


    receive(msg: BatchRedeem){
        let ctx: Context = context();
        let htlcIDs: map<Int,Int> = msg.data.htlcIDs;
        let secrets: map<Int,Int> = msg.data.secrets;

        foreach(key,value in htlcIDs){
            require(secrets.get(key) != null,"Incorrect Data");
            require(self.htlcExsits(value) == true, "Contract Does Not Exist");
        }

        foreach(key,value in secrets){
            require(htlcIDs.get(key) != null,"Incorrect Data");
        }

        let totalRedeem: Int = 0;

        foreach(key,value in htlcIDs){
            let pre: Int = sha256((secrets.get(key)!!).toString());
            let hashlockFromSecret: Int = sha256(pre.toString());

            require((self.contracts.get(value)!!).hashlock == hashlockFromSecret,"Hashlock Not Match");
            require((self.contracts.get(value)!!).refunded == false,"Already Refunded");
            require((self.contracts.get(value)!!).redeemed == false,"Already Redeemed");

            self.contracts.set(value, HTLC {               
                                            hashlock: value,
                                            secret: secrets.get(key)!!,
                                            amount: (self.contracts.get(value)!!).amount,
                                            timelock: (self.contracts.get(value)!!).timelock,
                                            sender: (self.contracts.get(value)!!).sender,
                                            srcAddress: (self.contracts.get(value)!!).srcAddress,
                                            redeemed: true,
                                            refunded: false
                                            });

            if(ctx.sender == self.contracts.get(value)!!.srcAddress){
                totalRedeem += self.contracts.get(value)!!.amount;
            }else{
                send(SendParameters{
                            to: (self.contracts.get(value)!!).srcAddress,
                            bounce: true,
                            value: (self.contracts.get(value)!!).amount,
                            mode: 0
                        });
            }
        }

        send(SendParameters{
                            to: ctx.sender,
                            bounce: true,
                            value: totalRedeem + ctx.value,
                            mode: 0
                        });

    }

    receive(msg: Refund){
        let ctx: Context = context();
        require(self.htlcExsits(msg.data.__hashlock) == true,"Contract Does Not Exist");
        require((self.contracts.get(msg.data.__hashlock)!!).refunded == false,"Already Refunded");
        require((self.contracts.get(msg.data.__hashlock)!!).redeemed == false,"Already Redeemed");
        require((self.contracts.get(msg.data.__hashlock)!!).timelock < now(), "Not Passed Timelock");
            
        self.contracts.set(msg.data.__hashlock, HTLC {
                                                        hashlock: (self.contracts.get(msg.data.__hashlock)!!).hashlock,
                                                        secret: (self.contracts.get(msg.data.__hashlock)!!).secret,
                                                        amount: (self.contracts.get(msg.data.__hashlock)!!).amount,
                                                        timelock: (self.contracts.get(msg.data.__hashlock)!!).timelock,
                                                        sender: (self.contracts.get(msg.data.__hashlock)!!).sender,
                                                        srcAddress: (self.contracts.get(msg.data.__hashlock)!!).srcAddress,
                                                        redeemed: false,
                                                        refunded: true
                                                    });

        send(SendParameters{
                            to: (self.contracts.get(msg.data.__hashlock)!!).sender,
                            bounce: true,
                            value: (self.contracts.get(msg.data.__hashlock)!!).amount + ctx.value,
                            mode: 0
                           });
    }

    get fun getHTLCDetails(hashlock: Int): HTLC? {
        return self.contracts.get(hashlock);
    }

    get fun getPHTLCDetails(phtlcID: Int): PHTLC?{
        return self.pContracts.get(phtlcID);
    }

}



