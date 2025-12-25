import "./messages";
import "./constants";
import "./jetton_minter";


struct JettonVestingInfo {
    name: String;
    owner: Address;

    amount: Int as coins;
    balance: Int as coins;
    vestedAmount: Int as coins;
    claimedAmount: Int as coins;
    unclaimedAmount: Int as coins;

    startVesting: Int as uint32;
    endVesting: Int as uint32;
}


contract JettonVesting {
    const deployTime: Int = 1764565200;

    id: Int;
    minter: Address;
    wallet: Address;

    owner: Address;
    name: String = "";
    balance: Int as coins = 0;
    amount: Int as coins = 0;

    cliffDuration: Int as uint32 = 0;
    vestingDuration: Int as uint32 = 0;

    init(id: Int, minter: Address) {
        self.id = id;
        self.minter = minter;
        self.owner = minter;
        self.wallet = contractAddress(initOf JettonWallet(myAddress(), self.minter, 0));
    }

    receive(){}

    receive(msg: SetupVesting) {
        require(self.minter == sender(), "Incorrect sender");
        require(self.amount == 0, "Vesting contract already setup");

        self.name = msg.name;
        self.owner = msg.owner;
        self.amount = msg.amount;
        self.balance = msg.amount;
        self.cliffDuration = msg.cliffDuration * mounthUnix;
        self.vestingDuration = msg.vestingDuration * mounthUnix;

        self.reserveStorage();

        message(MessageParameters {
            to: msg.owner,
            value: 0,
            mode: SendRemainingBalance | SendIgnoreErrors,
            bounce: false,
            body: JettonExcesses { queryId: 0 }.toCell(),
        });
    }
  
    receive(msg: ClaimToken) {
        require(self.owner == sender(), "Incorrect sender");

        let startVesting: Int = self.deployTime + self.cliffDuration;
        require(now() > startVesting, "Cliff period active");

        let endVesting: Int = startVesting + self.vestingDuration;
        let durationVesting: Int = max(1, endVesting - startVesting);
        let vestingAmount: Int = (self.amount * (now() - startVesting)) / durationVesting;
        let transferAmount: Int = min(vestingAmount, self.amount) - (self.amount - self.balance);

        require(transferAmount > 0, "Not avalible tokens for transfer");

        if (msg.amount != null) {
            require(msg.amount!! <= transferAmount, "Requested amount exceeds available");
            transferAmount = msg.amount!!;
        }

        self.reserveStorage();
        self.balance -= transferAmount;

        message(MessageParameters {
            to: self.wallet,
            value: 0,
            mode: SendRemainingBalance | SendIgnoreErrors,
            bounce: true,
            body: JettonTransfer {
                queryId: msg.queryId,
                amount: transferAmount,
                destination: msg.destination,
                responseDestination: msg.responseDestination,
                forwardTonAmount: msg.forwardTonAmount,
                forwardPayload: msg.forwardPayload
            }.toCell()
        });
    }

    receive(msg: ChangeOwner) {
        require(self.owner == sender(), "Incorrect sender");
        self.reserveStorage();
        self.owner = msg.newOwner;

        message(MessageParameters {
            to: msg.newOwner,
            value: 0,
            mode: SendRemainingBalance | SendIgnoreErrors,
            bounce: false,
            body: JettonExcesses { queryId: msg.queryId }.toCell(),
        });
    }

    receive(msg: ClaimTON) {
        require(sender() == self.owner, "Incorrect sender");
        nativeReserve(minTonsForStorageLarge, ReserveExact | ReserveBounceIfActionFail);

        message(MessageParameters {
            bounce: true,
            to: msg.receiver,
            value: 0,
            mode: SendRemainingBalance,
        });
    }

    // ------------ Private functions ---------- //

    fun reserveStorage() {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;
        let tonBalanceBeforeMsg = myBalance() - msgValue;
        nativeReserve(max(tonBalanceBeforeMsg, minTonsForStorageLarge), ReserveAtMost);
    }

    // ------------ Bounce handlers ------------ //

    bounced(msg: bounced<JettonTransfer>) {
        self.balance += msg.amount;
    }

    // ------------ Getters ------------ //

    get fun vestingInfo(): JettonVestingInfo {
        let startVesting: Int = self.deployTime + self.cliffDuration;
        let endVesting: Int = startVesting + self.vestingDuration;

        let durationVesting: Int = max(1, endVesting - startVesting);
        let vestingAmount: Int = now() > startVesting 
                                ? min(self.amount, (self.amount * (now() - startVesting)) / durationVesting): 0;
        let claimedAmount: Int = self.amount - self.balance;
        let unclaimedAmount: Int = vestingAmount - claimedAmount;

        return JettonVestingInfo {
            name: self.name,
            owner: self.owner,
            amount: self.amount,
            balance: self.balance,
            vestedAmount: vestingAmount,
            claimedAmount: claimedAmount,
            unclaimedAmount: unclaimedAmount,
            startVesting: startVesting,
            endVesting: endVesting
        }
    }
}
