// No of Seconds in a year
const SECONDS_IN_A_YEAR:    Int = 31536000;
// Maximum number of compounding periods (limits the loop)
const DAYS_IN_YEAR:         Int = 365;
// 24 * 60 * 60 (hours * minutes * seconds)
const SECONDS_IN_DAY:       Int = 86_400;
// 100.00% Ensures 0.00 < apy < 1.00 is not returned as zero
const APY_DECIMALS:         Int = 10_000;

// Pool Deposit Mode: Boost = Increase global fee growth
const BOOST:                Int = 1;
// Pool Deposit Mode: Deposit = Create a deposit for user
const DEPOSIT:              Int = 2;

const MIN_GAS_FEES:         Int = ton("0.02");