import "@stdlib/deploy";
import "@stdlib/ownable";
import "./jetton/factory_message";
import "./packages/token/jetton/JettonWallet";
import "./curve/curve";

message CreateToken {
    metadata: TokenContent;
    initial_buy: Int as coins;
}

message SetTokenFactory {
    token_factory: Address;
}

struct ForwardPayload {
    op: Int as uint8;
    data: Slice;
}

struct InitCurveParams {
    creator: Address;
    initial_buy: Int as coins;
}

const INIT_CURVE : Int = 0x00;
const SELL_CURVE:  Int = 0x01;

const WRONG_OP: Int = 0xffff;


contract CurveRouter with Deployable, Ownable {

    owner: Address;
    token_factory: Address?;
    pending_inits: map<Int as uint64, Int as uint8>;

    init(owner: Address) {
        self.owner = owner;
        self.token_factory = null;
    }

    receive(msg:JettonTransferNotification) {
        let payload: ForwardPayload = ForwardPayload.fromSlice(msg.forward_payload);
        if(payload.op == INIT_CURVE) {
            let params: InitCurveParams = InitCurveParams.fromSlice(payload.data);
            self._init_curve(msg.query_id, sender(), msg.amount, params);
            return;
        }
        if(payload.op == SELL_CURVE) {
            self._sell(sender(), msg.amount, msg.sender);
            return;
        }
        throw(WRONG_OP);
    }

    fun _init_curve(query_id:Int, jetton_wallet_address: Address, jetton_balance: Int, params:InitCurveParams) {
        let deleted: Bool = self.pending_inits.del(query_id);
        require(deleted, "Invalid query id");
        let initCode: StateInit = initOf Curve(myAddress(), jetton_wallet_address);
        send(SendParameters {
            to: contractAddress(initCode),
            value: 0,
            mode: SendRemainingValue,
            body: CurveInit {
                jetton_wallet_address: jetton_wallet_address,
                jetton_balance: jetton_balance,
                initial_buy: params.initial_buy,
                creator_address: params.creator
            }.toCell(),
            code: initCode.code,
            data: initCode.data
        });
    }

    fun _sell(jetton_wallet_address: Address, amount: Int, to: Address) {
        let initCode: StateInit = initOf Curve(myAddress(), jetton_wallet_address);
        send(SendParameters {
            to: contractAddress(initCode),
            value: 0,
            mode: SendRemainingValue,
            body: Sell {
                jetton_amount: amount,
                to: to
            }.toCell()
        });
    }

    receive(msg:SetTokenFactory) {
        self.requireOwner();
        self.token_factory = msg.token_factory;
        self.reply("Token factory set".asComment());
    }

    receive(msg:PayJettonTo) {
        let initCode: StateInit = initOf Curve(myAddress(), msg.jetton_wallet_address);
        require(sender() == contractAddress(initCode), "Invalid sender");
        let transfer: JettonTransfer = JettonTransfer {
            query_id: 0,
            destination: msg.destination,
            response_destination: msg.destination,
            amount: msg.amount,
            forward_payload: emptySlice(),
            forward_ton_amount: 0,
            custom_payload: emptyCell()
        };
        send(SendParameters {
            to: msg.jetton_wallet_address,
            value: context().value - msg.keep,
            body: transfer.toCell()
        });
    }

    receive(msg:PayTonTo) {
        let initCode: StateInit = initOf Curve(myAddress(), msg.jetton_wallet_address);
        require(sender() == contractAddress(initCode), "Invalid sender");
        send(SendParameters {
            to: msg.destination,
            value: msg.amount + context().value
        });
    }

    receive(msg:CreateToken) {
        // TODO: check gas + initial buy
        require(self.token_factory != null, "Token factory not set");
        let query_id: Int = random(0, 0xFFFFFFFFFFFFFFFF);
        // TODO: collision test
        self.pending_inits.set(query_id, 0);
        let forward: ForwardPayload = ForwardPayload {
            op: INIT_CURVE,
            data: InitCurveParams {
                creator: sender(),
                initial_buy:msg.initial_buy
            }.toCell().asSlice()
        };
        let body: Cell = Create {
            query_id: query_id,
            content: msg.metadata,
            response_destination: sender(),
            forward_payload: forward.toCell().asSlice()
        }.toCell();
        let params: SendParameters = SendParameters {
            to:self.token_factory!!,
            value: 0,
            mode: SendRemainingValue,
            body: body
        };
        send(params);
    }

    get fun curve_address(jetton_wallet_address: Address): Address {
        let initCode: StateInit = initOf Curve(myAddress(), jetton_wallet_address);
        return contractAddress(initCode);
    }
}
