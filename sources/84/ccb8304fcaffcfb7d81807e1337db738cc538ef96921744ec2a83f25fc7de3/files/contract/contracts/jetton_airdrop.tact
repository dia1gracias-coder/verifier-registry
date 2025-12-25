import "./jetton_wallet";
import "./messages";
import "./constants";
import "./utils";
import "./proofs";

struct JettonAirdropInfo {
    merkleRoot: Int as uint256;
    isStopped: Bool;
    isStoppable: Bool;
}

contract JettonAirdrop {
    const stoppableAfter: Int = 1774976400; // Mar 31 2026

    minter: Address;
    wallet: Address;

    merkleRoot: Int as uint256 = 0;
    isStopped: Bool = false;

    init(minter: Address) {
        self.minter = minter;
        self.wallet = contractAddress(initOf JettonWallet(myAddress(), self.minter, 0));
    }

    receive(){}

    receive(msg: SetupAirdrop) {
        require(sender() == self.minter, "Incorrect sender");
        require(self.merkleRoot == 0, "Airdrop already setup");

        self.merkleRoot = msg.hashRoot;
        self.reserveStorage();

        message(MessageParameters {
            to: self.minter,
            value: 0,
            mode: SendRemainingBalance | SendIgnoreErrors,
            bounce: false
        });
    }

    receive(msg: StopAirdrop) {
        require(sender() == self.minter, "Incorrect sender");
        require(self.stoppableAfter <= now(), "Cannot stop airdrop yet");

        self.isStopped = true;
        self.reserveStorage();

        message(MessageParameters {
            to: self.minter,
            value: 0,
            mode: SendRemainingBalance | SendIgnoreErrors,
            bounce: false
        });
    }

    receive(msg: ClaimAirdrop) {
        require(!self.isStopped, "Airdrop is stopped");
        require(self.merkleRoot != 0, "Airdrop not configured");

        let wallet: StateInit = initOf JettonWallet(msg.destination, self.minter, 0);
        require(wallet.hasSameBasechainAddress(sender()), "Incorrect sender");

        let airdrop: ProofParam = getProofParams(msg.airdropProof, self.merkleRoot, msg.destination.asSlice());
        require(airdrop.startFrom <= now(), "Airdrop proof not started");
        require(airdrop.expiredAt >= now(), "Airdrop proof expired");

        self.reserveStorage();

        message(MessageParameters {
            to: self.wallet,
            value: 0,
            mode: SendRemainingBalance | SendIgnoreErrors,
            bounce: true,
            body: JettonTransfer {
                queryId: msg.queryId,
                amount: airdrop.amount,
                destination: msg.destination,
                responseDestination: msg.responseDestination,
                forwardTonAmount: 0,
                forwardPayload: beginCell().storeUint(0, 1).asSlice(),
            }.toCell()
        });
    }

    receive(msg: ClaimTON) {
        require(sender() == self.minter, "Incorrect sender");
        nativeReserve(minTonsForStorageLarge, ReserveExact | ReserveBounceIfActionFail);

        message(MessageParameters {
            bounce: true,
            to: msg.receiver,
            value: 0,
            mode: SendRemainingBalance,
        });
    }

    receive(msg: JettonBurn) {
        require(sender() == self.minter, "Incorrect sender");
        require(self.isStopped, "Airdrop not stopped");

        message(MessageParameters {
            to: self.wallet,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: msg.toCell(),
        });
    }

    // ------------ Private functions ---------- //

    fun reserveStorage() {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;
        let tonBalanceBeforeMsg = myBalance() - msgValue;
        nativeReserve(max(tonBalanceBeforeMsg, minTonsForStorageLarge), ReserveAtMost);
    }

    // ------------ Getters ------------ //

    get fun walletAddress(): Address {
        return self.wallet;
    }

    get fun airdropInfo(): JettonAirdropInfo {
        return JettonAirdropInfo{
            merkleRoot: self.merkleRoot,
            isStopped: self.isStopped,
            isStoppable: self.stoppableAfter > now() ? false : true
        };
    }
}
