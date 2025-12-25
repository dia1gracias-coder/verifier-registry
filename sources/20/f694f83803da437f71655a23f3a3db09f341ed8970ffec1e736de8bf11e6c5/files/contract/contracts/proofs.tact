
struct ParsedExotic {
    s: Slice;
    isExotic: Int;
}

struct GetOpt {
    data: Slice;
    found: Int;
}

struct MerkleProof {
    inner: Cell;
    hash: Int;
}

struct ProofParam {
    amount: Int;
    startFrom: Int;
    expiredAt: Int;
}

asm fun beginParseExotic(x: Cell): ParsedExotic { XCTOS }

asm fun dictGetOpt(index: Slice, dict: Cell, keyLen: Int): GetOpt { DICTGET NULLSWAPIFNOT }

const notExotic : Int = 103;
const notMerkleProof : Int = 104;
const wrongHash : Int = 105;
const leafNotFound : Int = 108;
const proofNotFound : Int = 109;
const cellTypeMerkleProof : Int = 3;

const ADDRESS_SLICE_LENGTH : Int = 2 + 1 + 8 + 256;
const TIMESTAMP_SIZE : Int = 48;

fun extractMerkleProof(proof: Cell): MerkleProof {
    let parsedExotic: ParsedExotic  = beginParseExotic(proof);
    throwUnless(notExotic, parsedExotic.isExotic != 0);

    let ty: Int = parsedExotic.s.loadInt(8);
    throwUnless(notMerkleProof, ty == cellTypeMerkleProof);

    return MerkleProof{
        inner: parsedExotic.s.loadRef(), 
        hash: parsedExotic.s.loadUint(256)
    };
}

fun checkMerkleProof(proof: Cell, expectedHash: Int): Cell {
    let merkleProof: MerkleProof = extractMerkleProof(proof);
    throwUnless(wrongHash, merkleProof.hash == expectedHash);
    return merkleProof.inner;
}

fun getProofParams(submittedProof: Cell, proofRoot: Int, owner: Slice): ProofParam {
    let proof: Cell = checkMerkleProof(submittedProof, proofRoot);
    let getOpt: GetOpt = dictGetOpt(owner, proof, ADDRESS_SLICE_LENGTH);
    throwUnless(proofNotFound, getOpt.found != 0);

    let amount: Int = getOpt.data.loadCoins();
    let startFrom: Int = getOpt.data.loadUint(TIMESTAMP_SIZE);
    let expiredAt: Int = getOpt.data.loadUint(TIMESTAMP_SIZE);

    return ProofParam{
        amount: amount,
        startFrom: startFrom,
        expiredAt: expiredAt
    };
}
