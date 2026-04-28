// OWNER AUTH: The owner is set at deployment to the deployer's TON wallet address
// (an Ed25519-based address, distinct from the secp256k1 EVM address used in weeks 1-4).
// Ownership cannot be transferred. Only the owner may call withdraw().
// Authentication uses sender() — the immediate message sender — never a delegated mechanism.

const MIN_AMOUNT:     Int = 1;    // 1 nanoTON — enforces economic cost per message
const NAME_MAX_BYTES: Int = 50;
const MSG_MAX_BYTES:  Int = 280;

// Count UTF-8 bytes across a snake-string cell chain.
// Tact strings may span multiple cells (refs) for values > ~127 bytes.
fun countStringBytes(s: Slice): Int {
    let total: Int = s.bits() / 8;
    while (!s.refsEmpty()) {
        s = s.loadRef().asSlice();
        total = total + s.bits() / 8;
    }
    return total;
}

fun stringIsEmpty(s: Slice): Bool {
    return s.bits() == 0 && s.refsEmpty();
}

struct Support {
    sender:    Address;
    name:      String;
    message:   String;
    amount:    Int as coins;
    timestamp: Int as uint64;
}

message SendSupport {
    name:    String;
    message: String;
}

message SupportSent {
    sender:    Address;
    name:      String;
    message:   String;
    amount:    Int as coins;
    timestamp: Int as uint64;
}

message Withdrawn {
    to:     Address;
    amount: Int as coins;
}

contract ProofOfSupport {
    owner:    Address;
    msgCount: Int as uint32 = 0;
    messages: map<Int, Support>;

    init(owner: Address) {
        self.owner = owner;
    }

    // Deploy receiver — catches the null-body state-init message
    receive() {}

    receive(msg: SendSupport) {
        let nameSlice: Slice = msg.name.asSlice();
        let msgSlice: Slice = msg.message.asSlice();

        throwIf(400, stringIsEmpty(nameSlice));
        throwIf(401, countStringBytes(nameSlice) > NAME_MAX_BYTES);
        throwIf(402, stringIsEmpty(msgSlice));
        throwIf(403, countStringBytes(msgSlice) > MSG_MAX_BYTES);
        throwIf(404, context().value < MIN_AMOUNT);

        let record: Support = Support {
            sender:    sender(),
            name:      msg.name,
            message:   msg.message,
            amount:    context().value,
            timestamp: now(),
        };
        self.messages.set(self.msgCount, record);
        self.msgCount = self.msgCount + 1;

        emit(SupportSent {
            sender:    record.sender,
            name:      record.name,
            message:   record.message,
            amount:    record.amount,
            timestamp: record.timestamp,
        }.toCell());
    }

    receive("withdraw") {
        // REENTRANCY: TON's actor model processes one inbound message per contract
        // at a time. A second message cannot interrupt this handler mid-execution.
        // Reentrancy is structurally impossible in TVM; no ReentrancyGuard equivalent needed.
        //
        // OWNER AUTH: Owner is set at deploy to the deployer's TON wallet address
        // (Ed25519-based; distinct from the secp256k1 EVM address used in weeks 1-4).
        // Ownership cannot be transferred. Only the owner may call withdraw().
        throwUnless(401, sender() == self.owner);

        // Keep 0.05 TON for ongoing storage rent; send the rest to owner.
        // Uses an explicit amount rather than SendRemainingBalance to avoid
        // action-phase edge cases with nativeReserve in the sandbox.
        let balance: Int = myBalance();
        let toSend: Int = balance - ton("0.05");

        if (toSend > 0) {
            send(SendParameters {
                to:     self.owner,
                value:  toSend,
                bounce: false,
                mode:   SendDefaultMode | SendIgnoreErrors,
            });
        }

        emit(Withdrawn {
            to:     self.owner,
            amount: toSend > 0 ? toSend : 0,
        }.toCell());
    }

    bounced(src: bounced<SendSupport>) {
        // Bounce received — do nothing. TON protocol satisfied.
    }

    get fun getMessages(): map<Int, Support> {
        return self.messages;
    }
}
