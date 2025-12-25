import "./jetton_wallet";
import "./jetton_vesting";
import "./jetton_airdrop";
import "./messages";
import "./constants";
import "./proofs";
import "./utils";

struct JettonMinterState {
    totalSupply: Int as coins;
    mintable: Bool;
    adminAddress: Address;
    jettonContent: Cell;
    jettonWalletCode: Cell;
}

contract JettonMinter {
    const AIRDROP_AMOUNT: Int = ton("150000");

    totalSupply: Int as coins;
    owner: Address;
    jettonContent: Cell;
    mintable: Bool;

    isAirdropInitialized: Bool = false;
    merkleRoot: Int as uint256 = 0;

    init(totalSupply: Int, owner: Address, jettonContent: Cell, mintable: Bool) {
        self.totalSupply = totalSupply;
        self.owner = owner;
        self.jettonContent = jettonContent;
        self.mintable = mintable;
    }

    receive(){}

    // ------------ Standart functions ------------ //

    receive(msg: JettonBurnNotification) {
        let sender = parseStdAddress(sender().asSlice());
        let wallet = getJettonBasechainWalletByOwner(msg.sender);

        // Workchain 0 is basechain
        require(sender.workchain == Basechain && sender.address == wallet.hash!!, "Unauthorized burn");

        self.totalSupply -= msg.amount;

        if (msg.responseDestination != null) {
            message(MessageParameters {
                to: msg.responseDestination!!,
                body: JettonExcesses { queryId: msg.queryId }.toCell(),
                value: 0,
                bounce: false,
                mode: SendRemainingValue | SendIgnoreErrors, // ignore errors, because supply has already been updated
            });
        }
    }

    receive(msg: JettonUpdateContent) {
        require(sender() == self.owner, "Incorrect sender");
        self.jettonContent = msg.content;
    }

    receive(msg: ChangeOwner) {
        require(sender() == self.owner, "Incorrect sender");
        self.owner = msg.newOwner;
    }

    receive(msg: CloseMinting) {
        require(sender() == self.owner, "Incorrect sender");
        self.mintable = false;
        cashback(sender());
    }

    receive(msg: ClaimTON) {
        require(sender() == self.owner, "Incorrect sender");
        nativeReserve(minTonsForStorage, ReserveExact | ReserveBounceIfActionFail);

        message(MessageParameters {
            bounce: true,
            to: msg.receiver,
            value: 0,
            mode: SendRemainingBalance,
        });
    }

     receive(msg: ClaimTONAirdrop) {
        require(sender() == self.owner, "Incorrect sender");
        self.reserveStorage();

        message(MessageParameters {
            to: self.airdropAddress(),
            bounce: false,
            value: 0,
            mode: SendRemainingBalance,
            body: ClaimTON { receiver: msg.receiver }.toCell()
        });
    }

    receive(msg: ProvideWalletAddress) {
        let ownerWorkchain: Int = parseStdAddress(msg.ownerAddress.asSlice()).workchain;

        let targetJettonWallet: BasechainAddress = (ownerWorkchain == Basechain)
            ? contractBasechainAddress(getJettonWalletInit(msg.ownerAddress))
            : emptyBasechainAddress();

        message(MessageParameters {
            body: makeTakeWalletAddressMsg(targetJettonWallet, msg),
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
        });
    }

    // ------------ Mint functions ------------ //

    receive(msg: VestingDistribution) {
        require(sender() == self.owner, "Incorrect sender");
        require(self.mintable, "Mint is closed");

        checkEitherForwardPayload(msg.transferMessage.forwardPayload);
        let ctx = context();

        require(
            ctx.value >
            minTonsForStorage +
            msg.transferMessage.forwardTonAmount +
            ctx.readForwardFee() +
            getForwardFee(walletStateInitCells, walletStateInitBits, false) +
            2 * getComputeFee(gasForTransfer, false),
            "Insufficient gas for mint",
        );

        self.reserveStorage();
        self.totalSupply += msg.transferMessage.amount;

        let vestingInit = self.jettonVestingInit(msg.vestingId);
        let walletInit = getJettonWalletInit(contractAddress(vestingInit));

        self.setupVestingContract(msg.setupVestingMessage, vestingInit);
        self.setupVestingWallet(msg.transferMessage, walletInit);
    }

    receive(msg: AirdropDistribution) {
        require(sender() == self.owner, "Incorrect sender");
        require(self.mintable, "Mint is closed");
        require(!self.isAirdropInitialized, "Airdrop already initialized");

        checkEitherForwardPayload(msg.transferMessage.forwardPayload);
        let ctx = context();

        require(
            ctx.value >
            minTonsForStorage +
            msg.transferMessage.forwardTonAmount +
            ctx.readForwardFee() +
            getForwardFee(walletStateInitCells, walletStateInitBits, false) +
            2 * getComputeFee(gasForTransfer, false),
            "Insufficient gas for mint",
        );

        self.reserveStorage();
        self.totalSupply += self.AIRDROP_AMOUNT;
        msg.transferMessage.amount = self.AIRDROP_AMOUNT;
        self.isAirdropInitialized = true;

        let airdropInit = getJettonAirdropInit();
        let walletInit = getJettonWalletInit(contractAddress(airdropInit));

        self.deployAirdropContract(airdropInit);
        self.setupAirdropWallet(msg.transferMessage, walletInit);
    }

    // ------------ Unlock functions ------------ //

    receive(msg: SetupUnlockRoot) {
        require(sender() == self.owner, "Incorrect sender");
        self.reserveStorage();
        self.merkleRoot = msg.unlockRoot;

        message(MessageParameters {
            to: sender(),
            value: 0,
            mode: SendRemainingBalance | SendIgnoreErrors,
            bounce: false,
            body: JettonExcesses { queryId: 0 }.toCell(),
        });
    }

    receive(msg: UpdateUnlock) {
        require(self.merkleRoot != 0, "Unlock not configured");

        let owner: Address = sender();
        let unlock: ProofParam = getProofParams(msg.unlockProof, self.merkleRoot, owner.asSlice());

        require(unlock.startFrom <= now(), "Unlock proof not started");
        require(unlock.expiredAt >= now(), "Unlock proof expired");
        
        self.reserveStorage();

        deploy(DeployParameters {
            init: getJettonWalletInit(owner),
            value: 0,
            mode: SendRemainingBalance | SendIgnoreErrors,
            body: UpdateUnlockByActivity {
                unlockValue: unlock.amount
            }.toCell()
        });
    }

    //------------ Airdrop functions ------------//

    receive(msg: SetupAirdrop) {
        require(sender() == self.owner, "Incorrect sender");
        self.reserveStorage();

        message(MessageParameters {
            to: self.airdropAddress(),
            value: 0,
            mode: SendRemainingBalance | SendIgnoreErrors,
            body: msg.toCell()
        });
    }

    receive(msg: StopAirdrop) {
        require(sender() == self.owner, "Incorrect sender");
        self.reserveStorage();

        message(MessageParameters {
            to: self.airdropAddress(),
            value: 0,
            mode: SendRemainingBalance | SendIgnoreErrors,
            body: msg.toCell()
        });
    }

    receive(msg: AirdropBurn) {
        require(sender() == self.owner, "Incorrect sender");
        self.reserveStorage();

        message(MessageParameters {
            to: self.airdropAddress(),
            value: 0,
            mode: SendRemainingBalance | SendIgnoreErrors,
            body: JettonBurn {
                queryId: msg.queryId,
                amount: msg.amount,
                responseDestination: msg.responseDestination,
                customPayload: msg.customPayload
            }.toCell()
        });
    }

    // ------------ Private functions ------------ //

    fun reserveStorage() {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;
        let tonBalanceBeforeMsg = myBalance() - msgValue;
        nativeReserve(max(tonBalanceBeforeMsg, minTonsForStorageLarge), ReserveAtMost);
    }

    fun setupVestingContract(message: SetupVesting, vestingInit: StateInit) {
        deploy(DeployParameters {
            value: ton("0.15"),
            mode: SendIgnoreErrors,
            bounce: false,
            body: message.toCell(),
            init: vestingInit
        });
    }

    fun setupVestingWallet(message: JettonTransferInternal, walletInit: StateInit) {
        deploy(DeployParameters {
            value: 0,
            mode: SendRemainingBalance | SendIgnoreErrors,
            bounce: false,
            body: message.toCell(),
            init: walletInit
        });
    }

    fun deployAirdropContract(airdropInit: StateInit) {
        deploy(DeployParameters {
            value: ton("0.15"),
            mode: SendIgnoreErrors,
            bounce: false,
            body: SetupAirdrop {
                hashRoot: 0
            }.toCell(),
            init: airdropInit
        });
    }

    fun setupAirdropWallet(message: JettonTransferInternal, walletInit: StateInit) {
        deploy(DeployParameters {
            value: 0,
            mode: SendRemainingBalance | SendIgnoreErrors,
            bounce: false,
            body: message.toCell(),
            init: walletInit
        });
    }

    // ----------- Bounced handlers ------------ //

    bounced(msg: bounced<JettonTransferInternal>) {
        self.totalSupply -= msg.amount;
    }

    // ------------ Getters ------------ //

    get fun get_jetton_data(): JettonMinterState {
        return JettonMinterState {
            totalSupply: self.totalSupply,
            mintable: self.mintable,
            adminAddress: self.owner,
            jettonContent: self.jettonContent,
            jettonWalletCode: codeOf JettonWallet,
        };
    }

    get fun get_wallet_address(ownerAddress: Address): Address {
        return getJettonWalletByOwner(ownerAddress);
    }

    get fun vestingAddress(id: Int): Address {
        return contractAddress(self.jettonVestingInit(id));
    }

    get fun jettonVestingInit(id: Int): StateInit {
        return initOf JettonVesting(id, myAddress());
    }

    get fun unlockMerkleRoot(): Int {
        return self.merkleRoot;
    }

    get fun airdropInitialized(): Bool {
        return self.isAirdropInitialized;
    }

    get fun airdropAddress(): Address {
        return contractAddress(getJettonAirdropInit());
    }
}

inline fun getJettonWalletInit(address: Address): StateInit {
    return initOf JettonWallet(address, myAddress(), 0);
}

inline fun getJettonAirdropInit(): StateInit {
    return initOf JettonAirdrop(myAddress());
}

inline fun getJettonWalletByOwner(jettonWalletOwner: Address): Address {
    return contractAddress(getJettonWalletInit(jettonWalletOwner));
}

inline fun getJettonBasechainWalletByOwner(jettonWalletOwner: Address): BasechainAddress {
    return contractBasechainAddress(getJettonWalletInit(jettonWalletOwner));
}
