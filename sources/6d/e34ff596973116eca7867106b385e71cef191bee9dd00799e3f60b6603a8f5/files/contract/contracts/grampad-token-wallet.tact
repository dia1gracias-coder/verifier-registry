import "./messages";
import "./constants";
import "./utils";

contract GramPadTokenWallet(
    balance: Int as coins,
    owner: Address,
    minter: Address,
) {
    receive(msg: JettonTransfer) {
        forceBasechain(msg.destination);
        require(sender() == self.owner, "Only wallet owner may transfer");

        self.balance -= msg.amount;
        require(self.balance >= 0, "Insufficient GRAMX balance");
        checkEitherForwardPayload(msg.forwardPayload);

        let ctx = context();
        let forwardCount = 1 + sign(msg.forwardTonAmount);
        require(
            ctx.value >
                msg.forwardTonAmount +
                forwardCount * ctx.readForwardFee() +
                2 * getComputeFee(GasForTransfer, false) +
                MinTonsForStorage,
            "Insufficient TON for transfer",
        );

        deploy(DeployParameters {
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: JettonTransferInternal {
                queryId: msg.queryId,
                amount: msg.amount,
                sender: self.owner,
                responseDestination: msg.responseDestination,
                forwardTonAmount: msg.forwardTonAmount,
                forwardPayload: msg.forwardPayload,
            }.toCell(),
            init: initOf GramPadTokenWallet(0, msg.destination, self.minter),
        });
    }

    receive(msg: JettonTransferInternal) {
        let expectedWallet = initOf GramPadTokenWallet(0, msg.sender, self.minter);
        if (!expectedWallet.hasSameBasechainAddress(sender())) {
            require(sender() == self.minter, "Unauthorized internal transfer");
        }

        self.balance += msg.amount;

        let ctx = context();
        let remainingValue = ctx.value;
        let balanceBeforeMessage = myBalance() - remainingValue;

        if (msg.forwardTonAmount > 0) {
            remainingValue -= msg.forwardTonAmount + ctx.readForwardFee();
            message(MessageParameters {
                to: self.owner,
                value: msg.forwardTonAmount,
                mode: SendPayGasSeparately,
                bounce: false,
                body: JettonNotification {
                    queryId: msg.queryId,
                    amount: msg.amount,
                    sender: msg.sender,
                    forwardPayload: msg.forwardPayload,
                }.toCell(),
            });
        }

        nativeReserve(max(balanceBeforeMessage, MinTonsForStorage), ReserveAtMost);
        if (msg.responseDestination != null && remainingValue > 0) {
            message(MessageParameters {
                to: msg.responseDestination!!,
                value: remainingValue,
                mode: SendRemainingBalance | SendIgnoreErrors,
                bounce: false,
                body: JettonExcesses { queryId: msg.queryId }.toCell(),
            });
        }
    }

    receive(msg: JettonBurn) {
        require(sender() == self.owner, "Only wallet owner may burn");

        self.balance -= msg.amount;
        require(self.balance >= 0, "Insufficient GRAMX balance");

        let ctx = context();
        require(
            ctx.value > ctx.readForwardFee() + 2 * getComputeFee(GasForBurn, false),
            "Insufficient TON for burn",
        );

        message(MessageParameters {
            to: self.minter,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: JettonBurnNotification {
                queryId: msg.queryId,
                amount: msg.amount,
                sender: self.owner,
                responseDestination: msg.responseDestination,
            }.toCell(),
        });
    }

    bounced(msg: bounced<JettonTransferInternal>) {
        self.balance += msg.amount;
    }

    bounced(msg: bounced<JettonBurnNotification>) {
        self.balance += msg.amount;
    }

    get fun get_wallet_data(): JettonWalletData {
        return JettonWalletData {
            balance: self.balance,
            owner: self.owner,
            minter: self.minter,
            code: myCode(),
        };
    }
}
