// Shared TVM exit codes for all Sooth TON contracts.
//
// This is the single source of truth for project-defined exit codes (>= 1000).
// The TS adapter mapping in src/ton/exitCodes.ts (errorCodeFromExitCode), shared
// by every TON adapter, must stay in sync with the canon-error names below; the
// drift guard is tests/exit-codes-coverage.spec.ts and the doc snapshot lives at
// .claude/skills/ton-dev/references/tvm-exit-codes.md.
//
// Standard TVM codes (0, 9, 13, 33/34, 0xffff) are NOT listed here — they are
// emitted directly by the contracts/stdlib and are not project-defined.
//
// Acton E028: throw codes are referenced symbolically via `Errors.<Name>`. The
// enum values are byte-identical to the historical bare `const ERROR_<Name>`
// integers, so every `throw Errors.X` compiles to the same exit code as the old
// `throw ERROR_X`. The descriptive names are preserved (ERROR_FOO -> Errors.FOO).

enum Errors {
    // --- Canon-mapped core codes (1001-1018), documented in tvm-exit-codes.md ---
    MARKET_NOT_TRADABLE = 1001
    NON_POSITIVE_AMOUNT = 1002
    UNKNOWN_OUTCOME = 1003
    POSITION_UNDERFLOW = 1004
    NUMERIC_BOUNDS_EXCEEDED = 1005
    SLIPPAGE_LIMIT = 1006
    FEE_POLICY_INVALID = 1007
    COLLATERAL_CUSTODY_MISMATCH = 1008
    INSUFFICIENT_COLLATERAL = 1009
    INSUFFICIENT_RESERVE = 1010
    JETTON_WALLET_MISMATCH = 1011
    ADMIN_UNAUTHORIZED = 1012
    TRADER_UNAUTHORIZED = 1013
    MARKET_ALREADY_SETTLED = 1014
    MARKET_NOT_SETTLED = 1015
    ZERO_REDEMPTION = 1016
    MARKET_HAS_OPEN_INTEREST = 1017
    PRODUCTION_SAFE_REJECTED = 1018

    // --- AMM / shared collateral-flow codes (1019-1024) ---
    INSUFFICIENT_MESSAGE_VALUE = 1019
    BOUNCE_RESTORE_MISMATCH = 1021
    INVALID_COLLATERAL_LOCK = 1022
    MARKET_DEADLINE_INVALID = 1023
    ORPHAN_COLLATERAL_UNDERFLOW = 1024

    // --- Order-engine CLOB codes (1025-1038) ---
    ORDER_TICK_RANGE = 1025
    ORDER_TICK_SUM = 1026
    ORDER_SELF_MATCH = 1027
    ORDER_ALREADY_EXISTS = 1028
    ORDER_NOT_FOUND = 1029
    ORDER_NOT_OWNER = 1030
    ORDER_STATE_MISMATCH = 1031
    ORDER_SIGNING_KEY_INVALID = 1032
    ORDER_OPERATOR_UNAUTHORIZED = 1033
    ORDER_FILL_EXCEEDS_REMAINING = 1034
    ORDER_SIGNATURE_INVALID = 1035
    ORDER_EXPIRED = 1036
    ORDER_NONCE_INVALID = 1037
    ORDER_MIN_NONCE_INVALID = 1038
    ORDER_BOOK_FULL = 1039

    // --- Registry lifecycle codes (1040-1047) ---
    REGISTRY_MARKET_EXISTS = 1040
    REGISTRY_MARKET_NOT_FOUND = 1041
    REGISTRY_LIFECYCLE_INVALID = 1042
    REGISTRY_TIMESTAMP_INVALID = 1043
    PAUSED = 1044
    REGISTRY_INVALIDATION_TOO_EARLY = 1045
    REGISTRY_VENUE_MASK_INVALID = 1046
    VENUE_SETUP_INVALID = 1047

    // --- Adjudicator codes (1049-1059) ---
    // 1049 occupies the gap before the contiguous 1050-1059 block (which is full;
    // 1060+ is the launchpad range). EVM-parity resolve deadline+buffer guard
    // (AdjudicatorBase.sol:127-133) + the local invalidationBuffer range check.
    ADJUDICATOR_DEADLINE_PASSED = 1049
    ADJUDICATOR_MARKET_EXISTS = 1050
    ADJUDICATOR_MARKET_NOT_FOUND = 1051
    ADJUDICATOR_RESOLVER_UNAUTHORIZED = 1052
    ADJUDICATOR_PHASE_INVALID = 1053
    ADJUDICATOR_LAUNCHPAD_UNAUTHORIZED = 1054
    ADJUDICATOR_TSTAR_INVALID = 1055
    ADJUDICATOR_VETO_NOT_ENDED = 1056
    ADJUDICATOR_GUARDIAN_UNAUTHORIZED = 1057
    ADJUDICATOR_VETO_ENDED = 1058
    ADJUDICATOR_REGISTRY_UNAUTHORIZED = 1059

    // --- Launchpad codes (1060-1079) ---
    LAUNCHPAD_MARKET_EXISTS = 1060
    LAUNCHPAD_MARKET_NOT_FOUND = 1061
    LAUNCHPAD_TIMESTAMP_INVALID = 1062
    LAUNCHPAD_AMOUNT_INVALID = 1063
    LAUNCHPAD_TRIAL_NOT_ENDED = 1064
    LAUNCHPAD_ALREADY_LIVE = 1065
    LAUNCHPAD_LIFECYCLE_INVALID = 1066
    LAUNCHPAD_VENUE_SETUP_INVALID = 1067
    // EVM fee parity (1/2): post-grad fee distribution shares must sum to 10000 bps
    // (EVM FeeRouter.sol:240 InvalidFeeDistribution).
    LAUNCHPAD_FEE_DISTRIBUTION_INVALID = 1069
    LAUNCHPAD_COLLATERAL_OUTSTANDING = 1070
    LAUNCHPAD_NO_LP_SUPPLY = 1071
    LAUNCHPAD_NO_REDEEMABLE_COLLATERAL = 1072
    LAUNCHPAD_INSUFFICIENT_LP_BALANCE = 1073
    LAUNCHPAD_BOUNCE_RESTORE_MISMATCH = 1075
    LAUNCHPAD_PURGE_PRECONDITION = 1076
    LAUNCHPAD_LP_JETTON_MODE_MISMATCH = 1077
    LAUNCHPAD_UNHANDLED_BRANCH = 1078
    LAUNCHPAD_CODE_HASH_MISMATCH = 1079

    // --- AMM fee-routing / retro-settlement codes (1080-1093) ---
    PROTOCOL_FEE_UNDERFLOW = 1080
    ADJUDICATOR_FEE_UNDERFLOW = 1081
    LAUNCHPAD_FEE_ROUTE_UNDERFLOW = 1082
    RETRO_SETTLEMENT_REQUIRED = 1084
    RETRO_PROOF_INVALID = 1085
    RETRO_ROOT_NOT_POSTED = 1086
    RETRO_ALREADY_CLAIMED = 1087
    TSTAR_OUT_OF_RANGE = 1088
    RETRO_ROOT_ALREADY_POSTED = 1089
    SELL_LOCK_NOT_FOUND = 1090
    SELL_LOCK_NOT_OWNER = 1091
    SELL_LOCK_NOT_UNLOCKED = 1092
    PENDING_ADMIN_NOT_READY = 1093
    // EVM TruthMarket.InfiniteDeadline(): a market with the infinite-deadline sentinel cannot be
    // permissionlessly invalidated (it opted out of the timeout safety net).
    INFINITE_DEADLINE = 1094
    // Engine fee config out of bounds: zero denominator or numerator above the 5% cap
    // (numerator * 20 > denominator), mirroring EVM's postGrad fee cap.
    ORDER_ENGINE_FEE_RATE_INVALID = 1095
    // H-1 fix: a fill charged a taker fee but the engine has no AMM collateral wallet wired
    // (ammCollateralJettonWallet == null), so the fee jettons cannot be forwarded to the AMM
    // for distribution. Set via SetAmmCollateralWallet on the factory path before fees go live.
    ORDER_ENGINE_AMM_WALLET_UNSET = 1096
    // Finding 3 (LOW): a fee-charging fill did not attach enough TON to cover the engine-fee
    // forward to the AMM (engineFeeTransferValue + the jetton-send overhead). Fails loudly in the
    // COMPUTE phase with this code rather than reverting in the ACTION phase. Inert at the default
    // feeNumerator == 0 (no fee charged => no forward => never asserted).
    ORDER_ENGINE_FEE_VALUE_INSUFFICIENT = 1097

    // --- LMSR fixed-point domain guards (65002-65003) ---
    // Internal saturation guards for the fixed-point ln/exp math in
    // sooth_amm.tolk and sooth_amm_proof.tolk. They should never trigger on
    // in-envelope inputs; they bound the domain of lnFixed/expFixed.
    FIXED_POINT_VALUE_NON_POSITIVE = 65002
    FIXED_POINT_VALUE_NEGATIVE = 65003

    // --- Sandbox-only Jetton test fixtures (2001-2204) ---
    // These codes are asserted only by the sandbox Jetton fixtures
    // (test_jetton_wallet, sooth_test_jetton_wallet, sooth_test_jetton_master);
    // they are not part of the production contract error surface.
    FIXTURE_WALLET_FORWARD_TON_NON_POSITIVE = 2001
    FIXTURE_WALLET_SENDER_NOT_OWNER = 2002
    FIXTURE_WALLET_AMOUNT_NON_POSITIVE = 2003
    FIXTURE_WALLET_INSUFFICIENT_BALANCE = 2004
    FIXTURE_WALLET_WRONG_DESTINATION = 2005
    FIXTURE_SOOTH_WALLET_SENDER_NOT_OWNER = 2101
    FIXTURE_SOOTH_WALLET_AMOUNT_NON_POSITIVE = 2102
    FIXTURE_SOOTH_WALLET_INSUFFICIENT_BALANCE = 2103
    FIXTURE_SOOTH_WALLET_SENDER_NOT_WALLET = 2104
    FIXTURE_SOOTH_WALLET_INSUFFICIENT_BURN_VALUE = 2105
    FIXTURE_SOOTH_MASTER_SENDER_NOT_ADMIN = 2201
    FIXTURE_SOOTH_MASTER_AMOUNT_NON_POSITIVE = 2202
    FIXTURE_SOOTH_MASTER_SENDER_NOT_WALLET = 2203
    FIXTURE_SOOTH_MASTER_INSUFFICIENT_SUPPLY = 2204
}
