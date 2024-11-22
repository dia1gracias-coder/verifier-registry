import "./jetton/messages";

// message GetAprFor {
//     childOwner: Address;
// }

// message SendAprFor {
//     apr: Int;
// }

message SetAPR {
    apr: Int as uint16;
}

message Deposit {
    amount: Int as coins;
    apr: Int as uint16;
}

message SendCoins {
    amount: Int as coins;
    to: Address;
    update: Bool;
}

message SetJettonWallet {
    wallet: Address;
}
