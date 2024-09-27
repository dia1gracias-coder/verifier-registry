import "@stdlib/ownable";
import "@stdlib/deploy";
import "./bank/bridgeBank";

struct BridgeBasicInfo {
    owner: Address;
    operator: Address;
    tokenDeployer: Address;
    user0_key: Int as uint256;
    user1_key: Int as uint256;
    user2_key: Int as uint256;
}

struct RunStaticsInfo {
    bridgeTokenCount: Int;
    symbol2address: map<Int, Address>;
}

contract BtcBridge with Ownable, Deployable, BridgeBank {
    owner: Address;
    operator: Address;
    tokenDeployer: Address;
    seqNo: Int as uint64 = 0;
    user0_key: Int as uint256;
    user1_key: Int as uint256;
    user2_key: Int as uint256;

    hasMadeClaim: map<Int, Bool>;
    validtors: map<Int, Bool>;

    bridgeTokenCount: Int as uint8 = 0;
    bridgeTokenWhitelist: map<Address, Bool>;
    bridgeTokenCreated: map<Int, Bool>;
    symbol2address: map<Int, DeployedJetton>;

    const ClaimTypeUnknow: Int = 0;
    const ClaimTypeBurn: Int = 1;
    const ClaimTypeLock: Int = 2;

    init(operator: Address, tokenDeployer: Address, validator0PubKey: Int, validator1PubKey: Int, validator2PubKey: Int) {
        self.owner = operator;
        self.operator = operator;
        self.tokenDeployer = tokenDeployer;
        require(validator0PubKey != 0 && validator1PubKey != 0 && validator2PubKey != 0, "Invalid pub keys");
        require(validator0PubKey != validator1PubKey && validator0PubKey != validator2PubKey && validator1PubKey != validator2PubKey, "Same pub keys");
        self.user0_key = validator0PubKey;
        self.user1_key = validator1PubKey;
        self.user2_key = validator2PubKey;
    }

    // 跨链铸币
    receive(msg: NewOracleClaimMulSigs) {
        let ctx: Context = context();
        // Check all signatures
        let op_hash: Int = msg.newOracleClaim.toCell().hash();
        require(op_hash == msg.claimID, "Invalid claimID");
        require(self.hasMadeClaim.get(msg.claimID) != true, "Invalid claimID");
        let sigPassCheckCnt: Int = 0;
        let ok: Bool = checkSignature(op_hash, msg.signature0, self.user0_key);
        if (ok) {
            sigPassCheckCnt += 1;
        }
        ok = checkSignature(op_hash, msg.signature1, self.user1_key);
        if (ok) {
            sigPassCheckCnt += 1;
        }
        ok = checkSignature(op_hash, msg.signature2, self.user2_key);
        if (ok) {
            sigPassCheckCnt += 1;
        }
        require(sigPassCheckCnt >= 2, "Invalid signatures");
        require(msg.newOracleClaim.seqNo == self.seqNo + 1, "Invalid seqno");

        self.mint(msg.newOracleClaim.jettonMaster, msg.newOracleClaim.receiver, msg.newOracleClaim.amount, self.seqNo); // (to, amount, response_destination)
        self.hasMadeClaim.set(msg.claimID, true);
        emit(LogProphecyProcessedEvent{claimID: msg.claimID, submitter: ctx.sender, seqNo: self.seqNo}.toCell());
        self.seqNo += 1;
    }

    //部署新的跨链币种
    receive(msg: DeployNewBridgeToken) {
        let ctx: Context = context();
        require(ctx.sender == self.tokenDeployer || ctx.sender == self.operator, "Not allowed to create bridge token");
        self.deployNewBridgeToken(myAddress(), msg.content, msg.max_supply, msg.symbol)
    }

    receive(msg: TokenExcesses) {
        emit(msg.toCell());
    }

    get fun seqNo(): Int {
        return self.seqNo;
    }

    get fun basicInfo(): BridgeBasicInfo {
        return
            BridgeBasicInfo{
                owner: self.owner,
                operator: self.operator,
                tokenDeployer: self.tokenDeployer,
                user0_key: self.user0_key,
                user1_key: self.user1_key,
                user2_key: self.user2_key,
            };
    }

    get fun deployedJettonNumber(): Int {
        return self.bridgeTokenCount;
    }

    get fun deployedJettonInfo(index: Int): DeployedJetton? {
        return self.symbol2address.get(index);
    }
}