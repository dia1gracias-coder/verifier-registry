// The 65-byte public key returned by `ecrecover()` in case of success,
// which consists of the 8-bit unsigned integer `h`
// and 256-bit unsigned integers `x1` and `x2`.
struct EcrecoverKey {
    h: Int as uint8;
    x1: Int as uint256;
    x2: Int as uint256;
}