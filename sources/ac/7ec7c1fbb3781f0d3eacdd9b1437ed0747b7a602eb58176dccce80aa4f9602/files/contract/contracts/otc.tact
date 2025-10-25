// Proof of Capital is a technology for managing the issue of tokens that are backed by capital.
// The contract allows you to block the desired part of the issue for a selected period with a
// guaranteed buyback under pre-set conditions.

// During the lock-up period, only the market maker appointed by the contract creator has the
// right to buyback the tokens. Starting two months before the lock-up ends, any token holders
// can interact with the contract. They have the right to return their purchased tokens to the
// contract in exchange for the collateral.

// The goal of our technology is to create a market for assets backed by capital and
// transparent issuance management conditions.

// You can integrate the provided contract and Proof of Capital technology into your token if
// you specify the royalty wallet address of our project, listed on our website:
// https://proofofcapital.org

// All royalties collected are automatically used to repurchase the project's core token, as
// specified on the website, and are returned to the contract.

// This is the third version of the contract. It introduces the following features: the ability to choose any jetton as collateral, build collateral with an offset,
// perform delayed withdrawals (and restrict them if needed), assign multiple market makers, modify royalty conditions, and withdraw profit on request.

import "./imports/constants";
import "./jetton/jetton_messages";
import "./otc_messages";

contract OTC {
    id: Int as uint32;
    inputMasterToken: Address;
    outputMasterToken: Address; 
    inputWalletAddress: Address = ZERO_ADDRESS;
    outputWalletAddress: Address = ZERO_ADDRESS;
    admin: Address;
    client: Address;
    tonBalance: Int as coins = 0;
    outputTokenBalance: Int as coins = 0;
    supplies: map<Int as uint8, Supply>;
    supplyCount: Int as uint8 = 0;
    indexSupply: Int as uint8 = 0;
    buybackPrice: Int as coins;
    minInputAmount: Int as coins;
    outputMinAmount: Int as coins;
    supplyLockEnd: Int as uint64;
    totalLockEnd: Int as uint64 = 0;
    isSupply: Bool;
    state: Int as uint8 = STATE_FUNDING;
    withdrawData: FarmWithdrawData?;
    proposedAt: Int? as uint64;

    init(id: Int, inputMasterToken: Address, outputMasterToken: Address, admin: Address, client: Address, supplies: map<Int as uint8, Supply>, buybackPrice: Int as coins, outputMinAmount: Int as coins, minInputAmount: Int as coins, isSupply: Bool) {
        require(admin == sender(), "Only admin can initialize the contract");
        self.id = id;
        self.inputMasterToken = inputMasterToken;
        self.outputMasterToken = outputMasterToken;
        self.admin = admin;
        self.client = client;
        self.supplies = supplies;
        self.buybackPrice = buybackPrice;
        self.outputMinAmount = outputMinAmount;
        self.minInputAmount = minInputAmount;
        self.isSupply = isSupply;
        let outputSum = 0;
        let inputSum = 0;
        foreach (key, value in self.supplies) {
            self.supplyCount += 1;
            outputSum += value.output;
            inputSum += value.input;
        }
        self.supplyLockEnd = now() + INITIAL_LOCK_PERIOD;
        require(outputSum >= outputMinAmount || !self.isSupply, "Output sum must be greater than output min amount");
        require(inputSum >= minInputAmount || self.isSupply, "Input sum must be greater than min input amount");
        require(self.supplyCount > 0 && self.isSupply || !self.isSupply && self.supplyCount == 0, "Supply count must be greater than 0 if input master token is not null or equal to zero if input master token is null");


        if (inputMasterToken != ZERO_ADDRESS) {
            message(MessageParameters{
                to: inputMasterToken,
                value: TAKE_WALLET_ADDRESS_AMOUNT,
                mode: 0,
                bounce: false,
                body: ProvideWalletAddress{
                    query_id: id,
                    owner_address: myAddress(),
                    include_address: false,
                }.toCell(),
            });
        }

        message(MessageParameters{
            to: outputMasterToken,
            value: TAKE_WALLET_ADDRESS_AMOUNT,
            mode: 0,
            bounce: false,
            body: ProvideWalletAddress{
                query_id: id,
                owner_address: myAddress(),
                include_address: false,
            }.toCell(),
        });
    }

   receive(msg: TakeWalletAddress) {
        let sender = sender();
        require(sender == self.inputMasterToken || sender == self.outputMasterToken, "Only input master token or output master token can take wallet address");
        nativeReserve(MIN_OTC_BALANCE + self.tonBalance, 0);
        if (sender == self.inputMasterToken) {
            require(self.inputWalletAddress == ZERO_ADDRESS, "Input wallet address already set");
            self.inputWalletAddress = msg.wallet_address;
        } else {
            require(self.outputWalletAddress == ZERO_ADDRESS, "Output wallet address already set");
            self.outputWalletAddress = msg.wallet_address;
        }
        message(MessageParameters{
            to: self.admin,
            value: 0,
            mode: SendRemainingBalance|SendIgnoreErrors,
            bounce: false,
        });
    }



    receive() {
        nativeReserve(MIN_OTC_BALANCE + self.tonBalance, 0);
        message(MessageParameters{
            to: self.admin,
            value: 0,
            mode: SendRemainingBalance|SendIgnoreErrors,
            bounce: false,
        });
    }

    receive("deposit-ton") {
        require(self.inputMasterToken==ZERO_ADDRESS, "Input token is jetton");
        require(self.state == STATE_FUNDING, "State must be replenishment of funds");
        let ctx = context();
        self.tonBalance += ctx.value - DEPOSIT_FEE;
        if (self.tonBalance >= self.minInputAmount) {
            self.state = STATE_SUPPLY_IN_PROGRESS;
            self.supplyLockEnd = now() + SUPPLY_LOCK_PERIOD;
        }
    }

    receive("check-input") {
        nativeReserve(MIN_OTC_BALANCE + self.tonBalance, 0);
        let ctx = context();
        require(self.inputMasterToken != ZERO_ADDRESS, "Input token is jetton");
        require(self.isSupply, "Input token is not supply");
        require(ctx.sender == self.client || ctx.sender == self.admin, "Only client or admin can check input");
        
        require(ctx.value >= MIN_CHECK_AMOUNT, "Value must be greater than min check input amount");
        require(self.state == STATE_FUNDING, "State must be replenishment of funds");
        message(MessageParameters{
            to: self.inputWalletAddress,
            value: 0,
            mode: SendRemainingBalance,
            bounce: false,
            body: TokenTransfer {
                query_id: self.id,
                amount: self.minInputAmount,
                recipient: myAddress(),
                forward_ton_amount: FORWARD_TRANSACTION_VALUE,
                forward_payload: CheckInput{}.toSlice(),
            }.toCell(),
        });
    }

    
    receive("check-output") {
        nativeReserve(MIN_OTC_BALANCE + self.tonBalance, 0);
        let ctx = context();
        require(!self.isSupply, "Input token is supply");
        require(ctx.sender == self.client || ctx.sender == self.admin, "Only client or admin can check output");
        
        require(ctx.value >= MIN_CHECK_AMOUNT, "Value must be greater than min check output amount");
        require(self.state == STATE_FUNDING, "State must be replenishment of funds");
        self.outputTokenBalance = 0;
        message(MessageParameters{
            to: self.outputWalletAddress,
            value: 0,
            mode: SendRemainingBalance,
            bounce: false,
            body: TokenTransfer {
                query_id: self.id,
                amount: self.outputMinAmount,
                recipient: myAddress(),
                forward_ton_amount: FORWARD_TRANSACTION_VALUE,
                forward_payload: CheckOutput{}.toSlice(),
            }.toCell(),
        });
    }

    receive(msg: DepositTon) {
        require(self.state == STATE_FUNDING, "State must be replenishment of funds");
        require(self.inputMasterToken==ZERO_ADDRESS, "Input token is jetton");
        self.tonBalance += msg.amount;
        if (self.tonBalance >= self.minInputAmount) {
            self.state = STATE_SUPPLY_IN_PROGRESS;
            self.supplyLockEnd = now() + SUPPLY_LOCK_PERIOD;
        }
        let ctx = context();
        require(ctx.value >= msg.amount + DEPOSIT_FEE, "Value must be greater than amount");
        nativeReserve(MIN_OTC_BALANCE + self.tonBalance, 0);

        message(MessageParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingBalance|SendIgnoreErrors,
            bounce: false,
        });
    }

    receive("withdraw-ton") {
        nativeReserve(MIN_OTC_BALANCE, 0);
        require(sender() == self.client, "Only client can withdraw TON");
        require(self.supplyLockEnd < now(), "Supply lock is active");

        self.tonBalance = 0;
        
        message(MessageParameters{
            to: self.client,
            value: 0,
            mode: SendRemainingBalance,
            bounce: false,
        });
    }

    receive(msg: WithdrawInput) {
        require(sender() == self.client, "Only client can withdraw input jetton");
        require(self.supplyLockEnd < now(), "Supply lock is active");

        nativeReserve(MIN_OTC_BALANCE + self.tonBalance, 0);
        
        message(MessageParameters{
            to: self.inputWalletAddress,
            value: 0,
            mode: SendRemainingBalance,
            bounce: false,
            body: TokenTransfer {
                query_id: msg.queryId,
                amount:  msg.amount,
                recipient: self.client,
                forward_ton_amount: 0,
                forward_payload: beginCell().storeUint(0, 1).endCell().asSlice(),
            }.toCell(),
        });
    }

    receive(msg: WithdrawOutput) {
        require(sender() == self.client, "Only client can withdraw output jetton");
        require(self.totalLockEnd < now(), "Total lock is active");
        require(self.supplyLockEnd < now(), "Supply lock is active");
        self.state = STATE_CANCELED;

        nativeReserve(MIN_OTC_BALANCE + self.tonBalance, 0);
        
        message(MessageParameters{
            to: self.outputWalletAddress,
            value: 0,
            mode: SendRemainingBalance,
            bounce: false,
            body: TokenTransfer {
                query_id: msg.queryId,
                amount:  msg.amount,
                recipient: self.client,
                forward_ton_amount: 0,
                forward_payload: beginCell().storeUint(0, 1).endCell().asSlice(),
            }.toCell(),
        });
    }



    receive(msg: TokenNotification) {
        let ctx = context();
      
        if (ctx.sender == self.inputWalletAddress) {
            if (msg.from == myAddress()) { 
                let opcode: Int = msg.forward_payload.loadUint(32);
                if(opcode == CHECK_INPUT_MESSAGE_ID) {
                    self.state = STATE_SUPPLY_IN_PROGRESS;
                    self.supplyLockEnd = now() + SUPPLY_LOCK_PERIOD;
                }
            } else if (msg.from == self.admin) {
                require(ctx.value >= MIN_ADMIN_SEND_VALUE, "Value must be greater than min admin send value");
                require(self.state == STATE_WAITTING_FOR_CLIENT_ANSWER || self.state == STATE_CLIENT_REJECTED || self.state == STATE_CANCELED, "State must be waiting for client answer or client rejected or canceled");
                require(self.proposedAt != null, "Farm account must be proposed first");
                require(self.proposedAt!! + PROPOSE_FARM_ACCOUNT_LOCK_PERIOD < now(), "Propose farm account lock is active");
                let outputAmount = msg.amount * NOMINATOR / self.buybackPrice;
                self.state = STATE_CANCELED;
                require(outputAmount <= self.outputTokenBalance, "Not enough output token for buyback");
                self.outputTokenBalance -= outputAmount;
                nativeReserve(MIN_OTC_BALANCE + self.tonBalance, 0);
                message(MessageParameters{
                    to: self.outputWalletAddress,
                    value: 0,
                    mode: SendRemainingBalance,
                    bounce: false,
                    body: TokenTransfer {
                        query_id: msg.query_id,
                        amount: outputAmount,
                        recipient: self.admin,
                        forward_ton_amount: 0,
                        forward_payload: beginCell().storeUint(0, 1).endCell().asSlice(),
                    }.toCell(),
                });
            }
        } else if (ctx.sender == self.outputWalletAddress) {
            if (msg.from == myAddress()) { 
                let opcode: Int = msg.forward_payload.loadUint(32);
                if(opcode == CHECK_OUTPUT_MESSAGE_ID) {
                    self.state = STATE_SUPPLY_PROVIDED;
                    self.outputTokenBalance = msg.amount;
                    self.totalLockEnd = now() + TOTAL_LOCK_PERIOD;
                }
            } else  if (msg.from == self.admin) {
                self.handleSupplyProcess(msg);
            }
        }
    }

    receive(msg: ProposeFarmAccount) {
        require(sender() == self.admin, "Only admin");
        require(self.state == STATE_SUPPLY_PROVIDED, "State must be supply provided");
        nativeReserve(MIN_OTC_BALANCE + self.tonBalance, 0);
        self.withdrawData = msg.withdrawData;
        self.proposedAt = now();
        self.state = STATE_WAITTING_FOR_CLIENT_ANSWER;

        message(MessageParameters{
            to: self.admin,
            value: 0,
            mode: SendRemainingBalance|SendIgnoreErrors,
            bounce: false,
        });
    }

    receive("yes") {
        require(sender() == self.client, "Only client can call");
        require(self.state == STATE_WAITTING_FOR_CLIENT_ANSWER || self.state == STATE_CLIENT_REJECTED, "State must allow client voting");
        self.state = STATE_CLIENT_ACCEPTED;
    }

    receive("no") {
        require(sender() == self.client, "Only client can call");
        require(self.state == STATE_WAITTING_FOR_CLIENT_ANSWER, "State must allow client voting");
        self.state = STATE_CLIENT_REJECTED;
    }

    receive(msg: Send) {
        require(sender() == self.admin, "Only admin");
        nativeReserve(MIN_OTC_BALANCE + self.tonBalance, 0);
        require(self.state == STATE_CLIENT_ACCEPTED, "Client must have accepted the proposal");
        require(self.withdrawData != null, "Withdraw data must be set");

        message(MessageParameters{
            to: self.outputWalletAddress,
            value: 0,
            mode: SendRemainingBalance|SendIgnoreErrors,
            bounce: false,
            body: TokenTransfer {
                query_id: msg.queryId,
                amount: self.outputMinAmount,
                recipient: self.withdrawData!!.farmAccount,
                forward_ton_amount: msg.forwardTonAmount,
                forward_payload:  self.withdrawData!!.sendData.asSlice(),
            }.toCell(),
        });
    }

    receive(msg: BuybackLaunchJetton) {
        let ctx = context();
        require(ctx.sender == self.admin, "Only admin can buyback");
        require(self.inputMasterToken == ZERO_ADDRESS, "Buyback only for TON inputs");

        require(self.state == STATE_WAITTING_FOR_CLIENT_ANSWER || self.state == STATE_CLIENT_REJECTED || self.state == STATE_CANCELED, "State must be waiting for client answer or client rejected or canceled");
        require(self.proposedAt != null, "Farm account must be proposed first");
        require(self.proposedAt!! + PROPOSE_FARM_ACCOUNT_LOCK_PERIOD < now(), "Propose farm account lock is active");

        require(ctx.value >= msg.amount + MIN_ADMIN_SEND_VALUE, "Value must be greater than amount");
        let outputAmount =  msg.amount * NOMINATOR / self.buybackPrice;
        require(outputAmount <= self.outputTokenBalance, "Not enough POK for buyback");
        self.state = STATE_CANCELED;
        self.outputTokenBalance -= outputAmount;
        self.tonBalance += msg.amount;
        nativeReserve(MIN_OTC_BALANCE + self.tonBalance, 0);
        message(MessageParameters{
            to: self.outputWalletAddress,
            value: 0,
            mode: SendRemainingBalance,
            bounce: false,
            body: TokenTransfer {
                query_id: msg.queryId,
                amount: outputAmount,
                recipient: self.admin,
                forward_ton_amount: 0,
                forward_payload: beginCell().storeUint(0, 1).endCell().asSlice(),
            }.toCell(),
        });

    }
   
    // //*warning: this function is for testing only ----------------------------------------------------------------------------------------------------------
    // receive("unlock-for-test") {
    //     require(sender() == self.admin, "Only admin can unlock for test");
    //     self.totalLockEnd = 0;
    //     self.supplyLockEnd = 0;
    //     self.proposedAt = 0;
    // }

    inline fun handleSupplyProcess(msg: TokenNotification) {
        let ctx = context();
        require(ctx.value >= MIN_ADMIN_SEND_VALUE, "Value must be greater than min admin send value");
        let currentSupply: Supply = self.supplies.get(self.indexSupply)!!;
        require(currentSupply.output  <= msg.amount, "Amount must be greater than supply output");
        require(self.state == STATE_SUPPLY_IN_PROGRESS, "State must be supply of funds");

        self.indexSupply += 1;
        if (self.indexSupply == self.supplyCount) {
            self.state = STATE_SUPPLY_PROVIDED;
            self.totalLockEnd = now() + TOTAL_LOCK_PERIOD;
        }
        self.outputTokenBalance += currentSupply.output;
        if (self.inputMasterToken == ZERO_ADDRESS) {
            self.tonBalance -= currentSupply.input;
            nativeReserve(MIN_OTC_BALANCE + self.tonBalance, 0);
            message(MessageParameters{
                to: self.admin,
                value: 0,
                mode: SendRemainingBalance,
                bounce: false,
            });
        } else {
            nativeReserve(MIN_OTC_BALANCE, 0);
            message(MessageParameters{
                to: self.inputWalletAddress,
                value: 0,
                mode: SendRemainingBalance,
                bounce: false,
                body: TokenTransfer {
                    query_id: self.id,
                    amount: currentSupply.input,
                    recipient: self.admin,
                    forward_ton_amount: 0,
                    forward_payload: beginCell().storeUint(0, 1).endCell().asSlice(),
                }.toCell(),
            });
        }
    }
    get fun outputTokenMaster(): Address {
        return self.outputMasterToken;
    }

    // Getter for input master token
    get fun inputTokenMaster(): Address {
        return self.inputMasterToken;
    }

    // Getter for input wallet address
    get fun inputWallet(): Address {
        return self.inputWalletAddress;
    }

    // Getter for output wallet address
    get fun outputWallet(): Address {
        return self.outputWalletAddress;
    }

    // Getter for admin address
    get fun adminAddress(): Address {
        return self.admin;
    }

    // Getter for client address
    get fun clientAddress(): Address {
        return self.client;
    }

    // Getter for TON balance
    get fun tonBalanceAmount(): Int {
        return self.tonBalance;
    }

    // Getter for output token balance
    get fun outputTokenBalanceAmount(): Int {
        return self.outputTokenBalance;
    }

    // Getter for supply count
    get fun supplyCountValue(): Int {
        return self.supplyCount;
    }

    // Getter for current supply index
    get fun currentSupplyIndex(): Int {
        return self.indexSupply;
    }

    // Getter for price to refund
    get fun refundPrice(): Int {
        return self.buybackPrice;
    }

    // Getter for minimum input amount
    get fun minInputAmountValue(): Int {
        return self.minInputAmount;
    }

    // Getter for minimum output amount
    get fun minOutputAmount(): Int {
        return self.outputMinAmount;
    }

    // Getter for supply lock end time
    get fun supplyLockEndTime(): Int {
        return self.supplyLockEnd;
    }

    // Getter for total lock end time
    get fun totalLockEndTime(): Int {
        return self.totalLockEnd;
    }

    // Getter for buyback price
    get fun buybackPrice(): Int {
        return self.buybackPrice;
    }

    // Getter for current state
    get fun currentState(): Int {
        return self.state;
    }

    // Getter for withdraw data
    get fun withdrawDataInfo(): FarmWithdrawData? {
        return self.withdrawData;
    }

    // Getter for proposed time
    get fun proposedTime(): Int? {
        return self.proposedAt;
    }


    // Getter for contract ID
    get fun contractId(): Int {
        return self.id;
    }

    // Getter for contract balance
    get fun balance(): Int {
        return myBalance();
    }
}
