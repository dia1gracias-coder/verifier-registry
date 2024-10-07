import "./JettonMessages";
import "./errcodes";

message(0x71a9dc7a) Cancel {}

struct State {
    type: Int as uint8;
    seller: Address;
    request: Request;
    open: Bool;
}

// @notice Check that condition is true, else if incoming value is enought - withdraw jettons
// @param code - code of the error being checking
// @param condition - result of checking condition
// @param to - withdraw destination of jettons
// @param amount - withdraw amount of jettons
inline fun SmartThrow(code: Int, condition: Bool, to: Address, amount: Int): Bool {
    if (!condition) {
        if (context().value >= jetton_transfer_fee) {
            basicJettonTransfer(context().sender, to, amount, 0);
        } else {
            nativeThrow(not_enough_ton);
        }
        emit(beginCell().storeUint(code, 32).endCell());
    }

    return condition;
}

trait OrderBase {
    seller: Address;
    router: Address;
    type: Int;

    request: Request;

    open: Bool;

    // @notice Send all balance to owner and annihilate contract from blockchain
    fun withdraw() {
        send(SendParameters{
            to: self.seller,
            value: 0,
            mode: SendRemainingBalance + SendDestroyIfZero,
        });
    }

    // @notice return self params of Order contract
    get fun state(): State {
        return State {
            type: self.type,
            seller: self.seller,
            request: self.request,
            open: self.open,
        };
    }
}
