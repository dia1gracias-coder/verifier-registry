import "./withdrawable.tact";

struct VestingRecord {
    beneficiary: Address; // beneficiary of tokens after they are released
    totalAmount: Int as uint256; // total amount of tokens to be released at the very end
    releasedAmount: Int as uint256; // amount of tokens already released
    lastQueryId: Int as uint64; // reentrancy guard
}

struct BeneficiaryRecord {
    beneficiary: Address;
    totalAmount: Int as uint256;
    lockedAmount: Int as uint256;
    releasedAmount: Int as uint256;
    releasableAmount: Int as uint256;
}

struct VestingConfig {
    startAt: Int as uint64; // start time of the vesting in seconds since the UNIX epoch
    durationSeconds: Int as uint64; // duration of the whole vesting period in seconds
    intervalSeconds: Int as uint64; // duration of an interval for the vesting in seconds
}

message Claim {
    queryId: Int as uint64;
    beneficiary: Address;
    responseTo: Address?;
}

message UpdateVester {
    newVester: Address?;
}

message Deploy {
    tokenWallet: Address;
    vester: Address?;
}

contract Vesting with WithdrawableJettonsOwner {
    owner: Address;
    index: Int? as uint32; // can be used to create different contracts with the same params
    tokenWallet: Address?;
    vester: Address?; // has a right to send tokens to include them in vesting
    
    config: VestingConfig;
    
    records: map<Address, VestingRecord>;
    totalAmount: Int as uint256 = 0;
    totalReleasedAmount: Int as uint256 = 0;

    init(index: Int?, config: VestingConfig) {
        // deployer becomes owner
        self.owner = sender();
        self.index = index;
        
        self.config = config;

        self.records = emptyMap();
    }

    receive(request: Deploy) {
        self.requireOwner();
        require(self.tokenWallet == null, "Already deployed");
        self.tokenWallet = request.tokenWallet;
        self.vester = request.vester;
    }

    override fun onTokenNotification(notification: TokenNotification) {
        // we don't care about unknown tokens and unknown senders
        require(sender() == self.tokenWallet, "Unknown token type");
        require(
            notification.from == self.vester || notification.from == self.owner, 
            "No access"
        );
        require(notification.amount > 0, "Amount must be > 0");
        
        let beneficiary: Address = notification.forward_payload.loadAddress();
        let success: Bool = self.addToVesting(
            beneficiary, notification.amount, notification.queryId);

        if (success) {
            self.sendExcesses(beneficiary);
        } else {
            self.sendTokens(self.tokenWallet!!, TokenTransfer{
                queryId: notification.queryId,
                amount: notification.amount,
                destination: notification.from,
                response_destination: notification.from,
                custom_payload: null,
                forward_ton_amount: 0,
                forward_payload: emptySlice()
            });
        }
    }

    receive(request: Claim) {
        let recordOpt: VestingRecord? = self.records.get(request.beneficiary); 
        require(recordOpt != null, "Not found");
        let record: VestingRecord = recordOpt!!;
        require(
            sender() == record.beneficiary || 
            sender() == self.owner ||
            sender() == self.vester,
            "No access"
        );
        require(request.queryId > record.lastQueryId, "Bad query");
        record.lastQueryId = request.queryId;

        let releasableAmount: Int = self.computeReleasableAmount(record, now());
        require(releasableAmount > 0, "Nothing to claim");

        record.releasedAmount += releasableAmount;
        self.records.set(request.beneficiary, record);

        self.totalReleasedAmount += releasableAmount;

        let responseDestination: Address = request.responseTo != null ? 
            request.responseTo!! : sender();

        // sends tokens & all excesses
        self.sendTokens(self.tokenWallet!!, TokenTransfer{
            queryId: request.queryId,
            amount: releasableAmount,
            destination: record.beneficiary,
            response_destination: responseDestination,
            custom_payload: null,
            forward_ton_amount: 0,
            forward_payload: emptySlice()
        });
    }

    receive(request: UpdateVester) {
        self.requireOwner();
        self.vester = request.newVester;
        self.sendExcesses(sender());
    }

    // withdraw extension: owner cannot withdraw vested tokens
    override fun requireSpecialCondition(request: Withdraw) {
        require(
            request.tokenWallet != self.tokenWallet, 
            "Cannot withdraw vested tokens"
        );
    }

    fun addToVesting(beneficiary: Address, amount: Int, queryId: Int): Bool {        
        let existingRecordOpt: VestingRecord? = self.records.get(beneficiary);
        let record: VestingRecord = existingRecordOpt == null ? VestingRecord{
            beneficiary: beneficiary,
            totalAmount: 0,
            releasedAmount: 0,
            lastQueryId: 0
        } : existingRecordOpt!!;

        if (queryId <= record.lastQueryId) {
            return false;
        }
        
        record.lastQueryId = queryId;
        record.totalAmount += amount;
        self.totalAmount += amount;

        self.records.set(beneficiary, record);

        return true;
    }

    fun computeReleasableAmount(record: VestingRecord, atMoment: Int): Int {
        let startAt: Int = self.config.startAt;
        let duration: Int = self.config.durationSeconds;
        let interval: Int = self.config.intervalSeconds;

        if (atMoment < startAt) {
            return 0;
        } 
        if (atMoment >= startAt + duration) {
            return record.totalAmount - record.releasedAmount;
        }   
        // Number of full vesting intervals that have elapsed
        let numberOfIntervals: Int = (atMoment - startAt) / interval;
        let vestedSeconds: Int = numberOfIntervals * interval;
        // Compute the amount of tokens that can be realesed
        let totalReleasableAmount: Int = 
            (record.totalAmount * vestedSeconds) / duration;
        return totalReleasableAmount - record.releasedAmount;
    }

    fun sendExcesses(to: Address) {
        send(SendParameters{
            bounce: false,
            to: to,
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors
        });
    }

    get fun allRecords(): map<Address, VestingRecord> {
        return self.records;
    }

    get fun config(): VestingConfig {
        return self.config;
    }

    get fun index(): Int? {
        return self.index;
    }

    get fun vester(): Address? {
        return self.vester;
    }

    get fun tokenWallet(): Address {
        return self.tokenWallet!!;
    }

    get fun totalAmount(): Int {
        return self.totalAmount;
    }

    get fun totalReleasedAmount(): Int {
        return self.totalReleasedAmount;
    }

    get fun releasableAmount(beneficiary: Address, dateInSeconds: Int?): Int {
        let record: VestingRecord = self.records.get(beneficiary)!!;
        let atMoment: Int = dateInSeconds != null ? dateInSeconds!! : now();
        return self.computeReleasableAmount(record, atMoment);
    }

    get fun beneficiaryRecord(beneficiary: Address, dateInSeconds: Int?): BeneficiaryRecord {
        let atMoment: Int = dateInSeconds != null ? dateInSeconds!! : now();
        let record: VestingRecord? = self.records.get(beneficiary);
        let res: BeneficiaryRecord = BeneficiaryRecord{
            beneficiary: beneficiary,
            totalAmount : 0,
            lockedAmount: 0,
            releasedAmount: 0,
            releasableAmount : 0
        };
        if (record != null) {
            res.totalAmount = record!!.totalAmount;
            res.releasedAmount = record!!.releasedAmount;
            res.lockedAmount = record!!.totalAmount - record!!.releasedAmount;
            res.releasableAmount = self.computeReleasableAmount(record!!, atMoment);
        }

        return res;
    }
}