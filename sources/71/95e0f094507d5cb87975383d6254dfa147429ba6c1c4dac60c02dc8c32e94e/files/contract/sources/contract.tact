import "@stdlib/deploy";

message TokenClaimRequest {
    user: Address;
    seqno: Int as uint64;
}

message OwnerWithdrawalRequest {
    to: Address;
}

message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}

message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

contract TokenDistributionParent with Deployable {
    owner: Address;
    tokenAddress: Address;
    supply: Int as coins;
    claimAmount: Int as coins; 
    claimInterval: Int;
    seqno: Int as uint64;

    init(owner: Address, tokenContractAddress: Address, amount: Int, interval: Int, seqno: Int) {
        self.owner = owner;
        self.tokenAddress = tokenContractAddress;
        self.claimAmount = amount;
        self.claimInterval = interval;
        self.seqno = seqno;
        self.supply = 0;
    }

    receive(msg: TokenClaimRequest) {
        require(self.supply >= self.claimAmount, "Supply empty");
        let expectedAddress: Address = contractAddress(initOf TokenDistributionChild(myAddress(), msg.user, self.claimAmount, self.claimInterval, self.seqno));
        require(sender() == expectedAddress, "Unauthorized request");

         send(SendParameters{
            value: ton("0.1"), 
            to: self.tokenAddress, 
            mode: 0,
            body: TokenTransfer {
                queryId: 0,
                amount: self.claimAmount,
                destination: msg.user,
                response_destination: msg.user,
                custom_payload: null,
                forward_ton_amount: ton("0.01"), 
                forward_payload: emptySlice()
            }.toCell()
        });
    }


    fun deployChildContract(userAddress: Address) {
        let init: StateInit = initOf TokenDistributionChild(myAddress(), userAddress, self.claimAmount, self.claimInterval, self.seqno);
        send(SendParameters{
            to: contractAddress(init),
            value: ton("0.1"),
            mode: SendIgnoreErrors,
            code: init.code,
            data: init.data
        });
    }

    receive("deploy") {
        self.deployChildContract(sender());
    }

    receive(msg: OwnerWithdrawalRequest) {
        require(sender() == self.owner, "Access denied");
        if(self.supply > 0 )
        {
            send(SendParameters{
            value: ton("0.1"), 
            to: self.tokenAddress, 
            mode: 0,
            body: TokenTransfer {
                queryId: 0,
                amount: self.supply,
                destination: msg.to,
                response_destination: msg.to,
                custom_payload: null,
                forward_ton_amount: ton("0.01"),
                forward_payload: emptySlice()
            }.toCell()
            });
        }

        send(SendParameters{
            to: msg.to,
            value: 0,
            mode: 128
        });
    }

    receive(msg: TokenNotification) {
        require(sender() == self.tokenAddress, "Access denied");
        self.supply = self.supply + msg.amount;
    }


    get fun claimInterval(): Int {
        return self.claimInterval;
    }

    get fun claimAmount(): Int {
        return self.claimAmount;
    }

    get fun supply(): Int {
        return self.supply;
    }

    get fun owner(): Address {
        return self.owner;
    }

    get fun childAddress(user: Address): Address {
        return contractAddress(initOf TokenDistributionChild(myAddress(), user, self.claimAmount, self.claimInterval, self.seqno));
    }
}

contract TokenDistributionChild {
    owner: Address;
    parentContract: Address;
    claimAmount: Int as coins;
    claimInterval: Int;
    lastClaimTime: Int;
    seqno: Int as uint64;

    init(parentAddress: Address, owner: Address, amount: Int, interval: Int, seqno: Int) {
        self.parentContract = parentAddress;
        self.owner = owner;
        self.claimAmount = amount;
        self.claimInterval = interval;
        self.lastClaimTime = 0;
        self.seqno = seqno;
    }

    receive("claim") {
        require(sender() == self.owner, "Access denied");
        let currentTime: Int = now();
        require(currentTime - self.lastClaimTime >= self.claimInterval, "Claim interval not met");

        send(SendParameters{
            to: self.parentContract,
            body: TokenClaimRequest{user: self.owner, seqno: self.seqno}.toCell(),
            value: 0,
            mode: SendRemainingValue
        });

        self.lastClaimTime = currentTime;
    }

    get fun lastClaim(): Int {
        return self.lastClaimTime;
    }

    get fun owner(): Address {
        return self.owner;
    }
}
