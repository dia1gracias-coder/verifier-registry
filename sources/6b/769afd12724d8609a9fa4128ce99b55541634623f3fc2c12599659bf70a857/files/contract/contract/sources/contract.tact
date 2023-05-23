contract IDO_Main {
    project_id: Int as uint16 = 0;
    owner: Address;
    
    init(_owner: Address) {
        self.owner = _owner;
    }

    receive("AdminCreateNewRound") {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "not owner");

        let init: StateInit = initOf Round(self.project_id, self.owner);
        send(SendParameters {
            to: contractAddress(init),
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors,
            bounce: true,
            code: init.code,
            data: init.data
        }); 
        self.project_id = self.project_id + 1;
    }
    
    // TODO: ChangeOwner (make sure the sub address also affected)

    get fun get_round_address(project_id: Int): Address {
        let init: StateInit = initOf Round(project_id, self.owner);
        return contractAddress(init);
    }

}

/* ===========================================================================
Due to the architectural design of TON, "each token owned by an address has its own independent receiving wallet address."
This means you cannot input "token contract messages that can be received into the token contract used for fundraising.
It doesn't make sense."

The actual process is that you must input this "receiving contract" into the target Jetton token contract
and obtain the Wallet Address exclusive to this Jetton token. Only then can you input this message into 
the "target business logic contract".
=========================================================================== */

message AdminUploadJettonWalletData {
    funding_period: Int as uint32;
    round_contract_jetton_wallet: Address; 
    multiplier: Int as uint16;
    upcoming_token_jetton_wallet: Address;  
}

message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;              // For the end-point of the Tx, this data means nothing important. (Ref: https://github.com/ton-blockchain/TEPs/blob/master/text/0074-jettons-standard.md)
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton 
}

/*
    Some metrics for IDO:
    1) `self.endtime`: The end timing for this token sale event. Data store in Unix Timestamp.
    2) `
*/
contract Round {
    project_id: Int as uint16;
    owner: Address;
    end_time: Int as uint32 = 0;

    round_contract_jetton_wallet: Address?;            // 此合約對於（支持扣款的認購代幣）的 Jetton Wallet, ex: IDIA, BUSD, USDT....
    multiplier: Int as uint16 = 0;                     // eg. 250, 500, 1000.... multiplier. range: 0 - 65,535
    
    upcoming_token_jetton_wallet: Address?;            // 此合約對於 (將要發售的代幣) 的 Jetton Wallet 地址, ex: new token 
    amount_of_upcoming_token: Int as coins = 0;        // 將要發售的代幣數量

    round_is_open: Bool?;

    original_submit_qty: Int as coins = 0;
    total_submit_score: Int as uint128 = 0;
    user_submit_list: map<Address, Int>;               // User submit the funding tokens(init. IDIA)

    init(_project_id: Int, _owner: Address) {
        self.project_id = _project_id;
        self.owner = _owner;
    }

    // 🔴 部署後、輸入這個合約的兩種 Jetton Token Wallet Address
    receive(msg: AdminUploadJettonWalletData) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "not the admin");
        
        require(msg.funding_period <= 86401, "Time Frame too long");
        require(msg.funding_period > 0, "Time Frame too short");
        self.end_time = now() + msg.funding_period;                             // TODO: close in next 24hr

        self.round_contract_jetton_wallet = msg.round_contract_jetton_wallet;   // Using IDIA, USDC....
        
        //  self.amount_of_funding_token * self.multiplier = QTY of new Token,  250; 1 ARKEN =  0.004 BUSD, 4000; 1 NewToken = 0.00025 IDIA
        require(msg.multiplier > 1, "ratio too high");
        require(msg.multiplier < 65535, "ratio too high");                     
        self.multiplier = msg.multiplier; 

        self.upcoming_token_jetton_wallet = msg.upcoming_token_jetton_wallet;
        
        require(self.round_is_open == null, "not correct status"); // TODO: 
        self.round_is_open = false;

        send(SendParameters { to: ctx.sender, value: 0, mode: SendRemainingValue + SendIgnoreErrors, bounce: true, body: "Success".asComment()});  
    }

    receive(msg: TokenNotification) {  // 0x7362d09c
        let ctx: Context = context();

        if (ctx.sender == self.round_contract_jetton_wallet) {
            require(self.round_is_open, "not in open status for users to participate");

            // UserSubmit
            // Q1: 可以重複 submit?
            let boost_timestamp: Int = self.end_time - now();
            let previous_coin: Int? = self.user_submit_list.get(msg.from); // 取得 sender 的提交數量
            self.original_submit_qty = self.original_submit_qty + msg.amount;
            
            if (previous_coin == null) { // 首次提交
                let user_score: Int = msg.amount * boost_timestamp;
                self.user_submit_list.set(msg.from, user_score);

                self.total_submit_score = self.total_submit_score + user_score;
                emit(SubmitLog{ submit_amount: msg.amount, timeStamp: now() }.toCell());
                dump("Success");
            } else if (previous_coin!! > 0) {
                let user_score: Int = (msg.amount * boost_timestamp) + previous_coin!!;
                self.user_submit_list.set(msg.from, user_score);

                self.total_submit_score = self.total_submit_score + user_score;
                emit(SubmitLog{ submit_amount: msg.amount, timeStamp: now() }.toCell());
                dump("Success2");
            }            

        } else if (ctx.sender == self.upcoming_token_jetton_wallet) {
            // 🔴 Admin: Adding the funds 
            require(msg.from == self.owner, "not at right sender WallerV4 address");

            require(self.round_is_open == false, "still in open status");
            self.round_is_open = true;
            self.amount_of_upcoming_token = msg.amount;
            send(SendParameters{
                    to: msg.from,
                    value: 0,
                    mode: SendRemainingValue + SendIgnoreErrors,
                    bounce: true,
                    body: "Inject Funds Success".asComment()
            });
        }
    }

    // TODO: UserClaim 
    // Share = User Score / Total Score 
    // QTY_of_newToken = Share * Total Deposit of newToken 


    // receive(msg: AdminWithdraw) {
    receive("AdminWithdraw"){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "not the admin");
        require(now()>= self.end_time, "Timing incorrect");

        send(SendParameters{
            to: self.round_contract_jetton_wallet!!, 
            value: ton("0.1"),
            bounce: false,
            mode: 0 + SendRemainingValue,
            body: TokenTransfer{ 
                queryId: 0,
                amount: self.original_submit_qty,
                destination: myAddress(),
                response_destination: ctx.sender, // 傳回 admin Address
                custom_payload: null, 
                forward_ton_amount: ton("0.015"),
                forward_payload: emptySlice() // 提交申購的代幣扣完款、贖回
            }.toCell()
        });
    }

    get fun get_user_submit_list(): map<Address, Int> {
        return self.user_submit_list;
    }

    get fun get_ido_round_data(): RoundData {
        return RoundData {
            project_id: self.project_id,
            owner: self.owner,
            end_time: self.end_time,
            round_contract_jetton_wallet: self.round_contract_jetton_wallet!!,
            multiplier: self.multiplier,
            upcoming_token_jetton_wallet: self.upcoming_token_jetton_wallet!!,
            amount_of_upcoming_token: self.amount_of_upcoming_token,
            round_is_open: self.round_is_open,
            original_submit_qty: self.original_submit_qty,
            total_submit_score: self.total_submit_score
        };
    }
}

struct RoundData {
    project_id: Int as uint16;
    owner: Address;
    end_time: Int as uint32;
    round_contract_jetton_wallet: Address;
    multiplier: Int as uint16;
    upcoming_token_jetton_wallet: Address;
    amount_of_upcoming_token: Int as coins;
    round_is_open: Bool?;
    original_submit_qty: Int as coins;
    total_submit_score: Int as uint128;
}

message SubmitLog {
    submit_amount: Int as coins;
    timeStamp: Int as uint32;
}

message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}
