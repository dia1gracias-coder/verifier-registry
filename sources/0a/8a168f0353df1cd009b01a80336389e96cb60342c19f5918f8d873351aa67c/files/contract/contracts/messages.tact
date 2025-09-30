// ===== EPOCH MESSAGES =====

// Custom deploy message with TONCAST staked amount
message(0x5a75ae3e) DeployEpoch {
    totalToncastStaked: Int as coins;
}

// Message to payout rewards to a staker (also used when user withdraws from DAO)
message(0x3a9b4f22) PayoutStaker {
    queryId: Int as uint64;
    stakerAddress: Address;
    stakerToncastAmount: Int as coins;
}

// Internal message to process epoch payouts batch
message(0x8d4b6e9f) ProcessEpochPayouts {
    userAddress: Address;
    withdrawnAmount: Int as coins;
    startEpoch: Int as uint32;
    endEpoch: Int as uint32;
}

// Structure containing all epoch data
struct EpochData {
    epochNumber: Int as uint32;
    totalTonReceived: Int as coins;
    totalToncastStaked: Int as coins;
    isInitialized: Bool;
    owner: Address;
}

// ===== DAO MESSAGES =====

// Standard Jetton transfer notification message (TEP-74)
message(0x7362d09c) JettonTransferNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forwardPayload: Slice as remaining;
}


// NFT transfer notification when NFT is sent to DAO (TEP-62)
message(0x05138d91) NftTransferNotification {
    queryId: Int as uint64;
    prevOwner: Address;
    forwardPayload: Slice as remaining;
}

// NFT get all data message
message(0x3a3a3a3a) NftGetAllData {
    queryId: Int as uint64;
}

// NFT report all data response  
// Custom message for NFT data with packed format to avoid cell overflow
message(0x7b7b7b7b) NftReportAllData {
    queryId: Int as uint64;
    index: Int as uint64; 
    data: Cell; // Contains addresses and staking_data
}

// Stop and redirect message - owner can stop the DAO and redirect funds to new DAO
message(0x53544f50) StopAndRedirect {  // 0x53544f50 = "STOP" in hex
    newDaoAddress: Address;
}

// ===== DAO STRUCTURES =====

// Jetton wallet data structure
struct JettonWalletData {
    balance: Int as coins;
    ownerAddress: Address;
    jettonMasterAddress: Address;
    jettonWalletCode: Cell;
}

// Staking data structure for NFT metadata
// Format: [coins amount][uint64 timestamp][address dao_address]
struct StakingData {
    amount: Int as coins;
    timestamp: Int as uint64;
    daoAddress: Address;
}

// DAO epoch data structure - consolidated getter data
struct DAOEpochData {
    deployTime: Int as uint64;
    currentRealTimeEpoch: Int as uint32;    // Real-time calculated epoch number
    epochDuration: Int as uint32;
    currentStoredEpochNumber: Int as uint32;  // Last processed epoch (deployed or skipped)
    totalCurrentlyStaked: Int as coins;
}

// DAO configuration data structure - consolidated getter data
struct DAOConfigData {
    nextItemIndex: Int as uint64;
    nftCollectionAddress: Address?;
    jettonMasterAddress: Address;
    jettonWalletAddress: Address;
    minDepositAmount: Int as coins;
    nftNamePrefix: String;
    nftImageUrl: String;
    isReadyToAcceptDeposits: Bool;
    stopped: Bool;
    newDaoAddress: Address?;
}
