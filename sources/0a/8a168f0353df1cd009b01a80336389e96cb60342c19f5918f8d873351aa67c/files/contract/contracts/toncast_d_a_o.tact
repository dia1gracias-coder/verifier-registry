/*
    ToncastDAO Contract
    
    Toncast Jetton addresses:
    - Testnet: kQBM0jlIe1_IGNJmHxV3EYDAswxLQhIxZnzvResvWbtPTCAV
    - Mainnet: EQCwIlIRZRVzdwS-iY7QJngnVCU8UMKfPhWr_KkZoQ6Mckju
    
    Error codes:
    - 401: Unauthorized - Jetton transfer from wrong wallet
    - 402: Insufficient amount - Deposit below minimum required
    - 403: Insufficient TON - Not enough TON for NFT mint
    - 409: Collection already deployed - NFT collection is already set
    - 410: Collection not deployed - NFT collection must be deployed first
    - 411: No pending withdrawal - NFT not recognized for withdrawal
    - 412: Query ID mismatch - Invalid withdrawal request
    - 413: Wrong collection - NFT is not from DAO collection
    - 414: NFT not owned by DAO - NFT must be transferred to DAO first
    - 415: Invalid metadata format - NFT metadata structure error
    - 416: No staking data - NFT missing staking information
    - 417: Wrong DAO address - NFT was minted by different DAO
    - 418: Invalid NFT address - Sender doesn't match calculated NFT address
    - 419: Invalid message format - NftReportAllData message format is incorrect
    - 430: Not self call - ProcessEpochPayouts can only be called by contract itself
    - 500: Epoch not initialized - Epoch contract not initialized (ToncastDAOepoch)
    - 501: Invalid staked amount - Total staked amount must be positive (ToncastDAOepoch)
    - 502: Invalid staker amount - Staker amount must be positive (ToncastDAOepoch)
    - 503: Staker amount exceeds total - Staker amount exceeds total staked (ToncastDAOepoch)
    - 504: Payout too small - Payout amount below minimum threshold (ToncastDAOepoch)
    - 505: Division by zero - Total staked amount is zero (ToncastDAOepoch)
    - 132: Access denied - Not contract owner (from @stdlib/ownable)
    
    Security note:
    The contract validates JettonTransferNotification by calculating the expected
    jetton wallet address using the jetton master address and wallet code.
    This ensures that only legitimate notifications from the contract's own
    jetton wallet are accepted, preventing spoofing attacks.
*/

import "@stdlib/ownable";
import "@stdlib/deploy";
import "./messages";
import "./constants";
import "./toncast_dao_epoch";


// Converts a String into a tail string Cell (no leading 0x00 here)
// TEP-64's leading 0x00 prefix is added in composeItemMetadata
inline extends fun asMetadataCell(self: String): Cell {
    return beginTailString().concat(self).toCell();
}


// Helper function to parse staking data from NFT metadata
inline fun parseStakingData(stakingCell: Cell): StakingData {
    let cs: Slice = stakingCell.beginParse();
    return StakingData{
        amount: cs.loadCoins(),
        timestamp: cs.loadUint(64),
        daoAddress: cs.loadAddress()
    };
}

inline fun composeItemMetadata(
    // Full name
    name: String,

    // Text description of the NFT
    description: String,

    // Link to the image
    image: String,

    // There could be other data, see:
    // https://github.com/ton-blockchain/TEPs/blob/master/text/0064-token-data-standard.md#nft-metadata-attributes
): Cell {
    let dict: map<Int as uint256, Cell> = emptyMap();
    dict.set(sha256("name"), name.asMetadataCell());
    dict.set(sha256("description"), description.asMetadataCell());
    dict.set(sha256("image"), image.asMetadataCell());

    return beginCell()
        .storeUint(0, 8) //                a null byte prefix
        .storeMaybeRef(dict.asCell()) // Store dict as maybe ref
        .endCell();
}

// Build initial data cell for collection
inline fun buildCollectionInitData(
    owner: Address,
    itemCode: Cell,
    contentContainer: Cell
): Cell {
    return beginCell()
        .storeAddress(owner)
        .storeUint(0, 64) // next_item_index
        .storeRef(contentContainer)
        .storeRef(itemCode)
        .endCell();
}

// Builds individual NFT content (owner + TEP-64 metadata)
inline fun buildNftIndividualContent(
    owner: Address,
    namePrefix: String,
    baseImageUrl: String,
    itemIndex: Int,
    depositAmount: Int
): Cell {
    let name: StringBuilder = beginString();
    name.append(namePrefix);
    name.append(" #");
    name.append(itemIndex.toString());
    name.append(" ");

    // Human-readable description in format: amount|timestamp|address
    let currentTime: Int = now();
    let daoAddress: Address = myAddress();
    
    let description: StringBuilder = beginString();
    description.append("Toncast staked: ");
    description.append(depositAmount.toString());
    description.append(" at timestamp: ");
    description.append(currentTime.toString());
    description.append(" in contract: ");
    description.append(daoAddress.toString());

    // Structured staking data for smart contract reading
    let stakingData: Cell = beginCell()
        .storeCoins(depositAmount)
        .storeUint(currentTime, 64)
        .storeAddress(daoAddress)
        .endCell();

    let image: StringBuilder = beginString();
    image.append(baseImageUrl);
    image.append(depositAmount.toString());
    image.append("-");
    image.append(currentTime.toString());
    image.append("-");
    image.append(daoAddress.toString());
    image.append(".png");

    let nftContent: Cell = composeItemMetadata(
        name.toString(),
        description.toString(),
        image.toString()
    );

    // Build full NFT content with owner, metadata and staking data
    // This will be sent as initialization message to NFT
    return beginCell()
        .storeAddress(owner)
        .storeRef(nftContent)
        .storeRef(stakingData)  // Store staking data as separate ref
        .endCell();
}

// Builds body for NFT deploy message
inline fun buildMintMessage(
    queryId: Int,
    itemIndex: Int,
    forwardAmount: Int,
    individualContent: Cell
): Cell {
    return beginCell()
        .storeUint(OP_NFT_DEPLOY, 32)
        .storeUint(queryId, 64)
        .storeUint(itemIndex, 64)
        .storeCoins(forwardAmount)
        .storeRef(individualContent)
        .endCell();
}

// Calculate jetton wallet address for validation
fun calculateJettonWalletAddress(
    ownerAddress: Address,
    jettonMasterAddress: Address
): Address {
    let initData: Cell = beginCell()
        .storeCoins(0)  // balance
        .storeAddress(ownerAddress)  // owner
        .storeAddress(jettonMasterAddress)  // jetton master
        .storeRef(TONCAST_JETTON_WALLET_CODE)  // wallet code
        .endCell();

    let stateInit: StateInit = StateInit{
        code: TONCAST_JETTON_WALLET_CODE,
        data: initData
    };

    return contractAddress(stateInit);
}

// Calculate NFT item address by index
inline fun calculateNftItemAddress(
    collectionAddress: Address,
    itemIndex: Int
): Address {
    let initData: Cell = beginCell()
        .storeUint(itemIndex, 64)
        .storeAddress(collectionAddress)
        .endCell();
    
    let stateInit: StateInit = StateInit{
        code: TONCAST_NFT_ITEM_CODE,
        data: initData
    };
    
    return contractAddress(stateInit);
}

// Calculate epoch contract address using ToncastDAOepoch init
inline fun calculateEpochContractAddress(epochNumber: Int, daoAddress: Address): Address {
    let epochInit: StateInit = initOf ToncastDAOepoch(
        daoAddress, // Owner is the DAO contract
        epochNumber  // Epoch number
    );
    
    return contractAddress(epochInit);
}

contract ToncastDAO with Ownable {
    owner: Address;                      // Contract owner
    stopped: Bool;                       // Whether the contract is stopped
    nftCollectionAddress: Address?;      // NFT collection address for minting (set on deploy)
    jettonMasterAddress: Address;        // Toncast Jetton master contract address
    minDepositAmount: Int as coins;     // Minimum amount of Toncast tokens to deposit (default: 1 TONCAST)
    nextItemIndex: Int as uint64;       // Next NFT index to mint
    nftNamePrefix: String;              // NFT name prefix (e.g., "ToncastDAO Member")
    nftImageUrl: String;                // NFT image URL template (without index suffix)
    pendingWithdrawals: map<Address, Int>; // Map of NFT addresses to query IDs for pending withdrawals
    pendingWithdrawalOwners: map<Address, Address>; // Map of NFT addresses to original owners
    collectionMetadata: Cell;            // NFT collection metadata in TEP-64 format
    seq: Int as uint32;                  // Sequence number for unique contract address
    newDaoAddress: Address?;             // New DAO address for fund forwarding when stopped
    
    // Epoch tracking
    deployTime: Int as uint64;           // Contract deploy timestamp
    epochDuration: Int as uint32;        // Epoch duration in seconds (default: 3600 = 1 hour)
    lastProcessedEpoch: Int as uint32;   // Last epoch that was processed (deployed or skipped)
    totalCurrentlyStaked: Int as coins;  // Total TONCAST currently staked in DAO (deposits - withdrawals)
    
    init(
        owner: Address,
        jettonMasterAddress: Address,
        minDepositAmount: Int as coins,
        nextItemIndex: Int as uint64,
        nftNamePrefix: String,
        nftImageUrl: String,
        epochDuration: Int as uint32,
        collectionMetadata: Cell,
        seq: Int as uint32
    ) {
        self.owner = owner;
        self.stopped = false;
        self.jettonMasterAddress = jettonMasterAddress;
        self.minDepositAmount = minDepositAmount;
        self.nextItemIndex = nextItemIndex;
        self.nftNamePrefix = nftNamePrefix;
        self.nftImageUrl = nftImageUrl;
        self.pendingWithdrawals = emptyMap();
        self.pendingWithdrawalOwners = emptyMap();
        self.collectionMetadata = collectionMetadata;
        self.seq = seq;
        self.newDaoAddress = null;

        // Initialize epoch tracking
        self.deployTime = now();
        self.epochDuration = epochDuration; // Epoch duration from init parameter
        self.lastProcessedEpoch = 0; // Starting from epoch 0
        self.totalCurrentlyStaked = 0; // No tokens staked initially

        // Defer collection deployment; address will be set on deploy
        self.nftCollectionAddress = null;
    }
    
    // Get current epoch number
    inline fun getCurrentEpochNumber(): Int {
        if (now() < self.deployTime) {
            return 0;
        }
        let timePassed: Int = now() - self.deployTime;
        return timePassed / self.epochDuration;
    }
    
    // Check and send accumulated funds to epoch or forward to new DAO if stopped
    inline fun checkAndUpdateEpoch() {
        // If stopped, forward accumulated funds to new DAO instead of creating epochs
        if (self.stopped) {
            // Forward all accumulated TON to new DAO (rewards from deposits/withdrawals)
            if (self.newDaoAddress != null) {
                let balance: Int = myBalance();
                if (balance > ton("0.05")) {
                    message(MessageParameters{
                        to: self.newDaoAddress!!,
                        value: balance - ton("0.05"),
                        mode: SendIgnoreErrors,
                        body: null
                    });
                }
            }
            return;
        }
        
        let currentEpoch: Int = self.getCurrentEpochNumber();
        
        // If we moved to a new epoch and haven't processed it yet
        if (currentEpoch > self.lastProcessedEpoch) {
            let balance: Int = myBalance();
            let amountToSend: Int = balance - ton("0.05"); // Keep minimum for storage
            
            // Only send if we have meaningful amount
            if (amountToSend > ton("0.1")) {
                // Send all accumulated funds to the epoch that just ended
                let epochToFund: Int = self.lastProcessedEpoch; // This is the epoch that just finished
                
                // Get epoch contract StateInit
                let epochInit: StateInit = initOf ToncastDAOepoch(
                    myAddress(), // Owner is this DAO contract
                    epochToFund  // Epoch number
                );
                
                // Deploy epoch contract with accumulated funds and current staking info
                deploy(DeployParameters{
                    init: epochInit,
                    value: amountToSend,
                    mode: SendIgnoreErrors,
                    body: DeployEpoch{
                        totalToncastStaked: self.totalCurrentlyStaked  // Send current total staked amount
                    }.toCell()
                });
            }
            
            // ALWAYS update to current epoch, even if we didn't deploy
            // Epochs without funds simply won't exist, and PayoutStaker with SendIgnoreErrors won't fail
            self.lastProcessedEpoch = currentEpoch;
        }
    }
    

    // Handle Jetton transfer notification when user sends Toncast tokens
    receive(msg: JettonTransferNotification) {
        // Deposits are allowed even when stopped (users can still stake)
        // Only epoch creation is prevented when stopped
        
        // Calculate expected jetton wallet address
        let expectedJettonWallet: Address = calculateJettonWalletAddress(
            myAddress(),  // This contract is the owner of its jetton wallet
            self.jettonMasterAddress
        );
        
        // Verify that notification came from our jetton wallet
        throwUnless(401, sender() == expectedJettonWallet); // 401 - Unauthorized
        // Verify minimum deposit amount
        throwUnless(402, msg.amount >= self.minDepositAmount); // 402 - Insufficient amount
        // Ensure there is enough TON to cover the storage fee
        throwUnless(403, context().value >= ton("0.2")); // 403 - Insufficient TON for NFT mint
        // Verify NFT collection is deployed
        throwUnless(410, self.nftCollectionAddress != null); // 410 - Collection not deployed
        
        // Track total TONCAST staked in DAO (deposit)
        self.totalCurrentlyStaked += msg.amount;
        
        // Build individual NFT content and mint message
        let individualContent: Cell = buildNftIndividualContent(
            msg.sender,
            self.nftNamePrefix,
            self.nftImageUrl,
            self.nextItemIndex,
            msg.amount
        );

        let mintMessage: Cell = buildMintMessage(
            msg.queryId,
            self.nextItemIndex,
            ton("0.05"),
            individualContent
        );
        
        // Send message to NFT collection to mint NFT
        message(MessageParameters{
            to: self.nftCollectionAddress!!,
            value: ton("0.06"),
            // mode: SendIgnoreErrors,
            body: mintMessage
        });
        
        // Increment NFT index for next mint
        self.nextItemIndex += 1;
        self.checkAndUpdateEpoch();
    }
    
    // Handle NFT transfer notification when NFT is sent to DAO for withdrawal
    receive(msg: NftTransferNotification) {
        // Allow withdrawals even if stopped (users should be able to get their funds back)
        // Verify NFT collection is deployed
        throwUnless(410, self.nftCollectionAddress != null); // 410 - Collection not deployed
        
        // Verify that NFT came from our collection
        // We need to get NFT data to verify it's from our collection
        let nftAddress: Address = sender();
        
        // Store pending withdrawal with query ID and previous owner
        self.pendingWithdrawals.set(nftAddress, msg.queryId);
        self.pendingWithdrawalOwners.set(nftAddress, msg.prevOwner);
        
        // Take 10% commission for withdrawal processing
        let incoming: Int = context().value;
        let commission: Int = incoming / 10; // 10% stays in DAO
        let availableForProcessing: Int = incoming - commission;
        
        // Request NFT data to verify and get staking info
        message(MessageParameters{
            to: nftAddress,
            value: availableForProcessing, // Use available value for processing
            mode: SendPayGasSeparately,
            body: NftGetAllData{
                queryId: msg.queryId
            }.toCell()
        });
    }
    
    // Handle NFT data response for withdrawal processing
    receive(msg: NftReportAllData) {
        let nftAddress: Address = sender();
        
        // Check if we have a pending withdrawal for this NFT
        let queryId: Int? = self.pendingWithdrawals.get(nftAddress);
        throwUnless(411, queryId != null); // 411 - No pending withdrawal
        
        // Get the original owner
        let originalOwner: Address? = self.pendingWithdrawalOwners.get(nftAddress);
        throwUnless(411, originalOwner != null); // 411 - No pending withdrawal owner
        
        // Verify query ID matches
        throwUnless(412, queryId!! == msg.queryId); // 412 - Query ID mismatch
        
        // Parse data from FunC format: ref(addresses) + ref(staking_data)
        let dataSlice: Slice = msg.data.beginParse();
        throwUnless(419, dataSlice.refs() >= 2); // 419 - Invalid message format
        
        // Load addresses from first ref
        let addrCell: Cell = dataSlice.loadRef();
        let addrSlice: Slice = addrCell.beginParse();
        let collection: Address = addrSlice.loadAddress();
        let owner: Address = addrSlice.loadAddress();
        
        // Load staking data from second ref
        let stakingDataCell: Cell = dataSlice.loadRef();
        
        // Verify NFT is from our collection
        throwUnless(413, collection == self.nftCollectionAddress!!); // 413 - Wrong collection
        
        // Calculate expected NFT address and verify it matches sender
        let expectedNftAddress: Address = calculateNftItemAddress(
            self.nftCollectionAddress!!,
            msg.index
        );
        throwUnless(418, nftAddress == expectedNftAddress); // 418 - Invalid NFT address
        
        // Verify NFT now belongs to DAO
        throwUnless(414, owner == myAddress()); // 414 - NFT not owned by DAO
        
        // Parse staking data
        let stakingData: StakingData = parseStakingData(stakingDataCell);
        
        // Verify DAO address matches (extra security check)
        throwUnless(417, stakingData.daoAddress == myAddress()); // 417 - Wrong DAO address
        
        // Remove from pending withdrawals
        let _ = self.pendingWithdrawals.del(nftAddress);
        let _ = self.pendingWithdrawalOwners.del(nftAddress);
        
        // Track total TONCAST staked in DAO (withdrawal)
        self.totalCurrentlyStaked -= stakingData.amount;
        
        // Get funds returned by NFT and take another 10% commission
        let afterCommission: Int = context().value - ton("0.01");
        
        // Calculate epochs to process
        let timeSinceDeployment: Int = stakingData.timestamp - self.deployTime;
        let stakingEpoch: Int = timeSinceDeployment / self.epochDuration;
        let firstCompleteEpoch: Int = stakingEpoch == 0 ? 0 : stakingEpoch + 1;
        let lastCompleteEpoch: Int = self.getCurrentEpochNumber() - 1;
        
        // Calculate exact funds needed for epoch processing
        let epochProcessingFunds: Int = 0;
        if (lastCompleteEpoch >= firstCompleteEpoch) {
            let epochsToProcess: Int = lastCompleteEpoch - firstCompleteEpoch + 1;
            // 0.01 TON per epoch + 0.02 TON for each batch processing message
            let batchCount: Int = (epochsToProcess + 99) / 100; // ceiling division
            epochProcessingFunds = ton("0.01") * epochsToProcess + ton("0.01") * batchCount;
        }
        
        // Calculate funds for Jetton transfer (all remaining after epoch reserve) must be greater than 0.1
        let jettonTransferFunds: Int = afterCommission - epochProcessingFunds; 
        // Send Jetton tokens back to the original owner
        let jettonWalletAddress: Address = calculateJettonWalletAddress(
            myAddress(),
            self.jettonMasterAddress
        );
        
        // Prepare Jetton transfer message
        let transferMessage: Cell = beginCell()
            .storeUint(0xf8a7ea5, 32) // op::transfer
            .storeUint(msg.queryId, 64)
            .storeCoins(stakingData.amount)
            .storeAddress(originalOwner!!)
            .storeAddress(originalOwner!!) // response_destination
            .storeMaybeRef(null) // custom_payload
            .storeCoins((jettonTransferFunds * 85) / 100) // forward_ton_amount - 85% of funds for notification
            .storeMaybeRef(null) // forward_payload
            .endCell();
        
        // Send Jetton transfer with calculated funds
        message(MessageParameters{
            to: jettonWalletAddress,
            value: jettonTransferFunds,
            mode: SendIgnoreErrors,
            body: transferMessage
        });

        // Send message to process epoch payouts if needed
        if (epochProcessingFunds > 0) {
            // Send internal message with exact funds for epoch processing
            message(MessageParameters{
                to: myAddress(),
                value: epochProcessingFunds,
                mode: SendPayGasSeparately,
                body: ProcessEpochPayouts{
                    userAddress: originalOwner!!,
                    withdrawnAmount: stakingData.amount,
                    startEpoch: firstCompleteEpoch,
                    endEpoch: lastCompleteEpoch
                }.toCell()
            });
        }
    }

    // Process batch payouts from epochs when user withdraws
    receive(msg: ProcessEpochPayouts) {
        // Only accept from self
        throwUnless(430, sender() == myAddress()); // 430 - Not self call
        
        // Calculate how many epochs to process in this batch
        let batchSize: Int = 100; // Process up to 100 epochs per batch
        let currentBatchEnd: Int = min(msg.startEpoch + batchSize - 1, msg.endEpoch);
        
        // Send payout requests to epochs in current batch
        let epochNum: Int = msg.startEpoch;
        while (epochNum <= currentBatchEnd) {
            let epochAddress: Address = calculateEpochContractAddress(epochNum, myAddress());
            
            // Send payout request to epoch
            // Using slightly more TON per epoch since we have remaining value available
            message(MessageParameters{
                to: epochAddress,
                value: ton("0.01"), 
                mode: SendIgnoreErrors,
                body: PayoutStaker{
                    queryId: 0, // Not needed for internal processing
                    stakerAddress: msg.userAddress,
                    stakerToncastAmount: msg.withdrawnAmount
                }.toCell()
            });
            
            epochNum += 1;
        }
        
        // If there are more epochs to process, send continuation message
        if (currentBatchEnd < msg.endEpoch) {
            // Use SendRemainingValue to pass all remaining TON to the next batch
            message(MessageParameters{
                to: myAddress(),
                value: 0, // 0 because we're using SendRemainingValue
                mode: SendRemainingValue | SendIgnoreErrors,
                body: ProcessEpochPayouts{
                    userAddress: msg.userAddress,
                    withdrawnAmount: msg.withdrawnAmount,
                    startEpoch: currentBatchEnd + 1,
                    endEpoch: msg.endEpoch
                }.toCell()
            });
        }
    }

    // Handle Deploy message: deploy NFT collection with on-chain metadata
    receive(deploy: Deploy) {
        // Ensure collection is not already set
        throwUnless(409, self.nftCollectionAddress == null);
        
        // Use incoming value for deploy (no strict min check; documented in README)
        let incoming: Int = context().value;

        // Keep 10% reserve for DAO
        let reserve: Int = incoming / 10;
        
        // Build collection content container with stored metadata
        let collectionContentContainer: Cell = beginCell().storeRef(self.collectionMetadata).storeRef(beginCell().endCell()).endCell();

        // Build initial data for collection
        let initData: Cell = buildCollectionInitData(
            myAddress(),
            TONCAST_NFT_ITEM_CODE,
            collectionContentContainer
        );

        // Prepare StateInit for collection contract
        let stateInit: StateInit = StateInit{
            code: TONCAST_NFT_COLLECTION_CODE,
            data: initData
        };
        let expectedAddress: Address = contractAddress(stateInit);

        // Deploy collection using stdlib helper
        deploy(DeployParameters{
            init: stateInit,
            value: incoming - reserve,
            mode: SendPayGasSeparately,
            body: null
        });

        // Save deployed collection address
        self.nftCollectionAddress = expectedAddress;
    }
    
    // Handle stop and redirect message from owner
    receive(msg: StopAndRedirect) {
        self.requireOwner(); // Only owner can stop
        self.stopped = true;
        self.newDaoAddress = msg.newDaoAddress;
        
        // Forward any remaining balance to new DAO
        let balance: Int = myBalance();
        if (balance > ton("0.05")) {
            message(MessageParameters{
                to: msg.newDaoAddress,
                value: balance - ton("0.05"),
                mode: SendIgnoreErrors,
                body: null
            });
        }
    }
    
    receive(msg: Slice) { 
            self.checkAndUpdateEpoch();
    }

    // Consolidated getter for all DAO configuration data
    get fun getDAOConfigData(): DAOConfigData {
        return DAOConfigData{
            nextItemIndex: self.nextItemIndex,
            nftCollectionAddress: self.nftCollectionAddress,
            jettonMasterAddress: self.jettonMasterAddress,
            jettonWalletAddress: calculateJettonWalletAddress(myAddress(), self.jettonMasterAddress),
            minDepositAmount: self.minDepositAmount,
            nftNamePrefix: self.nftNamePrefix,
            nftImageUrl: self.nftImageUrl,
            isReadyToAcceptDeposits: self.nftCollectionAddress != null,
            stopped: self.stopped,
            newDaoAddress: self.newDaoAddress
        };
    }
    
    // Consolidated getter for all epoch-related data
    get fun getDAOEpochData(): DAOEpochData {
        return DAOEpochData{
            deployTime: self.deployTime,
            currentRealTimeEpoch: self.getCurrentEpochNumber(),
            epochDuration: self.epochDuration,
            currentStoredEpochNumber: self.lastProcessedEpoch,  // Last epoch that was processed
            totalCurrentlyStaked: self.totalCurrentlyStaked
        };
    }
    
    // Getter for epoch contract address by number (kept separate as it requires a parameter)
    get fun getEpochContractAddress(epochNumber: Int): Address {
        return calculateEpochContractAddress(epochNumber, myAddress());
    }
    
    // Getter for collection metadata
    get fun getCollectionMetadata(): Cell {
        return self.collectionMetadata;
    }
}
