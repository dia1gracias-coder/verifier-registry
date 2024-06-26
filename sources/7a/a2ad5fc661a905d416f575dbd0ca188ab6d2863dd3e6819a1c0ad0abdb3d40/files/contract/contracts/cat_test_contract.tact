import "@stdlib/deploy";

message ClaimProcessed {
    payload: String; // JSON 객체 형태의 문자열
}

message Withdraw {
    amount: Int as coins;
}

message Payment {
    amount: Int as coins;
    memo: String;
}

message ClaimEvent {
    payload: String; // JSON 객체 형태의 문자열
    address: Address;
}

message PaymentEvent {
    amount: Int as coins;
    memo: String;
    address: Address;
}

message ClaimResponse {
    payload: String; // 처리된 JSON 객체 형태의 문자열
}

contract CatTestContract with Deployable {
    const MinTonForStorage: Int = ton("0.01");
    deployer: Address;

    init() {
        self.deployer = sender();
    }

    receive(msg: ClaimProcessed) {
        let senderAddress: Address = sender();
        
        // 트랜잭션 로그에 클레임 처리 기록
        emit(ClaimEvent{address: senderAddress, payload: msg.payload}.toCell());

        // 클레임 처리 완료 알림 및 페이로드 반환
        self.reply(ClaimResponse{payload: msg.payload}.toCell());
    }

    // 유저 결제 함수
    receive(msg: Payment) {
        let senderAddress: Address = sender();
        let paymentAmount: Int = msg.amount;

        // 트랜잭션 로그에 결제 기록
        emit(PaymentEvent {
            address: senderAddress,
            amount: paymentAmount,
            memo: msg.memo
        }.toCell());

        // 결제 처리 완료 알림
        self.notify("PaymentReceived".asComment());
    }

    // this will withdraw the entire balance of the contract and leave 0
    receive("withdraw all") {
        require(sender() == self.deployer, "Only deployer is allowed to withdraw");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors
        });
    }

    // this will withdraw the entire balance but leave 0.01 for storage rent costs
    receive("withdraw safe") {
        require(sender() == self.deployer, "Only deployer is allowed to withdraw");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: myBalance() - context().value - self.MinTonForStorage,
            mode: SendRemainingValue + SendIgnoreErrors
        });
    }

    // this will withdraw a specific amount but leave 0.01 for storage rent costs
    receive(msg: Withdraw) {
        require(sender() == self.deployer, "Only deployer is allowed to withdraw");
        let amount: Int = min(msg.amount, myBalance() - context().value - self.MinTonForStorage);
        require(amount > 0, "Insufficient balance");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: amount,
            mode: SendRemainingValue + SendIgnoreErrors
        });
    }

    get fun balance(): String {
        return myBalance().toCoinsString();
    }
}