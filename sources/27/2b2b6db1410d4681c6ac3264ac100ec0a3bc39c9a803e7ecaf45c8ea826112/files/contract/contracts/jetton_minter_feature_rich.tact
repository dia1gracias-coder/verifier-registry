import "./jetton_wallet_feature_rich";
import "./messages";
import "./constants";
import "./utils";
import "@stdlib/ownable";


struct JettonMinterState {
    totalSupply: Int as coins;
    mintable: Bool;
    adminAddress: Address;
    jettonContent: Cell;
    jettonWalletCode: Cell;
    burnable: Bool;
}

contract JettonMinterFeatureRich(
    totalSupply: Int as coins,
    owner: Address,
    jettonContent: Cell,
    mintable: Bool, // Should be deployed with this flag set to true
    maxSupply: Int as coins,
    burnable: Bool, // Flag to control if burning is allowed
) {
    receive() {
        // Ensure only the stored owner can send TON here
        require(sender() == self.owner, "Only owner");
    }

    // Owner of this contract may be masterchain address,
    // however minting is possible only to basechain addresses
    // it is asserted inside the deploy function
    receive(msg: Mint) {
        require(sender() == self.owner, "Incorrect sender");
        require(self.mintable, "Mint is closed");
        require(self.totalSupply + msg.mintMessage.amount <= self.maxSupply, "Max supply reached");
        checkEitherForwardPayload(msg.mintMessage.forwardPayload);

        let ctx = context();
        // we don't add compute fees for mint itself and reserve here
        // it's okay since it's sent only by the admin and excesses will return back
        let fwdCount = 1 + sign(msg.mintMessage.forwardTonAmount); // fix: TRA-04 | Incorrect Gas Calculation in `Mint` receiver
        require(
            ctx.value >
            minTonsForStorage +
            msg.mintMessage.forwardTonAmount +
            fwdCount * ctx.readForwardFee() +
            getForwardFee(walletStateInitCells, walletStateInitBits, false) +
            2 * getComputeFee(gasForTransfer, false),
            "Insufficient gas for mint",
        );

        self.totalSupply += msg.mintMessage.amount;

        // basechain destination is calculated inside deploy function
        deploy(DeployParameters {
            value: 0, // ignore msg.tonAmount and use SendMode 64 instead
            bounce: true,
            mode: SendRemainingValue | SendBounceIfActionFail,
            body: msg.mintMessage.toCell(),
            init: getJettonWalletInit(msg.receiver),
        });
    }

    receive(msg: ProvideWalletAddress) {
        let ownerWorkchain: Int = parseStdAddress(msg.ownerAddress.asSlice()).workchain;

        // If owner is basechain address, we can calculate jettonWallet
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

    receive(msg: JettonBurnNotification) {
        let sender = parseStdAddress(sender().asSlice());
        let wallet = getJettonBasechainWalletByOwner(msg.sender);

        require(sender.workchain == Basechain && sender.address == wallet.hash!!, "Unauthorized burn");
        require(self.burnable, "Burning is not allowed");

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
        require(self.mintable, "Cannot change metadata after minting is closed");
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

        // we allow bounce here and don't handle it, if claim fails we just accept the TONs back
        message(MessageParameters {
            bounce: true,
            to: msg.receiver,
            value: 0,
            mode: SendRemainingBalance,
        });
    }

    receive(msg: ChangeBurnable) {
        require(sender() == self.owner, "Only deployer can change burn flag");
        self.burnable = msg.burnable;
    }

    bounced(msg: bounced<JettonTransferInternalV2>) {
        self.totalSupply -= msg.amount;
    }

    get fun get_jetton_data(): JettonMinterState {
        return JettonMinterState {
            totalSupply: self.totalSupply,
            mintable: self.mintable,
            adminAddress: self.owner,
            jettonContent: self.jettonContent,
            jettonWalletCode: codeOf JettonWalletFeatureRich,
            burnable: self.burnable,
        };
    }

    get fun get_wallet_address(ownerAddress: Address): Address {
        return getJettonWalletByOwner(ownerAddress);
    }
}

inline fun getJettonWalletInit(address: Address): StateInit {
    return initOf JettonWalletFeatureRich(address, myAddress(), 0);
}

inline fun getJettonWalletByOwner(jettonWalletOwner: Address): Address {
    return contractAddress(getJettonWalletInit(jettonWalletOwner));
}

inline fun getJettonBasechainWalletByOwner(jettonWalletOwner: Address): BasechainAddress {
    return contractBasechainAddress(getJettonWalletInit(jettonWalletOwner));
}
