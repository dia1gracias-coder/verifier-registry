struct Place {
    userId: Int as uint64;
    type: Int as uint8;
}

struct TrinityMatrix {
    places: map<Int as uint8, Place> = emptyMap();
    userPlace: map<Int as uint64, Int as uint8> = emptyMap();
    firstFreePlace: Int as uint8 = 1;
}

struct TrinityInfo {
    matrixProfit: Int as coins = 0;
    lineProfit: Int as coins = 0;
    lostProfit: Int as coins = 0;
    holdValue: Int as coins = 0;
    nextLevelValue: Int as coins = 0;

    canClaimFirstLineBonus: Int as coins = 0;
    canClaimSecondLineBonus: Int as coins = 0;
    canClaimThirdLineBonus: Int as coins = 0;

    notAvailableFirstLineBonus: Int as coins = 0;
    notAvailableSecondLineBonus: Int as coins = 0;
    notAvailableThirdLineBonus: Int as coins = 0;

    reinvestCount: Int as uint16 = 1;
    upperAddress: Address? = null;
    matrix: TrinityMatrix = TrinityMatrix{};
}

struct STryActivateOneLevel {
    userId: Int as uint64;
    levelNumber: Int as uint8;
    isEarly: Bool;
}

struct STryActivateManyLevels {
    userId: Int as uint64;
    startLevelNumber: Int as uint8;
    finishLevelNumber: Int as uint8;
    isEarly: Bool;
}
