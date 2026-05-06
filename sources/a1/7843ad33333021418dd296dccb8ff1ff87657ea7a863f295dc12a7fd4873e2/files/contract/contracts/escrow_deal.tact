const STATE_FUNDED: Int = 1;
const STATE_RELEASED: Int = 3;
const STATE_REFUNDED: Int = 4;

message(0x52454c53) ReleaseToExecutor {
    queryId: Int as uint64;
}

message(0x5246554e) RefundToClient {
    queryId: Int as uint64;
}

contract EscrowDeal {
    escrowId: Int as uint64;

    factory: Address;
    operator: Address;

    client: Address;
    executor: Address;

    dealAmount: Int as coins;
    reserve: Int as coins;

    state: Int as uint8;

    init(
        escrowId: Int,
        factory: Address,
        operator: Address,
        client: Address,
        executor: Address,
        dealAmount: Int,
        reserve: Int,
    ) {
        self.escrowId = escrowId;

        self.factory = factory;
        self.operator = operator;

        self.client = client;
        self.executor = executor;

        self.dealAmount = dealAmount;
        self.reserve = reserve;

        // Сделка создаётся уже профинансированной.
        self.state = STATE_FUNDED;
    }

    receive() {
        // Пустое deploy-сообщение от EscrowFactory.
        // Нужно, чтобы первый internal message с empty body не падал с exit code 130.
    }

    fun requireOperator() {
        require(context().sender == self.operator, "ONLY_OPERATOR");
    }

    receive(msg: ReleaseToExecutor) {
        self.requireOperator();

        require(self.state == STATE_FUNDED, "INVALID_STATE");

        self.state = STATE_RELEASED;

        send(SendParameters {
            to: self.executor,
            value: self.dealAmount,
            bounce: false,
        });
    }

    receive(msg: RefundToClient) {
        self.requireOperator();

        require(self.state == STATE_FUNDED, "INVALID_STATE");

        self.state = STATE_REFUNDED;

        send(SendParameters {
            to: self.client,
            value: self.dealAmount,
            bounce: false,
        });
    }

    get fun getState(): Int {
        return self.state;
    }

    get fun getEscrowId(): Int {
        return self.escrowId;
    }

    get fun getDealData(): EscrowDealData {
        return EscrowDealData {
            escrowId: self.escrowId,
            factory: self.factory,
            operator: self.operator,
            client: self.client,
            executor: self.executor,
            dealAmount: self.dealAmount,
            reserve: self.reserve,
            state: self.state,
        };
    }
}

struct EscrowDealData {
    escrowId: Int as uint64;
    factory: Address;
    operator: Address;
    client: Address;
    executor: Address;
    dealAmount: Int as coins;
    reserve: Int as coins;
    state: Int as uint8;
}
