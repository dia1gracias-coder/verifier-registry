import "@stdlib/deploy";

// ReferralSystem structs 
struct UserData {
    referrerKey: Int;
    address: Address;
    referralsCount: Int;
    earningsFromReferrals: Int;
    lastActivity: Int;
}

struct Users {
    userData: map<Int, UserData>;
    addresses: map<Address, Int>;
    lastKey: Int;
    // Dense (hole-free) index of live users: position -> user key. Maintained
    // via swap-remove on deletion so pruning iterates only live users and never
    // wastes gas scanning removed slots.
    userIndex: map<Int, Int>;
    userCount: Int;
}

// State of the amortized pruning of inactive users. Pruning runs continuously
// over the contract's lifetime: each buy advances a ring cursor that checks a
// few slots of the dense index. The only persistent state needed is the cursor
// itself — it survives between transactions and resumes the scan where it left off.
struct PruneState {
    cursor: Int;
}

// LotterySystem structs
struct LotteryBank {
    balance: Int;
}

struct PastLotteryInformation {
    lastLotteryTime: Int;
    lastWinnerKey: Int;
    lastWinnerAddress: Address;
    lastWinAmount: Int;
    totalWinners: Int;
    totalWinsAmount: Int;
}

struct CurrentLotteryRound {
    endTime: Int;
    ticketMap: map<Int, Int>;
    participantList: map<Int, Int>;
    totalTickets: Int;
    participantsCount: Int;
}

struct DrawState {
    isDrawing: Bool;
    cursor: Int;
    accumulated: Int;
    randomTarget: Int;
    winnerKey: Int;
    winnerFound: Bool;
    snapshotParticipants: Int;
    prizeAmount: Int;
    ownerShareAmount: Int;
    // Timestamp of the last draw-chunk progress (heartbeat for the watchdog).
    lastProgressTime: Int;
}

// JettonRewards structs
struct JettonRewardsStats {
    lastMintTime: Int;
    totalMinted: Int;
}

// GasManager structs
struct GasDeductionResult {
    initialAmount: Int;     
    gasAmount: Int;  
    remainingAmount: Int;   
    isEnough: Bool;         
}

struct StorageStats {
    lastUpdateTime: Int;             
    transactionCount: Int;          
    totalTimeInterval: Int;         
    totalStorageDueCollected: Int;  
    reservedStorage: Int;           
    storageLimit: Int;              
    lastTonsReserve: Int;            
    storageTonsDeficit: Int;   
}

// PRMDJettonMaster structs
struct MultiMintReceiver {
    receiver: Address;
    amount: Int as coins;
    tonAmount: Int as coins;
    responseDestination: Address;
    forwardAmount: Int as coins;
    forwardPayload: Cell?;
}

struct JettonWalletData {
    balance: Int as coins;
    owner: Address;
    master: Address;
    walletCode: Cell;
}

struct JettonMasterData {
    totalSupply: Int as coins;
    mintable: Bool;
    owner: Address;
    content: Cell;
    walletCode: Cell;
}

//Getter structs
//
// IMPORTANT (scalability): the getter structs below intentionally contain ONLY
// scalar fields — never the on-chain maps (userData/addresses/userIndex,
// ticketMap/participantList). A get method serializes everything it returns
// into a single BoC, so embedding those maps would make the response grow
// linearly with state size (millions of users -> tens of MB, eventually hitting
// get-method gas / response-size limits). `getPyramidaState` therefore returns a
// constant-size global snapshot, and a single user's record is read on demand
// via `getUserByAddress(address)`.

// Constant-size summary of the current lottery round (no maps).
struct CurrentRoundSummary {
    endTime: Int;
    totalTickets: Int;
    participantsCount: Int;
}

// Constant-size summary of the user registry (no maps).
struct UsersSummary {
    lastKey: Int;
    userCount: Int;
}

struct PyramidaState {
    lotteryBank: LotteryBank;
    pastLotteryInfo: PastLotteryInformation;
    currentRound: CurrentRoundSummary;
    drawState: DrawState;
    pruneState: PruneState;
    users: UsersSummary;
    jettonRewardsStats: JettonRewardsStats;
    owner: Address;
    jettonMasterAddress: Address;
    // Real spendable prize ceiling: max(0, myBalance − reservedStorage − min).
    // The virtual `lotteryBank.balance` only grows, while this caps the actual
    // payout (a draw pays min(bank*winnerShare%, availableForPrize)). Exposed so
    // the UI/bot can show the real prize instead of an over-stated virtual bank.
    availableForPrize: Int;
}

// Single user's record, read on demand by address. `registered` is false when
// the address has never bought a ticket (all other fields are then zero/default).
struct UserView {
    registered: Bool;
    key: Int;
    referrerKey: Int;
    address: Address;
    referralsCount: Int;
    earningsFromReferrals: Int;
    lastActivity: Int;
}