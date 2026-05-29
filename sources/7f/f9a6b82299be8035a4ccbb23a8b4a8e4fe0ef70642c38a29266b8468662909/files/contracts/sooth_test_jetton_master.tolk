import "errors.tolk"

struct Storage {
    totalSupply: coins
    admin: address
    content: cell
    walletCode: cell
}

fun Storage.load() {
    return Storage.fromCell(contract.getData());
}

fun Storage.save(self) {
    contract.setData(self.toCell());
}

struct (0x6d696e74) Mint {
    owner: address
    amount: coins
    responseDestination: address
    forwardTonAmount: coins
}

struct (0x178d4519) JettonInternalTransfer {
    queryId: uint64
    amount: coins
    from: address
    responseAddress: address
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

struct (0x7bdd97de) JettonBurnNotification {
    queryId: uint64
    amount: coins
    sender: address
    responseDestination: address
}

type AllowedMessage = Mint | JettonBurnNotification

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessage.fromSlice(in.body);
    var storage = lazy Storage.load();
    match (msg) {
        Mint => {
            assert (
                in.senderAddress == storage.admin
            ) throw Errors.FIXTURE_SOOTH_MASTER_SENDER_NOT_ADMIN;
            assert (msg.amount > 0) throw Errors.FIXTURE_SOOTH_MASTER_AMOUNT_NON_POSITIVE;
            val wallet = calculateWalletDeploy(
                msg.owner,
                contract.getAddress(),
                storage.walletCode,
                msg.owner.getWorkchain(),
            );
            val body: JettonInternalTransfer = {
                queryId: 0,
                amount: msg.amount,
                from: storage.admin,
                responseAddress: msg.responseDestination,
                forwardTonAmount: msg.forwardTonAmount,
                forwardPayload: beginCell().endCell().beginParse(),
            };
            storage.totalSupply += msg.amount;
            storage.save();
            val outMsg = createMessage({
                bounce: BounceMode.NoBounce,
                value: in.valueCoins - ton("0.03"),
                dest: wallet,
                body,
            });
            outMsg.send(SEND_MODE_REGULAR);
        }

        JettonBurnNotification => {
            assert (msg.amount > 0) throw Errors.FIXTURE_SOOTH_MASTER_AMOUNT_NON_POSITIVE;
            val senderWallet = calculateWalletDeploy(
                msg.sender,
                contract.getAddress(),
                storage.walletCode,
                msg.sender.getWorkchain(),
            ).calculateAddress();
            assert (
                in.senderAddress == senderWallet
            ) throw Errors.FIXTURE_SOOTH_MASTER_SENDER_NOT_WALLET;
            assert (
                storage.totalSupply >= msg.amount
            ) throw Errors.FIXTURE_SOOTH_MASTER_INSUFFICIENT_SUPPLY;
            storage.totalSupply -= msg.amount;
            storage.save();
        }

        else => {
            assert (in.body.isEmpty()) throw 0xffff;
        }
    }
}

struct WalletStorage {
    balance: coins
    owner: address
    jettonMaster: address
    walletCode: cell
}

fun calculateWalletDeploy(
    owner: address,
    jettonMaster: address,
    walletCode: cell,
    workchain: int8,
): AutoDeployAddress {
    val data: WalletStorage = {
        balance: 0,
        owner,
        jettonMaster,
        walletCode,
    };
    return { workchain, stateInit: { code: walletCode, data: data.toCell() } };
}

get fun get_jetton_data() {
    val storage = lazy Storage.load();
    return (storage.totalSupply, true, storage.admin, storage.content, storage.walletCode);
}

get fun get_wallet_address(owner: address) {
    val storage = lazy Storage.load();
    return calculateWalletDeploy(
        owner,
        contract.getAddress(),
        storage.walletCode,
        owner.getWorkchain(),
    ).calculateAddress();
}
