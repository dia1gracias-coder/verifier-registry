import "@stdlib/deploy";

// ReferralSystem structs
//
// v3: the referral network itself (links, keys, counters) lives in the
// ecosystem identity layer (code_contracts/referral). The game only keeps a
// short-lived queue of unresolved commission pots: a buy sets a pot aside and
// asks the profile layer for the buyer's referrer chain; the answer
// (RefChainResolved) pays the chain and the remainder joins the bank.
struct PendingRef {
    buyer: Address;
    pot: Int as coins;
}

// A ticket gift awaiting the on-chain key lookup: the recipient is named by
// their permanent numeric invite key; the gifted TON is earmarked until the
// KeyPointer answers (a bounced lookup or a FIFO eviction settles the
// tickets on the gifter — funds never leave the contract).
struct PendingGift {
    gifter: Address;
    amount: Int as coins;
    key: Int as uint64;
    refKey: Int as uint64;
}

// LotterySystem structs
struct LotteryBank {
    balance: Int;
}

struct PastLotteryInformation {
    lastLotteryTime: Int;
    lastWinnerAddress: Address;
    lastWinAmount: Int;
    totalWinners: Int;
    totalWinsAmount: Int;
}

struct CurrentLotteryRound {
    endTime: Int;
    ticketMap: map<Address, Int>;
    participantList: map<Int, Address>;
    totalTickets: Int;
    participantsCount: Int;
}

struct DrawState {
    isDrawing: Bool;
    cursor: Int;
    accumulated: Int;
    randomTarget: Int;
    winnerAddress: Address;
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

struct PyramidaState {
    lotteryBank: LotteryBank;
    pastLotteryInfo: PastLotteryInformation;
    currentRound: CurrentRoundSummary;
    drawState: DrawState;
    jettonRewardsStats: JettonRewardsStats;
    owner: Address;
    jettonMasterAddress: Address;
    profileRegistrar: Address;
    // Commission pots waiting for their referrer chain from the profile layer.
    pendingRefCount: Int;
    pendingRefTotal: Int;
    // Real spendable prize ceiling: max(0, myBalance − reservedStorage − min).
    // The virtual `lotteryBank.balance` only grows, while this caps the actual
    // payout (a draw pays min(bank*winnerShare%, availableForPrize)). Exposed so
    // the UI/bot can show the real prize instead of an over-stated virtual bank.
    availableForPrize: Int;
}