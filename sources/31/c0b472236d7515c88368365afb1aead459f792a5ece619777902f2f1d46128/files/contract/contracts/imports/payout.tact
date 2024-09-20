import "@stdlib/ownable";
import "./jetton-validation";
import "./constants";
import "./messages/excess";
import "./messages/token-transfer";

message PayoutRequest {
    requestId: String;
    sender: Address;
    payee: Address;
    amount: Int as coins;
    currency: Int as uint8;
    jettonMasterAddress: Address?;
}

message PayoutResponse {
    requestInfo: PayoutRequest;
}

trait Payout with JettonValidator {
    jettonWalletGovernedCode: Cell;

    virtual fun handlePayoutResponse(msg: PayoutResponse) {
        let ctx: Context = context();
        let requestInfo: PayoutRequest = msg.requestInfo;
        let sender: Address = requestInfo.sender;
        let requestId: String = requestInfo.requestId;
        let amount: Int = requestInfo.amount;
        let payee: Address = requestInfo.payee;
        let paymentAddress: Address = contractAddress(initOf Payment(myAddress(), requestId));
        require(ctx.sender == paymentAddress, "Invalid sender");

        if (requestInfo.currency == CurrencyTon) {
            send(SendParameters{
                to: payee,
                value: amount,
                mode: SendPayGasSeparately,
                bounce: false,
                body: "Payout success".asComment()
            });

            send(SendParameters{
                to: sender,
                value: 0,
                mode: SendRemainingValue,
                bounce: false,
                body: Excesses{query_id: 0}.toCell()
            });
            return;
        }

        if (requestInfo.jettonMasterAddress != null) {
            let myJettonWalletAddress: Address = self.calculateMyJettonGovernedAddress(requestInfo.jettonMasterAddress!!);
            send(SendParameters{
                to: myJettonWalletAddress,
                value: 0,
                mode: SendRemainingValue,
                bounce: false,
                body: TokenTransfer{
                    query_id: 0,
                    amount: amount,
                    destination: payee,
                    response_destination: sender,
                    custom_payload: null,
                    forward_ton_amount: 0,
                    forward_payload: beginCell().storeUint(0, 1).endCell().asSlice()
                }.toCell()
            });
            return;
        }

        require(false, "Invalid currency");
    }
}

contract Payment with OwnableTransferable {
    owner: Address;
    requestId: String;
    completed: Bool;

    init(owner: Address, requestId: String) {
        self.owner = owner;
        self.requestId = requestId;
        self.completed = false;
    }

    receive(msg: PayoutRequest) {
        let ctx: Context = context();
        self.requireOwner();
        nativeReserve(minTonsForStorage, ReserveExact);

        if (!self.completed) {
            self.completed = true;
            send(SendParameters{
                to: sender(),
                value: 0,
                mode: SendRemainingBalance,
                body: PayoutResponse{requestInfo: msg}.toCell()
            });
        }
    }

    bounced(msg: Slice) {
        self.completed = false;
    }

    get fun ownerAddress(): Address {
        return self.owner;
    }

    get fun requestId(): String {
        return self.requestId;
    }

    get fun completed(): Bool {
        return self.completed;
    }
}