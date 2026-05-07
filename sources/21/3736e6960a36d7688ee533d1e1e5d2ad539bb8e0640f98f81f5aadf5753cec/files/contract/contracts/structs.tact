struct Matrix {
    u1: Int? as uint64;
    u1t: Int? as uint8;

    u2: Int? as uint64;
    u2t: Int? as uint8;

    u3: Int? as uint64;
    u3t: Int? as uint8;

    u4: Int? as uint64;
    u4t: Int? as uint8;

    u5: Int? as uint64;
    u5t: Int? as uint8;

    u6: Int? as uint64;
    u6t: Int? as uint8;
}

struct Info {
    totalProfit: Int as coins = ton("0.0");
    lostProfit: Int as coins = ton("0.0");
    reinvestCount: Int as uint16 = 1;
    personalReferralsCount: Int as uint32 = 0;
    wasUseUpperAddress: Bool = false;
    upperAddress: Address?;
    nextUpperAddress: Address?;
    matrix: Matrix = Matrix{};
}
