import "@stdlib/deploy";
import "@stdlib/ownable";

import "./staking_messages";
import "./staking_child";

contract StakingMaster with Deployable, Ownable {
    owner: Address;
    apr: Int as uint16;

    jettonWallet: Address?;

    init(_owner: Address, _apr: Int) {
        require(_apr <= 100_00, "wrong apr value");
        self.owner = _owner;
        self.apr = _apr;
    }

    receive(msg: SetAPR) {
        self.requireOwner();
        require(msg.apr <= 100_00, "wrong apr value");
        self.apr = msg.apr;
    }

    receive(msg: SetJettonWallet) {
        self.requireOwner();
        require(self.jettonWallet == null, "already setted");
        self.jettonWallet = msg.wallet;
    }

    receive(msg: TokenNotification) {
        require(self.jettonWallet!! == context().sender, "not from jetton wallet");
        if(msg.from != self.owner) {
            let init: StateInit = self.getStakingChildInit(msg.from);
            send(SendParameters{
                to: contractAddress(init),
                value: 0,
                mode: SendRemainingValue, 
                // bounce: true,
                body: Deposit{
                    amount: msg.amount,
                    apr: self.apr
                }.toCell(),
                code: init.code,
                data: init.data
            });
        }
    }

    receive(msg: SendCoins) {
        let sender: Address = context().sender;
        require(self.getStakingChildAddress(msg.to) == sender, "wrong child");
        // do not check self.jettonWallet!! cause it is not possible to get such message before this filed is filled

        let msgValue: Int = context().value;

        if(msg.update) {
            require(msgValue > ton("0.1"), "low value");
            msgValue = msgValue - ton("0.06");
            send(SendParameters{
                to: sender,
                value: ton("0.05"), // TODO: change!!!
                // mode: SendRemainingValue, // TODO: change!!!
                // bounce: true,
                body: SetAPR{
                    apr: self.apr
                }.toCell()
            });
        }

        send(SendParameters{
            to: self.jettonWallet!!,
            value: msgValue,
            // mode: SendRemainingValue,
            // bounce: true,
            body: TokenTransfer{
                queryId: 0,
                amount: msg.amount,
                destination: msg.to,
                responseDestination: msg.to, // address to return remaining ton value
                customPayload: null,
                forwardTonAmount: 0,
                forwardPayload: emptySlice()
            }.toCell()
        });
    }

    get fun getAPR(): Int {
        return self.apr;
    }

    get fun getJettonWalletAddress(): Address? {
        return self.jettonWallet;
    }

    get fun getStakingChildAddress(owner: Address): Address {
        let winit: StateInit = self.getStakingChildInit(owner);
        return contractAddress(winit);
    }
    
    fun getStakingChildInit(owner: Address): StateInit {
        return initOf StakingChild(owner, myAddress());
    }
}
