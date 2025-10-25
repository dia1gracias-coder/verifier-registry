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

message DepositTon {
    amount: Int as coins;
}

struct Supply {
    input: Int as coins;
    output: Int as coins;
}

const CHECK_INPUT_MESSAGE_ID: Int = 0x006ad5e9;

message(CHECK_INPUT_MESSAGE_ID) CheckInput {}

const CHECK_OUTPUT_MESSAGE_ID: Int = 0x0004d318;

message(CHECK_OUTPUT_MESSAGE_ID) CheckOutput {}


message WithdrawInput {
    queryId: Int as uint64;
    amount: Int as coins;
}

message WithdrawOutput {
    queryId: Int as uint64;
    amount: Int as coins;
}


struct FarmWithdrawData {
    farmAccount: Address;
    sendData: Cell;
}

message ProposeFarmAccount {
    queryId: Int as uint64;
    withdrawData: FarmWithdrawData;
}


message Send {
    queryId: Int as uint64;
    forwardTonAmount: Int as coins;
}

message BuybackLaunchJetton {
    queryId: Int as uint64;
    amount: Int as coins; 
}