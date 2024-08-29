import "@stdlib/deploy";
import "@stdlib/ownable";
// Find out how to import wallet correctly
import "./jetton";

import "./messages";

struct ClaimData {
    asset: Address;
    amount: Int as coins;
    claimableAfter: Int as uint32;
}

contract BridgeDepositor with Deployable {
    // asset -> amount
    totalDeposited: map<Address, Int as coins>;
    // jettonWallet -> jettonMaster
    allowedAssets: map<Address, Address>;
    owner: Address;

    init(owner: Address) {
        self.owner = owner;
    }

    get fun get_user_data_address(user: Address): Address {
        return contractAddress(initOf UserData(myAddress(), user));
    }

    fun onlyChild(user: Address) {
        let expectedChild: Address = contractAddress(initOf UserData(myAddress(), user));
        require(sender() == expectedChild, "Access denied");
    }

    receive(msg: ToggleAsset) {
        require(self.owner == sender(), "Only owner");
        if (self.allowedAssets.get(msg.wallet) == null) {
            self.allowedAssets.set(msg.wallet, msg.asset);
        } else {
            self.allowedAssets.set(msg.wallet, null);
        }
    }

    // Handles deposit event from JettoWallet instance
    receive(msg: TokenNotification) {
        let asset: Address? = self.allowedAssets.get(sender());
        require(asset != null, "Asset is not allowed");

        // self address
        let init: StateInit = initOf UserData(myAddress(), msg.from);
        send(SendParameters{  
            to: contractAddress(init),
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: Deposit{
                queryId: msg.queryId,
                amount: msg.amount,
                asset: asset!!
            }.toCell(),
            code: init.code,
            data: init.data
        });
        emit(DepositEvent {queryId: msg.queryId, amount: msg.amount, user: msg.from, asset: asset!!}.toCell());
    }

    // Handles withdraw notification from UserData instance. Used to emit event.
    receive(msg: WithdrawNotification) {
        self.onlyChild(msg.user);
        emit(WithdrawEvent {queryId: msg.queryId, amount: msg.amount, user: msg.user, asset: msg.asset, claimId: msg.claimId}.toCell());
    }

    // Handles claim notification from child
    receive(msg: ClaimNotification) {
        self.onlyChild(msg.user);

        let init: StateInit = initOf JettonDefaultWallet(msg.asset, myAddress());  
        let walletAddress: Address = contractAddress(init);
        send(SendParameters{
                to: walletAddress, 
                value: 0,
                mode: SendRemainingValue, 
                bounce: false,
                body: TokenTransfer{
                    queryId: msg.queryId,
                    amount: msg.amount,
                    destination: msg.user,
                    response_destination: msg.response_destination,
                    forward_ton_amount: msg.forward_ton_amount,
                    forward_payload: msg.forward_payload
                }.toCell()
        });
        emit(ClaimEvent {queryId: msg.queryId, claimId: msg.claimId, isCancelled: false}.toCell());
    }

    // Handles cancellation of withdraw notification
    receive(msg: CancelClaimNotification) {
        self.onlyChild(msg.user);
        emit(ClaimEvent {queryId: msg.queryId, claimId: msg.claimId, isCancelled: true}.toCell());
    }
}

contract UserData {
    const minTonsForStorage: Int = ton("0.01");
    const gasConsumption: Int = ton("0.01");
    const claimPeriod: Int = 432000;

    // asset -> amount
    deposits: map<Address, Int as coins>;
    claims: map<Int as uint128, ClaimData>;
    user: Address;
    master: Address;

    init(master: Address, user: Address) {
        require(sender() == master, "Not the master");
        self.user = user;
        self.master = master;
    }

    get fun getBalance(asset: Address): Int? {
        return self.deposits.get(asset);
    }

    get fun getClaim(id: Int): ClaimData? {
        return self.claims.get(id);
    }

    receive(msg: Deposit) {
        require(sender() == self.master, "Only master");
        let balance: Int? = self.deposits.get(msg.asset);
        if (balance == null) {
            balance = 0;
        }
        self.deposits.set(msg.asset, balance!! + msg.amount);
    }

    receive(msg: Withdraw) {
        require(sender() == self.user, "Only user");
        let balance: Int? = self.deposits.get(msg.asset);
        if (balance == null) {
            balance = 0;
        }
        require(balance!! - msg.amount >= 0, "Insufficient balance");
        self.deposits.set(msg.asset, balance!! - msg.amount);
        let claimableAfter = now() + self.claimPeriod;
        self.claims.set(msg.claimId, ClaimData{asset: msg.asset, amount: msg.amount, claimableAfter: claimableAfter});
        send(SendParameters{
            to: self.master, 
            value: 0,
            mode: SendRemainingValue, 
            bounce: false,
            body: WithdrawNotification{
                    queryId: msg.queryId,
                    claimId: msg.claimId,
                    amount: msg.amount,
                    asset: msg.asset,
                    user: sender(),
                    claimableAfter: claimableAfter
            }.toCell()
        });
    }

    receive(msg: Claim) {
        require(sender() == self.user, "Only user");
        let claim: ClaimData? = self.claims.get(msg.claimId);
        require(claim != null, "Claim id does not exists");
        require(claim!!.claimableAfter <= now(), "Cannot claim yet");
        send(SendParameters{
            to: self.master, 
            value: 0,
            mode: SendRemainingValue, 
            bounce: false,
            body: ClaimNotification{
                    queryId: msg.queryId,
                    claimId: msg.claimId,
                    user: sender(),
                    asset: claim!!.asset,
                    amount: claim!!.amount,
                    response_destination: msg.response_destination,
                    forward_ton_amount: msg.forward_ton_amount,
                    forward_payload: msg.forward_payload
            }.toCell()
        });
        self.claims.set(msg.claimId, null);
    }

    receive(msg: CancelWithdraw) {
        require(sender() == self.user, "Only user");
        let claim: ClaimData? = self.claims.get(msg.claimId);
        require(claim != null, "Claim id does not exists");
        let claimData: ClaimData = claim!!;

        let balance: Int? = self.deposits.get(claimData.asset);
        if (balance == null) {
            balance = 0;
        }
        self.deposits.set(claimData.asset, balance!! + claimData.amount);
        self.claims.set(msg.claimId, null);
        send(SendParameters{
            to: self.master, 
            value: 0,
            mode: SendRemainingValue, 
            bounce: false,
            body: CancelClaimNotification{
                    queryId: msg.queryId,
                    claimId: msg.claimId,
                    user: self.user
            }.toCell()
        });
    }
}
