import "@stdlib/deploy";
import "@stdlib/ownable";
import "./constants.tact";
import "./messages.tact";
import "./structs.tact";

// Pyramida contract
contract Pyramida with Deployable, Ownable, GasManager, ReferralSystem, LotterySystem, JettonRewards {
    owner: Address;
    
    // Jetton fields
    jettonContent: Cell;
    jettonMasterAddress: Address;
    jettonRewardsStats: JettonRewardsStats;
    ownerJettonMinted: Bool;
    
    // GasManager fields
    oldIncrement: Int;
    increment: Int;
    gasStats: StorageStats;
    gasResults: GasDeductionResult;
    
    // ReferralSystem fields
    users: Users;
    
    // LotterySystem fields
    lotteryBank: LotteryBank;
    pastLotteryInfo: PastLotteryInformation;
    currentRound: CurrentLotteryRound;
    pendingRound: CurrentLotteryRound;
    drawState: DrawState;

    // Inactive-user pruning state
    pruneState: PruneState;

    // Contract initialization
    init(
        owner: Address, 
        jettonContent: Cell
    ) {
        self.owner = owner;
        self.ownerJettonMinted = false;
        self.jettonContent = jettonContent;

        // Initialize jetton
        let prmdInit: StateInit = initOf PRMDJettonMaster(owner, jettonContent, myAddress());  
        self.jettonMasterAddress = contractAddress(prmdInit);
        
        self.jettonRewardsStats = JettonRewardsStats{
            lastMintTime: now(),
            totalMinted: 0
        };

        // Initialize GasManager
        self.increment = 0;
        self.oldIncrement = 0;

        self.gasResults = GasDeductionResult{
            initialAmount: 0,
            gasAmount: 0,
            remainingAmount: 0,
            isEnough: false
        };

        self.gasStats = StorageStats{
            lastUpdateTime: now(),
            transactionCount: 0,
            totalTimeInterval: 0,
            totalStorageDueCollected: 0,
            reservedStorage: 0,
            storageLimit: 0,
            lastTonsReserve: 0,
            storageTonsDeficit: 0
        };
        
        // Initialize referral system
        self.users = Users{
            userData: emptyMap(),
            addresses: emptyMap(),
            lastKey: 0,
            userIndex: emptyMap(),
            userCount: 0
        };

        self.users.userData.set(OWNER_REFERRER_KEY, UserData{referrerKey: OWNER_REFERRER_KEY, address: owner, referralsCount: 0, earningsFromReferrals: 0, lastActivity: now()});
        self.users.addresses.set(owner, OWNER_REFERRER_KEY);
        // Owner occupies position 0 in the compact live-user index.
        self.users.userIndex.set(0, OWNER_REFERRER_KEY);
        self.users.userCount = 1;

        // Initialize lottery
        self.lotteryBank = LotteryBank{
            balance: 0,
        };
        self.pastLotteryInfo = PastLotteryInformation{
            lastLotteryTime: now(),
            lastWinnerKey: 0,
            lastWinnerAddress: newAddress(0, 0),
            lastWinAmount: 0,
            totalWinsAmount: 0,
            totalWinners: 0
        };

        self.currentRound = CurrentLotteryRound{
            endTime: now() + LOTTERY_ROUND_DURATION,
            ticketMap: emptyMap(),
            participantList: emptyMap(),
            totalTickets: 0,
            participantsCount: 0
        };

        self.pendingRound = CurrentLotteryRound{
            endTime: 0,
            ticketMap: emptyMap(),
            participantList: emptyMap(),
            totalTickets: 0,
            participantsCount: 0
        };

        self.drawState = DrawState{
            isDrawing: false,
            cursor: 0,
            accumulated: 0,
            randomTarget: 0,
            winnerKey: 0,
            winnerFound: false,
            snapshotParticipants: 0,
            prizeAmount: 0,
            ownerShareAmount: 0,
            lastProgressTime: 0
        };

        self.pruneState = PruneState{
            cursor: 0
        };
    }

    fun setOwner(oldOwner: UserData, newOwner: Address, amount: Int): Bool {
        require(newOwner != newAddress(0, 0), "Owner cannot be zero");
        require(newOwner != self.owner, "Owner cannot be the same");
        require(self.users.addresses.get(newOwner) == null, "User already exists");

        let oldOwnerAddress: Address = oldOwner.address;
        let newKeyForOldOwner: Int = self.users.lastKey + 1;
        self.users.lastKey = newKeyForOldOwner;
        self.increment += 1;
        self.owner = newOwner;
        let ownerReferralsCount: Int = oldOwner.referralsCount;
        self.users.userData.set(OWNER_REFERRER_KEY, UserData{referrerKey: OWNER_REFERRER_KEY, address: newOwner, referralsCount: ownerReferralsCount, earningsFromReferrals: 0, lastActivity: now()});
        self.users.addresses.set(newOwner, OWNER_REFERRER_KEY);
        // Old owner becomes a regular (prunable) user with a fresh key; register it
        // in the compact live-user index as well.
        self.users.userData.set(newKeyForOldOwner, UserData{referrerKey: OWNER_REFERRER_KEY, address: oldOwnerAddress, referralsCount: 0, earningsFromReferrals: oldOwner.earningsFromReferrals, lastActivity: now()});
        self.users.addresses.set(oldOwnerAddress, newKeyForOldOwner);
        self.users.userIndex.set(self.users.userCount, newKeyForOldOwner);
        self.users.userCount += 1;
        send(SendParameters{
            to: self.jettonMasterAddress,
            value: self.getGasResults(amount).remainingAmount,
            bounce: false,
            mode: SendIgnoreErrors,
            body: ChangeJettonMasterOwner{
                queryId: randomInt() % (1 << 64),
                owner: newOwner
            }.toCell()
        });
        return true;
    }

    // GasManager abstract methods
    override fun getGasResults(incomingTons: Int): GasDeductionResult {
        if (self.oldIncrement != self.increment) {
            self.gasResults = self.deductGas(incomingTons);
            self.oldIncrement = self.increment;
        }
        return self.gasResults;
    }
    
    override fun getStorageStats(): StorageStats {
        return self.gasStats;
    }
    
    override fun setStorageStats(stats: StorageStats): Bool {
        self.gasStats = stats;
        return true;
    }

    // LotterySystem abstract methods
    
    override fun getCurrentRound(): CurrentLotteryRound {
        return self.currentRound;
    }
    
    override fun setCurrentRound(round: CurrentLotteryRound): Bool {
        self.currentRound = round;
        return true;
    }

    override fun getLotteryBank(): LotteryBank {
        return self.lotteryBank;
    }

    override fun setLotteryBank(bank: LotteryBank): Bool {
        self.lotteryBank = bank;
        return true;
    }

    override fun getAvailableForPrize(): Int {
        let stats: StorageStats = self.getStorageStats();
        return max(0, myBalance() - stats.reservedStorage - MIN_CONTRACT_BALANCE);
    }

    override fun getDrawState(): DrawState {
        return self.drawState;
    }

    override fun setDrawState(state: DrawState): Bool {
        self.drawState = state;
        return true;
    }

    override fun getPruneState(): PruneState {
        return self.pruneState;
    }

    override fun setPruneState(state: PruneState): Bool {
        self.pruneState = state;
        return true;
    }

    override fun getPendingRound(): CurrentLotteryRound {
        return self.pendingRound;
    }

    override fun setPendingRound(round: CurrentLotteryRound): Bool {
        self.pendingRound = round;
        return true;
    }

    override fun sendLotteryPrize(winnerKey: Int, prize: Int): Bool {
        let user: UserData? = self.users.userData.get(winnerKey);
        if (user == null) {
            // Winner is no longer in the registry (e.g. pruned after a long
            // dormant round). Refund the prize back to the bank instead of
            // silently losing it, so the up-front bank debit in drawLottery()
            // is never stranded. Safety net for any index<->userData desync.
            let bank: LotteryBank = self.getLotteryBank();
            bank.balance += prize;
            self.setLotteryBank(bank);
            return false;
        }
        let text: StringBuilder = beginString();

        if (winnerKey != OWNER_REFERRER_KEY){
            self.pastLotteryInfo.lastLotteryTime = now();
            self.pastLotteryInfo.lastWinnerKey = winnerKey;
            self.pastLotteryInfo.lastWinnerAddress = user!!.address;
            self.pastLotteryInfo.lastWinAmount = prize;
            self.pastLotteryInfo.totalWinsAmount += prize;
            self.pastLotteryInfo.totalWinners += 1;

            text.append("Congratulations! You are the Pyramida Lottery Winner №");
            text.append(self.pastLotteryInfo.totalWinners.toString());
            text.append("!");
        } else {
            text.append("Congratulations! You are the Pyramida Lottery Owner!");
        }

        send(SendParameters{
                to: user!!.address,
                value: prize,
                mode: SendIgnoreErrors,
                body: text.toString().asComment()
            });

        return true;
    }

    // ReferralSystem abstract methods
    override fun getUsers(): Users {
        return self.users;
    }
    
    override fun setUsers(users: Users): Bool {
        self.users = users;
        return true;
    }
    
    override fun getUserData(key: Int): UserData? {
        return self.users.userData.get(key);
    }

    override fun isProtectedFromPruning(userKey: Int): Bool {
        return self.currentRound.ticketMap.get(userKey) != null
            || self.pendingRound.ticketMap.get(userKey) != null;
    }
    
    override fun sendCommissions(incomingTons: Int, commissions: map<Address, Int>): Int {
        let totalCommission: Int = 0;
        foreach (address, amount in commissions) {
            let userKey: Int? = self.users.addresses.get(address);
            if (userKey != null) {
                let userData: UserData? = self.users.userData.get(userKey!!);
                if (userData != null) {
                    self.users.userData.set(userKey!!, UserData{referrerKey: userData!!.referrerKey, address: address, referralsCount: userData!!.referralsCount, earningsFromReferrals: userData!!.earningsFromReferrals + amount, lastActivity: now()});
                }
            }
            send(SendParameters{
                to: address,
                value: amount,
                mode: SendIgnoreErrors,
                body: "Referral commission from Pyramida Lottery".asComment()
            });
            totalCommission += amount;
        }
        return max(0, incomingTons - totalCommission);
    }

    // JettonRewards abstract methods
    override fun getJettonRewardsStats(): JettonRewardsStats {
        return self.jettonRewardsStats;
    }
    
    override fun setJettonRewardsStats(stats: JettonRewardsStats): Bool {
        self.jettonRewardsStats = stats;
        return true;
    }
    
    override fun sendJetton(address: Address, amount: Int): Bool {
        send(SendParameters{
            to: self.jettonMasterAddress,
            value: ton("0.1"),
            bounce: true,
            mode: SendIgnoreErrors,
            body: MintJetton{
                queryId: randomInt() % (1 << 64),
                amount: amount,
                receiver: address,
                responseDestination: myAddress(),
                forwardAmount: FORWARD_AMOUNT,
                forwardPayload: null
            }.toCell()
        });
        return true;
    }
    
    // Handle empty messages (simple TON transfer)
    receive() {
        let context: Context = context();
        require(context.value >= MIN_LOTTERY_ENTRY, "No enough TON");
        self.reserveBalance();
        self.increment += 1;
        let incomingTons: Int = context.value;
        
        let referrerKey: Int = OWNER_REFERRER_KEY;
        
        let userKey: Int? = self.users.addresses.get(context.sender);
        if (userKey != null) {
            let userData: UserData? = self.users.userData.get(userKey!!);
            if (userData != null) {
                referrerKey = userData!!.referrerKey;
            }
        }
        
        let commissions: map<Address, Int> = self.getCommissions(context.sender, referrerKey, incomingTons);
        let remainder: Int = self.sendCommissions(incomingTons, commissions);

        userKey = self.users.addresses.get(context.sender);

        if (userKey != null) {  
            self.addTicketsToLottery(userKey!!, incomingTons);
            self.touchUser(userKey!!);
        }
                
        if (self.jettonRewardsStats.totalMinted < MAX_SUPPLY) {
            let jettonsForMint: Int = self.mintJetton();
            if (jettonsForMint > 0) {
                self.sendJetton(context.sender, jettonsForMint);
                remainder = max(0, remainder - ton("0.1"));
            }
        }

        self.lotteryBank.balance += self.getGasResults(remainder).remainingAmount;
        self.amortizedPrune();
    }
    
    // Receiver for messages with text comments
    receive(str: String) {
        let context: Context = context();
        require(context.value >= MIN_LOTTERY_ENTRY, "No enough TON");
        self.reserveBalance();
        self.increment += 1;
        let incomingTons: Int = context.value;
        
        let referrerKey: Int = OWNER_REFERRER_KEY;
        
        let userKey: Int? = self.users.addresses.get(context.sender);
        if (userKey != null) {
            let userData: UserData? = self.users.userData.get(userKey!!);
            if (userData != null) {
                referrerKey = userData!!.referrerKey;
            }
        } else {
            let commentSlice: Slice = str.asSlice();
            let key: Int = 0;
            let isValid: Bool = true;
            let digits: Int = 0;

            while (!commentSlice.empty() && commentSlice.dataEmpty() == false && isValid && digits < MAX_REFERRER_KEY_DIGITS) {
                let char: Int = commentSlice.loadUint(8);
                if (char >= 48 && char <= 57) {
                    key = (key * 10) + (char - 48);
                    digits += 1;
                } else {
                    isValid = false;
                }
            }
            
            if (isValid && key > 0) {
                if (self.users.userData.get(key) != null) {
                    referrerKey = key;
                }
            }
        }
        
        let commissions: map<Address, Int> = self.getCommissions(context.sender, referrerKey, incomingTons);
        let remainder: Int = self.sendCommissions(incomingTons, commissions);
        
        userKey = self.users.addresses.get(context.sender);
        
        if (userKey != null) {  
            self.addTicketsToLottery(userKey!!, incomingTons);
            self.touchUser(userKey!!);
        }
        
        if (self.jettonRewardsStats.totalMinted < MAX_SUPPLY) {
            let jettonsForMint: Int = self.mintJetton();
            if (jettonsForMint > 0) {
                self.sendJetton(context.sender, jettonsForMint);
                remainder = max(0, remainder - ton("0.1"));
            }
        }
        
        self.lotteryBank.balance += self.getGasResults(remainder).remainingAmount;
        self.amortizedPrune();
    }

    // Jetton burn receiver
    receive(msg: JettonsBurned) {
        let context: Context = context();
        require(self.jettonMasterAddress == context.sender, "Only Pyramida JettonMaster contract can update total amount");
        self.reserveBalance();
        self.increment += 1;
        self.jettonRewardsStats.totalMinted = max(0,self.jettonRewardsStats.totalMinted - msg.amount);
        self.jettonRewardsStats.totalMinted = max(0,(self.jettonRewardsStats.totalMinted+msg.totalSupply)/2);
        self.lotteryBank.balance += self.getGasResults(context.value).remainingAmount;
    }
    
    // Set JettonMaster address
    receive(msg: UpdateJettonMasterAddress) {
        let context: Context = context();
        require(context.sender == self.owner, "Only owner can set jetton master");
        self.reserveBalance();
        self.jettonMasterAddress = msg.address;
        self.increment += 1;
        self.lotteryBank.balance += self.getGasResults(context.value).remainingAmount;
    }
    
    // Change owner
    receive(msg: ChangePyramidaOwner) {
        let context: Context = context();
        require(context.sender == self.owner, "Only owner can change owner");
        require(context.value >= MIN_LOTTERY_ENTRY, "Amount too small for owner change");
        self.reserveBalance();
        let ownerData: UserData? = self.users.userData.get(OWNER_REFERRER_KEY);
        self.setOwner(ownerData!!, msg.owner, context.value);
        self.increment += 1;
        self.lotteryBank.balance += self.getGasResults(context.value).remainingAmount;
    }
    
    // Trigger lottery draw (separate transaction, full gas budget).
    // Accepted ONLY from the contract itself (self-message) — nobody else can trigger a draw.
    receive(msg: DrawLottery) {
        let context: Context = context();
        require(context.sender == myAddress(), "DrawLottery can only be sent by the contract itself");
        self.reserveBalance();
        self.increment += 1;
        self.drawLottery();
        self.lotteryBank.balance += self.getGasResults(context.value).remainingAmount;
    }

    // Receive excesses
    receive(msg: Excesses) {
        let context: Context = context();
        self.reserveBalance();
        self.increment += 1;
        self.lotteryBank.balance += self.getGasResults(context.value).remainingAmount;
    }

    // Mint initial jettons to owner
    receive(msg: MintInitJettonsToOwner) {
        let context: Context = context();
        let myAddress: Address = myAddress();
        require(context.sender == self.owner, "Only owner can mint initial jettons");
        require(self.ownerJettonMinted == false, "Owner jettons already minted");
        self.reserveBalance();
        let prmdInit: StateInit = initOf PRMDJettonMaster(self.owner, self.jettonContent, myAddress);
        let jettonMasterAddress: Address = contractAddress(prmdInit);
        self.jettonMasterAddress = jettonMasterAddress;

        send(SendParameters{
            to: self.jettonMasterAddress,
            value: ton("0.9"),
            mode: SendIgnoreErrors,
            bounce: true,
            code: prmdInit.code,
            data: prmdInit.data,
            body: MintJetton{
                queryId: randomInt() % (1 << 64),
                amount: INITIAL_SUPPLY,
                receiver: self.owner,
                responseDestination: myAddress,
                forwardAmount: FORWARD_AMOUNT,
                forwardPayload: null
            }.toCell()
        });
        self.jettonRewardsStats.totalMinted += INITIAL_SUPPLY;
        self.ownerJettonMinted = true;
        self.increment += 1;
        self.lotteryBank.balance += max(0, self.getGasResults(context.value).remainingAmount - ton("0.9"));
    }

    // Handle return on failed token minting
    bounced(src: bounced<MintJetton>) {
        self.jettonRewardsStats.totalMinted = max(0, self.jettonRewardsStats.totalMinted - src.amount);
    }

    // Getters

    // Constant-size global snapshot. Deliberately excludes the on-chain maps so
    // the response never grows with state size (see structs.tact). A single
    // user data is read on demand via getUserByAddress(address).
    get fun getPyramidaState(): PyramidaState {
        return PyramidaState{
            lotteryBank: self.lotteryBank,
            pastLotteryInfo: self.pastLotteryInfo,
            currentRound: CurrentRoundSummary{
                endTime: self.currentRound.endTime,
                totalTickets: self.currentRound.totalTickets,
                participantsCount: self.currentRound.participantsCount
            },
            drawState: self.drawState,
            pruneState: self.pruneState,
            users: UsersSummary{
                lastKey: self.users.lastKey,
                userCount: self.users.userCount
            },
            jettonRewardsStats: self.jettonRewardsStats,
            owner: self.owner,
            jettonMasterAddress: self.jettonMasterAddress,
            availableForPrize: self.getAvailableForPrize()
        };
    }

    // O(1) lookup of a single user's record by address. Returns registered=false
    // (and zeroed fields) when the address has never registered. This is the
    // scalable per-user read path — the web app calls it only for the connected
    // wallet instead of downloading the whole user map.
    get fun getUserByAddress(userAddress: Address): UserView {
        let key: Int? = self.users.addresses.get(userAddress);
        if (key == null) {
            return UserView{
                registered: false,
                key: 0,
                referrerKey: 0,
                address: userAddress,
                referralsCount: 0,
                earningsFromReferrals: 0,
                lastActivity: 0
            };
        }
        let data: UserData? = self.users.userData.get(key!!);
        if (data == null) {
            return UserView{
                registered: false,
                key: key!!,
                referrerKey: 0,
                address: userAddress,
                referralsCount: 0,
                earningsFromReferrals: 0,
                lastActivity: 0
            };
        }
        return UserView{
            registered: true,
            key: key!!,
            referrerKey: data!!.referrerKey,
            address: data!!.address,
            referralsCount: data!!.referralsCount,
            earningsFromReferrals: data!!.earningsFromReferrals,
            lastActivity: data!!.lastActivity
        };
    }

    // DIAGNOSTIC ONLY — returns the full user registry INCLUDING the maps.
    // The web app never calls this: its response grows linearly with state size
    // and is not safe to invoke at scale. It exists so internal-correctness
    // tests (pruning swap-remove, userIndex compaction) can inspect map
    // internals. Get methods run off-chain only, so this has no on-chain cost
    // and cannot affect contract execution. Production reads go through
    // getPyramidaState (lean) and getUserByAddress (O(1) per user).
    get fun getUsersState(): Users {
        return self.users;
    }
}

// PRMD jetton master
@interface("org.ton.jetton.master")
contract PRMDJettonMaster with JettonMaster {
    owner: Address;
    pyramidaAddress: Address;
    content: Cell;
    totalSupply: Int as coins;
    mintable: Bool;

    init(owner: Address, content: Cell, pyramidaAddress: Address) {
        self.owner = owner;
        self.content = content;
        self.totalSupply = 0;
        self.mintable = true;
        self.pyramidaAddress = pyramidaAddress;
    }
}

// PRMD jetton wallet
@interface("org.ton.jetton.wallet")
contract PRMDJettonWallet with JettonWallet {
    balance: Int as coins;
    owner: Address;
    master: Address;

    init(master: Address, owner: Address) {
        self.balance = 0;
        self.owner = owner;
        self.master = master;
    }
}

// =====================================
// Traits for implementing the Jetton standard
// =====================================

@interface("org.ton.jetton.master")
trait JettonMaster with Ownable {
    owner: Address;
    pyramidaAddress: Address;
    content: Cell;
    totalSupply: Int as coins;
    mintable: Bool;

    // === Jetton standard methods (TEP-74) === //
    
    // Change owner of the contract
    receive(msg: ChangeJettonMasterOwner) {
        let ctx: Context = context();
        require(ctx.sender == self.owner || ctx.sender == self.pyramidaAddress, "Not owner");
        self.owner = msg.owner;
    }
    
    // Update token content
    receive(msg: UpdateJettonContent) {
        self.requireOwner();
        self.content = msg.content;
    }
    
    // Disable minting
    receive(msg: StopMinting) {
        let ctx: Context = context();
        require(ctx.sender == self.owner || ctx.sender == self.pyramidaAddress, "Not owner");
        self.mintable = false;
    }
    
    // Minting. Deploys/credits the receiver's wallet and carries the remaining
    // attached value forward (SendRemainingValue), so the receiver gets the
    // standard transfer_notification funded by `forwardAmount`.
    receive(msg: MintJetton) {
        let ctx: Context = context();
        require(ctx.sender == self.owner || ctx.sender == self.pyramidaAddress, "Not owner");
        require(self.mintable, "Not mintable");
        require(msg.amount > 0, "Amount should be positive");

        let mintAmount: Int = msg.amount;
        if (self.totalSupply + mintAmount > MAX_SUPPLY) {
            mintAmount = MAX_SUPPLY - self.totalSupply;
            self.mintable = false;
        }
        self.totalSupply += mintAmount;

        require(
            ctx.value >
                minTonsForStorage +
                msg.forwardAmount +
                ctx.readForwardFee() +
                getForwardFee(walletStateInitCells, walletStateInitBits, false) +
                2 * getComputeFee(gasForTransfer, false),
            "Insufficient gas for mint",
        );

        let jettonWallet = self.getJettonWalletInit(msg.receiver);
        send(SendParameters{
            to: contractAddress(jettonWallet),
            value: 0,
            bounce: true,
            mode: SendRemainingValue | SendBounceIfActionFail,
            body: TokenTransferInternal{
                queryId: msg.queryId,
                amount: mintAmount,
                from: myAddress(),
                responseDestination: msg.responseDestination,
                forwardAmount: msg.forwardAmount,
                forwardPayload: emptySlice()
            }.toCell(),
            code: jettonWallet.code,
            data: jettonWallet.data
        });
    }
    
    // Multiple minting (admin airdrop). Each receiver gets its own value paid
    // separately; leftover is returned to the sender.
    receive(msg: MultiMint) {
        let ctx: Context = context();
        require(ctx.sender == self.owner || ctx.sender == self.pyramidaAddress, "Not owner");
        require(self.mintable, "Not mintable");
        require(msg.receiverCount > 0, "receiverCount must be positive");

        let tonBalanceBeforeMsg: Int = myBalance() - ctx.value;
        let minPerReceiver: Int = minTonsForStorage + 2 * getComputeFee(gasForTransfer, false);
        let i: Int = 0;

        while (i < msg.receiverCount && self.mintable) {
            let receiver = msg.receivers.get(i);
            i += 1;
            require(receiver != null, "Invalid receiver");
            require(receiver!!.amount > 0, "Amount should be positive");
            require(receiver!!.tonAmount > receiver!!.forwardAmount + minPerReceiver, "Insufficient ton amount");

            let mintAmount = receiver!!.amount;
            if (self.totalSupply + mintAmount > MAX_SUPPLY) {
                mintAmount = MAX_SUPPLY - self.totalSupply;
                self.mintable = false;
            }
            self.totalSupply += mintAmount;

            let jettonWallet = self.getJettonWalletInit(receiver!!.receiver);
            send(SendParameters{
                to: contractAddress(jettonWallet),
                value: receiver!!.tonAmount,
                bounce: true,
                mode: SendPayGasSeparately,
                body: TokenTransferInternal{
                    queryId: msg.queryId,
                    amount: mintAmount,
                    from: myAddress(),
                    responseDestination: receiver!!.responseDestination,
                    forwardAmount: receiver!!.forwardAmount,
                    forwardPayload: emptySlice()
                }.toCell(),
                code: jettonWallet.code,
                data: jettonWallet.data
            });
        }

        // Keep the master solvent, then return any leftover to the sender.
        nativeReserve(max(tonBalanceBeforeMsg, minTonsForStorage), ReserveAtMost);
        send(SendParameters{
            to: ctx.sender,
            value: 0,
            bounce: false,
            mode: SendRemainingBalance | SendIgnoreErrors,
            body: Excesses{
                queryId: msg.queryId
            }.toCell()
        });
    }
    
    // Handle Jetton burn notifications. Decrements supply and forwards the
    // remaining value to the Pyramida lottery (it credits leftover gas to the
    // bank — a deliberate product behavior for this rewards token).
    receive(msg: TokenBurnNotification) {
        let ctx: Context = context();
        require(msg.amount > 0, "Amount should be positive");

        let walletInit = self.getJettonWalletInit(msg.sender);
        require(contractAddress(walletInit) == ctx.sender, "Invalid sender");

        self.totalSupply = max(0, self.totalSupply - msg.amount);
        if (self.totalSupply < MAX_SUPPLY) {
            self.mintable = true;
        }

        send(SendParameters{
            to: self.pyramidaAddress,
            value: 0,
            bounce: false,
            mode: SendRemainingValue | SendIgnoreErrors,
            body: JettonsBurned{
                queryId: msg.queryId,
                amount: msg.amount,
                totalSupply: self.totalSupply
            }.toCell()
        });
    }
    
    // Provide wallet address (TEP-89 discovery).
    receive(msg: ProvideWalletAddress) {
        let ctx: Context = context();
        let walletAddress = self.getWalletAddress(msg.ownerAddress);
        
        send(SendParameters{
            to: ctx.sender,
            value: 0,
            bounce: false,
            mode: SendRemainingValue,
            body: TakeWalletAddress{
                queryId: msg.queryId,
                walletAddress: walletAddress,
                ownerAddress: msg.includeAddress ? 
                    beginCell().storeBool(true).storeAddress(msg.ownerAddress).endCell().asSlice() :
                    beginCell().storeBool(false).endCell().asSlice()
            }.toCell()
        });
    }
    
    // Handle TokenTransferInternal return on failed minting
    bounced(src: bounced<TokenTransferInternal>) {
        self.totalSupply = max(0, self.totalSupply - src.amount);
    }
    
    // === Internal methods === //
    
    // Get initialization of jetton wallet
    virtual fun getJettonWalletInit(owner: Address): StateInit {
        return initOf PRMDJettonWallet(myAddress(), owner);
    }
    
    // Get wallet address
    fun getWalletAddress(owner: Address): Address {
        return contractAddress(self.getJettonWalletInit(owner));
    }
    
    // === Get methods === //
    
    // Get jetton data
    get fun get_jetton_data(): JettonMasterData {
        return JettonMasterData{
            totalSupply: self.totalSupply,
            mintable: self.mintable,
            owner: self.owner,
            content: self.content,
            walletCode: self.getJettonWalletInit(myAddress()).code
        };
    }
    
    // Get wallet address
    get fun get_wallet_address(owner: Address): Address {
        return self.getWalletAddress(owner);
    }
}

@interface("org.ton.jetton.wallet")
trait JettonWallet {
    balance: Int as coins;
    owner: Address;
    master: Address;

    // === Jetton standard methods (TEP-74) === //
    
    // Outgoing transfer initiated by the wallet owner. Carries the remaining
    // attached value forward (SendRemainingValue) and honors the sender's
    // `forwardAmount` (forward_ton_amount), so DEX routers/pools receive exactly
    // the gas they requested for their transfer_notification.
    receive(msg: TokenTransfer) {
        forceBasechain(msg.destination);
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Incorrect sender");
        require(msg.amount > 0, "Amount should be positive");

        self.balance = self.balance - msg.amount;
        require(self.balance >= 0, "Insufficient balance");

        // Require enough TON to deploy the destination wallet, pay the forward
        // notification, the two outgoing message forward fees and compute, and
        // keep a storage reserve. `forwardAmount` is positive -> 2 forwards.
        let fwdCount: Int = 1 + sign(msg.forwardAmount);
        require(
            ctx.value >
                msg.forwardAmount +
                fwdCount * ctx.readForwardFee() +
                getForwardFee(walletStateInitCells, walletStateInitBits, false) +
                (2 * getComputeFee(gasForTransfer, false) + minTonsForStorage),
            "Insufficient amount of TON attached",
        );

        let receiverWalletInit = initOf PRMDJettonWallet(self.master, msg.destination);
        send(SendParameters{
            to: contractAddress(receiverWalletInit),
            value: 0,
            bounce: true,
            mode: SendRemainingValue,
            body: TokenTransferInternal{
                queryId: msg.queryId,
                amount: msg.amount,
                from: self.owner,
                responseDestination: msg.responseDestination,
                forwardAmount: msg.forwardAmount,
                forwardPayload: msg.forwardPayload
            }.toCell(),
            code: receiverWalletInit.code,
            data: receiverWalletInit.data
        });
    }
    
    // Incoming internal transfer from the master (mint) or another wallet.
    receive(msg: TokenTransferInternal) {
        let ctx: Context = context();
        self.balance = self.balance + msg.amount;

        // Accept only from the master, or from the sender's own jetton wallet.
        if (ctx.sender != self.master) {
            let senderWalletInit = initOf PRMDJettonWallet(self.master, msg.from);
            require(contractAddress(senderWalletInit) == ctx.sender, "Incorrect sender");
        }

        let msgValue: Int = ctx.value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;

        // Forward the requested notification value to the owner (e.g. the DEX
        // pool/router), funded by the sender's forward_ton_amount.
        if (msg.forwardAmount > 0) {
            let fwdFee: Int = ctx.readForwardFee();
            msgValue = msgValue - msg.forwardAmount - fwdFee;
            send(SendParameters{
                to: self.owner,
                value: msg.forwardAmount,
                bounce: false,
                mode: SendPayGasSeparately,
                body: TransferNotification{
                    queryId: msg.queryId,
                    amount: msg.amount,
                    sender: msg.from,
                    forwardPayload: msg.forwardPayload
                }.toCell()
            });
        }

        // Keep the wallet solvent, then return any unused TON to the original sender.
        nativeReserve(max(tonBalanceBeforeMsg, minTonsForStorage), ReserveAtMost);
        if (msg.responseDestination != null && msgValue > 0) {
            send(SendParameters{
                to: msg.responseDestination!!,
                value: msgValue,
                bounce: false,
                mode: SendRemainingBalance | SendIgnoreErrors,
                body: Excesses{
                    queryId: msg.queryId
                }.toCell()
            });
        }
    }
    
    // Jetton burning
    receive(msg: Burn) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Incorrect sender");
        require(msg.amount > 0, "Amount should be positive");

        self.balance = self.balance - msg.amount;
        require(self.balance >= 0, "Insufficient balance");

        let fwdFee: Int = ctx.readForwardFee();
        require(ctx.value > fwdFee + 2 * getComputeFee(gasForBurn, false), "Insufficient amount of TON attached");

        send(SendParameters{
            to: self.master,
            value: 0,
            bounce: true,
            mode: SendRemainingValue,
            body: TokenBurnNotification{
                queryId: msg.queryId,
                amount: msg.amount,
                sender: self.owner,
                responseDestination: msg.responseDestination
            }.toCell()
        });
    }
    
    // Handle returns
    bounced(src: bounced<TokenTransferInternal>) {
        self.balance += src.amount;
    }
    
    bounced(src: bounced<TokenBurnNotification>) {
        self.balance += src.amount;
    }
    
    // === Get methods === //
    
    // Get wallet data
    get fun get_wallet_data(): JettonWalletData {
        return JettonWalletData{
            balance: self.balance,
            owner: self.owner,
            master: self.master,
            walletCode: initOf PRMDJettonWallet(self.master, myAddress()).code
        };
    }
}

trait GasManager {
    abstract fun getStorageStats(): StorageStats;
    abstract fun setStorageStats(stats: StorageStats): Bool;
    abstract fun getGasResults(incomingTons: Int): GasDeductionResult;
    
    virtual fun deductGas(
        incomingTons: Int
    ): GasDeductionResult {
        let stats: StorageStats = self.getStorageStats();
        let updatedStats: StorageStats = self.updateStorageStats(stats);

        let acceleratedTime = max(1, STORAGE_PERIOD/10);

        let storageLimit: Int = self.calculateAdaptiveStorageFee(updatedStats);
        updatedStats.storageLimit = storageLimit;
                
        let storageTonsDeficit: Int = max(1, storageLimit - updatedStats.reservedStorage);
        updatedStats.storageTonsDeficit = storageTonsDeficit;

        let avgStorageDuePerTransaction: Int = max(1, updatedStats.totalStorageDueCollected / updatedStats.transactionCount);
        let avgInterval: Int = max(1, updatedStats.totalTimeInterval / updatedStats.transactionCount);
        
        let needTransactionCount: Int = max(1, storageTonsDeficit / max(1,avgStorageDuePerTransaction));
        let storagePeriodPercent: Int = max(1, ((needTransactionCount*avgInterval)*100) / (acceleratedTime));
        let storageLimitPercent: Int = max(1, storageTonsDeficit*100 / max(1,storageLimit));
        let myStorageDue: Int = myStorageDue();

        let additionalStorageNeeded: Int = max(myStorageDue, avgStorageDuePerTransaction) * (max(120, 100 + (((storagePeriodPercent+storageLimitPercent)/2) * (myStorageDue / avgStorageDuePerTransaction))))/100;
        
        let computeGas: Int = self.getComputeGas();
        let totalGasNeeded: Int = additionalStorageNeeded + computeGas;
        
        let isEnough: Bool = incomingTons >= totalGasNeeded;
        
        let availableForStorage: Int = max(0, incomingTons - computeGas);
        let storageReserveNow: Int = min(additionalStorageNeeded, availableForStorage);
        
        if (storageReserveNow > 0) {
            updatedStats.reservedStorage += storageReserveNow;
            updatedStats.lastTonsReserve = storageReserveNow;
        }
        
        let gasToDeduct: Int = min(incomingTons, computeGas + storageReserveNow);
        let remainingAmount: Int = max(0, incomingTons - gasToDeduct);
        self.setStorageStats(updatedStats);
        
        return GasDeductionResult {
            initialAmount: incomingTons,
            gasAmount: gasToDeduct,
            remainingAmount: remainingAmount,
            isEnough: isEnough
        };
    }
    

    virtual fun updateStorageStats(stats: StorageStats): StorageStats {
        let currentTime: Int = now();
        
        let currentStorageDue: Int = max(1, myStorageDue());
        
        if (stats.transactionCount == 0) {
            return StorageStats{
                lastUpdateTime: currentTime,
                transactionCount: 1,
                totalTimeInterval: 1,
                totalStorageDueCollected: currentStorageDue,
                reservedStorage: 0,
                storageLimit: 0,
                lastTonsReserve: 0,
                storageTonsDeficit: 0
            };
        }

        let timeInterval: Int = currentTime - stats.lastUpdateTime;
        
        if (stats.transactionCount < 100) {
            let newCount: Int = stats.transactionCount + 1;
            let newTotalInterval: Int = max(1,stats.totalTimeInterval + timeInterval);
            let newTotalDue: Int = stats.totalStorageDueCollected + currentStorageDue;
            
            let avgStorageDuePerSecond: Int = newTotalDue / newTotalInterval;
                        
            let estimatedSpent: Int = avgStorageDuePerSecond * timeInterval;
            
            let newReservedStorage: Int = max(0, stats.reservedStorage - estimatedSpent);
            
            return StorageStats{
                lastUpdateTime: currentTime,
                transactionCount: newCount,
                totalTimeInterval: newTotalInterval,
                totalStorageDueCollected: newTotalDue,
                reservedStorage: newReservedStorage,
                storageLimit: stats.storageLimit,
                lastTonsReserve: stats.lastTonsReserve,
                storageTonsDeficit: stats.storageTonsDeficit
            };
        }
        
        let avgInterval: Int = 0;
        let avgStorageDuePerTransaction: Int = 0;
        
        avgInterval = stats.totalTimeInterval / max(1, stats.transactionCount);
        avgStorageDuePerTransaction = stats.totalStorageDueCollected / max(1, stats.transactionCount);
        

        let newTotalInterval: Int = stats.totalTimeInterval - avgInterval + timeInterval;
        let newTotalDue: Int = stats.totalStorageDueCollected - avgStorageDuePerTransaction + currentStorageDue;
        
        let avgStorageDuePerSecond: Int = newTotalDue / newTotalInterval;
        
        let estimatedSpent: Int = avgStorageDuePerSecond * timeInterval;
        
        let newReservedStorage: Int = max(0, stats.reservedStorage - estimatedSpent);
        
        return StorageStats{
            lastUpdateTime: currentTime,
            transactionCount: 100, 
            totalTimeInterval: newTotalInterval,
            totalStorageDueCollected: newTotalDue,
            reservedStorage: newReservedStorage,
            storageLimit: stats.storageLimit,
            lastTonsReserve: stats.lastTonsReserve,
            storageTonsDeficit: stats.storageTonsDeficit
        };
    }
    
    virtual fun calculateAdaptiveStorageFee(stats: StorageStats): Int {
        let myStorageDue: Int = max(1,myStorageDue());

        if (stats.transactionCount < 1) {
            return myStorageDue*STORAGE_PERIOD;
        }
        
        let avgIntervalSeconds: Int = 1;

        if (stats.transactionCount > 0) {
            avgIntervalSeconds = max(1,stats.totalTimeInterval / stats.transactionCount);
        }
        
        let avgStorageDuePerTransaction: Int = 0;
        if (stats.transactionCount > 0) {
            avgStorageDuePerTransaction = max(1,stats.totalStorageDueCollected / stats.transactionCount);
        }
                
        let expectedTransactions: Int = max(1, STORAGE_PERIOD / avgIntervalSeconds);
        
        let totalStorageCost: Int = max(avgStorageDuePerTransaction, myStorageDue) * expectedTransactions * 120 / 100;

        return totalStorageCost;
    }
    
    virtual fun getComputeGas(): Int {
        return getComputeFee(gasConsumed()*3, false);
    }

    virtual fun reserveBalance() {
        let stats: StorageStats = self.getStorageStats();
        let reserve: Int = max(stats.reservedStorage, MIN_CONTRACT_BALANCE);
        nativeReserve(reserve, ReserveAtMost);
    }
}

trait ReferralSystem {
    abstract fun getUsers(): Users;
    abstract fun setUsers(users: Users): Bool;
    abstract fun getUserData(key: Int): UserData?;
    abstract fun sendCommissions(incomingTons: Int, commissions: map<Address, Int>): Int;
    abstract fun getPruneState(): PruneState;
    abstract fun setPruneState(state: PruneState): Bool;
    // True if the user takes part in the current or pending lottery round and
    // must therefore never be pruned (removing them would let a draw debit the
    // bank for a winner that no longer exists). Implemented by the contract,
    // which owns both rounds.
    abstract fun isProtectedFromPruning(userKey: Int): Bool;

    // Stamp a user's last-activity time. Called when the user takes part in the
    // lottery (so their own purchase counts as activity, not only referral income).
    virtual fun touchUser(userKey: Int) {
        let users: Users = self.getUsers();
        let userData: UserData? = users.userData.get(userKey);
        if (userData != null) {
            users.userData.set(userKey, UserData{
                referrerKey: userData!!.referrerKey,
                address: userData!!.address,
                referralsCount: userData!!.referralsCount,
                earningsFromReferrals: userData!!.earningsFromReferrals,
                lastActivity: now()
            });
            self.setUsers(users);
        }
    }

    // Amortized pruning over the contract's lifetime. Called on every buy: it
    // advances a ring cursor over the dense index of live users and checks up to
    // PRUNE_SCAN_PER_TX slots, removing anyone inactive for >= ACTIVITY_TTL.
    //
    // Why amortized instead of a yearly big-bang sweep:
    //   - the cost is spread across buys (no expensive spike on millions of users);
    //   - state stays continuously pruned instead of growing for a year and then
    //     collapsing at once; no self-message chain or watchdog is needed for pruning.
    //
    // Removal is swap-remove: the last live element is moved into the freed slot
    // and the cursor does NOT advance (the moved element is re-checked on the next
    // iteration). The owner (key 0, position 0) is never removed or moved.
    //
    // Robustness: all index/map accesses are null-safe (no `!!`). An unexpected
    // null (an invariant desync that should never happen) does not abort the buy
    // transaction; it is skipped/cleaned softly — otherwise a single desync would
    // block pruning forever.
    virtual fun amortizedPrune() {
        let users: Users = self.getUsers();
        // Only the owner is registered -> nothing to prune.
        if (users.userCount <= 1) {
            return;
        }

        let pruneState: PruneState = self.getPruneState();
        let cursor: Int = pruneState.cursor;
        let checks: Int = 0;

        while (checks < PRUNE_SCAN_PER_TX && users.userCount > 1) {
            // Ring cursor: wrap to the start once the end of the dense index is reached.
            if (cursor >= users.userCount) {
                cursor = 0;
            }

            let userKey: Int? = users.userIndex.get(cursor);
            if (userKey == null) {
                // The dense index should have no holes; do not abort, just advance.
                cursor += 1;
            } else if (userKey!! == OWNER_REFERRER_KEY) {
                // The owner (position 0) is never removed.
                cursor += 1;
            } else {
                let userData: UserData? = users.userData.get(userKey!!);
                if (userData == null) {
                    // index/userData desync -> drop the dangling index slot via
                    // swap-remove (there is nothing left to clean in userData/addresses).
                    let lastPos: Int = users.userCount - 1;
                    let lastKey: Int? = users.userIndex.get(lastPos);
                    if (lastKey != null) {
                        users.userIndex.set(cursor, lastKey!!);
                    } else {
                        users.userIndex.del(cursor);
                    }
                    users.userIndex.del(lastPos);
                    users.userCount = lastPos;
                    // Cursor is NOT advanced: the moved element is re-checked next iteration.
                } else if (now() - userData!!.lastActivity >= ACTIVITY_TTL
                           && !self.isProtectedFromPruning(userKey!!)) {
                    // Inactive >= TTL and not a participant of the current or
                    // pending round -> swap-remove. A round is only drawn by the
                    // next buy after it ends, so a stalled (undrawn) round may
                    // still hold dormant participants; never remove them, or the
                    // draw would debit the bank for a winner that no longer exists.
                    let lastPos: Int = users.userCount - 1;
                    let lastKey: Int? = users.userIndex.get(lastPos);
                    if (lastKey != null) {
                        users.userIndex.set(cursor, lastKey!!);
                    } else {
                        users.userIndex.del(cursor);
                    }
                    users.userIndex.del(lastPos);
                    users.userCount = lastPos;
                    users.userData.del(userKey!!);
                    users.addresses.del(userData!!.address);
                    // Cursor is NOT advanced: the moved element is re-checked next iteration.
                } else {
                    cursor += 1;
                }
            }
            checks += 1;
        }

        pruneState.cursor = cursor;
        self.setUsers(users);
        self.setPruneState(pruneState);
    }

    virtual fun getCommissions(address: Address, referrerKey: Int, incomingTons: Int): map<Address, Int> {
        if (self.getUserData(referrerKey) == null) {
            referrerKey = OWNER_REFERRER_KEY;
        }

        let users: Users = self.getUsers();
        let userKey: Int? = users.addresses.get(address);
        if (userKey == null) {
            let newUserKey: Int = users.lastKey + 1;
            let referrerData: UserData? = users.userData.get(referrerKey);
            if (referrerData != null) {
                users.userData.set(
                    referrerKey, 
                    UserData{
                        referrerKey: referrerData!!.referrerKey, 
                        address: referrerData!!.address, 
                        referralsCount: (referrerData!!.referralsCount + 1), 
                        earningsFromReferrals: referrerData!!.earningsFromReferrals,
                        lastActivity: referrerData!!.lastActivity
                    }
                );
            }
            users.lastKey = newUserKey;
            users.userData.set(
                newUserKey, 
                UserData{
                    referrerKey: referrerKey, 
                    address: address, 
                    referralsCount: 0, 
                    earningsFromReferrals: 0,
                    lastActivity: now()
                }
            );
            users.addresses.set(address, newUserKey);
            // Append to the compact live-user index.
            users.userIndex.set(users.userCount, newUserKey);
            users.userCount += 1;
            self.setUsers(users);
        }

        let comissonsMap: map<Address, Int> = emptyMap();
        let depth: Int = REFERRAL_LEVELS;
        
        while (depth > 0 && incomingTons > 0) {
            if (referrerKey == OWNER_REFERRER_KEY) {
                depth = 0;
            }
            
            let referrerData: UserData? = self.getUserData(referrerKey);
            if (referrerData != null) {
                let comission = max(0, incomingTons * REFERRAL_SHARE_PERCENT / 100);
                comissonsMap.set(referrerData!!.address, comission);
                referrerKey = referrerData!!.referrerKey;
                incomingTons = max(0, incomingTons - comission);
                depth = max(0, depth - 1);  
            } else {
                // Referrer in the middle of the chain was pruned: redirect this
                // level to the owner instead of dropping the share. The owner
                // (key 0) is never pruned, so the next iteration credits it and
                // the loop terminates via the OWNER_REFERRER_KEY guard above.
                referrerKey = OWNER_REFERRER_KEY;
            }
        }
        return comissonsMap;
    }
}

trait LotterySystem {
    abstract fun getCurrentRound(): CurrentLotteryRound;
    abstract fun setCurrentRound(round: CurrentLotteryRound): Bool;
    abstract fun sendLotteryPrize(winnerKey: Int, prize: Int): Bool;
    abstract fun getLotteryBank(): LotteryBank;
    abstract fun setLotteryBank(bank: LotteryBank): Bool;
    abstract fun getAvailableForPrize(): Int;
    abstract fun getDrawState(): DrawState;
    abstract fun setDrawState(state: DrawState): Bool;
    abstract fun getPendingRound(): CurrentLotteryRound;
    abstract fun setPendingRound(round: CurrentLotteryRound): Bool;

    virtual fun addTicketsToRound(round: CurrentLotteryRound, userKey: Int, amount: Int): CurrentLotteryRound {
        let currentTickets: Int? = round.ticketMap.get(userKey);
        if (currentTickets != null) {
            round.ticketMap.set(userKey, currentTickets!! + amount);
        } else {
            round.ticketMap.set(userKey, amount);
            round.participantList.set(round.participantsCount, userKey);
            round.participantsCount += 1;
        }
        round.totalTickets += amount;
        return round;
    }

    // Send a DrawLottery message from the contract to itself, so the draw runs
    // in a separate transaction with a full gas budget. Self-messages are the only
    // accepted source of DrawLottery (enforced by the receiver).
    virtual fun sendDrawMessage() {
        send(SendParameters{
            to: myAddress(),
            value: DRAW_TRIGGER_VALUE,
            mode: SendIgnoreErrors,
            bounce: false,
            body: DrawLottery{queryId: 0}.toCell()
        });
    }

    virtual fun addTicketsToLottery(userKey: Int, amount: Int): Bool {
        let drawState = self.getDrawState();
        if (drawState.isDrawing) {
            let pending = self.getPendingRound();
            pending = self.addTicketsToRound(pending, userKey, amount);
            self.setPendingRound(pending);
            // Watchdog: a draw is in progress. Nudge the chain only if it has made
            // no progress for longer than STALL_TIMEOUT (not on every entry), to
            // avoid spawning redundant self-messages during a normal draw.
            if (now() - drawState.lastProgressTime >= STALL_TIMEOUT) {
                drawState.lastProgressTime = now();
                self.setDrawState(drawState);
                self.sendDrawMessage();
            }
        } else {
            let round = self.getCurrentRound();
            round = self.addTicketsToRound(round, userKey, amount);
            self.setCurrentRound(round);
            // Round has ended: trigger the draw via a self-message.
            if (round.totalTickets > 0 && now() >= round.endTime) {
                self.sendDrawMessage();
            }
        }
        return true;
    }

    virtual fun drawLottery(): Bool {
        let drawState = self.getDrawState();

        if (!drawState.isDrawing) {
            let round = self.getCurrentRound();
            // Soft no-op: stale self-messages (e.g. queued during a previous draw)
            // must not throw. A draw only starts when the round actually ended and
            // has participants. The returned funds are credited back to the bank by
            // the receiver, so no TON is lost on a no-op.
            if (round.totalTickets == 0 || now() < round.endTime) {
                return false;
            }

            let bank = self.getLotteryBank();
            let available: Int = self.getAvailableForPrize();
            let prize = min(bank.balance*LOTTERY_WINNER_SHARE/100, available);
            let ownerShare = min(bank.balance*LOTTERY_OWNER_PERCENT/100, max(0, available - prize));

            bank.balance = max(0, bank.balance - (prize + ownerShare));
            self.setLotteryBank(bank);

            drawState = DrawState{
                isDrawing: true,
                cursor: 0,
                accumulated: 0,
                // Security assumption: random() is seeded from the draw
                // transaction's block seed, so a block producer could in theory
                // grind the seed to influence the winner. Accepted by design —
                // we trust validators (typical for small on-chain lotteries).
                randomTarget: random(1, round.totalTickets),
                winnerKey: 0,
                winnerFound: false,
                snapshotParticipants: round.participantsCount,
                prizeAmount: prize,
                ownerShareAmount: ownerShare,
                lastProgressTime: now()
            };
            self.setDrawState(drawState);
        }

        self.processDrawChunk();
        return true;
    }

    virtual fun processDrawChunk(): Bool {
        let drawState = self.getDrawState();
        if (!drawState.isDrawing) {
            return false;
        }

        let round = self.getCurrentRound();

        while (drawState.cursor < drawState.snapshotParticipants
               && !drawState.winnerFound
               && gasConsumed() < DRAW_GAS_CHUNK_LIMIT) {
            // Robustness: read the participant and their tickets safely. An
            // unexpected null (a round-map desync that should never happen) does
            // not abort the draw or cause a crash loop — the slot is skipped with
            // a zero contribution.
            let userKey: Int? = round.participantList.get(drawState.cursor);
            if (userKey == null) {
                drawState.cursor += 1;
            } else {
                let tickets: Int? = round.ticketMap.get(userKey!!);
                let ticketCount: Int = 0;
                if (tickets != null) {
                    ticketCount = tickets!!;
                }
                drawState.accumulated += ticketCount;
                if (drawState.accumulated >= drawState.randomTarget) {
                    drawState.winnerKey = userKey!!;
                    drawState.winnerFound = true;
                }
                drawState.cursor += 1;
            }
        }

        // Heartbeat: this chunk just ran -> record progress.
        drawState.lastProgressTime = now();

        if (drawState.winnerFound || drawState.cursor >= drawState.snapshotParticipants) {
            if (!drawState.winnerFound) {
                // Fallback winner: the last participant in the snapshot. If that
                // slot is somehow empty, leave winnerKey=0 (owner) as a last resort,
                // but never abort.
                let fallback: Int? = round.participantList.get(max(0, drawState.snapshotParticipants - 1));
                if (fallback != null) {
                    drawState.winnerKey = fallback!!;
                }
                drawState.winnerFound = true;
            }
            self.setDrawState(drawState);
            self.finalizeDraw();
        } else {
            // Chunk exhausted gas budget without finishing: continue in the next
            // transaction via a self-message.
            self.setDrawState(drawState);
            self.sendDrawMessage();
        }
        return true;
    }

    virtual fun finalizeDraw(): Bool {
        let drawState = self.getDrawState();

        self.sendLotteryPrize(drawState.winnerKey, drawState.prizeAmount);
        self.sendLotteryPrize(OWNER_REFERRER_KEY, drawState.ownerShareAmount);

        let pending = self.getPendingRound();
        let newRound = CurrentLotteryRound{
            endTime: now() + LOTTERY_ROUND_DURATION,
            ticketMap: pending.ticketMap,
            participantList: pending.participantList,
            totalTickets: pending.totalTickets,
            participantsCount: pending.participantsCount
        };
        self.setCurrentRound(newRound);

        self.setPendingRound(CurrentLotteryRound{
            endTime: 0,
            ticketMap: emptyMap(),
            participantList: emptyMap(),
            totalTickets: 0,
            participantsCount: 0
        });

        self.setDrawState(DrawState{
            isDrawing: false,
            cursor: 0,
            accumulated: 0,
            randomTarget: 0,
            winnerKey: 0,
            winnerFound: false,
            snapshotParticipants: 0,
            prizeAmount: 0,
            ownerShareAmount: 0,
            lastProgressTime: 0
        });

        return true;
    }
}

trait JettonRewards {
    abstract fun getJettonRewardsStats(): JettonRewardsStats;
    abstract fun setJettonRewardsStats(stats: JettonRewardsStats): Bool;
    abstract fun sendJetton(address: Address, amount: Int): Bool;

    // By design: all emission accumulated since the last mint goes entirely to
    // the sender of the current buy (it is not distributed proportionally to the
    // contribution size). This is an intentional activity incentive, not a bug.
    virtual fun mintJetton(): Int {
        let stats = self.getJettonRewardsStats();
        let jettonsToMint: Int = 0;
        if (now() > stats.lastMintTime && stats.totalMinted < MAX_SUPPLY) {
            jettonsToMint = (now() - stats.lastMintTime) * EMISSION_RATE;
            stats.lastMintTime = now();
            if (stats.totalMinted + jettonsToMint > MAX_SUPPLY) {
                jettonsToMint = MAX_SUPPLY - stats.totalMinted;
            }
            stats.totalMinted += jettonsToMint;
        }
        self.setJettonRewardsStats(stats);
        return jettonsToMint;
    }
}
