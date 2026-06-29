import "./grampad-token-wallet";
import "./messages";
import "./constants";
import "./utils";

contract GramPadTokenMaster {
    initialHolder: Address;
    jettonContent: Cell;
    initialized: Bool;
    totalSupply: Int as coins;

    init(initialHolder: Address, jettonContent: Cell) {
        self.initialHolder = initialHolder;
        self.jettonContent = jettonContent;
        self.initialized = false;
        self.totalSupply = GramxTotalSupply;
    }

    receive(msg: DeployToken) {
        require(!self.initialized, "GRAMX is already initialized");
        forceBasechain(self.initialHolder);
        require(context().value >= MinDeployValue, "Insufficient deployment value");

        self.initialized = true;
        nativeReserve(MinTonsForStorage, ReserveAtMost);

        deploy(DeployParameters {
            value: ton("0.1"),
            bounce: true,
            mode: SendPayGasSeparately | SendBounceIfActionFail,
            body: JettonTransferInternal {
                queryId: msg.queryId,
                amount: GramxTotalSupply,
                sender: self.initialHolder,
                responseDestination: self.initialHolder,
                forwardTonAmount: 0,
                forwardPayload: rawSlice("0"),
            }.toCell(),
            init: getGramxWalletInit(self.initialHolder),
        });
    }

    receive(msg: ProvideWalletAddress) {
        let ownerWorkchain = parseStdAddress(msg.ownerAddress.asSlice()).workchain;
        let targetWallet: BasechainAddress = (ownerWorkchain == Basechain)
            ? contractBasechainAddress(getGramxWalletInit(msg.ownerAddress))
            : emptyBasechainAddress();

        message(MessageParameters {
            body: makeTakeWalletAddressMessage(targetWallet, msg),
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
        });
    }

    receive(msg: JettonBurnNotification) {
        let messageSender = parseStdAddress(sender().asSlice());
        let expectedWallet = contractBasechainAddress(getGramxWalletInit(msg.sender));

        require(
            messageSender.workchain == Basechain &&
                messageSender.address == expectedWallet.hash!!,
            "Unauthorized burn notification",
        );
        require(msg.amount <= self.totalSupply, "Burn exceeds total supply");

        self.totalSupply -= msg.amount;

        if (msg.responseDestination != null) {
            message(MessageParameters {
                to: msg.responseDestination!!,
                body: JettonExcesses { queryId: msg.queryId }.toCell(),
                value: 0,
                bounce: false,
                mode: SendRemainingValue | SendIgnoreErrors,
            });
        }
    }

    bounced(msg: bounced<JettonTransferInternal>) {
        if (msg.amount == GramxTotalSupply) {
            self.initialized = false;
        }
    }

    get fun get_jetton_data(): JettonMasterData {
        return JettonMasterData {
            totalSupply: self.totalSupply,
            mintable: false,
            adminAddress: self.initialHolder,
            jettonContent: self.jettonContent,
            jettonWalletCode: codeOf GramPadTokenWallet,
        };
    }

    get fun get_wallet_address(ownerAddress: Address): Address {
        return contractAddress(getGramxWalletInit(ownerAddress));
    }

    get fun is_initialized(): Bool {
        return self.initialized;
    }

    get fun grampad_contract_version(): Int {
        return 2;
    }
}

inline fun getGramxWalletInit(owner: Address): StateInit {
    return initOf GramPadTokenWallet(0, owner, myAddress());
}
