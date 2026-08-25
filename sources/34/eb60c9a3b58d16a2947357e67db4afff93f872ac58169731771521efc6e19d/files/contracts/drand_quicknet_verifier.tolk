// SPDX-License-Identifier: MIT

// Reusable DOSGRAM drand Quicknet verification library for TVM.
//
// Quicknet uses the RFC 9380 BLS suite with signatures in G1 and the public
// key in G2. TVM's high-level BLS_VERIFY opcode uses the opposite orientation,
// so this verifier performs hash-to-G1 and the pairing equation explicitly.

const QUICKNET_GENESIS = 1692803367;
const QUICKNET_PERIOD = 3;
const CEREMONY_DELAY = 30;

// BLS12-381 base field, little-endian 64-bit limbs.
const P0 = 0xB9FEFFFFFFFFAAAB;
const P1 = 0x1EABFFFEB153FFFF;
const P2 = 0x6730D2A0F6B0F624;
const P3 = 0x64774B84F38512BF;
const P4 = 0x4B1BA7B6434BACD7;
const P5 = 0x1A0111EA397FE69A;
const LIMB_MASK = 0xFFFFFFFFFFFFFFFF;

// "BLS_SIG_BLS12381G1_XMD:SHA-256_SSWU_RO_NUL_" (43 bytes).
const DST_FIRST = 0x424C535F5349475F424C53313233383147315F584D443A5348412D3235365F53;
const DST_LAST = 0x5357555F524F5F4E554C5F;

// Quicknet collective public key, scheme bls-unchained-g1-rfc9380.
const QUICKNET_PK_0 = 0x83CF0F2896ADEE7EB8B5F01FCAD3912212C437E0073E911FB90022D3E760183C;
const QUICKNET_PK_1 = 0x8C4B450B6A0A6C3AC6A5776A2D1064510D1FEC758C921CC22B0E17E63AAF4BCB;
const QUICKNET_PK_2 = 0x5ED66304DE9CF809BD274CA73BAB4AF5A6E9C76A4BC09E76EAE8991EF5ECE45A;

// Standard compressed BLS12-381 G2 generator.
const G2_GENERATOR_0 = 0x93E02B6052719F607DACD3A088274F65596BD0D09920B61AB5DA61BBDC7F5049;
const G2_GENERATOR_1 = 0x334CF11213945D57E5AC7D055D042B7E024AA2B2F08F0A91260805272DC51051;
const G2_GENERATOR_2 = 0xC6E47AD4FA403B02B4510B647AE3D1770BAC0326A805BBEFD48056C8C121BDB8;

struct ReductionWitness {
    q0: int;
    q1: int;
    q2: int;
    r0: int;
    r1: int;
    r2: int;
    r3: int;
    r4: int;
    r5: int;
}

@inline
fun sha256Builder(a: builder): int
    asm "1 PUSHINT HASHEXT_SHA256";

@inline
fun sha256TwoBuilders(a: builder, b: builder): int
    asm "2 PUSHINT HASHEXT_SHA256";

@inline
fun sha256Slice(a: slice): int
    asm "1 PUSHINT HASHEXT_SHA256";

@inline
fun blsMapToG1(a: slice): slice
    asm "BLS_MAP_TO_G1";

@inline
fun blsG1Add(a: slice, b: slice): slice
    asm "BLS_G1_ADD";

@inline
fun blsG1Neg(a: slice): slice
    asm "BLS_G1_NEG";

@inline
fun blsG1InGroup(a: slice): bool
    asm "BLS_G1_INGROUP";

@inline
fun blsG1IsZero(a: slice): bool
    asm "BLS_G1_ISZERO";

@inline
fun blsG2InGroup(a: slice): bool
    asm "BLS_G2_INGROUP";

@inline
fun blsG2IsZero(a: slice): bool
    asm "BLS_G2_ISZERO";

@inline
fun blsPairing2(p1a: slice, p2a: slice, p1b: slice, p2b: slice): bool
    asm "2 PUSHINT BLS_PAIRING";

@inline
fun pLimb(index: int): int {
    if (index == 0) { return P0; }
    if (index == 1) { return P1; }
    if (index == 2) { return P2; }
    if (index == 3) { return P3; }
    if (index == 4) { return P4; }
    if (index == 5) { return P5; }
    return 0;
}

@inline
fun qLimb(w: ReductionWitness, index: int): int {
    if (index == 0) { return w.q0; }
    if (index == 1) { return w.q1; }
    if (index == 2) { return w.q2; }
    return 0;
}

@inline
fun rLimb(w: ReductionWitness, index: int): int {
    if (index == 0) { return w.r0; }
    if (index == 1) { return w.r1; }
    if (index == 2) { return w.r2; }
    if (index == 3) { return w.r3; }
    if (index == 4) { return w.r4; }
    if (index == 5) { return w.r5; }
    return 0;
}

@inline
fun xLimb(high: int, low: int, index: int): int {
    if (index < 4) {
        return (low >> (index * 64)) & LIMB_MASK;
    }
    return (high >> ((index - 4) * 64)) & LIMB_MASK;
}

fun remainderIsCanonical(w: ReductionWitness): bool {
    if (w.r5 != P5) { return w.r5 < P5; }
    if (w.r4 != P4) { return w.r4 < P4; }
    if (w.r3 != P3) { return w.r3 < P3; }
    if (w.r2 != P2) { return w.r2 < P2; }
    if (w.r1 != P1) { return w.r1 < P1; }
    return w.r0 < P0;
}

// Verifies x = q * p + r using 64-bit limbs. This lets TVM authenticate the
// 512-to-381-bit hash_to_field reduction without ever storing a 381-bit int.
fun verifyReduction(high: int, low: int, w: ReductionWitness): bool {
    if (!remainderIsCanonical(w)) {
        return false;
    }

    var carry = 0;
    var k = 0;
    while (k < 8) {
        var total = carry + rLimb(w, k);
        var i = 0;
        while (i < 3) {
            val pIndex = k - i;
            if (pIndex >= 0 && pIndex < 6) {
                total += qLimb(w, i) * pLimb(pIndex);
            }
            i += 1;
        }
        if ((total & LIMB_MASK) != xLimb(high, low, k)) {
            return false;
        }
        carry = total >> 64;
        k += 1;
    }
    return carry == 0;
}

fun parseWitness(source: slice): ReductionWitness {
    return ReductionWitness {
        q0: source.loadUint(64),
        q1: source.loadUint(64),
        q2: source.loadUint(64),
        r0: source.loadUint(64),
        r1: source.loadUint(64),
        r2: source.loadUint(64),
        r3: source.loadUint(64),
        r4: source.loadUint(64),
        r5: source.loadUint(64),
    };
}

fun fieldElement(w: ReductionWitness): slice {
    return beginCell()
        .storeUint(w.r5, 64)
        .storeUint(w.r4, 64)
        .storeUint(w.r3, 64)
        .storeUint(w.r2, 64)
        .storeUint(w.r1, 64)
        .storeUint(w.r0, 64)
        .endCell()
        .beginParse();
}

fun dstPrime(): builder {
    return beginCell()
        .storeUint(DST_FIRST, 256)
        .storeUint(DST_LAST, 88)
        .storeUint(43, 8);
}

fun expandMessage(round: int): (int, int, int, int) {
    // drand signs SHA256(I2OSP(round, 8)).
    val message = sha256Builder(beginCell().storeUint(round, 64));

    // RFC 9380 expand_message_xmd for SHA-256, len_in_bytes = 128.
    val b0 = sha256TwoBuilders(
        beginCell()
            .storeUint(0, 256)
            .storeUint(0, 256)
            .storeUint(message, 256)
            .storeUint(128, 16)
            .storeUint(0, 8),
        dstPrime(),
    );
    val b1 = sha256Builder(
        beginCell().storeUint(b0, 256).storeUint(1, 8)
            .storeUint(DST_FIRST, 256).storeUint(DST_LAST, 88).storeUint(43, 8),
    );
    val b2 = sha256Builder(
        beginCell().storeUint(b0 ^ b1, 256).storeUint(2, 8)
            .storeUint(DST_FIRST, 256).storeUint(DST_LAST, 88).storeUint(43, 8),
    );
    val b3 = sha256Builder(
        beginCell().storeUint(b0 ^ b2, 256).storeUint(3, 8)
            .storeUint(DST_FIRST, 256).storeUint(DST_LAST, 88).storeUint(43, 8),
    );
    val b4 = sha256Builder(
        beginCell().storeUint(b0 ^ b3, 256).storeUint(4, 8)
            .storeUint(DST_FIRST, 256).storeUint(DST_LAST, 88).storeUint(43, 8),
    );
    return (b1, b2, b3, b4);
}

fun quicknetPublicKey(): slice {
    return beginCell()
        .storeUint(QUICKNET_PK_0, 256)
        .storeUint(QUICKNET_PK_1, 256)
        .storeUint(QUICKNET_PK_2, 256)
        .endCell()
        .beginParse();
}

fun g2Generator(): slice {
    return beginCell()
        .storeUint(G2_GENERATOR_0, 256)
        .storeUint(G2_GENERATOR_1, 256)
        .storeUint(G2_GENERATOR_2, 256)
        .endCell()
        .beginParse();
}

fun verifyQuicknet(round: int, signatureCell: cell, witnessCell: cell): int {
    assert (round > 0) throw 200;

    var first = witnessCell.beginParse();
    val firstBits = first.loadBits(576);
    var second = first.loadRef().beginParse();
    first.assertEnd();
    val secondBits = second.loadBits(576);
    second.assertEnd();
    val firstWitness = parseWitness(firstBits);
    val secondWitness = parseWitness(secondBits);
    val (b1, b2, b3, b4) = expandMessage(round);
    assert (verifyReduction(b1, b2, firstWitness)) throw 201;
    assert (verifyReduction(b3, b4, secondWitness)) throw 201;

    val mapped0 = blsMapToG1(fieldElement(firstWitness));
    val mapped1 = blsMapToG1(fieldElement(secondWitness));
    val messagePoint = blsG1Add(mapped0, mapped1);

    // The pairing op consumes a compressed G1 point, while drand defines
    // randomness as SHA256 of that exact 48-byte encoding. Reject trailing
    // bits or refs so a valid point cannot acquire multiple randomness values
    // by appending unauthenticated data to its cell.
    var canonicalSignature = signatureCell.beginParse();
    canonicalSignature.loadBits(384);
    canonicalSignature.assertEnd();
    val signature = signatureCell.beginParse();
    val publicKey = quicknetPublicKey();
    val generator = g2Generator();
    assert (blsG1InGroup(signature) && !blsG1IsZero(signature)) throw 202;
    assert (blsG2InGroup(publicKey) && !blsG2IsZero(publicKey)) throw 203;
    assert (blsPairing2(signature, generator, blsG1Neg(messagePoint), publicKey)) throw 204;

    // drand's published randomness is SHA256(compressed signature).
    return sha256Slice(signature);
}

fun roundForSealTime(sealedAt: int): int {
    val target = sealedAt + CEREMONY_DELAY;
    assert (target >= QUICKNET_GENESIS) throw 205;
    val delta = target - QUICKNET_GENESIS;
    return ((delta + QUICKNET_PERIOD - 1) / QUICKNET_PERIOD) + 1;
}
