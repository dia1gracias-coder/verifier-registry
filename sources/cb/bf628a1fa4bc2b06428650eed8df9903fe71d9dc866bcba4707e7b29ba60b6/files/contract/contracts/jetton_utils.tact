// ==================== Common ====================

@name(cell_hash)
native hashCell(c: Cell): Int;

fun workchain(): Int {
  return 0;
}

fun calculateJettonWalletAddress(stateInit: Cell): Address {
    return beginCell()
        .storeUint(4, 3)
        .storeInt(workchain(), 8)
        .storeUint(hashCell(stateInit), 256)
        .asSlice()
        .loadAddress();
}

fun calculateUserJettonWalletAddress(ownerAddress: Address, jettonMinterAddress: Address, jettonWalletCode: Cell, version: Int): Address {
  if (version == 1) {
    return calculateJettonWalletAddress(packJettonWalletStateInit_v1(ownerAddress, jettonMinterAddress, jettonWalletCode));
  }
  return calculateJettonWalletAddress(packJettonWalletStateInit_v2(ownerAddress, jettonMinterAddress, jettonWalletCode));
}

// ==================== Implementation v1 ====================

@name(store_maybe_ref)
native storeMaybeRef(builder: Builder, c: Cell): Builder;

fun packJettonWalletData_v1(status: Int, balance: Int, ownerAddress: Address, jettonMinterAddress: Address): Cell {
    return beginCell()
        .storeUint(status, 4)
        .storeCoins(balance)
        .storeAddress(ownerAddress)
        .storeAddress(jettonMinterAddress)
        .endCell();
}

fun packJettonWalletStateInit_v1(ownerAddress: Address, jettonMinterAddress: Address, jettonWalletCode: Cell): Cell {
    let builder: Builder = beginCell();
    builder = builder.storeUint(0, 2);
    builder = storeMaybeRef(builder, jettonWalletCode);
    builder = storeMaybeRef(builder, packJettonWalletData_v1(0, 0, ownerAddress, jettonMinterAddress));
    builder = builder.storeUint(0, 1);
    return builder.endCell();
}

// ==================== Implementation v2 ====================

@name(store_dict)
native storeDict(builder: Builder, c: Cell): Builder;

fun packJettonWalletData_v2(balance: Int, ownerAddress: Address, jettonMinterAddress: Address, jettonWalletCode: Cell): Cell {
    return beginCell()
        .storeCoins(balance)
        .storeAddress(ownerAddress)
        .storeAddress(jettonMinterAddress)
        .storeRef(jettonWalletCode)
        .endCell();
}

fun packJettonWalletStateInit_v2(ownerAddress: Address, jettonMinterAddress: Address, jettonWalletCode: Cell): Cell {
    let builder: Builder = beginCell();
    builder = builder.storeUint(0, 2);
    builder = storeDict(builder, jettonWalletCode);
    builder = storeDict(builder, packJettonWalletData_v2(0, ownerAddress, jettonMinterAddress, jettonWalletCode));
    builder = builder.storeUint(0, 1);
    return builder.endCell();
}
