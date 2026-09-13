import "@stdlib/strings"
import "@stdlib/tvm-dicts"
import "constants"
import "errors"


fun readText(payload: slice): (slice, bool) {
    var b = beginCell();
    var s = payload;
    var totalBits = 0;
    var ok = true;
    var done = false;
    var hops = 0;

    while (!done) {
        if (hops > MAX_TEXT_HOPS) {
            return (createEmptySlice(), false);
        }
        hops += 1;
        val bits = s.remainingBitsCount();
        if (totalBits + bits > 1016) {
            ok = false;
            done = true;
        } else {
            b.storeSlice(s.loadBits(bits));
            totalBits += bits;

            val refs = s.remainingRefsCount();
            if (refs == 0) {
                done = true;
            } else if (refs > 1) {
                ok = false;
                done = true;
            } else {
                s = s.loadRef().beginParse();
            }
        }
    }

    if (!ok) {
        return (createEmptySlice(), false);
    }
    return (b.endCell().beginParse(), true);
}

fun stripTld(domain: slice): slice {
    val len = domain.remainingBitsCount();
    if (len <= 32) {
        return domain;
    }
    if (domain.getLastBits(32).preloadUint(32) == TLD_SUFFIX) {
        return domain.getFirstBits(len - 32);
    }
    return domain;
}

fun isValidDomain(domain: slice): bool {
    val len = domain.remainingBitsCount();
    if (len % 8 != 0) {
        return false;
    }
    if (len < MIN_DOMAIN_LENGTH * 8 || len > MAX_DOMAIN_LENGTH * 8) {
        return false;
    }

    var s = domain;
    var i = 0;
    while (i < len) {
        val ch = s.loadUint(8);
        val isHyphen = ch == 45;
        val isDigit = ch >= 48 && ch <= 57;
        val isLower = ch >= 97 && ch <= 122;
        if (!((isHyphen && i > 0 && i < len - 8) || isDigit || isLower)) {
            return false;
        }
        i += 8;
    }
    return true;
}

fun getTopDomainBits(subdomain: slice): int {
    var s = subdomain;
    var i = 0;
    var done = false;
    while (!done) {
        if (s.loadUint(8) == 0) {
            done = true;
        } else {
            i += 8;
        }
    }
    assert (i != 0) throw Errors.DnsNoZeroByte;
    return i;
}


fun getMinPriceGrm(charCount: int): int {
    if (charCount <= 1) {
        return 100000;
    }
    if (charCount == 2) {
        return 30000;
    }
    if (charCount == 3) {
        return 5000;
    }
    if (charCount == 4) {
        return 300;
    }
    if (charCount == 5) {
        return 100;
    }
    if (charCount == 6) {
        return 70;
    }
    if (charCount == 7) {
        return 50;
    }
    if (charCount == 8) {
        return 30;
    }
    if (charCount == 9) {
        return 20;
    }
    return 10;
}

fun getMinPrice(charCount: int): coins {
    return (getMinPriceGrm(charCount) * GRM_UNIT) as coins;
}

fun domainLength(domain: slice): int {
    return domain.remainingBitsCount() / 8;
}


fun snakeValue(text: string): cell {
    return beginCell().storeUint(0, 8).storeString(text).endCell();
}

fun buildInitialContent(domainCell: cell): cell {
    val domainStr = domainCell as unknown as string;

    var name = StringBuilder.create();
    name.append(domainStr);
    name.append(NAME_SUFFIX);

    var image = StringBuilder.create();
    image.append(IMAGE_URL_PREFIX);
    image.append(domainStr);
    image.append(IMAGE_URL_SUFFIX);

    var records = createEmptyDict();
    records.uDictSetRef(256, KEY_NAME, snakeValue(name.build()));
    records.uDictSetRef(256, KEY_IMAGE, snakeValue(image.build()));
    records.uDictSetRef(256, KEY_DESCRIPTION, snakeValue(DOMAIN_DESCRIPTION));

    var b = beginCell();
    b.storeUint(0, 8);
    b.storeMaybeRef(records);
    return b.endCell();
}

fun isReservedRecord(key: int): bool {
    return key == KEY_NAME || key == KEY_DESCRIPTION || key == KEY_IMAGE;
}
