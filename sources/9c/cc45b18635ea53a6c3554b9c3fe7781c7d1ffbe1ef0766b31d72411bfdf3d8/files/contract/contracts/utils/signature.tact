import "../interfaces/types/crypto";
import "./assembly_crypto";

// The trait `Signature` provides functionality for recovering public keys from ECDSA signatures over secp256k1 curve.
trait Signature{
    // This function is used for tests and debugging purposes and can be called only  off-chain.
    get fun pubkeyFromSignature(
        hash: Int,
        signature: Slice
    ): EcrecoverKey? {
        return self.recoverPubKey(hash, signature);
    }

    // Recovery the public key from the signature and hash of the message.
    fun recoverPubKey(hash: Int, signature: Slice): EcrecoverKey {
        // Signature is expected to be a 65-byte slice
        require(signature.bits() == 520, "Invalid signature length");
        // Load r (256 bits = 32 bytes)
        let r: Int = signature.loadUint(256); 
        // Load s (256 bits = 32 bytes)
        let s = signature.loadUint(256);
        // Load v (8 bits = 1 byte)
        let v = signature.loadUint(8);

        // Recover the public key from the signature
        let pubkey = ecrecover(hash, v, r, s);
        require(pubkey != null, "Invalid signature");

        return pubkey!!;
    }
}