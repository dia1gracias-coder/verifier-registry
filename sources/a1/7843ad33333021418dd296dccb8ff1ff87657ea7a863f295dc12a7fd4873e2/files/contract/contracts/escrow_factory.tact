import "@stdlib/deploy";
import "@stdlib/ownable";
import "./escrow_deal";

message(0x43524544) CreateDeal {
    queryId: Int as uint64;
    escrowId: Int as uint64;

    executor: Address;

    dealAmount: Int as coins;
    reserve: Int as coins;
}

message(0x534f5052) SetOperator {
    queryId: Int as uint64;
    operator: Address;
}

message(0x53545259) SetTreasury {
    queryId: Int as uint64;
    treasury: Address;
}

contract EscrowFactory with Deployable, Ownable {
    owner: Address;
    operator: Address;
    treasury: Address;

    minCreateValue: Int as coins;

    escrows: map<Int, Address>;

    init(
        owner: Address,
        operator: Address,
        treasury: Address,
        minCreateValue: Int,
    ) {
        self.owner = owner;
        self.operator = operator;
        self.treasury = treasury;
        self.minCreateValue = minCreateValue;
    }

    receive(msg: CreateDeal) {
        let ctx = context();

        require(self.escrows.get(msg.escrowId) == null, "ESCROW_EXISTS");
        require(msg.dealAmount > 0, "INVALID_AMOUNT");
        require(msg.reserve >= 0, "INVALID_RESERVE");

        // Client pays:
        // 1. dealAmount      -> goes to EscrowDeal
        // 2. reserve         -> goes to EscrowDeal for gas/storage buffer
        // 3. minCreateValue  -> goes to treasury as create overhead
        let requiredValue = msg.dealAmount + msg.reserve + self.minCreateValue;

        require(ctx.value >= requiredValue, "INSUFFICIENT_CREATE_VALUE");

        let init = initOf EscrowDeal(
            msg.escrowId,
            myAddress(),
            self.operator,
            ctx.sender,
            msg.executor,
            msg.dealAmount,
            msg.reserve,
        );

        let escrowAddress = contractAddress(init);

        self.escrows.set(msg.escrowId, escrowAddress);

        // Deploy child EscrowDeal and fund it with dealAmount + reserve.
        // EscrowDeal has empty receive(), so we send empty body.
        send(SendParameters {
            to: escrowAddress,
            value: msg.dealAmount + msg.reserve,
            bounce: false,
            code: init.code,
            data: init.data,
            body: beginCell().endCell(),
        });

        // Send create overhead to treasury.
        if (self.minCreateValue > 0) {
            send(SendParameters {
                to: self.treasury,
                value: self.minCreateValue,
                bounce: false,
            });
        }
    }

    receive(msg: SetOperator) {
        self.requireOwner();

        self.operator = msg.operator;
    }

    receive(msg: SetTreasury) {
        self.requireOwner();

        self.treasury = msg.treasury;
    }

    get fun getEscrowAddress(escrowId: Int): Address? {
        return self.escrows.get(escrowId);
    }

    get fun getConfig(): EscrowFactoryConfig {
        return EscrowFactoryConfig {
            owner: self.owner,
            operator: self.operator,
            treasury: self.treasury,
            minCreateValue: self.minCreateValue,
        };
    }
}

struct EscrowFactoryConfig {
    owner: Address;
    operator: Address;
    treasury: Address;
    minCreateValue: Int as coins;
}
