import "@stdlib/strings"
import "errors"
import "types"

const MIN_NAME_LENGTH = 1
const MAX_NAME_LENGTH = 32

const ASCII_HYPHEN = 45
const ASCII_ZERO = 48
const ASCII_NINE = 57
const ASCII_LOWER_A = 97
const ASCII_LOWER_Z = 122

/// Validates the canonical lowercase ASCII representation and returns its byte length.
fun validateCanonicalName(name: string): int {
    assert (name.depth() == 0) throw Errors.InvalidNameEncoding;

    var bytes = name.beginParse();
    val bitLength = bytes.remainingBitsCount();
    assert (bitLength % 8 == 0) throw Errors.InvalidNameEncoding;

    val length = bitLength / 8;
    assert (length >= MIN_NAME_LENGTH && length <= MAX_NAME_LENGTH) throw Errors.InvalidNameLength;

    var index = 0;
    var previousWasHyphen = false;
    repeat (length) {
        val ch = bytes.loadUint(8);
        val isDigit = ch >= ASCII_ZERO && ch <= ASCII_NINE;
        val isLowercaseLetter = ch >= ASCII_LOWER_A && ch <= ASCII_LOWER_Z;
        val isHyphen = ch == ASCII_HYPHEN;

        if (isHyphen) {
            assert (
                index > 0 && index < length - 1 && !previousWasHyphen
            ) throw Errors.InvalidNameCharacter;
        } else {
            assert (isDigit || isLowercaseLetter) throw Errors.InvalidNameCharacter;
        }

        previousWasHyphen = isHyphen;
        index += 1;
    }

    return length;
}

/// SHA-256 of the canonical name bytes. Names are limited to a single cell by validation.
fun canonicalNameHash(name: string): uint256 {
    assert (name.depth() == 0) throw Errors.InvalidNameEncoding;
    return name.beginParse().bitsHash();
}

fun calculateProposalId(
    adminAddress: address,
    governanceEpoch: uint32,
    queryId: uint64,
    action: cell,
): uint256 {
    return beginCell()
        .storeAddress(adminAddress)
        .storeUint(governanceEpoch, 32)
        .storeUint(queryId, 64)
        .storeRef(action)
        .endCell()
        .hash();
}

/// Ordered commitment used for a resumable, pre-launch catalog upload.
fun nextInitialCatalogHash(
    previousHash: uint256,
    index: uint32,
    nameHash: uint256,
    status: uint2,
    price: coins,
    reservedFor: address?,
): uint256 {
    return beginCell()
        .storeUint(previousHash, 256)
        .storeUint(index, 32)
        .storeUint(nameHash, 256)
        .storeUint(status, 2)
        .storeCoins(price)
        .storeAddressOpt(reservedFor)
        .endCell()
        .hash();
}

fun NamePrices.priceForLength(self, length: int): coins {
    if (length == 1) {
        return self.length1;
    }
    if (length == 2) {
        return self.length2;
    }
    if (length == 3) {
        return self.length3;
    }
    if (length == 4) {
        return self.length4;
    }
    if (length == 5) {
        return self.length5;
    }
    if (length == 6) {
        return self.length6;
    }
    if (length <= 12) {
        return self.length7To12;
    }
    return self.length13To32;
}

fun NamePrices.assertValid(self) {
    assert (
        self.length1 > 0 && self.length2 > 0 && self.length3 > 0 && self.length4 > 0 &&
        self.length5 > 0 &&
        self.length6 > 0 &&
        self.length7To12 > 0 &&
        self.length13To32 > 0
    ) throw Errors.InvalidPriceTable;

    assert (
        self.length1 >= self.length2 && self.length2 >= self.length3 &&
        self.length3 >= self.length4 &&
        self.length4 >= self.length5 &&
        self.length5 >= self.length6 &&
        self.length6 >= self.length7To12 &&
        self.length7To12 >= self.length13To32
    ) throw Errors.InvalidPriceTable;
}
