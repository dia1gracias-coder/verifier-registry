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
    phtlcID: Int;
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

        self.counter +=1;
        let phtlcID: Int = self.counter;

        if(msg.data.amount == 0 || msg.data.timelock <= now()){
            send(SendParameters{to: ctx.sender,
                                bounce: true,
                                value: ctx.value,
                                mode: 0}); 
        }else{
                    self.pContracts.set(phtlcID, PHTLC {
                                                                dstAddress: msg.data.dstAddress,
                                                                srcAssetId: msg.data.srcAssetId,
                                                                sender: ctx.sender,
                                                                srcAddress: msg.data.srcAddress,
                                                                timelock: msg.data.timelock, 
                                                                messenger: msg.data.messenger,
                                                                amount: msg.data.amount,
                                                                refunded: false,
                                                                converted: false,
                                                                phtlcID: phtlcID
                                                            });
        }
        require(msg.data.amount != 0,"Funds Not Sent");
        require(msg.data.timelock > now(),"Not Future Timelock");
    }

    receive(msg: RefundP){
        require(self.phtlcExists(msg.phtlcID) == true,"Contract Does Not Exist");
        require((self.pContracts.get(msg.phtlcID)!!).refunded == false,"Already Refunded");
        require((self.pContracts.get(msg.phtlcID)!!).converted == false,"Already Converted");
        require((self.pContracts.get(msg.phtlcID)!!).timelock <= now(),"Not Passed Timelock");

        let ctx: Context = context();

        self.pContracts.set(msg.phtlcID,PHTLC{
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
                    require(self.htlcExsits(htlcID) == false ,"HTLC with that hashlock exists");
                    
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


                    self.contracts.set(htlcID, HTLC {       hashlock: msg.data.hashlock,
                                                            secret: 0x0,
                                                            amount: (self.pContracts.get(msg.data.phtlcID)!!).amount,
                                                            timelock: (self.pContracts.get(msg.data.phtlcID)!!).timelock,
                                                            sender: (self.pContracts.get(msg.data.phtlcID)!!).sender,
                                                            srcAddress: (self.pContracts.get(msg.data.phtlcID)!!).srcAddress,
                                                            redeemed: false,
                                                            refunded: false
                                                            });                 
        }else{
            require(1 == 0,"No Allowance");
        }
    }

    receive(msg: Create){ 
        let ctx: Context = context();
        if(false == self.htlcExsits(msg.data.__hashlock) && now() <= msg.data.__timelock && msg.data.__amount != 0){
                    self.contracts.set(msg.data.__hashlock, HTLC {hashlock: msg.data.__hashlock,
                                                                secret: 0x0,
                                                                amount: msg.data.__amount,
                                                                timelock: msg.data.__timelock,
                                                                sender: msg.data.__sender,
                                                                srcAddress: msg.data.__srcAddress,
                                                                redeemed: false,
                                                                refunded: false});

                    send(SendParameters{to: msg.data.__messenger,
                                        bounce: true,
                                        value: 2000000,
                                        mode: 0,
                                        body: HTLCNotify {data: HTLCNotification {
                                                                                    htlcID: msg.data.__hashlock,
                                                                                    sender: msg.data.__sender,
                                                                                    receiver: msg.data.__srcAddress,
                                                                                    amount: msg.data.__amount,
                                                                                    timelock: msg.data.__timelock,
                                                                                    hashlock: msg.data.__hashlock,
                                                                                    dstAddress: msg.data.__targetCurrencyReceiverAddress,
                                                                                    phtlcID: msg.data.__phtlcID
                                                                                }}.toCell()});
        }else{
                    send(SendParameters{to: ctx.sender,
                                        bounce: true,
                                        value: ctx.value,
                                        mode: 0}); 
          
        require(false == self.htlcExsits(msg.data.__hashlock),"Contract Already Exists"); 
        require(now() <= msg.data.__timelock ,"Not Future Timelock");
        require(msg.data.__amount != 0,"Funds Not Sent");
        }            
    }

        receive(msg: Redeem) {
            require(self.htlcExsits(msg.data.__hashlock) == true, "Contract Does Not Exist");

            let pre: Int = sha256((msg.data.__secret).toString());
            let hashlockFromSecret: Int = sha256(pre.toString());
            let ctx: Context = context();                                                           

        
            require((self.contracts.get(msg.data.__hashlock)!!).hashlock == hashlockFromSecret,"Hashlock Not Match");
            require((self.contracts.get(msg.data.__hashlock)!!).refunded == false,"Already Refunded");
            require((self.contracts.get(msg.data.__hashlock)!!).redeemed == false,"Already Redeemed");

            self.contracts.set(msg.data.__hashlock, HTLC {hashlock: (self.contracts.get(msg.data.__hashlock)!!).hashlock,
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



