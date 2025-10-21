import "@stdlib/common"

struct Storage {
    currentSupply: uint16;
    packThreshold: uint16;
    priceCoefficient: uint16;
    priceAlgo: uint4;
    protocolFeeBuy: uint16;
    protocolFeeSell: uint16;
    startTime: uint32;
    isStopped: bool;
    contractId: uint128;

    startPrice: coins;
    endPrice: coins;
    protocolFeeBalance: coins;
    beneficiaryBalance: coins;

    userHoldingCode: cell;
}

struct ExtendedStorage {
    factoryAddress: address;
    beneficiaryAddress: address;
    protocolFeeAddress: address;
}

@inline
fun loadStorage(): Storage {
    val data = contract.getData();
    var slice = data.beginParse();
    return Storage{
        currentSupply: slice.loadUint(16),
        packThreshold: slice.loadUint(16),
        priceCoefficient: slice.loadUint(16),
        priceAlgo: slice.loadUint(4),
        protocolFeeBuy: slice.loadUint(16),
        protocolFeeSell: slice.loadUint(16),
        startTime: slice.loadUint(32),
        isStopped: slice.loadBool(),
        contractId: slice.loadUint(128),

        startPrice: slice.loadCoins(),
        endPrice: slice.loadCoins(),
        protocolFeeBalance: slice.loadCoins(),
        beneficiaryBalance: slice.loadCoins(),
        userHoldingCode: slice.loadRef(),
    }
}

fun loadExtendedStorage(): ExtendedStorage {
    val data = contract.getData();
    var slice = data.beginParse();
    // skipping mainStorageData
    slice.skipBits(16 + 16 + 16 + 4 + 16 + 16 + 32 + 1 + 128);
    slice.loadCoins();   // startPrice
    slice.loadCoins();   // endPrice
    slice.loadCoins();   // protocolFeeBalance
    slice.loadCoins();   // beneficiaryBalance
    slice.loadRef();     // userHoldingCode
    var extendedCell = slice.loadRef();

    var extendedSlice = extendedCell.beginParse();
    return ExtendedStorage{
        factoryAddress: extendedSlice.loadAddress(),
        beneficiaryAddress: extendedSlice.loadAddress(),
        protocolFeeAddress: extendedSlice.loadAddress()
    };
}

@inline
fun Storage.Save(self) {
    val extended = loadExtendedStorage();
    val extendedCell = beginCell()
        .storeAddress(extended.factoryAddress)
        .storeAddress(extended.beneficiaryAddress)
        .storeAddress(extended.protocolFeeAddress)
        .endCell();

    val mainCell = beginCell()
        .storeUint(self.currentSupply, 16)
        .storeUint(self.packThreshold, 16)
        .storeUint(self.priceCoefficient, 16)
        .storeUint(self.priceAlgo, 4)
        .storeUint(self.protocolFeeBuy, 16)
        .storeUint(self.protocolFeeSell, 16)
        .storeUint(self.startTime, 32)
        .storeBool(self.isStopped)
        .storeUint(self.contractId, 128)
        .storeCoins(self.startPrice)
        .storeCoins(self.endPrice)
        .storeCoins(self.protocolFeeBalance)
        .storeCoins(self.beneficiaryBalance)
        .storeRef(self.userHoldingCode)
        .storeRef(extendedCell)
        .endCell();

    contract.setData(mainCell);
    return extended;
}