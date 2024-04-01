import "@stdlib/deploy";
import "@stdlib/ownable";

message(0x00000001) MintChild {
    user: Address;
    referrer: Address?;
}

message(0x0000002) Claim {
    amount: Int as coins;
    boost: Int as coins;
    user: Address;
    referrer: Address?;
}

message(0x0000003) ReferralCount {
}

message(0x0000004) Referrer {
    user: Address?;
}

message(0x0000005) Boost {
    amount: Int as uint32;
}

message(0x00000006) OwnerWithdrawalRequest {
    amount: Int as coins;
    tokenAddress: Address;
}

message(0x00000007) OwnerWithdrawalTonRequest {  
}

message(0x00000008) TokenConfig {
    tokenAddress: Address;
    claimAmount: Int as coins;
    referralReward: Int as coins;
    boostReward: Int as coins;
}

message(0x0000009) CustomMessage {
    to: Address;
    payload: Cell?;
}


message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}

message(0xd53276db) TokenExcesses {
    queryId: Int as uint64;
}

message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64; // should be 0
     amount: Int as coins; // should be amount of jettons to send
     destination: Address; // should be user address 
     responseDestination: Address?; // should be myAddress()
     customPayload: Cell?; // should be null
     forwardTonAmount: Int as coins; // should be ton("0.01")
     forwardPayload: Slice?; // should be emptySlice()
}


struct ChildState {
    interval: Int as uint32 = 0;
    lastClaimTime: Int as uint64 = 0;
    referralsCount: Int as uint32 = 0;
    boost: Int as uint32 = 0;
}


contract ClaimMaster with Ownable, Deployable {
    queryId: Int as uint64;
    tokenAddress: Address?;
    randomSecure: Int as uint64;
    interval: Int as uint32;
    owner: Address;
    master: Address;
    claimAmount: Int = 3_000_000_00;
    referralReward: Int = 15_000_000_0;
    boostReward: Int = 5_000_000;

    init(owner: Address, master: Address, interval: Int, randomSecure: Int) 
    {
        self.owner = owner;
        self.queryId = 0;
        self.tokenAddress = null;
        self.randomSecure = randomSecure;
        self.interval = interval;
        self.master = master;
    }

    receive(msg: ChangeOwner){
        nativeThrowUnless(101, sender() == self.master);

        self.owner = msg.newOwner;
    }

    receive(msg: CustomMessage){
        nativeThrowUnless(101, sender() == self.master);
        send(SendParameters
        {
            to: msg.to,
            value: 0,
            mode: SendRemainingValue,
            body: msg.payload
        });
    }

    receive(msg: TokenNotification)
    {
        let userContract: Address = self.get_user_address(msg.from);

        send(SendParameters
        {
            to: userContract,
            value: 0,
            mode: SendRemainingValue,
            body: Boost {amount: msg.amount / 100_000_000_0}.toCell()
        });
    }

    receive(msg: MintChild)
    {
        nativeThrowUnless(101, sender() == self.owner);
        let init: StateInit = initOf ClaimChild(myAddress(), msg.user, self.owner, self.interval);
        send(SendParameters
        {
            to: contractAddress(init),
            value: 0,
            mode: SendRemainingValue,
            code: init.code,
            data: init.data,
            body: Referrer {user: msg.referrer}.toCell()
        });
    }

    receive(msg: Claim)
    {
        let expected: Address = self.get_user_address(msg.user);

        nativeThrowUnless(101, sender() == expected);

        send(SendParameters{
            value: ton("0.05"), 
            to: self.tokenAddress!!, 
            mode: 0,
            body: TokenTransfer {
                queryId: 0,
                amount: self.claimAmount + msg.amount * self.referralReward + msg.boost * self.boostReward,
                destination: msg.user,
                responseDestination: myAddress(),
                customPayload: null,
                forwardTonAmount: 1,
                forwardPayload: null
            }.toCell()
        });

        if(msg.referrer != null)
        {
            let refAddress: Address = self.get_user_address(msg.referrer!!);
            send(SendParameters{
                value: 0,
                to: refAddress, 
                mode: SendRemainingValue,
                body: beginCell().storeUint(0x0000003, 32).endCell()
            });
        }
    }

    receive(msg: TokenConfig)
    {
        let ctx: Context = context();
        nativeThrowUnless(101, ctx.sender == self.owner || ctx.sender == self.master);
        self.tokenAddress = msg.tokenAddress;
        self.claimAmount = msg.claimAmount;
        self.referralReward = msg.referralReward;
        self.boostReward = msg.boostReward;
    }

    receive() 
    {
    }

    receive(msg: TokenExcesses)
    {
    }

    receive(msg: OwnerWithdrawalTonRequest)
    {
        nativeThrowUnless(1001, sender() == self.master);
        send(SendParameters{
                to: self.master,
                value: 0,
                mode: SendRemainingBalance
            });
    }

    receive(msg: OwnerWithdrawalRequest)
    {
        nativeThrowUnless(1001, sender() == self.master);

        if(msg.tokenAddress != null)
        {
            send(SendParameters{
                value: ton("0.065"), 
                to: msg.tokenAddress, 
                mode: 0,
                body: TokenTransfer {
                    queryId: self.queryId,
                    amount: msg.amount,
                    destination: self.master,
                    responseDestination: self.master,
                    customPayload: null,
                    forwardTonAmount: 1,
                    forwardPayload: null
                }.toCell()
            });

            self.queryId = self.queryId + 1;
        }

            send(SendParameters{
                to: self.master,
                value: 0,
                mode: SendRemainingBalance
            });
    }

    get fun interval(): Int {
        return self.interval;
    }

    get fun tokenAddress(): Address? {
        return self.tokenAddress;
    }

    get fun queryId(): Int {
        return self.queryId;
    }

    get fun get_user_address(user: Address): Address {
        return contractAddress(initOf ClaimChild(myAddress(), user, self.owner, self.interval));
    }

    get fun claimAmount(): Int {
        return self.claimAmount;
    }
    get fun referralReward(): Int {
        return self.referralReward;
    }
    get fun boostReward(): Int {
        return self.boostReward;
    }
}

contract ClaimChild with Ownable {
    owner: Address;
    parent: Address;
    master: Address;
    interval: Int as uint32;
    lastClaimTime: Int as uint64 = 0;
    referralsCount: Int as uint32 = 0;
    referrer: Address? = null;
    boost: Int as uint32 = 0;

    init(parent: Address, user: Address, master: Address, interval: Int) {
        self.parent = parent;
        self.owner = user;
        self.master = master;
        self.interval = interval;
    }

    receive(msg: Referrer)
    {
        nativeThrowUnless(666, sender() == self.parent);
        self.referrer = msg.user;
        self.lastClaimTime = now();

        send(SendParameters
            {
                to: self.parent,
                body: Claim {
                    user: self.owner, 
                    referrer: msg.user,
                    boost: 0,
                    amount: 0
                    }.toCell(),
                value: ton("0.1"),
                mode: SendIgnoreErrors
            });
    }

    receive(msg: ReferralCount)
    {
        let ctx: Context = context();
        nativeThrowUnless(666, ctx.sender == self.parent);
        
        self.referralsCount = self.referralsCount + 1;

        send(SendParameters{
                to: ctx.sender,
                value: 0,
                mode: SendRemainingValue
            });
    }

    receive(msg: Boost)
    {
        let ctx: Context = context();
        nativeThrowUnless(666, ctx.sender == self.master || ctx.sender == self.parent);

        self.boost = self.boost + msg.amount;

        send(SendParameters{
                to: ctx.sender,
                value: 0,
                mode: SendRemainingValue
            });
    }

    receive() {
        let ctx: Context = context();
        nativeThrowUnless(1001, ctx.value >= ton("0.1"));

        let currentTime: Int = now();
        if(currentTime - self.lastClaimTime >= self.interval)
        {
            self.lastClaimTime = currentTime;

            let amount: Int = self.referralsCount;
            self.referralsCount = 0;

            send(SendParameters
            {
                to: self.parent,
                body: Claim {
                    user: self.owner, 
                    referrer: self.referrer,
                    amount: amount,
                    boost: self.boost
                    }.toCell(),
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors
            });
        }
        else
        {
            send(SendParameters{
                to: ctx.sender,
                value: 0,
                mode: SendRemainingValue,
                body: "🦘".asComment()
            });
        }
    }

    get fun lastClaimTime(): Int {
        return self.lastClaimTime;
    }

    get fun parent(): Address {
        return self.parent;
    }

    get fun master(): Address {
        return self.master;
    }

    get fun referrer(): Address? {
        return self.referrer;
    }

    get fun interval(): Int {
        return self.interval;
    }

    get fun referralsCount(): Int {
        return self.referralsCount;
    }

    get fun get_state(): ChildState {
        return ChildState {    
            interval: self.interval, 
            lastClaimTime: self.lastClaimTime,
            referralsCount: self.referralsCount,    
            boost: self.boost
        };
    }
}
