// Underlying assembly function that does the work
// and only captures the topmost value from the stack.
//
// Since the `ECRECOVER` instruction places 0 on top of the stack
// in case of failure and -1 in case of success,
// this maps nicely onto the Bool type.
asm fun _ecrecoverExecute(hash: Int, v: Int, r: Int, s: Int): Bool { ECRECOVER }


// Simply captures the values from the stack
// if the call to `_ecrecoverExecute()` was successful.
asm fun _ecrecoverSuccess(): EcrecoverKey { }


// Recovers a public key from the signature as done in Bitcoin or Ethereum.
//
// Takes the 256-bit unsigned integer `hash` and the 65-byte signature consisting of:
// * 8-bit unsigned integer `v`
// * 256-bit unsigned integers `r` and `s`
//
// Returns `null` on failure or an `EcrecoverKey` structure on success.
fun ecrecover(hash: Int, v: Int, r: Int, s: Int): EcrecoverKey? {
    let successful = _ecrecoverExecute(hash, v, r, s);
    if (successful) {
        return _ecrecoverSuccess();
    }
    
    return null;
}




