// import "@stdlib/deploy";
//     struct HTLC {
//         hashlock: Int as int256;
//         secret: Int as int256;
//         amount: Int as int256;
//         timelock: Int as uint256;
//         sender: Address;
//         _receiver: Address;
//         redeemed: Bool;
//         refunded: Bool;
//     }

//     message TonTransferInitiated {
//        __hashlock: Int as int256;
//        __amount: Int as int256;
//        __chainId: Int as int256;
//        __timelock: Int as int256;
//        __sender: Address;
//        __receiver: Address;
//        __targetCurrencyReceiverAddress: String; 
//     }

//     message TonTransferClaimed {
//         __hashlock: Int as int256;
//         __receiver: Address;
//         __amount: Int as int256;
//     }

//     message TonTransferRefunded {
//         __hashlock: Int as int256;
//         __receiver: Address;
//         __amount: Int as int256;
//     }


// contract HashedTimeLockTON with Deployable {
//     init() {
        
//     }

//     contracts: map<Int as int256, HTLC> ;

//     fun contractExists(hashlock: Int): Bool {
//         if(self.contracts.get(hashlock) != null){
//             return true;
//         }
//         return false;
//     }



//     fun create(_Receiver: Address, _hashlock: Int, _timelock: Int, _chainId: Int,_targetCurrencyReceiverAddress: String , _amount: Int): Int {
//         require(now() <= _timelock,"Not Future Timelock");
//         require(_amount != 0,"Funds Not Sent");

//         require(false == self.contractExists(_hashlock),"Contract Already Exists");                                                                

//         let htlc: HTLC = HTLC { hashlock: _hashlock,
//                                 amount: _amount,
//                                 secret: 0x0,
//                                 timelock: _timelock,
//                                 sender: sender(),
//                                 _receiver: _Receiver,
//                                 redeemed: false,
//                                 refunded: false};

//         self.contracts.set(_hashlock,htlc);

//         emit(TonTransferInitiated{
//                         __hashlock: _hashlock,
//                         __amount: _amount,
//                         __chainId: _chainId,
//                         __timelock: _timelock,
//                         __sender: sender(),
//                         __receiver: _Receiver,
//                         __targetCurrencyReceiverAddress: _targetCurrencyReceiverAddress
//                         }.toCell());

//         return _hashlock;
//     }


//     fun redeem(hashlock: Int, _secret: Int): Bool{
//             let pre: Int = sha256(_secret.toString());
//             let hashlockFromSecret: Int = sha256(pre.toString());

        
//             require((self.contracts.get(hashlock)!!).hashlock == hashlockFromSecret,"Hashlock Not Match");
//             require((self.contracts.get(hashlock)!!).refunded == false,"Already Refunded");
//             require((self.contracts.get(hashlock)!!).redeemed == false,"Already Redeemed");
//             require((self.contracts.get(hashlock)!!).timelock <= now(),"Not Future Timelock");

//             let htlc: HTLC =  HTLC {
//                             hashlock: (self.contracts.get(hashlock)!!).hashlock,
//                             secret: _secret,
//                             amount: (self.contracts.get(hashlock)!!).amount,
//                             timelock: (self.contracts.get(hashlock)!!).timelock,
//                             sender: (self.contracts.get(hashlock)!!).sender,
//                             _receiver: (self.contracts.get(hashlock)!!)._receiver,
//                             redeemed: true,
//                             refunded: false
//             };
            
//             self.contracts.set(hashlock,htlc);

//             emit(TonTransferClaimed{__hashlock: hashlock, __receiver: htlc._receiver, __amount: htlc.amount}.toCell());
//             return true;
//         }


    

//     fun refund(hashlock: Int): Bool {

//         if(self.contractExists(hashlock)){
//             let htlc: HTLC = self.contracts.get(hashlock)!!;

//             require(htlc.refunded == false, "Already Refunded");
//             require(htlc.redeemed == false, "Already Redeemed");
//             require(htlc.timelock > now(), "Not Passed Timelock");

//             htlc.refunded = true;
            

//             emit(TonTransferRefunded{__hashlock: hashlock,__receiver: htlc.sender, __amount: htlc.amount}.toCell());

//             return true;
//         }
//           return false;  
//     }

//     get fun getHTLCDetails(hashlock: Int): HTLC? {
//             if(self.contractExists(hashlock)){
//                 return self.contracts.get(hashlock);
//             }

//             return HTLC {
//                             hashlock: 0x0,
//                             secret: 0x0,
//                             amount: 0x0,
//                             timelock: 0x0,
//                             sender: newAddress(0,0),
//                             _receiver: newAddress(0,0),
//                             redeemed: false,
//                             refunded: false
//             };
//     }

//     receive(msg: TonTransferInitiated){
//                 send(SendParameters{
//                 to: contractAddress(initOf HashedTimeLockTON()),
//                 bounce: true,
//                 value: msg.__amount,
//                 mode: SendBounceIfActionFail + SendPayGasSeparately
//         });
//     }

//     receive(msg: TonTransferClaimed) {
//         send(SendParameters{
//                 to: msg.__receiver,
//                 bounce: true,
//                 value: msg.__amount,
//                 mode: SendBounceIfActionFail + SendPayGasSeparately
//             });
//     }

//     receive(msg: TonTransferRefunded){
//         send(SendParameters{
//                 to: msg.__receiver,
//                 bounce: true,
//                 value: msg.__amount,
//                 mode: SendBounceIfActionFail + SendPayGasSeparately
//             });
//     }

// }


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


import "@stdlib/deploy";
    struct HTLC {
        hashlock: Int as int256;
        secret: Int as int256;
        amount: Int as coins;
        timelock: Int as uint256;
        sender: Address;
        _receiver: Address;
        redeemed: Bool;
        refunded: Bool;
    }

    struct TonTransferInitiated {
       __hashlock: Int as int256;
       __amount: Int as coins;
       __chainId: Int as int256;
       __timelock: Int as int256;
       __sender: Address;
       __receiver: Address;
       __targetCurrencyReceiverAddress: String; 
    }

    message Create {
        data: TonTransferInitiated;
    }

    struct TonTransferClaimed {
        __hashlock: Int as int256;
        __receiver: Address;
        __amount: Int as coins;
    }

    message Redeem {
        data: TonTransferClaimed;
    }

    struct TonTransferRefunded {
        __hashlock: Int as int256;
        __receiver: Address;
        __amount: Int as coins;
    }

    message Refund {
        data: TonTransferRefunded;
    }

contract HashedTimeLockTON with Deployable {
    init() {
        
    }

    contracts: map<Int as int256, HTLC> ;

    fun contractExists(hashlock: Int): Bool {
        if(self.contracts.get(hashlock) != null){
            return true;
        }
        return false;
    }



    fun create(_Receiver: Address, _hashlock: Int, _timelock: Int, _chainId: Int,_targetCurrencyReceiverAddress: String , _amount: Int): Int {
        require(now() <= _timelock,"Not Future Timelock");
        require(_amount != 0,"Funds Not Sent");

        require(false == self.contractExists(_hashlock),"Contract Already Exists");                                                                

        let htlc: HTLC = HTLC { hashlock: _hashlock,
                                amount: _amount,
                                secret: 0x0,
                                timelock: _timelock,
                                sender: sender(),
                                _receiver: _Receiver,
                                redeemed: false,
                                refunded: false};

        self.contracts.set(_hashlock,htlc);

        emit(Create {data: TonTransferInitiated{
                        __hashlock: _hashlock,
                        __amount: _amount,
                        __chainId: _chainId,
                        __timelock: _timelock,
                        __sender: sender(),
                        __receiver: _Receiver,
                        __targetCurrencyReceiverAddress: _targetCurrencyReceiverAddress
                        }}.toCell());

        return _hashlock;
    }


    fun redeem(hashlock: Int, _secret: Int): Bool{
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
                send(SendParameters{
                to: myAddress(),
                bounce: true,
                value: msg.data.__amount,
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
                            sender: newAddress(0,0),
                            _receiver: newAddress(0,0),
                            redeemed: false,
                            refunded: false
            };
    }
}
