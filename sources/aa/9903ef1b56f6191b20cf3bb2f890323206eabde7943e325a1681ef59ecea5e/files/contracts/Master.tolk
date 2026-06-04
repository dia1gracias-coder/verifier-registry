import "types"

contract Master {
    author: "Acton User"
    version: "1.0.0"
    description: "Minimal starter contract with owner management"
    storage: Storage
    incomingMessages: AllowedMessage
}

type AllowedMessage = ChangeOwner | DeployChild | TestBounce
type TheoreticallyBounceable = MyMessage

fun calcDeployedChild(parent: address, childContractCode: cell): AutoDeployAddress {
    return AutoDeployAddress {
        stateInit: ContractState {
            code: childContractCode,
            data: ChildStorage {
                parent,
                seqno: 0,
            }.toCell(),
        },
    };
}

fun onInternalMessage(in: InMessage) {
    if (in.body.isEmpty()) {
        return;
    }
    val msg = AllowedMessage.fromSlice(in.body);

    match (msg) {
        ChangeOwner => {
            var storage = lazy Storage.load();
            assert (in.senderAddress == storage.owner) throw Errors.NotOwner;
            storage.owner = msg.newOwner;
            storage.save();
        }
        DeployChild => {
            val storage = lazy Storage.load();
            assert (in.senderAddress == storage.owner) throw Errors.NotOwner;
            val deployMsg = createMessage({
                bounce: BounceMode.NoBounce,
                value: ton("0.02"),
                dest: calcDeployedChild(contract.getAddress(), storage.childContractCode),
            });
            deployMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
        }
        TestBounce => {
            val storage = lazy Storage.load();
            assert (in.senderAddress == storage.owner) throw Errors.NotOwner;
            if (msg.sendWithoutStateInit) {
                val msgToChild = createMessage({
                    bounce: BounceMode.RichBounce,
                    value: ton("0"),
                    dest: calcDeployedChild(
                        contract.getAddress(),
                        storage.childContractCode,
                    ).calculateAddress(),
                    body: MyMessage {
                        seqno: 1 as uint256,
                        salt: 2 as uint256,
                        traceId: 3 as uint256,
                        extraData: beginCell().storeUint(0xABCDEF, 24).endCell(),
                        produceError: msg.produceError,
                    },
                });
                msgToChild.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
            } else {
                val msgToChild = createMessage({
                    bounce: BounceMode.RichBounce,
                    value: ton("0"),
                    dest: calcDeployedChild(contract.getAddress(), storage.childContractCode),
                    body: MyMessage {
                        seqno: 1 as uint256,
                        salt: 2 as uint256,
                        traceId: 3 as uint256,
                        extraData: beginCell().storeUint(0xABCDEF, 24).endCell(),
                        produceError: msg.produceError,
                    },
                });
                msgToChild.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
            }
        }
    }
}

fun onBouncedMessage(in: InMessageBounced) {
    var storage = lazy Storage.load();
    val rich = lazy RichBounceBody.fromSlice(in.bouncedBody);
    val msg = lazy TheoreticallyBounceable.fromSlice(rich.originalBody.beginParse());
    match (msg) {
        MyMessage => {
            storage.lastBouncedBody = msg.toCell();
        }
    }
    storage.save();
}

get fun owner(): address {
    val storage = lazy Storage.load();
    return storage.owner;
}

get fun id(): uint64 {
    val storage = lazy Storage.load();
    return storage.id;
}

get fun lastBouncedBody(): cell {
    val storage = lazy Storage.load();
    return storage.lastBouncedBody;
}

get fun childContractAddress(): address {
    val storage = lazy Storage.load();
    return calcDeployedChild(contract.getAddress(), storage.childContractCode).calculateAddress();
}
