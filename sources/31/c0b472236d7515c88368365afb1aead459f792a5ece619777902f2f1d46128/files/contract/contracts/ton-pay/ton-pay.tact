import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages/index";
import "../imports/constants";
import "../imports/jetton-validation";
import "../imports/signature-verifiable";
import "../imports/payout";
import "./structs/ton-pay-data";

contract TonPay with Deployable, OwnableTransferable, SignatureVerifiable, Payout {
    owner: Address;
    recipient: Address;
    publicKey: Int as uint256;
    usdtMasterAddress: Address;
    jettonWalletGovernedCode: Cell;
    tonPayUsdtWallet: Address;

    init(owner: Address, recipient: Address, usdtMasterAddress: Address, publicKey: Int, jettonWalletGovernedCode: Cell) {
        self.owner = owner;
        self.recipient = recipient;
        self.publicKey = publicKey;
        self.usdtMasterAddress = usdtMasterAddress;
        self.jettonWalletGovernedCode = jettonWalletGovernedCode;
        self.tonPayUsdtWallet = calculateJettonWalletGovernedAddress(myAddress(), usdtMasterAddress, jettonWalletGovernedCode);

        nativeReserve(minTonsForStorage, ReserveExact);
        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingBalance,
            body: Excesses{query_id: 0}.toCell()
        });
    }

    /* handle deposit USDT message */
    receive(msg: TokenNotification) {
        let ctx: Context = context();
        let msgValue: Int = self.msg_value(ctx.value);
        /* Check msg.value after reducing fee */
        require(msgValue >= ton("0.1"), "not enough TONs to deposit");
        /* Check sender type is usdt wallet */
        nativeThrowUnless(999, ctx.sender == self.tonPayUsdtWallet);
        /* send usdt to recipient and send ton excess to sender */
        let usdtSender: Address = msg.from;
        let usdtAmount: Int = msg.amount;
        send(SendParameters{
            to: self.tonPayUsdtWallet,
            value: msgValue,
            mode: SendPayGasSeparately,
            bounce: false,
            body: TokenTransfer{
                query_id: msg.query_id,
                amount: usdtAmount,
                destination: self.recipient,
                response_destination: usdtSender,
                custom_payload: null,
                forward_ton_amount: 0,
                forward_payload: beginCell().storeUint(0, 1).endCell().asSlice()
            }.toCell()
        });
        /* emit usdt deposit event */
        emit(DepositEvent{sender: usdtSender, amount: usdtAmount}.toCell());
    }

    /* handle withdraw message */
    receive(msg: Withdrawal) {
        let ctx: Context = context();
        /* Check msg.value after reducing fee */
        let msgValue: Int = self.msg_value(ctx.value);
        require(msgValue >= 0, "not enough TONs to withdraw");
        /* Check signature */
        let info: WithdrawalInfo = msg.info;
        self.checkSignature(msg.signatureMoreInfo, info.toCell(), msg.signature);
        /* send payout request to check payment */
        let paymentStateInit: StateInit = initOf Payment(myAddress(), info.requestId);
        let paymentAddress: Address = contractAddress(initOf Payment(myAddress(), info.requestId));

        send(SendParameters{
            to: paymentAddress,
            value: msgValue,
            mode: SendPayGasSeparately,
            bounce: false,
            body: PayoutRequest{
                requestId: info.requestId,
                sender: ctx.sender,
                payee: info.receiver,
                amount: info.amount,
                currency: CurrencyUSDT,
                jettonMasterAddress: self.usdtMasterAddress,
            }.toCell(),
            code: paymentStateInit.code,
            data: paymentStateInit.data
        });
    }

    receive(msg: UpdatePublicKey) {
        self.requireOwner();
        self.publicKey = msg.publicKey;

        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            body: Excesses{query_id: 0}.toCell()
        });
    }

    receive(msg: UpdateJettonWalletGoverned) {
        self.requireOwner();
        if (msg.usdtMasterAddress != null) {
            self.usdtMasterAddress = msg.usdtMasterAddress!!;
        }
        if (msg.jettonWalletGovernedCode != null) {
            self.jettonWalletGovernedCode = msg.jettonWalletGovernedCode!!;
        }
        self.tonPayUsdtWallet = self.calculateMyJettonGovernedAddress(self.usdtMasterAddress);

        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            body: Excesses{query_id: 0}.toCell()
        });
    }

    receive(msg: UpdateRecipient) {
        self.requireOwner();
        self.recipient = msg.recipient;

        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            body: Excesses{query_id: 0}.toCell()
        });
    }

    receive(msg: PayoutResponse){
        self.handlePayoutResponse(msg);
        /* emit usdt withdrawal event */
        let payoutInfo: PayoutRequest = msg.requestInfo;
        emit(WithdrawalEvent{sender: payoutInfo.payee, amount: payoutInfo.amount, requestId: payoutInfo.requestId}.toCell());
    }

    receive() {}

    fun msg_value(value: Int): Int {
        let msgValue: Int = value;
        let ton_balance_before_msg: Int = myBalance() - msgValue;
        let storage_fee: Int = minTonsForStorage - min(ton_balance_before_msg, minTonsForStorage);
        msgValue = msgValue - (storage_fee + gasConsumption);
        return msgValue;
    }

    get fun tonPayData(): TonPayData {
        return TonPayData{
            owner: self.owner,
            recipient: self.recipient,
            publicKey: self.publicKey,
            usdtMasterAddress: self.usdtMasterAddress,
            jettonWalletGovernedCode: self.jettonWalletGovernedCode,
            tonPayUsdtWallet: self.tonPayUsdtWallet
        };
    }
}