import "@stdlib/deploy";

// Messenger notification
message(0x3beb51c2) Notify {
    srcId: Int;
    hashlock: Int;
    dstChain: String;
    dstAsset: String;
    dstAddress: String;
    srcAsset: String;
    sender: Address;
    srcReceiver: Address;
    amount: Int;
    timelock: Int;
    jettonMasterAddress: Address;
    htlcJettonWalletAddress: Address;  
}

// Lock object
struct HTLC {
    dstAddress: String;
    dstChain: String;
    dstAsset: String;
    srcAsset: String;
    sender: Address;
    senderPubKey: Int;
    srcReceiver: Address;
    secret: Int;
    hashlock: Int;
    amount: Int;
    timelock: Int;
    messenger: Address;
    redeemed: Bool;
    unlocked: Bool;
}

// Messages received by contract
message(0x1b564d91) Commit{
    dstChain: String;
    dstAsset: String;
    dstAddress: String;
    srcAsset: String;
    srcReceiver: Address;
    timelock: Int; 
    messenger: Address;
    senderPubKey: Int;
    hopChains: map<Int,StringImpl>;
    hopAssets: map<Int,StringImpl>;
    hopAddresses: map<Int,StringImpl>;
}

message(0x5cdd41d9) LockCommitment{
    Id: Int;
    hashlock: Int;
    timelock: Int;
}

message(0xc1d818ff) LockCommitmentSig{
    Id: Int;
    data: Slice; 
    signature: Slice;
}

message(0x12e78cb1) Lock {
    hashlock: Int;
    timelock: Int;
    srcReceiver: Address;
    srcAsset: String;
    dstChain: String;
    dstAddress: String;
    dstAsset: String;
    srcId: Int;
    messenger: Address;
}

message(0x758db085) Redeem {
    Id: Int;
    secret: Int;
}

message(0xad821ef9) Unlock {
    Id: Int;
}

// Emitted messages
message(0x71f9f7aa) TokenCommitted{
    Id: Int;
    dstChain: String;
    dstAddress: String;
    dstAsset: String;
    sender: Address;
    srcReceiver: Address;
    srcAsset: String;
    amount: Int;
    timelock: Int; 
    messenger: Address;
    senderPubKey: Int;
    hopChains: map<Int,StringImpl>;
    hopAssets: map<Int,StringImpl>;
    hopAddresses: map<Int,StringImpl>;
}

message(0x95b0219d) TokenLocked{
    hashlock: Int;
    dstChain: String;
    dstAddress: String;
    dstAsset: String;
    sender: Address;
    srcReceiver: Address;
    srcAsset: String;
    amount: Int;
    timelock: Int;
    messenger: Address;
    srcId: Int;
}

// String implementation as struct
struct StringImpl{
    data: String;
}

contract LayerswapV8 with Deployable {
    init() {
    // self.seed = random(10000000000000000000000000000000000000000000000000000000000000000000000000000,99999999999999999999999999999999999999999999999999999999999999999999999999999);
    self.seed = 100;
    }

    contracts: map<Int, HTLC>;
    srcIdToId: map<Int,Int>;
    contractNonce: Int = 0;
    seed: Int;
    zeroAddress: Address = newAddress(0,0x0);
    
    fun contractExists(id: Int): Bool {
        return (self.contracts.get(id) == null)? false : true;
    }

    receive(msg: Commit){
            let ctx: Context = context();

            require(ctx.value != 0,"Funds Not Sent");
            require(msg.timelock > now(),"Not Future Timelock");
            self.contractNonce +=1;
            let Id: Int = self.seed ^ self.contractNonce; 

            require(self.contractExists(Id) == false,"Commit Already Exists");
            self.contracts.set(Id, HTLC {
                                                dstAddress: msg.dstAddress,
                                                dstChain: msg.dstChain,
                                                dstAsset: msg.dstAsset,
                                                srcAsset: msg.srcAsset,
                                                sender: ctx.sender,
                                                senderPubKey: msg.senderPubKey,
                                                srcReceiver: msg.srcReceiver,
                                                secret: 0,
                                                hashlock: 0,
                                                amount: ctx.value,
                                                timelock: msg.timelock, 
                                                messenger: msg.messenger,
                                                redeemed: false,
                                                unlocked: false
                                                });


            emit(TokenCommitted{
                                Id: Id,
                                dstChain: msg.dstChain,
                                dstAddress: msg.dstAddress,
                                dstAsset: msg.dstAsset,
                                sender: sender(),
                                srcReceiver: msg.srcReceiver,
                                srcAsset: msg.srcAsset,
                                amount: ctx.value,
                                timelock: msg.timelock,
                                messenger: msg.messenger,
                                senderPubKey: msg.senderPubKey,
                                hopChains: msg.hopChains,
                                hopAssets: msg.hopAssets,
                                hopAddresses: msg.hopAddresses
                                }.toCell());
    }

    receive(msg: LockCommitment){
        self.lockCommitment(msg,context());
    }

    receive(msg: LockCommitmentSig){
        require(self.contractExists(msg.Id),"Commitment Does Not Exist");
        let htlc: HTLC = (self.contracts.get(msg.Id)!!);
        require(checkSignature(msg.data.hash(),msg.signature,htlc.senderPubKey),"Invalid signature");
        let hashlock: Int = msg.data.loadInt(257);
        let timelock: Int = msg.data.loadInt(257);
        let lockCommitmentMessage: LockCommitment = LockCommitment{
                                                                        Id: msg.Id,
                                                                        hashlock: hashlock,
                                                                        timelock: timelock
                                                                };
        let ctx: Context = context();
        self.lockCommitment(lockCommitmentMessage,ctx);
    }

    receive(msg: Lock){ 
        let ctx: Context = context();
        require(self.contractExists(msg.hashlock) == false,"Lock Already Exists"); 
        require(now() < msg.timelock ,"Not Future Timelock");
        require(ctx.value != 0,"Funds Not Sent");

        self.contracts.set(msg.hashlock,  HTLC {
                                                dstAddress: msg.dstAddress,
                                                dstChain: msg.dstChain,
                                                dstAsset: msg.dstAsset,
                                                srcAsset: msg.srcAsset,
                                                sender: sender(),
                                                senderPubKey: 0, // as after locking it cant be used for LockCommitment
                                                srcReceiver: msg.srcReceiver,
                                                secret: 0,
                                                hashlock: msg.hashlock,
                                                amount: ctx.value,
                                                timelock: msg.timelock,
                                                messenger: msg.messenger,
                                                redeemed: false,
                                                unlocked: false
                                            });

        if(msg.srcId != 0){
            self.srcIdToId.set(msg.srcId,msg.hashlock);
        }

        if(msg.messenger != self.zeroAddress && msg.srcId != 0){
            // notify messenger
            send(SendParameters{to: msg.messenger,
                                bounce: true,
                                value: 20000000,
                                mode: 0,
                                body: Notify{
                                            srcId: msg.srcId,
                                            hashlock: msg.hashlock,
                                            dstChain: msg.dstChain,
                                            dstAsset: msg.dstAsset,
                                            dstAddress: msg.dstAddress,
                                            srcAsset: msg.srcAsset,
                                            sender: sender(),
                                            srcReceiver: msg.srcReceiver,
                                            amount: ctx.value,
                                            timelock: msg.timelock,
                                            jettonMasterAddress: self.zeroAddress,
                                            htlcJettonWalletAddress: self.zeroAddress
                                        }.toCell()});  
        }

        emit(TokenLocked{
                hashlock: msg.hashlock,
                dstChain: msg.dstChain,
                dstAddress: msg.dstAddress,
                dstAsset: msg.dstAsset,
                sender: sender(),
                srcReceiver: msg.srcReceiver,
                srcAsset: msg.srcAsset,
                amount: ctx.value,
                timelock: msg.timelock,
                messenger: msg.messenger,
                srcId: msg.srcId
            }.toCell());
    }

    receive(msg: Redeem) {
        require(self.contractExists(msg.Id) == true, "Lock Does Not Exist");

        let htlc: HTLC = (self.contracts.get(msg.Id)!!);
        require(htlc.unlocked == false,"Already Unlocked");
        require(htlc.redeemed == false,"Already Redeemed");

        let hashlockFromSecretSlice: Slice = beginCell().storeUint(msg.secret,256).asSlice();
        let hashlockFromSecret: Int = sha256(hashlockFromSecretSlice);

        require(htlc.hashlock == hashlockFromSecret,"Hashlock Not Match");

        let contractValue: Int = htlc.amount;
        let recieverAddr: Address = htlc.srcReceiver;

        send(SendParameters{
                            to: recieverAddr,
                            bounce: false,
                            value: contractValue,
                            mode: 0
                            }); 

        send(SendParameters{
                to: sender(),
                bounce: false,
                value: 0,
                mode: 64
                });

        self.contracts.del(msg.Id);
    }

    receive(msg: Unlock){
        let htlc: HTLC = self.contracts.get(msg.Id)!!;
        require(self.contractExists(msg.Id) == true,"Lock Does Not Exist");
        require(htlc.unlocked == false,"Already Unlocked");
        require(htlc.redeemed == false,"Already Redeemed");
        require(htlc.timelock < now(), "Not Passed Timelock");

        // user will get exact amount he locked
        send(SendParameters{
                    to: htlc.sender,
                    bounce: false,
                    value: htlc.amount,
                    mode: 0
                });

        // tx sender will get remainig amount after msg processing
        send(SendParameters{
                    to: sender(),
                    bounce: false,
                    value: 0,
                    mode: 64
                });
        self.contracts.del(msg.Id);
    }

    get fun getDetails(Id: Int): HTLC? {
        return self.contracts.get(Id);
    }

    get fun getContractsLength(): Int {
        let length: Int = 0;
        foreach(key,value in self.contracts){
            length+=1;
        }
        return length;
    }

    get fun getSrcIdToIdLength(): Int{
        let length: Int = 0;
        foreach(key,value in self.srcIdToId){
            length+=1;
        }
        return length;
    }

    get fun getContracts(senderAddr: Address): map<Int,Int>{
        let result: map<Int,Int> = emptyMap();
        let i: Int = 0;
        foreach(key,value in self.contracts){
            if(value.sender == senderAddr){
                result.set(i,key);
                i+=1;
            }
        }
        return result;
    }

    get fun getIdBySrcId(srcId: Int): Int?{
        foreach(key,value in self.srcIdToId){
            if(key == srcId){
                return value;
            }
        }
        return null;
    }

    fun lockCommitment(msg: LockCommitment,ctx: Context){
        require(self.contractExists(msg.Id) == true,"Commit Does Not Exist");
        let htlc: HTLC = (self.contracts.get(msg.Id)!!);

        if(ctx.sender == htlc.sender || ctx.sender == htlc.messenger){
                    require(self.contractExists(msg.Id) == true ,"Lock Already Exists");
                    require(self.contractExists(msg.hashlock) == false ,"Lock With Hashlock Exists");
                    require(htlc.unlocked == false,"Already Unlocked");
                    require(msg.timelock > now(),"Not Future Timelock");
                    require(htlc.hashlock == 0,"Hashlock Already Set");
    
                    self.contracts.set(msg.Id,HTLC{       
                                                dstAddress: htlc.dstAddress,
                                                dstChain: htlc.dstChain,
                                                dstAsset: htlc.dstAsset,
                                                srcAsset: htlc.srcAsset,
                                                sender: htlc.sender,
                                                senderPubKey: htlc.senderPubKey,
                                                srcReceiver: htlc.srcReceiver,
                                                secret: 0,
                                                hashlock: msg.hashlock,
                                                amount: htlc.amount,
                                                timelock: msg.timelock,
                                                messenger: htlc.messenger,
                                                redeemed: false,
                                                unlocked: false
                                                }); 

         send(SendParameters{to: sender(),
                            bounce: false,
                            value: 0,
                            mode: 64});
        }else{
            require(false,"No Allowance");
        }
    }
}
