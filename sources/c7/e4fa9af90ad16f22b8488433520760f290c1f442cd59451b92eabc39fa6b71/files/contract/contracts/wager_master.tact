import "@stdlib/deploy";
import "@stdlib/ownable";

const STATUS_SIZE: Int = 4;
const DECIMAL_POINTS: Int = 6; // USDT has 6 decimal points on TON
const JUROR_COUNT: Int = 9;
const JURY_SIZE: Int = 1000;

message CreateWager {
    deadline: Int as uint32;
    description: String;
}

message SetWagerResult {
    wagerId: Int as uint256;
    result: Bool;
}

message Vote {
    choice: Bool;
}

message ClaimWinnings {
    wagerId: Int as uint256;
}

message AddJuror {
    jurorAddress: Address;
}

message RequestNewJurors {
    wagerId: Int as uint256;
}

message SetNewJurors {
    jurors: map<Address, Bool>;
}

message SetJurorVote {
    choice: Bool;
}

message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}

contract WagerMaster with Ownable {
    owner: Address;
    nextWagerId: Int as uint256 = 0;
    wagerCreatorFee: Int as uint16 = 5; // 0.25%
    platformFee: Int as uint16 = 50; // 2.75%
    wagers: map<Int, Address>;
    usdtMasterAddress: Address;
    jettonWalletCode: Cell;
    jury: map<Int, Address>;
    nextJurorId: Int as uint32 = 1;

    init(usdtMaster: Address, jettonWalletCode: Cell) {
        self.owner = sender();
        self.usdtMasterAddress = usdtMaster;
        self.jettonWalletCode = jettonWalletCode;
    }

    receive(msg: CreateWager) {
        self.nextWagerId = self.nextWagerId + 1;

        let jurors: map<Address, Bool> = emptyMap();
        if (self.nextJurorId >= JURY_SIZE) {
            // Select 9 random jurors
            let i: Int = 0;
            while (i < JUROR_COUNT) {
                let randomIndex: Int = random(0, self.nextJurorId - 2);
                let jurorAddress: Address = self.jury.get(randomIndex)!!;
                if (jurors.get(jurorAddress) == null) {
                    jurors.set(jurorAddress, false);
                    i = i + 1;
                }
            }
        }

        let init: StateInit = initOf Wager(myAddress(), self.nextWagerId, msg.deadline, msg.description, sender(), self.usdtMasterAddress, self.jettonWalletCode, jurors);
        let wagerAddress: Address = contractAddress(init);

        self.wagers.set(self.nextWagerId, wagerAddress);

        send(SendParameters{
            to: wagerAddress,
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            code: init.code,
            data: init.data
        });
    }

    receive(msg: SetWagerResult) {
        require(sender() == self.owner, "Only owner can set wager result");
        let wagerAddress: Address = self.wagers.get(msg.wagerId)!!;

        send(SendParameters{
            to: wagerAddress,
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: msg.toCell()
        });
    }

    receive(msg: AddJuror) {
        require(sender() == self.owner, "Only owner can add jurors");
        
        self.jury.set(self.nextJurorId, msg.jurorAddress);
        self.nextJurorId = self.nextJurorId + 1;
    }

    receive(msg: RequestNewJurors) {
        require(self.wagers.get(msg.wagerId) != null, "Invalid wager ID");
        require(sender() == self.wagers.get(msg.wagerId), "Only wager contract can request new jurors");

        let newJurors: map<Address, Bool> = emptyMap();
        if (self.nextJurorId >= JURY_SIZE) {
            // Select 9 new random jurors
            let i: Int = 0;
            while (i < JUROR_COUNT) {
                let randomIndex: Int = random(0, JURY_SIZE - 1);
                let jurorAddress: Address = self.jury.get(randomIndex)!!;
                if (newJurors.get(jurorAddress) == null) {
                    newJurors.set(jurorAddress, false);
                    i = i + 1;
                }
            }
        }

        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: SetNewJurors{jurors: newJurors}.toCell()
        });
    }

    get fun getWagerAddress(wagerId: Int): Address {
        return self.wagers.get(wagerId)!!;
    }

    get fun getJurySize(): Int {
        return (self.nextJurorId - 1);
    }
}

contract Wager {
    master: Address;
    wagerId: Int as uint256;
    deadline: Int as uint32;
    description: String;
    creator: Address;
    totalYesAmount: Int as coins = 0;
    totalNoAmount: Int as coins = 0;
    result: Bool?;
    voters: map<Address, VoterInfo>;
    usdtMasterAddress: Address;
    jettonWalletCode: Cell;
    jurors: map<Address, Bool>;
    jurorVotes: map<Address, Bool>;
    votedCount: Int as uint8 = 1;
    firstVote: Bool?;

    init(master: Address, wagerId: Int, deadline: Int, description: String, creator: Address, usdtMaster: Address, jettonWalletCode: Cell, jurors: map<Address, Bool>) {
        self.master = master;
        self.wagerId = wagerId;
        self.deadline = deadline;
        self.description = description;
        self.creator = creator;
        self.usdtMasterAddress = usdtMaster;
        self.jettonWalletCode = jettonWalletCode;
        self.jurors = jurors;
    }

    receive(msg: TokenNotification) {
        require(now() < self.deadline, "Voting period has ended");
        require(msg.amount > 0, "Vote amount must be greater than 0");

        // Verify that the sender is a valid USDT wallet
        let expectedWalletAddress: Address = self.calculateUserJettonWalletAddress(msg.from, self.usdtMasterAddress);
        require(sender() == expectedWalletAddress, "Invalid USDT wallet");

        let choice: Bool = msg.forwardPayload.loadBool();
        self.vote(msg.from, msg.amount, choice);
    }

    receive(msg: SetWagerResult) {
        require(sender() == self.master, "Only master can set result");
        require(self.result == null, "Result already set");
        if(self.jurors.isEmpty()) {
            require(now() >= self.deadline, "Cannot set result before deadline");
        } else {
            require(now() >= self.deadline + 86400, "Cannot set result when jurors are present and within 24 hours of deadline");
        }
        self.result = msg.result;
    }

    receive(msg: SetJurorVote) {
        require(now() >= self.deadline, "Cannot set juror vote before deadline");
        require(self.result == null, "Result already set");
        require(self.jurors.get(sender()) != null, "Only assigned juror can vote");
        require(!self.jurors.get(sender())!!, "Juror has already voted");

        self.jurorVotes.set(sender(), msg.choice);
        self.jurors.set(sender(), true);

        if (self.votedCount == 1) {
            self.firstVote = msg.choice;
        }
        
        if (msg.choice != self.firstVote) {
            // This vote doesn't match the first vote, request new jurors
            send(SendParameters{
                to: self.master,
                value: 0,
                mode: SendRemainingValue,
                bounce: false,
                body: RequestNewJurors{wagerId: self.wagerId}.toCell()
            });
            return;
        }

        self.votedCount = self.votedCount + 1;

        if (self.votedCount == JUROR_COUNT) {
            // All jurors have voted and they all agree
            self.result = self.firstVote;
        }
    }

    receive(msg: SetNewJurors) {
        require(sender() == self.master, "Only master can set new jurors");
        self.jurors = msg.jurors;
        self.jurorVotes = emptyMap();
    }

    fun calculateJettonWalletStateInit(ownerAddress: Address, jettonMasterAddress: Address): StateInit {
        return StateInit{
            code: self.jettonWalletCode,
            data: self.packJettonWalletData(0, 0, ownerAddress, jettonMasterAddress)
        };
    }

    fun packJettonWalletData(status: Int, balance: Int, ownerAddress: Address, jettonMasterAddress: Address): Cell {
        return beginCell()
            .storeUint(status, STATUS_SIZE)
            .storeCoins(balance)
            .storeAddress(ownerAddress)
            .storeAddress(jettonMasterAddress)
            .endCell();
    }

    fun calculateJettonWalletAddress(stateInit: StateInit): Address {
        return contractAddress(stateInit);
    }

    fun calculateUserJettonWalletAddress(ownerAddress: Address, jettonMasterAddress: Address): Address {
        return self.calculateJettonWalletAddress(
            self.calculateJettonWalletStateInit(ownerAddress, jettonMasterAddress)
        );
    }

    fun vote(voterAddress: Address, amount: Int, choice: Bool) {
        if (self.voters.get(voterAddress) != null) {
            let existingVote: VoterInfo = self.voters.get(voterAddress)!!;
            
            if (existingVote.choice != choice) {
                if (existingVote.choice) {
                    self.totalYesAmount -= existingVote.amount;
                    self.totalNoAmount += existingVote.amount + amount;
                } else {
                    self.totalNoAmount -= existingVote.amount;
                    self.totalYesAmount += existingVote.amount + amount;
                }
                self.voters.set(voterAddress, VoterInfo{choice: choice, amount: existingVote.amount + amount});
            } else {
                if (choice) {
                    self.totalYesAmount += amount;
                } else {
                    self.totalNoAmount += amount;
                }
                self.voters.set(voterAddress, VoterInfo{choice: choice, amount: existingVote.amount + amount});
            }
        } else {
            if (choice) {
                self.totalYesAmount += amount;
            } else {
                self.totalNoAmount += amount;
            }
            self.voters.set(voterAddress, VoterInfo{choice: choice, amount: amount});
        }
    }

    receive(msg: ClaimWinnings) {
        require(self.result != null, "Result not set yet");
        require(now() >= self.deadline, "Cannot claim before deadline");

        let claimant: Address = sender();
        let totalPot: Int = self.totalYesAmount + self.totalNoAmount;
        let winningPot: Int = self.result!! ? self.totalYesAmount : self.totalNoAmount;
        let losingPot: Int = totalPot - winningPot;
        let distributablePot: Int = winningPot + (losingPot * 9950) / 10000; // 97% of total pot
        let totalClaim: Int = 0;

        if (claimant == self.creator) {
            let creatorFee: Int = (losingPot * 5) / 10000; // 0.25% of losing pot
            totalClaim += creatorFee;
        }

        if (claimant == self.master) {
            let platformFee: Int = (losingPot * 50) / 10000; // 2.75% of losing pot
            totalClaim += platformFee;
        }

        if (self.voters.get(claimant) != null) {
            let voterInfo: VoterInfo = self.voters.get(claimant)!!;
            if (voterInfo.choice == self.result!!) {
                let userShare: Int = (voterInfo.amount * distributablePot) / winningPot;
                totalClaim += userShare;

                self.voters.set(claimant, null);
            }
        }

        require(totalClaim > 0, "No winnings to claim");

        // Send Jetton Transfer message
        send(SendParameters{
            to: self.calculateUserJettonWalletAddress(myAddress(), self.usdtMasterAddress),
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: beginCell()
                .storeUint(0x0f8a7ea5, 32) // op for Jetton Transfer
                .storeUint(0, 64) // query_id
                .storeCoins(totalClaim)
                .storeAddress(claimant)
                .storeAddress(myAddress()) // response destination
                .storeInt(0, 1) // no custom payload
                .storeInt(0, 1) // no forward_ton_amount
                .endCell()
        });
    }

    get fun getWagerInfo(): WagerInfo {
        return WagerInfo{
            master: self.master,
            deadline: self.deadline,
            description: self.description,
            creator: self.creator,
            totalYesAmount: self.totalYesAmount,
            totalNoAmount: self.totalNoAmount,
            result: self.result
        };
    }

    get fun getVoterInfo(key: Address): VoterInfo? {
        return self.voters.get(key);
    }
}

struct WagerInfo {
    master: Address;
    deadline: Int as uint32;
    description: String;
    creator: Address;
    totalYesAmount: Int as coins;
    totalNoAmount: Int as coins;
    result: Bool?;
}

struct VoterInfo {
    choice: Bool;
    amount: Int as coins;
}