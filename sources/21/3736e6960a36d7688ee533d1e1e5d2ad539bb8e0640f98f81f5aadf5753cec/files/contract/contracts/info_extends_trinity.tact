import "./structs_trinity.tact";

// Type User - 1 - direct user

struct ResFindPlace {
    line: Int as uint8;
    branch: Int as uint8;
    place: Int as uint8;
    upperId: Int? as uint64;
}

extends mutates fun placeUserInMatrix(self: TrinityInfo, userId: Int, typeUser: Int): ResFindPlace {
    let place: Int = self.matrix.allocateNextFreePlace();
    let placeInfo: ResFindPlace = self.matrix.getPlacementInfo(place);
    self.matrix.recordPlace(place, userId, typeUser);
    return placeInfo;
}

inline extends fun getPlacementInfo(self: TrinityMatrix, place: Int): ResFindPlace {
    if (place >= 1 && place <= 3) {
        return ResFindPlace {line: 1, branch: place, place: place, upperId: null};
    } else if (place >= 4 && place <= 12) {
        let branch: Int = ((place - 4) / 3) + 1;
        let upperPlace: Int = ((place - 4) % 3) + 1;
        let userId = self.places.get(upperPlace)!!.userId;
        return ResFindPlace {line: 2, branch: branch, place: place, upperId: userId};
    } else {
        let branch = ((place - 13) / 9) + 1;
        let upperPlace: Int = 4 + (place - 13) % 9;
        let userId = self.places.get(upperPlace)!!.userId;
        return ResFindPlace {line: 3, branch: branch, place: place, upperId: userId};
    }
}

inline extends mutates fun allocateNextFreePlace(self: TrinityMatrix): Int {
    let place: Int = self.firstFreePlace;

    while (place < 39 && self.places.get(place) != null) {
        place += 1;
    }

    self.firstFreePlace = place + 1;
    return place;
}

inline extends mutates fun findPlaceInSecondLine(self: TrinityInfo, userPlaceInFirstLine: Int, upperId: Int): Int {
    let upperIdPlace: Int? = self.matrix.userPlace.get(upperId); // Place in first line

    if(upperIdPlace == null) {
        return 0;
    }

    let place: Int = userPlaceInFirstLine * 3 + upperIdPlace!!;
    return place;
}

inline extends mutates fun findPlaceInThirdLine(self: TrinityInfo, userPlaceInFirstLine: Int, upperId: Int): Int {
    let upperIdPlace: Int? = self.matrix.userPlace.get(upperId); // Place in second line

    if(upperIdPlace == null) {
        return 0;
    }

    let place: Int = userPlaceInFirstLine * 9 + upperIdPlace!!;
    return place;
}

inline extends mutates fun incrementLineBonusForId1(self: TrinityInfo, place: Int, amount: Int, isRecycle: Bool) {
    if (place <= 3) {
        self.notAvailableFirstLineBonus += amount;
        self.lineProfit += amount;

        if (place == 3) {
            self.canClaimFirstLineBonus += self.notAvailableFirstLineBonus;
            self.notAvailableFirstLineBonus = 0;
        }
    } else if (place >= 4 && place <= 12) {
        self.notAvailableSecondLineBonus += amount;
        self.lineProfit += amount;

        if (self.matrix.isFullSecondLine()) {
            self.canClaimSecondLineBonus += self.notAvailableSecondLineBonus;
            self.notAvailableSecondLineBonus = 0;
        }

    } else {
        self.notAvailableThirdLineBonus += amount;
        self.lineProfit += amount;

        if (isRecycle) {
            self.canClaimThirdLineBonus += self.notAvailableThirdLineBonus;
            self.notAvailableThirdLineBonus = 0;
        }
    }
}

extends mutates fun incrementLineBonus(self: TrinityInfo, place: Int, amount: Int, isRecycle: Bool) {
    if (place > 1 && place <= 3) {
        self.notAvailableFirstLineBonus += amount;
        self.lineProfit += amount;

        if (place == 3) {
            self.canClaimFirstLineBonus += self.notAvailableFirstLineBonus;
            self.notAvailableFirstLineBonus = 0;
        }
    } else if (place > 4 && place <= 12) {
        self.notAvailableSecondLineBonus += amount;
        self.lineProfit += amount;

        if (self.matrix.isFullSecondLine()) {
            self.canClaimSecondLineBonus += self.notAvailableSecondLineBonus;
            self.notAvailableSecondLineBonus = 0;
        }
    } else if (place > 13 && place <= 39) {
        self.notAvailableThirdLineBonus += amount;
        self.lineProfit += amount;

        if (isRecycle) {
            self.canClaimThirdLineBonus += self.notAvailableThirdLineBonus;
            self.notAvailableThirdLineBonus = 0;
        }
    } else {
        self.holdValue += amount;
    }
}

inline extends mutates fun recordPlace(self: TrinityMatrix, place: Int, userId: Int, placeType: Int) {
    self.places.set(place, Place {userId: userId, type: placeType});
    
    // Записываем места пользователей только на первой и второй линии, для третьей линии не нужно, так как она последняя
    if place <= 12 {
        self.userPlace.set(userId, place);
    }
}

extends mutates fun resetInfoForReinvest(self: TrinityInfo) {
    self.reinvestCount += 1;
    self.upperAddress = null;
    self.holdValue = ton("0.0");
    
    self.matrix = TrinityMatrix{};
}

inline extends mutates fun updateUpperAddress(self: TrinityInfo, upperAddress: Address) {
    self.upperAddress = upperAddress;
}

inline extends fun isFrozenLevel(self: TrinityInfo, currentLevel: Int, lastLevel: Int): Bool {
    return currentLevel < 12 && currentLevel == lastLevel && self.reinvestCount > 1;
}

inline extends fun isFullSecondLine(self: TrinityMatrix): Bool {
    let count: Int = 0;

    while (count < 3) {
        if (self.places.get(count + 10) == null) {
            return false;
        }

        count += 1;
    }

    return true;
}

inline extends fun isFullThirdLine(self: TrinityMatrix): Bool {
    let count: Int = 0;

    while (count < 9) {
        if (self.places.get(count + 31) == null) {
            return false;
        }

        count += 1;
    }

    return true;
}