import "./structs.tact";

extends mutates fun findPlaceInMatrix(self: Info, id: Int, fromId: Int, levelNumber: Int, levelPrice: Int, lastLevel: Int): Int {
    let referralType: Int = id == fromId ? 1 : 2;
    let statusCode: Int = 0;

    if (referralType == 1){
        self.personalReferralsCount += 1;
    }

    if (self.matrix.u1 == null) {
        self.matrix.u1 = id;
        self.matrix.u1t = referralType;
        self.wasUseUpperAddress = true;
        statusCode = 1;
    } else if (self.matrix.u2 == null) {
        self.matrix.u2 = id;
        self.matrix.u2t = referralType;
        self.wasUseUpperAddress = true;
        statusCode = 1;
    } else if (self.matrix.u3 == null) {
        self.matrix.u3 = id;
        self.matrix.u3t = referralType;
        statusCode = 21;
    } else if (self.matrix.u4 == null) {
        self.matrix.u4 = id;
        self.matrix.u4t = referralType;
        statusCode = 22;
    } else if (self.matrix.u5 == null) {
        self.matrix.u5 = id;
        self.matrix.u5t = 4;

        if (self.matrix.u6 != null) {
            statusCode = 41;
        } else {
            statusCode = 31;
        }
    } else if (self.matrix.u6 == null) {
        self.matrix.u6 = id;
        self.matrix.u6t = 4;

        if (self.matrix.u5 != null) {
            statusCode = 42;
        } else {
            statusCode = 32;
        }
    }

    if (statusCode == 1 || statusCode == 21 || statusCode == 22) {
        if self.isFrozenLevel(levelNumber, lastLevel) {
            self.incrementLostProfit(levelPrice);
        } else {
            self.incrementProfit(levelPrice);
        }
    }
    
    return statusCode;
}

extends mutates fun findPlaceForOverflowUp(self: Info, id: Int, fromId: Int, levelPrice: Int, isFrozen: Bool): Int {
    let statusCode: Int = 0;

    if (self.matrix.u2 == fromId) {
        if (self.matrix.u4 == null) {
            self.matrix.u4 = id;
            self.matrix.u4t = 2;
            statusCode = 22;
        } else if (self.matrix.u6 == null) {
            self.matrix.u6 = id;
            self.matrix.u6t = 4;
            statusCode = (self.matrix.u5 == null ? 32 : 42);
        }
    } else if (self.matrix.u1 == fromId) {
        if (self.matrix.u3 == null) {
            self.matrix.u3 = id;
            self.matrix.u3t = 2;
            statusCode = 21;
        } else if (self.matrix.u5 == null) {
            self.matrix.u5 = id;
            self.matrix.u5t = 4;
            statusCode = (self.matrix.u6 == null ? 31 : 41);
        }
    }

    if (statusCode == 21 || statusCode == 22) {
        if (isFrozen) {
            self.incrementLostProfit(levelPrice);
        } else {
            self.incrementProfit(levelPrice);
        }
    }

    return statusCode;
}

extends mutates fun findPlaceForOverflowDown(self: Info, id: Int, levelPrice: Int, isFrozen: Bool) {
    if (self.matrix.u1 == null) {
        self.matrix.u1 = id;
        self.matrix.u1t = 3;
    } else if (self.matrix.u2 == null) {
        self.matrix.u2 = id; 
        self.matrix.u2t = 3;
    }

    if (isFrozen) {
        self.incrementLostProfit(levelPrice);
    } else {
        self.incrementProfit(levelPrice);
    }
}

extends mutates fun resetInfoForReinvest(self: Info) {
    self.reinvestCount += 1;

    if (self.nextUpperAddress != null && self.upperAddress != self.nextUpperAddress) {
        self.upperAddress = self.nextUpperAddress;
    }
        
    self.wasUseUpperAddress = false;
    self.matrix = Matrix{};
}

extends mutates fun updateUpperAddress(self: Info, newUpperAddress: Address) {
     if (self.wasUseUpperAddress) {
        self.nextUpperAddress = newUpperAddress;
    } else {
        self.upperAddress = newUpperAddress;
    }
}

extends mutates fun incrementProfit(self: Info, value: Int) {
    self.totalProfit += (value / 2);
}

extends mutates fun incrementLostProfit(self: Info, value: Int) {
    self.lostProfit += (value / 2);
}

extends fun isFrozenLevel(self: Info, currentLevel: Int, lastLevel: Int): Bool {
    return currentLevel < 12 && currentLevel == lastLevel && self.reinvestCount > 1;
}
