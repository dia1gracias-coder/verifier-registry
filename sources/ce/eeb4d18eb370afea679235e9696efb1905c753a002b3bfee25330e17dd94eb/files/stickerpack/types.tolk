import "@stdlib/tvm-dicts"
import "@stdlib/common"
import "../common/const"

fun initOperationsData(isBuy: bool): OperationsData {
    return OperationsData{
        buy: isBuy,
        coinsValue: 0,
        fees: 0,
        items: 0,
        prices: createEmptyDict(),
    };
}

struct OperationsData {
    buy: bool;
    coinsValue: coins;
    fees: coins;
    items: uint16;
    prices: dict;
}

fun OperationsData.AddItem(mutate self, price:coins, fees: coins) {
    self.items += 1;
    self.coinsValue += price;
    self.fees += fees;
    self.prices.uDictSet(
        16,
        self.items,
        beginCell().storeUint(price, 256).endCell().beginParse(),
    );
}

fun OperationsData.SendLog(self, topic:uint248 | bits248) {
    var mainBuilder = beginCell()
        .storeBool(self.buy)
        .storeCoins(self.coinsValue)
        .storeCoins(self.fees)
        .storeUint(self.items, 16);

    var pricesBuilder = beginCell();
    var i: uint16 = 1;
    while (i <= self.items) {
        var (priceSlice: slice?, found: bool) = self.prices.uDictGet(16, i);
        if (found && priceSlice != null) {
            var price = priceSlice!!.loadUint(256);
            pricesBuilder = pricesBuilder.storeCoins(price);
        }
        i += 1;
    }
    mainBuilder = mainBuilder.storeRef(pricesBuilder.endCell());
    val emitMsg = createExternalLogMessage({
        dest: ExtOutLogBucket{
            topic: topic,
        },
        body: mainBuilder.endCell(),
    });
    emitMsg.send(SEND_MODE_REGULAR);
}


struct AdminStopLog {
    stopped: bool;
}
