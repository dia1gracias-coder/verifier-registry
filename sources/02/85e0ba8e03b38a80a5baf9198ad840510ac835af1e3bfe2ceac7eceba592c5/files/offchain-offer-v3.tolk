import "@stdlib/gas-payments"
import "@stdlib/tvm-dicts"

tolk 1.0

const MAGIC_GAS_PRICE = ton("0.008")

struct Fees {
    marketpalceAddress: address
    marketpalceFeeAddress: address
    royaltyAddress: address

    feeFactor: uint16
    feeBase: uint16

    royaltyFactor: uint16
    royaltyBase: uint16
}

struct (0x00) CollectionTarget {
    collectionAddress: address
    attributes: cell
}

struct (0x01) NftTarget {
    nftAddress: address
}

type OfferTarget = CollectionTarget | NftTarget

struct StaticCell {
    createdAt: uint32
    target: OfferTarget
}

struct Storage {
    publicKey: uint256
    ownerAddress: address
    isComplete: bool
    nftPrice: coins
    maxCount: uint20
    boughtCount: uint20
    finishAt: uint32
    fees: Cell<Fees>
    lastCleaned: uint64
    queryIds: dict
    static: Cell<StaticCell>
}

struct (0x00000000) DeployMsg {

}

struct (0x9E548F0A) CancelMsg {
    queryId: uint64
}

struct (0x5CD0FA66) ChangePriceMsg {
    queryId: uint64
    newPrice: coins
}

struct (0x0000022b) MarketaplceEmergencyMsg {
    queryId: uint64
    mode: uint8
    message: cell
}

struct (0xA8A9ADA5) OfferWasCancelled {
    queryId: uint64
}

struct ChargeData {
    sellerAddress: address
    nftAddress: address
}

struct ChargeRequest {
    // 512 bit for sign
    queryId: uint64 // 567 bit
    price: coins // 703
    myAddress: address // 970
    comment: cell
    t: Cell<ChargeData>
}

type AllowedMessage = DeployMsg | CancelMsg | MarketaplceEmergencyMsg | ChangePriceMsg

// load contract data from the persistent storage
fun Storage.load() {
    return Storage.fromCell(contract.getData())
}

// save contract data into the persistent storage
fun Storage.save(self) {
    contract.setData(self.toCell())
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessage.fromSlice(in.body);
    match (msg) {
        DeployMsg => {
            var storage = lazy Storage.load();
            val expectedBalance = (storage.maxCount * (storage.nftPrice + MAGIC_GAS_PRICE));
            val balance = contract.getOriginalBalance() + in.valueCoins;
            assert (balance > expectedBalance) throw 2001;
            assert (storage.lastCleaned == 0) throw 2002;
            assert (storage.ownerAddress == in.senderAddress) throw 2003;
            storage.lastCleaned = 1;
            storage.save();
        }
        CancelMsg => {
            var storage = lazy Storage.load();
            assert (storage.isComplete == false) throw 3002;
            if (storage.ownerAddress != in.senderAddress) {
                val fee = storage.fees.load();
                if (fee.marketpalceAddress != in.senderAddress) {
                    throw 3003;
                }
            }
            val reply = createMessage({
                bounce: false,
                value: 0,
                dest: storage.ownerAddress,
                body: OfferWasCancelled {
                    queryId: msg.queryId,
                }
            });
            reply.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
            storage.isComplete = true;
            storage.finishAt = blockchain.now();
            storage.save();
        }
        MarketaplceEmergencyMsg => {
            val storage = lazy Storage.load();
            val fees = storage.fees.load();
            assert (fees.marketpalceAddress == in.senderAddress) throw 4001;
            assert (storage.isComplete == true) throw 4002;
            assert (storage.finishAt < blockchain.now() - 30) throw 4003; // for unexpected quick actions
            val mesage = msg.message;
            val mode = msg.mode;
            assert ((mode & SEND_MODE_DESTROY) != SEND_MODE_DESTROY) throw 4004;
            var m: OutMessage = {
                messageCell: mesage,
            };
            m.send(mode);
        }
        ChangePriceMsg => {
            var storage = lazy Storage.load();
            assert (storage.isComplete == false) throw 6001;
            assert (storage.ownerAddress == in.senderAddress) throw 6002;
            storage.nftPrice = msg.newPrice;
            val balance = contract.getOriginalBalance() + in.valueCoins;
            storage.maxCount = (balance) / (msg.newPrice + MAGIC_GAS_PRICE);
            storage.save();
        }
        else => {
            throw 0xffff;
        }
    }
}

@inline
fun calcFees(price: int, fees: Fees) {
    val fee = fees.feeBase == 0 ? 0 : mulDivFloor(price, fees.feeFactor, fees.feeBase);
    val rlt = fees.royaltyBase == 0 ? 0 : mulDivFloor(price, fees.royaltyFactor, fees.royaltyBase);
    val profit = price - fee - rlt;
    return (profit, fee, rlt)
}

fun onExternalMessage(inMsg: slice) {
    var storage = lazy Storage.load();
    val opCode = inMsg.loadUint(8);
    if (opCode == 43) {
        val largeBalance = contract.getOriginalBalance() > (storage.nftPrice + MAGIC_GAS_PRICE);
        if (largeBalance) {
            assert (storage.finishAt < blockchain.now()) throw 1001;
        }
        assert (storage.isComplete == false) throw 1002;
        acceptExternalMessage();
        storage.isComplete = true;
        storage.save();
        val dieMsg = createMessage({
            bounce: false,
            value: 0,
            dest: storage.ownerAddress,
        });
        dieMsg.send(SEND_MODE_IGNORE_ERRORS | SEND_MODE_CARRY_ALL_BALANCE);
        return;
    } else if (opCode == 44) {
        val signature = inMsg.loadBits(512);
        val isValid = isSignatureValid(inMsg.hash(), signature, storage.publicKey);
        assert (isValid) throw 109;
        val validUntil = inMsg.loadUint(32);
        val targetAddress: address = inMsg.loadAddress();
        assert (validUntil > blockchain.now()) throw 113;
        assert (targetAddress == contract.getAddress()) throw 115;
        assert (storage.isComplete == false) throw 1002;
        acceptExternalMessage();
        storage.isComplete = true;
        storage.save();
        val dieMsg = createMessage({
            bounce: false,
            value: 0,
            dest: storage.ownerAddress,
        });
        dieMsg.send(SEND_MODE_IGNORE_ERRORS | SEND_MODE_CARRY_ALL_BALANCE);
        return;
    } else if (opCode != 143) {
        throw 0xFFFF;
    }
    val signature = inMsg.loadBits(512);
    val pk = storage.publicKey;
    val isValid = isSignatureValid(inMsg.hash(), signature, pk);
    assert (isValid) throw 109;



    val msg = lazy ChargeRequest.fromSlice(inMsg);
    val (_, duplicate) = storage.queryIds.uDictGet(64, msg.queryId);
    assert (!duplicate) throw 105;
    storage.queryIds.uDictSetBuilder(64, msg.queryId, beginCell());
    val limit = blockchain.now() << 32;
    assert (msg.queryId > limit) throw 113;

    assert (msg.price == storage.nftPrice) throw 107;
    assert (msg.myAddress == contract.getAddress()) throw 115;
    assert (storage.boughtCount < storage.maxCount) throw 108;
    assert (blockchain.now() < storage.finishAt) throw 109;
    assert (!storage.isComplete) throw 110;
    assert ((contract.getOriginalBalance() - MAGIC_GAS_PRICE) > msg.price) throw 111;


    val price = storage.nftPrice;
    val fees = storage.fees.load();
    var (profit, fee, rlt) = calcFees(price, fees);
    assert (profit > 0) throw 112;
    val bill = msg.t.load();

    val static = storage.static.load();
    match (static.target) {
        NftTarget => {
            assert (bill.nftAddress == static.target.nftAddress) throw 116;
        }
        CollectionTarget => {}
    }

    acceptExternalMessage();

    var clearLimit = 7;
    val bound = (blockchain.now() - 64) << 32;
    var s = storage.queryIds;
    while (clearLimit > 0) {
        val (k, _, has) = s.uDictDeleteFirstAndGet(64);
        if (has && (k != null) && (k < bound)) {
            clearLimit = clearLimit - 1;
            storage.lastCleaned = k;
            storage.queryIds = s;
        } else {
            clearLimit = 0;
        }
    }
    storage.boughtCount = storage.boughtCount + 1;

    storage.save();


    val profitMsg = createMessage({
        bounce: false,
        value: profit,
        dest: bill.sellerAddress,
        body: msg.comment,
    });
    profitMsg.send(SEND_MODE_IGNORE_ERRORS | SEND_MODE_PAY_FEES_SEPARATELY);

    if (fee > 0) {
        val feeMsg = createMessage({
            bounce: false,
            value: fee,
            dest: fees.marketpalceFeeAddress,
        });
        feeMsg.send(SEND_MODE_IGNORE_ERRORS | SEND_MODE_PAY_FEES_SEPARATELY);
    }
    if (rlt > 0) {
        val feeMsg = createMessage({
            bounce: false,
            value: rlt,
            dest: fees.royaltyAddress,
        });
        feeMsg.send(SEND_MODE_IGNORE_ERRORS | SEND_MODE_PAY_FEES_SEPARATELY);
    }
}

fun onBouncedMessage(in: InMessageBounced) {

}


get fun get_offchain_offer_v2() {
    var storage = lazy Storage.load();
    var fees = lazy storage.fees.load();
    var static = lazy storage.static.load();

    var (profit, fee, rlt) = calcFees(storage.nftPrice, fees);

    var collectionAddress: address? = null;
    var attributes: cell = beginCell().endCell();
    var nftAddress: address? = null;

    match (static.target) {
        CollectionTarget => {
            collectionAddress = static.target.collectionAddress;
            attributes = static.target.attributes;
        }
        NftTarget => {
            nftAddress = static.target.nftAddress;
        }
    }

    return (
        storage.lastCleaned == 0 ? true : storage.isComplete,
        storage.ownerAddress,
        static.createdAt,
        storage.finishAt,
        storage.publicKey,
        storage.nftPrice,
        storage.maxCount,
        storage.boughtCount,

        fees.marketpalceAddress,
        fees.marketpalceFeeAddress,
        fees.royaltyAddress,
        fees.feeFactor,
        fees.feeBase,
        fees.royaltyFactor,
        fees.royaltyBase,
        profit,
        attributes,
        collectionAddress,
        nftAddress,
    )
}
