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
        __receiver: Address;
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
        if(self.contracts.get(hashlock) != null){
            return true;
        }
        return false;
    }



    fun create(_Receiver: Address, _hashlock: Int, _timelock: Int, _chainId: Int,_targetCurrencyReceiverAddress: String ): Int {
        let ctx: Context = context();
        require(now() <= _timelock,"Not Future Timelock");
        require(ctx.value != 0,"Funds Not Sent");

        require(false == self.contractExists(_hashlock),"Contract Already Exists");                                                                

        let htlc: HTLC = HTLC { hashlock: _hashlock,
                                amount: ctx.value,
                                secret: 0x0,
                                timelock: _timelock,
                                sender: sender(),
                                _receiver: _Receiver,
                                redeemed: false,
                                refunded: false};

        self.contracts.set(_hashlock,htlc);

        emit(Create {data: TonTransferInitiated{
                        __hashlock: _hashlock,
                        __amount: ctx.value,
                        __chainId: _chainId,
                        __timelock: _timelock,
                        __sender: sender(),
                        __receiver: _Receiver,
                        __targetCurrencyReceiverAddress: _targetCurrencyReceiverAddress
                        }}.toCell());

        return _hashlock;
    }


    fun redeem(hashlock: Int, _secret: Int): Bool{
            require(self.contractExists(hashlock), "Contract does not exist");

            let pre: Int = sha256(_secret.toString());
            let hashlockFromSecret: Int = sha256(pre.toString());

        
            require((self.contracts.get(hashlock)!!).hashlock == hashlockFromSecret,"Hashlock Not Match");
            require((self.contracts.get(hashlock)!!).refunded == false,"Already Refunded");
            require((self.contracts.get(hashlock)!!).redeemed == false,"Already Redeemed");
            require((self.contracts.get(hashlock)!!).timelock <= now(),"Not Future Timelock");

            let htlc: HTLC =  HTLC {
                            hashlock: (self.contracts.get(hashlock)!!).hashlock,
                            secret: _secret,
                            amount: (self.contracts.get(hashlock)!!).amount,
                            timelock: (self.contracts.get(hashlock)!!).timelock,
                            sender: (self.contracts.get(hashlock)!!).sender,
                            _receiver: (self.contracts.get(hashlock)!!)._receiver,
                            redeemed: true,
                            refunded: false
            };
            
            self.contracts.set(hashlock,htlc);

            emit(Redeem{data: TonTransferClaimed{__hashlock: hashlock, __receiver: htlc._receiver, __amount: htlc.amount}}.toCell());
            return true;
        }


    

    fun refund(hashlock: Int): Bool {

        if(self.contractExists(hashlock)){
            let htlc: HTLC = self.contracts.get(hashlock)!!;

            require(htlc.refunded == false, "Already Refunded");
            require(htlc.redeemed == false, "Already Redeemed");
            require(htlc.timelock > now(), "Not Passed Timelock");

            htlc.refunded = true;
            

            emit(Refund {data:TonTransferRefunded{__hashlock: hashlock,__receiver: htlc.sender, __amount: htlc.amount}}.toCell());

            return true;
        }
          return false;  
    }

    receive(msg: Create){
        let ctx: Context = context();
                send(SendParameters{
                to: myAddress(),
                bounce: true,
                value: ctx.value,
                mode: SendBounceIfActionFail + SendPayGasSeparately
        });
    }

    receive(msg: Redeem) {
        send(SendParameters{
                to: msg.data.__receiver,
                bounce: true,
                value: msg.data.__amount,
                mode: SendBounceIfActionFail + SendPayGasSeparately
            });
    }

    receive(msg: Refund){
        send(SendParameters{
                to: msg.data.__receiver,
                bounce: true,
                value: msg.data.__amount,
                mode: SendBounceIfActionFail + SendPayGasSeparately
            });
    }

    get fun getHTLCDetails(hashlock: Int): HTLC? {
            if(self.contractExists(hashlock)){
                return self.contracts.get(hashlock);
            }
            return HTLC {
                            hashlock: 0x0,
                            secret: 0x0,
                            amount: 0x0,
                            timelock: 0x0,
                            sender: newAddress(0,0x0),
                            _receiver: newAddress(0,0x0),
                            redeemed: false,
                            refunded: false
            };
    }

}


