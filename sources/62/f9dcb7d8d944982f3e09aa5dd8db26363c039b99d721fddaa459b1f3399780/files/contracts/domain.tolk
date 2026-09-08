import "@stdlib/strings"
import "@stdlib/tvm-dicts"
import "constants"
import "errors"

// ============================================================
//  Reading the domain out of a jetton transfer comment
// ============================================================

/// Glues a text payload that may be spread over a chain of cells into one
/// slice. Returns `(text, ok)` instead of throwing: this runs while handling a
/// non-bounceable jetton notification, where an exception would strand the
/// sender's GRM inside the collection forever.
fun readText(payload: slice): (slice, bool) {
    var b = beginCell();
    var s = payload;
    var totalBits = 0;
    var ok = true;
    var done = false;

    while (!done) {
        val bits = s.remainingBitsCount();
        // 1016 bits = 127 bytes, the most a single cell can hold
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

/// "alice.grm" -> "alice", "alice" -> "alice".
/// A bare domain can never contain a dot, so the suffix is unambiguous.
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

/// Length, byte alignment and alphabet in one pass.
/// Allowed: a-z, 0-9 and '-', where '-' may be neither first nor last.
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

/// Length in bits of the first label of "grm\0alice\0"-style subdomain.
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

// ============================================================
//  Pricing — the starting price of a domain
//  This is the only place prices are defined.
// ============================================================

/// Result is in whole GRM.
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
    return 10; // 10 characters and longer
}

/// Starting price in nanoGRM. Takes a character count, not a bit length, so
/// that no division feeds the multiplication.
fun getMinPrice(charCount: int): coins {
    return (getMinPriceGrm(charCount) * GRM_UNIT) as coins;
}

/// Number of characters in a validated domain.
fun domainLength(domain: slice): int {
    return domain.remainingBitsCount() / 8;
}

// ============================================================
//  On-chain metadata (TEP-64 snake format)
// ============================================================

/// Wraps text into a TEP-64 on-chain metadata value: a 0x00 tag followed by
/// snake-encoded content. `storeString` handles the cell chaining itself, so
/// arbitrarily long values are safe.
fun snakeValue(text: string): cell {
    return beginCell().storeUint(0, 8).storeString(text).endCell();
}

/// The metadata every domain is born with, derived entirely from its own name.
/// Rebuilt from scratch whenever a domain goes back to auction, so an expired
/// domain never hands its records to the next owner.
fun buildInitialContent(domainCell: cell): cell {
    // a domain cell holds plain bytes with no references, which is exactly
    // what a snake-encoded string is
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
    b.storeUint(0, 8); // on-chain metadata tag
    b.storeMaybeRef(records);
    return b.endCell();
}

/// name, description and image are computed from the domain and are read-only.
fun isReservedRecord(key: int): bool {
    return key == KEY_NAME || key == KEY_DESCRIPTION || key == KEY_IMAGE;
}
