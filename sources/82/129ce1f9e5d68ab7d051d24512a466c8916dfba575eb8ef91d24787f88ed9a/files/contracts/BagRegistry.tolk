import "errors.tolk"
import "events.tolk"
import "messages.tolk"
import "storage.tolk"

import "gen/BagItem.code"

const ITEM_FUNDING: coins = ton("0.07")
const MIN_REGISTRY_BALANCE: coins = ton("0.05")
const MIN_ADD_BAG_VALUE: coins = ton("0.1")

const OP_ADD_BAG: int = 0x41444247

const MAX_USER_CELL_BITS: int = 16384
const MAX_USER_CELL_CELLS: int = 256

fun assertUserCellBounded(c: cell) {
    val (cellsOpt, bitsOpt, _, _) = c.beginParse().calculateSize(MAX_USER_CELL_CELLS);
    val cells = cellsOpt ?? (MAX_USER_CELL_CELLS + 1);
    val bits = bitsOpt ?? (MAX_USER_CELL_BITS + 1);
    assert (cells <= MAX_USER_CELL_CELLS) throw BagError.MetadataTooLarge;
    assert (bits <= MAX_USER_CELL_BITS) throw BagError.MetadataTooLarge;
}

contract BagRegistry {
    author: "piracy.ton"
    version: "2.0.0"
    description: "Owner-less master registry of TON Storage bags"

    storage: BagRegistryStorage
    incomingMessages: BagRegistryMessage
    thrownErrors: BagError
}

fun deployBagItem(bagIndex: uint64, initParams: BagItemInitParams) {
    val deployMsg = createMessage({
        bounce: BounceMode.NoBounce,
        dest: calcDeployedBagItem(bagIndex, contract.getAddress(), bagItemCompiledCode()),
        value: ITEM_FUNDING,
        body: initParams,
    });
    deployMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun refundSurplusTo(uploader: address) {
    val refundMsg = createMessage({
        bounce: BounceMode.NoBounce,
        dest: uploader,
        value: 0,
    });
    // SAFETY: mode 128 carries all remaining balance and runs only after
    // reserveToncoinsOnBalance(MIN_REGISTRY_BALANCE, EXACT), so the registry
    // can never be drained below its rent reserve. Mode 2 ignores action
    // errors so a failed refund cannot revert the committed state changes.
    refundMsg.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS);
}

fun onInternalMessage(in: InMessage) {
    if (in.body.isEmpty()) {
        return;
    }

    assert (in.body.preloadUint(32) == OP_ADD_BAG) throw 0xFFFF;

    val msg = AddBag.fromSlice(in.body);

    assert (in.valueCoins >= MIN_ADD_BAG_VALUE) throw BagError.InsufficientValue;
    assert (msg.bagId != 0) throw BagError.InvalidBagId;
    assert (msg.category <= 5) throw BagError.InvalidCategory;

    assertUserCellBounded(msg.name);
    assertUserCellBounded(msg.metadata as cell);

    var storage = BagRegistryStorage.load();
    val bagIndex = storage.nextBagIndex;
    val now = blockchain.now() as uint64;

    val initParams: BagItemInitParams = {
        bagId: msg.bagId,
        category: msg.category,
        uploaderAddress: in.senderAddress,
        timestamp: now,
        name: msg.name,
        metadata: msg.metadata,
    };

    deployBagItem(bagIndex, initParams);

    emitBagIndexed({
        bagIndex,
        bagId: msg.bagId,
        category: msg.category,
        uploader: in.senderAddress,
        timestamp: now,
        name: msg.name,
    });

    reserveToncoinsOnBalance(MIN_REGISTRY_BALANCE, RESERVE_MODE_EXACT_AMOUNT);
    refundSurplusTo(in.senderAddress);

    storage.nextBagIndex = bagIndex + 1;
    storage.save();
}

get fun get_total(): int {
    val storage = BagRegistryStorage.load();
    return storage.nextBagIndex;
}

get fun get_bag_address(bagIndex: int): address {
    val storage = BagRegistryStorage.load();
    assert (bagIndex >= 0 && bagIndex < storage.nextBagIndex) throw BagError.IndexOutOfRange;
    val deployed = calcDeployedBagItem(
        bagIndex as uint64,
        contract.getAddress(),
        bagItemCompiledCode(),
    );
    return deployed.calculateAddress();
}

get fun get_balance(): int {
    return contract.getOriginalBalance();
}

get fun get_item_code(): cell {
    return bagItemCompiledCode();
}
