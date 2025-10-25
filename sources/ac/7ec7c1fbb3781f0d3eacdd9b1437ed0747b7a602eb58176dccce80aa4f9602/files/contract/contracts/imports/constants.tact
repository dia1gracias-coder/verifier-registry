// Proof of Capital is a technology for managing the issue of tokens that are backed by capital.
// The contract allows you to block the desired part of the issue for a selected period with a
// guaranteed buyback under pre-set conditions.

// During the lock-up period, only the market maker appointed by the contract creator has the
// right to buyback the tokens. Starting two months before the lock-up ends, any token holders
// can interact with the contract. They have the right to return their purchased tokens to the
// contract in exchange for the collateral.

// The goal of our technology is to create a market for assets backed by capital and
// transparent issuance management conditions.

// You can integrate the provided contract and Proof of Capital technology into your token if
// you specify the royalty wallet address of our project, listed on our website:
// https://proofofcapital.org

// All royalties collected are automatically used to repurchase the project's core token, as
// specified on the website, and are returned to the contract.

// This is the third version of the contract. It introduces the following features: the ability to choose any jetton as collateral, build collateral with an offset,
// perform delayed withdrawals (and restrict them if needed), assign multiple market makers, modify royalty conditions, and withdraw profit on request.

const MIN_OTC_BALANCE: Int = ton("0.05");
const TAKE_WALLET_ADDRESS_AMOUNT: Int = ton("0.05");
const DEPOSIT_FEE: Int = ton("0.01");
const MIN_CHECK_AMOUNT: Int = ton("0.1");
const FORWARD_TRANSACTION_VALUE: Int = ton("0.05");
const MIN_ADMIN_SEND_VALUE: Int = ton("0.1");


const PROPOSE_FARM_ACCOUNT_LOCK_PERIOD: Int = 10*24*60*60; // 10 DAYS
const SUPPLY_LOCK_PERIOD: Int = 10*24*60*60; // 10 days for supply phase (USDT/TON only)
const TOTAL_LOCK_PERIOD: Int = 65*24*60*60; // 75 days total lock
const INITIAL_LOCK_PERIOD: Int = 70*24*60*60; // 80 days initial lock

const ZERO_ADDRESS: Address = address("UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJKZ");

const NOMINATOR: Int = ton("1");


const STATE_FUNDING: Int = 0; // (was STATE_REPLISHMENT_OF_FUNDS)
const STATE_SUPPLY_IN_PROGRESS: Int = 1; // (was STATE_SUPPLY_OF_FUNDS)
const STATE_SUPPLY_PROVIDED: Int = 2; // supply completed, both checks passed
const STATE_WAITTING_FOR_CLIENT_ANSWER: Int = 3; // used AFTER propose
const STATE_CLIENT_ACCEPTED: Int = 4; // client answered "yes"
const STATE_CLIENT_REJECTED: Int = 5; // client answered "no"
const STATE_CANCELED: Int = 6; // final cancellation
