// Shared governance message structs + pause guard for all Sooth TON contracts.
//
// Every Sooth contract exposes the same two-step admin handoff (ProposeAdmin/AcceptAdmin with a
// timelock) and the same pause switch (SetPaused). The message structs are byte-identical across
// all of them (opcodes 0x7061646d / 0x6161646d / 0x70617573), so they live here as a single
// source of truth instead of being hand-copied six times. The per-contract execute* handlers
// stay local (their storage nesting and events differ), but they parse these shared structs.
//
// Opcodes are wire-significant; do NOT change them.

import "errors.tolk"

struct (0x70617573) SetPaused {
    paused: bool
}

struct (0x7061646d) ProposeAdmin {
    admin: address
}

struct (0x6161646d) AcceptAdmin {}

// Standard pause guard. Callers pass their pause flag (it lives in different storage tiers
// across contracts), keeping the assert + canon PAUSED code in one place.
fun requireNotPaused(paused: bool) {
    assert (paused == false) throw Errors.PAUSED;
}

// Infinite-deadline sentinel. EVM uses type(uint64).max (18446744073709551615) to mark a
// market that never expires; TON's deadline field is a SIGNED int64, so the sentinel here is
// int64 max (0x7FFFFFFFFFFFFFFF == 9223372036854775807). The EVM uint64-max literal would
// serialize as -1 over int64 and read as permanently expired — hence the int64-max sentinel.
// Deadline/expiry checks short-circuit for this value: invalidate REVERTS (EVM
// InfiniteDeadline), resolve SKIPS the window, trial uses the full default period — matching
// EVM. (TVM does arithmetic on 257-bit stack integers, so `deadline + buffer` at the sentinel
// does NOT wrap; the guards exist for EVM-semantic parity + a clear error, not overflow safety.)
fun infiniteDeadline(): int64 {
    return 0x7FFFFFFFFFFFFFFF;
}
