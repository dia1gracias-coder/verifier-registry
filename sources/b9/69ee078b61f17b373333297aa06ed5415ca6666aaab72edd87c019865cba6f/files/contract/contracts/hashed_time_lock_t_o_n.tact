import "@stdlib/deploy";
    struct HTLC {
        hashlock: Int;
        secret: Int;
        amount: Int;
        timelock: Int;
        sender: Address;
        _receiver: Address;
        redeemed: Bool;
        refunded: Bool;
    }

    struct TonTransferInitiated {
       __hashlock: Int;
       __amount: Int;
       __chainId: Int ;
       __timelock: Int ;
       __sender: Address;
       __receiver: Address;
       __targetCurrencyReceiverAddress: String; 
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

    fun contractExists(hashlock: Int): Bool {
        if(self.contracts.get(hashlock) == null){
            return false;
        }
        return true;
    }

    fun create(_Receiver: Address, _hashlock: Int, _timelock: Int, _chainId: Int,_targetCurrencyReceiverAddress: String ): Int {
        let ctx: Context = context();                                                           

        emit(Create {data: TonTransferInitiated{__hashlock: _hashlock,
                                                __amount: ctx.value,
                                                __chainId: _chainId,
                                                __timelock: _timelock,
                                                __sender: sender(),
                                                __receiver: _Receiver,
                                                __targetCurrencyReceiverAddress: _targetCurrencyReceiverAddress
                                                }}.toCell());
        return _hashlock;
    }


    fun redeem(hashlock: Int, _secret: Int): Int{
            emit(Redeem{data: TonTransferClaimed{__hashlock: hashlock, __secret: _secret, __amount: (self.contracts.get(hashlock)!!).amount}}.toCell());
            return hashlock;
        }

    fun refund(hashlock: Int): Bool {
        // if(self.contractExists(hashlock)){
        //     require((self.contracts.get(hashlock)!!).refunded == false,"Already Refunded");
        //     require((self.contracts.get(hashlock)!!).redeemed == false,"Already Redeemed");
        //     require((self.contracts.get(hashlock)!!).timelock > now(), "Not Passed Timelock");

            emit(Refund {data:TonTransferRefunded{__hashlock: hashlock,__receiver: (self.contracts.get(hashlock)!!).sender, __amount: (self.contracts.get(hashlock)!!).amount}}.toCell());

            // return true;
        // }
          return false;  
    }

    receive(msg: Create){
        require(false == self.contractExists(msg.data.__hashlock),"Contract Already Exists"); 

        require(now() <= msg.data.__timelock ,"Not Future Timelock");
        require(msg.data.__amount != 0,"Funds Not Sent");

        self.contracts.set(msg.data.__hashlock, HTLC {hashlock: msg.data.__hashlock,
                                                    secret: 0x0,
                                                    amount: msg.data.__amount,
                                                    timelock: msg.data.__timelock,
                                                    sender: msg.data.__sender,
                                                    _receiver: msg.data.__receiver,
                                                    redeemed: false,
                                                    refunded: false});

        send(SendParameters{to: myAddress(),
                            bounce: true,
                            value: msg.data.__amount,
                            mode: 128});                     
    }

    receive(msg: Redeem) {
            require(self.contractExists(msg.data.__hashlock) == true, "Contract does not exist");

            let pre: Int = sha256((msg.data.__secret).toString());
            let hashlockFromSecret: Int = sha256(pre.toString());
        
            require((self.contracts.get(msg.data.__hashlock)!!).hashlock == hashlockFromSecret,"Hashlock Not Match");
            require((self.contracts.get(msg.data.__hashlock)!!).refunded == false,"Already Refunded");
            require((self.contracts.get(msg.data.__hashlock)!!).redeemed == false,"Already Redeemed");

            self.contracts.set(msg.data.__hashlock, HTLC {hashlock: (self.contracts.get(msg.data.__hashlock)!!).hashlock,
                                                            secret: msg.data.__secret,
                                                            amount: (self.contracts.get(msg.data.__hashlock)!!).amount,
                                                            timelock: (self.contracts.get(msg.data.__hashlock)!!).timelock,
                                                            sender: (self.contracts.get(msg.data.__hashlock)!!).sender,
                                                            _receiver: (self.contracts.get(msg.data.__hashlock)!!)._receiver,
                                                            redeemed: true,
                                                            refunded: false
                                                            });

            send(SendParameters{
                    to: (self.contracts.get(msg.data.__hashlock)!!)._receiver,
                    bounce: true,
                    value: msg.data.__amount,
                    mode: 128
                });
    }

    receive(msg: Refund){
            require(self.contractExists(msg.data.__hashlock) == true, "Contract Does Not Exist");
            require((self.contracts.get(msg.data.__hashlock)!!).refunded == false,"Already Refunded");
            require((self.contracts.get(msg.data.__hashlock)!!).redeemed == false,"Already Redeemed");
            require((self.contracts.get(msg.data.__hashlock)!!).timelock < now(), "Not Passed Timelock");
            

        self.contracts.set(msg.data.__hashlock,HTLC {
                            hashlock: (self.contracts.get(msg.data.__hashlock)!!).hashlock,
                            secret: (self.contracts.get(msg.data.__hashlock)!!).secret,
                            amount: (self.contracts.get(msg.data.__hashlock)!!).amount,
                            timelock: (self.contracts.get(msg.data.__hashlock)!!).timelock,
                            sender: (self.contracts.get(msg.data.__hashlock)!!).sender,
                            _receiver: (self.contracts.get(msg.data.__hashlock)!!)._receiver,
                            redeemed: false,
                            refunded: true
            });

        send(SendParameters{
                to: msg.data.__receiver,
                bounce: true,
                value: msg.data.__amount,
                mode: 128
            });
    }

    get fun getHTLCDetails(hashlock: Int): HTLC? {
        return self.contracts.get(hashlock);
    }

}



